class_name WorkerUnitState
extends RefCounted

var team: String = "player"
var unit_id: String = ""
var name: String = ""
var role: String = ""
var position: Vector2 = Vector2.ZERO
var move_target: Vector2 = Vector2.ZERO
var has_move_target: bool = false
var home_position: Vector2 = Vector2.ZERO
var job_resource_type: String = ""
var state: String = "idle"
var carry_type: String = ""
var carry_amount: int = 0
var base_carry_capacity: int = 1
var base_gather_interval: float = 1.0
var work_timer: float = 0.0
var base_speed: float = 3.0
var armor: float = 0.0
var max_health: float = 60.0
var health: float = 60.0
var manual_hold: bool = false
var target_resource_index: int = -1
var target_construction_index: int = -1
var unit_color: Color = Color.WHITE
var last_action: String = "spawned"


func configure_from_record(record: Dictionary, spawn_position: Vector2, new_home_position: Vector2) -> void:
    team = "player"
    unit_id = str(record.get("id", ""))
    name = str(record.get("name", unit_id))
    role = str(record.get("role", ""))
    position = spawn_position
    move_target = spawn_position
    has_move_target = false
    home_position = new_home_position
    armor = float(record.get("armor", 0))

    var total_cost: int = 0
    for resource_value in record.get("cost", {}).values():
        total_cost += int(resource_value)

    max_health = float(maxi(45, 50 + int(armor * 12.0) + (total_cost * 2)))
    health = max_health

    match unit_id:
        "farmer":
            job_resource_type = "food"
            base_carry_capacity = 4
            unit_color = Color("8ab648")
        "builder":
            job_resource_type = "stone"
            base_carry_capacity = 4
            unit_color = Color("c0c0c0")
        "mechanic":
            job_resource_type = "parts"
            base_carry_capacity = 3
            unit_color = Color("c09050")
        _:
            job_resource_type = ""
            base_carry_capacity = 1
            unit_color = Color("70b8e8")

    var recharge: int = int(record.get("recharge", 100))
    base_gather_interval = maxf(0.35, float(recharge) / 200.0)
    base_speed = 2.4 + minf(0.8, float(record.get("vision", 5)) * 0.05)
    state = "seeking_resource"
    last_action = "seeking %s" % job_resource_type


func update(
    delta: float,
    resource_nodes: Array,
    stockpile: Dictionary,
    construction_sites: Array = [],
    world_state = null
) -> void:
    if not is_alive():
        state = "dead"
        return

    _regenerate(delta, world_state)

    if job_resource_type.is_empty():
        state = "idle"
        return

    if has_move_target:
        if position.distance_to(move_target) > 0.1:
            state = "moving"
            _move_towards(move_target, delta, world_state)
            return
        has_move_target = false
        manual_hold = true
        state = "holding"
        last_action = "holding position"
        return

    if manual_hold and carry_amount <= 0 and target_resource_index < 0 and target_construction_index < 0:
        state = "holding"
        return

    if target_construction_index >= 0:
        _update_construction(delta, construction_sites, world_state)
        return

    if carry_amount > 0:
        _update_return_home(delta, stockpile, world_state)
        return

    if target_resource_index < 0 or target_resource_index >= resource_nodes.size():
        target_resource_index = _find_nearest_resource_index(resource_nodes)

    if target_resource_index < 0:
        state = "idle"
        last_action = "waiting for %s" % job_resource_type
        return

    var target_resource = resource_nodes[target_resource_index]
    if target_resource.depleted():
        target_resource_index = -1
        state = "seeking_resource"
        last_action = "reassigning"
        return

    var target_position: Vector2 = Vector2(target_resource.tile) + Vector2(0.5, 0.5)
    if position.distance_to(target_position) > 0.1:
        state = "to_%s" % target_resource.resource_type
        _move_towards(target_position, delta, world_state)
        return

    state = "gathering"
    work_timer += delta
    if work_timer < current_gather_interval(world_state):
        return

    work_timer = 0.0
    var harvested: int = target_resource.harvest(1)
    if harvested <= 0:
        target_resource_index = -1
        return

    carry_type = target_resource.resource_type
    carry_amount += harvested
    last_action = "harvested %d %s" % [carry_amount, carry_type]

    if carry_amount >= current_carry_capacity(world_state) or target_resource.depleted():
        state = "returning"


func status_text() -> String:
    if target_construction_index >= 0:
        return "%s build" % state
    if carry_amount > 0:
        return "%s %d/%d %s" % [state, carry_amount, base_carry_capacity, carry_type]
    return "%s %s" % [state, job_resource_type]


func assign_resource_target(resource_index: int) -> void:
    manual_hold = false
    has_move_target = false
    target_resource_index = resource_index
    target_construction_index = -1
    carry_amount = 0
    carry_type = ""
    work_timer = 0.0
    state = "seeking_resource"
    last_action = "ordered to gather %s" % job_resource_type


func assign_construction_target(site_index: int) -> void:
    if unit_id != "builder":
        return
    manual_hold = false
    has_move_target = false
    target_construction_index = site_index
    target_resource_index = -1
    carry_amount = 0
    carry_type = ""
    work_timer = 0.0
    state = "to_build"
    last_action = "ordered to build"


func assign_move_target(new_target: Vector2) -> void:
    manual_hold = true
    move_target = new_target
    has_move_target = true
    target_resource_index = -1
    target_construction_index = -1
    carry_amount = 0
    carry_type = ""
    work_timer = 0.0
    state = "moving"
    last_action = "moving"


func clear_orders() -> void:
    target_resource_index = -1
    target_construction_index = -1
    has_move_target = false
    carry_amount = 0
    carry_type = ""
    work_timer = 0.0
    manual_hold = false
    state = "idle"
    last_action = "orders cleared"


func set_home_position(new_home_position: Vector2) -> void:
    home_position = new_home_position


func current_carry_capacity(world_state = null) -> int:
    if world_state == null:
        return base_carry_capacity
    return maxi(1, int(round(float(base_carry_capacity) * float(world_state.modifiers.get("worker_carry", 1.0)))))


func current_gather_interval(world_state = null) -> float:
    if world_state == null:
        return base_gather_interval
    return maxf(0.2, base_gather_interval / maxf(0.1, float(world_state.modifiers.get("worker_gather", 1.0))))


func current_speed(world_state = null) -> float:
    if world_state == null:
        return base_speed
    return base_speed * float(world_state.modifiers.get("worker_speed", 1.0))


func apply_damage(amount: float) -> bool:
    var mitigated: float = maxf(1.0, amount - (armor * 1.2))
    health = maxf(0.0, health - mitigated)
    if health <= 0.0:
        clear_orders()
        state = "dead"
        last_action = "fell in battle"
        return true
    return false


func is_alive() -> bool:
    return health > 0.0


func serialize() -> Dictionary:
    return {
        "team": team,
        "unit_id": unit_id,
        "name": name,
        "role": role,
        "position": {"x": position.x, "y": position.y},
        "move_target": {"x": move_target.x, "y": move_target.y},
        "has_move_target": has_move_target,
        "home_position": {"x": home_position.x, "y": home_position.y},
        "job_resource_type": job_resource_type,
        "state": state,
        "carry_type": carry_type,
        "carry_amount": carry_amount,
        "base_carry_capacity": base_carry_capacity,
        "base_gather_interval": base_gather_interval,
        "work_timer": work_timer,
        "base_speed": base_speed,
        "armor": armor,
        "max_health": max_health,
        "health": health,
        "manual_hold": manual_hold,
        "target_resource_index": target_resource_index,
        "target_construction_index": target_construction_index,
        "last_action": last_action
    }


func load_from_payload(payload: Dictionary, record: Dictionary) -> void:
    var spawn_position_payload: Dictionary = payload.get("position", {})
    var home_position_payload: Dictionary = payload.get("home_position", {})
    configure_from_record(
        record,
        Vector2(float(spawn_position_payload.get("x", 0.0)), float(spawn_position_payload.get("y", 0.0))),
        Vector2(float(home_position_payload.get("x", 0.0)), float(home_position_payload.get("y", 0.0)))
    )
    var move_target_payload: Dictionary = payload.get("move_target", {})
    team = str(payload.get("team", "player"))
    name = str(payload.get("name", name))
    move_target = Vector2(float(move_target_payload.get("x", position.x)), float(move_target_payload.get("y", position.y)))
    has_move_target = bool(payload.get("has_move_target", false))
    job_resource_type = str(payload.get("job_resource_type", job_resource_type))
    state = str(payload.get("state", "idle"))
    carry_type = str(payload.get("carry_type", ""))
    carry_amount = int(payload.get("carry_amount", 0))
    base_carry_capacity = int(payload.get("base_carry_capacity", base_carry_capacity))
    base_gather_interval = float(payload.get("base_gather_interval", base_gather_interval))
    work_timer = float(payload.get("work_timer", 0.0))
    base_speed = float(payload.get("base_speed", base_speed))
    armor = float(payload.get("armor", armor))
    max_health = float(payload.get("max_health", max_health))
    health = float(payload.get("health", health))
    manual_hold = bool(payload.get("manual_hold", false))
    target_resource_index = int(payload.get("target_resource_index", -1))
    target_construction_index = int(payload.get("target_construction_index", -1))
    last_action = str(payload.get("last_action", last_action))


func _update_return_home(delta: float, stockpile: Dictionary, world_state) -> void:
    if position.distance_to(home_position) > 0.1:
        state = "returning"
        _move_towards(home_position, delta, world_state)
        return

    stockpile[carry_type] = int(stockpile.get(carry_type, 0)) + carry_amount
    last_action = "deposited %d %s" % [carry_amount, carry_type]
    carry_amount = 0
    carry_type = ""
    state = "seeking_resource"
    target_resource_index = -1


func _move_towards(target_position: Vector2, delta: float, world_state = null) -> void:
    position = position.move_toward(target_position, current_speed(world_state) * delta)


func _find_nearest_resource_index(resource_nodes: Array) -> int:
    var best_index: int = -1
    var best_distance: float = INF

    for index in range(resource_nodes.size()):
        var resource_node = resource_nodes[index]
        if resource_node.resource_type != job_resource_type or resource_node.depleted():
            continue

        var resource_position: Vector2 = Vector2(resource_node.tile) + Vector2(0.5, 0.5)
        var distance_to_resource: float = position.distance_to(resource_position)
        if distance_to_resource < best_distance:
            best_distance = distance_to_resource
            best_index = index

    return best_index


func _update_construction(delta: float, construction_sites: Array, world_state = null) -> void:
    if unit_id != "builder":
        target_construction_index = -1
        return

    if target_construction_index < 0 or target_construction_index >= construction_sites.size():
        target_construction_index = -1
        state = "idle"
        return

    var construction_site = construction_sites[target_construction_index]
    if construction_site.built:
        target_construction_index = -1
        state = "idle"
        last_action = "build complete"
        return

    var target_position: Vector2 = Vector2(construction_site.tile) + Vector2(0.5, 0.5)
    if position.distance_to(target_position) > 0.12:
        state = "to_build"
        _move_towards(target_position, delta, world_state)
        return

    state = "building"
    work_timer += delta
    if work_timer < 0.35:
        return

    work_timer = 0.0
    var build_amount: float = 8.0
    if world_state != null:
        build_amount *= float(world_state.modifiers.get("build_speed", 1.0))

    if construction_site.advance(build_amount):
        target_construction_index = -1
        state = "idle"
        last_action = "completed %s" % construction_site.name
    else:
        last_action = "building %s" % construction_site.name


func _regenerate(delta: float, world_state) -> void:
    if world_state == null:
        return

    var regeneration_rate: float = float(world_state.modifiers.get("regeneration", 0.0))
    if regeneration_rate <= 0.0 or health >= max_health:
        return

    health = minf(max_health, health + (delta * regeneration_rate * 5.0))
