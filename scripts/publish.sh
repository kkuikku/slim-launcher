#!/usr/bin/env bash
# First-time publish: create github.com/kkuikku/slim-launcher, push, and attach the
# .plasmoid to a release. Needs the GitHub CLI signed in: gh auth login
set -euo pipefail
cd "$(dirname "$0")/.."
REPO=kkuikku/slim-launcher
VERSION=$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Version"])')

gh auth status >/dev/null || { echo "Run: gh auth login"; exit 1; }
FILE=$(./scripts/build.sh)

if [ ! -d .git ]; then
    git init -q -b main
    git add -A
    git commit -q -m "Slim Launcher $VERSION" \
        -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Czu7sccmXmkrzZ3biZXhfX"
fi
if ! gh repo view "$REPO" >/dev/null 2>&1; then
    gh repo create "$REPO" --public --source=. --remote=origin --push \
        --description "A slimmer Kickoff application launcher for KDE Plasma 6"
else
    git push -u origin main
fi
gh release create "v$VERSION" "$FILE" --repo "$REPO" --title "Slim Launcher $VERSION" \
    --notes "See CHANGELOG.md"
echo "Published: https://github.com/$REPO"
