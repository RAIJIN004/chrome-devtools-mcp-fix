# Chrome DevTools MCP - File Upload Fix for Facebook Marketplace

## Problem Description

The `upload_file` tool in the Chrome DevTools MCP package fails intermittently when uploading files to Facebook Marketplace and other similar sites that use hidden file inputs.

### Symptoms

- File upload appears to work but image never loads (stuck on "Loading...")
- Works sometimes, fails other times on the same page
- The file picker native dialog may open but upload fails
- Happens more frequently with complex file paths (spaces, special characters, long paths)

### Root Cause

The original `upload_file` handler in `chrome-devtools-mcp` uses two methods:

1. **Direct upload**: `handle.uploadFile(filePath)` - tries to upload directly to the element
2. **File chooser**: Click element → wait for file chooser → accept file

Both methods fail on sites like Facebook Marketplace because:
- The button that triggers upload is not a `<input type="file">` element
- The actual file input is hidden (`display: none`)
- The native file picker dialog doesn't always communicate properly with Puppeteer

## Solution

This patch adds a **third fallback method** that:
1. Searches for hidden `<input type="file">` elements in the DOM
2. Makes them temporarily visible
3. Uses Chrome DevTools Protocol (CDP) to upload files directly to the input

## Installation

### Automatic Installation

Run the appropriate script for your OS:

**Windows:**
```batch
scripts\apply-fix.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/apply-fix.sh
./scripts/apply-fix.sh
```

### Manual Installation

1. Find your chrome-devtools-mcp installation:
   ```bash
   npm list -g chrome-devtools-mcp
   npm root -g
   ```

2. Navigate to the tools directory:
   ```bash
   cd $(npm root -g)/chrome-devtools-mcp/build/src/tools
   ```

3. Backup the original file:
   ```bash
   cp input.js input.js.backup
   ```

4. Replace the `uploadFile` handler (lines 297-342) with the patched version from `fix/input-file-patched.js`

## Verification

After applying the fix, test on Facebook Marketplace:

1. Navigate to https://www.facebook.com/marketplace/create/item
2. Use the `upload_file` tool directly on the "Add photos or drag and drop" button:
   ```
   upload_file(uid="button_uid", filePath="C:\path\to\image.jpg")
   ```
3. The image should upload successfully without needing to manually make the input visible

## Technical Details

The patched handler adds this fallback logic:

```javascript
// Method 3: PATCHED FALLBACK - Find hidden file input and make it visible
try {
    const page = request.page.pptrPage;
    
    // Find existing file inputs
    let fileInput = document.querySelector('input[type="file"]');
    
    // Make the input temporarily visible
    fileInput.style.display = 'block';
    fileInput.style.position = 'fixed';
    // ... other styles ...
    
    // Use CDP to upload directly
    const cdpSession = await page.target().createCDPSession();
    const { nodeIds } = await cdpSession.send('DOM.querySelectorAll', {
        nodeId: (await cdpSession.send('DOM.getDocument')).root.nodeId,
        selector: 'input[type="file"]'
    });
    
    // Upload via CDP
    await cdpSession.send('DOM.setFileInputFiles', {
        files: [filePath],
        backendNodeId
    });
} catch (patchedError) {
    // Fallback failed
}
```

## Compatibility

- **Chrome DevTools MCP version**: 0.20.3 (tested)
- **Should work with**: Any version that uses similar input.js structure

## Notes

- This patch modifies the npm global package. If you update chrome-devtools-mcp, you'll need to reapply the patch.
- The backup file (`input.js.backup`) is created during automatic installation.
- This fix is specifically designed for Facebook Marketplace but should work on any site with similar hidden file input patterns.

## License

This fix is provided as-is. The original chrome-devtools-mcp is licensed under Apache-2.0.
