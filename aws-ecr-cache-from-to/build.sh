#!/usr/bin/env bash

set -euxo pipefail

REPOSITORY="$(terraform output -raw repository_url)"

BUILDER_NAME="ecr-cache-builder-$(date +%Y%m%dT%H%M%S)"
if ! docker buildx inspect "$BUILDER_NAME" > /dev/null 2>&1; then
  docker buildx create --name "$BUILDER_NAME" --driver docker-container --bootstrap --use
else
  docker buildx use "$BUILDER_NAME"
fi
trap 'docker buildx rm "$BUILDER_NAME"' EXIT

CACHE_TAG="${REPOSITORY}:cache"
IMAGE_TAG="${REPOSITORY}:latest"

docker buildx build \
  --builder "$BUILDER_NAME" \
  --tag "$IMAGE_TAG" \
  --provenance=false \
  --cache-to "type=registry,ref=${CACHE_TAG},mode=max,image-manifest=true" \
  --cache-from "type=registry,ref=${CACHE_TAG}" \
  --push \
  .

docker buildx prune --builder "$BUILDER_NAME" --all --force

docker buildx build \
  --builder "$BUILDER_NAME" \
  --tag "$IMAGE_TAG" \
  --provenance=false \
  --cache-to "type=registry,ref=${CACHE_TAG},mode=max,image-manifest=true" \
  --cache-from "type=registry,ref=${CACHE_TAG}" \
  --push \
  .

docker run --pull=always --rm "$IMAGE_TAG"
