extends Node

var chapter_title := ""
var dialogue_active := false
var ink_state_json := ""
var ink_path := ""
var ink_current_tags: Array = []
var ink_current_meta: Dictionary = {}
var ink_current_text := ""
var ink_showing_choices := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func reset_all() -> void:
	chapter_title = ""
	dialogue_active = false
	clear_ink_state()


func snapshot() -> Dictionary:
	return {
		"chapter_title": chapter_title,
		"dialogue_active": dialogue_active,
		"ink_state_json": ink_state_json,
		"ink_path": ink_path,
		"ink_current_tags": ink_current_tags.duplicate(),
		"ink_current_meta": ink_current_meta.duplicate(true),
		"ink_current_text": ink_current_text,
		"ink_showing_choices": ink_showing_choices,
	}


func restore(data: Dictionary) -> void:
	chapter_title = String(data.get("chapter_title", ""))
	dialogue_active = bool(data.get("dialogue_active", false))
	ink_state_json = String(data.get("ink_state_json", ""))
	ink_path = String(data.get("ink_path", ""))
	var ink_tags = data.get("ink_current_tags", [])
	ink_current_tags = ink_tags.duplicate() if ink_tags is Array else []
	var ink_meta = data.get("ink_current_meta", {})
	ink_current_meta = ink_meta.duplicate(true) if ink_meta is Dictionary else {}
	ink_current_text = String(data.get("ink_current_text", ""))
	ink_showing_choices = bool(data.get("ink_showing_choices", false))


func clear_ink_state() -> void:
	ink_state_json = ""
	ink_path = ""
	ink_current_tags = []
	ink_current_meta = {}
	ink_current_text = ""
	ink_showing_choices = false
