#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DPI="${PDF2CBZ_DPI:-150}"  # Default to 150 DPI, configurable via environment variable
FORCE="${PDF2CBZ_FORCE:-false}"  # Default to not overwriting existing files

# Function to print usage information
print_usage() {
    cat << EOF
PDF to CBZ Converter
====================

Usage: pdf2cbz.sh [FILE|DIRECTORY|GLOB]

This tool converts PDF files to CBZ (Comic Book Archive) format.

Arguments:
  FILE       Convert a single PDF file to CBZ
  DIRECTORY  Convert all PDF files in the specified directory
  GLOB       Convert all PDF files matching the glob pattern (e.g., "*.pdf" or "books/*.pdf")

Environment Variables:
  PDF2CBZ_DPI    Image quality in DPI (default: 150)
                 Common values: 72 (low), 150 (medium), 300 (high), 600 (very high)
  PDF2CBZ_FORCE  Overwrite existing CBZ files (default: false)
                 Set to "true" or "1" to enable

Examples:
  pdf2cbz.sh mycomic.pdf              # Convert single file
  pdf2cbz.sh /path/to/pdfs/           # Convert all PDFs in directory
  pdf2cbz.sh "*.pdf"                  # Convert all PDFs in current directory
  pdf2cbz.sh "comics/*.pdf"           # Convert all PDFs matching pattern

  PDF2CBZ_DPI=300 pdf2cbz.sh mycomic.pdf           # Convert with high quality
  PDF2CBZ_DPI=72 pdf2cbz.sh "*.pdf"                # Convert with low quality (smaller files)
  PDF2CBZ_FORCE=true pdf2cbz.sh mycomic.pdf        # Force overwrite existing CBZ

Output:
  CBZ files are created in the same directory as the source PDF files.
  The output filename will be the same as the input PDF but with .cbz extension.
  Current DPI setting: $DPI

Requirements:
  - poppler-utils (for pdftoppm)
  - zip

EOF
}

# Function to convert a single PDF to CBZ
convert_pdf_to_cbz() {
    local pdf_file="$1"

    # Check if file exists
    if [ ! -f "$pdf_file" ]; then
        echo -e "${RED}Error: File not found: $pdf_file${NC}" >&2
        return 1
    fi

    # Check if it's a PDF file
    if [[ ! "$pdf_file" =~ \.pdf$ ]] && [[ ! "$pdf_file" =~ \.PDF$ ]]; then
        echo -e "${YELLOW}Warning: Skipping non-PDF file: $pdf_file${NC}" >&2
        return 1
    fi

    # Get the base name without extension
    local base_name="${pdf_file%.pdf}"
    base_name="${base_name%.PDF}"
    local cbz_file="${base_name}.cbz"

    # Check if CBZ file already exists and force flag is not set
    if [ -f "$cbz_file" ] && [ "$FORCE" != "true" ] && [ "$FORCE" != "1" ]; then
        echo -e "${YELLOW}Skipping: $pdf_file (CBZ already exists: $cbz_file)${NC}"
        echo -e "${YELLOW}  Use PDF2CBZ_FORCE=true to overwrite existing files${NC}"
        return 0
    fi

    echo -e "${GREEN}Converting: $pdf_file (DPI: $DPI)${NC}"

    # Create a temporary directory for extracted images
    local temp_dir=$(mktemp -d)

    # Extract PDF pages as images
    echo "  Extracting pages at ${DPI} DPI..."
    if ! pdftoppm -jpeg -r "$DPI" "$pdf_file" "$temp_dir/page" 2>&1; then
        echo -e "${RED}Error: Failed to extract pages from $pdf_file${NC}" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Check if any images were created
    local image_count=$(ls -1 "$temp_dir"/*.jpg 2>/dev/null | wc -l)
    if [ "$image_count" -eq 0 ]; then
        echo -e "${RED}Error: No pages extracted from $pdf_file${NC}" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Create CBZ file (which is just a ZIP file with images)
    echo "  Creating CBZ archive..."
    cd "$temp_dir"
    if ! zip -q -r "$cbz_file" *.jpg; then
        echo -e "${RED}Error: Failed to create CBZ file${NC}" >&2
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    cd - > /dev/null

    # Move the CBZ file to the original location
    mv "$temp_dir"/*.cbz "$cbz_file"

    # Clean up
    rm -rf "$temp_dir"

    echo -e "${GREEN}  ✓ Created: $cbz_file${NC}"
    return 0
}

# Function to convert all PDFs in a directory
convert_directory() {
    local dir="$1"

    # Check if directory exists
    if [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Directory not found: $dir${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}Converting all PDFs in directory: $dir${NC}"

    local count=0
    local success=0

    # Find all PDF files in the directory
    while IFS= read -r -d '' pdf_file; do
        ((count++))
        if convert_pdf_to_cbz "$pdf_file"; then
            ((success++))
        fi
    done < <(find "$dir" -maxdepth 1 -type f \( -iname "*.pdf" \) -print0)

    if [ "$count" -eq 0 ]; then
        echo -e "${YELLOW}No PDF files found in directory: $dir${NC}"
        exit 0
    fi

    echo ""
    echo -e "${GREEN}Conversion complete: $success/$count files converted successfully${NC}"
}

# Function to convert PDFs matching a glob pattern
convert_glob() {
    local pattern="$1"

    local count=0
    local success=0
    local files=()

    # Expand the glob pattern
    shopt -s nullglob
    for file in $pattern; do
        if [ -f "$file" ]; then
            files+=("$file")
        fi
    done
    shopt -u nullglob

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No files matching pattern: $pattern${NC}"
        exit 0
    fi

    echo -e "${GREEN}Converting ${#files[@]} file(s) matching pattern: $pattern${NC}"

    for pdf_file in "${files[@]}"; do
        ((count++))
        if convert_pdf_to_cbz "$pdf_file"; then
            ((success++))
        fi
    done

    echo ""
    echo -e "${GREEN}Conversion complete: $success/$count files converted successfully${NC}"
}

# Main script logic
main() {
    # Check if no arguments provided
    if [ $# -eq 0 ]; then
        print_usage
        exit 0
    fi

    local input="$1"

    # Check if input is a directory
    if [ -d "$input" ]; then
        convert_directory "$input"
    # Check if input contains glob characters
    elif [[ "$input" == *"*"* ]] || [[ "$input" == *"?"* ]]; then
        convert_glob "$input"
    # Otherwise treat as a single file
    else
        if convert_pdf_to_cbz "$input"; then
            exit 0
        else
            exit 1
        fi
    fi
}

# Run main function
main "$@"
