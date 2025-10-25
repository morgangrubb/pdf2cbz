# PDF to CBZ Converter

A simple Docker-based tool to convert PDF files to CBZ (Comic Book Archive) format.

## What is CBZ?

CBZ is a comic book archive format that is simply a ZIP file containing image files (typically JPEG or PNG). This format is widely supported by comic book readers and e-reading applications.

## Features

- Convert single PDF files to CBZ
- Batch convert all PDFs in a directory
- Convert PDFs matching a glob pattern
- Configurable image quality (default 150 DPI)
- Lightweight Alpine Linux-based Docker image

## Prerequisites

- Docker installed on your system

## Building the Docker Image

```bash
docker build -t pdf2cbz .
```

## Usage

### Basic Syntax

```bash
docker run --rm -v /path/to/pdfs:/work pdf2cbz [FILE|DIRECTORY|GLOB]
```

The `-v` flag mounts your local directory containing PDFs into the container's `/work` directory.

### Examples

#### Convert a Single PDF

```bash
docker run --rm -v $(pwd):/work pdf2cbz mycomic.pdf
```

This will create `mycomic.cbz` in the same directory.

#### Convert with Custom DPI Quality

```bash
# High quality (larger file size)
docker run --rm -v $(pwd):/work -e PDF2CBZ_DPI=300 pdf2cbz mycomic.pdf

# Low quality (smaller file size)
docker run --rm -v $(pwd):/work -e PDF2CBZ_DPI=72 pdf2cbz mycomic.pdf

# Very high quality
docker run --rm -v $(pwd):/work -e PDF2CBZ_DPI=600 pdf2cbz mycomic.pdf
```

#### Convert All PDFs in Current Directory

```bash
docker run --rm -v $(pwd):/work pdf2cbz .
```

or

```bash
docker run --rm -v $(pwd):/work pdf2cbz "*.pdf"
```

#### Convert All PDFs in a Specific Directory

```bash
docker run --rm -v /home/user/comics:/work pdf2cbz /work
```

#### Convert PDFs Matching a Pattern

```bash
docker run --rm -v $(pwd):/work pdf2cbz "volume*.pdf"
```

### No Arguments - Show Help

```bash
docker run --rm pdf2cbz
```

This displays usage information and examples.

## Skipping Existing Files

By default, the script will skip PDFs that already have a corresponding CBZ file. This prevents unnecessary re-processing and saves time during batch conversions.

To force overwrite existing CBZ files, use the `PDF2CBZ_FORCE` environment variable:

```bash
# Force overwrite existing CBZ files
docker run --rm -v $(pwd):/work -e PDF2CBZ_FORCE=true pdf2cbz mycomic.pdf

# Or set to 1
docker run --rm -v $(pwd):/work -e PDF2CBZ_FORCE=1 pdf2cbz "*.pdf"
```

## Image Quality Configuration

The output image quality can be configured using the `PDF2CBZ_DPI` environment variable:

- **72 DPI**: Low quality, smallest file size (suitable for quick previews)
- **150 DPI**: Medium quality, balanced size (**default**)
- **300 DPI**: High quality, larger file size (recommended for printing)
- **600 DPI**: Very high quality, very large file size (professional use)

### Examples

```bash
# Default (150 DPI)
docker run --rm -v $(pwd):/work pdf2cbz mycomic.pdf

# High quality
docker run --rm -v $(pwd):/work -e PDF2CBZ_DPI=300 pdf2cbz mycomic.pdf

# Low quality (smaller files)
docker run --rm -v $(pwd):/work -e PDF2CBZ_DPI=72 pdf2cbz "*.pdf"

# Combine options: high quality and force overwrite
docker run --rm -v $(pwd):/work -e PDF2CBZ_DPI=300 -e PDF2CBZ_FORCE=true pdf2cbz "*.pdf"
```

## How It Works

1. **PDF Extraction**: Uses `pdftoppm` from poppler-utils to extract each page of the PDF as a JPEG image at the specified DPI (default 150)
2. **Archive Creation**: Uses `zip` to package all extracted images into a single archive file
3. **Rename**: The archive is renamed with a `.cbz` extension

## Output

- CBZ files are created in the same directory as the source PDF files
- Output filename is the same as the input PDF but with `.cbz` extension
- Original PDF files are not modified or deleted

## Creating a Convenient Alias

To make the command easier to use, you can create a shell alias:

### Bash/Zsh

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias pdf2cbz='docker run --rm -v $(pwd):/work pdf2cbz'

# Or with custom default DPI:
alias pdf2cbz='docker run --rm -v $(pwd):/work -e PDF2CBZ_DPI=300 pdf2cbz'

# Or with force overwrite enabled:
alias pdf2cbz='docker run --rm -v $(pwd):/work -e PDF2CBZ_FORCE=true pdf2cbz'
```

Then reload your shell configuration:

```bash
source ~/.bashrc  # or source ~/.zshrc
```

Now you can simply run:

```bash
pdf2cbz mycomic.pdf
```

## Script-Only Usage (Without Docker)

If you prefer to run the script directly without Docker, you can use `pdf2cbz.sh` on any system with bash, poppler-utils, and zip installed:

### Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get install poppler-utils zip
```

**macOS:**
```bash
brew install poppler
```

**Alpine Linux:**
```bash
apk add poppler-utils zip bash
```

### Run the Script

```bash
chmod +x pdf2cbz.sh
./pdf2cbz.sh mycomic.pdf

# With custom DPI
PDF2CBZ_DPI=300 ./pdf2cbz.sh mycomic.pdf
```

## Technical Details

- **Base Image**: Alpine Linux (minimal footprint)
- **Default Image Resolution**: 150 DPI (configurable via `PDF2CBZ_DPI` environment variable)
- **Image Format**: JPEG
- **Overwrite Behavior**: Skips existing CBZ files by default (override with `PDF2CBZ_FORCE=true`)
- **Dependencies**: 
  - poppler-utils (provides `pdftoppm`)
  - zip
  - bash

## Troubleshooting

### Permission Errors

If you encounter permission errors when running the Docker container, ensure the mounted directory has appropriate permissions:

```bash
chmod 755 /path/to/pdfs
```

### Large PDF Files

For very large PDF files with many pages, the conversion may take some time and require significant disk space for temporary image files. The script cleans up temporary files automatically after conversion.

### No Output Files

If no CBZ files are created, check:
- The input files are valid PDF files
- The PDF files contain actual pages (not empty)
- You have write permissions in the output directory

## License

This project is provided as-is for public use.

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.