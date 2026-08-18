#!/bin/sh
set -eu

: "${BUNDLE_ID:?Set BUNDLE_ID, for example com.yourname.CatchUp}"

if [ "$BUNDLE_ID" = "com.example.CatchUp" ]; then
  echo "Choose a unique BUNDLE_ID instead of com.example.CatchUp" >&2
  exit 1
fi

find project.yml CatchUp Extensions -type f \( -name '*.yml' -o -name '*.swift' -o -name '*.entitlements' \) -print0 |
  xargs -0 sed -i.bak \
    -e "s/com\.example\.CatchUp\.Monitor/${BUNDLE_ID}.Monitor/g" \
    -e "s/com\.example\.CatchUp/${BUNDLE_ID}/g" \
    -e "s/group\.com\.example\.CatchUp/group.${BUNDLE_ID}/g"
rm -f project.yml.bak
find CatchUp Extensions -name '*.bak' -delete

echo "Configured Catch Up with bundle ID $BUNDLE_ID"

