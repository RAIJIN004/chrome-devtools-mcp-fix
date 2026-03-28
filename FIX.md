# File Upload Fix - Technical Documentation

## Problem Analysis

### Original Code Flow

The original `uploadFile` handler in `chrome-devtools-mcp/build/src/tools/input.js` has two methods:

```
Method 1: handle.uploadFile(filePath)
    ↓ (fails on hidden inputs)
Method 2: Click element → waitForFileChooser() → fileChooser.accept()
    ↓ (fails when file chooser doesn't trigger properly)
[ERROR] "Failed to upload file. The element could not accept the file directly..."
```

### Why It Fails on Facebook Marketplace

1. Facebook uses a button element (`<button>Add photos</button>`) as the upload trigger
2. The actual `<input type="file">` is hidden with `display: none`
3. When clicking the button, the native file picker opens but sometimes:
   - The file picker doesn't communicate properly with Puppeteer
   - The upload signal gets lost
   - The hidden input doesn't receive the file reference

### Root Cause

The issue is NOT with file paths (we tested and verified complex paths work):
- ✅ Simple paths: `C:\Users\user\Downloads\image.jpg`
- ✅ Paths with spaces: `C:\Users\user\My Documents\image.jpg`
- ✅ Paths with special chars: `C:\Users\user\Downloads\COPIA LIMPIA (19-09-2025)\image.png`
- ✅ Long paths with unicode: `C:\Users\user\Downloads\TapScanner 02-01-2024-13꞉22 (p1).jpg`

The issue IS with how the file gets to the hidden input element.

## The Solution

### Method 3: CDP Direct Upload

The patched handler adds a third method that:

1. Finds hidden `<input type="file">` elements in the DOM
2. Makes them temporarily visible (for debugging/verification)
3. Uses Chrome DevTools Protocol (CDP) to upload directly:

```javascript
const cdpSession = await page.target().createCDPSession();
const { nodeIds } = await cdpSession.send('DOM.querySelectorAll', {
    nodeId: (await cdpSession.send('DOM.getDocument')).root.nodeId,
    selector: 'input[type="file"]'
});

for (const nodeId of nodeIds) {
    const { backendNodeId } = await cdpSession.send('DOM.describeNode', { nodeId });
    await cdpSession.send('DOM.setFileInputFiles', {
        files: [filePath],
        backendNodeId
    });
}
```

### Why This Works

- CDP operates at a lower level than Puppeteer's Element Handle API
- `DOM.setFileInputFiles` bypasses the file picker entirely
- Works directly with the browser's DOM, regardless of CSS visibility

## Code Changes

### Original Handler (Lines 297-342)

```javascript
export const uploadFile = definePageTool({
    name: 'upload_file',
    handler: async (request, response) => {
        const { uid, filePath } = request.params;
        const handle = (await request.page.getElementByUid(uid));
        try {
            try {
                await handle.uploadFile(filePath);
            } catch {
                try {
                    const [fileChooser] = await Promise.all([
                        request.page.pptrPage.waitForFileChooser({ timeout: 3000 }),
                        handle.asLocator().click(),
                    ]);
                    await fileChooser.accept([filePath]);
                } catch {
                    throw new Error(`Failed to upload file...`);
                }
            }
            // ...
        }
    },
});
```

### Patched Handler (Full Replacement)

The patched version adds Method 3 inside the second `catch` block, after the file chooser fails.

## Testing Results

| Test Case | Original | Patched |
|-----------|----------|---------|
| Facebook Marketplace - Simple path | Sometimes fails | ✅ Works |
| Facebook Marketplace - Complex path | Often fails | ✅ Works |
| Other sites with hidden inputs | Fails | ✅ Works |
| Sites with visible file inputs | ✅ Works | ✅ Works |

## Rollback

If you need to rollback:

```bash
# Linux/Mac
cp $(npm root -g)/chrome-devtools-mcp/build/src/tools/input.js.backup \
   $(npm root -g)/chrome-devtools-mcp/build/src/tools/input.js

# Windows
copy "C:\Users\%USERNAME%\AppData\Roaming\npm\node_modules\chrome-devtools-mcp\build\src\tools\input.js.backup" \
     "C:\Users\%USERNAME%\AppData\Roaming\npm\node_modules\chrome-devtools-mcp\build\src\tools\input.js"
```

## Future Updates

If chrome-devtools-mcp updates and overwrites your fix:

1. The backup will be lost
2. You'll need to reapply the patch
3. Consider forking the repository and using your fork instead

## References

- Chrome DevTools Protocol Documentation: https://chromedevtools.github.io/devtools-protocol/
- DOM.setFileInputFiles: https://chromedevtools.github.io/devtools-protocol/tot/DOM/#method-setFileInputFiles
- Puppeteer File Upload: https://pptr.dev/api/puppeteer.page.uploadfile
