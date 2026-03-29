class_name WorkerUnitState
extends RefCounted

var unit_id: String = ""
var name: String = ""
var role: String = ""
var position: Vector2 = Vector2.ZERO
var home_position: Vector2 = Vector2.ZERO
var job_resource_type: String = ""
var state: String = "idle"
var carry_type: String = ""
var carry_amount: int = 0
var carry_capacity: int = 1
var gather_interval: float = 1.0
var work_timer: float = 0.0
var speed: float = 3.0
var target_resource_index: int = -1
var target_construction_index: int = -1
var unit_color: Color = Color.WHITE
var last_action: String = "spawned"


func configure_from_record(record: Dictionary, spawn_position: Vector2, new_home_position: Vector2) -> void:
    unit_id = str(record.get("id", ""))
    name = str(record.get("name", unit_id))
    role = str(record.get("role", ""))
    position = spawn_position
    home_position = new_home_position

    match unit_id:
        "farmer":
            job_resource_type = "food"
            carry_capacity = 4
            unit_color = Color("8ab648")
        "builder":
            job_resource_type = "stone"
            carry_capacity = 4
            unit_color = Color("c0c0c0")
        "mechanic":
            job_resource_type = "parts"
            carry_capacity = 3
            unit_color = Color("c09050")
        _:
            job_resource_type = ""
            carry_capacity = 1
            unit_color = Color("70b8e8")

    var recharge: int = int(record.get("recharge", 100))
    gather_interval = maxf(0.35, float(recharge) / 200.0)
    state = "seeking_resource"
    last_action = "seeking %s" % job_resource_type


func update(delta: float, resource_nodes: Array, stockpile: Dictionary, construction_sites: Array = []) -> void:
    if job_resource_type.is_empty():
        state = "idle"
        return

    if target_construction_index >= 0:
        _update_construction(delta, construction_sites)
        return

    if carry_amount > 0:
        _update_return_home(delta, stockpile)
        return

    if target_resource_index < 0 or target_resource_index >= resource_nodes.size():
        target_resource_index = _find_nearest_resource_index(resource_nodes)

    if target_resource_index < 0:
        state = "idle"
        last_action = "waiting for %s" % job_resource_type
        return

    var target_resource: ResourceNodeState = resource_nodes[target_resource_index]
    if target_resource.depleted():
        target_resource_index = -1
        state = "seeking_resource"
        last_action = "reassigning"
        return

    var target_position: Vector2 = Vector2(target_resource.tile) + Vector2(0.5, 0.5)
    var distance_to_target: float = position.distance_to(target_position)

    if distance_to_target > 0.1:
        state = "to_%s" % target_resource.resource_type
        _move_towards(target_position, delta)
        return

    state = "gathering"
    work_timer += delta
    if work_timer < gather_interval:
        return

    work_timer = 0.0
    var harvested: int = target_resource.harvest(1)
    if harvested <= 0:
        target_resource_index = -1
        return

    carry_type = target_resource.resource_type
    carry_amount += harvested
    last_action = "harvested %d %s" % [carry_amount, carry_type]

    if carry_amount >= carry_capacity or target_resource.depleted():
        state = "returning"


func status_text() -> String:
    if target_construction_index >= 0:
        return "%s build" % state
    if carry_amount > 0:
        return "%s %d/%d %s" % [state, carry_amount, carry_capacity, carry_type]
    return "%s %s" % [state, job_resource_type]


func assign_resource_target(resource_index: int) -> void:
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
    target_construction_index = site_index
    target_resource_index = -1
    carry_amount = 0
    carry_type = ""
    work_timer = 0.0
    state = "to_build"
    last_action = "ordered to build"


func clear_orders() -> void:
    target_resource_index = -1
    target_construction_index = -1
    carry_amount = 0
    carry_type = ""
    work_timer = 0.0
    state = "idle"
    last_action = "orders cleared"


func set_home_position(new_home_position: Vector2) -> void:
    home_position = new_home_position


func _update_return_home(delta: float, stockpile: Dictionary) -> void:
    var distance_to_home: float = position.distance_to(home_position)
    if distance_to_home > 0.1:
        state = "returning"
        _move_towards(home_position, delta)
        return

    stockpile[carry_type] = int(stockpile.get(carry_type, 0)) + carry_amount
    last_action = "deposited %d %s" % [carry_amount, carry_type]
    carry_amount = 0
    carry_type = ""
    state = "seeking_resource"
    target_resource_index = -1


func _move_towards(target_position: Vector2, delta: float) -> void:
    position = position.move_toward(target_position, speed * delta)


func _find_nearest_resource_index(resource_nodes: Array) -> int:
    var best_index: int = -1
    var best_distance: float = INF

    for index in range(resource_nodes.size()):
        var resource_node: ResourceNodeState = resource_nodes[index]
        if resource_node.resource_type != job_resource_type or resource_node.depleted():
            continue

        var resource_position: Vector2 = Vector2(resource_node.tile) + Vector2(0.5, 0.5)
        var distance_to_resource: float = position.distance_to(resource_position)
        if distance_to_resource < best_distance:
            best_distance = distance_to_resource
            best_index = index

    return best_index


func _update_construction(delta: float, construction_sites: Array) -> void:
    if unit_id != "builder":
        target_construction_index = -1
        return

    if target_construction_index < 0 or target_construction_index >= construction_sites.size():
        target_construction_index = -1
        state = "idle"
        return

    var construction_site: ConstructionSiteState = construction_sites[target_construction_index]
    if construction_site.built:
        target_construction_index = -1
        state = "idle"
        last_action = "build complete"
        return

    var target_position: Vector2 = Vector2(construction_site.tile) + Vector2(0.5, 0.5)
    if position.distance_to(target_position) > 0.12:
        state = "to_build"
        _move_towards(target_position, delta)
        return

    state = "building"
    work_timer += delta
    if work_timer < 0.35:
        return

    work_timer = 0.0
    var build_amount: float = 8.0
    if construction_site.advance(build_amount):
        target_construction_index = -1
        state = "idle"
        last_action = "completed %s" % construction_site.name
    else:
        last_action = "building %s" % construction_site.name
