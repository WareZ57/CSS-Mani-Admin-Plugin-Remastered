#!/bin/sh
# Fetches the SDKs into deps/: hl2sdk (css branch: headers and libraries for x86 and x86_64)
# and Metamod:Source 1.12 (SourceHook)
set -e
cd "$(dirname "$0")/.."
mkdir -p deps
[ -d deps/hl2sdk-css ] || git clone --depth 1 -b css https://github.com/alliedmodders/hl2sdk deps/hl2sdk-css
[ -d deps/mmsource ] || git clone --depth 1 -b 1.12-dev https://github.com/alliedmodders/metamod-source deps/mmsource
