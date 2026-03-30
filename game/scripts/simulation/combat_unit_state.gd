class_name CombatUnitState
extends RefCounted

const WorkerUnitType = preload("res://scripts/simulation/worker_unit_state.gd")
const BuildingType = preload("res://scripts/simulation/building_state.gd")

var team: String = "player"
var unit_id: String = ""
var name: String = ""
var role: String = ""
var position: Vector2 = Vector2.ZERO
var diplomacy_target_id: String = ""
var diplomacy_target_position: Vector2 = Vector2.ZERO
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false
var attack_range: float = 1.0
var vision: float = 6.0
var base_attack_interval: float = 0.8
var attack_timer: float = 0.0
var armor: float = 0.0
var base_speed: float = 2.8
var base_max_health: float = 75.0
var max_health: float = 75.0
var health: float = 75.0
var damage_profile: Dictionary = {}
var unit_color: Color = Color.WHITE
var state: String = "idle"
var target_ref: Variant = null
var target_kind: String = ""
var last_action: String = "spawned"
var enemy_ai: Dictionary = {}


func configure_from_record(record: Dictionary, spawn_position: Vector2, new_team: String = "player") -> void:
    team = new_team
    unit_id = str(record.get("id", ""))
    name = str(record.get("name", unit_id))
    role = str(record.get("role", ""))
    position = spawn_position
    diplomacy_target_id = ""
    diplomacy_target_position = spawn_position
    move_target = spawn_position
    has_move_target = false
    attack_range = maxf(1.0, float(record.get("range", 1)))
    vision = maxf(4.0, float(record.get("vision", 6)))
    base_attack_interval = maxf(0.35, float(record.get("recharge", 30)) / 30.0)
    armor = float(record.get("armor", 0))
    damage_profile = record.get("damage_profile", {}).duplicate(true)

    var total_cost: int = 0
    for resource_value in record.get("cost", {}).values():
        total_cost += int(resource_value)

    base_speed = 2.1 + minf(0.9, vision * 0.05)
    base_max_health = float(maxi(55, 65 + int(armor * 20.0) + (total_cost * 4)))
    max_health = base_max_health
    health = max_health
    attack_timer = 0.0
    target_ref = null
    target_kind = ""
    state = "idle"
    last_action = "awaiting orders"
    enemy_ai = {}

    if team == "enemy":
        unit_color = Color("e15c55")
    else:
        match role:
            "ranged":
                unit_color = Color("70b8e8")
            "magic":
                unit_color = Color("55d6b7")
            _:
                unit_color = Color("ca7753")


func refresh_modifiers(world_state) -> void:
    if team != "player":
        return

    var previous_max: float = maxf(1.0, max_health)
    max_health = base_max_health * float(world_state.modifiers.get("combat_health", 1.0))
    health = clampf((health / previous_max) * max_health, 1.0 if health > 0.0 else 0.0, max_health)


func update(
    delta: float,
    world_state,
    hostile_units: Array,
    hostile_workers: Array = [],
    hostile_buildings: Array = [],
    allied_units: Array = [],
    runtime_context: Dictionary = {}
) -> void:
    if not is_alive():
        state = "dead"
        return

    _regenerate(delta, world_state)

    if not _is_target_valid(target_ref):
        target_ref = null
        target_kind = ""

    if target_ref == null and diplomacy_target_id.is_empty() and role != "civilian":
        var target_payload: Dictionary = _find_nearest_target(
            hostile_units,
            hostile_workers,
            hostile_buildings,
            _enemy_target_priority(),
            _enemy_target_focus_position(),
            _enemy_target_focus_bias()
        )
        target_ref = target_payload.get("target", null)
        target_kind = str(target_payload.get("kind", ""))

    if team == "enemy" and target_ref == null and diplomacy_target_id.is_empty() and role != "civilian":
        var pressure_target: Vector2 = _enemy_pressure_target(hostile_units, hostile_workers, hostile_buildings)
        var attack_mode: String = str(enemy_ai.get("attack_mode", "assault"))
        var rally_point: Vector2 = _enemy_rally_point()
        var has_rally_point: bool = bool(enemy_ai.get("has_rally_point", false))
        var group_ready: bool = bool(runtime_context.get("group_ready", true))
        if attack_mode == "hold":
            var hold_point: Vector2 = rally_point if has_rally_point else pressure_target
            if hold_point != Vector2.ZERO:
                _hold_position(hold_point, float(enemy_ai.get("hold_radius", 1.35)), "holding ground")
        elif attack_mode == "rally" and has_rally_point and not group_ready:
            _hold_position(rally_point, float(enemy_ai.get("release_radius", 2.25)), "forming attack group")
        if pressure_target != Vector2.ZERO and (not has_move_target or position.distance_to(move_target) <= 0.35):
            if attack_mode != "hold" and not (attack_mode == "rally" and has_rally_point and not group_ready):
                move_target = pressure_target
                has_move_target = true
                state = "advancing"
                last_action = "advancing on settlement"

    if target_ref != null:
        var target_position: Vector2 = _target_position(target_ref)
        if position.distance_to(target_position) > attack_range:
            state = "engaging"
            _move_towards(target_position, delta)
            return

        state = "attacking"
        attack_timer += delta
        if attack_timer < base_attack_interval:
            return

        attack_timer = 0.0
        var damage_amount: float = _damage_against_target(target_ref)
        if team == "player":
            damage_amount *= float(world_state.modifiers.get("combat_damage", 1.0))

        if target_ref is CombatUnitState:
            target_ref.apply_damage(damage_amount)
        elif target_ref is WorkerUnitType:
            target_ref.apply_damage(damage_amount)
        elif target_ref is BuildingType:
            target_ref.apply_damage(damage_amount)

        last_action = "hit %s" % target_kind
        if not _is_target_valid(target_ref):
            target_ref = null
            target_kind = ""
        return

    if has_move_target:
        if position.distance_to(move_target) > 0.15:
            state = "moving"
            _move_towards(move_target, delta)
        else:
            has_move_target = false
            state = "holding"
    else:
        state = "holding"


func assign_move_target(new_target: Vector2) -> void:
    clear_diplomacy_target()
    move_target = new_target
    has_move_target = true
    target_ref = null
    target_kind = ""
    state = "moving"
    last_action = "moving"


func assign_attack_target(target: Variant, kind: String) -> void:
    clear_diplomacy_target()
    target_ref = target
    target_kind = kind
    has_move_target = false
    attack_timer = 0.0
    state = "engaging"
    last_action = "engaging %s" % kind


func assign_diplomacy_target(target_id: String, target_position: Vector2) -> void:
    diplomacy_target_id = target_id
    diplomacy_target_position = target_position
    move_target = target_position
    has_move_target = true
    target_ref = null
    target_kind = ""
    attack_timer = 0.0
    state = "messaging"
    last_action = "bearing message"


func clear_diplomacy_target() -> void:
    diplomacy_target_id = ""
    diplomacy_target_position = Vector2.ZERO


func clear_runtime_references() -> void:
    target_ref = null
    target_kind = ""


func set_enemy_ai_directive(directive: Dictionary) -> void:
    if team != "enemy":
        return
    enemy_ai = directive.duplicate(true)


func apply_damage(amount: float) -> bool:
    var mitigated: float = maxf(1.0, amount - (armor * 1.4))
    health = maxf(0.0, health - mitigated)
    if health <= 0.0:
        state = "dead"
        target_ref = null
        target_kind = ""
        clear_diplomacy_target()
        last_action = "destroyed"
        return true
    return false


func is_alive() -> bool:
    return health > 0.0


func status_text() -> String:
    return "%s %d hp" % [state, int(ceil(health))]


func serialize() -> Dictionary:
    return {
        "team": team,
        "unit_id": unit_id,
        "name": name,
        "role": role,
        "position": {"x": position.x, "y": position.y},
        "diplomacy_target_id": diplomacy_target_id,
        "diplomacy_target_position": {"x": diplomacy_target_position.x, "y": diplomacy_target_position.y},
        "move_target": {"x": move_target.x, "y": move_target.y},
        "has_move_target": has_move_target,
        "attack_range": attack_range,
        "vision": vision,
        "base_attack_interval": base_attack_interval,
        "attack_timer": attack_timer,
        "armor": armor,
        "base_speed": base_speed,
        "base_max_health": base_max_health,
        "max_health": max_health,
        "health": health,
        "damage_profile": damage_profile.duplicate(true),
        "state": state,
        "last_action": last_action,
        "enemy_ai": enemy_ai.duplicate(true)
    }


func load_from_payload(payload: Dictionary, record: Dictionary) -> void:
    var position_payload: Dictionary = payload.get("position", {})
    configure_from_record(
        record,
        Vector2(float(position_payload.get("x", 0.0)), float(position_payload.get("y", 0.0))),
        str(payload.get("team", "player"))
    )

    name = str(payload.get("name", name))
    role = str(payload.get("role", role))

    diplomacy_target_id = str(payload.get("diplomacy_target_id", ""))
    var diplomacy_target_payload: Dictionary = payload.get("diplomacy_target_position", {})
    diplomacy_target_position = Vector2(
        float(diplomacy_target_payload.get("x", position.x)),
        float(diplomacy_target_payload.get("y", position.y))
    )

    var move_target_payload: Dictionary = payload.get("move_target", {})
    move_target = Vector2(float(move_target_payload.get("x", position.x)), float(move_target_payload.get("y", position.y)))
    has_move_target = bool(payload.get("has_move_target", false))
    attack_range = float(payload.get("attack_range", attack_range))
    vision = float(payload.get("vision", vision))
    base_attack_interval = float(payload.get("base_attack_interval", base_attack_interval))
    attack_timer = float(payload.get("attack_timer", 0.0))
    armor = float(payload.get("armor", armor))
    base_speed = float(payload.get("base_speed", base_speed))
    base_max_health = float(payload.get("base_max_health", base_max_health))
    max_health = float(payload.get("max_health", max_health))
    health = float(payload.get("health", health))
    damage_profile = payload.get("damage_profile", damage_profile).duplicate(true)
    state = str(payload.get("state", state))
    last_action = str(payload.get("last_action", last_action))
    enemy_ai = payload.get("enemy_ai", {}).duplicate(true)
    target_ref = null
    target_kind = ""


func _move_towards(target_position: Vector2, delta: float) -> void:
    position = position.move_toward(target_position, base_speed * delta)


func _find_nearest_target(
    hostile_units: Array,
    hostile_workers: Array,
    hostile_buildings: Array,
    priority_order: Array = [],
    focus_position: Vector2 = Vector2.ZERO,
    focus_bias: float = 0.0
) -> Dictionary:
    var immediate_target: Dictionary = _find_immediate_target(hostile_units, hostile_workers)
    if immediate_target.get("target", null) != null:
        return immediate_target

    var effective_priority: Array = priority_order.duplicate()
    if effective_priority.is_empty():
        effective_priority = ["unit", "worker", "building"]

    for target_kind_id in effective_priority:
        var target_payload: Dictionary = _find_nearest_target_of_kind(
            str(target_kind_id),
            hostile_units,
            hostile_workers,
            hostile_buildings,
            focus_position,
            focus_bias
        )
        if target_payload.get("target", null) != null:
            return target_payload

    var best_target: Variant = null
    var best_kind: String = ""
    var best_distance: float = INF

    for hostile_unit in hostile_units:
        if hostile_unit == null or not hostile_unit.is_alive():
            continue

        var distance_to_target: float = position.distance_to(hostile_unit.position)
        if distance_to_target < best_distance and distance_to_target <= vision:
            best_distance = distance_to_target
            best_target = hostile_unit
            best_kind = "unit"

    for hostile_worker in hostile_workers:
        if hostile_worker == null or not hostile_worker.is_alive():
            continue

        var distance_to_target: float = position.distance_to(hostile_worker.position)
        if distance_to_target < best_distance and distance_to_target <= vision:
            best_distance = distance_to_target
            best_target = hostile_worker
            best_kind = "worker"

    for hostile_building in hostile_buildings:
        if hostile_building == null or not hostile_building.is_alive():
            continue

        var distance_to_target: float = position.distance_to(hostile_building.center_position())
        if distance_to_target < best_distance and distance_to_target <= vision:
            best_distance = distance_to_target
            best_target = hostile_building
            best_kind = "building"

    return {"target": best_target, "kind": best_kind}


func _find_immediate_target(hostile_units: Array, hostile_workers: Array) -> Dictionary:
    var threat_radius: float = maxf(attack_range + 1.2, 2.75)
    var best_target: Variant = null
    var best_kind: String = ""
    var best_distance: float = INF

    for hostile_unit in hostile_units:
        if hostile_unit == null or not hostile_unit.is_alive():
            continue

        var distance_to_target: float = position.distance_to(hostile_unit.position)
        if distance_to_target <= threat_radius and distance_to_target < best_distance:
            best_distance = distance_to_target
            best_target = hostile_unit
            best_kind = "unit"

    for hostile_worker in hostile_workers:
        if hostile_worker == null or not hostile_worker.is_alive():
            continue

        var distance_to_target: float = position.distance_to(hostile_worker.position)
        if distance_to_target <= threat_radius and distance_to_target < best_distance:
            best_distance = distance_to_target
            best_target = hostile_worker
            best_kind = "worker"

    return {"target": best_target, "kind": best_kind}


func _find_nearest_target_of_kind(
    kind: String,
    hostile_units: Array,
    hostile_workers: Array,
    hostile_buildings: Array,
    focus_position: Vector2,
    focus_bias: float
) -> Dictionary:
    var best_target: Variant = null
    var best_score: float = INF

    match kind:
        "unit":
            for hostile_unit in hostile_units:
                if hostile_unit == null or not hostile_unit.is_alive():
                    continue
                var distance_to_target: float = position.distance_to(hostile_unit.position)
                if distance_to_target > vision:
                    continue
                var score: float = _target_score(hostile_unit.position, focus_position, focus_bias)
                if score < best_score:
                    best_score = score
                    best_target = hostile_unit
        "worker":
            for hostile_worker in hostile_workers:
                if hostile_worker == null or not hostile_worker.is_alive():
                    continue
                var distance_to_target: float = position.distance_to(hostile_worker.position)
                if distance_to_target > vision:
                    continue
                var score: float = _target_score(hostile_worker.position, focus_position, focus_bias)
                if score < best_score:
                    best_score = score
                    best_target = hostile_worker
        "deposit", "building":
            for hostile_building in hostile_buildings:
                if hostile_building == null or not hostile_building.is_alive():
                    continue
                if kind == "deposit" and not hostile_building.supports_deposit():
                    continue
                var target_position: Vector2 = hostile_building.center_position()
                var distance_to_target: float = position.distance_to(target_position)
                if distance_to_target > vision:
                    continue
                var score: float = _target_score(target_position, focus_position, focus_bias)
                if kind == "deposit":
                    score -= 0.4
                if score < best_score:
                    best_score = score
                    best_target = hostile_building
        _:
            pass

    return {"target": best_target, "kind": kind if best_target != null else ""}


func _target_position(target: Variant) -> Vector2:
    if target is CombatUnitState:
        return target.position
    if target is WorkerUnitType:
        return target.position
    if target is BuildingType:
        return target.center_position()
    return position


func _damage_against_target(target: Variant) -> float:
    if target is BuildingType:
        return maxf(4.0, float(damage_profile.get("buildings", 4)))
    if target is CombatUnitState:
        return maxf(4.0, float(damage_profile.get(target.unit_id, 8)))
    if target is WorkerUnitType:
        return maxf(4.0, float(damage_profile.get(target.unit_id, 10)))
    return 5.0


func _is_target_valid(target: Variant) -> bool:
    if target == null:
        return false
    if target is CombatUnitState:
        return target.is_alive()
    if target is WorkerUnitType:
        return target.is_alive()
    if target is BuildingType:
        return target.is_alive()
    return false


func _regenerate(delta: float, world_state) -> void:
    if team != "player":
        return

    var regeneration_rate: float = float(world_state.modifiers.get("regeneration", 0.0))
    if regeneration_rate <= 0.0 or health >= max_health:
        return

    health = minf(max_health, health + (delta * regeneration_rate * 4.0))


func _enemy_pressure_target(hostile_units: Array, hostile_workers: Array, hostile_buildings: Array) -> Vector2:
    if not enemy_ai.is_empty():
        var pressure_priority: Array = _enemy_pressure_priority()
        var focus_position: Vector2 = _enemy_target_focus_position()
        var focus_bias: float = _enemy_target_focus_bias()
        for pressure_kind in pressure_priority:
            var pressure_payload: Dictionary = _find_nearest_target_of_kind(
                str(pressure_kind),
                hostile_units,
                hostile_workers,
                hostile_buildings,
                focus_position,
                focus_bias
            )
            var pressure_target = pressure_payload.get("target", null)
            if pressure_target == null:
                continue
            return _target_position(pressure_target)

        var pressure_point: Vector2 = _enemy_pressure_point()
        if pressure_point != Vector2.ZERO:
            return pressure_point

    var best_position: Vector2 = Vector2.ZERO
    var best_distance: float = INF

    for hostile_building in hostile_buildings:
        if hostile_building == null or not hostile_building.is_alive():
            continue

        var building_position: Vector2 = hostile_building.center_position()
        var building_distance: float = position.distance_to(building_position)
        if hostile_building.supports_deposit():
            building_distance -= 1.4

        if building_distance < best_distance:
            best_distance = building_distance
            best_position = building_position

    for hostile_worker in hostile_workers:
        if hostile_worker == null or not hostile_worker.is_alive():
            continue

        var worker_distance: float = position.distance_to(hostile_worker.position)
        if worker_distance < best_distance:
            best_distance = worker_distance
            best_position = hostile_worker.position

    return best_position


func _enemy_target_priority() -> Array:
    if team != "enemy":
        return []

    var configured_priority: Array = enemy_ai.get("target_priority", [])
    if not configured_priority.is_empty():
        return configured_priority.duplicate()

    var attack_mode: String = str(enemy_ai.get("attack_mode", "assault"))
    match attack_mode:
        "raid":
            return ["worker", "deposit", "building", "unit"]
        "siege":
            return ["deposit", "building", "worker", "unit"]
        "hold":
            return ["unit", "worker", "deposit", "building"]
        _:
            return ["unit", "worker", "deposit", "building"]


func _enemy_pressure_priority() -> Array:
    var pressure_rule: String = str(enemy_ai.get("pressure_rule", "settlement"))
    match pressure_rule:
        "workers":
            return ["worker", "deposit", "building", "unit"]
        "buildings":
            return ["deposit", "building", "worker", "unit"]
        "units":
            return ["unit", "worker", "deposit", "building"]
        "defend":
            return []
        _:
            return _enemy_target_priority()


func _enemy_target_focus_position() -> Vector2:
    var pressure_point: Vector2 = _enemy_pressure_point()
    if pressure_point != Vector2.ZERO:
        return pressure_point

    return _enemy_rally_point()


func _enemy_target_focus_bias() -> float:
    var pressure_rule: String = str(enemy_ai.get("pressure_rule", "settlement"))
    match pressure_rule:
        "workers":
            return 0.2
        "buildings":
            return 0.35
        "target_point":
            return 0.8
        _:
            return 0.1 if _enemy_target_focus_position() != Vector2.ZERO else 0.0


func _enemy_rally_point() -> Vector2:
    if not bool(enemy_ai.get("has_rally_point", false)):
        return Vector2.ZERO
    return _vector_from_payload(enemy_ai.get("rally_point", {}), Vector2.ZERO)


func _enemy_pressure_point() -> Vector2:
    if not bool(enemy_ai.get("has_pressure_point", false)):
        return Vector2.ZERO
    return _vector_from_payload(enemy_ai.get("pressure_point", {}), Vector2.ZERO)


func _hold_position(target_position: Vector2, radius: float, action_text: String) -> void:
    var effective_radius: float = maxf(0.35, radius)
    if position.distance_to(target_position) > effective_radius:
        move_target = target_position
        has_move_target = true
        state = "rallying"
        last_action = action_text
    else:
        has_move_target = false
        state = "holding"
        last_action = action_text


func _target_score(target_position: Vector2, focus_position: Vector2, focus_bias: float) -> float:
    var score: float = position.distance_to(target_position)
    if focus_position != Vector2.ZERO and focus_bias > 0.0:
        score += target_position.distance_to(focus_position) * focus_bias
    return score


func _vector_from_payload(payload: Variant, fallback: Vector2) -> Vector2:
    if typeof(payload) != TYPE_DICTIONARY:
        return fallback

    var point_payload: Dictionary = payload
    return Vector2(
        float(point_payload.get("x", fallback.x)),
        float(point_payload.get("y", fallback.y))
    )
