#!/usr/bin/env bash
set -e

# Default to "src" directory if not provided
TARGET_DIR=${2:-"src"}
RELEASE_TAG=$1

if [ -z "$RELEASE_TAG" ]; then
    echo "Error: No release tag provided."
    echo "Usage: ./prepare.sh <tag> [target_dir]"
    exit 1
fi

# Clean and create target directory
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

echo "Downloading source for tag ${RELEASE_TAG} into ${TARGET_DIR}..."

# Download and extract into the target directory
curl -fLs "https://github.com/5rahim/seanime/archive/refs/tags/${RELEASE_TAG}.tar.gz" \
  | tar -xz --strip-components=1 -C "$TARGET_DIR"

echo "Source code prepared in ${TARGET_DIR}."