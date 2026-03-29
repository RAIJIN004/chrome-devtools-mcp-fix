/**
 * PATCHED uploadFile Handler for Chrome DevTools MCP
 * 
 * This is the replacement for the uploadFile handler in:
 * chrome-devtools-mcp/build/src/tools/input.js (lines 297-342)
 * 
 * Original issue: upload_file fails on Facebook Marketplace and similar sites
 * that use hidden file inputs that don't trigger file chooser properly.
 * 
 * Fix: Removes the unreliable file chooser method (opens system window)
 * and uses Chrome DevTools Protocol directly for hidden file inputs.
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
// PATCHED UPLOAD_FILE HANDLER - No system window, uses CDP directly
// ============================================================================
export const uploadFile = definePageTool({
    name: 'upload_file',
    description: 'Upload a file through a provided element. Uses CDP for hidden file inputs (no system dialog).',
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
            const page = request.page.pptrPage;
            
            // Method 1: Try direct upload (works for visible file inputs)
            try {
                await handle.uploadFile(filePath);
                uploaded = true;
                logger('File uploaded directly using uploadFile method');
            }
            catch (directError) {
                logger('Direct upload failed, using CDP method (no system window)', directError);
                
                // Method 2: CDP FALLBACK - Upload directly without opening system dialog
                // This works for hidden file inputs on Facebook Marketplace, etc.
                try {
                    const cdpSession = await page.target().createCDPSession();
                    
                    // Get the element's backend node ID
                    const elementHandle = await page.evaluateHandle(
                        (targetUid) => {
                            // Try to find by UID attribute first
                            const element = document.querySelector(`[uid="${targetUid}"]`) ||
                                           document.querySelector(`[data-uid="${targetUid}"]`);
                            if (element) return element;
                            
                            // Fallback: find any file input on the page
                            return document.querySelector('input[type="file"]');
                        },
                        uid
                    );
                    
                    if (elementHandle) {
                        // Get the backend node ID using CDP
                        const { node } = await cdpSession.send('DOM.describeNode', {
                            objectId: elementHandle.remoteObject.objectId
                        });
                        
                        if (node && node.backendNodeId) {
                            // Upload file directly via CDP
                            await cdpSession.send('DOM.setFileInputFiles', {
                                files: [filePath],
                                backendNodeId: node.backendNodeId
                            });
                            uploaded = true;
                            logger('File uploaded using CDP method (no system window)');
                        }
                    }
                    
                    // If still not uploaded, try finding any file input
                    if (!uploaded) {
                        const { nodeIds } = await cdpSession.send('DOM.querySelectorAll', {
                            nodeId: (await cdpSession.send('DOM.getDocument')).root.nodeId,
                            selector: 'input[type="file"]'
                        });
                        
                        if (nodeIds && nodeIds.length > 0) {
                            // Upload to the first file input found
                            const { backendNodeId } = await cdpSession.send('DOM.describeNode', { 
                                nodeId: nodeIds[0] 
                            });
                            await cdpSession.send('DOM.setFileInputFiles', {
                                files: [filePath],
                                backendNodeId
                            });
                            uploaded = true;
                            logger('File uploaded using CDP fallback (found input[type=file])');
                        }
                    }
                }
                catch (cdpError) {
                    logger('CDP upload method failed', cdpError);
                }
            }
            
            if (!uploaded) {
                throw new Error(`Failed to upload file. Could not upload to element with uid "${uid}". The element may not accept file uploads.`);
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
