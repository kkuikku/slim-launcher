#!/usr/bin/env bash
# Build dist/slim-launcher-<version>.plasmoid from package/
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')
mkdir -p dist
OUT="dist/slim-launcher-$VERSION.plasmoid"
rm -f "$OUT"
(cd package && zip -qr "../$OUT" . -x '*.qmlc' -x '*~')
echo "$OUT"
