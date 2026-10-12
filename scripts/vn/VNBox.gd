extends Control
class_name VNBox

signal finished
signal choice_selected(choice: DialogueChoice)
signal meta_clicked(url_id: String)
signal line_shown(line: DialogueLine)

const CHARS_PER_SEC := 45.0

var _queue: Array[DialogueLine] = []
var _current: DialogueLine = null
var _typing := false
var _char_accum := 0.0
var _waiting_choice := false
var _hovered_url = null
var _last_meta_frame := -1

var _dialogue_panel: PanelContainer
var _nameplate: Label
var _text_label: RichTextLabel
var _choice_container: VBoxContainer
var _hint: Label
var _portrait_panel: Panel
var _portrait_initial: Label
var _tactic_panel: PanelContainer
var _tactic_title: Label
var _tactic_container: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	set_process(true)


func play(lines: Array) -> void:
	_queue.clear()
	for line in lines:
		_queue.append(line)
	_current = null
	_typing = false
	_waiting_choice = false
	_hide_choices()
	_text_label.text = ""
	_nameplate.text = ""
	_hint.text = ""
	_next()


func refresh() -> void:
	_update_hint()


func _next() -> void:
	if _queue.is_empty():
		_current = null
		_typing = false
		_waiting_choice = false
		_text_label.text = ""
		_nameplate.text = ""
		_hide_choices()
		finished.emit()
		return

	_current = _queue.pop_front()
	if _current.choices.size() > 0:
		_show_choices()
		return
	_display_line(_current)


func _display_line(line: DialogueLine) -> void:
	_nameplate.text = line.speaker
	if line.internal_thought:
		_nameplate.text = line.speaker + " · про себя"
	_nameplate.modulate = _speaker_color(line.speaker)
	_update_portrait(line)
	_text_label.add_theme_color_override("default_color", Color(0.72, 0.82, 1.0) if line.internal_thought else Color(0.92, 0.9, 0.86))
	_text_label.text = line.text
	_text_label.visible_characters = 0
	_char_accum = 0.0
	_typing = true
	_waiting_choice = false
	_hide_choices()
	line_shown.emit(line)


func _process(delta: float) -> void:
	if _typing:
		_char_accum += delta * CHARS_PER_SEC
		var total := _text_label.get_total_character_count()
		_text_label.visible_characters = int(_char_accum)
		if total > 0 and int(_char_accum) >= total:
			_complete_typing()
	else:
		_update_hint()


func _complete_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_update_hint()


func _advance() -> void:
	if Engine.get_process_frames() == _last_meta_frame:
		return
	if _waiting_choice:
		return
	if _typing:
		_complete_typing()
		return
	if _current != null and _current.required_url != "" and not GameManager.clicked_urls.has(_current.required_url):
		_update_hint()
		return
	_next()


func _show_choices() -> void:
	_typing = false
	_text_label.text = ""
	_nameplate.text = ""
	var available := _available_choices()
	if available.is_empty():
		_next()
		return
	_waiting_choice = true
	_hide_choices(false)
	for choice in available:
		var button := Button.new()
		button.text = choice.label
		button.focus_mode = Control.FOCUS_NONE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_select.bind(choice))
		if choice.kind == "TACTIC":
			_tactic_container.add_child(button)
		else:
			_choice_container.add_child(button)
	var has_tactic := false
	for choice in available:
		if choice.kind == "TACTIC":
			has_tactic = true
	_tactic_panel.visible = has_tactic
	_tactic_title.text = "Тактики" if has_tactic else ""
	_update_hint()


func _available_choices() -> Array:
	var result: Array = []
	if _current == null:
		return result
	for choice in _current.choices:
		if choice.kind == "TACTIC":
			if GameManager.unlocked_tactics.has(choice.tactic_id):
				result.append(choice)
		else:
			result.append(choice)
	return result


func _select(choice: DialogueChoice) -> void:
	_waiting_choice = false
	_hide_choices()
	GameManager.apply_choice(choice)
	choice_selected.emit(choice)
	var response: Array = choice.response
	for i in range(response.size() - 1, -1, -1):
		_queue.insert(0, response[i])
	_next()


func _hide_choices(clear := true) -> void:
	if clear:
		_clear_container(_choice_container)
		_clear_container(_tactic_container)
	_tactic_panel.visible = false


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _update_hint() -> void:
	if _waiting_choice:
		_hint.text = "Выберите, как действовать"
		return
	if _typing:
		_hint.text = ""
		return
	if _current == null:
		_hint.text = ""
		return
	if _current.required_url != "" and not GameManager.clicked_urls.has(_current.required_url):
		_hint.text = "Закрепите ключевую фразу в тексте, чтобы продолжить"
	else:
		_hint.text = "Пробел / клик — далее"


func _update_portrait(line: DialogueLine) -> void:
	_portrait_panel.visible = line.speaker != ""
	var color := _speaker_color(line.speaker)
	if line.internal_thought:
		color = color.darkened(0.25)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_portrait_panel.add_theme_stylebox_override("panel", style)
	_portrait_initial.text = line.speaker.substr(0, 1).to_upper()


func _speaker_color(speaker: String) -> Color:
	match speaker:
		"Анна":
			return Color(0.52, 0.32, 0.48)
		"Уэллер":
			return Color(0.3, 0.42, 0.58)
		"Сколфилд":
			return Color(0.45, 0.42, 0.38)
		_:
			return Color(0.3, 0.3, 0.32)


func _on_meta(meta) -> void:
	_last_meta_frame = Engine.get_process_frames()
	meta_clicked.emit(str(meta))
	_update_hint()


func _on_hover_started(meta) -> void:
	_hovered_url = meta


func _on_hover_ended(meta) -> void:
	if _hovered_url == meta:
		_hovered_url = null


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _hovered_url != null:
			return
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		_advance()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_rect(_dialogue_panel, 0, 1, 1, 1, 60, -270, -60, -30)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.07, 0.9)
	panel_style.border_color = Color(0.3, 0.28, 0.25, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(18)
	_dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_dialogue_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 8)
	_dialogue_panel.add_child(vbox)

	_nameplate = Label.new()
	_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_nameplate)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_text_label.custom_minimum_size = Vector2(0, 120)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", 20)
	_text_label.meta_clicked.connect(_on_meta)
	_text_label.meta_hover_started.connect(_on_hover_started)
	_text_label.meta_hover_ended.connect(_on_hover_ended)
	vbox.add_child(_text_label)

	_choice_container = VBoxContainer.new()
	_choice_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_choice_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_choice_container)

	_hint = Label.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.modulate = Color(0.7, 0.7, 0.7, 0.85)
	_hint.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_hint)

	_portrait_panel = Panel.new()
	_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_portrait_panel, 0, 1, 0, 1, 80, -540, 280, -300)
	add_child(_portrait_panel)

	_portrait_initial = Label.new()
	_portrait_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_initial.add_theme_font_size_override("font_size", 72)
	_portrait_initial.modulate = Color(1, 1, 1, 0.85)
	_portrait_panel.add_child(_portrait_initial)

	_tactic_panel = PanelContainer.new()
	_tactic_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_tactic_panel.visible = false
	_set_rect(_tactic_panel, 1, 0, 1, 0, -360, 120, -40, 120)
	var tactic_style := StyleBoxFlat.new()
	tactic_style.bg_color = Color(0.06, 0.06, 0.09, 0.92)
	tactic_style.border_color = Color(0.55, 0.45, 0.2, 0.9)
	tactic_style.set_border_width_all(2)
	tactic_style.set_corner_radius_all(6)
	tactic_style.set_content_margin_all(14)
	_tactic_panel.add_theme_stylebox_override("panel", tactic_style)
	add_child(_tactic_panel)

	var tactic_vbox := VBoxContainer.new()
	tactic_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	tactic_vbox.add_theme_constant_override("separation", 8)
	_tactic_panel.add_child(tactic_vbox)

	_tactic_title = Label.new()
	_tactic_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tactic_title.add_theme_font_size_override("font_size", 18)
	_tactic_title.modulate = Color(0.9, 0.78, 0.45)
	tactic_vbox.add_child(_tactic_title)

	_tactic_container = VBoxContainer.new()
	_tactic_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_tactic_container.add_theme_constant_override("separation", 6)
	tactic_vbox.add_child(_tactic_container)

	gui_input.connect(_on_gui_input)


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom
