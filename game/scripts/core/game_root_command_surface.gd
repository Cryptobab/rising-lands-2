class_name GameRootCommandSurface
extends RefCounted

const DRUID_SPELL_ACTIONS := [
    {"slot": 1, "key": "Q", "id": "armour"},
    {"slot": 2, "key": "W", "id": "petrification"},
    {"slot": 3, "key": "E", "id": "nova"},
    {"slot": 4, "key": "R", "id": "vision"},
]

const BUILDING_ACTIONS_BY_ID := {
    "culture": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "farmer", "label": "farmer"},
        {"slot": 2, "key": "W", "kind": "train", "id": "builder", "label": "builder"},
        {"slot": 3, "key": "E", "kind": "train", "id": "mechanic", "label": "mechanic"},
        {"slot": 4, "key": "R", "kind": "train", "id": "settler", "label": "settler"},
        {"slot": 5, "key": "T", "kind": "train", "id": "messenger", "label": "messenger"},
    ],
    "barracks": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "swordsman", "label": "swordsman"},
        {"slot": 2, "key": "W", "kind": "train", "id": "captain", "label": "captain"},
        {"slot": 3, "key": "E", "kind": "train", "id": "archer", "label": "archer"},
        {"slot": 4, "key": "R", "kind": "train", "id": "scorcher", "label": "scorcher"},
    ],
    "sanctuary": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "druid", "label": "druid"},
    ],
    "temple": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "druid", "label": "druid"},
    ],
    "workshop": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "stomper", "label": "stomper"},
    ],
    "garage": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "speeder", "label": "speeder"},
        {"slot": 2, "key": "W", "kind": "train", "id": "boomer", "label": "boomer"},
        {"slot": 3, "key": "E", "kind": "train", "id": "reaper", "label": "reaper"},
        {"slot": 4, "key": "R", "kind": "train", "id": "bomber", "label": "bomber"},
        {"slot": 5, "key": "T", "kind": "train", "id": "hellfire", "label": "hellfire"},
    ],
    "hangar": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "heliped", "label": "heliped"},
        {"slot": 2, "key": "W", "kind": "train", "id": "balloon", "label": "balloon"},
    ],
    "heliport": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "heliped", "label": "heliped"},
        {"slot": 2, "key": "W", "kind": "train", "id": "balloon", "label": "balloon"},
    ],
    "market": [
        {"slot": 1, "key": "Q", "kind": "train", "id": "messenger", "label": "messenger"},
    ],
    "laboratory": [
        {"slot": 1, "key": "Q", "kind": "research", "id": "agriculture", "label": "agriculture"},
        {"slot": 2, "key": "W", "kind": "research", "id": "military", "label": "military"},
        {"slot": 3, "key": "E", "kind": "research", "id": "civil_engineering", "label": "civil"},
        {"slot": 4, "key": "R", "kind": "research", "id": "religious", "label": "religious"},
    ],
    "library": [
        {"slot": 1, "key": "Q", "kind": "research", "id": "agriculture", "label": "agriculture"},
        {"slot": 2, "key": "W", "kind": "research", "id": "military", "label": "military"},
        {"slot": 3, "key": "E", "kind": "research", "id": "civil_engineering", "label": "civil"},
        {"slot": 4, "key": "R", "kind": "research", "id": "religious", "label": "religious"},
    ],
}


func build_selection_snapshot(game_root) -> Dictionary:
    return {
        "selection_text": _selection_text(game_root),
        "context_hint": _context_hint(game_root),
        "selection_detail_lines": selection_detail_lines(game_root),
        "actions": selected_actions(game_root)
    }


func selected_actions(game_root) -> Array:
    var selected_unit = game_root._selected_combat_unit()
    if game_root.selected_combat_indices.size() == 1 and selected_unit != null:
        var combat_actions: Array = _combat_unit_actions(game_root, selected_unit)
        if not combat_actions.is_empty():
            return combat_actions.duplicate(true)

    var building = game_root._selected_building()
    if building == null:
        return []
    return _building_actions(building.building_id).duplicate(true)


func invoke_selected_action(game_root, slot: int) -> bool:
    for action in selected_actions(game_root):
        if int(action.get("slot", 0)) != slot:
            continue

        var action_kind: String = str(action.get("kind", ""))
        var action_id: String = str(action.get("id", ""))
        match action_kind:
            "spell":
                return game_root.cast_spell_for_selected_unit(action_id)
            "tame":
                return game_root.tame_creature_for_selected_unit()
            "transport_unload":
                return game_root.unload_selected_transport()
            "train":
                return game_root.queue_training_for_building(game_root.selected_building_index, action_id)
            "research":
                return game_root.queue_research_for_building(game_root.selected_building_index, action_id)
            _:
                return false
    return false


func selection_detail_lines(game_root) -> Array[String]:
    var lines: Array[String] = []
    var selected_workers: Array = game_root._selected_workers()
    var selected_combat: Array = game_root._selected_combat_units()
    var selected_total: int = selected_workers.size() + selected_combat.size()

    if selected_total > 1:
        lines.append("Selected Units: %d" % selected_total)
        if not selected_workers.is_empty():
            lines.append("Workers: %d | Builders: %d" % [selected_workers.size(), _count_selected_builders(game_root)])
        if not selected_combat.is_empty():
            lines.append("Combat: %d | %s" % [selected_combat.size(), _selected_role_summary(selected_combat)])
        return lines

    var selected_worker = game_root._selected_worker()
    if selected_worker != null:
        lines.append(
            "Selected Worker: %s | hp %d/%d | %s"
            % [selected_worker.name, int(ceil(selected_worker.health)), int(ceil(selected_worker.max_health)), selected_worker.status_text()]
        )
        return lines

    var selected_combat_unit = game_root._selected_combat_unit()
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

    var selected_building = game_root._selected_building()
    if selected_building != null:
        lines.append(
            "Selected Building: %s | hp %d/%d"
            % [selected_building.name, int(ceil(selected_building.health)), int(ceil(selected_building.max_health))]
        )
        lines.append("Queue: %s" % selected_building.queue_label())
        if selected_building.can_attack():
            lines.append("Defense: %dm range | %s" % [int(round(selected_building.attack_range)), selected_building.last_action])
        return lines

    if game_root.selected_site_index >= 0 and game_root.selected_site_index < game_root.construction_sites.size():
        var selected_site = game_root.construction_sites[game_root.selected_site_index]
        lines.append(
            "Selected Site: %s | build %d%%"
            % [selected_site.name, int(round(selected_site.build_ratio() * 100.0))]
        )

    return lines


func _selection_text(game_root) -> String:
    if not game_root.selected_worker_indices.is_empty() or not game_root.selected_combat_indices.is_empty():
        return "Selection: %s" % game_root._selection_status_text(
            game_root.selected_worker_indices.size(),
            game_root.selected_combat_indices.size()
        )
    if game_root.selected_building_index >= 0 and game_root.selected_building_index < game_root.buildings.size():
        return "Selection: %s" % game_root.buildings[game_root.selected_building_index].name
    if game_root.selected_site_index >= 0 and game_root.selected_site_index < game_root.construction_sites.size():
        return "Selection: %s site" % game_root.construction_sites[game_root.selected_site_index].name
    return "Selection: none"


func _context_hint(game_root) -> String:
    var selected_building = game_root._selected_building()
    if selected_building == null:
        return "Context: none"

    var actions: Array = _building_actions(selected_building.building_id)
    if actions.is_empty():
        return "Context: %s" % selected_building.queue_label()

    var hints: Array[String] = []
    for action in actions:
        hints.append("%s %s" % [str(action.get("key", "")), str(action.get("label", action.get("id", "")))])
    return "Context: %s" % " | ".join(hints)


func _combat_unit_actions(game_root, combat_unit) -> Array:
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

    var actions: Array = []
    for action in DRUID_SPELL_ACTIONS:
        var spell_id: String = str(action.get("id", ""))
        var spell_record: Dictionary = game_root.ruleset_database.find_spell(spell_id)
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
    return BUILDING_ACTIONS_BY_ID.get(building_id, []).duplicate(true)


func _count_selected_builders(game_root) -> int:
    var builder_count: int = 0
    for worker in game_root._selected_workers():
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
