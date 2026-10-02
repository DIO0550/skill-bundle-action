#!/usr/bin/env bash
# zip を GitHub Release に添付する。
set -euo pipefail

shopt -s nullglob
assets=("${ASSETS_DIR}"/*.zip)
if (( ${#assets[@]} == 0 )); then
  echo "::error::添付する zip がありません: ${ASSETS_DIR}"
  exit 1
fi

if gh release view "$TAG" >/dev/null 2>&1; then
  if [[ "${SKIP_IF_EXISTS}" == "true" ]]; then
    echo "Release '$TAG' は既に存在するためスキップします（バージョンを上げると新しい Release が作られます）"
    echo "released=false" >> "$GITHUB_OUTPUT"
    exit 0
  fi
  gh release upload "$TAG" "${assets[@]}" --clobber
else
  flags=(--target "$TARGET" --title "$TAG" --generate-notes)
  [[ "${PRERELEASE}" == "true" ]] && flags+=(--prerelease)
  gh release create "$TAG" "${assets[@]}" "${flags[@]}"
fi
echo "released=true" >> "$GITHUB_OUTPUT"
