class_name GameRoot
extends Node2D

const WorldStateScript = preload("res://scripts/core/world_state.gd")
const CampaignStateScript = preload("res://scripts/core/campaign_state.gd")
const MissionStateScript = preload("res://scripts/core/mission_state.gd")
const MissionEventStateScript = preload("res://scripts/core/mission_event_state.gd")
const DiplomacyTargetStateScript = preload("res://scripts/core/diplomacy_target_state.gd")
const MapStateScript = preload("res://scripts/core/map_state.gd")
const RulesetDatabaseScript = preload("res://scripts/data/ruleset_database.gd")
const ResourceNodeStateScript = preload("res://scripts/simulation/resource_node_state.gd")
const BuildingStateScript = preload("res://scripts/simulation/building_state.gd")
const ConstructionSiteStateScript = preload("res://scripts/simulation/construction_site_state.gd")
const WorkerUnitStateScript = preload("res://scripts/simulation/worker_unit_state.gd")
const CombatUnitStateScript = preload("res://scripts/simulation/combat_unit_state.gd")

const TILE_SIZE: float = 40.0
const MAP_TOP_MARGIN: float = 160.0
const DEFAULT_RULESET_ID: String = "classic"
const DEFAULT_MAP_PATH: String = "res://data/classic/vertical_slice/mission_001_map.json"
const DEFAULT_SAVE_PATH: String = "user://save_slot_1.json"
const MAX_ALERT_LOG: int = 6
const COMMAND_MARKER_DURATION: float = 1.1
const SELECTION_DRAG_THRESHOLD: float = 12.0
const MINIMAP_SIZE: Vector2 = Vector2(220.0, 144.0)
const TRANSPORT_BOARD_DISTANCE: float = 0.75
const TRANSPORT_UNLOAD_SPACING: float = 0.8
const TAME_MANA_COST: float = 5.0
const TAME_COOLDOWN_SECONDS: float = 14.0
const TAME_RANGE: float = 5.5
const TAME_HEALTH_RATIO: float = 0.5
const TAME_STABILIZE_RATIO: float = 0.35

const BUILD_KEY_ORDER: Array = [
    {"keycode": KEY_1, "building_id": "storehouse"},
    {"keycode": KEY_2, "building_id": "culture"},
    {"keycode": KEY_3, "building_id": "barracks"},
    {"keycode": KEY_4, "building_id": "laboratory"},
    {"keycode": KEY_5, "building_id": "library"},
    {"keycode": KEY_6, "building_id": "sanctuary"},
    {"keycode": KEY_7, "building_id": "workshop"},
    {"keycode": KEY_8, "building_id": "garage"},
    {"keycode": KEY_9, "building_id": "hangar"},
    {"keycode": KEY_M, "building_id": "market"},
    {"keycode": KEY_0, "building_id": "tower_catapult"},
    {"keycode": KEY_MINUS, "building_id": "tower_cannon"},
    {"keycode": KEY_EQUAL, "building_id": "wall"},
]

var world_state
var campaign_state
var mission_state
var map_state
var ruleset_database
var debug_label: Label
var resource_nodes: Array = []
var buildings: Array = []
var construction_sites: Array = []
var workers: Array = []
var combat_units: Array = []
var enemy_units: Array = []
var diplomacy_targets: Array = []
var pending_enemy_spawns: Array = []
var enemy_ai_state: Array = []
var mission_events: Array = []
var alert_log: Array[String] = []
var allied_clans: Array[String] = []
var hostile_clans: Array[String] = []
var simulation_status: String = "bootstrapping"
var selected_worker_index: int = -1
var selected_combat_index: int = -1
var selected_worker_indices: Array[int] = []
var selected_combat_indices: Array[int] = []
var selected_building_index: int = -1
var selected_site_index: int = -1
var build_mode: String = ""
var command_markers: Array = []
var hover_tile: Vector2i = Vector2i(-1, -1)
var selection_drag_active: bool = false
var selection_drag_origin: Vector2 = Vector2.ZERO
var selection_drag_current: Vector2 = Vector2.ZERO
var runtime_initialized: bool = false
var ui_enabled: bool = false
var auto_enemy_pressure_enabled: bool = true
var ruleset_id: String = DEFAULT_RULESET_ID
var current_mission_id: String = ""
var current_map_path: String = DEFAULT_MAP_PATH
var active_save_slot_id: String = "slot_1"
var campaign_profile_path: String = "user://campaign_profile.json"
var save_slot_directory: String = "user://save_slots"
var mission_resolution_recorded: bool = false
var next_entity_id: int = 1


func _ready() -> void:
    if not runtime_initialized:
        initialize_runtime(true)


func initialize_runtime(show_ui: bool = true) -> void:
    ui_enabled = show_ui
    if runtime_initialized:
        if show_ui:
            _ensure_debug_label()
        set_process(true)
        set_process_unhandled_input(show_ui)
        return

    if not _ensure_ruleset_database():
        simulation_status = "ruleset unavailable: %s" % ruleset_id
        return
    _initialize_campaign_state(show_ui)
    _bootstrap_runtime_state()
    runtime_initialized = true

    if show_ui:
        _ensure_debug_label()

    set_process(true)
    set_process_unhandled_input(show_ui)
    _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()


func run_simulation_steps(step_count: int, delta: float = 1.0 / 60.0) -> void:
    if not runtime_initialized:
        initialize_runtime(false)

    for _step in range(step_count):
        advance_simulation(delta)


func configure_ruleset(next_ruleset_id: String, restart_runtime: bool = false) -> bool:
    var normalized_ruleset_id: String = str(next_ruleset_id).strip_edges().to_lower()
    if normalized_ruleset_id.is_empty():
        normalized_ruleset_id = DEFAULT_RULESET_ID

    if ruleset_database != null and ruleset_id == normalized_ruleset_id:
        return true

    var next_database = RulesetDatabaseScript.new()
    next_database.load_ruleset(normalized_ruleset_id)
    if not next_database.available:
        return false

    ruleset_database = next_database
    ruleset_id = ruleset_database.ruleset_id
    current_mission_id = _default_mission_id()
    current_map_path = _default_map_path()

    if campaign_state != null:
        campaign_state.bootstrap_from_missions(ruleset_database.missions, ruleset_id)
        if not current_mission_id.is_empty():
            campaign_state.set_active_mission(current_mission_id)

    if runtime_initialized and restart_runtime:
        _bootstrap_runtime_state()
        _refresh_debug_text()
        if is_inside_tree():
            queue_redraw()

    return true


func _ensure_ruleset_database() -> bool:
    if ruleset_database != null:
        return true
    return configure_ruleset(ruleset_id, false)


func _default_mission_id() -> String:
    if ruleset_database == null:
        return "monde01"
    if not ruleset_database.default_mission_id.is_empty():
        return ruleset_database.default_mission_id
    if not ruleset_database.missions.is_empty():
        return str(ruleset_database.missions[0].get("id", ""))
    return ""


func _default_map_path() -> String:
    if ruleset_database == null:
        return DEFAULT_MAP_PATH
    if not ruleset_database.default_map_path.is_empty():
        return ruleset_database.default_map_path
    var mission_id: String = _default_mission_id()
    if not mission_id.is_empty():
        return ruleset_database.mission_map_path(mission_id)
    return DEFAULT_MAP_PATH


func _initialize_campaign_state(auto_load_profile: bool) -> void:
    campaign_state = CampaignStateScript.new()
    campaign_state.bootstrap_from_missions(ruleset_database.missions, ruleset_id)
    current_mission_id = campaign_state.active_mission_id if not campaign_state.active_mission_id.is_empty() else _default_mission_id()
    current_map_path = _map_path_for_mission(current_mission_id)

    if auto_load_profile and FileAccess.file_exists(campaign_profile_path):
        load_campaign_profile(campaign_profile_path)


func _apply_campaign_research_carryover() -> void:
    if campaign_state == null or world_state == null or ruleset_database == null:
        return

    for tech_id in campaign_state.carryover_research():
        var tech_record: Dictionary = ruleset_database.find_tech(str(tech_id))
        if tech_record.is_empty():
            continue
        world_state.register_research(tech_record)


func _bootstrap_runtime_state() -> void:
    world_state = WorldStateScript.new()
    mission_state = MissionStateScript.new()
    map_state = MapStateScript.new()
    next_entity_id = 1

    world_state.bootstrap_runtime(ruleset_id)
    if not map_state.load_from_file(current_map_path):
        current_map_path = _default_map_path()
        map_state.load_from_file(current_map_path)

    if map_state.width > 0 and map_state.height > 0:
        world_state.map_size = Vector2i(map_state.width, map_state.height)

    for resource_type in map_state.starting_resources.keys():
        world_state.resources[resource_type] = int(map_state.starting_resources.get(resource_type, 0))

    _apply_campaign_research_carryover()
    _load_mission_record()
    _load_mission_events_from_map()
    _spawn_map_entities()
    pending_enemy_spawns = map_state.enemy_spawns.duplicate(true)
    enemy_ai_state = _normalize_enemy_ai_plans(map_state.enemy_ai_plans)
    _apply_enemy_ai_to_existing_units()
    alert_log = []
    command_markers = []
    build_mode = ""
    _clear_selection()
    _clear_drag_selection()
    mission_resolution_recorded = false
    mission_state.evaluate(_build_mission_snapshot())
    simulation_status = "systems online"


func start_mission(mission_id: String, map_path: String = "") -> bool:
    if ruleset_database == null:
        initialize_runtime(false)

    if campaign_state == null:
        _initialize_campaign_state(false)

    if not campaign_state.is_mission_unlocked(mission_id):
        return false

    current_mission_id = mission_id
    current_map_path = map_path if not map_path.is_empty() else _map_path_for_mission(mission_id)
    campaign_state.set_active_mission(mission_id)
    save_campaign_profile()
    _bootstrap_runtime_state()
    _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()
    return true


func advance_simulation(delta: float) -> void:
    if not runtime_initialized:
        initialize_runtime(false)

    world_state.tick(delta)
    _update_command_markers(delta)
    _update_enemy_spawns()
    _update_enemy_ai()
    _update_buildings(delta)
    _sync_enemy_ai_assignments()
    var enemy_ai_contexts: Dictionary = _build_enemy_ai_contexts()
    var hostile_player_buildings: Array = _player_owned_buildings()
    _update_worker_home_positions()

    for worker in workers:
        worker.update(delta, resource_nodes, world_state.resources, construction_sites, world_state)

    for combat_unit in combat_units:
        combat_unit.update(delta, world_state, enemy_units)

    for enemy_unit in enemy_units:
        enemy_unit.update(
            delta,
            world_state,
            combat_units,
            workers,
            hostile_player_buildings,
            enemy_units,
            _enemy_ai_context_for_unit(enemy_unit, enemy_ai_contexts)
        )

    _update_transport_runtime()
    _update_clan_demands(_build_mission_snapshot())
    _update_diplomacy_state()
    _finalize_construction_sites()
    _cleanup_destroyed_entities()
    _update_worker_home_positions()
    _update_hunger(delta)
    _update_mission_state()

    if ui_enabled and debug_label != null and Engine.get_process_frames() % 10 == 0:
        _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()


func spawn_completed_building(building_id: String, tile: Vector2i, team: String = "player") -> int:
    var building_record: Dictionary = ruleset_database.find_building(building_id)
    if building_record.is_empty():
        return -1

    var building = BuildingStateScript.new()
    building.configure_from_record(building_record, tile, team)
    if team == "player":
        building.refresh_modifiers(world_state)
    buildings.append(building)
    return buildings.size() - 1


func spawn_unit(unit_id: String, position: Vector2, team: String = "player") -> Variant:
    var unit_record: Dictionary = ruleset_database.find_unit(unit_id)
    if unit_record.is_empty():
        return null

    if team == "player" and _is_worker_unit_id(unit_id):
        var worker = WorkerUnitStateScript.new()
        worker.configure_from_record(unit_record, position, _nearest_deposit_position(position))
        worker.entity_id = _allocate_entity_id()
        workers.append(worker)
        return worker

    var combat_unit = CombatUnitStateScript.new()
    combat_unit.configure_from_record(unit_record, position, team)
    combat_unit.entity_id = _allocate_entity_id()
    if team == "player":
        combat_unit.refresh_modifiers(world_state)
        combat_units.append(combat_unit)
    else:
        enemy_units.append(combat_unit)
    return combat_unit


func _allocate_entity_id() -> int:
    var allocated_id: int = next_entity_id
    next_entity_id += 1
    return allocated_id


func _assign_missing_entity_ids() -> void:
    for worker in workers:
        if worker.entity_id < 0:
            worker.entity_id = _allocate_entity_id()

    for combat_unit in combat_units:
        if combat_unit.entity_id < 0:
            combat_unit.entity_id = _allocate_entity_id()

    for enemy_unit in enemy_units:
        if enemy_unit.entity_id < 0:
            enemy_unit.entity_id = _allocate_entity_id()


func _recalculate_next_entity_id() -> void:
    var max_entity_id: int = 0
    for worker in workers:
        max_entity_id = maxi(max_entity_id, int(worker.entity_id))
    for combat_unit in combat_units:
        max_entity_id = maxi(max_entity_id, int(combat_unit.entity_id))
    for enemy_unit in enemy_units:
        max_entity_id = maxi(max_entity_id, int(enemy_unit.entity_id))
    next_entity_id = maxi(next_entity_id, max_entity_id + 1)


func _transport_unit_by_entity_id(entity_id: int):
    if entity_id < 0:
        return null
    for combat_unit in combat_units:
        if combat_unit.entity_id == entity_id:
            return combat_unit
    return null


func _player_actor_by_entity_id(entity_id: int):
    if entity_id < 0:
        return null
    for worker in workers:
        if worker.entity_id == entity_id:
            return worker
    for combat_unit in combat_units:
        if combat_unit.entity_id == entity_id:
            return combat_unit
    return null


func _can_board_transport(carrier, actor) -> bool:
    if carrier == null or actor == null:
        return false
    if not carrier.can_transport() or carrier.team != "player" or not carrier.is_alive():
        return false
    if carrier.entity_id == actor.entity_id:
        return false
    if carrier.passenger_ids.has(actor.entity_id) or carrier.passenger_ids.size() >= carrier.transport_capacity:
        return false
    if actor is WorkerUnitStateScript:
        return actor.team == "player" and actor.is_alive() and not actor.is_boarded()
    if actor is CombatUnitStateScript:
        return (
            actor.team == "player"
            and actor.is_alive()
            and not actor.is_boarded()
            and not actor.can_transport()
            and actor.role != "flying"
        )
    return false


func _board_actor_onto_transport(carrier, actor) -> void:
    if carrier == null or actor == null or not _can_board_transport(carrier, actor):
        return
    carrier.passenger_ids.append(actor.entity_id)
    actor.pending_transport_id = -1
    actor.boarded_transport_id = carrier.entity_id
    actor.position = carrier.position
    actor.move_target = carrier.position
    actor.has_move_target = false
    actor.state = "transported"
    actor.last_action = "aboard %s" % carrier.name
    if actor is WorkerUnitStateScript:
        actor.manual_hold = true
        actor.target_resource_index = -1
        actor.target_construction_index = -1
    else:
        actor.target_ref = null
        actor.target_kind = ""
    carrier.last_action = "loaded %s" % actor.name


func _crash_transport_passenger(actor, carrier_name: String) -> void:
    if actor == null or not actor.is_alive():
        return
    actor.pending_transport_id = -1
    actor.boarded_transport_id = -1
    actor.apply_damage(actor.health + 9999.0)
    actor.last_action = "lost with %s" % carrier_name


func _update_transport_runtime() -> void:
    for carrier in combat_units:
        if not carrier.can_transport():
            continue

        var next_passenger_ids: Array[int] = []
        for passenger_id in carrier.passenger_ids:
            var actor = _player_actor_by_entity_id(passenger_id)
            if actor == null or not actor.is_alive():
                continue
            if not carrier.is_alive():
                _crash_transport_passenger(actor, carrier.name)
                continue
            actor.pending_transport_id = -1
            actor.boarded_transport_id = carrier.entity_id
            actor.position = carrier.position
            actor.move_target = carrier.position
            actor.has_move_target = false
            actor.state = "transported"
            actor.last_action = "aboard %s" % carrier.name
            next_passenger_ids.append(passenger_id)
        carrier.passenger_ids = next_passenger_ids

    for worker in workers:
        _resolve_transport_order_for_actor(worker)
    for combat_unit in combat_units:
        if combat_unit.team == "player":
            _resolve_transport_order_for_actor(combat_unit)

    _prune_transport_selection()


func _resolve_transport_order_for_actor(actor) -> void:
    if actor == null or not actor.is_alive() or actor.is_boarded():
        return

    var transport_id: int = int(actor.pending_transport_id)
    if transport_id < 0:
        return

    var carrier = _transport_unit_by_entity_id(transport_id)
    if carrier == null or not _can_board_transport(carrier, actor):
        actor.pending_transport_id = -1
        actor.has_move_target = false
        actor.state = "holding"
        actor.last_action = "transport unavailable"
        return

    if actor.position.distance_to(carrier.position) > TRANSPORT_BOARD_DISTANCE:
        actor.move_target = carrier.position
        actor.has_move_target = true
        actor.state = "boarding"
        actor.last_action = "boarding %s" % carrier.name
        return

    _board_actor_onto_transport(carrier, actor)


func unload_selected_transport() -> bool:
    var carrier = _selected_combat_unit()
    if carrier == null or carrier.team != "player" or not carrier.can_transport():
        return false
    return _unload_transport(carrier)


func _unload_transport(carrier) -> bool:
    if carrier == null or carrier.passenger_ids.is_empty():
        simulation_status = "transport empty"
        return false

    var unload_offsets: Array = _formation_offsets(carrier.passenger_ids.size(), TRANSPORT_UNLOAD_SPACING)
    var unload_count: int = 0
    for index in range(carrier.passenger_ids.size()):
        var actor = _player_actor_by_entity_id(int(carrier.passenger_ids[index]))
        if actor == null or not actor.is_alive():
            continue
        _set_actor_unloaded(actor, carrier.position + unload_offsets[index])
        unload_count += 1

    var remaining_passenger_ids: Array[int] = []
    carrier.passenger_ids = remaining_passenger_ids
    carrier.last_action = "unloaded passengers"
    if unload_count <= 0:
        simulation_status = "transport empty"
        return false

    _push_command_marker(carrier.position, "transport")
    simulation_status = "%s unloaded %d passengers" % [carrier.name, unload_count]
    return true


func _set_actor_unloaded(actor, unload_position: Vector2) -> void:
    actor.pending_transport_id = -1
    actor.boarded_transport_id = -1
    actor.position = unload_position
    actor.move_target = unload_position
    actor.has_move_target = false
    actor.state = "holding"
    actor.last_action = "unloaded from transport"
    if actor is WorkerUnitStateScript:
        actor.manual_hold = true
        actor.target_resource_index = -1
        actor.target_construction_index = -1
    else:
        actor.target_ref = null
        actor.target_kind = ""


func _prune_transport_selection() -> void:
    var next_worker_selection: Array[int] = []
    for index in selected_worker_indices:
        if index >= 0 and index < workers.size() and not workers[index].is_boarded():
            next_worker_selection.append(index)
    selected_worker_indices = next_worker_selection

    var next_combat_selection: Array[int] = []
    for index in selected_combat_indices:
        if index >= 0 and index < combat_units.size() and not combat_units[index].is_boarded():
            next_combat_selection.append(index)
    selected_combat_indices = next_combat_selection
    _sync_primary_selection_indices()


func queue_training_for_building(building_index: int, unit_id: String) -> bool:
    if building_index < 0 or building_index >= buildings.size():
        return false

    var building = buildings[building_index]
    if not building.is_alive() or not building.can_train_unit(unit_id):
        return false

    var unit_record: Dictionary = ruleset_database.find_unit(unit_id)
    if unit_record.is_empty():
        return false

    var cost: Dictionary = unit_record.get("cost", {}).duplicate(true)
    if not world_state.spend_resources(cost):
        simulation_status = "insufficient resources for %s" % unit_id
        return false

    var duration: float = maxf(2.0, float(unit_record.get("recruit_time", 600)) / 300.0)
    building.enqueue_job("train", unit_id, duration, {"unit_id": unit_id})
    simulation_status = "%s queued %s" % [building.name, unit_record.get("name", unit_id)]
    return true


func queue_research_for_building(building_index: int, branch: String) -> bool:
    if building_index < 0 or building_index >= buildings.size():
        return false

    var building = buildings[building_index]
    if not building.is_alive() or not building.can_research():
        return false

    var tech_record: Dictionary = ruleset_database.next_tech_for_branch(branch, world_state.unlocked_techs)
    if tech_record.is_empty():
        simulation_status = "branch exhausted: %s" % branch
        return false

    var normalized_cost: int = maxi(1, int(ceil(float(tech_record.get("cost", 1)) / 2500.0)))
    if not world_state.spend_resources({"tech": normalized_cost}):
        simulation_status = "not enough tech for %s" % str(tech_record.get("id", "tech"))
        return false

    var duration: float = maxf(4.0, float(tech_record.get("cost", 1)) / 2500.0)
    building.enqueue_job(
        "research",
        str(tech_record.get("id", "")),
        duration,
        {"branch": branch, "tech_cost": normalized_cost}
    )
    simulation_status = "%s started %s" % [building.name, str(tech_record.get("id", "tech"))]
    return true


func cast_spell_for_selected_unit(spell_id: String) -> bool:
    var caster = _selected_combat_unit()
    if caster == null or caster.team != "player" or caster.unit_id != "druid":
        return false

    var spell_record: Dictionary = ruleset_database.find_spell(spell_id)
    if spell_record.is_empty():
        simulation_status = "unknown spell: %s" % spell_id
        return false

    var mana_cost: float = float(spell_record.get("cost", {}).get("mana", 0))
    if not caster.can_cast_spell(spell_id, mana_cost):
        simulation_status = "spell not ready: %s" % str(spell_record.get("name", spell_id))
        return false

    var resource_cost: Dictionary = _spell_resource_cost(spell_record)
    if not world_state.can_afford(resource_cost):
        simulation_status = "insufficient resources for %s" % str(spell_record.get("name", spell_id))
        return false

    var enemy_target = null
    match spell_id:
        "petrification", "nova":
            enemy_target = _nearest_enemy_spell_target(caster, float(spell_record.get("range", 0)))
            if enemy_target == null:
                simulation_status = "no target for %s" % str(spell_record.get("name", spell_id))
                return false
        _:
            pass

    if not world_state.spend_resources(resource_cost):
        simulation_status = "insufficient resources for %s" % str(spell_record.get("name", spell_id))
        return false
    if not caster.spend_mana(mana_cost):
        for resource_type in resource_cost.keys():
            world_state.add_resource(str(resource_type), int(resource_cost.get(resource_type, 0)))
        simulation_status = "not enough mana for %s" % str(spell_record.get("name", spell_id))
        return false

    var cast_succeeded: bool = false
    match spell_id:
        "armour":
            cast_succeeded = _cast_armour_spell(caster, spell_record)
        "vision":
            cast_succeeded = _cast_vision_spell(caster, spell_record)
        "petrification":
            cast_succeeded = _cast_petrification_spell(caster, enemy_target, spell_record)
        "nova":
            cast_succeeded = _cast_nova_spell(caster, enemy_target, spell_record)
        _:
            cast_succeeded = false

    if not cast_succeeded:
        for resource_type in resource_cost.keys():
            world_state.add_resource(str(resource_type), int(resource_cost.get(resource_type, 0)))
        caster.mana = minf(caster.max_mana, caster.mana + mana_cost)
        simulation_status = "spell failed: %s" % str(spell_record.get("name", spell_id))
        return false

    caster.set_spell_cooldown(spell_id, _spell_cooldown_seconds(spell_record))
    _push_alert("%s cast %s" % [caster.name, str(spell_record.get("name", spell_id))])
    return true


func tame_creature_for_selected_unit() -> bool:
    var caster = _selected_combat_unit()
    if caster == null or caster.team != "player" or caster.unit_id != "druid":
        return false

    if caster.cooldown_for_spell("tame") > 0.0:
        simulation_status = "taming not ready"
        return false

    if caster.mana < TAME_MANA_COST:
        simulation_status = "not enough mana to tame"
        return false

    var target = _nearest_tamable_creature(caster, TAME_RANGE)
    if target == null:
        simulation_status = "no weakened creature to tame"
        return false

    if not caster.spend_mana(TAME_MANA_COST):
        simulation_status = "not enough mana to tame"
        return false

    if not _tame_creature(target, caster):
        caster.mana = minf(caster.max_mana, caster.mana + TAME_MANA_COST)
        simulation_status = "taming failed"
        return false

    caster.set_spell_cooldown("tame", TAME_COOLDOWN_SECONDS)
    caster.last_action = "tamed a creature"
    _push_alert("%s tamed %s" % [caster.name, target.name])
    return true


func save_campaign_profile(path: String = campaign_profile_path) -> bool:
    if ruleset_database == null:
        return false

    if campaign_state == null:
        _initialize_campaign_state(false)

    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false

    file.store_string(JSON.stringify({
        "ruleset_id": ruleset_id,
        "campaign_state": campaign_state.serialize(),
        "active_save_slot_id": active_save_slot_id,
        "current_mission_id": current_mission_id,
        "current_map_path": current_map_path
    }, "\t"))
    file.close()
    return true


func load_campaign_profile(path: String = campaign_profile_path) -> bool:
    if not FileAccess.file_exists(path):
        return false

    if not _ensure_ruleset_database():
        return false

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return false

    var payload: Dictionary = parsed
    var payload_ruleset_id: String = str(payload.get("ruleset_id", payload.get("campaign_state", {}).get("ruleset_id", ruleset_id)))
    if not payload_ruleset_id.is_empty() and payload_ruleset_id != ruleset_id:
        if not configure_ruleset(payload_ruleset_id, false):
            return false

    if campaign_state == null:
        campaign_state = CampaignStateScript.new()

    campaign_state.load_from_payload(payload.get("campaign_state", {}), ruleset_database.missions, ruleset_id)
    active_save_slot_id = str(payload.get("active_save_slot_id", active_save_slot_id))
    current_mission_id = str(payload.get("current_mission_id", campaign_state.active_mission_id))
    if current_mission_id.is_empty():
        current_mission_id = campaign_state.active_mission_id if not campaign_state.active_mission_id.is_empty() else _default_mission_id()
    current_map_path = str(payload.get("current_map_path", _map_path_for_mission(current_mission_id)))
    campaign_state.set_active_mission(current_mission_id)
    return true


func save_to_slot(slot_id: String = active_save_slot_id) -> bool:
    if slot_id.is_empty():
        return false

    if not _ensure_save_slot_dir():
        return false

    active_save_slot_id = slot_id
    var slot_path: String = _slot_save_path(slot_id)
    if not save_game_state(slot_path):
        return false

    if campaign_state != null:
        campaign_state.set_slot_metadata(slot_id, {
            "ruleset_id": ruleset_id,
            "ruleset_name": ruleset_database.display_name,
            "mission_id": current_mission_id,
            "mission_title": mission_state.title,
            "map_path": current_map_path,
            "updated_at": int(Time.get_unix_time_from_system()),
            "tick_count": world_state.tick_count,
            "mission_status": world_state.mission_status,
            "resources": world_state.resources.duplicate(true)
        })
    save_campaign_profile()
    _push_alert("saved slot: %s" % slot_id)
    return true


func load_from_slot(slot_id: String = active_save_slot_id) -> bool:
    if slot_id.is_empty():
        return false

    var slot_path: String = _slot_save_path(slot_id)
    active_save_slot_id = slot_id
    var loaded: bool = load_game_state(slot_path)
    if loaded:
        save_campaign_profile()
        _push_alert("loaded slot: %s" % slot_id)
    return loaded


func list_save_slots() -> Array:
    if campaign_state == null:
        return []
    return campaign_state.list_slot_metadata()


func _process(delta: float) -> void:
    advance_simulation(delta)


func save_game_state(path: String = DEFAULT_SAVE_PATH) -> bool:
    if not runtime_initialized:
        initialize_runtime(false)

    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false

    file.store_string(JSON.stringify(serialize_runtime(), "\t"))
    file.close()
    simulation_status = "saved game"
    _refresh_debug_text()
    return true


func load_game_state(path: String = DEFAULT_SAVE_PATH) -> bool:
    if not FileAccess.file_exists(path):
        return false

    if not runtime_initialized:
        initialize_runtime(false)

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if typeof(parsed) != TYPE_DICTIONARY:
        return false

    var payload: Dictionary = parsed
    var payload_ruleset_id: String = str(payload.get("ruleset_id", ruleset_id))
    if not payload_ruleset_id.is_empty() and payload_ruleset_id != ruleset_id:
        if not configure_ruleset(payload_ruleset_id, false):
            return false

    _release_runtime_references()
    world_state = WorldStateScript.new()
    world_state.load_from_payload(payload.get("world_state", {}))
    ruleset_id = str(payload.get("ruleset_id", world_state.ruleset_id)).strip_edges().to_lower()
    if ruleset_id.is_empty():
        ruleset_id = DEFAULT_RULESET_ID
    current_map_path = str(payload.get("map_path", _default_map_path()))
    current_mission_id = str(payload.get("mission_id", current_mission_id if not current_mission_id.is_empty() else _default_mission_id()))
    active_save_slot_id = str(payload.get("save_slot_id", active_save_slot_id))
    allied_clans = []
    hostile_clans = []
    for clan_id in payload.get("allied_clans", []):
        allied_clans.append(str(clan_id))
    for clan_id in payload.get("hostile_clans", []):
        hostile_clans.append(str(clan_id))

    map_state = MapStateScript.new()
    if not map_state.load_from_file(current_map_path):
        return false
    if payload.has("build_palette"):
        map_state.build_palette = payload.get("build_palette", []).duplicate(true)

    mission_state = MissionStateScript.new()
    var mission_record: Dictionary = ruleset_database.find_mission(current_mission_id)
    if mission_record.is_empty():
        mission_state.load_stub_mission(current_mission_id)
    else:
        mission_state.load_from_record(mission_record)
    mission_state.configure_runtime_objectives(_objective_payloads_from_map())
    if payload.get("mission_events", []).is_empty():
        _load_mission_events_from_map()
    else:
        _load_mission_events_from_payload(payload.get("mission_events", []))

    resource_nodes = []
    for resource_payload in payload.get("resource_nodes", []):
        var resource_node = ResourceNodeStateScript.new()
        resource_node.load_from_payload(resource_payload)
        resource_nodes.append(resource_node)

    buildings = []
    for building_payload in payload.get("buildings", []):
        var building_record: Dictionary = ruleset_database.find_building(str(building_payload.get("building_id", "")))
        if building_record.is_empty():
            continue
        var building = BuildingStateScript.new()
        building.load_from_payload(building_payload, building_record)
        buildings.append(building)

    construction_sites = []
    for site_payload in payload.get("construction_sites", []):
        var site_record: Dictionary = ruleset_database.find_building(str(site_payload.get("building_id", "")))
        var construction_site = ConstructionSiteStateScript.new()
        construction_site.load_from_payload(site_payload, site_record)
        construction_sites.append(construction_site)

    workers = []
    for worker_payload in payload.get("workers", []):
        var worker_record: Dictionary = ruleset_database.find_unit(str(worker_payload.get("unit_id", "")))
        if worker_record.is_empty():
            continue
        var worker = WorkerUnitStateScript.new()
        worker.load_from_payload(worker_payload, worker_record)
        workers.append(worker)

    combat_units = []
    for unit_payload in payload.get("combat_units", []):
        var combat_record: Dictionary = ruleset_database.find_unit(str(unit_payload.get("unit_id", "")))
        if combat_record.is_empty():
            continue
        var combat_unit = CombatUnitStateScript.new()
        combat_unit.load_from_payload(unit_payload, combat_record)
        combat_units.append(combat_unit)

    enemy_units = []
    for unit_payload in payload.get("enemy_units", []):
        var enemy_record: Dictionary = ruleset_database.find_unit(str(unit_payload.get("unit_id", "")))
        if enemy_record.is_empty():
            continue
        var enemy_unit = CombatUnitStateScript.new()
        enemy_unit.load_from_payload(unit_payload, enemy_record)
        enemy_units.append(enemy_unit)

    if payload.get("diplomacy_targets", []).is_empty():
        _load_diplomacy_targets_from_map()
    else:
        _load_diplomacy_targets_from_payload(payload.get("diplomacy_targets", []))

    pending_enemy_spawns = payload.get("pending_enemy_spawns", []).duplicate(true)
    enemy_ai_state = _normalize_enemy_ai_plans(payload.get("enemy_ai_state", map_state.enemy_ai_plans))
    _apply_enemy_ai_to_existing_units()
    alert_log = []
    for alert_entry in payload.get("alert_log", []):
        alert_log.append(str(alert_entry))
    simulation_status = str(payload.get("simulation_status", "loaded save"))
    _clear_selection()
    build_mode = ""
    command_markers = []
    _clear_drag_selection()
    runtime_initialized = true
    mission_resolution_recorded = bool(payload.get("mission_resolution_recorded", false))
    next_entity_id = int(payload.get("next_entity_id", 1))
    _assign_missing_entity_ids()
    _recalculate_next_entity_id()
    _update_transport_runtime()
    if campaign_state != null:
        campaign_state.set_active_mission(current_mission_id)
    _refresh_player_modifiers()
    _update_worker_home_positions()
    mission_state.evaluate(_build_mission_snapshot())
    _refresh_debug_text()
    if is_inside_tree():
        queue_redraw()
    return true


func serialize_runtime() -> Dictionary:
    return {
        "ruleset_id": ruleset_id,
        "map_path": current_map_path,
        "mission_id": current_mission_id,
        "save_slot_id": active_save_slot_id,
        "next_entity_id": next_entity_id,
        "build_palette": map_state.build_palette.duplicate(true),
        "world_state": world_state.serialize(),
        "resource_nodes": _serialize_collection(resource_nodes),
        "buildings": _serialize_collection(buildings),
        "construction_sites": _serialize_collection(construction_sites),
        "workers": _serialize_collection(workers),
        "combat_units": _serialize_collection(combat_units),
        "enemy_units": _serialize_collection(enemy_units),
        "diplomacy_targets": _serialize_collection(diplomacy_targets),
        "allied_clans": allied_clans.duplicate(true),
        "hostile_clans": hostile_clans.duplicate(true),
        "pending_enemy_spawns": pending_enemy_spawns.duplicate(true),
        "enemy_ai_state": enemy_ai_state.duplicate(true),
        "mission_events": _serialize_collection(mission_events),
        "alert_log": alert_log.duplicate(true),
        "mission_resolution_recorded": mission_resolution_recorded,
        "simulation_status": simulation_status
    }


func _objective_payloads_from_map() -> Array:
    if map_state != null and not map_state.objectives.is_empty():
        return map_state.objectives.duplicate(true)

    var fallback_objectives: Array = []
    var food_target: int = int(map_state.storehouse_goal.get("food", 0))
    var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
    if food_target > 0:
        fallback_objectives.append({
            "id": "stockpile_food",
            "type": "stockpile",
            "resource": "food",
            "target": food_target,
            "label": "Stock %d sacks of food in the cave" % food_target,
            "required": true
        })
    if stone_target > 0:
        fallback_objectives.append({
            "id": "stockpile_stone",
            "type": "stockpile",
            "resource": "stone",
            "target": stone_target,
            "label": "Stock %d sacks of stones in the cave" % stone_target,
            "required": true
        })
    return fallback_objectives


func _build_mission_snapshot() -> Dictionary:
    var building_counts: Dictionary = {}
    var player_building_positions: Array = []
    var enemy_building_count: int = 0
    for building in buildings:
        if not building.is_alive():
            continue
        if building.team == "player":
            building_counts[building.building_id] = int(building_counts.get(building.building_id, 0)) + 1
            player_building_positions.append({
                "building_id": building.building_id,
                "x": building.center_position().x,
                "y": building.center_position().y
            })
        else:
            enemy_building_count += 1

    var unit_counts: Dictionary = {}
    var player_unit_positions: Array = []
    for worker in workers:
        if not worker.is_alive():
            continue
        unit_counts[worker.unit_id] = int(unit_counts.get(worker.unit_id, 0)) + 1
        player_unit_positions.append({
            "unit_id": worker.unit_id,
            "x": worker.position.x,
            "y": worker.position.y
        })

    for combat_unit in combat_units:
        if combat_unit.team != "player" or not combat_unit.is_alive():
            continue
        unit_counts[combat_unit.unit_id] = int(unit_counts.get(combat_unit.unit_id, 0)) + 1
        player_unit_positions.append({
            "unit_id": combat_unit.unit_id,
            "x": combat_unit.position.x,
            "y": combat_unit.position.y
        })

    return {
        "resources": world_state.resources.duplicate(true),
        "building_counts": building_counts,
        "player_building_positions": player_building_positions,
        "unit_counts": unit_counts,
        "player_unit_positions": player_unit_positions,
        "population_count": world_state.population_count,
        "housing_capacity": world_state.housing_capacity,
        "starvation_strikes": world_state.starvation_strikes,
        "starving": world_state.starving,
        "enemy_building_count": enemy_building_count,
        "branch_levels": world_state.branch_levels.duplicate(true),
        "unlocked_tech_count": world_state.unlocked_techs.size(),
        "elapsed_time": world_state.elapsed_time,
        "enemy_waves_spawned": world_state.enemy_waves_spawned,
        "enemy_units_alive": enemy_units.size(),
        "pending_enemy_spawns": pending_enemy_spawns.size(),
        "allied_clans": allied_clans.duplicate(true),
        "hostile_clans": hostile_clans.duplicate(true),
        "clan_stances": _clan_stance_map(),
        "clan_trust": _clan_trust_map(),
        "clan_demands": _clan_demand_map()
    }


func _draw() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("11161c"), true)

    if map_state == null or map_state.width <= 0 or map_state.height <= 0:
        return

    var origin := _map_origin(viewport_size)

    if hover_tile.x >= 0 and hover_tile.y >= 0 and hover_tile.x < map_state.width and hover_tile.y < map_state.height:
        var hover_color := Color("ffffff")
        hover_color.a = 0.15
        draw_rect(Rect2(_tile_origin(hover_tile, origin), Vector2(TILE_SIZE - 1.0, TILE_SIZE - 1.0)), hover_color, true)

    for y in range(map_state.height):
        for x in range(map_state.width):
            var terrain: String = map_state.terrain_at(x, y)
            var color: Color = _terrain_color(terrain)
            draw_rect(
                Rect2(origin + Vector2(x * TILE_SIZE, y * TILE_SIZE), Vector2(TILE_SIZE - 1.0, TILE_SIZE - 1.0)),
                color,
                true
            )

    for resource_node in resource_nodes:
        var resource_pos := _tile_origin(resource_node.tile, origin)
        draw_circle(resource_pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5), 8.0, _resource_color(resource_node.resource_type))
        draw_rect(Rect2(resource_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(
            Rect2(resource_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * resource_node.fill_ratio(), 4.0)),
            Color("d9d9d9"),
            true
        )

    for building_index in range(buildings.size()):
        var building = buildings[building_index]
        var building_pos := _tile_origin(building.tile, origin)
        var outline_color := Color("1a222b")
        if building_index == selected_building_index:
            outline_color = Color("f0c58a")
        draw_rect(Rect2(building_pos + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), _building_color(building.building_id), true)
        draw_rect(Rect2(building_pos + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), outline_color, false, 2.0)
        draw_rect(Rect2(building_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(
            Rect2(building_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * (building.health / maxf(1.0, building.max_health)), 4.0)),
            Color("b9e36f"),
            true
        )
        if not building.production_queue.is_empty():
            draw_rect(
                Rect2(building_pos + Vector2(6.0, 6.0), Vector2((TILE_SIZE - 12.0) * building.queue_ratio(), 3.0)),
                Color("70b8e8"),
                true
            )

    for diplomacy_target in diplomacy_targets:
        var diplomacy_pos := _tile_origin(diplomacy_target.tile, origin)
        var diplomacy_color: Color = diplomacy_target.display_color()
        draw_rect(Rect2(diplomacy_pos + Vector2(8.0, 8.0), Vector2(TILE_SIZE - 16.0, TILE_SIZE - 16.0)), diplomacy_color, false, 3.0)
        draw_circle(diplomacy_pos + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5), 5.0, diplomacy_color)

    for site_index in range(construction_sites.size()):
        var construction_site = construction_sites[site_index]
        var site_pos := _tile_origin(construction_site.tile, origin)
        var site_color := Color("c98b5d")
        if site_index == selected_site_index:
            site_color = Color("f0c58a")
        draw_rect(Rect2(site_pos + Vector2(6.0, 6.0), Vector2(TILE_SIZE - 12.0, TILE_SIZE - 12.0)), site_color, false, 2.0)
        draw_rect(Rect2(site_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2(TILE_SIZE - 12.0, 4.0)), Color("11161c"), true)
        draw_rect(
            Rect2(site_pos + Vector2(6.0, TILE_SIZE - 8.0), Vector2((TILE_SIZE - 12.0) * construction_site.build_ratio(), 4.0)),
            Color("f0c58a"),
            true
        )

    for worker_index in range(workers.size()):
        var worker = workers[worker_index]
        if worker.is_boarded():
            continue
        var unit_screen_pos: Vector2 = origin + (worker.position * TILE_SIZE)
        draw_circle(unit_screen_pos, 9.0, worker.unit_color)
        draw_circle(unit_screen_pos, 3.0, Color("11161c"))
        if selected_worker_indices.has(worker_index):
            draw_arc(unit_screen_pos, 14.0, 0.0, TAU, 24, Color("70b8e8"), 2.0)
        if worker.carry_amount > 0:
            draw_circle(unit_screen_pos + Vector2(10.0, -8.0), 4.0, _resource_color(worker.carry_type))

    for combat_index in range(combat_units.size()):
        var combat_unit = combat_units[combat_index]
        if combat_unit.is_boarded():
            continue
        var combat_pos: Vector2 = origin + (combat_unit.position * TILE_SIZE)
        draw_circle(combat_pos, 10.0, combat_unit.unit_color)
        draw_circle(combat_pos, 3.0, Color("11161c"))
        if selected_combat_indices.has(combat_index):
            draw_arc(combat_pos, 15.0, 0.0, TAU, 24, Color("f6d36b"), 2.0)
        if combat_unit.can_transport() and not combat_unit.passenger_ids.is_empty():
            draw_circle(combat_pos + Vector2(12.0, -10.0), 5.0, Color("f0c58a"))

    for enemy_unit in enemy_units:
        var enemy_pos: Vector2 = origin + (enemy_unit.position * TILE_SIZE)
        draw_circle(enemy_pos, 10.0, enemy_unit.unit_color)
        draw_circle(enemy_pos, 4.0, Color("1f0d0d"))
        draw_rect(Rect2(enemy_pos + Vector2(-10.0, 12.0), Vector2(20.0, 3.0)), Color("11161c"), true)
        draw_rect(
            Rect2(enemy_pos + Vector2(-10.0, 12.0), Vector2(20.0 * (enemy_unit.health / maxf(1.0, enemy_unit.max_health)), 3.0)),
            Color("e15c55"),
            true
        )

    if not build_mode.is_empty() and hover_tile.x >= 0 and hover_tile.y >= 0:
        var ghost_color := _building_color(build_mode)
        ghost_color.a = 0.35 if _can_place_building(hover_tile) else 0.15
        draw_rect(Rect2(_tile_origin(hover_tile, origin) + Vector2(4.0, 4.0), Vector2(TILE_SIZE - 8.0, TILE_SIZE - 8.0)), ghost_color, true)

    for marker in command_markers:
        var marker_position_payload: Dictionary = marker.get("position", {})
        var marker_position := Vector2(
            float(marker_position_payload.get("x", 0.0)),
            float(marker_position_payload.get("y", 0.0))
        )
        var marker_color: Color = _command_marker_color(str(marker.get("kind", "")))
        var marker_screen_pos: Vector2 = origin + (marker_position * TILE_SIZE)
        draw_arc(marker_screen_pos, 11.0, 0.0, TAU, 20, marker_color, 2.0)
        draw_circle(marker_screen_pos, 3.0, marker_color)

    if selection_drag_active and build_mode.is_empty():
        var selection_rect := Rect2(selection_drag_origin, selection_drag_current - selection_drag_origin).abs()
        var selection_fill := Color("70b8e8")
        selection_fill.a = 0.12
        draw_rect(selection_rect, selection_fill, true)
        draw_rect(selection_rect, Color("70b8e8"), false, 2.0)

    _draw_minimap(viewport_size)


func _draw_minimap(viewport_size: Vector2) -> void:
    var minimap_origin := Vector2(viewport_size.x - MINIMAP_SIZE.x - 28.0, 24.0)
    var frame_rect := Rect2(minimap_origin - Vector2(6.0, 6.0), MINIMAP_SIZE + Vector2(12.0, 12.0))
    draw_rect(frame_rect, Color("10161c"), true)
    draw_rect(frame_rect, Color("31404f"), false, 2.0)

    var cell_size := Vector2(MINIMAP_SIZE.x / float(map_state.width), MINIMAP_SIZE.y / float(map_state.height))
    for y in range(map_state.height):
        for x in range(map_state.width):
            var terrain: Color = _terrain_color(map_state.terrain_at(x, y)).darkened(0.18)
            draw_rect(
                Rect2(minimap_origin + Vector2(float(x) * cell_size.x, float(y) * cell_size.y), cell_size + Vector2.ONE),
                terrain,
                true
            )

    for resource_node in resource_nodes:
        draw_circle(_minimap_point(Vector2(resource_node.tile) + Vector2(0.5, 0.5), minimap_origin), 2.4, _resource_color(resource_node.resource_type))

    for building in buildings:
        var building_color: Color = _building_color(building.building_id)
        if building.team != "player":
            building_color = Color("e15c55")
        draw_rect(Rect2(_minimap_point(building.center_position(), minimap_origin) - Vector2.ONE, Vector2(3.0, 3.0)), building_color, true)

    for diplomacy_target in diplomacy_targets:
        draw_circle(_minimap_point(diplomacy_target.center_position(), minimap_origin), 2.5, diplomacy_target.display_color())

    for worker in workers:
        draw_circle(_minimap_point(worker.position, minimap_origin), 2.0, worker.unit_color)

    for combat_unit in combat_units:
        draw_circle(_minimap_point(combat_unit.position, minimap_origin), 2.4, combat_unit.unit_color)

    for enemy_unit in enemy_units:
        draw_circle(_minimap_point(enemy_unit.position, minimap_origin), 2.4, enemy_unit.unit_color)


func _minimap_point(world_position: Vector2, minimap_origin: Vector2) -> Vector2:
    return minimap_origin + Vector2(
        (world_position.x / maxf(1.0, float(map_state.width))) * MINIMAP_SIZE.x,
        (world_position.y / maxf(1.0, float(map_state.height))) * MINIMAP_SIZE.y
    )


func _load_mission_record() -> void:
    var mission_record: Dictionary = ruleset_database.find_mission(current_mission_id)
    if mission_record.is_empty():
        mission_state.load_stub_mission(current_mission_id)
    else:
        mission_state.load_from_record(mission_record)
    mission_state.configure_runtime_objectives(_objective_payloads_from_map())
    if campaign_state != null:
        campaign_state.set_active_mission(current_mission_id)


func _load_mission_events_from_map() -> void:
    mission_events = []
    for event_payload in map_state.mission_events:
        var mission_event = MissionEventStateScript.new()
        mission_event.configure_from_payload(event_payload)
        mission_events.append(mission_event)


func _load_mission_events_from_payload(payloads: Array) -> void:
    mission_events = []
    for event_payload in payloads:
        var mission_event = MissionEventStateScript.new()
        mission_event.load_from_payload(event_payload)
        mission_events.append(mission_event)


func _load_diplomacy_targets_from_map() -> void:
    _load_diplomacy_targets_from_payload(map_state.diplomacy_targets)


func _campaign_clan_state_for(clan_id: String) -> Dictionary:
    if campaign_state == null:
        return {}
    return campaign_state.clan_state_for(clan_id)


func _merged_diplomacy_target_payload(target_payload: Dictionary) -> Dictionary:
    var merged_payload: Dictionary = target_payload.duplicate(true)
    var clan_id: String = str(merged_payload.get("clan_id", ""))
    if clan_id.is_empty():
        return merged_payload

    var carryover_payload: Dictionary = _campaign_clan_state_for(clan_id)
    var has_explicit_stance: bool = merged_payload.has("stance") or merged_payload.has("allied")
    var has_explicit_trust: bool = merged_payload.has("trust")

    if not has_explicit_stance:
        if allied_clans.has(clan_id):
            merged_payload["stance"] = "allied"
        elif hostile_clans.has(clan_id):
            merged_payload["stance"] = "hostile"
        elif not carryover_payload.is_empty():
            merged_payload["stance"] = str(carryover_payload.get("stance", "neutral"))

    if not has_explicit_trust and not carryover_payload.is_empty():
        merged_payload["trust"] = int(carryover_payload.get("trust", 0))

    return merged_payload


func _load_diplomacy_targets_from_payload(payloads: Array) -> void:
    diplomacy_targets = []
    for target_payload in payloads:
        var diplomacy_target = DiplomacyTargetStateScript.new()
        diplomacy_target.load_from_payload(_merged_diplomacy_target_payload(target_payload))
        match diplomacy_target.stance:
            "allied":
                if not allied_clans.has(diplomacy_target.clan_id):
                    allied_clans.append(diplomacy_target.clan_id)
            "hostile":
                if not hostile_clans.has(diplomacy_target.clan_id):
                    hostile_clans.append(diplomacy_target.clan_id)
        diplomacy_targets.append(diplomacy_target)


func _spawn_map_entities() -> void:
    _release_runtime_references()
    resource_nodes.clear()
    buildings.clear()
    construction_sites.clear()
    workers.clear()
    combat_units.clear()
    enemy_units.clear()
    allied_clans = []
    hostile_clans = []
    _load_diplomacy_targets_from_map()

    for resource_payload in map_state.resources:
        var resource_node = ResourceNodeStateScript.new()
        resource_node.configure_from_payload(resource_payload)
        resource_nodes.append(resource_node)

    if not map_state.starting_buildings.is_empty():
        for building_payload in map_state.starting_buildings:
            var tile := Vector2i(int(building_payload.get("x", map_state.player_start.x)), int(building_payload.get("y", map_state.player_start.y)))
            spawn_completed_building(
                str(building_payload.get("building_id", "storehouse")),
                tile,
                str(building_payload.get("team", "player"))
            )
    else:
        spawn_completed_building("storehouse", map_state.player_start)

    var home_position := Vector2(map_state.player_start) + Vector2(0.5, 0.5)
    if not map_state.starting_units.is_empty():
        for unit_payload in map_state.starting_units:
            var unit_position := Vector2(
                float(unit_payload.get("x", home_position.x)),
                float(unit_payload.get("y", home_position.y))
            ) + Vector2(0.5, 0.5)
            spawn_unit(
                str(unit_payload.get("unit_id", "farmer")),
                unit_position,
                str(unit_payload.get("team", "player"))
            )
        return

    var worker_specs: Array = [
        {"unit_id": "farmer", "offset": Vector2(-0.25, -0.25)},
        {"unit_id": "farmer", "offset": Vector2(1.15, -0.10)},
        {"unit_id": "farmer", "offset": Vector2(-0.10, 1.15)},
        {"unit_id": "builder", "offset": Vector2(1.10, 1.10)},
        {"unit_id": "builder", "offset": Vector2(0.45, -0.75)},
        {"unit_id": "mechanic", "offset": Vector2(-0.65, 0.55)}
    ]

    for worker_spec in worker_specs:
        spawn_unit(str(worker_spec.get("unit_id", "")), home_position + worker_spec.get("offset", Vector2.ZERO))


func _update_buildings(delta: float) -> void:
    for building in buildings:
        if building.team == "player":
            building.regenerate(delta, float(world_state.modifiers.get("regeneration", 0.0)) * 2.0)

        var completed_jobs: Array = building.process(delta, world_state)
        for completed_job in completed_jobs:
            _handle_completed_building_job(building, completed_job)

        if building.team == "player":
            building.update_combat(delta, world_state, enemy_units)
        else:
            building.update_combat(delta, world_state, combat_units)


func _handle_completed_building_job(building, completed_job: Dictionary) -> void:
    var job_kind: String = str(completed_job.get("kind", ""))
    match job_kind:
        "train":
            var spawn_position := _spawn_position_for_building(building)
            var trained_actor: Variant = spawn_unit(str(completed_job.get("id", "")), spawn_position, building.team)
            if trained_actor == null:
                simulation_status = "failed to train %s" % str(completed_job.get("id", "unit"))
            else:
                if building.team == "enemy":
                    _apply_enemy_ai_to_actor(trained_actor, completed_job)
                simulation_status = "%s trained %s" % [building.name, str(completed_job.get("id", "unit"))]
        "research":
            var tech_record: Dictionary = ruleset_database.find_tech(str(completed_job.get("id", "")))
            if world_state.register_research(tech_record):
                _refresh_player_modifiers()
                simulation_status = "researched %s" % str(tech_record.get("id", "tech"))
        _:
            pass


func _refresh_player_modifiers() -> void:
    for building in buildings:
        building.refresh_modifiers(world_state)

    for combat_unit in combat_units:
        combat_unit.refresh_modifiers(world_state)


func _update_enemy_spawns() -> void:
    if not auto_enemy_pressure_enabled or pending_enemy_spawns.is_empty():
        return

    var remaining_spawns: Array = []
    for spawn_payload in pending_enemy_spawns:
        if float(spawn_payload.get("delay", 0.0)) <= world_state.elapsed_time:
            var unit_id: String = str(spawn_payload.get("unit_id", "basher"))
            var spawn_position := Vector2(float(spawn_payload.get("x", 0)) + 0.5, float(spawn_payload.get("y", 0)) + 0.5)
            var enemy_actor: Variant = spawn_unit(unit_id, spawn_position, "enemy")
            if enemy_actor != null:
                _apply_enemy_ai_to_actor(enemy_actor, spawn_payload)
                world_state.enemy_waves_spawned += 1
                _push_alert("enemy sighted: %s" % unit_id)
        else:
            remaining_spawns.append(spawn_payload)

    pending_enemy_spawns = remaining_spawns


func _update_enemy_ai() -> void:
    if not auto_enemy_pressure_enabled or enemy_ai_state.is_empty():
        return

    for index in range(enemy_ai_state.size()):
        var plan: Dictionary = _normalize_enemy_ai_plan(enemy_ai_state[index], index)
        if not bool(plan.get("enabled", true)):
            enemy_ai_state[index] = plan
            continue
        if world_state.elapsed_time < float(plan.get("start_after", 0.0)):
            enemy_ai_state[index] = plan
            continue

        var unit_id: String = str(plan.get("unit_id", ""))
        if unit_id.is_empty():
            enemy_ai_state[index] = plan
            continue

        if _enemy_unit_count(unit_id) >= int(plan.get("cap", 1)):
            enemy_ai_state[index] = plan
            continue

        var interval: float = maxf(1.0, float(plan.get("interval", 12.0)))
        var last_enqueue_time: float = float(plan.get("last_enqueue_time", -interval))
        if (world_state.elapsed_time - last_enqueue_time) < interval:
            enemy_ai_state[index] = plan
            continue

        var building = _find_enemy_training_building(plan)
        if building == null:
            enemy_ai_state[index] = plan
            continue

        var max_queue: int = maxi(1, int(plan.get("max_queue", 1)))
        if _queued_enemy_jobs(building, unit_id) >= max_queue:
            enemy_ai_state[index] = plan
            continue

        var unit_record: Dictionary = ruleset_database.find_unit(unit_id)
        if unit_record.is_empty():
            enemy_ai_state[index] = plan
            continue

        var duration: float = maxf(2.0, float(unit_record.get("recruit_time", 600)) / 300.0)
        building.enqueue_job("train", unit_id, duration, {
            "unit_id": unit_id,
            "enemy_ai_directive": _enemy_ai_directive_from_plan(plan)
        })
        plan["last_enqueue_time"] = world_state.elapsed_time
        enemy_ai_state[index] = plan


func _enemy_unit_count(unit_id: String) -> int:
    var count: int = 0
    for enemy_unit in enemy_units:
        if enemy_unit.unit_id == unit_id and enemy_unit.is_alive():
            count += 1
    return count


func _find_enemy_training_building(plan: Dictionary):
    var building_id: String = str(plan.get("building_id", ""))
    var search_rect: Rect2 = _action_rect(plan)
    for building in buildings:
        if building == null or building.team != "enemy" or not building.is_alive():
            continue
        if not building_id.is_empty() and building.building_id != building_id:
            continue
        if search_rect != null and not search_rect.has_point(building.center_position()):
            continue
        if not building.can_train_unit(str(plan.get("unit_id", ""))):
            continue
        return building
    return null


func _queued_enemy_jobs(building, unit_id: String) -> int:
    var count: int = 0
    for job in building.production_queue:
        if str(job.get("kind", "")) == "train" and str(job.get("id", "")) == unit_id:
            count += 1
    return count


func _normalize_enemy_ai_plans(plans: Array) -> Array:
    var normalized: Array = []
    for index in range(plans.size()):
        if typeof(plans[index]) != TYPE_DICTIONARY:
            continue
        normalized.append(_normalize_enemy_ai_plan(plans[index], index))
    return normalized


func _normalize_enemy_ai_plan(plan_payload: Dictionary, index: int) -> Dictionary:
    var plan: Dictionary = plan_payload.duplicate(true)
    var building_id: String = str(plan.get("building_id", "front"))
    var unit_id: String = str(plan.get("unit_id", "enemy"))
    var plan_id: String = str(plan.get("id", ""))
    if plan_id.is_empty():
        plan_id = "enemy_plan_%02d_%s_%s" % [index + 1, building_id, unit_id]
    plan["id"] = plan_id

    var behavior_profile: String = str(plan.get("behavior_profile", ""))
    if behavior_profile.is_empty():
        behavior_profile = _default_enemy_ai_profile(plan)
    plan["behavior_profile"] = behavior_profile

    var attack_mode: String = str(plan.get("attack_mode", ""))
    if attack_mode.is_empty():
        attack_mode = _default_enemy_ai_attack_mode(plan, behavior_profile)
    plan["attack_mode"] = attack_mode

    var pressure_rule: String = str(plan.get("pressure_rule", ""))
    if pressure_rule.is_empty():
        pressure_rule = _default_enemy_ai_pressure_rule(attack_mode, behavior_profile)
    plan["pressure_rule"] = pressure_rule

    var target_priority: Array = _string_array(plan.get("target_priority", []))
    if target_priority.is_empty():
        target_priority = _default_enemy_ai_target_priority(attack_mode, pressure_rule, behavior_profile)
    plan["target_priority"] = target_priority

    var default_group_size: int = 2 if attack_mode == "rally" else 1
    plan["min_group_size"] = maxi(1, int(plan.get("min_group_size", default_group_size)))
    plan["release_radius"] = maxf(0.85, float(plan.get("release_radius", 2.25)))
    plan["hold_radius"] = maxf(0.55, float(plan.get("hold_radius", 1.35)))
    plan["assignment_radius"] = maxf(float(plan.get("assignment_radius", 6.0)), float(plan.get("release_radius", 2.25)) + 1.5)

    var plan_anchor: Vector2 = _enemy_ai_plan_anchor(plan)
    var has_rally_point: bool = (
        plan.has("rally_point")
        or plan.has("rally_x")
        or plan.has("rally_y")
        or attack_mode == "hold"
        or int(plan.get("min_group_size", 1)) > 1
    )
    plan["has_rally_point"] = has_rally_point
    if has_rally_point:
        var rally_point: Vector2 = _enemy_ai_plan_point(plan, "rally", plan_anchor)
        plan["rally_point"] = {"x": rally_point.x, "y": rally_point.y}

    var has_pressure_point: bool = plan.has("pressure_point") or plan.has("pressure_x") or plan.has("pressure_y")
    plan["has_pressure_point"] = has_pressure_point
    if has_pressure_point:
        var pressure_point: Vector2 = _enemy_ai_plan_point(plan, "pressure", Vector2.ZERO)
        plan["pressure_point"] = {"x": pressure_point.x, "y": pressure_point.y}

    plan["group_released"] = bool(plan.get("group_released", false))
    return plan


func _default_enemy_ai_profile(plan: Dictionary) -> String:
    var planned_group_size: int = int(plan.get("min_group_size", 1))
    if planned_group_size > 1:
        return "siege"

    var unit_id: String = str(plan.get("unit_id", ""))
    if unit_id in ["hurler", "scorcher", "speeder"]:
        return "raider"
    return "assault"


func _default_enemy_ai_attack_mode(plan: Dictionary, behavior_profile: String) -> String:
    match behavior_profile:
        "sentinel":
            return "hold"
        "siege":
            return "rally"
        "raider":
            return "raid"
        _:
            return "rally" if int(plan.get("min_group_size", 1)) > 1 else "assault"


func _default_enemy_ai_pressure_rule(attack_mode: String, behavior_profile: String) -> String:
    match attack_mode:
        "hold":
            return "defend"
        "raid":
            return "workers"
        "rally":
            return "buildings" if behavior_profile == "siege" else "settlement"
        _:
            return "workers" if behavior_profile == "raider" else "settlement"


func _default_enemy_ai_target_priority(attack_mode: String, pressure_rule: String, behavior_profile: String) -> Array:
    match pressure_rule:
        "workers":
            return ["worker", "deposit", "building", "unit"]
        "buildings":
            return ["deposit", "building", "worker", "unit"]
        "units":
            return ["unit", "worker", "deposit", "building"]
        "defend":
            return ["unit", "worker", "deposit", "building"]
        _:
            if attack_mode == "raid" or behavior_profile == "raider":
                return ["worker", "deposit", "building", "unit"]
            if attack_mode == "rally" or behavior_profile == "siege":
                return ["deposit", "building", "worker", "unit"]
            return ["unit", "worker", "deposit", "building"]


func _string_array(values: Array) -> Array:
    var normalized: Array = []
    for value in values:
        normalized.append(str(value))
    return normalized


func _enemy_ai_plan_anchor(plan: Dictionary) -> Vector2:
    var width: float = maxf(1.0, float(plan.get("width", 1)))
    var height: float = maxf(1.0, float(plan.get("height", 1)))
    return Vector2(
        float(plan.get("x", 0)) + (width * 0.5),
        float(plan.get("y", 0)) + (height * 0.5)
    )


func _enemy_ai_plan_point(plan: Dictionary, prefix: String, fallback: Vector2) -> Vector2:
    var point_key: String = "%s_point" % prefix
    var point_payload: Variant = plan.get(point_key, null)
    if typeof(point_payload) == TYPE_DICTIONARY:
        return _point_from_payload(point_payload, fallback)

    var x_key: String = "%s_x" % prefix
    var y_key: String = "%s_y" % prefix
    if plan.has(x_key) or plan.has(y_key):
        var fallback_tile := Vector2(floor(fallback.x), floor(fallback.y))
        return Vector2(
            float(plan.get(x_key, fallback_tile.x)) + 0.5,
            float(plan.get(y_key, fallback_tile.y)) + 0.5
        )

    return fallback


func _point_from_payload(payload: Variant, fallback: Vector2) -> Vector2:
    if typeof(payload) != TYPE_DICTIONARY:
        return fallback

    var point_dict: Dictionary = payload
    return Vector2(
        float(point_dict.get("x", fallback.x)),
        float(point_dict.get("y", fallback.y))
    )


func _enemy_ai_directive_from_plan(plan: Dictionary) -> Dictionary:
    return {
        "plan_id": str(plan.get("id", "")),
        "behavior_profile": str(plan.get("behavior_profile", "assault")),
        "attack_mode": str(plan.get("attack_mode", "assault")),
        "pressure_rule": str(plan.get("pressure_rule", "settlement")),
        "target_priority": _string_array(plan.get("target_priority", [])),
        "has_rally_point": bool(plan.get("has_rally_point", false)),
        "rally_point": plan.get("rally_point", {"x": 0.0, "y": 0.0}).duplicate(true),
        "has_pressure_point": bool(plan.get("has_pressure_point", false)),
        "pressure_point": plan.get("pressure_point", {"x": 0.0, "y": 0.0}).duplicate(true),
        "min_group_size": int(plan.get("min_group_size", 1)),
        "release_radius": float(plan.get("release_radius", 2.25)),
        "hold_radius": float(plan.get("hold_radius", 1.35))
    }


func _enemy_ai_wave_plan(action_payload: Dictionary, unit_id: String, base_delay: float) -> Dictionary:
    if not _payload_has_enemy_ai_fields(action_payload):
        return {}

    var plan_payload: Dictionary = action_payload.duplicate(true)
    plan_payload["unit_id"] = unit_id
    plan_payload["building_id"] = str(plan_payload.get("building_id", "wave"))
    plan_payload["id"] = str(plan_payload.get("id", "enemy_wave_%s_%d_%d" % [
        unit_id,
        int(round(base_delay * 10.0)),
        pending_enemy_spawns.size()
    ]))
    return _normalize_enemy_ai_plan(plan_payload, pending_enemy_spawns.size())


func _enemy_ai_wave_directive(action_payload: Dictionary, unit_id: String, base_delay: float) -> Dictionary:
    var normalized_plan: Dictionary = _enemy_ai_wave_plan(action_payload, unit_id, base_delay)
    if normalized_plan.is_empty():
        return {}
    return _enemy_ai_directive_from_plan(normalized_plan)


func _payload_has_enemy_ai_fields(payload: Dictionary) -> bool:
    for key in [
        "behavior_profile",
        "attack_mode",
        "pressure_rule",
        "target_priority",
        "rally_point",
        "rally_x",
        "rally_y",
        "pressure_point",
        "pressure_x",
        "pressure_y",
        "min_group_size",
        "release_radius",
        "hold_radius",
        "assignment_radius"
    ]:
        if payload.has(str(key)):
            return true
    return false


func _apply_enemy_ai_to_existing_units() -> void:
    _sync_enemy_ai_assignments()


func _sync_enemy_ai_assignments() -> void:
    if enemy_ai_state.is_empty():
        return

    for enemy_unit in enemy_units:
        if enemy_unit == null or not enemy_unit.is_alive():
            continue
        if not str(enemy_unit.enemy_ai.get("plan_id", "")).is_empty():
            continue
        _apply_enemy_ai_to_actor(enemy_unit)


func _apply_enemy_ai_to_actor(actor: Variant, directive_source: Dictionary = {}) -> void:
    if actor == null or not actor.has_method("set_enemy_ai_directive"):
        return
    if str(actor.team) != "enemy":
        return

    var directive: Dictionary = {}
    if typeof(directive_source.get("enemy_ai_directive", {})) == TYPE_DICTIONARY:
        directive = directive_source.get("enemy_ai_directive", {}).duplicate(true)

    if directive.is_empty():
        var requested_plan_id: String = str(directive_source.get("enemy_ai_plan_id", ""))
        var matching_plan: Dictionary = _enemy_ai_plan_by_id(requested_plan_id)
        if matching_plan.is_empty():
            matching_plan = _matching_enemy_ai_plan_for_unit(actor)
        if matching_plan.is_empty():
            return
        directive = _enemy_ai_directive_from_plan(matching_plan)

    actor.set_enemy_ai_directive(directive)


func _enemy_ai_plan_by_id(plan_id: String) -> Dictionary:
    if plan_id.is_empty():
        return {}

    for plan in enemy_ai_state:
        if str(plan.get("id", "")) == plan_id:
            return plan
    return {}


func _upsert_enemy_ai_plan(plan_payload: Dictionary) -> void:
    if plan_payload.is_empty():
        return

    var plan_id: String = str(plan_payload.get("id", ""))
    if plan_id.is_empty():
        return

    for index in range(enemy_ai_state.size()):
        if str(enemy_ai_state[index].get("id", "")) != plan_id:
            continue
        var existing_plan: Dictionary = enemy_ai_state[index].duplicate(true)
        var existing_group_released: bool = bool(existing_plan.get("group_released", false))
        var next_plan: Dictionary = plan_payload.duplicate(true)
        next_plan["group_released"] = bool(next_plan.get("group_released", existing_group_released))
        enemy_ai_state[index] = next_plan
        return

    enemy_ai_state.append(plan_payload.duplicate(true))


func _matching_enemy_ai_plan_for_unit(enemy_unit) -> Dictionary:
    var best_plan: Dictionary = {}
    var best_distance: float = INF

    for plan in enemy_ai_state:
        if not bool(plan.get("enabled", true)):
            continue
        if str(plan.get("unit_id", "")) != str(enemy_unit.unit_id):
            continue

        var anchor_point: Vector2 = _point_from_payload(
            plan.get("rally_point", plan.get("pressure_point", {})),
            _enemy_ai_plan_anchor(plan)
        )
        var distance_to_anchor: float = enemy_unit.position.distance_to(anchor_point)
        if distance_to_anchor > float(plan.get("assignment_radius", 6.0)):
            continue
        if distance_to_anchor < best_distance:
            best_distance = distance_to_anchor
            best_plan = plan

    return best_plan


func _build_enemy_ai_contexts() -> Dictionary:
    var contexts: Dictionary = {}
    if enemy_ai_state.is_empty():
        return contexts

    var units_by_plan: Dictionary = {}
    for enemy_unit in enemy_units:
        if enemy_unit == null or not enemy_unit.is_alive():
            continue
        var plan_id: String = str(enemy_unit.enemy_ai.get("plan_id", ""))
        if plan_id.is_empty():
            continue
        if not units_by_plan.has(plan_id):
            units_by_plan[plan_id] = []
        units_by_plan[plan_id].append(enemy_unit)

    for index in range(enemy_ai_state.size()):
        var plan: Dictionary = enemy_ai_state[index].duplicate(true)
        var plan_id: String = str(plan.get("id", ""))
        var assigned_units: Array = units_by_plan.get(plan_id, [])
        var unit_count: int = assigned_units.size()
        var rally_count: int = unit_count

        if bool(plan.get("has_rally_point", false)):
            rally_count = 0
            var rally_point: Vector2 = _point_from_payload(plan.get("rally_point", {}), _enemy_ai_plan_anchor(plan))
            var release_radius: float = maxf(0.85, float(plan.get("release_radius", 2.25)))
            for enemy_unit in assigned_units:
                if enemy_unit.position.distance_to(rally_point) <= release_radius:
                    rally_count += 1

        var group_released: bool = bool(plan.get("group_released", false))
        var min_group_size: int = maxi(1, int(plan.get("min_group_size", 1)))
        if unit_count <= 0:
            group_released = false
        elif not group_released and rally_count >= min_group_size:
            group_released = true
        plan["group_released"] = group_released
        enemy_ai_state[index] = plan

        contexts[plan_id] = {
            "plan_unit_count": unit_count,
            "plan_rally_count": rally_count,
            "group_ready": group_released
        }
    return contexts


func _enemy_ai_context_for_unit(enemy_unit, contexts: Dictionary) -> Dictionary:
    if enemy_unit == null:
        return {}

    var plan_id: String = str(enemy_unit.enemy_ai.get("plan_id", ""))
    if plan_id.is_empty():
        return {}

    return contexts.get(plan_id, {})


func _finalize_construction_sites() -> void:
    var remaining_sites: Array = []
    for site in construction_sites:
        if site.built:
            spawn_completed_building(site.building_id, site.tile)
            simulation_status = "completed %s" % site.name
        else:
            remaining_sites.append(site)
    construction_sites = remaining_sites


func _cleanup_destroyed_entities() -> void:
    var worker_index_map: Dictionary = {}
    var surviving_workers: Array = []
    for old_worker_index in range(workers.size()):
        var worker = workers[old_worker_index]
        if worker.is_alive():
            worker_index_map[old_worker_index] = surviving_workers.size()
            surviving_workers.append(worker)
        else:
            world_state.casualties["player"] = int(world_state.casualties.get("player", 0)) + 1
    workers = surviving_workers
    selected_worker_indices = _remap_selection_indices(selected_worker_indices, worker_index_map)

    var combat_index_map: Dictionary = {}
    var surviving_combat_units: Array = []
    for old_combat_index in range(combat_units.size()):
        var combat_unit = combat_units[old_combat_index]
        if combat_unit.is_alive():
            combat_index_map[old_combat_index] = surviving_combat_units.size()
            surviving_combat_units.append(combat_unit)
        else:
            world_state.casualties["player"] = int(world_state.casualties.get("player", 0)) + 1
    combat_units = surviving_combat_units
    selected_combat_indices = _remap_selection_indices(selected_combat_indices, combat_index_map)

    var surviving_enemy_units: Array = []
    for enemy_unit in enemy_units:
        if enemy_unit.is_alive():
            surviving_enemy_units.append(enemy_unit)
        else:
            world_state.casualties["enemy"] = int(world_state.casualties.get("enemy", 0)) + 1
            simulation_status = "enemy defeated"
    enemy_units = surviving_enemy_units

    var surviving_buildings: Array = []
    for building in buildings:
        if building.is_alive():
            surviving_buildings.append(building)
        else:
            simulation_status = "%s destroyed" % building.name
    buildings = surviving_buildings

    _sync_primary_selection_indices()
    selected_building_index = _normalize_index(selected_building_index, buildings.size())
    selected_site_index = _normalize_index(selected_site_index, construction_sites.size())


func _update_command_markers(delta: float) -> void:
    if command_markers.is_empty():
        return

    var remaining_markers: Array = []
    for marker in command_markers:
        var updated_marker: Dictionary = marker.duplicate(true)
        updated_marker["ttl"] = float(updated_marker.get("ttl", 0.0)) - delta
        if float(updated_marker.get("ttl", 0.0)) > 0.0:
            remaining_markers.append(updated_marker)
    command_markers = remaining_markers


func _update_diplomacy_state() -> void:
    if diplomacy_targets.is_empty():
        return

    for combat_unit in combat_units:
        if combat_unit == null or not combat_unit.is_alive() or combat_unit.unit_id != "messenger":
            continue
        if combat_unit.diplomacy_target_id.is_empty():
            continue

        var diplomacy_target = _find_diplomacy_target_by_id(combat_unit.diplomacy_target_id)
        if diplomacy_target == null:
            combat_unit.clear_diplomacy_target()
            continue
        if diplomacy_target.stance == "allied":
            combat_unit.clear_diplomacy_target()
            continue
        if diplomacy_target.is_hostile():
            combat_unit.clear_diplomacy_target()
            combat_unit.has_move_target = false
            combat_unit.state = "holding"
            combat_unit.last_action = "rebuffed by %s" % diplomacy_target.clan_name
            _push_alert("%s refuses diplomacy and prepares for war" % diplomacy_target.clan_name)
            continue
        if combat_unit.position.distance_to(diplomacy_target.center_position()) > 0.45:
            continue
        if not diplomacy_target.can_form_alliance():
            combat_unit.clear_diplomacy_target()
            combat_unit.has_move_target = false
            combat_unit.state = "holding"
            if diplomacy_target.demand_status == "active":
                combat_unit.last_action = "awaiting %s demand" % diplomacy_target.clan_name
                _push_alert("%s demands: %s" % [diplomacy_target.clan_name, diplomacy_target.demand_label()])
            else:
                combat_unit.last_action = "trust too low with %s" % diplomacy_target.clan_name
                _push_alert("%s requires more trust before alliance" % diplomacy_target.clan_name)
            continue

        _form_alliance(diplomacy_target, combat_unit)


func _form_alliance(diplomacy_target, messenger) -> void:
    _set_clan_stance(diplomacy_target.clan_id, "allied")
    messenger.clear_diplomacy_target()
    messenger.has_move_target = false
    messenger.state = "holding"
    messenger.last_action = "allied with %s" % diplomacy_target.clan_name
    simulation_status = "allied with %s" % diplomacy_target.clan_name
    _push_alert("alliance forged: %s" % diplomacy_target.clan_name)


func _update_worker_home_positions() -> void:
    var deposit_positions: Array = []
    for building in buildings:
        if building.team == "player" and building.supports_deposit():
            deposit_positions.append(building.center_position())

    if deposit_positions.is_empty():
        deposit_positions.append(Vector2(map_state.player_start) + Vector2(0.5, 0.5))

    for worker in workers:
        var best_home: Vector2 = deposit_positions[0]
        var best_distance: float = worker.position.distance_to(best_home)
        for deposit_position in deposit_positions:
            var candidate_distance: float = worker.position.distance_to(deposit_position)
            if candidate_distance < best_distance:
                best_distance = candidate_distance
                best_home = deposit_position
        worker.set_home_position(best_home)


func _update_hunger(delta: float) -> void:
    var hunger_result: Dictionary = world_state.process_hunger(delta, _player_population_count(), _player_housing_capacity())
    if bool(hunger_result.get("recovered", false)):
        _push_alert("food stocks stabilized")

    if not bool(hunger_result.get("missed", false)):
        return

    _apply_starvation_penalty()
    _push_alert(
        "starvation warning: need %d food (%s)"
        % [
            maxi(1, int(hunger_result.get("shortfall", 0))),
            world_state.hunger_status_text()
        ]
    )


func _apply_starvation_penalty() -> void:
    var starvation_damage: float = 2.0 + (float(world_state.starvation_strikes) * 1.5)
    for worker in workers:
        if worker.is_alive():
            worker.apply_damage(starvation_damage)

    for combat_unit in combat_units:
        if combat_unit.team == "player" and combat_unit.is_alive():
            combat_unit.apply_damage(starvation_damage)


func _update_mission_state() -> void:
    var snapshot: Dictionary = _build_mission_snapshot()
    var newly_completed: Array[String] = mission_state.evaluate(snapshot)
    for completed_label in newly_completed:
        _push_alert("objective complete: %s" % completed_label)

    _update_mission_events(snapshot)
    if world_state.mission_status != "active":
        return
    mission_state.evaluate(_build_mission_snapshot())

    if world_state.starvation_failed():
        world_state.mission_status = "defeat"
        simulation_status = "clan starved"
        _register_campaign_outcome(false)
        return

    if _goal_complete():
        world_state.mission_status = "victory"
        simulation_status = "mission goal complete"
        _register_campaign_outcome(true)
        return

    if _player_defeated():
        world_state.mission_status = "defeat"
        simulation_status = "mission failed"
        _register_campaign_outcome(false)
        return

    world_state.mission_status = "active"


func _player_defeated() -> bool:
    var has_storehouse: bool = false
    for building in buildings:
        if building.team == "player" and building.supports_deposit():
            has_storehouse = true
            break

    var has_living_units: bool = false
    for worker in workers:
        if worker.is_alive():
            has_living_units = true
            break
    if not has_living_units:
        for combat_unit in combat_units:
            if combat_unit.team == "player" and combat_unit.is_alive():
                has_living_units = true
                break

    return not has_storehouse or not has_living_units


func _campaign_carryover_clan_payload() -> Dictionary:
    var payload: Dictionary = {}

    for diplomacy_target in diplomacy_targets:
        if diplomacy_target == null or diplomacy_target.clan_id.is_empty():
            continue
        payload[diplomacy_target.clan_id] = {
            "stance": diplomacy_target.stance,
            "trust": diplomacy_target.trust
        }

    for clan_id in allied_clans:
        var normalized_id: String = str(clan_id)
        if normalized_id.is_empty():
            continue
        var relationship_payload: Dictionary = payload.get(normalized_id, _campaign_clan_state_for(normalized_id))
        relationship_payload["stance"] = "allied"
        relationship_payload["trust"] = int(relationship_payload.get("trust", 0))
        payload[normalized_id] = relationship_payload

    for clan_id in hostile_clans:
        var normalized_id: String = str(clan_id)
        if normalized_id.is_empty():
            continue
        var relationship_payload: Dictionary = payload.get(normalized_id, _campaign_clan_state_for(normalized_id))
        relationship_payload["stance"] = "hostile"
        relationship_payload["trust"] = int(relationship_payload.get("trust", 0))
        payload[normalized_id] = relationship_payload

    return payload


func _register_campaign_outcome(victory: bool) -> void:
    if mission_resolution_recorded or campaign_state == null:
        return

    mission_resolution_recorded = true
    if victory:
        campaign_state.merge_carryover_state(world_state.unlocked_techs, _campaign_carryover_clan_payload())
    var outcome: Dictionary = campaign_state.record_mission_result(current_mission_id, victory, world_state.elapsed_time)
    save_campaign_profile()

    if victory:
        var next_mission_id: String = str(outcome.get("next_mission_id", ""))
        if not next_mission_id.is_empty():
            _push_alert("campaign unlocked: %s" % _mission_display_name(next_mission_id))
    else:
        _push_alert("campaign setback recorded")


func _update_mission_events(snapshot: Dictionary) -> void:
    for mission_event in mission_events:
        if not mission_event.should_fire(snapshot, mission_state):
            continue

        mission_event.fired = true
        for action_payload in mission_event.actions:
            _execute_mission_event_action(action_payload)


func _execute_mission_event_action(action_payload: Dictionary) -> void:
    var action_type: String = str(action_payload.get("type", ""))
    match action_type:
        "message":
            _push_alert(str(action_payload.get("text", "Mission event")))
        "grant_resources":
            var resource_payload: Dictionary = action_payload.get("resources", {})
            for resource_type in resource_payload.keys():
                world_state.add_resource(str(resource_type), int(resource_payload.get(resource_type, 0)))
        "spawn_unit":
            var spawn_count: int = maxi(1, int(action_payload.get("count", 1)))
            var base_position := Vector2(
                float(action_payload.get("x", map_state.player_start.x)) + 0.5,
                float(action_payload.get("y", map_state.player_start.y)) + 0.5
            )
            for index in range(spawn_count):
                var spawn_offset := Vector2(float(index % 2) * 0.45, float(index / 2) * 0.45)
                spawn_unit(
                    str(action_payload.get("unit_id", "")),
                    base_position + spawn_offset,
                    str(action_payload.get("team", "player"))
                )
        "spawn_building":
            spawn_completed_building(
                str(action_payload.get("building_id", "")),
                Vector2i(int(action_payload.get("x", map_state.player_start.x)), int(action_payload.get("y", map_state.player_start.y))),
                str(action_payload.get("team", "player"))
            )
        "schedule_enemy_wave":
            _schedule_enemy_wave(action_payload)
        "set_clan_stance":
            _set_clan_stance(str(action_payload.get("clan_id", "")), str(action_payload.get("stance", "neutral")))
            if action_payload.has("message"):
                _push_alert(str(action_payload.get("message", "")))
        "modify_clan_trust":
            _modify_clan_trust(
                str(action_payload.get("clan_id", "")),
                int(action_payload.get("value", 0)),
                str(action_payload.get("message", "")),
                bool(action_payload.get("allow_auto_alliance", true))
            )
        "set_clan_demand":
            _set_clan_demand(
                str(action_payload.get("clan_id", "")),
                action_payload.get("demand", {}).duplicate(true),
                str(action_payload.get("message", ""))
            )
        "unlock_build_palette":
            _unlock_build_palette(action_payload.get("building_ids", []).duplicate(true), str(action_payload.get("message", "")))
        "set_build_palette":
            _set_build_palette(action_payload.get("building_ids", []).duplicate(true), str(action_payload.get("message", "")))
        "transfer_building_team":
            _transfer_building_team(action_payload)
        "transfer_unit_team":
            _transfer_unit_team(action_payload)
        "set_mission_outcome":
            _set_mission_outcome(str(action_payload.get("status", "active")), str(action_payload.get("message", "")))
        _:
            pass


func _schedule_enemy_wave(action_payload: Dictionary) -> void:
    var spawn_count: int = maxi(1, int(action_payload.get("count", 1)))
    var base_delay: float = world_state.elapsed_time + maxf(0.0, float(action_payload.get("delay", 0.0)))
    var base_x: int = int(action_payload.get("x", 0))
    var base_y: int = int(action_payload.get("y", 0))
    var spacing: float = maxf(0.0, float(action_payload.get("spacing", 0.8)))
    var stagger: float = maxf(0.0, float(action_payload.get("stagger", 0.0)))
    var unit_id: String = str(action_payload.get("unit_id", "basher"))
    var enemy_ai_plan_id: String = str(action_payload.get("enemy_ai_plan_id", ""))
    var wave_ai_plan: Dictionary = _enemy_ai_wave_plan(action_payload, unit_id, base_delay)
    var enemy_ai_directive: Dictionary = _enemy_ai_wave_directive(action_payload, unit_id, base_delay)
    if enemy_ai_plan_id.is_empty() and not wave_ai_plan.is_empty():
        _upsert_enemy_ai_plan(wave_ai_plan)

    for index in range(spawn_count):
        var spawn_payload := {
            "unit_id": unit_id,
            "x": base_x + int(index % 2),
            "y": base_y + int(floor(float(index) / 2.0)),
            "delay": base_delay + (stagger * index),
            "spacing": spacing
        }
        if not enemy_ai_plan_id.is_empty():
            spawn_payload["enemy_ai_plan_id"] = enemy_ai_plan_id
        if not enemy_ai_directive.is_empty():
            spawn_payload["enemy_ai_directive"] = enemy_ai_directive.duplicate(true)
        pending_enemy_spawns.append(spawn_payload)


func _set_clan_stance(clan_id: String, stance: String) -> void:
    if clan_id.is_empty():
        return

    allied_clans.erase(clan_id)
    hostile_clans.erase(clan_id)
    match stance:
        "allied":
            if not allied_clans.has(clan_id):
                allied_clans.append(clan_id)
        "hostile":
            if not hostile_clans.has(clan_id):
                hostile_clans.append(clan_id)
        _:
            pass

    var diplomacy_target = _find_diplomacy_target_by_id(clan_id)
    if diplomacy_target != null:
        diplomacy_target.set_stance(stance)


func _modify_clan_trust(clan_id: String, value: int, message: String = "", allow_auto_alliance: bool = true) -> void:
    var diplomacy_target = _find_diplomacy_target_by_id(clan_id)
    if diplomacy_target == null:
        return

    diplomacy_target.trust += value
    if not message.is_empty():
        _push_alert(message)

    var auto_alliance: bool = allow_auto_alliance and bool(diplomacy_target.demand.get("auto_alliance_on_threshold", false))
    if auto_alliance and diplomacy_target.stance != "allied" and diplomacy_target.can_form_alliance():
        _set_clan_stance(clan_id, "allied")
        _push_alert("%s joins the coalition" % diplomacy_target.clan_name)


func _set_clan_demand(clan_id: String, demand_payload: Dictionary, message: String = "") -> void:
    var diplomacy_target = _find_diplomacy_target_by_id(clan_id)
    if diplomacy_target == null:
        return

    diplomacy_target.set_demand(demand_payload)
    if not message.is_empty():
        _push_alert(message)


func _unlock_build_palette(building_ids: Array, message: String = "") -> void:
    if map_state == null:
        return

    for building_id in building_ids:
        var normalized_id: String = str(building_id)
        if normalized_id.is_empty() or map_state.build_palette.has(normalized_id):
            continue
        map_state.build_palette.append(normalized_id)

    if not message.is_empty():
        _push_alert(message)


func _set_build_palette(building_ids: Array, message: String = "") -> void:
    if map_state == null:
        return

    map_state.build_palette = []
    for building_id in building_ids:
        var normalized_id: String = str(building_id)
        if normalized_id.is_empty() or map_state.build_palette.has(normalized_id):
            continue
        map_state.build_palette.append(normalized_id)

    if not message.is_empty():
        _push_alert(message)


func _transfer_building_team(action_payload: Dictionary) -> void:
    var target_team: String = str(action_payload.get("team", "player"))
    var target_building = _find_matching_building(action_payload)
    if target_building == null:
        return

    target_building.team = target_team
    if target_team == "player":
        target_building.refresh_modifiers(world_state)
    if action_payload.has("message"):
        _push_alert(str(action_payload.get("message", "")))


func _transfer_unit_team(action_payload: Dictionary) -> void:
    var target_team: String = str(action_payload.get("team", "player"))
    var target_unit = _find_matching_unit(action_payload)
    if target_unit == null:
        return

    var target_position: Vector2 = target_unit.position
    var target_unit_id: String = str(target_unit.unit_id)

    if target_unit in enemy_units:
        enemy_units.erase(target_unit)
    elif target_unit in combat_units:
        combat_units.erase(target_unit)

    spawn_unit(target_unit_id, target_position, target_team)
    if action_payload.has("message"):
        _push_alert(str(action_payload.get("message", "")))


func _set_mission_outcome(status: String, message: String = "") -> void:
    match status:
        "victory":
            world_state.mission_status = "victory"
            simulation_status = message if not message.is_empty() else "mission goal complete"
            _register_campaign_outcome(true)
        "defeat":
            world_state.mission_status = "defeat"
            simulation_status = message if not message.is_empty() else "mission failed"
            _register_campaign_outcome(false)
        _:
            world_state.mission_status = "active"
            if not message.is_empty():
                simulation_status = message


func _clan_stance_map() -> Dictionary:
    var payload: Dictionary = {}
    for diplomacy_target in diplomacy_targets:
        payload[diplomacy_target.clan_id] = diplomacy_target.stance
    for clan_id in allied_clans:
        payload[str(clan_id)] = "allied"
    for clan_id in hostile_clans:
        payload[str(clan_id)] = "hostile"
    return payload


func _clan_trust_map() -> Dictionary:
    var payload: Dictionary = {}
    for diplomacy_target in diplomacy_targets:
        payload[diplomacy_target.clan_id] = diplomacy_target.trust
    return payload


func _clan_demand_map() -> Dictionary:
    var payload: Dictionary = {}
    for diplomacy_target in diplomacy_targets:
        payload[diplomacy_target.clan_id] = {
            "status": diplomacy_target.demand_status,
            "label": diplomacy_target.demand_label()
        }
    return payload


func _update_clan_demands(snapshot: Dictionary) -> void:
    for diplomacy_target in diplomacy_targets:
        if diplomacy_target == null or diplomacy_target.demand_status != "active" or diplomacy_target.demand.is_empty():
            continue

        if _clan_demand_satisfied(snapshot, diplomacy_target):
            diplomacy_target.demand_status = "fulfilled"
            _modify_clan_trust(
                diplomacy_target.clan_id,
                int(diplomacy_target.demand.get("trust_reward", 1)),
                str(diplomacy_target.demand.get("success_message", "")),
                bool(diplomacy_target.demand.get("allow_auto_alliance", true))
            )

            var success_stance: String = str(diplomacy_target.demand.get("on_success_stance", ""))
            if not success_stance.is_empty():
                _set_clan_stance(diplomacy_target.clan_id, success_stance)

            var success_resources: Dictionary = diplomacy_target.demand.get("grant_resources", {})
            for resource_type in success_resources.keys():
                world_state.add_resource(str(resource_type), int(success_resources.get(resource_type, 0)))
            continue

        var deadline: float = float(diplomacy_target.demand.get("deadline", -1.0))
        if deadline >= 0.0 and world_state.elapsed_time >= deadline:
            diplomacy_target.demand_status = "failed"
            _modify_clan_trust(
                diplomacy_target.clan_id,
                int(diplomacy_target.demand.get("trust_penalty", -1)),
                str(diplomacy_target.demand.get("failure_message", "")),
                false
            )

            var failure_stance: String = str(diplomacy_target.demand.get("on_failure_stance", "hostile" if diplomacy_target.revenge_on_failure else ""))
            if not failure_stance.is_empty():
                _set_clan_stance(diplomacy_target.clan_id, failure_stance)


func _clan_demand_satisfied(snapshot: Dictionary, diplomacy_target) -> bool:
    var demand: Dictionary = diplomacy_target.demand
    var demand_type: String = str(demand.get("type", ""))
    match demand_type:
        "stockpile":
            return int(snapshot.get("resources", {}).get(str(demand.get("resource", "")), 0)) >= int(demand.get("target", 0))
        "building_count":
            return int(snapshot.get("building_counts", {}).get(str(demand.get("building_id", "")), 0)) >= int(demand.get("target", 0))
        "unit_count":
            return int(snapshot.get("unit_counts", {}).get(str(demand.get("unit_id", "")), 0)) >= int(demand.get("target", 0))
        "tech_count":
            return int(snapshot.get("unlocked_tech_count", 0)) >= int(demand.get("target", 0))
        "branch_level":
            return int(snapshot.get("branch_levels", {}).get(str(demand.get("branch", "")), 0)) >= int(demand.get("target", 0))
        "objective_complete":
            return mission_state.objective_completed(str(demand.get("objective_id", "")))
        "alliance_count":
            return int(snapshot.get("allied_clans", []).size()) >= int(demand.get("target", 0))
        _:
            return false


func _find_matching_building(action_payload: Dictionary):
    var target_building_id: String = str(action_payload.get("building_id", ""))
    var source_team: String = str(action_payload.get("source_team", ""))
    var search_rect: Rect2 = _action_rect(action_payload)

    for building in buildings:
        if building == null or not building.is_alive():
            continue
        if not target_building_id.is_empty() and building.building_id != target_building_id:
            continue
        if not source_team.is_empty() and building.team != source_team:
            continue
        if search_rect != null and not search_rect.has_point(building.center_position()):
            continue
        return building
    return null


func _find_matching_unit(action_payload: Dictionary):
    var target_unit_id: String = str(action_payload.get("unit_id", ""))
    var source_team: String = str(action_payload.get("source_team", ""))
    var search_rect: Rect2 = _action_rect(action_payload)

    for unit in combat_units + enemy_units:
        if unit == null or not unit.is_alive():
            continue
        if not target_unit_id.is_empty() and unit.unit_id != target_unit_id:
            continue
        if not source_team.is_empty() and unit.team != source_team:
            continue
        if search_rect != null and not search_rect.has_point(unit.position):
            continue
        return unit
    return null


func _action_rect(action_payload: Dictionary) -> Variant:
    if not action_payload.has("x") or not action_payload.has("y"):
        return null
    return Rect2(
        Vector2(float(action_payload.get("x", 0.0)), float(action_payload.get("y", 0.0))),
        Vector2(maxf(1.0, float(action_payload.get("width", 1.0))), maxf(1.0, float(action_payload.get("height", 1.0))))
    )


func _goal_complete() -> bool:
    if mission_state.runtime_objectives.is_empty():
        var food_target: int = int(map_state.storehouse_goal.get("food", 0))
        var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
        return int(world_state.resources.get("food", 0)) >= food_target and int(world_state.resources.get("stone", 0)) >= stone_target
    return mission_state.required_objectives_complete()


func _release_runtime_references() -> void:
    for combat_unit in combat_units:
        if combat_unit != null:
            combat_unit.clear_runtime_references()
    for enemy_unit in enemy_units:
        if enemy_unit != null:
            enemy_unit.clear_runtime_references()


func _map_path_for_mission(mission_id: String) -> String:
    if ruleset_database != null:
        var candidate_path: String = ruleset_database.mission_map_path(mission_id)
        if not candidate_path.is_empty() and FileAccess.file_exists(candidate_path):
            return candidate_path
    return DEFAULT_MAP_PATH


func _slot_save_path(slot_id: String) -> String:
    return "%s/%s.json" % [save_slot_directory, slot_id]


func _ensure_save_slot_dir() -> bool:
    return DirAccess.make_dir_recursive_absolute(save_slot_directory) == OK


func _clear_selection() -> void:
    selected_worker_indices = []
    selected_combat_indices = []
    selected_worker_index = -1
    selected_combat_index = -1
    selected_building_index = -1
    selected_site_index = -1


func _clear_drag_selection() -> void:
    selection_drag_active = false
    selection_drag_origin = Vector2.ZERO
    selection_drag_current = Vector2.ZERO


func _sync_primary_selection_indices() -> void:
    selected_worker_index = selected_worker_indices[0] if not selected_worker_indices.is_empty() else -1
    selected_combat_index = selected_combat_indices[0] if not selected_combat_indices.is_empty() else -1


func _remap_selection_indices(indices: Array[int], index_map: Dictionary) -> Array[int]:
    var remapped: Array[int] = []
    for index in indices:
        if index_map.has(index):
            remapped.append(int(index_map[index]))
    return remapped


func _mission_display_name(mission_id: String) -> String:
    var mission_record: Dictionary = ruleset_database.find_mission(mission_id)
    if not mission_record.is_empty():
        return _mission_frame_text(mission_record, mission_id)
    return mission_id


func _mission_frame_text(mission_record: Dictionary, fallback_mission_id: String = "") -> String:
    var chapter_text: String = _mission_chapter_text(mission_record)
    var mission_label: String = _mission_label(mission_record, fallback_mission_id)
    if chapter_text.is_empty():
        return mission_label
    return "%s | %s" % [chapter_text, mission_label]


func _mission_label(mission_record: Dictionary, fallback_mission_id: String = "") -> String:
    var mission_number: int = int(mission_record.get("mission_number", 0))
    if mission_number > 0:
        return "Mission %02d" % mission_number

    var title: String = str(mission_record.get("title", fallback_mission_id)).strip_edges()
    if not title.is_empty():
        return title
    return fallback_mission_id


func _mission_chapter_text(mission_record: Dictionary) -> String:
    var explicit_chapter: String = str(mission_record.get("chapter", "")).strip_edges()
    if not explicit_chapter.is_empty():
        return explicit_chapter.replace("\n", " ")

    var mission_number: int = int(mission_record.get("mission_number", 0))
    if mission_number <= 0:
        return ""
    if mission_number <= 4:
        return "Chapter I"
    if mission_number <= 8:
        return "Chapter II"
    if mission_number <= 12:
        return "Chapter III"
    if mission_number <= 16:
        return "Chapter IV"
    if mission_number <= 20:
        return "Chapter V"
    return "Chapter VI"


func _mission_synopsis_text(mission_record: Dictionary) -> String:
    var briefing: String = str(mission_record.get("briefing", ""))
    if briefing.is_empty():
        return ""

    var synopsis_index: int = briefing.find("Synopsis:")
    if synopsis_index < 0:
        return ""

    var synopsis_block: String = briefing.substr(synopsis_index + "Synopsis:".length()).strip_edges()
    var fragments: Array[String] = []
    for line in synopsis_block.split("\n"):
        var stripped: String = str(line).strip_edges()
        if stripped.is_empty():
            continue
        fragments.append(stripped)
        if fragments.size() >= 3:
            break
    return " | ".join(fragments)


func _campaign_record_totals() -> Dictionary:
    var totals := {
        "wins": 0,
        "losses": 0,
        "best_time": -1.0
    }
    if campaign_state == null:
        return totals

    for record in campaign_state.mission_records.values():
        totals["wins"] = int(totals.get("wins", 0)) + int(record.get("wins", 0))
        totals["losses"] = int(totals.get("losses", 0)) + int(record.get("losses", 0))
        var best_time: float = float(record.get("best_time", -1.0))
        if best_time >= 0.0:
            var current_best: float = float(totals.get("best_time", -1.0))
            if current_best < 0.0 or best_time < current_best:
                totals["best_time"] = best_time
    return totals


func _map_origin(viewport_size: Vector2) -> Vector2:
    var map_pixel_size := Vector2(map_state.width * TILE_SIZE, map_state.height * TILE_SIZE)
    return Vector2((viewport_size.x - map_pixel_size.x) * 0.5, MAP_TOP_MARGIN)


func _tile_origin(tile: Vector2i, origin: Vector2) -> Vector2:
    return origin + Vector2(float(tile.x) * TILE_SIZE, float(tile.y) * TILE_SIZE)


func _screen_to_tile(screen_position: Vector2) -> Vector2i:
    var origin := _map_origin(get_viewport_rect().size)
    var local := screen_position - origin
    return Vector2i(int(floor(local.x / TILE_SIZE)), int(floor(local.y / TILE_SIZE)))


func _screen_to_world(screen_position: Vector2) -> Vector2:
    var origin := _map_origin(get_viewport_rect().size)
    var local := screen_position - origin
    return local / TILE_SIZE


func _resource_index_at_tile(tile: Vector2i) -> int:
    for index in range(resource_nodes.size()):
        if resource_nodes[index].tile == tile and not resource_nodes[index].depleted():
            return index
    return -1


func _construction_index_at_tile(tile: Vector2i) -> int:
    for index in range(construction_sites.size()):
        if construction_sites[index].tile == tile:
            return index
    return -1


func _building_index_at_tile(tile: Vector2i) -> int:
    for index in range(buildings.size()):
        if buildings[index].tile == tile:
            return index
    return -1


func _worker_index_at_tile(tile: Vector2i) -> int:
    var tile_center := Vector2(tile) + Vector2(0.5, 0.5)
    var best_index := -1
    var best_distance := 0.6
    for index in range(workers.size()):
        if not workers[index].is_alive() or workers[index].is_boarded():
            continue
        var distance_to_worker: float = workers[index].position.distance_to(tile_center)
        if distance_to_worker < best_distance:
            best_distance = distance_to_worker
            best_index = index
    return best_index


func _combat_unit_index_at_tile(tile: Vector2i) -> int:
    var tile_center := Vector2(tile) + Vector2(0.5, 0.5)
    var best_index := -1
    var best_distance := 0.65
    for index in range(combat_units.size()):
        if not combat_units[index].is_alive() or combat_units[index].is_boarded():
            continue
        var distance_to_unit: float = combat_units[index].position.distance_to(tile_center)
        if distance_to_unit < best_distance:
            best_distance = distance_to_unit
            best_index = index
    return best_index


func _enemy_unit_index_at_tile(tile: Vector2i) -> int:
    var tile_center := Vector2(tile) + Vector2(0.5, 0.5)
    var best_index := -1
    var best_distance := 0.65
    for index in range(enemy_units.size()):
        var distance_to_unit: float = enemy_units[index].position.distance_to(tile_center)
        if distance_to_unit < best_distance:
            best_distance = distance_to_unit
            best_index = index
    return best_index


func _friendly_transport_index_at_tile(tile: Vector2i) -> int:
    var clicked_index: int = _combat_unit_index_at_tile(tile)
    if clicked_index < 0:
        return -1
    var carrier = combat_units[clicked_index]
    if carrier.team != "player" or not carrier.can_transport():
        return -1
    return clicked_index


func _diplomacy_target_index_at_tile(tile: Vector2i) -> int:
    for index in range(diplomacy_targets.size()):
        if diplomacy_targets[index].tile == tile:
            return index
    return -1


func _find_diplomacy_target_by_id(clan_id: String):
    for diplomacy_target in diplomacy_targets:
        if diplomacy_target.clan_id == clan_id:
            return diplomacy_target
    return null


func _can_place_building(tile: Vector2i) -> bool:
    if tile.x < 0 or tile.y < 0 or tile.x >= map_state.width or tile.y >= map_state.height:
        return false

    if map_state.terrain_at(tile.x, tile.y) == "water":
        return false
    if _resource_index_at_tile(tile) >= 0:
        return false
    if _building_index_at_tile(tile) >= 0:
        return false
    if _construction_index_at_tile(tile) >= 0:
        return false
    return true


func _selected_worker():
    if selected_worker_index < 0 or selected_worker_index >= workers.size():
        return null
    if workers[selected_worker_index].is_boarded():
        return null
    return workers[selected_worker_index]


func _selected_workers() -> Array:
    var results: Array = []
    for index in selected_worker_indices:
        if index >= 0 and index < workers.size() and not workers[index].is_boarded():
            results.append(workers[index])
    return results


func _selected_combat_unit():
    if selected_combat_index < 0 or selected_combat_index >= combat_units.size():
        return null
    if combat_units[selected_combat_index].is_boarded():
        return null
    return combat_units[selected_combat_index]


func _selected_combat_units() -> Array:
    var results: Array = []
    for index in selected_combat_indices:
        if index >= 0 and index < combat_units.size() and not combat_units[index].is_boarded():
            results.append(combat_units[index])
    return results


func _selected_building():
    if selected_building_index < 0 or selected_building_index >= buildings.size():
        return null
    return buildings[selected_building_index]


func _selected_worker_is_builder() -> bool:
    for worker in _selected_workers():
        if worker.unit_id == "builder":
            return true
    return false


func select_units_in_world_rect(selection_rect: Rect2) -> int:
    var normalized_rect := selection_rect.abs()
    selected_worker_indices = []
    selected_combat_indices = []
    selected_building_index = -1
    selected_site_index = -1

    for worker_index in range(workers.size()):
        if workers[worker_index].is_boarded():
            continue
        if normalized_rect.has_point(workers[worker_index].position):
            selected_worker_indices.append(worker_index)

    for combat_index in range(combat_units.size()):
        if combat_units[combat_index].is_boarded():
            continue
        if normalized_rect.has_point(combat_units[combat_index].position):
            selected_combat_indices.append(combat_index)

    _sync_primary_selection_indices()
    var selected_count: int = selected_worker_indices.size() + selected_combat_indices.size()
    if selected_count <= 0:
        simulation_status = "nothing selected"
    else:
        simulation_status = _selection_status_text(selected_worker_indices.size(), selected_combat_indices.size())
    return selected_count


func issue_order_to_tile(tile: Vector2i) -> void:
    _issue_order_to_tile(tile)


func _place_construction_site(tile: Vector2i, building_id: String) -> void:
    if not _can_place_building(tile):
        simulation_status = "invalid build location"
        return

    var building_record: Dictionary = ruleset_database.find_building(building_id)
    if building_record.is_empty():
        simulation_status = "unknown building"
        return

    var building_cost: Dictionary = building_record.get("cost", {}).duplicate(true)
    if not world_state.spend_resources(building_cost):
        simulation_status = "insufficient resources for %s" % building_id
        return

    var construction_site = ConstructionSiteStateScript.new()
    construction_site.configure_from_record(building_record, tile)
    construction_sites.append(construction_site)
    selected_site_index = construction_sites.size() - 1
    selected_building_index = -1
    simulation_status = "placed %s site" % building_record.get("name", building_id)


func _spawn_position_for_building(building) -> Vector2:
    var candidate_offsets: Array = [
        Vector2(1.5, 0.5),
        Vector2(0.5, 1.5),
        Vector2(-0.5, 0.5),
        Vector2(0.5, -0.5)
    ]

    for offset in candidate_offsets:
        var candidate: Vector2 = Vector2(building.tile) + offset
        if candidate.x >= 0.5 and candidate.y >= 0.5 and candidate.x < float(map_state.width) and candidate.y < float(map_state.height):
            return candidate
    return building.center_position()


func _nearest_deposit_position(position: Vector2) -> Vector2:
    var deposit_positions: Array = []
    for building in buildings:
        if building.team == "player" and building.supports_deposit():
            deposit_positions.append(building.center_position())

    if deposit_positions.is_empty():
        return Vector2(map_state.player_start) + Vector2(0.5, 0.5)

    var best_position: Vector2 = deposit_positions[0]
    var best_distance: float = position.distance_to(best_position)
    for deposit_position in deposit_positions:
        var candidate_distance: float = position.distance_to(deposit_position)
        if candidate_distance < best_distance:
            best_distance = candidate_distance
            best_position = deposit_position
    return best_position


func _is_worker_unit_id(unit_id: String) -> bool:
    return ["farmer", "builder", "mechanic"].has(unit_id)


func _normalize_index(index: int, size: int) -> int:
    if index < 0 or index >= size:
        return -1
    return index


func _building_color(building_id: String) -> Color:
    match building_id:
        "storehouse":
            return Color("70b8e8")
        "culture":
            return Color("8ab648")
        "barracks":
            return Color("ca7753")
        "sanctuary", "temple":
            return Color("55d6b7")
        "workshop":
            return Color("8d7c69")
        "garage":
            return Color("c85d4f")
        "hangar", "heliport":
            return Color("7ebde8")
        "market":
            return Color("d9a259")
        "library":
            return Color("d9c27b")
        "laboratory":
            return Color("d98be0")
        "tower_catapult":
            return Color("908a78")
        "tower_cannon":
            return Color("a7a3a0")
        "wall", "portcullis":
            return Color("6d747c")
        _:
            return Color("70b8e8")


func _terrain_color(terrain: String) -> Color:
    match terrain:
        "grass":
            return Color("456b3d")
        "dirt":
            return Color("6a553d")
        "forest":
            return Color("2f4f2c")
        "rock":
            return Color("666869")
        "sand":
            return Color("b29660")
        "water":
            return Color("2a4a71")
        _:
            return Color("202c36")


func _resource_color(resource_type: String) -> Color:
    match resource_type:
        "food":
            return Color("8ab648")
        "stone":
            return Color("c0c0c0")
        "parts":
            return Color("c09050")
        "tech":
            return Color("d98be0")
        _:
            return Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        hover_tile = _screen_to_tile(event.position)
        if selection_drag_active:
            selection_drag_current = event.position
            if is_inside_tree():
                queue_redraw()
        return

    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                selection_drag_active = true
                selection_drag_origin = event.position
                selection_drag_current = event.position
                return

            if selection_drag_active:
                selection_drag_current = event.position
                var drag_start: Vector2 = selection_drag_origin
                var drag_distance: float = drag_start.distance_to(selection_drag_current)
                _clear_drag_selection()
                if build_mode.is_empty() and drag_distance >= SELECTION_DRAG_THRESHOLD:
                    _handle_drag_selection(drag_start, event.position)
                else:
                    _handle_left_click(event.position)
                if is_inside_tree():
                    queue_redraw()
            return

        if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
            _handle_right_click(event.position)
            return

    if event is InputEventKey and event.pressed and not event.echo:
        var requested_build_mode: String = _build_mode_for_key(event.keycode)
        if not requested_build_mode.is_empty() and _selected_worker_is_builder():
            build_mode = requested_build_mode
            simulation_status = "build mode: %s" % _building_display_name(requested_build_mode)
            return

        match event.keycode:
            KEY_ESCAPE:
                build_mode = ""
                _clear_selection()
                _clear_drag_selection()
                simulation_status = "selection cleared"
            KEY_Q:
                _handle_context_action(1)
            KEY_W:
                _handle_context_action(2)
            KEY_E:
                _handle_context_action(3)
            KEY_R:
                _handle_context_action(4)
            KEY_T:
                _handle_context_action(5)
            KEY_Y:
                _handle_context_action(6)
            KEY_F5:
                if not save_game_state():
                    simulation_status = "save failed"
            KEY_F6:
                if not save_to_slot(active_save_slot_id):
                    simulation_status = "slot save failed"
            KEY_F7:
                if not load_from_slot(active_save_slot_id):
                    simulation_status = "slot load failed"
            KEY_F9:
                if not load_game_state():
                    simulation_status = "load failed"


func _handle_context_action(slot: int) -> void:
    invoke_selected_building_action(slot)


func selected_building_actions() -> Array:
    var selected_unit = _selected_combat_unit()
    if selected_combat_indices.size() == 1 and selected_unit != null:
        var combat_actions: Array = _combat_unit_actions(selected_unit)
        if not combat_actions.is_empty():
            return combat_actions.duplicate(true)

    var building = _selected_building()
    if building == null:
        return []
    return _building_actions(building.building_id).duplicate(true)


func invoke_selected_building_action(slot: int) -> bool:
    var selected_unit = _selected_combat_unit()
    if selected_combat_indices.size() == 1 and selected_unit != null:
        for action in _combat_unit_actions(selected_unit):
            if int(action.get("slot", 0)) != slot:
                continue

            var action_kind: String = str(action.get("kind", ""))
            var action_id: String = str(action.get("id", ""))
            match action_kind:
                "spell":
                    return cast_spell_for_selected_unit(action_id)
                "tame":
                    return tame_creature_for_selected_unit()
                "transport_unload":
                    return unload_selected_transport()
                _:
                    return false

    var building = _selected_building()
    if building == null:
        return false

    for action in _building_actions(building.building_id):
        if int(action.get("slot", 0)) != slot:
            continue

        var action_kind: String = str(action.get("kind", ""))
        var action_id: String = str(action.get("id", ""))
        match action_kind:
            "train":
                return queue_training_for_building(selected_building_index, action_id)
            "research":
                return queue_research_for_building(selected_building_index, action_id)
            _:
                return false
    return false


func _build_mode_for_key(keycode: Key) -> String:
    for binding in BUILD_KEY_ORDER:
        if int(binding.get("keycode", -1)) != int(keycode):
            continue

        var building_id: String = str(binding.get("building_id", ""))
        if not _build_palette_allows(building_id):
            return ""
        return building_id
    return ""


func _build_palette_allows(building_id: String) -> bool:
    if map_state == null or map_state.build_palette.is_empty():
        return true
    return map_state.build_palette.has(building_id)


func _build_palette_label() -> String:
    var labels: Array[String] = []
    for binding in BUILD_KEY_ORDER:
        var building_id: String = str(binding.get("building_id", ""))
        if not _build_palette_allows(building_id):
            continue
        labels.append("%s %s" % [_key_label(int(binding.get("keycode", -1))), _building_display_name(building_id)])
    return "Build: %s" % " | ".join(labels)


func _key_label(keycode: int) -> String:
    match keycode:
        KEY_MINUS:
            return "-"
        KEY_EQUAL:
            return "="
        _:
            return OS.get_keycode_string(keycode)


func _combat_unit_actions(combat_unit) -> Array:
    if combat_unit == null or combat_unit.team != "player":
        return []

    if combat_unit.can_transport():
        return [{
            "slot": 1,
            "key": "Q",
            "kind": "transport_unload",
            "id": "unload",
            "label": "Unload %d/%d" % [combat_unit.passenger_ids.size(), combat_unit.transport_capacity]
        }]

    if combat_unit.unit_id != "druid":
        return []

    var supported_spells := [
        {"slot": 1, "key": "Q", "id": "armour"},
        {"slot": 2, "key": "W", "id": "petrification"},
        {"slot": 3, "key": "E", "id": "nova"},
        {"slot": 4, "key": "R", "id": "vision"},
    ]
    var actions: Array = []
    for action in supported_spells:
        var spell_id: String = str(action.get("id", ""))
        var spell_record: Dictionary = ruleset_database.find_spell(spell_id)
        if spell_record.is_empty():
            continue

        var label: String = str(spell_record.get("name", spell_id))
        var cooldown: float = combat_unit.cooldown_for_spell(spell_id)
        if cooldown > 0.0:
            label = "%s %.1fs" % [label, cooldown]

        actions.append({
            "slot": int(action.get("slot", 0)),
            "key": str(action.get("key", "")),
            "kind": "spell",
            "id": spell_id,
            "label": label
        })

    var tame_label: String = "Tame"
    var tame_cooldown: float = combat_unit.cooldown_for_spell("tame")
    if tame_cooldown > 0.0:
        tame_label = "Tame %.1fs" % tame_cooldown
    actions.append({
        "slot": 5,
        "key": "T",
        "kind": "tame",
        "id": "tame",
        "label": tame_label
    })
    return actions


func _building_actions(building_id: String) -> Array:
    match building_id:
        "culture":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "farmer", "label": "farmer"},
                {"slot": 2, "key": "W", "kind": "train", "id": "builder", "label": "builder"},
                {"slot": 3, "key": "E", "kind": "train", "id": "mechanic", "label": "mechanic"},
                {"slot": 4, "key": "R", "kind": "train", "id": "settler", "label": "settler"},
                {"slot": 5, "key": "T", "kind": "train", "id": "messenger", "label": "messenger"},
            ]
        "barracks":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "swordsman", "label": "swordsman"},
                {"slot": 2, "key": "W", "kind": "train", "id": "captain", "label": "captain"},
                {"slot": 3, "key": "E", "kind": "train", "id": "archer", "label": "archer"},
                {"slot": 4, "key": "R", "kind": "train", "id": "scorcher", "label": "scorcher"},
            ]
        "sanctuary", "temple":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "druid", "label": "druid"},
            ]
        "workshop":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "stomper", "label": "stomper"},
            ]
        "garage":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "speeder", "label": "speeder"},
                {"slot": 2, "key": "W", "kind": "train", "id": "boomer", "label": "boomer"},
                {"slot": 3, "key": "E", "kind": "train", "id": "reaper", "label": "reaper"},
                {"slot": 4, "key": "R", "kind": "train", "id": "bomber", "label": "bomber"},
                {"slot": 5, "key": "T", "kind": "train", "id": "hellfire", "label": "hellfire"},
            ]
        "hangar", "heliport":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "heliped", "label": "heliped"},
                {"slot": 2, "key": "W", "kind": "train", "id": "balloon", "label": "balloon"},
            ]
        "market":
            return [
                {"slot": 1, "key": "Q", "kind": "train", "id": "messenger", "label": "messenger"},
            ]
        "laboratory", "library":
            return [
                {"slot": 1, "key": "Q", "kind": "research", "id": "agriculture", "label": "agriculture"},
                {"slot": 2, "key": "W", "kind": "research", "id": "military", "label": "military"},
                {"slot": 3, "key": "E", "kind": "research", "id": "civil_engineering", "label": "civil"},
                {"slot": 4, "key": "R", "kind": "research", "id": "religious", "label": "religious"},
            ]
        _:
            return []


func _spell_resource_cost(spell_record: Dictionary) -> Dictionary:
    var resource_cost: Dictionary = {}
    var raw_cost: Dictionary = spell_record.get("cost", {})
    for resource_type in ["food", "stone", "parts"]:
        var amount: int = int(raw_cost.get(resource_type, 0))
        if amount > 0:
            resource_cost[resource_type] = amount
    return resource_cost


func _spell_duration_seconds(spell_record: Dictionary) -> float:
    return maxf(1.5, float(spell_record.get("duration", 30)) / 30.0)


func _spell_cooldown_seconds(spell_record: Dictionary) -> float:
    return maxf(2.0, float(spell_record.get("learn_time", 1000)) / 500.0)


func _nearest_enemy_spell_target(caster, max_range: float) -> Variant:
    var best_target = null
    var best_distance: float = INF
    var effective_range: float = maxf(2.0, max_range)
    for enemy_unit in enemy_units:
        if enemy_unit == null or not enemy_unit.is_alive():
            continue
        var distance_to_target: float = caster.position.distance_to(enemy_unit.position)
        if distance_to_target > effective_range:
            continue
        if distance_to_target < best_distance:
            best_distance = distance_to_target
            best_target = enemy_unit
    return best_target


func _nearest_tamable_creature(caster, max_range: float) -> Variant:
    var best_target = null
    var best_distance: float = INF
    for enemy_unit in enemy_units:
        if enemy_unit == null or not enemy_unit.is_alive():
            continue
        if not _is_tamable_creature(enemy_unit):
            continue
        if enemy_unit.health > (enemy_unit.max_health * TAME_HEALTH_RATIO):
            continue
        var distance_to_target: float = caster.position.distance_to(enemy_unit.position)
        if distance_to_target > maxf(1.5, max_range):
            continue
        if distance_to_target < best_distance:
            best_distance = distance_to_target
            best_target = enemy_unit
    return best_target


func _is_tamable_creature(actor) -> bool:
    if actor == null or actor.team == "player":
        return false
    var unit_record: Dictionary = ruleset_database.find_unit(str(actor.unit_id))
    if unit_record.is_empty():
        return false
    return (
        str(unit_record.get("faction", "")).to_lower() == "creature"
        or str(unit_record.get("role", "")).to_lower() == "creature"
    )


func _tame_creature(target, caster) -> bool:
    if target == null or caster == null:
        return false

    var target_index: int = enemy_units.find(target)
    if target_index < 0:
        return false

    enemy_units.remove_at(target_index)
    target.set_team("player")
    target.clear_runtime_references()
    target.clear_diplomacy_target()
    target.has_move_target = false
    target.move_target = caster.position
    target.position = caster.position + Vector2(0.65, 0.0)
    target.health = maxf(target.health, target.max_health * TAME_STABILIZE_RATIO)
    target.state = "holding"
    target.last_action = "tamed by %s" % caster.name
    target.refresh_modifiers(world_state)
    combat_units.append(target)
    return true


func _cast_armour_spell(caster, spell_record: Dictionary) -> bool:
    caster.apply_spell_effect({
        "id": "armour",
        "duration": _spell_duration_seconds(spell_record),
        "armor_bonus": 2.0
    })
    caster.last_action = "cast armour"
    return true


func _cast_vision_spell(caster, spell_record: Dictionary) -> bool:
    caster.apply_spell_effect({
        "id": "vision",
        "duration": _spell_duration_seconds(spell_record),
        "vision_bonus": maxf(2.0, float(spell_record.get("radius", 4)))
    })
    caster.last_action = "cast vision"
    return true


func _cast_petrification_spell(caster, target, spell_record: Dictionary) -> bool:
    if target == null:
        return false

    target.apply_spell_effect({
        "id": "petrification",
        "duration": _spell_duration_seconds(spell_record)
    })
    target.has_move_target = false
    target.last_action = "petrified"
    caster.last_action = "cast petrification"
    return true


func _cast_nova_spell(caster, primary_target, spell_record: Dictionary) -> bool:
    if primary_target == null:
        return false

    var damage_amount: float = float(ruleset_database.misc.get("degat_nova_petite", 40))
    var effect_radius: float = maxf(0.75, float(spell_record.get("radius", 0)))
    var impact_position: Vector2 = primary_target.position

    for enemy_unit in enemy_units:
        if enemy_unit == null or not enemy_unit.is_alive():
            continue
        if enemy_unit.position.distance_to(impact_position) > effect_radius:
            continue
        enemy_unit.apply_damage(damage_amount)
        enemy_unit.last_action = "shaken by nova"

    caster.last_action = "cast nova"
    return true


func _context_hint_for_building(building) -> String:
    var actions: Array = _building_actions(building.building_id)
    if actions.is_empty():
        return "Context: %s" % building.queue_label()

    var hints: Array[String] = []
    for action in actions:
        hints.append("%s %s" % [str(action.get("key", "")), str(action.get("label", action.get("id", "")))])
    return "Context: %s" % " | ".join(hints)


func _building_display_name(building_id: String) -> String:
    var building_record: Dictionary = ruleset_database.find_building(building_id)
    if not building_record.is_empty():
        return str(building_record.get("name", building_id))
    return building_id


func _handle_drag_selection(start_position: Vector2, end_position: Vector2) -> void:
    var start_world := _screen_to_world(start_position)
    var end_world := _screen_to_world(end_position)
    select_units_in_world_rect(Rect2(start_world, end_world - start_world).abs().grow(0.2))


func _handle_left_click(screen_position: Vector2) -> void:
    var tile := _screen_to_tile(screen_position)
    hover_tile = tile

    if not build_mode.is_empty():
        if _selected_worker_is_builder():
            _place_construction_site(tile, build_mode)
        build_mode = ""
        return

    var clicked_worker_index: int = _worker_index_at_tile(tile)
    var clicked_combat_index: int = _combat_unit_index_at_tile(tile)
    selected_building_index = _building_index_at_tile(tile)
    selected_site_index = _construction_index_at_tile(tile)

    if clicked_worker_index >= 0:
        selected_worker_indices = [clicked_worker_index]
        selected_combat_indices = []
        _sync_primary_selection_indices()
        selected_building_index = -1
        selected_site_index = -1
        simulation_status = "selected %s" % workers[clicked_worker_index].name
    elif clicked_combat_index >= 0:
        selected_worker_indices = []
        selected_combat_indices = [clicked_combat_index]
        _sync_primary_selection_indices()
        selected_building_index = -1
        selected_site_index = -1
        simulation_status = "selected %s" % combat_units[clicked_combat_index].name
    elif selected_building_index >= 0:
        selected_worker_indices = []
        selected_combat_indices = []
        _sync_primary_selection_indices()
        selected_site_index = -1
        simulation_status = "selected %s" % buildings[selected_building_index].name
    elif selected_site_index >= 0:
        selected_worker_indices = []
        selected_combat_indices = []
        _sync_primary_selection_indices()
        selected_building_index = -1
        simulation_status = "selected construction site"
    else:
        _clear_selection()
        simulation_status = "nothing selected"


func _handle_right_click(screen_position: Vector2) -> void:
    var tile := _screen_to_tile(screen_position)
    hover_tile = tile
    _issue_order_to_tile(tile)


func _issue_order_to_tile(tile: Vector2i) -> void:
    var selected_workers := _selected_workers()
    var selected_combat := _selected_combat_units()

    if not selected_workers.is_empty():
        var resource_index := _resource_index_at_tile(tile)
        if resource_index >= 0:
            var resource_node = resource_nodes[resource_index]
            var assigned_workers: int = 0
            for worker in selected_workers:
                if worker.job_resource_type != resource_node.resource_type:
                    continue
                worker.assign_resource_target(resource_index)
                assigned_workers += 1

            if assigned_workers > 0:
                _push_command_marker(Vector2(tile) + Vector2(0.5, 0.5), "gather")
                simulation_status = "%d workers assigned to %s" % [assigned_workers, resource_node.resource_type]
            else:
                simulation_status = "selected workers cannot gather %s" % resource_node.resource_type
            return

        var construction_index := _construction_index_at_tile(tile)
        if construction_index >= 0:
            var assigned_builders: int = 0
            for worker in selected_workers:
                if worker.unit_id != "builder":
                    continue
                worker.assign_construction_target(construction_index)
                assigned_builders += 1

            if assigned_builders > 0:
                selected_site_index = construction_index
                selected_building_index = -1
                _push_command_marker(Vector2(tile) + Vector2(0.5, 0.5), "build")
                simulation_status = "%d builders assigned to build" % assigned_builders
            else:
                simulation_status = "no builder selected"
            return

    var transport_index := _friendly_transport_index_at_tile(tile)
    if transport_index >= 0:
        var carrier = combat_units[transport_index]
        var boarding_count: int = _issue_transport_board_orders(selected_workers, selected_combat, carrier)
        if boarding_count > 0:
            _push_command_marker(carrier.position, "transport")
            simulation_status = "%d units boarding %s" % [boarding_count, carrier.name]
            return

    if not selected_combat.is_empty():
        var diplomacy_index := _diplomacy_target_index_at_tile(tile)
        if diplomacy_index >= 0:
            var diplomacy_target = diplomacy_targets[diplomacy_index]
            var messenger_count: int = 0
            for combat_unit in selected_combat:
                if combat_unit.unit_id != "messenger":
                    continue
                combat_unit.assign_diplomacy_target(diplomacy_target.clan_id, diplomacy_target.center_position())
                messenger_count += 1

            if messenger_count > 0:
                _push_command_marker(diplomacy_target.center_position(), "diplomacy")
                simulation_status = "%d messengers dispatched to %s" % [messenger_count, diplomacy_target.clan_name]
            else:
                simulation_status = "no messenger selected"
            return

        var enemy_index := _enemy_unit_index_at_tile(tile)
        if enemy_index >= 0:
            for combat_unit in selected_combat:
                combat_unit.assign_attack_target(enemy_units[enemy_index], "enemy")
            _push_command_marker(Vector2(tile) + Vector2(0.5, 0.5), "attack")
            simulation_status = _attack_status_text(selected_combat.size())
            return

    var target_position := Vector2(tile) + Vector2(0.5, 0.5)
    if not selected_workers.is_empty():
        _issue_worker_move_orders(selected_workers, target_position)
    if not selected_combat.is_empty():
        _issue_combat_move_orders(selected_combat, target_position)

    if not selected_workers.is_empty() or not selected_combat.is_empty():
        _push_command_marker(target_position, "move")
        simulation_status = _movement_status_text(selected_workers.size(), selected_combat.size())


func _issue_worker_move_orders(selected_workers: Array, target_position: Vector2) -> void:
    var offsets: Array = _formation_offsets(selected_workers.size(), 0.85)
    for index in range(selected_workers.size()):
        var worker = selected_workers[index]
        worker.assign_move_target(target_position + offsets[index])


func _issue_combat_move_orders(selected_combat: Array, target_position: Vector2) -> void:
    var offsets: Array = _formation_offsets(selected_combat.size(), 0.95)
    for index in range(selected_combat.size()):
        var combat_unit = selected_combat[index]
        combat_unit.assign_move_target(target_position + offsets[index])


func _issue_transport_board_orders(selected_workers: Array, selected_combat: Array, carrier) -> int:
    if carrier == null or not carrier.can_transport():
        return 0

    var boarding_count: int = 0
    for worker in selected_workers:
        if not _can_board_transport(carrier, worker):
            continue
        worker.assign_transport_target(carrier.entity_id, carrier.position)
        boarding_count += 1

    for combat_unit in selected_combat:
        if not _can_board_transport(carrier, combat_unit):
            continue
        combat_unit.assign_transport_target(carrier.entity_id, carrier.position)
        boarding_count += 1

    return boarding_count


func _formation_offsets(count: int, spacing: float) -> Array:
    var offsets: Array = []
    if count <= 0:
        return offsets

    var columns: int = maxi(1, int(ceil(sqrt(float(count)))))
    var rows: int = int(ceil(float(count) / float(columns)))
    var total_width: float = float(columns - 1) * spacing
    var total_height: float = float(rows - 1) * spacing

    for index in range(count):
        var row: int = int(index / columns)
        var column: int = int(index % columns)
        offsets.append(Vector2(
            (float(column) * spacing) - (total_width * 0.5),
            (float(row) * spacing) - (total_height * 0.5)
        ))
    return offsets


func _push_command_marker(position: Vector2, kind: String) -> void:
    command_markers.append({
        "position": {"x": position.x, "y": position.y},
        "kind": kind,
        "ttl": COMMAND_MARKER_DURATION
    })


func _selection_status_text(worker_count: int, combat_count: int) -> String:
    var fragments: Array[String] = []
    if worker_count > 0:
        fragments.append("%d workers" % worker_count)
    if combat_count > 0:
        fragments.append("%d units" % combat_count)
    return "selected %s" % " + ".join(fragments)


func _movement_status_text(worker_count: int, combat_count: int) -> String:
    var fragments: Array[String] = []
    if worker_count > 0:
        fragments.append("%d workers moving" % worker_count)
    if combat_count > 0:
        fragments.append("%d units moving" % combat_count)
    return " | ".join(fragments)


func _attack_status_text(combat_count: int) -> String:
    return "%d units attacking" % combat_count


func _count_selected_builders() -> int:
    var builder_count: int = 0
    for worker in _selected_workers():
        if worker.unit_id == "builder":
            builder_count += 1
    return builder_count


func _selected_role_summary(selected_units: Array) -> String:
    var role_counts: Dictionary = {}
    for unit in selected_units:
        var role_id: String = str(unit.unit_id)
        role_counts[role_id] = int(role_counts.get(role_id, 0)) + 1

    var fragments: Array[String] = []
    for role_id in role_counts.keys():
        fragments.append("%s x%d" % [role_id, int(role_counts.get(role_id, 0))])
    return ", ".join(fragments)


func _command_marker_color(kind: String) -> Color:
    match kind:
        "gather":
            return Color("8ab648")
        "build":
            return Color("f0c58a")
        "attack":
            return Color("e15c55")
        "diplomacy":
            return Color("d9a259")
        "transport":
            return Color("9fd9ff")
        _:
            return Color("70b8e8")


func _selection_detail_lines() -> Array[String]:
    var lines: Array[String] = []
    var selected_workers := _selected_workers()
    var selected_combat := _selected_combat_units()
    var selected_total: int = selected_workers.size() + selected_combat.size()

    if selected_total > 1:
        lines.append("Selected Units: %d" % selected_total)
        if not selected_workers.is_empty():
            lines.append("Workers: %d | Builders: %d" % [selected_workers.size(), _count_selected_builders()])
        if not selected_combat.is_empty():
            lines.append("Combat: %d | %s" % [selected_combat.size(), _selected_role_summary(selected_combat)])
        return lines

    var selected_worker = _selected_worker()
    if selected_worker != null:
        lines.append(
            "Selected Worker: %s | hp %d/%d | %s"
            % [selected_worker.name, int(ceil(selected_worker.health)), int(ceil(selected_worker.max_health)), selected_worker.status_text()]
        )
        return lines

    var selected_combat_unit = _selected_combat_unit()
    if selected_combat_unit != null:
        lines.append(
            "Selected Unit: %s | hp %d/%d | %s"
            % [
                selected_combat_unit.name,
                int(ceil(selected_combat_unit.health)),
                int(ceil(selected_combat_unit.max_health)),
                selected_combat_unit.status_text()
            ]
        )
        for spell_line in selected_combat_unit.spell_status_lines():
            lines.append(spell_line)
        return lines

    var selected_building = _selected_building()
    if selected_building != null:
        lines.append(
            "Selected Building: %s | hp %d/%d"
            % [selected_building.name, int(ceil(selected_building.health)), int(ceil(selected_building.max_health))]
        )
        lines.append("Queue: %s" % selected_building.queue_label())
        if selected_building.can_attack():
            lines.append("Defense: %dm range | %s" % [int(round(selected_building.attack_range)), selected_building.last_action])
        return lines

    if selected_site_index >= 0 and selected_site_index < construction_sites.size():
        var selected_site = construction_sites[selected_site_index]
        lines.append(
            "Selected Site: %s | build %d%%"
            % [selected_site.name, int(round(selected_site.build_ratio() * 100.0))]
        )

    return lines


func set_interactive_runtime(enabled: bool) -> void:
    set_process(enabled)
    set_process_unhandled_input(enabled)


func mission_record_for_id(mission_id: String = "") -> Dictionary:
    if ruleset_database == null:
        return {}

    var resolved_id: String = mission_id
    if resolved_id.is_empty():
        resolved_id = current_mission_id
    return ruleset_database.find_mission(resolved_id)


func mission_frame_for_id(mission_id: String = "") -> String:
    var mission_record: Dictionary = mission_record_for_id(mission_id)
    if mission_record.is_empty():
        return mission_id
    return _mission_frame_text(mission_record, mission_id if not mission_id.is_empty() else current_mission_id)


func mission_synopsis_for_id(mission_id: String = "") -> String:
    var mission_record: Dictionary = mission_record_for_id(mission_id)
    return _mission_synopsis_text(mission_record)


func build_ui_snapshot() -> Dictionary:
    var summary: Dictionary = ruleset_database.summary()
    var ruleset_summary: Dictionary = ruleset_database.ruleset_summary()
    var active_record: Dictionary = mission_record_for_id()
    var mission_label: String = _mission_label(active_record, current_mission_id)
    var chapter_text: String = _mission_chapter_text(active_record)
    var synopsis_text: String = _mission_synopsis_text(active_record)
    var campaign_record_totals: Dictionary = _campaign_record_totals()
    var campaign_text: String = "Campaign: offline"
    var campaign_summary_lines: Array[String] = []
    var carryover_text: String = ""
    var hunger_text: String = world_state.hunger_status_text()
    if campaign_state != null:
        campaign_text = "Campaign: %d/%d complete | %d unlocked" % [
            campaign_state.completed_count(),
            campaign_state.mission_count(),
            campaign_state.unlocked_missions.size()
        ]
        if campaign_state.campaign_complete():
            campaign_text += " | COMPLETE"
        campaign_summary_lines.append(campaign_text)
        campaign_summary_lines.append("Record: %d wins | %d losses" % [
            int(campaign_record_totals.get("wins", 0)),
            int(campaign_record_totals.get("losses", 0))
        ])
        var best_campaign_time: float = float(campaign_record_totals.get("best_time", -1.0))
        if best_campaign_time >= 0.0:
            campaign_summary_lines.append("Best mission clear: %.1fs" % best_campaign_time)
        if campaign_state.carried_tech_count() > 0 or campaign_state.carryover_clan_count_by_stance("allied") > 0 or campaign_state.carryover_clan_count_by_stance("hostile") > 0:
            carryover_text = "Carryover: %d techs | %d allied clans | %d hostile clans" % [
                campaign_state.carried_tech_count(),
                campaign_state.carryover_clan_count_by_stance("allied"),
                campaign_state.carryover_clan_count_by_stance("hostile")
            ]
            campaign_summary_lines.append(carryover_text)
    else:
        campaign_summary_lines.append(campaign_text)

    var objective_lines: Array[String] = mission_state.objective_lines()
    if objective_lines.is_empty():
        for objective_text in mission_state.objectives:
            objective_lines.append("[ ] %s" % objective_text)
    if objective_lines.is_empty():
        objective_lines.append("[ ] No objectives loaded")

    var food_target: int = int(map_state.storehouse_goal.get("food", 0))
    var stone_target: int = int(map_state.storehouse_goal.get("stone", 0))
    var goal_text: String = ""
    if food_target > 0 or stone_target > 0:
        goal_text = "Stockpile: %d/%d food | %d/%d stone | Allies: %d" % [
            int(world_state.resources.get("food", 0)),
            food_target,
            int(world_state.resources.get("stone", 0)),
            stone_target,
            allied_clans.size()
        ]
    else:
        goal_text = "Pressure: %d enemies | %d pending waves | Allies: %d" % [
            enemy_units.size(),
            pending_enemy_spawns.size(),
            allied_clans.size()
        ]

    var selection_text := "Selection: none"
    if not selected_worker_indices.is_empty() or not selected_combat_indices.is_empty():
        selection_text = "Selection: %s" % _selection_status_text(selected_worker_indices.size(), selected_combat_indices.size())
    elif selected_building_index >= 0 and selected_building_index < buildings.size():
        selection_text = "Selection: %s" % buildings[selected_building_index].name
    elif selected_site_index >= 0 and selected_site_index < construction_sites.size():
        selection_text = "Selection: %s site" % construction_sites[selected_site_index].name

    var context_hint: String = "Context: none"
    var selected_building = _selected_building()
    if selected_building != null:
        context_hint = _context_hint_for_building(selected_building)

    var actor_lines: Array[String] = []
    for index in range(mini(3, workers.size())):
        var worker = workers[index]
        actor_lines.append("%s: %s" % [worker.name, worker.status_text()])

    for index in range(mini(3, combat_units.size())):
        var combat_unit = combat_units[index]
        actor_lines.append("%s: %s" % [combat_unit.name, combat_unit.status_text()])

    var result_payload: Dictionary = {
        "visible": false,
        "status": str(world_state.mission_status),
        "title": "",
        "body": "",
        "next_mission_id": "",
        "next_mission_title": "",
        "next_mission_label": "",
        "next_chapter_text": ""
    }
    if world_state.mission_status == "victory":
        var next_mission_id: String = ""
        var campaign_complete: bool = false
        var next_record: Dictionary = {}
        if campaign_state != null:
            next_mission_id = campaign_state.next_mission_id_after(current_mission_id)
            if not next_mission_id.is_empty() and not campaign_state.is_mission_unlocked(next_mission_id):
                next_mission_id = ""
            campaign_complete = campaign_state.campaign_complete()
            if not next_mission_id.is_empty():
                next_record = mission_record_for_id(next_mission_id)
        result_payload["visible"] = true
        result_payload["title"] = "Campaign Complete" if campaign_complete else "Mission Complete"
        result_payload["body"] = (
            "The clan secured the Rising Lands after %d completed missions.\nRecord: %d wins | %d losses."
            % [
                campaign_state.completed_count(),
                int(campaign_record_totals.get("wins", 0)),
                int(campaign_record_totals.get("losses", 0))
            ]
            if campaign_complete
            else "%s secured in %d ticks.\nNext deployment: %s." % [
                _mission_frame_text(active_record, current_mission_id),
                world_state.tick_count,
                _mission_frame_text(next_record, next_mission_id) if not next_mission_id.is_empty() else "Return to the campaign shell"
            ]
        )
        result_payload["next_mission_id"] = next_mission_id
        result_payload["next_mission_title"] = str(next_record.get("title", next_mission_id))
        result_payload["next_mission_label"] = _mission_label(next_record, next_mission_id)
        result_payload["next_chapter_text"] = _mission_chapter_text(next_record)
    elif world_state.mission_status == "defeat":
        result_payload["visible"] = true
        result_payload["title"] = "Mission Failed"
        result_payload["body"] = (
            "%s starved after the clan exhausted its food stores. Retry the mission or regroup in the campaign shell."
            % _mission_frame_text(active_record, current_mission_id)
            if world_state.starvation_failed()
            else "%s broke under pressure. Retry the mission or regroup in the campaign shell." % _mission_frame_text(active_record, current_mission_id)
        )

    return {
        "ruleset_id": ruleset_id,
        "ruleset_name": str(ruleset_summary.get("display_name", ruleset_id)),
        "ruleset_summary": ruleset_summary.duplicate(true),
        "campaign_text": campaign_text,
        "campaign_summary_lines": campaign_summary_lines,
        "carryover_text": carryover_text,
        "objective_lines": objective_lines,
        "goal_text": goal_text,
        "selection_text": selection_text,
        "context_hint": context_hint,
        "status_text": simulation_status,
        "alert_lines": alert_log.duplicate(true),
        "actor_lines": actor_lines,
        "selection_detail_lines": _selection_detail_lines(),
        "selected_building_actions": selected_building_actions(),
        "mission_title": mission_state.title,
        "mission_label": mission_label,
        "chapter_text": chapter_text,
        "mission_synopsis": synopsis_text,
        "mission_state": world_state.mission_status,
        "current_mission_id": current_mission_id,
        "active_save_slot_id": active_save_slot_id,
        "build_palette_label": _build_palette_label(),
        "forces_text": "%d workers | %d units | %d enemies | Pop %d/%d" % [
            workers.size(),
            combat_units.size(),
            enemy_units.size(),
            world_state.population_count,
            world_state.housing_capacity
        ],
        "hunger_text": hunger_text,
        "research_text": "%d unlocked" % world_state.unlocked_techs.size(),
        "tick_text": str(world_state.tick_count),
        "summary": summary.duplicate(true),
        "result": result_payload.duplicate(true),
        "resources": {
            "food": int(world_state.resources.get("food", 0)),
            "stone": int(world_state.resources.get("stone", 0)),
            "parts": int(world_state.resources.get("parts", 0)),
            "tech": int(world_state.resources.get("tech", 0)),
            "allies": allied_clans.size(),
            "population": world_state.population_count,
            "housing": world_state.housing_capacity,
            "starvation_strikes": world_state.starvation_strikes
        }
    }


func _refresh_debug_text() -> void:
    if debug_label == null:
        return

    var snapshot: Dictionary = build_ui_snapshot()
    var summary: Dictionary = snapshot.get("summary", {})
    var alert_lines: Array[String] = []
    for alert_entry in snapshot.get("alert_lines", []):
        alert_lines.append("Alert: %s" % str(alert_entry))

    debug_label.text = "\n".join([
        "Rising Lands 2",
        "Godot campaign UX slice",
        "Controls: LMB click/select | drag box-select | RMB assign/move | 1-9, M, 0, -, = build palette",
        "Systems: Q/W/E/R/T/Y context | F5 save | F9 load",
        "Ruleset: %s (%s)" % [str(snapshot.get("ruleset_name", "")), str(snapshot.get("ruleset_id", ""))],
        str(snapshot.get("build_palette_label", "")),
        "Mission: %s" % str(snapshot.get("mission_title", "")),
        str(snapshot.get("campaign_text", "")),
        str(snapshot.get("carryover_text", "")),
        "Active Mission: %s | Save Slot: %s" % [
            str(snapshot.get("current_mission_id", "")),
            str(snapshot.get("active_save_slot_id", ""))
        ],
        "Objectives:",
    ] + snapshot.get("objective_lines", []) + [
        str(snapshot.get("goal_text", "")),
        str(snapshot.get("selection_text", "")),
        str(snapshot.get("context_hint", "")),
        "Status: %s" % str(snapshot.get("status_text", "")),
    ] + alert_lines + [
        "Mission State: %s" % str(snapshot.get("mission_state", "")),
        "Food: %s" % str(snapshot.get("resources", {}).get("food", 0)),
        "Stone: %s" % str(snapshot.get("resources", {}).get("stone", 0)),
        "Parts: %s" % str(snapshot.get("resources", {}).get("parts", 0)),
        "Tech: %s" % str(snapshot.get("resources", {}).get("tech", 0)),
        str(snapshot.get("hunger_text", "")),
        "Research: %s" % str(snapshot.get("research_text", "")),
        "Forces: %s" % str(snapshot.get("forces_text", "")),
        "Tick: %s" % str(snapshot.get("tick_text", "")),
        "%s data: %d units, %d buildings, %d missions" % [
            str(snapshot.get("ruleset_name", "Ruleset")),
            int(summary.get("units", 0)),
            int(summary.get("buildings", 0)),
            int(summary.get("missions", 0))
        ]
    ] + snapshot.get("selection_detail_lines", []) + snapshot.get("actor_lines", []))


func _ensure_debug_label() -> void:
    if debug_label != null:
        return

    debug_label = Label.new()
    debug_label.position = Vector2(24, 20)
    add_child(debug_label)


func _serialize_collection(items: Array) -> Array:
    var payload: Array = []
    for item in items:
        payload.append(item.serialize())
    return payload


func _player_owned_buildings() -> Array:
    var player_buildings: Array = []
    for building in buildings:
        if building == null or not building.is_alive():
            continue
        if building.team != "player":
            continue
        player_buildings.append(building)
    return player_buildings


func _player_population_count() -> int:
    var population: int = 0
    for worker in workers:
        if worker.is_alive():
            population += 1

    for combat_unit in combat_units:
        if combat_unit.team == "player" and combat_unit.is_alive():
            population += 1

    return population


func _player_housing_capacity() -> int:
    var housing: int = 0
    for building in buildings:
        if building.team != "player" or not building.is_alive():
            continue
        housing += int(building.housing)
    return housing


func _push_alert(message: String) -> void:
    simulation_status = message
    alert_log.append(message)
    while alert_log.size() > MAX_ALERT_LOG:
        alert_log.remove_at(0)
