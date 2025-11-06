#!/usr/bin/env bash

set -e
cd "$(dirname "$0")"/../

RELEASE_TAG=$1

# Download the source code as a .tar.gz archive, which is much faster than cloning
echo "Downloading source for tag ${RELEASE_TAG}..."
curl -Ls "https://github.com/5rahim/seanime/archive/refs/tags/${RELEASE_TAG}.tar.gz" | tar -xz --strip-components=1

echo "Source code prepared."