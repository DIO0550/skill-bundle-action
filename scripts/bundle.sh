#!/usr/bin/env bash
# プラグインを zip 化する。git 管理下のファイル（HEAD 時点）だけを含める。
set -euo pipefail

plugin_path="${INPUT_PLUGIN_PATH:-.}"
skills_path="${INPUT_SKILLS_PATH:-skills}"
out_dir="$(mkdir -p "${INPUT_OUTPUT_DIR:-dist}" && cd "${INPUT_OUTPUT_DIR:-dist}" && pwd)"

if [[ ! -d "$plugin_path" ]]; then
  echo "::error::plugin-path '$plugin_path' が見つかりません"
  exit 1
fi
cd "$plugin_path"
prefix="$(git rev-parse --show-prefix)"   # リポジトリルートからの相対パス（末尾 /）
rev="$(git rev-parse HEAD)"
repo_root="$(git rev-parse --show-toplevel)"

manifest=".claude-plugin/plugin.json"
manifest_field() {
  [[ -f "$manifest" ]] && jq -r --arg k "$1" '.[$k] // empty' "$manifest" || true
}

name="${INPUT_NAME:-}"
[[ -z "$name" ]] && name="$(manifest_field name)"
[[ -z "$name" ]] && name="${REPO_NAME:-$(basename "$repo_root")}"

version="${INPUT_VERSION:-}"
[[ -z "$version" ]] && version="$(manifest_field version)"

tag="${INPUT_TAG:-}"
if [[ -z "$tag" ]]; then
  if [[ -n "$version" ]]; then
    tag="v${version#v}"
  else
    tag="build-$(date -u +%Y%m%d)-$(git rev-parse --short HEAD)"
  fi
fi

suffix="${version:+-${version#v}}"
[[ -z "$suffix" ]] && suffix="-${tag}"

# exclude を pathspec に変換
excludes=()
while IFS= read -r line; do
  line="$(echo "$line" | xargs)"
  [[ -n "$line" ]] && excludes+=(":(exclude)${line}")
done <<< "${INPUT_EXCLUDE:-}"

# $1: plugin-path からの相対ディレクトリ ("" ならルート), $2: zip 内のトップフォルダ名, $3: 出力ファイル
archive() {
  local dir="$1" top="$2" out="$3"
  local tree="${rev}:${prefix}${dir:+${dir%/}}"
  git -C "$repo_root" archive --format=zip --prefix="${top}/" -o "$out" "$tree" -- . "${excludes[@]}"
  echo "created: $out"
}

plugin_zip="${out_dir}/${name}${suffix}.zip"
archive "" "$name" "$plugin_zip"

skills_zip=""
if git cat-file -e "${rev}:${prefix}${skills_path%/}" 2>/dev/null; then
  skills_zip="${out_dir}/${name}-skills${suffix}.zip"
  archive "$skills_path" "skills" "$skills_zip"

  if [[ "${INPUT_PER_SKILL:-false}" == "true" ]]; then
    while IFS= read -r skill; do
      archive "${skills_path%/}/${skill}" "$skill" "${out_dir}/${skill}.zip"
    done < <(git -C "$repo_root" ls-tree -d --name-only "${rev}:${prefix}${skills_path%/}")
  fi
else
  echo "skills ディレクトリ '${skills_path}' が無いため skills zip はスキップします"
fi

{
  echo "tag=$tag"
  echo "version=$version"
  echo "plugin-zip=$plugin_zip"
  echo "skills-zip=$skills_zip"
  echo "assets-dir=$out_dir"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
