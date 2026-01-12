#!/bin/sh

set -eu

# Configuration from GitHub Actions workflow
REGISTRY="${REGISTRY:-ghcr.io}"
REPOSITORY_OWNER="${REPOSITORY_OWNER:-$(git config --get remote.origin.url | sed -En 's#^.*(/|:)([^/:]*)/[^/]*\.git$#\2#p')}"
REPOSITORY_NAME="${REPOSITORY_NAME:-yawsldocker}"
IMAGE_NAME="${IMAGE_NAME:-${REGISTRY}/${REPOSITORY_OWNER}/${REPOSITORY_NAME}}"
FLAVOR="${FLAVOR:-alpine}"
VERSION="${VERSION:-3.23}"

# Construct full image name with flavor
FULL_IMAGE_NAME="${IMAGE_NAME}-${FLAVOR}"

echo "Building Docker image: ${FULL_IMAGE_NAME}"
echo "Version: ${VERSION}"
echo "Flavor: ${FLAVOR}"
echo ""

# Build the image with nerdctl
buildctl build \
    --frontend dockerfile.v0 \
    --local context=. \
    --local dockerfile=. \
    --output type=image,name="${FULL_IMAGE_NAME}:${VERSION}",push=false \
    --opt platform=linux/amd64 \
    --opt build-arg:ALPINE_VERSION="${VERSION}" \
    --opt label:org.opencontainers.image.description="WSL Custom Root FS - ${FLAVOR}" \
    --opt label:org.opencontainers.image.flavor="${FLAVOR}" \
    --opt label:org.opencontainers.image.version="${VERSION}" \
    --opt label:org.opencontainers.image.source="https://github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}" \
    --opt label:com.kaweezle.wsl.rootfs.uid="1000" \
    --opt label:com.kaweezle.wsl.rootfs.username="${FLAVOR}" \
    --opt label:com.kaweezle.wsl.rootfs.configured="true"

echo ""
echo "Build completed successfully!"
echo "Image tags:"
echo "  - ${FULL_IMAGE_NAME}:${VERSION}"
echo "  - ${FULL_IMAGE_NAME}:latest"
