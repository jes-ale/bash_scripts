#!/bin/bash
set -euo pipefail

# Check if both arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <target_directory> <output_directory>"
    exit 1
fi

TARGET_DIR="$1"
OUTPUT_DIR="$2"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${TIMESTAMP}"

# Validate directories
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Output directory '$OUTPUT_DIR' does not exist."
    exit 1
fi

# Create backup with integrity verification
echo "Creating backup of '$TARGET_DIR'..."
tar -cvpf - -C "$(dirname "$TARGET_DIR")" "$(basename "$TARGET_DIR")" | \
gzip -9 > "${OUTPUT_DIR}/${BACKUP_NAME}.tar.gz"

# Generate verification checksums
echo "Generating verification checksums..."
cd "$OUTPUT_DIR"
sha256sum "${BACKUP_NAME}.tar.gz" > "${BACKUP_NAME}.sha256"
md5sum "${BACKUP_NAME}.tar.gz" > "${BACKUP_NAME}.md5"

# Create file manifest for additional verification
echo "Creating file manifest..."
tar -tzf "${BACKUP_NAME}.tar.gz" | sort > "${BACKUP_NAME}.manifest"

echo "Backup completed successfully:"
echo "Archive: ${OUTPUT_DIR}/${BACKUP_NAME}.tar.gz"
echo "Checksums: ${BACKUP_NAME}.sha256 and ${BACKUP_NAME}.md5"
echo "Manifest: ${BACKUP_NAME}.manifest"

# Verification step
echo "Verifying backup integrity..."
sha256sum -c "${BACKUP_NAME}.sha256" && \
echo "SHA256 verification: PASSED" || \
(echo "SHA256 verification: FAILED" && exit 1)
