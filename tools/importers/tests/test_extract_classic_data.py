from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from extract_classic_data import extract_mission_metadata, parse_ini_sections, parse_textes


class ExtractClassicDataTests(unittest.TestCase):
    def test_parse_ini_sections_reads_basic_sections(self) -> None:
        content = """
; comment
[UNIT]
NAME=Worker
COUTPATATE=4

[BUILDING]
NAME=Storehouse
LOGEMENT=2
""".strip()

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "sample.ini"
            path.write_text(content, encoding="utf-8")
            sections = parse_ini_sections(path)

        self.assertEqual(sections["UNIT"]["NAME"], "Worker")
        self.assertEqual(sections["BUILDING"]["LOGEMENT"], "2")

    def test_parse_textes_skips_headers_and_comments(self) -> None:
        content = """
[FRANCAIS]
// comment
Menu
Play
Quit
""".strip()

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "TEXTES.TXT"
            path.write_text(content, encoding="utf-8")
            entries = parse_textes(path)

        self.assertEqual(len(entries), 3)
        self.assertEqual(entries[0]["entry_index"], 0)
        self.assertEqual(entries[0]["text"], "Menu")

    def test_extract_mission_metadata_captures_objectives(self) -> None:
        text = """
- Mission 4 -

Some briefing text.

Synopsis:
Build a Market.
Train a Messenger.
""".strip()

        metadata = extract_mission_metadata("MONDE04", text)

        self.assertEqual(metadata["mission_number"], 4)
        self.assertEqual(metadata["title"], "- Mission 4 -")
        self.assertEqual(metadata["objectives"], ["Build a Market.", "Train a Messenger."])


if __name__ == "__main__":
    unittest.main()
