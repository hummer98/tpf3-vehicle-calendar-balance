# Changelog

All notable changes to Vehicle Last Year Balance at Any Calendar Speed are
recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the mod uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). The mod's
`revision` in `mod.json` is MAJOR * 10000 + MINOR * 100 + PATCH.

## [Unreleased]

## [1.0.0] - 2026-11-25

### Added
- First public release. The **Last Year** balance in the vehicle window and
  the **Balance** column on the **Vehicles** tab of the **Statistics**
  window sum the last 12 months at any **Calendar Speed**, looked up in the
  game's calendar, instead of one default-speed year of game time
  (about 3 months at 0.25x, more than a year at 2x).
- Sorting the Statistics table by Balance keeps the base game's value.
- If the calendar cannot be read or the calculation fails, the base game's
  value is shown; each kind of failure is logged once.
- Texts in the game's 13 languages.
- Display only: nothing is stored in the save, no base file is replaced,
  no dependencies.
