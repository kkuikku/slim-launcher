#!/usr/bin/env bash
# Install or upgrade the widget from package/
set -euo pipefail
cd "$(dirname "$0")/.."
ID=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')
if kpackagetool6 -t Plasma/Applet -s "$ID" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u package
else
    kpackagetool6 -t Plasma/Applet -i package
fi
echo "Done. Apply to the panel with: systemctl --user restart plasma-plasmashell.service"
