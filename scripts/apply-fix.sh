#!/bin/bash
# ============================================================================
# Chrome DevTools MCP - File Upload Fix for Facebook Marketplace
# Linux/Mac Installation Script
# ============================================================================
#
# This script patches the chrome-devtools-mcp package to fix file upload
# issues on Facebook Marketplace and similar sites.
#
# Usage: chmod +x scripts/apply-fix.sh && ./scripts/apply-fix.sh
# ============================================================================

set -e

echo ""
echo "============================================================"
echo " Chrome DevTools MCP - File Upload Fix"
echo "============================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get npm global path
NPM_GLOBAL=$(npm root -g)
echo -e "NPM global path: ${GREEN}$NPM_GLOBAL${NC}"

MCP_PATH="$NPM_GLOBAL/chrome-devtools-mcp"
INPUT_JS="$MCP_PATH/build/src/tools/input.js"
BACKUP_JS="$MCP_PATH/build/src/tools/input.js.backup"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/../fix/input-file-patched-handler.js"

echo ""
echo "Checking for chrome-devtools-mcp installation..."

if [ ! -d "$MCP_PATH" ]; then
    echo -e "${RED}ERROR: chrome-devtools-mcp not found at $MCP_PATH${NC}"
    echo "Please install it first: npm install -g chrome-devtools-mcp"
    exit 1
fi

if [ ! -f "$INPUT_JS" ]; then
    echo -e "${RED}ERROR: input.js not found at $INPUT_JS${NC}"
    exit 1
fi

echo -e "Found chrome-devtools-mcp at: ${GREEN}$MCP_PATH${NC}"
echo ""

# Create backup
echo "Creating backup of original file..."
if [ -f "$BACKUP_JS" ]; then
    echo -e "${YELLOW}Backup already exists at $BACKUP_JS${NC}"
else
    cp "$INPUT_JS" "$BACKUP_JS"
    echo -e "${GREEN}Backup created successfully.${NC}"
fi

# Function to extract the handler from the patched file
get_patched_handler() {
    cat "$PATCH_FILE"
}

# Find the uploadFile handler start line
echo ""
echo "Locating uploadFile handler in input.js..."

# Find the start of uploadFile handler
START_LINE=$(grep -n "export const uploadFile = definePageTool" "$INPUT_JS" | cut -d: -f1)

if [ -z "$START_LINE" ]; then
    echo -e "${RED}ERROR: Could not find uploadFile handler in input.js${NC}"
    exit 1
fi

echo -e "Found uploadFile handler at line: ${GREEN}$START_LINE${NC}"

# Find the end of the handler (next export or end of file)
END_LINE=$(tail -n +$((START_LINE + 1)) "$INPUT_JS" | grep -n "^export " | head -1 | cut -d: -f1)
if [ -z "$END_LINE" ]; then
    # If no next export, find the end of file
    END_LINE=$(wc -l < "$INPUT_JS")
else
    END_LINE=$((START_LINE + END_LINE - 1))
fi

echo "Handler spans lines $START_LINE to $END_LINE"

# Create the patched file
echo ""
echo "Creating patched file..."

# Copy everything before the handler
head -n $((START_LINE - 1)) "$INPUT_JS" > "$INPUT_JS.tmp"

# Add the patched handler
echo "" >> "$INPUT_JS.tmp"
echo "// ============================================================================" >> "$INPUT_JS.tmp"
echo "// PATCHED UPLOAD_FILE HANDLER - Added robust fallback for problematic sites" >> "$INPUT_JS.tmp"
echo "// Applied by chrome-devtools-mcp-fix script" >> "$INPUT_JS.tmp"
echo "// Date: $(date +%Y-%m-%d)" >> "$INPUT_JS.tmp"
echo "// ============================================================================" >> "$INPUT_JS.tmp"
cat "$PATCH_FILE" >> "$INPUT_JS.tmp"

# Copy everything after the handler (if any)
if [ $END_LINE -lt $(wc -l < "$INPUT_JS") ]; then
    tail -n +$((END_LINE + 1)) "$INPUT_JS" >> "$INPUT_JS.tmp"
fi

# Replace the original file
echo ""
echo "Replacing original file..."
mv "$INPUT_JS.tmp" "$INPUT_JS"

echo -e "${GREEN}Patch applied successfully!${NC}"
echo ""
echo "============================================================"
echo " Next Steps"
echo "============================================================"
echo ""
echo "1. Restart your MCP connection (restart opencode)"
echo ""
echo "2. Test the fix on Facebook Marketplace:"
echo "   - Navigate to https://www.facebook.com/marketplace/create/item"
echo "   - Use upload_file tool on the 'Add photos' button"
echo ""
echo "3. If you need to rollback:"
echo "   cp '$BACKUP_JS' '$INPUT_JS'"
echo ""
echo "============================================================"
echo ""
