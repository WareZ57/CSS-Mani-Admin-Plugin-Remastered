#!/bin/sh
# Builds both plugins in AlliedModders' build container (Docker):
#   ./build.sh            -> build/x86/mani_admin_plugin_i486.so and build/x86_64/mani_admin_plugin_x64.so
#   ./build.sh x86_64     -> one architecture only (x86 or x86_64)
set -e
cd "$(dirname "$0")"
[ -d deps/hl2sdk-css ] && [ -d deps/mmsource ] || tools/fetch_deps.sh
IMAGE=ghcr.io/alliedmodders/build-containers/debian11-clang22:latest
for arch in ${1:-x86 x86_64}; do
	docker run --rm -u "$(id -u):$(id -g)" -v "$PWD":/work -w /work "$IMAGE" \
		make ARCH="$arch" -j"$(nproc)"
done
