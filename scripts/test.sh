#!/usr/bin/env bash
# Lint the QML against the installed Qt/Plasma modules, run the widget in
# plasmoidviewer, and save the log and a screenshot to test-output/.
set -uo pipefail
cd "$(dirname "$0")/.."
ID=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')
OUT=test-output; mkdir -p "$OUT"; rm -f "$OUT"/*

QMLLINT=$(command -v qmllint6 || command -v qmllint || echo /usr/lib/qt6/bin/qmllint)
echo "== qmllint ($QMLLINT)" | tee "$OUT/qmllint.txt"
for f in package/contents/ui/*.qml package/contents/config/*.qml; do
    "$QMLLINT" -I /usr/lib/qt6/qml -I package/contents/ui "$f" >>"$OUT/qmllint.txt" 2>&1
done
grep -cE "^(Error|Warning)" "$OUT/qmllint.txt" | xargs echo "lint messages:"

echo "== installing"
./scripts/install.sh >"$OUT/install.txt" 2>&1 || { cat "$OUT/install.txt"; exit 1; }

echo "== plasmoidviewer (12 s)"
timeout 12 plasmoidviewer -a "$ID" >"$OUT/plasmoidviewer.txt" 2>&1 &
sleep 7
spectacle -b -n -a -o "$OUT/screenshot.png" 2>/dev/null || echo "screenshot failed (spectacle)"
wait
grep -iE "slimlauncher|qml|error|warning" "$OUT/plasmoidviewer.txt" >"$OUT/plasmoidviewer-filtered.txt" || true

echo "== results in $OUT/:"
ls -1 "$OUT"
echo "Send qmllint.txt, plasmoidviewer-filtered.txt and screenshot.png"
