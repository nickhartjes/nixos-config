#!/usr/bin/env bash

# Component Validation Script
# Validates all NixOS configuration components for syntax and structure

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPONENTS_DIR="$PROJECT_ROOT/components"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 NixOS Components Validation${NC}"
echo "================================================"

# Check if components directory exists
if [[ ! -d "$COMPONENTS_DIR" ]]; then
    echo -e "${RED}Error: Components directory not found at $COMPONENTS_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}📂 Validating syntax for all .nix files...${NC}"

# Simple syntax validation
echo "Running syntax check..."
if find "$COMPONENTS_DIR" -name "*.nix" -exec nix-instantiate --parse {} \; >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓ All .nix files have valid syntax${NC}"
    syntax_valid=true
else
    echo -e "  ${RED}✗ Some files have syntax errors${NC}"
    syntax_valid=false
fi

# Count files
total_files=$(find "$COMPONENTS_DIR" -name "*.nix" -type f | wc -l)
echo -e "  ${BLUE}📊 Total .nix files: $total_files${NC}"

# Check for common issues
echo ""
echo -e "${BLUE}🏗️  Structure Check${NC}"

# Check option naming
echo "Checking option naming consistency..."
bad_options=$(find "$COMPONENTS_DIR" -name "*.nix" -exec grep -l "options\." {} \; | \
              xargs grep -L "options\.components\." 2>/dev/null | wc -l)

if [[ $bad_options -eq 0 ]]; then
    echo -e "  ${GREEN}✓ All options use 'components.*' namespace${NC}"
else
    echo -e "  ${YELLOW}⚠ $bad_options file(s) with non-standard option naming${NC}"
fi

# Summary
echo ""
echo "================================================"
echo -e "${BLUE}📋 Summary${NC}"
echo "  Components validated: $total_files files"

if $syntax_valid && [[ $bad_options -eq 0 ]]; then
    echo -e "${GREEN}🎉 All components are valid and well-structured!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️ Some issues found - see details above${NC}"
    exit 1
fi