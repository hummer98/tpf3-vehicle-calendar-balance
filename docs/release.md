# 版の番号と release の手順

## 版の番号

- 置き場所は、リポジトリの直下の `VERSION` の1か所（1行、`1.0.0`）。書式は semver の `MAJOR.MINOR.PATCH`（先頭の 0 なし、接尾辞なし、MINOR と PATCH は 99 まで）。
- 手で書き換えない。`tools/release.py` が上げる。
- `mod.json` の `revision`（整数）は版から決まる: `MAJOR * 10000 + MINOR * 100 + PATCH`（1.0.0 → 10000、1.2.3 → 10203）。`tools/release.py` が `VERSION` と一緒に書き換える。版の順に増えるので、`tools/stage.py` の「アップロード済みより大きい revision」の確認と合う。
- `tests/test_release.py` が、次のときに落ちる。
  - `mod.json` の revision が `VERSION` から決まる値と違う。
  - `CHANGELOG.md` の一番新しい版の節が `VERSION` と違う（手で版を上げた）。最初の release の前は版の節が無いので、比べない。
  - `CHANGELOG.md` に `## [Unreleased]` の節が無い。
- `VERSION` は zip に入らない。この MOD は平常時にログを出さないので、ゲームの中で版を出す所は無い。ゲームに届くのは `mod.json` の revision だけ。

### どの部分を上げるか

| 上げる所 | いつ |
|---|---|
| PATCH | 不具合の修正、文の直し。動き方は変えない |
| MINOR | 機能の追加、動き方の調整 |
| MAJOR | 表示する値の意味が大きく変わるとき |

## CHANGELOG.md

英語、[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) の形。変更は `## [Unreleased]` の下に `### Added` / `### Changed` / `### Fixed` / `### Removed` の見出しで、変更をコミットするときに書きためる。release のときに `tools/release.py` が `## [Unreleased]` を `## [X.Y.Z] - YYYY-MM-DD` にし、その上に空の `## [Unreleased]` を作る。その版の節が、そのまま GitHub の release の本文になる。最初の版（1.0.0）も同じで、中身は `## [Unreleased]` に書いておき、`release.py 1.0.0` で節に変わる。

公開するリポジトリに入る文なので、手元のパスや内部のツールの名前は書かない。

`CHANGELOG.md` は zip に入れない。ゲームの MOD の検証は `.md` を「PC/Mac/Linux でだけ許す（コンソールでは使えなくなる）」拡張子の並びに入れているように見えるため（`tools/package.py` の注記）。変更は GitHub の release と mod.io の変更の欄で伝える。

## tools/release.py

前提: 作業ツリーがコミット済み、`master`（`--branch` で変更）を checkout している、`luajit` と、GitHub に出すなら `gh` がある。

**ゲームが読んでいるフォルダ（`local/mods/` の下）では走らせない。** release はファイルを書き換え、`dist/` を作る。ゲームの起動中に MOD のフォルダが変わるとゲームが落ちることがある。release は開発用の clone で行い、`local/mods/` へはゲームを止めてから取り込む。コミットの作者は git の設定か `GIT_AUTHOR_*` / `GIT_COMMITTER_*`（このツールは何も設定しない）。

```sh
python3 tools/release.py 1.0.0 --dry-run      # 試す（何も書かない）
python3 tools/release.py 1.0.0                # 番号の指定（最初の release はこれ）
python3 tools/release.py patch|minor|major    # 今の版から上げる
python3 tools/release.py ... --local-only     # タグと zip まで（GitHub には出さない）
python3 tools/release.py --github-only        # HEAD のタグの push と GitHub release だけ
```

すること:

1. 確認: 作業ツリー、枝、新しい版（今の版以上で、どのタグ `v*` よりも上。今の版と同じ番号は、そのタグが無いときだけ = 最初の release）、`## [Unreleased]` に中身がある。
2. `VERSION`・`mod.json` の revision・`CHANGELOG.md` を書き、`tools/package.py` と同じ確認（JSON、表紙、Lua のテスト、ツールのテスト）をする。落ちたら書いたファイルを全部戻して止まる。
3. コミット `Release vX.Y.Z` と、注釈付きタグ `vX.Y.Z`。
4. `dist/hummer_vehicle_calendar_balance-vX.Y.Z.zip`（`tools/package.py` と同じ中身。直下にファイル）。
5. リモート `github`（`--remote` で変更）があれば: `git push github HEAD:refs/heads/master`、`git push github refs/tags/vX.Y.Z`、`gh release create vX.Y.Z <zip> --verify-tag --repo <owner/name> --title "Vehicle Last Year Balance at Any Calendar Speed vX.Y.Z" --notes <その版の節>`。
   - 既定が `origin` でないのは、開発用の clone の `origin` が `local/mods/` のコピーを指しているため。
   - push するのはその版のタグだけ。`git push --tags` は使わない（古い履歴のタグを出さないため）。
   - リモートが無いとき、または `--local-only` のときは、zip まで作って止まり、しなかったコマンドを出す。あとで HEAD がタグのコミットにある状態で `--github-only` を走らせると、zip を作り直してタグの push と release だけをする。
   - リモートがあって `gh` が無いときは、何も書く前に止まる。
   - コミットの後にタグが作れなかったときは、出てくる `git tag -a …` を手で実行し、`--github-only` で続ける。
   - タグの後の push か `gh` が失敗したとき（GitHub の master が先に進んでいた、ログインが切れていた等）は、原因を直し、HEAD がタグのコミットにある状態で `--github-only` を走らせる（タグの push と release）。枝は `git push github HEAD:master` で出す。同じ版で cut し直すと、タグがあるので止まる。
   - release の本文では、`CHANGELOG.md` の折り返した行を項目ごとに1行につなげる（GitHub の release の本文は、改行を改行のまま出すことがあるため）。mod.io の変更の欄には `--dry-run` の `notes:` の後の文を写す。

## 最初の公開（1.0.0）

`VERSION` は 1.0.0、revision は 10000 で、1.0.0 の中身は `## [Unreleased]` に書いてある。mod.io にはまだ無い。

1. 開発用の clone で、版・タグ・GitHub release を出す。
   ```sh
   python3 tools/release.py 1.0.0 --dry-run
   python3 tools/release.py 1.0.0
   ```
   mod.io への上げがうまくいくのを見てから GitHub に出したいときは、`--local-only` で出しておき、4 の後に `python3 tools/release.py --github-only` とする。
2. ゲームを止める（`pgrep -f '^\./TransportFever3'` で何も出ないこと）。`local/mods/hummer_vehicle_calendar_balance_1` で、開発用の clone から取り込む。
   ```sh
   git pull --ff-only <開発用の clone> master
   ```
   pull ではタグは来ないが、テストも `stage.py` もタグを見ないので、それでよい。
   そのフォルダがまだ無いときは、`local/mods/` の中で `git clone <開発用の clone> hummer_vehicle_calendar_balance_1` で作る。modId の違う古い写しが残っていれば、同じ recipe を 2 回登録しないよう、どちらか一方だけを有効にする（古い写しを外す前に、それを使っているセーブが無いことを確認する）。
3. 同じ `local/mods/` のコピーで、ステージングに写す。
   ```sh
   python3 tools/stage.py --first-upload
   ```
   `--first-upload` は、`_metadata/mod.io_fileid.txt` がまだ無い（mod.io のページが無い）ときだけ使う。このとき revision は比べない（比べる相手が無い）。
4. ゲームを起動し、MOD hub > My mods > この MOD > Upload。最初のアップロードで mod.io のページができ、ゲームがステージングのコピーに `_metadata/mod.io_fileid.txt` を書く。mod.io の Web のページに `docs/modio_description.md` の説明文を貼る。
5. README の mod.io の URL（英語と日本語の「Install / 導入」の2か所）を、できたページの URL に直してコミットし、`git push github master` で出す。README は zip に入らないので、版は上げず、`## [Unreleased]` にも書かない。

## 更新（1.0.1 など）

1. 変更をコミットするときに、`CHANGELOG.md` の `## [Unreleased]` に書いておく。
2. 開発用の clone で出す。
   ```sh
   python3 tools/release.py patch --dry-run
   python3 tools/release.py patch          # または minor / major / X.Y.Z
   ```
3. ゲームを止めて、`local/mods/` のコピーへ `git pull --ff-only <開発用の clone> master`。
4. `python3 tools/stage.py`（`--first-upload` は付けない）。ステージングのコピーにある `_metadata/mod.io_fileid.txt` を残したまま入れ替える。
   - `stage.py` は、`mod.json` の revision がアップロード済みのもの（ステージングのコピーの `mod.json`）より大きいことを求める。revision は版から決まるので、release を出せば必ず上がる。逆に、release を出さずに直したものは revision が同じなので止まる。文の直しだけでも、mod.io に上げるなら patch を出す。
   - `--keep-revision` は、revision を上げずに mod.io のデータだけを上げ直すとき（同じ版の上げ直し）に限る。
   - `mod.io_fileid.txt` が無いと止まる（2つ目のページができるのを防ぐため）。
5. ゲームの中で MOD hub > My mods > この MOD > Revalidate、変更の欄にその版の節（`--github-only --dry-run` の `notes:` の後の文）を写し、Update。
6. 説明文が変わったら、mod.io の Web のページも直す。README の mod.io の URL は、最初の公開の後は変わらない。

## mod.io の MOD ID の控え
- mod.io の MOD ID は、最初のアップロードのあとにここへ書く（まだ無い）。
- ゲームは、これを `local/staging_area/hummer_vehicle_calendar_balance_1/_metadata/mod.io_fileid.txt` に書く（名前は fileid でも、中身は MOD ID）。`stage.py` が置き直しのたびに引き継ぐ。リポジトリには入れない（zip の `_metadata/` に入ってしまうため）。
- ステージングのコピーが消えたときは、`stage.py --first-upload` で置き直してから、上の番号だけを書いた `mod.io_fileid.txt` をそこへ戻す。戻さずにアップロードすると、mod.io に2つ目のページができる。

## mod.io

- MOD ID: 6552141（2026-11-25 に 1.0.0 を新規に公開）。ゲームが `staging_area/<folder>/_metadata/mod.io_fileid.txt` に書く番号と同じ。次の更新でこの写しが要る。
