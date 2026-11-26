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
MOD_NAMES = {"en": "Vehicle Last Year Balance Follows Calendar Speed",
             "ja": "車両の最終年の残高をカレンダー速度に合わせる"}


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

    def test_mod_io_name_and_summary_fit(self):
        # mod.io refuses a name over 50 characters; the summary is kept to
        # 250 bytes so that no multi-byte text can push it over the limit
        info = load_modinfo()
        self.assertLessEqual(len(info["name"]), 50)
        self.assertLessEqual(len(info["summary"].encode("utf-8")), 250)
        with open(os.path.join(ROOT, "docs", "modio_description.md"),
                  encoding="utf-8") as f:
            page = f.read()
        for line in page.splitlines():
            if line.startswith("**Summary:**") or line.startswith("**概要"):
                text = line.split(":** ", 1)[1]
                self.assertLessEqual(len(text.encode("utf-8")), 250, line)

    def test_release_title_is_the_mod_name(self):
        # the GitHub release and the tag message carry the mod's name
        import sys
        sys.path.insert(0, os.path.join(ROOT, "tools"))
        import release
        self.assertEqual(release.TITLE, load_modinfo()["name"])

    def test_texts_say_the_mod_follows_the_calendar_speed(self):
        # the old title and wording read as if the mod ignored the speed;
        # it is the base game that ignores it
        s = load_strings()
        old = ["at Any Calendar Speed", "at any", "whatever", "かかわらず",
               "によらず", "bei jeder", "con cualquier", "quelle que soit",
               "con qualsiasi", "관계없이", "bij elke", "niezależnie",
               "em qualquer", "при любом", "无论", "不論"]
        for lang in LANGS:
            for key in ("mod_name", "mod_desc"):
                for w in old:
                    self.assertNotIn(w, s[lang][key], "%s %s" % (lang, key))
        info = load_modinfo()
        for w in old:
            self.assertNotIn(w, info["name"] + info["summary"]
                             + info["description"])

    def test_every_language_has_the_when_it_helps_paragraph(self):
        # the second paragraph tells when the mod's value differs in use
        s = load_strings()
        for lang in LANGS:
            self.assertEqual(s[lang]["mod_desc"].count("\n\n"), 1, lang)
        self.assertIn("pay back its price", s["en"]["mod_desc"])
        self.assertIn("元が取れるまでの年数", s["ja"]["mod_desc"])


if __name__ == "__main__":
    unittest.main()
