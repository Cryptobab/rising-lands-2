class_name RulesetDatabase
extends RefCounted

const DATA_ROOT_TEMPLATE: String = "res://data/%s"
const DEFAULT_NORMALIZED_DIR: String = "normalized"
const DEFAULT_MAP_DIR: String = "vertical_slice"

var available: bool = false
var ruleset_id: String = ""
var display_name: String = ""
var description: String = ""
var ruleset_root_path: String = ""
var normalized_path: String = ""
var map_root_path: String = ""
var default_mission_id: String = ""
var default_map_path: String = ""
var ruleset_manifest: Dictionary = {}
var manifest: Dictionary = {}
var units: Array = []
var buildings: Array = []
var spells: Array = []
var tech_tree: Array = []
var strings: Array = []
var missions: Array = []
var misc: Dictionary = {}


func load_ruleset(next_ruleset_id: String, override_normalized_path: String = "") -> void:
    ruleset_id = str(next_ruleset_id).strip_edges().to_lower()
    if ruleset_id.is_empty():
        ruleset_id = "classic"

    ruleset_root_path = DATA_ROOT_TEMPLATE % ruleset_id
    var manifest_path: String = "%s/ruleset_manifest.json" % ruleset_root_path
    ruleset_manifest = _load_json_file(manifest_path, {})
    available = FileAccess.file_exists(manifest_path)

    display_name = str(ruleset_manifest.get("display_name", ruleset_id.capitalize()))
    description = str(ruleset_manifest.get("description", ""))
    normalized_path = str(ruleset_manifest.get("normalized_path", "%s/%s" % [ruleset_root_path, DEFAULT_NORMALIZED_DIR]))
    if not override_normalized_path.is_empty():
        normalized_path = override_normalized_path
    map_root_path = str(ruleset_manifest.get("map_root_path", "%s/%s" % [ruleset_root_path, DEFAULT_MAP_DIR]))
    default_mission_id = str(ruleset_manifest.get("default_mission_id", ""))
    default_map_path = str(ruleset_manifest.get("default_map_path", ""))

    manifest = _load_json_file("%s/manifest.json" % normalized_path, {})
    units = _load_json_file("%s/units.json" % normalized_path, [])
    buildings = _load_json_file("%s/buildings.json" % normalized_path, [])
    spells = _load_json_file("%s/spells.json" % normalized_path, [])
    tech_tree = _load_json_file("%s/tech_tree.json" % normalized_path, [])
    strings = _load_json_file("%s/strings.json" % normalized_path, [])
    missions = _load_json_file("%s/missions.json" % normalized_path, [])
    misc = _load_json_file("%s/misc.json" % normalized_path, {})

    if not available:
        available = (
            FileAccess.file_exists("%s/manifest.json" % normalized_path)
            or not missions.is_empty()
            or not units.is_empty()
            or not buildings.is_empty()
        )

    if default_mission_id.is_empty() and not missions.is_empty():
        default_mission_id = str(missions[0].get("id", ""))
    if default_map_path.is_empty() and not default_mission_id.is_empty():
        default_map_path = mission_map_path(default_mission_id)


func summary() -> Dictionary:
    return {
        "units": units.size(),
        "buildings": buildings.size(),
        "spells": spells.size(),
        "techs": tech_tree.size(),
        "strings": strings.size(),
        "missions": missions.size(),
    }


func ruleset_summary() -> Dictionary:
    return {
        "id": ruleset_id,
        "display_name": display_name,
        "description": description,
        "root_path": ruleset_root_path,
        "normalized_path": normalized_path,
        "map_root_path": map_root_path,
        "default_mission_id": default_mission_id,
        "default_map_path": default_map_path,
        "available": available
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


func find_tech(tech_id: String) -> Dictionary:
    for tech in tech_tree:
        if str(tech.get("id", "")) == tech_id:
            return tech
    return {}


func techs_for_branch(branch: String) -> Array:
    var branch_techs: Array = []
    for tech in tech_tree:
        if str(tech.get("branch", "")) == branch:
            branch_techs.append(tech)
    return branch_techs


func next_tech_for_branch(branch: String, unlocked_techs: Array) -> Dictionary:
    for tech in tech_tree:
        if str(tech.get("branch", "")) != branch:
            continue

        var tech_id: String = str(tech.get("id", ""))
        if unlocked_techs.has(tech_id):
            continue
        return tech

    return {}


func mission_map_path(mission_id: String, override_map_path: String = "") -> String:
    if not override_map_path.is_empty() and FileAccess.file_exists(override_map_path):
        return override_map_path

    var mission_record: Dictionary = find_mission(mission_id)
    var manifest_map_path: String = str(mission_record.get("map_path", ""))
    if not manifest_map_path.is_empty() and FileAccess.file_exists(manifest_map_path):
        return manifest_map_path

    var candidate_path: String = "%s/%s_map.json" % [map_root_path, mission_id]
    if FileAccess.file_exists(candidate_path):
        return candidate_path

    return default_map_path


func _load_json_file(path: String, fallback: Variant) -> Variant:
    if not FileAccess.file_exists(path):
        return fallback

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if parsed == null:
        return fallback

    return parsed
