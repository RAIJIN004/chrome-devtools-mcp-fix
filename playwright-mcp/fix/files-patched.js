"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);
var files_exports = {};
__export(files_exports, {
  default: () => files_default,
  uploadFile: () => uploadFile
});
module.exports = __toCommonJS(files_exports);
var import_mcpBundle = require("playwright-core/lib/mcpBundle");
var import_tool = require("./tool");

// ============================================================================
// PATCHED: browser_file_upload - Fallback for hidden file inputs
// ============================================================================
// Original issue: Facebook Marketplace blocks the native file chooser,
// so no fileChooser modal state is created. This fix falls back to
// using locator.setInputFiles() on hidden input[type="file"] elements.
// ============================================================================

const uploadFile = (0, import_tool.defineTabTool)({
  capability: "core",
  schema: {
    name: "browser_file_upload",
    title: "Upload files",
    description: "Upload one or multiple files",
    inputSchema: import_mcpBundle.z.object({
      paths: import_mcpBundle.z.array(import_mcpBundle.z.string()).optional().describe("The absolute paths to the files to upload. Can be single file or multiple files. If omitted, file chooser is cancelled.")
    }),
    type: "action"
  },
  // ======================================================================
  // PATCHED HANDLE - Added fallback via setInputFiles when fileChooser
  // modal is not available (e.g., on Facebook Marketplace).
  // ======================================================================
  handle: async (tab, params, response) => {
    response.setIncludeSnapshot();
    const modalState = tab.modalStates().find((state) => state.type === "fileChooser");

    if (modalState) {
      // Method 1: Original - file chooser modal is available
      response.addCode(`await fileChooser.setFiles(${JSON.stringify(params.paths)})`);
      tab.clearModalState(modalState);
      await tab.waitForCompletion(async () => {
        if (params.paths)
          await modalState.fileChooser.setFiles(params.paths);
      });
      return;
    }

    // Method 2: PATCHED FALLBACK - No file chooser, use setInputFiles
    // directly on hidden input[type="file"] elements.
    // This works on Facebook Marketplace and similar sites that
    // block the native file chooser from opening.
    if (!params.paths || params.paths.length === 0)
      throw new Error("No file chooser visible");

    const page = tab.page;
    const fileInputs = page.locator('input[type="file"]');
    const count = await fileInputs.count();

    if (count === 0)
      throw new Error("No file chooser visible and no input[type='file'] elements found on the page");

    // Upload to the first file input (most pages have only one)
    const firstInput = fileInputs.first();
    await firstInput.setInputFiles(params.paths);
    response.addCode(`// Uploaded files directly via setInputFiles fallback`);
  },
  clearsModalState: "fileChooser"
});

var files_default = [
  uploadFile
];
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  uploadFile
});
