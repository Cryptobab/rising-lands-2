class_name MapState
extends RefCounted

var map_id: String = ""
var name: String = ""
var width: int = 0
var height: int = 0
var legend: Dictionary = {}
var tile_rows: Array = []
var resources: Array = []
var player_start: Vector2i = Vector2i.ZERO
var starting_resources: Dictionary = {}
var starting_buildings: Array = []
var starting_units: Array = []
var storehouse_goal: Dictionary = {}
var build_palette: Array = []
var enemy_spawns: Array = []
var objectives: Array = []
var mission_events: Array = []
var diplomacy_targets: Array = []


func load_from_file(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return false

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return false

    var payload: Dictionary = parsed
    map_id = str(payload.get("id", ""))
    name = str(payload.get("name", ""))
    width = int(payload.get("width", 0))
    height = int(payload.get("height", 0))
    legend = payload.get("legend", {})
    tile_rows = payload.get("tiles", [])
    resources = payload.get("resources", [])
    starting_resources = payload.get("starting_resources", {})
    starting_buildings = payload.get("starting_buildings", [])
    starting_units = payload.get("starting_units", [])
    storehouse_goal = payload.get("storehouse_goal", {})
    build_palette = payload.get("build_palette", [])
    enemy_spawns = payload.get("enemy_spawns", [])
    objectives = payload.get("objectives", [])
    mission_events = payload.get("mission_events", [])
    diplomacy_targets = payload.get("diplomacy_targets", [])

    var start_payload: Dictionary = payload.get("player_start", {})
    player_start = Vector2i(int(start_payload.get("x", 0)), int(start_payload.get("y", 0)))
    return true


func terrain_at(x: int, y: int) -> String:
    if y < 0 or y >= tile_rows.size():
        return "void"

    var row: String = str(tile_rows[y])
    if x < 0 or x >= row.length():
        return "void"

    var symbol: String = row.substr(x, 1)
    return str(legend.get(symbol, "void"))
