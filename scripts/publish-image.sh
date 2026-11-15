#!/usr/bin/env bash
set -euo pipefail

: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME to your Docker Hub account}"
IMAGE_TAG="${IMAGE_TAG:-$(git rev-parse --short=12 HEAD)}"
PLATFORMS="${PLATFORMS:-linux/amd64}"

if [[ "${IMAGE_TAG}" == "latest" ]]; then
  echo "The assignment requires a versioned image tag; 'latest' is not allowed." >&2
  exit 1
fi

IMAGE="docker.io/${DOCKERHUB_USERNAME}/hello-api:${IMAGE_TAG}"
docker buildx build --platform "${PLATFORMS}" --tag "${IMAGE}" --push .

printf 'Published %s\n' "${IMAGE}"
printf 'Docker Hub: https://hub.docker.com/r/%s/hello-api\n' "${DOCKERHUB_USERNAME}"
