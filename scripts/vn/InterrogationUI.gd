extends Control

const CHARS_PER_SEC := 45.0
const SCRIPT_PATH := "res://data/case1_scolfield.json"

var _manager: DialogueManager
var _mode := "idle"
var _typing := false
var _char_accum := 0.0
var _hovered_meta = null
var _last_meta_frame := -1

var _nameplate: Label
var _text_label: RichTextLabel
var _choice_container: VBoxContainer
var _hint: Label
var _back_button: Button
var _status_label: Label
var _chapter_label: Label
var _log_label: Label
var _log_tween: Tween
var _portrait_panel: Panel
var _portrait_initial: Label
var _flash: ColorRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.set_state(GameManager.GameState.INTERROGATION)
	_build_ui()
	_connect_game()
	_setup_manager()


func _setup_manager() -> void:
	_manager = DialogueManager.new()
	_manager.line_ready.connect(_on_line_ready)
	_manager.choices_ready.connect(_on_choices_ready)
	_manager.clue_registered.connect(_on_clue_registered)
	_manager.energy_depleted.connect(_on_energy_depleted)
	_manager.milestone_reached.connect(_on_milestone_reached)
	_manager.dialogue_ended.connect(_on_dialogue_ended)
	if not _manager.load_script(SCRIPT_PATH):
		_mode = "error"
		_refresh_status()
		_log("Сценарий не загрузился. Смотри консоль.")
		return
	_refresh_status()
	_manager.start()
	if not SaveManager.is_loading():
		SaveManager.autosave_checkpoint()


func _process(delta: float) -> void:
	if _typing:
		_char_accum += delta * CHARS_PER_SEC
		var total := _text_label.get_total_character_count()
		_text_label.visible_characters = int(_char_accum)
		if total > 0 and int(_char_accum) >= total:
			_complete_typing()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.04, 0.04, 0.055)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var status_panel := PanelContainer.new()
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(status_panel, 0, 0, 1, 0, 0, 0, 0, 54)
	var status_style := StyleBoxFlat.new()
	status_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	status_style.content_margin_left = 24
	status_style.content_margin_right = 24
	status_style.content_margin_top = 8
	status_style.content_margin_bottom = 8
	status_panel.add_theme_stylebox_override("panel", status_style)
	add_child(status_panel)

	_status_label = Label.new()
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.theme_type_variation = UITheme.STATUS
	status_panel.add_child(_status_label)

	_chapter_label = Label.new()
	_chapter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chapter_label.theme_type_variation = UITheme.CHAPTER
	_chapter_label.modulate = Color(0.85, 0.75, 0.5)
	_set_rect(_chapter_label, 0.5, 0, 1, 0, 0, 64, -24, 92)
	add_child(_chapter_label)

	_back_button = Button.new()
	_back_button.text = "← Назад"
	_back_button.theme_type_variation = UITheme.BUTTON
	_back_button.focus_mode = Control.FOCUS_NONE
	_back_button.visible = false
	_set_rect(_back_button, 0, 0, 0, 0, 24, 64, 140, 100)
	_back_button.pressed.connect(_on_back_pressed)
	add_child(_back_button)

	_log_label = Label.new()
	_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_label.theme_type_variation = UITheme.LOG
	_log_label.modulate = Color(0.95, 0.85, 0.5, 0.0)
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_set_rect(_log_label, 0, 0, 1, 0, 0, 112, 0, 142)
	add_child(_log_label)

	_portrait_panel = Panel.new()
	_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_portrait_panel, 0, 1, 0, 1, 80, -520, 280, -300)
	add_child(_portrait_panel)

	_portrait_initial = Label.new()
	_portrait_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_initial.theme_type_variation = UITheme.PORTRAIT
	_portrait_initial.modulate = Color(1, 1, 1, 0.85)
	_portrait_panel.add_child(_portrait_initial)

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_set_rect(dialogue_panel, 0, 1, 1, 1, 60, -270, -60, -30)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.07, 0.9)
	panel_style.border_color = Color(0.3, 0.28, 0.25, 0.8)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(18)
	dialogue_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(dialogue_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 8)
	dialogue_panel.add_child(vbox)

	_nameplate = Label.new()
	_nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate.theme_type_variation = UITheme.NAME
	vbox.add_child(_nameplate)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.scroll_active = false
	_text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_text_label.custom_minimum_size = Vector2(0, 120)
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.theme_type_variation = UITheme.BODY
	_text_label.meta_clicked.connect(_on_meta_clicked)
	_text_label.meta_hover_started.connect(_on_meta_hover_started)
	_text_label.meta_hover_ended.connect(_on_meta_hover_ended)
	vbox.add_child(_text_label)

	_choice_container = VBoxContainer.new()
	_choice_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_choice_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_choice_container)

	_hint = Label.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.modulate = Color(0.7, 0.7, 0.7, 0.85)
	_hint.theme_type_variation = UITheme.HINT
	vbox.add_child(_hint)

	_flash = ColorRect.new()
	_flash.color = Color(0.95, 0.78, 0.25, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)

	gui_input.connect(_on_gui_input)


func _connect_game() -> void:
	GameManager.energy_changed.connect(_on_int_changed)
	GameManager.pinned_slots_changed.connect(_on_int_changed)
	GameManager.resistance_changed.connect(_on_int_changed)
	GameManager.admissibility_changed.connect(_on_string_changed)
	GameManager.trait_unlocked.connect(_on_string_changed)
	GameManager.tactic_unlocked.connect(_on_string_changed)
	GameManager.clue_registered.connect(_on_string_changed)
	GameManager.flags_changed.connect(_on_string_changed)


func _on_int_changed(_value: int) -> void:
	_refresh_status()


func _on_string_changed(_value: String) -> void:
	_refresh_status()


func _refresh_status() -> void:
	if _status_label == null:
		return
	_status_label.text = "Энергия: %d/%d   |   Улики: %d   |   Черты: %d   |   Тактики: %d   |   Риск адвоката: %d%%   |   Флаги: %d   |   Допустимость: %s" % [
		GameManager.player_energy,
		GameManager.MAX_ENERGY,
		GameManager.registered_clues.size(),
		GameManager.unlocked_traits.size(),
		GameManager.unlocked_tactics.size(),
		GameManager.attorney_resistance,
		GameManager.flags.size(),
		GameManager.admissibility_status,
	]


func _on_line_ready(speaker: String, text: String, metadata: Dictionary) -> void:
	_mode = "line"
	_clear_choices()
	_hide_back()
	_update_chapter(String(metadata.get("chapter", "")))
	var internal := bool(metadata.get("internal", false))
	_nameplate.text = speaker
	if internal:
		_nameplate.text = speaker + " · про себя"
	_nameplate.modulate = _speaker_color(speaker)
	_update_portrait(speaker, internal)
	_text_label.add_theme_color_override("default_color", Color(0.72, 0.82, 1.0) if internal else Color(0.92, 0.9, 0.86))
	_text_label.text = text
	_text_label.visible_characters = 0
	_char_accum = 0.0
	_typing = true
	_hint.text = ""


func _on_choices_ready(available_choices: Array) -> void:
	_mode = "choice"
	_typing = false
	_text_label.text = ""
	_nameplate.text = ""
	_portrait_panel.visible = false
	_clear_choices()
	_hint.text = "Выберите, как действовать"
	_update_chapter(String(_manager.get_current_node().get("chapter", "")))
	for choice in available_choices:
		var button := Button.new()
		button.text = String(choice.get("text", ""))
		button.theme_type_variation = UITheme.BUTTON
		button.focus_mode = Control.FOCUS_NONE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_choice_pressed.bind(String(choice.get("id", ""))))
		_choice_container.add_child(button)
	_refresh_back_button()


func _on_choice_pressed(choice_id: String) -> void:
	_manager.select_choice(choice_id)
	_refresh_status()


func _on_meta_clicked(meta_id: String) -> void:
	_last_meta_frame = Engine.get_process_frames()
	if _manager == null:
		return
	if _manager.is_meta_registered(meta_id):
		_log("Уже зафиксировано.")
		return
	_manager.click_meta(meta_id)
	_refresh_status()


func _on_clue_registered(clue_id: String, remaining_energy: int) -> void:
	_log("Зафиксировано: %s  ·  энергия %d" % [clue_id, remaining_energy])
	_refresh_status()


func _on_energy_depleted() -> void:
	_log("Не хватает сил. Нужно отдышаться.")


func _on_milestone_reached(milestone_index: int) -> void:
	_log("РУБЕЖ ВЗЯТ: %d" % milestone_index)
	_golden_pulse()
	GameManager.play_cue(1046.5, 0.24, -4.0)
	_refresh_status()


func _on_dialogue_ended() -> void:
	_mode = "ended"
	_typing = false
	_hint.text = ""
	_clear_choices()
	_hide_back()
	set_process(false)
	GameManager.change_scene(GameManager.SCENE_EPILOGUE, 1.0)


func _on_back_pressed() -> void:
	if _manager != null and _manager.go_back():
		_refresh_status()


func _advance_or_complete() -> void:
	if _mode != "line":
		return
	if _typing:
		_complete_typing()
		return
	if _manager != null:
		var node: Dictionary = _manager.get_current_node()
		var target := String(node.get("target_confession", ""))
		if target != "" and not _manager.is_meta_registered(target):
			_log("Сначала закрепите признание кликом по подсвеченной фразе.")
			return
	_manager.advance()


func _complete_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_hint.text = "Пробел / клик — далее"


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _hovered_meta != null:
			return
		if Engine.get_process_frames() == _last_meta_frame:
			return
		_advance_or_complete()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("advance"):
		_advance_or_complete()
		get_viewport().set_input_as_handled()


func _on_meta_hover_started(meta) -> void:
	_hovered_meta = meta


func _on_meta_hover_ended(meta) -> void:
	if _hovered_meta == meta:
		_hovered_meta = null


func _update_chapter(chapter: String) -> void:
	if chapter != "":
		_chapter_label.text = chapter


func _refresh_back_button() -> void:
	if _back_button == null or _manager == null:
		return
	_back_button.visible = _mode == "choice" and _manager.can_go_back()


func _hide_back() -> void:
	if _back_button != null:
		_back_button.visible = false


func _clear_choices() -> void:
	for child in _choice_container.get_children():
		_choice_container.remove_child(child)
		child.queue_free()


func _update_portrait(speaker: String, internal: bool) -> void:
	_portrait_panel.visible = speaker != ""
	var color := _speaker_color(speaker)
	if internal:
		color = color.darkened(0.25)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	_portrait_panel.add_theme_stylebox_override("panel", style)
	_portrait_initial.text = speaker.substr(0, 1).to_upper()


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


func _golden_pulse() -> void:
	if _flash == null:
		return
	_flash.color = Color(0.95, 0.78, 0.25, 0.5)
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, 0.6)


func _log(text: String) -> void:
	if text == "":
		return
	_log_label.text = text
	if _log_tween != null and _log_tween.is_valid():
		_log_tween.kill()
	_log_label.modulate.a = 1.0
	_log_tween = create_tween()
	_log_tween.tween_interval(2.2)
	_log_tween.tween_property(_log_label, "modulate:a", 0.0, 0.8)


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float, offset_left: float, offset_top: float, offset_right: float, offset_bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom
