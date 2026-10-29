extends Node

signal skip_prologue_changed(value: bool)

const SETTINGS_PATH := "user://settings.cfg"

var skip_prologue := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		skip_prologue = bool(config.get_value("gameplay", "skip_prologue", false))


func set_skip_prologue(value: bool) -> void:
	if skip_prologue == value:
		return
	skip_prologue = value
	save_settings()
	skip_prologue_changed.emit(skip_prologue)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("gameplay", "skip_prologue", skip_prologue)
	config.save(SETTINGS_PATH)
