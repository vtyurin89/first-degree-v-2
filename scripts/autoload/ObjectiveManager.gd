extends Node

signal objective_status_changed(id: String, old_status: int, new_status: int)
signal objective_activated(id: String)
signal objective_completed(id: String)
signal objective_failed(id: String)
signal objectives_reset()

enum Status { HIDDEN, ACTIVE, COMPLETED, FAILED }
enum Category { MAIN, INVESTIGATION, CHARACTER }

const DEFINITIONS := {
	"take_case": {
		"text_key": "OBJ_TAKE_CASE_FILE",
		"category": Category.MAIN,
		"weight": 10,
		"optional": false,
		"initial": Status.ACTIVE,
		"exclusive_with": [],
	},
	"study_evidence": {
		"text_key": "OBJ_STUDY_EVIDENCE",
		"category": Category.INVESTIGATION,
		"weight": 20,
		"optional": true,
		"initial": Status.ACTIVE,
		"exclusive_with": [],
	},
	"dont_die": {
		"text_key": "OBJ_DONT_DIE",
		"category": Category.CHARACTER,
		"weight": 90,
		"optional": true,
		"initial": Status.ACTIVE,
		"exclusive_with": [],
	},
	"study_911_transcript": {
		"text_key": "OBJ_STUDY_911",
		"category": Category.INVESTIGATION,
		"weight": 30,
		"optional": true,
		"initial": Status.HIDDEN,
		"exclusive_with": [],
	},
	"interrogate_box_1": {
		"text_key": "OBJ_INTERROGATE_BOX_1",
		"category": Category.MAIN,
		"weight": 40,
		"optional": false,
		"initial": Status.HIDDEN,
		"exclusive_with": ["interrogate_box_2"],
	},
	"interrogate_box_2": {
		"text_key": "OBJ_INTERROGATE_BOX_2",
		"category": Category.MAIN,
		"weight": 41,
		"optional": false,
		"initial": Status.HIDDEN,
		"exclusive_with": ["interrogate_box_1"],
	},
}

var _statuses: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_to_defaults(false)


func reset_to_defaults(emit_signal := true) -> void:
	_statuses.clear()
	for id in DEFINITIONS.keys():
		_statuses[id] = int(DEFINITIONS[id].get("initial", Status.HIDDEN))
	if emit_signal:
		objectives_reset.emit()


func set_status(id: String, status: int) -> bool:
	if not DEFINITIONS.has(id):
		push_error("[ObjectiveManager] Неизвестная задача: %s" % id)
		return false
	if status < Status.HIDDEN or status > Status.FAILED:
		return false
	return _change_status(id, status, true)


func activate_objective(id: String) -> bool:
	return set_status(id, Status.ACTIVE)


func complete_objective(id: String) -> bool:
	return set_status(id, Status.COMPLETED)


func fail_objective(id: String) -> bool:
	return set_status(id, Status.FAILED)


func get_status(id: String) -> int:
	return int(_statuses.get(id, Status.HIDDEN))


func is_active(id: String) -> bool:
	return get_status(id) == Status.ACTIVE


func is_completed(id: String) -> bool:
	return get_status(id) == Status.COMPLETED


func is_failed(id: String) -> bool:
	return get_status(id) == Status.FAILED


func is_visible(id: String) -> bool:
	return get_status(id) != Status.HIDDEN


func get_definition(id: String) -> Dictionary:
	if not DEFINITIONS.has(id):
		return {}
	return DEFINITIONS[id]


func get_visible_objectives() -> Array:
	var result: Array = []
	for id in DEFINITIONS.keys():
		var status := get_status(id)
		if status == Status.HIDDEN:
			continue
		var definition: Dictionary = DEFINITIONS[id]
		result.append({
			"id": id,
			"text_key": String(definition.get("text_key", "")),
			"category": int(definition.get("category", Category.MAIN)),
			"weight": int(definition.get("weight", 0)),
			"optional": bool(definition.get("optional", false)),
			"status": status,
		})
	result.sort_custom(func(a, b):
		var weight_a := int(a.get("weight", 0))
		var weight_b := int(b.get("weight", 0))
		if weight_a == weight_b:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return weight_a < weight_b
	)
	return result


func snapshot_statuses() -> Dictionary:
	return _statuses.duplicate()


func restore_statuses(data: Dictionary) -> void:
	reset_to_defaults(false)
	for id in DEFINITIONS.keys():
		if data.has(id):
			var status := int(data[id])
			if status >= Status.HIDDEN and status <= Status.FAILED:
				_statuses[id] = status
	objectives_reset.emit()


func _change_status(id: String, new_status: int, process_exclusive: bool) -> bool:
	var old_status := get_status(id)
	if old_status == new_status:
		return false
	_statuses[id] = new_status
	objective_status_changed.emit(id, old_status, new_status)
	match new_status:
		Status.ACTIVE:
			objective_activated.emit(id)
		Status.COMPLETED:
			objective_completed.emit(id)
			if process_exclusive:
				_cancel_exclusive(id)
		Status.FAILED:
			objective_failed.emit(id)
	return true


func _cancel_exclusive(id: String) -> void:
	var definition: Dictionary = DEFINITIONS.get(id, {})
	for other_id in definition.get("exclusive_with", []):
		var other_status := get_status(String(other_id))
		if other_status == Status.ACTIVE or other_status == Status.HIDDEN:
			_change_status(String(other_id), Status.FAILED, false)
