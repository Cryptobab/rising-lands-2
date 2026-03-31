class_name CombatUnitState
extends RefCounted

const WorkerUnitType = preload("res://scripts/simulation/worker_unit_state.gd")
const BuildingType = preload("res://scripts/simulation/building_state.gd")

var entity_id: int = -1
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
var base_vision: float = 6.0
var vision: float = 6.0
var base_attack_interval: float = 0.8
var attack_timer: float = 0.0
var base_armor: float = 0.0
var armor: float = 0.0
var base_speed: float = 2.8
var base_max_health: float = 75.0
var max_health: float = 75.0
var health: float = 75.0
var max_mana: float = 0.0
var mana: float = 0.0
var mana_regen: float = 0.0
var damage_profile: Dictionary = {}
var unit_color: Color = Color.WHITE
var state: String = "idle"
var target_ref: Variant = null
var target_kind: String = ""
var last_action: String = "spawned"
var enemy_ai: Dictionary = {}
var active_effects: Array = []
var spell_cooldowns: Dictionary = {}
var disabled_timer: float = 0.0
var pending_transport_id: int = -1
var boarded_transport_id: int = -1
var transport_capacity: int = 0
var passenger_ids: Array[int] = []


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
    base_vision = maxf(4.0, float(record.get("vision", 6)))
    vision = base_vision
    base_attack_interval = maxf(0.35, float(record.get("recharge", 30)) / 30.0)
    base_armor = float(record.get("armor", 0))
    armor = base_armor
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
    active_effects = []
    spell_cooldowns = {}
    disabled_timer = 0.0
    pending_transport_id = -1
    boarded_transport_id = -1
    transport_capacity = 0
    passenger_ids = []
    max_mana = 0.0
    mana = 0.0
    mana_regen = 0.0

    if unit_id == "druid":
        max_mana = 12.0
        mana = max_mana
        mana_regen = 0.18
    elif unit_id == "heliped":
        transport_capacity = 2
    elif unit_id == "balloon":
        transport_capacity = 4

    _refresh_unit_color()


func refresh_modifiers(world_state) -> void:
    if team != "player":
        return

    var previous_max: float = maxf(1.0, max_health)
    max_health = base_max_health * float(world_state.modifiers.get("combat_health", 1.0))
    health = clampf((health / previous_max) * max_health, 1.0 if health > 0.0 else 0.0, max_health)


func set_team(new_team: String) -> void:
    team = new_team
    if team != "enemy":
        enemy_ai = {}
    _refresh_unit_color()


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

    if is_boarded():
        has_move_target = false
        target_ref = null
        target_kind = ""
        attack_timer = 0.0
        state = "transported"
        last_action = "aboard transport"
        return

    _update_spell_state(delta)
    _regenerate(delta, world_state)

    if is_spell_disabled():
        has_move_target = false
        target_ref = null
        target_kind = ""
        attack_timer = 0.0
        state = "petrified"
        last_action = "held by magic"
        return

    if not _is_target_valid(target_ref):
        target_ref = null
        target_kind = ""

    var attack_mode: String = str(enemy_ai.get("attack_mode", "assault"))
    var has_rally_point: bool = bool(enemy_ai.get("has_rally_point", false))
    var group_ready: bool = bool(runtime_context.get("group_ready", true))
    var rally_locked: bool = team == "enemy" and attack_mode == "rally" and has_rally_point and not group_ready

    if target_ref == null and diplomacy_target_id.is_empty() and role != "civilian" and not rally_locked:
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
        var rally_point: Vector2 = _enemy_rally_point()
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
    pending_transport_id = -1
    move_target = new_target
    has_move_target = true
    target_ref = null
    target_kind = ""
    state = "moving"
    last_action = "moving"


func assign_attack_target(target: Variant, kind: String) -> void:
    clear_diplomacy_target()
    pending_transport_id = -1
    target_ref = target
    target_kind = kind
    has_move_target = false
    attack_timer = 0.0
    state = "engaging"
    last_action = "engaging %s" % kind


func assign_diplomacy_target(target_id: String, target_position: Vector2) -> void:
    pending_transport_id = -1
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


func assign_transport_target(transport_id: int, transport_position: Vector2) -> void:
    if transport_id < 0 or is_boarded():
        return
    clear_diplomacy_target()
    pending_transport_id = transport_id
    move_target = transport_position
    has_move_target = true
    target_ref = null
    target_kind = ""
    attack_timer = 0.0
    state = "boarding"
    last_action = "boarding transport"


func clear_runtime_references() -> void:
    target_ref = null
    target_kind = ""
    attack_timer = 0.0


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
    if is_boarded():
        return "aboard transport"
    return "%s %d hp" % [state, int(ceil(health))]


func is_boarded() -> bool:
    return boarded_transport_id >= 0


func can_transport() -> bool:
    return transport_capacity > 0


func can_cast_spell(spell_id: String, mana_cost: float) -> bool:
    if team != "player" or max_mana <= 0.0 or not is_alive():
        return false
    if float(spell_cooldowns.get(spell_id, 0.0)) > 0.0:
        return false
    return mana >= mana_cost


func spend_mana(amount: float) -> bool:
    if amount <= 0.0:
        return true
    if mana < amount:
        return false
    mana -= amount
    return true


func cooldown_for_spell(spell_id: String) -> float:
    return float(spell_cooldowns.get(spell_id, 0.0))


func set_spell_cooldown(spell_id: String, duration: float) -> void:
    spell_cooldowns[spell_id] = maxf(0.1, duration)


func apply_spell_effect(effect_payload: Dictionary) -> void:
    var effect_id: String = str(effect_payload.get("id", ""))
    if effect_id.is_empty():
        return

    var duration: float = maxf(0.1, float(effect_payload.get("duration", effect_payload.get("remaining", 0.0))))
    var next_effect: Dictionary = effect_payload.duplicate(true)
    next_effect["id"] = effect_id
    next_effect["remaining"] = duration

    var remaining_effects: Array = []
    for active_effect in active_effects:
        if str(active_effect.get("id", "")) == effect_id:
            continue
        remaining_effects.append(active_effect)
    remaining_effects.append(next_effect)
    active_effects = remaining_effects
    _refresh_spell_modifiers()


func is_spell_disabled() -> bool:
    return disabled_timer > 0.0


func spell_status_lines() -> Array[String]:
    var lines: Array[String] = []
    if can_transport():
        lines.append("Transport %d/%d" % [passenger_ids.size(), transport_capacity])
    if max_mana > 0.0:
        lines.append("Mana %.1f/%.1f" % [mana, max_mana])
    for spell_id in spell_cooldowns.keys():
        lines.append("%s cooldown %.1fs" % [str(spell_id), float(spell_cooldowns.get(spell_id, 0.0))])
    return lines


func serialize() -> Dictionary:
    return {
        "entity_id": entity_id,
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
        "base_armor": base_armor,
        "armor": armor,
        "base_speed": base_speed,
        "base_max_health": base_max_health,
        "max_health": max_health,
        "health": health,
        "base_vision": base_vision,
        "max_mana": max_mana,
        "mana": mana,
        "mana_regen": mana_regen,
        "damage_profile": damage_profile.duplicate(true),
        "state": state,
        "last_action": last_action,
        "enemy_ai": enemy_ai.duplicate(true),
        "active_effects": active_effects.duplicate(true),
        "spell_cooldowns": spell_cooldowns.duplicate(true),
        "pending_transport_id": pending_transport_id,
        "boarded_transport_id": boarded_transport_id,
        "transport_capacity": transport_capacity,
        "passenger_ids": passenger_ids.duplicate()
    }


func load_from_payload(payload: Dictionary, record: Dictionary) -> void:
    var position_payload: Dictionary = payload.get("position", {})
    configure_from_record(
        record,
        Vector2(float(position_payload.get("x", 0.0)), float(position_payload.get("y", 0.0))),
        str(payload.get("team", "player"))
    )

    entity_id = int(payload.get("entity_id", entity_id))
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
    base_vision = float(payload.get("base_vision", base_vision))
    vision = float(payload.get("vision", vision))
    base_attack_interval = float(payload.get("base_attack_interval", base_attack_interval))
    attack_timer = float(payload.get("attack_timer", 0.0))
    base_armor = float(payload.get("base_armor", base_armor))
    armor = float(payload.get("armor", armor))
    base_speed = float(payload.get("base_speed", base_speed))
    base_max_health = float(payload.get("base_max_health", base_max_health))
    max_health = float(payload.get("max_health", max_health))
    health = float(payload.get("health", health))
    max_mana = float(payload.get("max_mana", max_mana))
    mana = float(payload.get("mana", mana))
    mana_regen = float(payload.get("mana_regen", mana_regen))
    damage_profile = payload.get("damage_profile", damage_profile).duplicate(true)
    state = str(payload.get("state", state))
    last_action = str(payload.get("last_action", last_action))
    enemy_ai = payload.get("enemy_ai", {}).duplicate(true)
    active_effects = payload.get("active_effects", []).duplicate(true)
    spell_cooldowns = payload.get("spell_cooldowns", {}).duplicate(true)
    pending_transport_id = int(payload.get("pending_transport_id", -1))
    boarded_transport_id = int(payload.get("boarded_transport_id", -1))
    transport_capacity = int(payload.get("transport_capacity", transport_capacity))
    passenger_ids = []
    for passenger_id in payload.get("passenger_ids", []):
        passenger_ids.append(int(passenger_id))
    target_ref = null
    target_kind = ""
    _refresh_spell_modifiers()


func _update_spell_state(delta: float) -> void:
    if max_mana > 0.0 and mana < max_mana:
        mana = minf(max_mana, mana + (delta * mana_regen))

    var next_cooldowns: Dictionary = {}
    for spell_id in spell_cooldowns.keys():
        var next_value: float = maxf(0.0, float(spell_cooldowns.get(spell_id, 0.0)) - delta)
        if next_value > 0.0:
            next_cooldowns[spell_id] = next_value
    spell_cooldowns = next_cooldowns

    if active_effects.is_empty():
        _refresh_spell_modifiers()
        return

    var next_effects: Array = []
    for effect in active_effects:
        var remaining: float = float(effect.get("remaining", 0.0)) - delta
        if remaining <= 0.0:
            continue
        var next_effect: Dictionary = effect.duplicate(true)
        next_effect["remaining"] = remaining
        next_effects.append(next_effect)
    active_effects = next_effects
    _refresh_spell_modifiers()


func _refresh_spell_modifiers() -> void:
    armor = base_armor
    vision = base_vision
    disabled_timer = 0.0

    for effect in active_effects:
        var effect_id: String = str(effect.get("id", ""))
        match effect_id:
            "armour":
                armor += float(effect.get("armor_bonus", 0.0))
            "vision":
                vision = maxf(vision, base_vision + float(effect.get("vision_bonus", 0.0)))
            "petrification":
                disabled_timer = maxf(disabled_timer, float(effect.get("remaining", 0.0)))
            _:
                pass

    vision = maxf(4.0, vision)


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
        if hostile_unit == null or not hostile_unit.is_alive() or hostile_unit.is_boarded():
            continue

        var distance_to_target: float = position.distance_to(hostile_unit.position)
        if distance_to_target < best_distance and distance_to_target <= vision:
            best_distance = distance_to_target
            best_target = hostile_unit
            best_kind = "unit"

    for hostile_worker in hostile_workers:
        if hostile_worker == null or not hostile_worker.is_alive() or hostile_worker.is_boarded():
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
                if hostile_unit == null or not hostile_unit.is_alive() or hostile_unit.is_boarded():
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
                if hostile_worker == null or not hostile_worker.is_alive() or hostile_worker.is_boarded():
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
        return target.is_alive() and not target.is_boarded()
    if target is WorkerUnitType:
        return target.is_alive() and not target.is_boarded()
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


func _refresh_unit_color() -> void:
    if team == "enemy":
        unit_color = Color("e15c55")
        return

    match role:
        "ranged":
            unit_color = Color("70b8e8")
        "magic":
            unit_color = Color("55d6b7")
        _:
            unit_color = Color("ca7753")
