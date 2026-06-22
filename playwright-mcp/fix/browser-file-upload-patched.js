/**
 * PATCHED uploadFile Handler for @playwright/mcp
 *
 * This is the replacement for the uploadFile handler in:
 * playwright/lib/mcp/browser/tools/files.js
 *
 * Original issue: browser_file_upload fails on Facebook Marketplace
 * because the page blocks the native file chooser event, so no
 * fileChooser modal state is created.
 *
 * Fix: Falls back to Playwright's locator.setInputFiles() when no
 * file chooser modal is available, targeting hidden input[type="file"]
 * elements directly.
 *
 * Author: Fix by RAIJIN004
 */

const path = require('path');

/**
 * PATCHED handle function for uploadFile
 *
 * Replaces the original handle in files.js (lines 38-49)
 *
 * Changes:
 * 1. If fileChooser modal exists → use original approach (setFiles)
 * 2. If no fileChooser → find input[type="file"] and use setInputFiles
 * 3. If no inputs found → throw original error
 */
async function patchedHandle(tab, params, response) {
  response.setIncludeSnapshot();
  const modalState = tab.modalStates().find((state) => state.type === "fileChooser");

  if (modalState) {
    // Method 1: Original file chooser approach
    response.addCode(`await fileChooser.setFiles(${JSON.stringify(params.paths)})`);
    tab.clearModalState(modalState);
    await tab.waitForCompletion(async () => {
      if (params.paths)
        await modalState.fileChooser.setFiles(params.paths);
    });
    return;
  }

  // Method 2: Fallback - no file chooser, use setInputFiles directly
  if (!params.paths || params.paths.length === 0)
    throw new Error("No file chooser visible");

  const page = tab.page;
  const fileInputs = page.locator('input[type="file"]');
  const count = await fileInputs.count();

  if (count === 0)
    throw new Error("No file chooser visible and no input[type='file'] elements found on the page");

  // Use the first file input found (most pages have only one)
  const firstInput = fileInputs.first();
  await firstInput.setInputFiles(params.paths.map(p => path.resolve(p)));
  response.addCode(`// Uploaded files directly via setInputFiles fallback`);
}

module.exports = { patchedHandle };
