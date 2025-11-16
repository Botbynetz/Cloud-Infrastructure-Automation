#!/bin/bash
# Script to package Lambda function for deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAMBDA_DIR="$SCRIPT_DIR"
OUTPUT_FILE="$LAMBDA_DIR/rds_snapshot_copy.zip"

echo "Packaging Lambda function..."

# Remove old package if exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "Removing old package..."
    rm "$OUTPUT_FILE"
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Copy Lambda code
cp "$LAMBDA_DIR/index.py" "$TEMP_DIR/"

# Install dependencies if requirements.txt exists
if [ -f "$LAMBDA_DIR/requirements.txt" ]; then
    echo "Installing dependencies..."
    pip install -r "$LAMBDA_DIR/requirements.txt" -t "$TEMP_DIR/" --quiet
fi

# Create zip package
echo "Creating zip package..."
cd "$TEMP_DIR"
zip -r "$OUTPUT_FILE" . -q

# Cleanup
cd "$SCRIPT_DIR"
rm -rf "$TEMP_DIR"

echo "✓ Lambda package created: $OUTPUT_FILE"
echo "  Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
