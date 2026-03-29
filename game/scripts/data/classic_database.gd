class_name ClassicDatabase
extends RefCounted

var manifest: Dictionary = {}
var units: Array = []
var buildings: Array = []
var spells: Array = []
var tech_tree: Array = []
var strings: Array = []
var missions: Array = []
var misc: Dictionary = {}


func load_from_dir(base_path: String = "res://data/classic/normalized") -> void:
    manifest = _load_json_file("%s/manifest.json" % base_path, {})
    units = _load_json_file("%s/units.json" % base_path, [])
    buildings = _load_json_file("%s/buildings.json" % base_path, [])
    spells = _load_json_file("%s/spells.json" % base_path, [])
    tech_tree = _load_json_file("%s/tech_tree.json" % base_path, [])
    strings = _load_json_file("%s/strings.json" % base_path, [])
    missions = _load_json_file("%s/missions.json" % base_path, [])
    misc = _load_json_file("%s/misc.json" % base_path, {})


func summary() -> Dictionary:
    return {
        "units": units.size(),
        "buildings": buildings.size(),
        "spells": spells.size(),
        "techs": tech_tree.size(),
        "strings": strings.size(),
        "missions": missions.size(),
    }


func find_mission(mission_id: String) -> Dictionary:
    for mission in missions:
        if str(mission.get("id", "")) == mission_id:
            return mission
    return {}


func find_unit(unit_id: String) -> Dictionary:
    for unit in units:
        if str(unit.get("id", "")) == unit_id:
            return unit
    return {}


func find_building(building_id: String) -> Dictionary:
    for building in buildings:
        if str(building.get("id", "")) == building_id:
            return building
    return {}


func _load_json_file(path: String, fallback: Variant) -> Variant:
    if not FileAccess.file_exists(path):
        return fallback

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if parsed == null:
        return fallback

    return parsed
