# mod.io page text

The in-game uploader has no description field: this goes to the mod.io web page.

**Summary:** The vehicle window's "Last Year" balance and the Statistics Balance column follow the calendar speed and sum the last 12 calendar months.

**概要（日本語。mod.io の summary の欄は 250 バイトまでなので、欄には英語だけを入れる）:** 車両の「最終年」の残高と統計の残高の列を、カレンダー速度に合わせて暦の直近12か月で集計。

## English: Vehicle Last Year Balance Follows Calendar Speed

**What this mod does:** the "Last Year" balance in the vehicle window and the "Balance" column on the "Vehicles" tab of the "Statistics" window sum the last 12 months of the calendar, following the "Calendar Speed".

**Why:** in the base game these values ignore the Calendar Speed. They always sum the same amount of game time, which is one calendar year only at calendar speed 1x. At 0.25x it covers about 3 months, at 0.5x about 6 months, and at 2x and 4x more than a year, so a vehicle looks far less (or more) profitable than it is over a year. The mod looks up in the game's calendar when the same day one year ago began and sums the 12 months from there to now; when you change the calendar speed during the year, the window follows the calendar.

If you only compare vehicles with each other at one calendar speed, the base game's values rank them the same. The mod helps when you read "Last Year" as a year's amount (for example, to see how many years a vehicle takes to pay back its price) and when you change the calendar speed during play (the same vehicle's balance can be compared before and after).

**Not changed:** sorting the Statistics table by Balance (the base game sorts with its own value), the vehicle balance chart, the line window and the company finances, and values other mods compute themselves (UI Overhaul's vehicle totals, sort and "losing money" filter; Square Line Manager Plus's vehicle hover panel). UI Overhaul's Balance column itself does show the calendar-year value.

**Limits:** within a year of the game start the value covers everything since the start. With the calendar paused, the window keeps its length and slides with game time.

Display only: nothing is stored in the save, so adding and removing the mod are safe. No base file is replaced; if anything fails, the base game's value is shown.

Texts in all 13 game languages. License: MIT. Source code: https://github.com/hummer98/tpf3-vehicle-calendar-balance

## 日本語: 車両の最終年の残高をカレンダー速度に合わせる

**この MOD がすること：** 車両ウィンドウの「最終年」の残高と、「統計」ウィンドウの「車両」タブの「残高」の列を、「カレンダー速度」に合わせて、暦の直近12か月で集計します。

**なぜ：** バニラでは、この集計がカレンダー速度を見ていません。いつも同じ長さのゲーム時間で集計するため、暦の1年になるのはカレンダー速度 1x のときだけです。0.25x では約3か月、0.5x では約6か月、2x と 4x では1年より長い期間になり、車両が1年で見たよりずっと稼いでいない（または多く稼いでいる）ように見えます。この MOD は、ゲームの暦から「1年前の同じ日」が始まった時点を引き、そこから今までの12か月の残高を集計します。年の途中でカレンダー速度を変えても、範囲は暦に合わせます。

同じカレンダー速度のまま車両どうしを比べるだけなら、バニラの値でも順番は変わりません。この MOD が役に立つのは、「最終年」の値を1年分の額として読むとき（車両の購入価格と比べて、元が取れるまでの年数を見積もるなど）と、プレイの途中でカレンダー速度を変えたとき（変える前と後で、同じ車両の残高を比べられます）です。

**変えない所：** 統計の表を残高で並べ替える順番（バニラの値で並べます）、車両の収支のグラフ、路線ウィンドウと会社の財務、ほかの MOD が自分で計算する値（UI Overhaul の車両の合計・並べ替え・赤字の絞り込み、Square Line Manager Plus の車両のホバーの表示）。UI Overhaul の表の「残高」の列そのものには効きます。

**制限：** ゲームを始めてから1年たつまでは、始めからの合計です。カレンダーを止めている間は、範囲の長さを保ったまま、ゲーム時間とともにずれていきます。

変えるのは表示だけです。セーブには何も保存しないので、入れるのも外すのも問題ありません。ゲームのファイルは置き換えず、計算に失敗したときはバニラの値を表示します。

ゲームの13言語に対応。ライセンス：MIT。ソースコード：https://github.com/hummer98/tpf3-vehicle-calendar-balance
