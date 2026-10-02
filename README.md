# skill-bundle-action

Claude Code プラグインを zip 化して GitHub Release に添付する GitHub Action です。
main への push ごとに次の zip を作り、Release の asset として公開します。

| ファイル | 中身 |
| --- | --- |
| `<name>-<version>.zip` | プラグイン全体（`<name>/` 配下に展開される） |
| `<name>-skills-<version>.zip` | `skills/` ディレクトリだけ |
| `<skill>.zip` | skill 単体（`per-skill: true` のとき。claude.ai の「スキルをアップロード」にそのまま使える） |

zip には git 管理下のファイル（push されたコミット時点）だけが入ります。
未追跡ファイルや `.gitignore` 対象は含まれず、実行権限は保持されます。

## 使い方

プラグインのリポジトリに `.github/workflows/release-plugin.yml` を追加します。

```yaml
name: Release plugin

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DIO0550/skill-bundle-action@v1
        with:
          per-skill: true
```

### バージョンとタグ

- `name` / `version` は `.claude-plugin/plugin.json` から読みます。
- タグは `v<version>` です。同じタグの Release が既にあればスキップするので、
  **`plugin.json` の `version` を上げたときだけ新しい Release ができます**。
  毎回上書きしたい場合は `skip-if-exists: false` にしてください。
- `version` が無い場合は `build-<日付>-<短縮SHA>` のタグで毎回 Release を作ります。

## Inputs

| 名前 | 既定値 | 説明 |
| --- | --- | --- |
| `plugin-path` | `.` | プラグインのルート（リポジトリルートからの相対パス） |
| `skills-path` | `skills` | skills ディレクトリ（`plugin-path` からの相対パス）。無ければ skills zip は作らない |
| `name` | plugin.json の `name` → リポジトリ名 | zip ファイル名とトップフォルダ名 |
| `version` | plugin.json の `version` | バージョン |
| `tag` | `v<version>` | リリースタグ |
| `per-skill` | `false` | skill ごとの zip も作る |
| `exclude` | `.github` | 除外するパス（`plugin-path` からの相対、改行区切り） |
| `create-release` | `true` | `false` なら zip を作るだけ |
| `skip-if-exists` | `true` | 同じタグの Release があればスキップ（`false` なら asset を上書き） |
| `prerelease` | `false` | prerelease として作成 |
| `output-dir` | `dist` | zip の出力先 |
| `github-token` | `${{ github.token }}` | `contents: write` 権限が必要 |

## Outputs

| 名前 | 説明 |
| --- | --- |
| `tag` | 使用したタグ |
| `version` | 使用したバージョン |
| `plugin-zip` | プラグイン全体 zip のパス |
| `skills-zip` | skills zip のパス（無ければ空） |
| `released` | Release を作成・更新したら `true` |

## 例: マーケットプレイス配下の 1 プラグインだけを対象にする

```yaml
      - uses: DIO0550/skill-bundle-action@v1
        with:
          plugin-path: plugins/my-plugin
```
