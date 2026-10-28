extends Node

var _theme: Theme


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme = UITheme.build_theme()
	get_tree().root.theme = _theme


func get_theme() -> Theme:
	return _theme
