#!/usr/bin/env bash
set -euo pipefail

BUILD_TYPE=${BUILD_TYPE:-}
LATEST_RELEASE=${LATEST_RELEASE:-}
REPO=${REPO_INPUT:-5rahim/seanime}
BRANCH=${BRANCH_INPUT:-main}

if [ "$BUILD_TYPE" = "dev" ]; then
    if [[ ! "$REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
        echo "Invalid repo: $REPO" >&2
        exit 1
    fi

    if [[ "$BRANCH" == -* ]]; then
        echo "Invalid branch: $BRANCH" >&2
        exit 1
    fi

    git check-ref-format --branch "$BRANCH" >/dev/null
    git clone --branch "$BRANCH" --single-branch "https://github.com/${REPO}.git" src
elif [ "$BUILD_TYPE" = "release" ]; then
    ./scripts/prepare.sh "$LATEST_RELEASE" src
else
    echo "Invalid build type: $BUILD_TYPE" >&2
    exit 1
fi
