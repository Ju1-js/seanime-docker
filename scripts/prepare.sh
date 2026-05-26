#!/usr/bin/env bash
set -euo pipefail

# Default to "src" directory if not provided
TARGET_DIR=${2:-"src"}
RELEASE_TAG=${1:-}

if [ -z "$RELEASE_TAG" ]; then
    echo "Error: No release tag provided."
    echo "Usage: ./prepare.sh <tag> [target_dir]"
    exit 1
fi

if [[ ! "$RELEASE_TAG" =~ ^[A-Za-z0-9._/-]+$ ]] || [[ "$RELEASE_TAG" == -* ]] || [[ "$RELEASE_TAG" == *..* ]] || [[ "$RELEASE_TAG" == */ ]] || [[ "$RELEASE_TAG" == *//* ]]; then
    echo "Error: Invalid release tag."
    exit 1
fi

if [[ -z "$TARGET_DIR" || ! "$TARGET_DIR" =~ ^[A-Za-z0-9._/-]+$ || "$TARGET_DIR" = /* || "$TARGET_DIR" = "." || "$TARGET_DIR" = *..* || "$TARGET_DIR" == -* || "$TARGET_DIR" == */ || "$TARGET_DIR" == *//* ]]; then
    echo "Error: Target directory must be a safe relative path."
    exit 1
fi

BASE_DIR=$(pwd -P)
TARGET_PARENT=$(dirname -- "$TARGET_DIR")
TARGET_NAME=$(basename -- "$TARGET_DIR")

if [[ "$TARGET_NAME" = "." || "$TARGET_NAME" = ".." ]]; then
    echo "Error: Target directory must name a directory under the workspace."
    exit 1
fi

mkdir -p -- "$TARGET_PARENT"
TARGET_PARENT_REAL=$(cd "$TARGET_PARENT" && pwd -P)
TARGET_PATH="${TARGET_PARENT_REAL}/${TARGET_NAME}"

case "$TARGET_PATH" in
    "$BASE_DIR"/*) ;;
    *)
        echo "Error: Target directory resolves outside the workspace."
        exit 1
        ;;
esac

# Clean and create target directory
rm -rf -- "$TARGET_PATH"
mkdir -p -- "$TARGET_PATH"

echo "Downloading source for tag ${RELEASE_TAG} into ${TARGET_PATH}..."

# Download and extract into the target directory
curl -fLs "https://github.com/5rahim/seanime/archive/refs/tags/${RELEASE_TAG}.tar.gz" \
  | tar -xz --strip-components=1 -C "$TARGET_PATH"

echo "Source code prepared in ${TARGET_PATH}."
