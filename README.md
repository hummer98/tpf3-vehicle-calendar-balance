# Vehicle Last Year Balance Follows Calendar Speed (Transport Fever 3)

[日本語は下にあります](#日本語)

**What this mod does:** the **Last Year** balance in the vehicle window and
the **Balance** column on the **Vehicles** tab of the **Statistics** window
sum the last 12 months of the calendar, following the **Calendar Speed**.

## Why

The base game ignores the Calendar Speed for these values: it always sums a
fixed amount of game time, one year (365 days of 4 seconds, about 24 minutes of game time). That is
one calendar year only at calendar speed 1x:

| Calendar Speed | What the base game's "Last Year" covers | With this mod |
|---|---|---|
| 0.25x | about 3 months | the last 12 months |
| 0.5x | about 6 months | the last 12 months |
| 1x | 12 months | the last 12 months (the same) |
| 2x | more than a year | the last 12 months |
| 4x | more than a year | the last 12 months |

So at a slow calendar a vehicle looks far less profitable than it is over a
year, and at a fast one more. The mod looks up, in the game's own
calendar, when the same day one year ago began, and sums the balance from
there to now. When you change the calendar speed during the year, the
window follows the calendar, not the game time.

If you only compare vehicles with each other at one calendar speed, the
base game's values rank them the same. The mod helps when you read "Last
Year" as a year's amount (for example, to see how many years a vehicle
takes to pay back its price) and when you change the calendar speed during
play (the same vehicle's balance can be compared before and after).

## Where it acts, and where not

Acts on:

- the vehicle window, **Balance** section: the **Last Year** value;
- the **Statistics** window, **Vehicles** tab: the **Balance** column of
  each row (also when UI Overhaul replaces that table, as it uses the same
  cell).

Does not change:

- sorting the Statistics table by **Balance**: the base game sorts with its
  own value, so the order can differ from the numbers shown at a calendar
  speed other than 1x;
- the vehicle window's balance chart, the line window's balance, and the
  company finances;
- values other mods compute themselves: UI Overhaul's vehicle totals, sort
  and "losing money" filter, and Square Line Manager Plus's vehicle hover
  panel.

Known limits:

- Within a year of the game start, the value covers everything since the
  start.
- With the calendar paused (Calendar Speed: Paused), the window keeps its
  length and slides with game time.
- The start keeps the current time of day on the day one year ago; across a
  calendar speed change this shifts it by less than one day.

## Compatibility

- Only the display changes (`cosmetic`). Nothing is stored in the save, so
  adding and removing the mod are safe (`severityAdd: None`,
  `severityRemove: None`).
- No base file is replaced. At GUI start the mod wraps the base recipe
  `vehicle_react_util.VehicleBalance`; calls it does not take over go to the
  base recipe unchanged. If anything fails, the cell shows the base game's
  value.
- No dependencies.

## Install

- mod.io: https://mod.io/g/transportfever3/m/vehicle-last-year-balance-at-any-calendar-speed (or subscribe in the game's mod hub).
- Manually: the game loads a local mod only from a folder named exactly
  `hummer_vehicle_calendar_balance_1` inside
  `<Steam>/userdata/<your id>/3493540/local/mods/`.
  - From the release zip: create that folder and extract the zip **into** it
    (the zip has no top folder of its own).
  - From GitHub: `git clone
    https://github.com/hummer98/tpf3-vehicle-calendar-balance
    hummer_vehicle_calendar_balance_1` inside `local/mods/` (a different
    folder name will not load).
  - Then enable the mod in the game.

## Development

| File | Role |
|---|---|
| `content/gui/hummer_vehicle_calendar_balance/vcb_core.lua` | Pure date logic: the game time at which the same day one year ago began, from the calendar's date entries; free of game globals so the tests run offline |
| `content/gui/hummer_vehicle_calendar_balance/vcb_balance.lua` | The wrap of `VehicleBalance`, our recipe (the base cell rebuilt with our value), the caches, and the fall back to the base window; logs only failures, once each |
| `content/gui/hummer_vehicle_calendar_balance/vcb.script.lua` | The replacement-config hook that installs the wrap |
| `content/gui/hummer_vehicle_calendar_balance/vcb.res.lua` | Points the game at the hook at GUI start |
| `mod.json` | modId and revision |
| `VERSION` | The version (`MAJOR.MINOR.PATCH`); `mod.json`'s revision is MAJOR * 10000 + MINOR * 100 + PATCH |
| `CHANGELOG.md` | Changes per version ([Keep a Changelog](https://keepachangelog.com/en/1.1.0/)); new ones go under `## [Unreleased]` |
| `strings.json` | Texts in the game's 13 languages; the window, tab, column and calendar speed words are the base game's own |
| `_metadata/modinfo.json` | Name, summary and description for the game's mod list and the in-game mod.io upload (one text for all languages: the name in English only, at most 50 characters for mod.io; summary and description English and Japanese) |
| `_metadata/0.png` | Cover image (required by the in-game uploader) |
| `docs/modio_description.md` | Description for the mod.io web page |
| `docs/release.md` | Versions and the release steps (Japanese) |

Tests run offline (no game needed; the checks against the installed game's
`base.mo` are skipped without it):

```sh
luajit tests/run.lua
TMPDIR=<scratch dir> python3 -m unittest discover -s tests
```

Set `TMPDIR` to a scratch directory for the Python tests and the tools
below (they create temporary folders), not `/tmp` or `local/mods`.

`python3 tools/package.py` runs both test suites and builds
`dist/hummer_vehicle_calendar_balance_1.zip` with only `mod.json`,
`strings.json`, `content/` and `_metadata/`. LICENSE stays out: the game's
mod validation rejects files without an allowed extension. It refuses to
build without `_metadata/0.png`.

`python3 tools/stage.py` copies the mod into the game's staging area
(`local/staging_area/hummer_vehicle_calendar_balance_1`) for the in-game
upload. Run it from the copy in `local/mods/`, while the game is stopped.
It refuses uncommitted changes, a missing cover and, after the first
upload, an unraised `revision`, and keeps the `_metadata/mod.io_fileid.txt`
the game writes at the first upload, which is what makes later uploads
update the same mod.io page. Use `--first-upload` for the first one.

Versions and releases ([docs/release.md](docs/release.md)): write each
change under `## [Unreleased]` in `CHANGELOG.md`. To release, in a
development clone (not the copy in `local/mods/`), run
`python3 tools/release.py patch|minor|major|X.Y.Z` (`--dry-run` first). It
writes `VERSION`, the revision and the changelog section, runs the tests,
commits `Release vX.Y.Z`, tags `vX.Y.Z`, builds
`dist/hummer_vehicle_calendar_balance-vX.Y.Z.zip` and, with the `github`
remote, pushes the branch and that tag and creates the GitHub release with
the section as its notes. The tests fail when `VERSION`, the revision and
the changelog disagree.

## License

[MIT](LICENSE) © 2026 hummer

---

## 日本語

**車両の最終年の残高をカレンダー速度に合わせる（Transport Fever 3）**

**この MOD がすること:** 車両ウィンドウの「**最終年**」の残高と、「**統計**」ウィンドウの「**車両**」タブの「**残高**」の列を、「**カレンダー速度**」に合わせて、暦の直近12か月で集計します。

### なぜ

バニラでは、この集計がカレンダー速度を見ていません。いつも同じ長さのゲーム時間（1日4秒 × 365日、ゲーム時間で約24分）で集計するため、暦の1年と同じになるのは、カレンダー速度が 1x のときだけです。

| カレンダー速度 | バニラの「最終年」の範囲 | この MOD |
|---|---|---|
| 0.25x | 約3か月 | 直近の12か月 |
| 0.5x | 約6か月 | 直近の12か月 |
| 1x | 12か月 | 直近の12か月（同じ） |
| 2x | 1年より長い | 直近の12か月 |
| 4x | 1年より長い | 直近の12か月 |

カレンダーが遅いと、車両は1年で見たよりずっと稼いでいないように見え、速いと実際より多く稼いでいるように見えます。この MOD は、ゲームの暦から「1年前の同じ日」が始まった時点を引き、そこから今までの残高を集計します。年の途中でカレンダー速度を変えても、範囲はゲーム時間ではなく暦に合わせます。

同じカレンダー速度のまま車両どうしを比べるだけなら、バニラの値でも順番は変わりません。この MOD が役に立つのは、「最終年」の値を1年分の額として読むとき（車両の購入価格と比べて、元が取れるまでの年数を見積もるなど）と、プレイの途中でカレンダー速度を変えたとき（変える前と後で、同じ車両の残高を比べられます）です。

### 効く所・効かない所

効く所:

- 車両ウィンドウの「残高」の節の「最終年」の値
- 「統計」ウィンドウの「車両」タブの、各行の「残高」の列（UI Overhaul がこの表を置き換えていても、同じ欄を使うので効きます）

変えない所:

- 統計の表を「残高」で並べ替える順番。バニラの値で並べるので、カレンダー速度が 1x でないと、表示の数字と順番が合わないことがあります
- 車両ウィンドウの収支のグラフ、路線ウィンドウの収支、会社の財務
- ほかの MOD が自分で計算する値: UI Overhaul の車両の合計・並べ替え・赤字の絞り込み、Square Line Manager Plus の車両のホバーの表示

分かっている制限:

- ゲームを始めてから1年たつまでは、始めからの合計です。
- カレンダーを止めている間（カレンダー速度: 一時停止）は、範囲の長さを保ったまま、ゲーム時間とともにずれていきます。
- 範囲の始めは、1年前の同じ日の、今と同じ時刻です。カレンダー速度を変えた前後では、1日分より小さくずれます。

### 互換性

- 変えるのは表示だけです（`cosmetic`）。セーブには何も保存しないので、入れるのも外すのも問題ありません（`severityAdd: None`、`severityRemove: None`）。
- ゲームのファイルは置き換えません。GUI の起動時に、ゲームのレシピ `vehicle_react_util.VehicleBalance` を包みます。この MOD が引き受けない呼び出しは、そのままゲームのレシピへ渡します。計算に失敗したときは、バニラの値を表示します。
- 必要な MOD はありません。

### 導入

- mod.io: https://mod.io/g/transportfever3/m/vehicle-last-year-balance-at-any-calendar-speed（ゲームの MOD ハブから購読することもできます）
- 手で入れる場合: ゲームは、`<Steam>/userdata/<あなたの ID>/3493540/local/mods/` の中の、名前がちょうど `hummer_vehicle_calendar_balance_1` のフォルダからだけ読み込みます。
  - release の zip から: そのフォルダを作り、zip をその**中に**展開します（zip には上のフォルダがありません）。
  - GitHub から: `local/mods/` の中で `git clone https://github.com/hummer98/tpf3-vehicle-calendar-balance hummer_vehicle_calendar_balance_1`（別のフォルダ名では読み込まれません）。
  - そのあと、ゲームで MOD を有効にします。

### 開発

ファイルの役割・テスト・ツールの使い方は、上の英語の「Development」を見てください。テストはゲームなしで回せます。

```sh
luajit tests/run.lua
TMPDIR=<作業用のフォルダ> python3 -m unittest discover -s tests
```

### ライセンス

[MIT](LICENSE) © 2026 hummer
