/**
 * PATCHED uploadFile Handler for Chrome DevTools MCP
 * 
 * This is the replacement for the uploadFile handler in:
 * chrome-devtools-mcp/build/src/tools/input.js (lines 297-342)
 * 
 * Original issue: upload_file fails on Facebook Marketplace and similar sites
 * that use hidden file inputs that don't trigger file chooser properly.
 * 
 * Fix: Adds a third fallback method that finds hidden <input type="file">
 * elements, makes them visible, and uploads via Chrome DevTools Protocol.
 * 
 * Date: 2026-03-28
 * Author: Fix by opencode/mimo-v2-omni-free
 */

import { logger } from '../logger.js';
import { zod } from '../third_party/index.js';
import { ToolCategory } from './categories.js';
import { definePageTool } from './ToolDefinition.js';

const includeSnapshotSchema = zod
    .boolean()
    .optional()
    .describe('Whether to include a snapshot in the response. Default is false.');

// ============================================================================
// PATCHED UPLOAD_FILE HANDLER - Added robust fallback for problematic sites
// ============================================================================
export const uploadFile = definePageTool({
    name: 'upload_file',
    description: 'Upload a file through a provided element. Includes automatic fallback for sites with hidden file inputs.',
    annotations: {
        category: ToolCategory.INPUT,
        readOnlyHint: false,
    },
    schema: {
        uid: zod
            .string()
            .describe('The uid of the file input element or an element that will open file chooser on the page from the page content snapshot'),
        filePath: zod.string().describe('The local path of the file to upload'),
        includeSnapshot: includeSnapshotSchema,
    },
    handler: async (request, response) => {
        const { uid, filePath } = request.params;
        const handle = (await request.page.getElementByUid(uid));
        
        try {
            let uploaded = false;
            
            // Method 1: Try direct upload (original method)
            try {
                await handle.uploadFile(filePath);
                uploaded = true;
                logger('File uploaded directly using uploadFile method');
            }
            catch (directError) {
                logger('Direct upload failed, trying file chooser method', directError);
                
                // Method 2: Try clicking and waiting for file chooser (original fallback)
                try {
                    const [fileChooser] = await Promise.all([
                        request.page.pptrPage.waitForFileChooser({ timeout: 3000 }),
                        handle.asLocator().click(),
                    ]);
                    await fileChooser.accept([filePath]);
                    uploaded = true;
                    logger('File uploaded using file chooser method');
                }
                catch (chooserError) {
                    logger('File chooser method failed, trying PATCHED fallback', chooserError);
                    
                    // Method 3: PATCHED FALLBACK - Find hidden file input and make it visible
                    try {
                        const page = request.page.pptrPage;
                        
                        // Execute JavaScript to find or create a visible file input and upload
                        const result = await page.evaluate(async (path) => {
                            // Find existing file inputs
                            let fileInput = document.querySelector('input[type="file"]');
                            
                            if (!fileInput) {
                                // Create a new file input if none exists
                                fileInput = document.createElement('input');
                                fileInput.type = 'file';
                                fileInput.style.display = 'none';
                                document.body.appendChild(fileInput);
                            }
                            
                            // Make the input temporarily visible and clickable
                            const originalStyles = {
                                display: fileInput.style.display,
                                position: fileInput.style.position,
                                visibility: fileInput.style.visibility,
                                opacity: fileInput.style.opacity,
                                width: fileInput.style.width,
                                height: fileInput.style.height
                            };
                            
                            fileInput.style.display = 'block';
                            fileInput.style.position = 'fixed';
                            fileInput.style.top = '50%';
                            fileInput.style.left = '50%';
                            fileInput.style.transform = 'translate(-50%, -50%)';
                            fileInput.style.zIndex = '999999';
                            fileInput.style.width = '200px';
                            fileInput.style.height = '50px';
                            fileInput.style.opacity = '1';
                            fileInput.style.visibility = 'visible';
                            fileInput.style.backgroundColor = 'white';
                            fileInput.style.border = '2px solid #1877f2';
                            fileInput.style.borderRadius = '8px';
                            fileInput.style.padding = '10px';
                            
                            return { 
                                success: true, 
                                inputId: fileInput.id || 'patched-file-input',
                                accept: fileInput.accept,
                                multiple: fileInput.multiple
                            };
                        }, filePath);
                        
                        if (result.success) {
                            // Now use the Puppeteer handle to upload the file
                            // Find the visible file input by evaluating again
                            const visibleInputHandle = await page.evaluateHandle(() => {
                                const inputs = document.querySelectorAll('input[type="file"]');
                                for (const input of inputs) {
                                    if (input.style.display === 'block' && input.style.position === 'fixed') {
                                        return input;
                                    }
                                }
                                // Return first file input if none found as visible
                                return inputs[0];
                            });
                            
                            if (visibleInputHandle) {
                                // Use Puppeteer's uploadFile on the handle
                                const cdpSession = await page.target().createCDPSession();
                                const { nodeIds } = await cdpSession.send('DOM.querySelectorAll', {
                                    nodeId: (await cdpSession.send('DOM.getDocument')).root.nodeId,
                                    selector: 'input[type="file"]'
                                });
                                
                                // Find the visible one
                                for (const nodeId of nodeIds) {
                                    const { model } = await cdpSession.send('DOM.getBoxModel', { nodeId });
                                    if (model && model.content) {
                                        // This input is visible (has dimensions)
                                        const { backendNodeId } = await cdpSession.send('DOM.describeNode', { nodeId });
                                        await cdpSession.send('DOM.setFileInputFiles', {
                                            files: [filePath],
                                            backendNodeId
                                        });
                                        uploaded = true;
                                        logger('File uploaded using PATCHED fallback method');
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    catch (patchedError) {
                        logger('Patched fallback method also failed', patchedError);
                    }
                }
            }
            
            if (!uploaded) {
                throw new Error(`Failed to upload file. All methods exhausted. The element could not accept the file directly, clicking did not trigger a file chooser, and the patched fallback also failed.`);
            }
            
            if (request.params.includeSnapshot) {
                response.includeSnapshot();
            }
            response.appendResponseLine(`File uploaded from ${filePath}.`);
        }
        finally {
            void handle.dispose();
        }
    },
});
