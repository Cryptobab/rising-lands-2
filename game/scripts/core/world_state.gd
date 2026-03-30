class_name WorldState
extends RefCounted

const DEFAULT_RESOURCES := {
    "food": 0,
    "stone": 0,
    "parts": 0,
    "tech": 0
}

const DEFAULT_BRANCH_LEVELS := {
    "agriculture": 0,
    "civil_engineering": 0,
    "military": 0,
    "religious": 0
}

const DEFAULT_MODIFIERS := {
    "worker_speed": 1.0,
    "worker_gather": 1.0,
    "worker_carry": 1.0,
    "build_speed": 1.0,
    "train_speed": 1.0,
    "research_speed": 1.0,
    "combat_damage": 1.0,
    "combat_health": 1.0,
    "building_health": 1.0,
    "regeneration": 0.0,
    "tech_generation": 1.0
}

var tick_count: int = 0
var elapsed_time: float = 0.0
var map_seed: int = 1997
var map_size: Vector2i = Vector2i(18, 12)
var resources: Dictionary = {}
var ruleset_id: String = "classic"
var phase_name: String = "bootstrap"
var unlocked_techs: Array = []
var branch_levels: Dictionary = {}
var modifiers: Dictionary = {}
var enemy_waves_spawned: int = 0
var casualties: Dictionary = {}
var mission_status: String = "active"


func bootstrap_runtime(next_ruleset_id: String = "classic", next_phase_name: String = "vertical_slice_prep") -> void:
    tick_count = 0
    elapsed_time = 0.0
    map_seed = 1997
    map_size = Vector2i(18, 12)
    resources = DEFAULT_RESOURCES.duplicate(true)
    ruleset_id = str(next_ruleset_id).strip_edges().to_lower()
    if ruleset_id.is_empty():
        ruleset_id = "classic"
    phase_name = next_phase_name
    unlocked_techs = []
    branch_levels = DEFAULT_BRANCH_LEVELS.duplicate(true)
    modifiers = DEFAULT_MODIFIERS.duplicate(true)
    enemy_waves_spawned = 0
    casualties = {
        "player": 0,
        "enemy": 0
    }
    mission_status = "active"


func bootstrap_classic_vertical_slice() -> void:
    bootstrap_runtime("classic", "vertical_slice_prep")


func tick(delta: float) -> void:
    tick_count += 1
    elapsed_time += delta


func can_afford(cost: Dictionary) -> bool:
    for resource_type in cost.keys():
        if int(resources.get(resource_type, 0)) < int(cost.get(resource_type, 0)):
            return false
    return true


func spend_resources(cost: Dictionary) -> bool:
    if not can_afford(cost):
        return false

    for resource_type in cost.keys():
        resources[resource_type] = int(resources.get(resource_type, 0)) - int(cost.get(resource_type, 0))
    return true


func add_resource(resource_type: String, amount: int) -> void:
    resources[resource_type] = int(resources.get(resource_type, 0)) + amount


func register_research(tech_record: Dictionary) -> bool:
    var tech_id: String = str(tech_record.get("id", ""))
    if tech_id.is_empty() or unlocked_techs.has(tech_id):
        return false

    var branch: String = str(tech_record.get("branch", ""))
    unlocked_techs.append(tech_id)
    branch_levels[branch] = int(branch_levels.get(branch, 0)) + 1

    match branch:
        "agriculture":
            modifiers["worker_gather"] = float(modifiers.get("worker_gather", 1.0)) + 0.08
            modifiers["worker_carry"] = float(modifiers.get("worker_carry", 1.0)) + 0.10
        "civil_engineering":
            modifiers["build_speed"] = float(modifiers.get("build_speed", 1.0)) + 0.10
            modifiers["building_health"] = float(modifiers.get("building_health", 1.0)) + 0.08
            modifiers["research_speed"] = float(modifiers.get("research_speed", 1.0)) + 0.05
        "military":
            modifiers["combat_damage"] = float(modifiers.get("combat_damage", 1.0)) + 0.12
            modifiers["combat_health"] = float(modifiers.get("combat_health", 1.0)) + 0.08
            modifiers["train_speed"] = float(modifiers.get("train_speed", 1.0)) + 0.05
        "religious":
            modifiers["tech_generation"] = float(modifiers.get("tech_generation", 1.0)) + 0.15
            modifiers["regeneration"] = float(modifiers.get("regeneration", 0.0)) + 0.03
        _:
            pass

    return true


func serialize() -> Dictionary:
    return {
        "tick_count": tick_count,
        "elapsed_time": elapsed_time,
        "map_seed": map_seed,
        "map_size": {"x": map_size.x, "y": map_size.y},
        "resources": resources.duplicate(true),
        "ruleset_id": ruleset_id,
        "phase_name": phase_name,
        "unlocked_techs": unlocked_techs.duplicate(true),
        "branch_levels": branch_levels.duplicate(true),
        "modifiers": modifiers.duplicate(true),
        "enemy_waves_spawned": enemy_waves_spawned,
        "casualties": casualties.duplicate(true),
        "mission_status": mission_status
    }


func load_from_payload(payload: Dictionary) -> void:
    tick_count = int(payload.get("tick_count", 0))
    elapsed_time = float(payload.get("elapsed_time", 0.0))
    map_seed = int(payload.get("map_seed", 1997))

    var map_size_payload: Dictionary = payload.get("map_size", {})
    map_size = Vector2i(int(map_size_payload.get("x", 18)), int(map_size_payload.get("y", 12)))

    resources = DEFAULT_RESOURCES.duplicate(true)
    for resource_type in payload.get("resources", {}).keys():
        resources[resource_type] = int(payload.get("resources", {}).get(resource_type, 0))

    ruleset_id = str(payload.get("ruleset_id", "classic")).strip_edges().to_lower()
    if ruleset_id.is_empty():
        ruleset_id = "classic"
    phase_name = str(payload.get("phase_name", "vertical_slice_prep"))
    unlocked_techs = []
    for tech_id in payload.get("unlocked_techs", []):
        unlocked_techs.append(str(tech_id))

    branch_levels = DEFAULT_BRANCH_LEVELS.duplicate(true)
    for branch_name in payload.get("branch_levels", {}).keys():
        branch_levels[branch_name] = int(payload.get("branch_levels", {}).get(branch_name, 0))

    modifiers = DEFAULT_MODIFIERS.duplicate(true)
    for modifier_name in payload.get("modifiers", {}).keys():
        modifiers[modifier_name] = float(payload.get("modifiers", {}).get(modifier_name, modifiers.get(modifier_name, 1.0)))

    enemy_waves_spawned = int(payload.get("enemy_waves_spawned", 0))
    casualties = {
        "player": int(payload.get("casualties", {}).get("player", 0)),
        "enemy": int(payload.get("casualties", {}).get("enemy", 0))
    }
    mission_status = str(payload.get("mission_status", "active"))
