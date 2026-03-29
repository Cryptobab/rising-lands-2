class_name BuildingState
extends RefCounted

const CombatUnitType = preload("res://scripts/simulation/combat_unit_state.gd")

var building_id: String = ""
var name: String = ""
var team: String = "player"
var tile: Vector2i = Vector2i.ZERO
var size: Vector2i = Vector2i.ONE
var cost: Dictionary = {}
var housing: int = 0
var base_max_health: float = 100.0
var max_health: float = 100.0
var health: float = 100.0
var trainable_units: Array = []
var research_enabled: bool = false
var tech_generation_rate: float = 0.0
var tech_progress_buffer: float = 0.0
var production_queue: Array = []
var damage_profile: Dictionary = {}
var attack_range: float = 0.0
var vision: float = 0.0
var attack_interval: float = 1.5
var attack_timer: float = 0.0
var last_action: String = "idle"


func configure_from_record(record: Dictionary, spawn_tile: Vector2i, new_team: String = "player") -> void:
    building_id = str(record.get("id", ""))
    name = str(record.get("name", building_id))
    team = new_team
    tile = spawn_tile
    cost = record.get("cost", {}).duplicate(true)
    housing = int(record.get("housing", 0))

    var build_time: int = maxi(40, int(record.get("build_time", 100)))
    var total_cost: int = 0
    for resource_value in cost.values():
        total_cost += int(resource_value)

    base_max_health = float(maxi(80, int(build_time * 0.6) + (housing * 12) + (total_cost * 5)))
    max_health = base_max_health
    health = max_health
    trainable_units = []
    research_enabled = false
    tech_generation_rate = 0.0
    tech_progress_buffer = 0.0
    production_queue = []
    damage_profile = record.get("damage_profile", {}).duplicate(true)
    attack_range = 0.0
    vision = 0.0
    attack_interval = 1.5
    attack_timer = 0.0
    last_action = "constructed"

    match building_id:
        "culture":
            trainable_units = ["farmer", "builder", "mechanic", "settler", "messenger"]
            tech_generation_rate = 0.35
        "market":
            trainable_units = ["messenger"]
        "barracks":
            trainable_units = ["swordsman", "captain", "archer", "scorcher"]
        "sanctuary", "temple":
            trainable_units = ["druid"]
        "workshop":
            trainable_units = ["stomper"]
        "garage":
            trainable_units = ["speeder", "boomer", "reaper", "bomber", "hellfire"]
        "hangar", "heliport":
            trainable_units = ["heliped", "balloon"]
        "laboratory":
            research_enabled = true
            tech_generation_rate = 0.25
        "library":
            research_enabled = true
            tech_generation_rate = 0.45
        "tower_catapult":
            attack_range = 8.5
            vision = 11.0
            attack_interval = 1.8
        "tower_cannon":
            attack_range = 6.5
            vision = 9.0
            attack_interval = 1.15
        _:
            pass


func refresh_modifiers(world_state) -> void:
    if team != "player":
        return

    var previous_max: float = maxf(1.0, max_health)
    max_health = base_max_health * float(world_state.modifiers.get("building_health", 1.0))
    health = clampf((health / previous_max) * max_health, 1.0 if health > 0.0 else 0.0, max_health)


func supports_deposit() -> bool:
    return building_id == "storehouse"


func can_train_unit(unit_id: String) -> bool:
    return trainable_units.has(unit_id)


func can_research() -> bool:
    return research_enabled


func can_attack() -> bool:
    return attack_range > 0.0 and not damage_profile.is_empty()


func enqueue_job(kind: String, item_id: String, duration: float, metadata: Dictionary = {}) -> void:
    var job := metadata.duplicate(true)
    job["kind"] = kind
    job["id"] = item_id
    job["duration"] = maxf(duration, 0.5)
    job["progress"] = 0.0
    production_queue.append(job)
    last_action = "queued %s" % item_id


func process(delta: float, world_state) -> Array:
    var completed_jobs: Array = []
    if not is_alive():
        return completed_jobs

    if tech_generation_rate > 0.0 and team == "player":
        tech_progress_buffer += tech_generation_rate * float(world_state.modifiers.get("tech_generation", 1.0)) * delta
        while tech_progress_buffer >= 1.0:
            tech_progress_buffer -= 1.0
            world_state.add_resource("tech", 1)
            last_action = "generated tech"

    if production_queue.is_empty():
        return completed_jobs

    var current_job: Dictionary = production_queue[0]
    var progress_multiplier: float = float(world_state.modifiers.get("train_speed", 1.0))
    if str(current_job.get("kind", "")) == "research":
        progress_multiplier = float(world_state.modifiers.get("research_speed", 1.0))

    current_job["progress"] = float(current_job.get("progress", 0.0)) + (delta * progress_multiplier)
    production_queue[0] = current_job

    if float(current_job.get("progress", 0.0)) < float(current_job.get("duration", 1.0)):
        return completed_jobs

    production_queue.remove_at(0)
    completed_jobs.append(current_job)
    last_action = "completed %s" % str(current_job.get("id", "job"))
    return completed_jobs


func update_combat(delta: float, world_state, hostile_units: Array) -> void:
    if not is_alive() or not can_attack():
        return

    var target = _find_nearest_target(hostile_units)
    if target == null:
        return

    attack_timer += delta
    if attack_timer < attack_interval:
        return

    attack_timer = 0.0
    var damage_amount: float = _damage_against_target(target)
    if team == "player":
        damage_amount *= float(world_state.modifiers.get("combat_damage", 1.0))

    target.apply_damage(damage_amount)
    last_action = "fired on %s" % target.name


func queue_ratio() -> float:
    if production_queue.is_empty():
        return 0.0

    var current_job: Dictionary = production_queue[0]
    var duration: float = maxf(0.001, float(current_job.get("duration", 1.0)))
    return clampf(float(current_job.get("progress", 0.0)) / duration, 0.0, 1.0)


func queue_label() -> String:
    if production_queue.is_empty():
        return "idle"

    var current_job: Dictionary = production_queue[0]
    return "%s %s (%d)" % [
        str(current_job.get("kind", "job")),
        str(current_job.get("id", "")),
        production_queue.size()
    ]


func center_position() -> Vector2:
    return Vector2(tile) + Vector2(0.5, 0.5)


func apply_damage(amount: float) -> bool:
    health = maxf(0.0, health - amount)
    return not is_alive()


func regenerate(delta: float, amount_per_second: float) -> void:
    if health <= 0.0 or amount_per_second <= 0.0:
        return
    health = minf(max_health, health + (delta * amount_per_second))


func is_alive() -> bool:
    return health > 0.0


func serialize() -> Dictionary:
    return {
        "building_id": building_id,
        "name": name,
        "team": team,
        "x": tile.x,
        "y": tile.y,
        "cost": cost.duplicate(true),
        "housing": housing,
        "base_max_health": base_max_health,
        "max_health": max_health,
        "health": health,
        "trainable_units": trainable_units.duplicate(true),
        "research_enabled": research_enabled,
        "tech_generation_rate": tech_generation_rate,
        "tech_progress_buffer": tech_progress_buffer,
        "production_queue": production_queue.duplicate(true),
        "damage_profile": damage_profile.duplicate(true),
        "attack_range": attack_range,
        "vision": vision,
        "attack_interval": attack_interval,
        "attack_timer": attack_timer,
        "last_action": last_action
    }


func load_from_payload(payload: Dictionary, record: Dictionary) -> void:
    configure_from_record(
        record,
        Vector2i(int(payload.get("x", 0)), int(payload.get("y", 0))),
        str(payload.get("team", "player"))
    )
    cost = payload.get("cost", cost).duplicate(true)
    housing = int(payload.get("housing", housing))
    base_max_health = float(payload.get("base_max_health", base_max_health))
    max_health = float(payload.get("max_health", max_health))
    health = float(payload.get("health", health))
    trainable_units = payload.get("trainable_units", trainable_units).duplicate(true)
    research_enabled = bool(payload.get("research_enabled", research_enabled))
    tech_generation_rate = float(payload.get("tech_generation_rate", tech_generation_rate))
    tech_progress_buffer = float(payload.get("tech_progress_buffer", 0.0))
    production_queue = payload.get("production_queue", []).duplicate(true)
    damage_profile = payload.get("damage_profile", damage_profile).duplicate(true)
    attack_range = float(payload.get("attack_range", attack_range))
    vision = float(payload.get("vision", vision))
    attack_interval = float(payload.get("attack_interval", attack_interval))
    attack_timer = float(payload.get("attack_timer", 0.0))
    last_action = str(payload.get("last_action", "loaded"))


func _find_nearest_target(hostile_units: Array) -> Variant:
    var best_target: Variant = null
    var best_distance: float = INF
    var center: Vector2 = center_position()
    var effective_range: float = maxf(attack_range, vision)

    for hostile_unit in hostile_units:
        if hostile_unit == null or not hostile_unit.is_alive():
            continue

        var distance_to_target: float = center.distance_to(hostile_unit.position)
        if distance_to_target > effective_range:
            continue

        if distance_to_target < best_distance:
            best_distance = distance_to_target
            best_target = hostile_unit

    return best_target


func _damage_against_target(target: CombatUnitType) -> float:
    return maxf(4.0, float(damage_profile.get(target.unit_id, damage_profile.get("buildings", 4))))
