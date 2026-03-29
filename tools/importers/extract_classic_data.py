from __future__ import annotations

import argparse
import json
import re
from collections import OrderedDict
from pathlib import Path
from typing import Any


UNIT_ORDER: list[dict[str, Any]] = [
    {"source_index": 0, "section": "SOLDAT", "id": "swordsman", "role": "melee", "faction": "player"},
    {"source_index": 1, "section": "GARDIEN DU FEU", "id": "scorcher", "role": "melee", "faction": "player"},
    {"source_index": 2, "section": "CAPITAINE", "id": "captain", "role": "ranged", "faction": "player"},
    {"source_index": 3, "section": "OURS DE COMBAT", "id": "killer", "role": "melee", "faction": "player"},
    {"source_index": 4, "section": "PRETRE", "id": "druid", "role": "magic", "faction": "player"},
    {"source_index": 5, "section": "FERMIER", "id": "farmer", "role": "worker", "faction": "player"},
    {"source_index": 6, "section": "MECANO", "id": "mechanic", "role": "worker", "faction": "player"},
    {"source_index": 7, "section": "BATISSEUR", "id": "builder", "role": "worker", "faction": "player"},
    {"source_index": 8, "section": "VOLEUR", "id": "archer", "role": "ranged", "faction": "player"},
    {"source_index": 9, "section": "COLON", "id": "settler", "role": "civilian", "faction": "player"},
    {"source_index": 10, "section": "MESSAGER", "id": "messenger", "role": "civilian", "faction": "player"},
    {"source_index": 11, "section": "SPYDER", "id": "speeder", "role": "vehicle", "faction": "player"},
    {"source_index": 12, "section": "BUNKER", "id": "boomer", "role": "vehicle", "faction": "player"},
    {"source_index": 13, "section": "RECOLTEUSE", "id": "reaper", "role": "vehicle", "faction": "player"},
    {"source_index": 14, "section": "PIEGEUR", "id": "bomber", "role": "vehicle", "faction": "player"},
    {"source_index": 15, "section": "SUN", "id": "hellfire", "role": "vehicle", "faction": "player"},
    {"source_index": 16, "section": "HELIPEDE", "id": "heliped", "role": "flying", "faction": "player"},
    {"source_index": 17, "section": "ZEEPELIN", "id": "balloon", "role": "flying", "faction": "player"},
    {"source_index": 18, "section": "ARAIGNEE", "id": "spider", "role": "creature", "faction": "creature"},
    {"source_index": 19, "section": "FOURMI", "id": "ant", "role": "creature", "faction": "creature"},
    {"source_index": 20, "section": "MASTAAR", "id": "basher", "role": "creature", "faction": "creature"},
    {"source_index": 21, "section": "LEZARD", "id": "raptor", "role": "creature", "faction": "creature"},
    {"source_index": 22, "section": "SANGLIER", "id": "hurler", "role": "creature", "faction": "creature"},
    {"source_index": 23, "section": "FOOTMAN", "id": "bukka", "role": "creature", "faction": "creature"},
    {"source_index": 24, "section": "TORTUE", "id": "snapper", "role": "creature", "faction": "creature"},
    {"source_index": 25, "section": "RHINO", "id": "stomper", "role": "ranged", "faction": "player"},
]

BUILDING_ORDER: list[dict[str, Any]] = [
    {"source_index": 0, "section": "PHARE", "id": "lighthouse"},
    {"source_index": 1, "section": "CASERNE", "id": "barracks"},
    {"source_index": 2, "section": "SANCTUAIRE", "id": "sanctuary"},
    {"source_index": 3, "section": "CAVE", "id": "storehouse"},
    {"source_index": 4, "section": "CULTURE", "id": "culture"},
    {"source_index": 5, "section": "ATELIER", "id": "workshop"},
    {"source_index": 6, "section": "BIBLIOTHEQUE", "id": "library"},
    {"source_index": 7, "section": "LABORATOIRE", "id": "laboratory"},
    {"source_index": 8, "section": "HANGAR", "id": "hangar"},
    {"source_index": 9, "section": "MUR", "id": "wall"},
    {"source_index": 10, "section": "TOURCATAPULTE", "id": "tower_catapult"},
    {"source_index": 11, "section": "TOURCANON", "id": "tower_cannon"},
    {"source_index": 12, "section": "HERSE", "id": "portcullis"},
    {"source_index": 13, "section": "CIRQUE", "id": "circus"},
    {"source_index": 14, "section": "GARAGE", "id": "garage"},
    {"source_index": 15, "section": "MONASTERE", "id": "temple"},
    {"source_index": 16, "section": "MARCHE", "id": "market"},
    {"source_index": 17, "section": "CRISTAL", "id": "crystal"},
    {"source_index": 18, "section": "HELIOPORT", "id": "heliport"},
    {"source_index": 19, "section": "HOSPI", "id": "hospital"},
    {"source_index": 20, "section": "MONASTEREFUSION", "id": "fusion_temple"},
    {"source_index": 21, "section": "TENTE", "id": "campaign_tent"},
]

SPELL_ORDER: list[dict[str, str]] = [
    {"section": "VISION", "id": "vision"},
    {"section": "PETRIFICATION", "id": "petrification"},
    {"section": "MIROIR", "id": "mirror"},
    {"section": "ARMURE", "id": "armour"},
    {"section": "NOVA", "id": "nova"},
]

TECH_BRANCHES: list[tuple[str, str, int]] = [
    ("AGRICULTURE", "agriculture", 19),
    ("MILITAIRE", "military", 20),
    ("GENIECIVIL", "civil_engineering", 24),
    ("RELIGIEUX", "religious", 18),
]

TEXT_GROUPS: list[tuple[int, int, str]] = [
    (0, 3, "tabs"),
    (4, 30, "options"),
    (31, 36, "main_menu_page_1"),
    (37, 39, "main_menu_page_2"),
    (40, 43, "resources"),
    (44, 51, "terrain"),
    (52, 69, "unit_names"),
    (70, 91, "building_names"),
    (92, 97, "action_icons"),
    (98, 102, "spell_names"),
    (103, 103, "flag"),
    (104, 105, "market_players"),
    (106, 113, "market_ui"),
    (114, 114, "save_ui"),
    (115, 116, "mission_ui"),
    (117, 119, "multiplayer_ui"),
]

MISSION_TITLE_RE = re.compile(r"-\s*Mission\s+(\d+)\s*\.?\s*-", re.IGNORECASE)
CHAPTER_RE = re.compile(r"^-+\s*CHAPTER\s+(.+)$", re.IGNORECASE)


def read_text_file(path: Path) -> str:
    for encoding in ("cp1252", "latin-1", "utf-8"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    return path.read_text(encoding="utf-8", errors="replace")


def parse_ini_sections(path: Path) -> OrderedDict[str, OrderedDict[str, str]]:
    sections: OrderedDict[str, OrderedDict[str, str]] = OrderedDict()
    current_name: str | None = None

    for raw_line in read_text_file(path).splitlines():
        stripped = raw_line.strip()

        if not stripped or stripped.startswith(";"):
            continue

        if stripped.startswith("[") and stripped.endswith("]"):
            current_name = stripped[1:-1]
            sections[current_name] = OrderedDict()
            continue

        if current_name is None or "=" not in raw_line:
            continue

        key, value = raw_line.split("=", 1)
        sections[current_name][key.strip()] = value.strip()

    return sections


def parse_textes(path: Path) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    entry_index = 0

    for source_line, raw_line in enumerate(read_text_file(path).splitlines()):
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("//"):
            continue
        if stripped.startswith("[") and stripped.endswith("]"):
            continue

        entries.append(
            {
                "entry_index": entry_index,
                "source_line": source_line,
                "group": categorize_text_entry(entry_index),
                "text": stripped,
            }
        )
        entry_index += 1

    return entries


def categorize_text_entry(entry_index: int) -> str:
    for start, end, group_name in TEXT_GROUPS:
        if start <= entry_index <= end:
            return group_name
    return "uncategorized"


def parse_mission_briefings(world_dir: Path) -> OrderedDict[str, dict[str, Any]]:
    missions: OrderedDict[str, dict[str, Any]] = OrderedDict()

    for path in sorted(world_dir.glob("MONDE*.TXT")):
        mission_id = path.stem.upper()
        text = read_text_file(path).strip()
        missions[mission_id] = {
            "file": path.name,
            "text": text,
            "metadata": extract_mission_metadata(mission_id, text),
        }

    return missions


def extract_mission_metadata(mission_id: str, text: str) -> dict[str, Any]:
    lines = [line.rstrip() for line in text.splitlines()]
    mission_number = int(mission_id[-2:])
    title = ""
    chapter = ""
    synopsis: list[str] = []
    in_synopsis = False

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue

        title_match = MISSION_TITLE_RE.match(stripped)
        if title_match:
            mission_number = int(title_match.group(1))
            title = stripped
            in_synopsis = False
            continue

        chapter_match = CHAPTER_RE.match(stripped)
        if chapter_match:
            chapter = stripped
            continue

        if stripped.lower().startswith("synopsis"):
            in_synopsis = True
            remainder = stripped.split(":", 1)
            if len(remainder) == 2 and remainder[1].strip():
                synopsis.append(remainder[1].strip())
            continue

        if in_synopsis:
            cleaned = stripped.lstrip("-").strip()
            if cleaned:
                synopsis.append(cleaned)

    return {
        "mission_number": mission_number,
        "title": title,
        "chapter": chapter,
        "objectives": synopsis,
    }


def to_int(value: str | None) -> int | None:
    if value is None:
        return None
    value = value.strip()
    if not value:
        return None
    return int(value)


def to_int_or_text(value: str | None) -> int | str | None:
    if value is None:
        return None
    value = value.strip()
    if not value:
        return None

    try:
        return int(value)
    except ValueError:
        return value


def parse_damage_array(value: str | None) -> list[int]:
    if not value:
        return []
    return [int(part.strip()) for part in value.split(",") if part.strip()]


def normalize_units(rising_sections: dict[str, dict[str, str]]) -> list[dict[str, Any]]:
    target_order = [unit["id"] for unit in UNIT_ORDER] + ["buildings"]
    records: list[dict[str, Any]] = []

    for unit in UNIT_ORDER:
        section = rising_sections.get(unit["section"], {})
        damage_values = parse_damage_array(section.get("DEGAT"))
        damage_profile = OrderedDict()
        for index, target_id in enumerate(target_order):
            if index < len(damage_values):
                damage_profile[target_id] = damage_values[index]

        record = {
            "id": unit["id"],
            "source_section": unit["section"],
            "source_index": unit["source_index"],
            "faction": unit["faction"],
            "role": unit["role"],
            "name": section.get("NAME", unit["id"].replace("_", " ").title()),
            "vision": to_int(section.get("RAYON")),
            "range": to_int(section.get("PORTEE")),
            "armor": to_int(section.get("BLINDAGE")),
            "fatigue": to_int(section.get("FATIGUE")),
            "recharge": to_int(section.get("RECHARGE")),
            "recruit_time": to_int(section.get("TMPSRECRUTE")),
            "cost": {
                "food": to_int(section.get("COUTPATATE")) or 0,
                "stone": to_int(section.get("COUTROCHE")) or 0,
                "parts": to_int(section.get("COUTPIECE")) or 0,
            },
            "damage_profile": damage_profile,
        }
        records.append(record)

    return records


def normalize_buildings(rising_sections: dict[str, dict[str, str]]) -> list[dict[str, Any]]:
    target_order = [unit["id"] for unit in UNIT_ORDER] + ["buildings"]
    records: list[dict[str, Any]] = []

    for building in BUILDING_ORDER:
        section = rising_sections.get(building["section"], {})
        damage_values = parse_damage_array(section.get("DEGAT"))
        damage_profile = OrderedDict()
        for index, target_id in enumerate(target_order):
            if index < len(damage_values):
                damage_profile[target_id] = damage_values[index]

        record = {
            "id": building["id"],
            "source_section": building["section"],
            "source_index": building["source_index"],
            "name": section.get("NAME", building["id"].replace("_", " ").title()),
            "build_time": to_int(section.get("TMPSCONSTRUCTION")),
            "housing": to_int(section.get("LOGEMENT")),
            "cost": {
                "food": to_int(section.get("COUTPATATE")) or 0,
                "stone": to_int(section.get("COUTROCHE")) or 0,
                "parts": to_int(section.get("COUTPIECE")) or 0,
            },
            "damage_profile": damage_profile,
        }
        records.append(record)

    return records


def normalize_spells(rising_sections: dict[str, dict[str, str]]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []

    for spell in SPELL_ORDER:
        section = rising_sections.get(spell["section"], {})
        record = {
            "id": spell["id"],
            "source_section": spell["section"],
            "name": section.get("NAME", spell["id"].replace("_", " ").title()),
            "radius": to_int(section.get("RAYON")),
            "duration": to_int(section.get("DUREE")),
            "learn_time": to_int(section.get("APPRENTISSAGE")),
            "range": to_int(section.get("PORTEE")),
            "cost": {
                "food": to_int(section.get("COUTPATATE")) or 0,
                "stone": to_int(section.get("COUTROCHE")) or 0,
                "parts": to_int(section.get("COUTPIECE")) or 0,
                "mana": to_int(section.get("COUTMANA")) or 0,
            },
        }
        records.append(record)

    return records


def normalize_tech_tree(rising_sections: dict[str, dict[str, str]]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []

    for prefix, branch_id, count in TECH_BRANCHES:
        for branch_index in range(count):
            section_name = f"{prefix}{branch_index}"
            section = rising_sections.get(section_name, {})
            if not section:
                continue

            record = {
                "id": f"{branch_id}_{branch_index:02d}",
                "source_section": section_name,
                "branch": branch_id,
                "branch_index": branch_index,
                "cost": to_int(section.get("COUT")),
                "mission": to_int(section.get("MISSION")),
                "effect_type": to_int(section.get("EFFET")),
                "param1": to_int(section.get("PARAM1")),
                "param2": to_int(section.get("PARAM2")),
                "param3": to_int(section.get("PARAM3")),
                "appearance_mission": to_int(section.get("APPARITION")),
            }
            records.append(record)

    return records


def normalize_misc(rising_sections: dict[str, dict[str, str]]) -> dict[str, Any]:
    section = rising_sections.get("DIVERS", {})
    normalized: dict[str, Any] = {}
    for key, value in section.items():
        normalized[key.lower()] = to_int_or_text(value)
    return normalized


def normalize_missions(raw_missions: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []

    for mission_id, payload in raw_missions.items():
        metadata = payload.get("metadata", {})
        records.append(
            {
                "id": mission_id.lower(),
                "source_file": payload.get("file", ""),
                "mission_number": metadata.get("mission_number"),
                "title": metadata.get("title", ""),
                "chapter": metadata.get("chapter", ""),
                "objectives": metadata.get("objectives", []),
                "briefing": payload.get("text", ""),
            }
        )

    return records


def build_raw_manifest(
    source_dir: Path,
    rising: dict[str, Any],
    monsters: dict[str, Any],
    textes: list[dict[str, Any]],
    missions: dict[str, Any],
) -> dict[str, Any]:
    return {
        "source_dir": str(source_dir),
        "files": {
            "RISING.INI": "RISING.INI",
            "MONSTRE.INI": "MONSTRE.INI",
            "TEXTES.TXT": "TEXTES.TXT",
            "WORLD": "WORLD",
        },
        "summary": {
            "rising_sections": len(rising),
            "monster_sections": len(monsters),
            "text_entries": len(textes),
            "missions": len(missions),
        },
    }


def build_normalized_manifest(
    source_dir: Path,
    units: list[dict[str, Any]],
    buildings: list[dict[str, Any]],
    spells: list[dict[str, Any]],
    techs: list[dict[str, Any]],
    strings: list[dict[str, Any]],
    missions: list[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "source_dir": str(source_dir),
        "summary": {
            "units": len(units),
            "buildings": len(buildings),
            "spells": len(spells),
            "techs": len(techs),
            "strings": len(strings),
            "missions": len(missions),
        },
    }


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def export_raw_dataset(output_dir: Path, manifest: dict[str, Any], rising: Any, monsters: Any, textes: Any, missions: Any) -> None:
    write_json(output_dir / "manifest.json", manifest)
    write_json(output_dir / "rising_ini.json", rising)
    write_json(output_dir / "monstre_ini.json", monsters)
    write_json(output_dir / "textes.json", textes)
    write_json(output_dir / "missions.json", missions)


def export_normalized_dataset(
    output_dir: Path,
    manifest: dict[str, Any],
    units: Any,
    buildings: Any,
    spells: Any,
    techs: Any,
    strings: Any,
    missions: Any,
    misc: Any,
) -> None:
    write_json(output_dir / "manifest.json", manifest)
    write_json(output_dir / "units.json", units)
    write_json(output_dir / "buildings.json", buildings)
    write_json(output_dir / "spells.json", spells)
    write_json(output_dir / "tech_tree.json", techs)
    write_json(output_dir / "strings.json", strings)
    write_json(output_dir / "missions.json", missions)
    write_json(output_dir / "misc.json", misc)


def main() -> None:
    parser = argparse.ArgumentParser(description="Extract raw and normalized classic Rising Lands data into JSON.")
    parser.add_argument("--source", required=True, help="Path to the original Rising Lands Release folder.")
    parser.add_argument("--output", required=True, help="Classic data root output directory.")
    args = parser.parse_args()

    source_dir = Path(args.source)
    output_root = Path(args.output)

    if not source_dir.exists():
        raise SystemExit(f"Source directory does not exist: {source_dir}")

    rising_ini_path = source_dir / "RISING.INI"
    monstre_ini_path = source_dir / "MONSTRE.INI"
    textes_path = source_dir / "TEXTES.TXT"
    world_dir = source_dir / "WORLD"

    rising_ini = parse_ini_sections(rising_ini_path)
    monstre_ini = parse_ini_sections(monstre_ini_path)
    textes = parse_textes(textes_path)
    raw_missions = parse_mission_briefings(world_dir)

    units = normalize_units(rising_ini)
    buildings = normalize_buildings(rising_ini)
    spells = normalize_spells(rising_ini)
    techs = normalize_tech_tree(rising_ini)
    strings = textes
    missions = normalize_missions(raw_missions)
    misc = normalize_misc(rising_ini)

    raw_manifest = build_raw_manifest(source_dir, rising_ini, monstre_ini, textes, raw_missions)
    normalized_manifest = build_normalized_manifest(source_dir, units, buildings, spells, techs, strings, missions)

    export_raw_dataset(output_root / "raw", raw_manifest, rising_ini, monstre_ini, textes, raw_missions)
    export_normalized_dataset(output_root / "normalized", normalized_manifest, units, buildings, spells, techs, strings, missions, misc)


if __name__ == "__main__":
    main()
