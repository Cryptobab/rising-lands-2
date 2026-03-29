class_name MissionState
extends RefCounted

var mission_id: String = ""
var title: String = ""
var chapter: String = ""
var objectives: Array[String] = []
var briefing_source: String = ""
var runtime_objectives: Array = []


func load_stub_mission(id: String) -> void:
    mission_id = id
    title = "Mission 1 - The New World"
    chapter = "Bootstrap"
    objectives = [
        "Establish a food economy",
        "Keep the clan alive",
        "Unlock the first military path"
    ]
    briefing_source = "WORLD/MONDE01.TXT"
    runtime_objectives = []


func load_from_record(record: Dictionary) -> void:
    mission_id = str(record.get("id", ""))
    title = str(record.get("title", ""))
    chapter = str(record.get("chapter", ""))
    briefing_source = str(record.get("source_file", ""))
    objectives.clear()
    runtime_objectives = []

    for objective in record.get("objectives", []):
        objectives.append(str(objective))


func configure_runtime_objectives(payloads: Array) -> void:
    runtime_objectives = []
    for payload in payloads:
        var objective: Dictionary = payload.duplicate(true)
        objective["id"] = str(objective.get("id", "objective_%d" % runtime_objectives.size()))
        objective["label"] = str(objective.get("label", objective.get("id", "Objective")))
        objective["required"] = bool(objective.get("required", true))
        objective["completed"] = false
        objective["progress_current"] = 0
        objective["progress_target"] = int(objective.get("target", 0))
        objective["status_text"] = "pending"
        runtime_objectives.append(objective)


func evaluate(snapshot: Dictionary) -> Array[String]:
    var newly_completed: Array[String] = []
    for index in range(runtime_objectives.size()):
        var objective: Dictionary = runtime_objectives[index]
        var was_completed: bool = bool(objective.get("completed", false))
        var target_value: int = int(objective.get("target", 0))
        var current_value: int = 0
        var completed: bool = false
        var status_text: String = "pending"
        var objective_type: String = str(objective.get("type", ""))

        match objective_type:
            "stockpile":
                current_value = int(snapshot.get("resources", {}).get(str(objective.get("resource", "")), 0))
                completed = current_value >= target_value
            "build":
                current_value = int(snapshot.get("building_counts", {}).get(str(objective.get("building_id", "")), 0))
                completed = current_value >= target_value
            "tech_count":
                current_value = int(snapshot.get("unlocked_tech_count", 0))
                completed = current_value >= target_value
            "research_branch":
                current_value = int(snapshot.get("branch_levels", {}).get(str(objective.get("branch", "")), 0))
                completed = current_value >= target_value
            "survive_until":
                current_value = int(floor(float(snapshot.get("elapsed_time", 0.0))))
                completed = float(snapshot.get("elapsed_time", 0.0)) >= float(target_value)
            "repel_waves":
                current_value = int(snapshot.get("enemy_waves_spawned", 0))
                completed = (
                    current_value >= target_value
                    and int(snapshot.get("enemy_units_alive", 0)) <= 0
                    and int(snapshot.get("pending_enemy_spawns", 0)) <= 0
                )
            _:
                current_value = 0
                completed = false

        if completed:
            status_text = "complete"
        elif current_value > 0:
            status_text = "in progress"

        objective["completed"] = completed
        objective["progress_current"] = current_value
        objective["progress_target"] = target_value
        objective["status_text"] = status_text
        runtime_objectives[index] = objective

        if completed and not was_completed:
            newly_completed.append(str(objective.get("label", objective.get("id", "Objective"))))

    return newly_completed


func required_objectives_complete() -> bool:
    if runtime_objectives.is_empty():
        return false

    for objective in runtime_objectives:
        if bool(objective.get("required", true)) and not bool(objective.get("completed", false)):
            return false
    return true


func objective_completed(objective_id: String) -> bool:
    for objective in runtime_objectives:
        if str(objective.get("id", "")) == objective_id:
            return bool(objective.get("completed", false))
    return false


func objective_lines() -> Array[String]:
    var lines: Array[String] = []
    for objective in runtime_objectives:
        var marker: String = "[ ]"
        if bool(objective.get("completed", false)):
            marker = "[x]"

        var target_value: int = int(objective.get("progress_target", 0))
        var current_value: int = int(objective.get("progress_current", 0))
        var progress_suffix: String = ""
        if target_value > 0:
            progress_suffix = " (%d/%d)" % [mini(current_value, target_value), target_value]
        if not bool(objective.get("required", true)):
            progress_suffix += " optional"

        lines.append("%s %s%s" % [marker, str(objective.get("label", "Objective")), progress_suffix])
    return lines
