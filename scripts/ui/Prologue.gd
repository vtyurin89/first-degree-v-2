extends Control

const CPS := 42.0

var _text: RichTextLabel
var _hint: Label
var _lines: Array
var _index := -1
var _typing := false
var _waiting := false
var _auto := false
var _accum := 0.0
var _timer := 0.0
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var background := ColorRect.new()
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.focus_mode = Control.FOCUS_NONE
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.anchor_left = 0.12
	_text.anchor_right = 0.88
	_text.anchor_top = 0.28
	_text.anchor_bottom = 0.72
	_text.theme_type_variation = UITheme.NARRATION
	add_child(_text)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.theme_type_variation = UITheme.HINT
	_hint.modulate = Color(0.6, 0.6, 0.6, 0.8)
	_hint.anchor_left = 0.0
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_top = -70
	_hint.offset_bottom = -40
	add_child(_hint)

	_lines = Case1Scolfield.get_prologue()
	_next_line()
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_advance()


func _process(delta: float) -> void:
	if _typing:
		_accum += delta * CPS
		var total := _text.get_total_character_count()
		_text.visible_characters = int(_accum)
		if total > 0 and int(_accum) >= total:
			_complete_line()
	elif _auto:
		_timer -= delta
		if _timer <= 0.0:
			_auto = false
			_next_line()


func _next_line() -> void:
	_index += 1
	if _index >= _lines.size():
		_end()
		return
	var entry: Dictionary = _lines[_index]
	var body: String = entry.get("text", "")
	if body == "":
		_text.text = ""
		_typing = false
		_waiting = false
		_auto = true
		_timer = entry.get("pause", 1.0)
		_hint.text = ""
		return
	_text.text = body
	_text.add_theme_color_override("default_color", Color(0.72, 0.82, 1.0) if entry.get("internal", false) else Color(0.92, 0.9, 0.86))
	_text.visible_characters = 0
	_accum = 0.0
	_typing = true
	_waiting = false
	_auto = false
	_hint.text = ""


func _complete_line() -> void:
	_typing = false
	_waiting = true
	_text.visible_characters = -1
	_hint.text = "Пробел / клик — далее"


func _end() -> void:
	if _done:
		return
	_done = true
	_hint.text = ""
	GameManager.change_scene(GameManager.SCENE_OFFICE, 1.0)


func _on_advance() -> void:
	if _done:
		return
	if _typing:
		_complete_line()
	elif _waiting:
		_next_line()


func _unhandled_input(event: InputEvent) -> void:
	var advance := event.is_action_pressed("advance")
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if advance or clicked:
		_on_advance()
		get_viewport().set_input_as_handled()
