#!/bin/sh
# Builds the two release packages in dist/ from cstrike/ (common files) and bin/<arch>/cstrike/ (plugin + .vdf):
#   dist/mani_admin_plugin_<version>_css_linux_32bit.zip and ..._64bit.zip, each one a ready-to-copy cstrike/ folder
set -e
cd "$(dirname "$0")/.."
VERSION=$(sed -n 's/^#define COMMON_CORE "\(.*\)"/\1/p' src/mani_main.h | tr -d '\r')
mkdir -p dist
for arch in 32bit 64bit; do
	tmp=$(mktemp -d)
	cp -a cstrike "$tmp/"
	cp -a "bin/${arch%bit}-bit/cstrike/." "$tmp/cstrike/"
	zip="dist/mani_admin_plugin_${VERSION}_css_linux_${arch}.zip"
	rm -f "$zip"
	(cd "$tmp" && python3 -m zipfile -c "$OLDPWD/$zip" cstrike)
	rm -rf "$tmp"
	echo "$zip"
done
