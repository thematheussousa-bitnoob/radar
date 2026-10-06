"""The `recado` hand-over shape: its header follows the person, never one fixed language.

The model copies the shape in SKILL.md into its answer, so a header written in one
language was that language for everyone. It is English in the file and tells the
model to write it in the person's language.

    python3 -m unittest discover -s tests -v
"""

import unittest
from pathlib import Path

SKILL_MD = Path(__file__).resolve().parents[2] / "skills" / "recado" / "SKILL.md"


class HandOverShape(unittest.TestCase):
    def test_the_header_follows_the_person(self):
        text = SKILL_MD.read_text(encoding="utf-8")
        self.assertIn("Text for <who>:", text)
        self.assertIn("first line in the person's language", text)
        self.assertNotIn("Texto pra", text)


if __name__ == "__main__":
    unittest.main()
