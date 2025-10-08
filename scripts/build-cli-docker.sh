#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/api/bin"
IMAGE_TAG="vercel-rust-cli:build"

mkdir -p "$OUT_DIR"

# Build the Docker image that compiles the CLI for musl
DOCKER_BUILDKIT=1 docker build -f "$ROOT_DIR/docker/cli.Dockerfile" -t "$IMAGE_TAG" "$ROOT_DIR"

# Create a container and copy the compiled binary out
CID=$(docker create "$IMAGE_TAG" /bin/sh)
trap 'docker rm -f "$CID" >/dev/null 2>&1 || true' EXIT

docker cp "$CID:/cli" "$OUT_DIR/cli"
chmod +x "$OUT_DIR/cli"

echo "Exported Linux musl binary -> $OUT_DIR/cli"