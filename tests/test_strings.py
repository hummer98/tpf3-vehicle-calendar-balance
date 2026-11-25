"""Tests for strings.json: python3 -m unittest discover -s tests"""
import gettext
import json
import os
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME_STRINGS = os.path.expanduser(
    "~/.local/share/Steam/steamapps/common/Transport Fever 3/base/strings")
LANGS = ["en", "ja", "de", "es", "fr", "it", "ko", "nl", "pl", "pt_BR", "ru",
         "zh_CN", "zh_TW"]
# the words players see where the mod acts: the vehicle window's "Last Year"
# row (entity_window/vehicle/vehicle_eow.script.tl), the Statistics window,
# its Vehicles tab and Balance column (statistics/statistics.tl,
# statistic_vehicles.tl) and the calendar speed control
# (game_bar/game_bar_widgets.tl)
UI_WORDS = ["Last Year", "Balance", "Statistics", "Vehicles",
            "Calendar Speed"]
MOD_NAMES = {"en": "Vehicle Last Year Balance at Any Calendar Speed",
             "ja": "車両の最終年の残高を暦の直近12か月で集計"}


def load_strings():
    with open(os.path.join(ROOT, "strings.json"), encoding="utf-8") as f:
        return json.load(f)


def load_modinfo():
    with open(os.path.join(ROOT, "_metadata", "modinfo.json"),
              encoding="utf-8") as f:
        return json.load(f)


def catalog(lang):
    mo = os.path.join(GAME_STRINGS, lang, "LC_MESSAGES", "base.mo")
    with open(mo, "rb") as f:
        return gettext.GNUTranslations(f).gettext


class StringsTest(unittest.TestCase):
    def test_all_game_languages_have_the_same_keys(self):
        s = load_strings()
        self.assertEqual(sorted(s), sorted(LANGS))
        for lang in LANGS:
            self.assertEqual(sorted(s[lang]), ["mod_desc", "mod_name"], lang)
            for key, value in s[lang].items():
                self.assertIsInstance(value, str, "%s: %s" % (lang, key))
                self.assertTrue(value.strip(), "%s: %s empty" % (lang, key))

    def test_ui_words_are_the_vanilla_ones(self):
        # players look for the row, the window, the tab and the column by
        # the words the game shows them
        if not os.path.isdir(GAME_STRINGS):
            self.skipTest("game strings not found")
        s = load_strings()
        for lang in LANGS:
            v = catalog(lang)
            for key in UI_WORDS:
                word = v(key)
                if lang != "en":
                    self.assertNotEqual(word, key, "%s: %r not in base.mo"
                                        % (lang, key))
                self.assertIn(word, s[lang]["mod_desc"],
                              "%s: %r" % (lang, key))

    def test_mod_names(self):
        s = load_strings()
        for lang, name in MOD_NAMES.items():
            self.assertEqual(s[lang]["mod_name"], name)
        # the game's mod list shows the name: keep each one short enough
        for lang in LANGS:
            self.assertLessEqual(len(s[lang]["mod_name"]), 60, lang)

    def test_mod_io_page_text_matches_my_mods(self):
        # docs/modio_description.md goes to the mod.io page: its summary
        # and headings must follow renames of the mod
        s, info = load_strings(), load_modinfo()
        with open(os.path.join(ROOT, "docs", "modio_description.md"),
                  encoding="utf-8") as f:
            page = f.read()
        self.assertIn("**Summary:** %s\n" % info["summary"], page)
        self.assertIn("## English: %s\n" % s["en"]["mod_name"], page)
        self.assertIn("## 日本語: %s\n" % s["ja"]["mod_name"], page)

    def test_my_mods_text_matches_the_strings(self):
        # My Mods shows _metadata/modinfo.json, the mod settings show
        # strings.json: keep the two descriptions from drifting apart
        s, info = load_strings(), load_modinfo()
        # the mod.io name is English only (at most 50 characters)
        self.assertEqual(info["name"], s["en"]["mod_name"])
        self.assertEqual(info["description"],
                         "[English] %s\n%s\n\n[日本語] %s\n%s"
                         % (s["en"]["mod_name"], s["en"]["mod_desc"],
                            s["ja"]["mod_name"], s["ja"]["mod_desc"]))
        self.assertEqual(info["authors"], [{"name": "hummer",
                                            "role": "CREATOR"}])


if __name__ == "__main__":
    unittest.main()
