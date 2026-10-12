extends Control

var case_data: CaseData
var _phase_index := 0
var _vnbox: VNBox

var _status_label: Label
var _log_label: Label
var _phase_label: Label
var _flash: ColorRect
var _log_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	GameManager.set_state(GameManager.GameState.INTERROGATION)
	case_data = Case1Scolfield.build()
	for tactic_id in case_data.initial_tactics:
		GameManager.unlock_tactic(tactic_id)
	_build_ui()
	_connect_game()
	_refresh_status()
	_start_phase(0)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.04, 0.04, 0.055)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var status_panel := PanelContainer.new()
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.anchor_left = 0
	status_panel.anchor_top = 0
	status_panel.anchor_right = 1
	status_panel.anchor_bottom = 0
	status_panel.offset_left = 0
	status_panel.offset_top = 0
	status_panel.offset_right = 0
	status_panel.offset_bottom = 54
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
	_status_label.add_theme_font_size_override("font_size", 16)
	status_panel.add_child(_status_label)

	_phase_label = Label.new()
	_phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_phase_label.add_theme_font_size_override("font_size", 16)
	_phase_label.modulate = Color(0.85, 0.75, 0.5)
	_phase_label.anchor_left = 0.5
	_phase_label.anchor_right = 1.0
	_phase_label.anchor_bottom = 0.0
	_phase_label.offset_top = 64
	_phase_label.offset_right = -24
	_phase_label.offset_bottom = 92
	add_child(_phase_label)

	_log_label = Label.new()
	_log_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_label.add_theme_font_size_override("font_size", 17)
	_log_label.modulate = Color(0.95, 0.85, 0.5, 0.0)
	_log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_label.anchor_left = 0
	_log_label.anchor_right = 1
	_log_label.anchor_top = 0
	_log_label.anchor_bottom = 0
	_log_label.offset_top = 110
	_log_label.offset_bottom = 140
	add_child(_log_label)

	_vnbox = VNBox.new()
	add_child(_vnbox)
	_vnbox.meta_clicked.connect(_on_meta_clicked)
	_vnbox.choice_selected.connect(_on_choice_selected)
	_vnbox.finished.connect(_on_vn_finished)

	_flash = ColorRect.new()
	_flash.color = Color(0.95, 0.78, 0.25, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)


func _connect_game() -> void:
	GameManager.pinned_slots_changed.connect(_on_int_changed)
	GameManager.energy_changed.connect(_on_int_changed)
	GameManager.resistance_changed.connect(_on_int_changed)
	GameManager.admissibility_changed.connect(_on_string_changed)
	GameManager.trait_unlocked.connect(_on_string_changed)
	GameManager.tactic_unlocked.connect(_on_string_changed)
	GameManager.clue_registered.connect(_on_string_changed)


func _on_int_changed(_value: int) -> void:
	_refresh_status()


func _on_string_changed(_value: String) -> void:
	_refresh_status()


func _refresh_status() -> void:
	if _status_label == null:
		return
	_status_label.text = "Энергия: %d/%d    |    Улики: %d    |    Допустимость: %s    |    Закрепы: %d    |    Доверие Уэллера: %d    |    Сопротивление адвоката: %d%%    |    Тактик: %d" % [
		GameManager.player_energy,
		GameManager.MAX_ENERGY,
		GameManager.registered_clues.size(),
		GameManager.admissibility_status,
		GameManager.pinned_slots_remaining,
		GameManager.weller_trust,
		GameManager.attorney_resistance,
		GameManager.unlocked_tactics.size(),
	]


func _start_phase(index: int) -> void:
	_phase_index = index
	GameManager.reset_phase_slots()
	var phase: InterrogationPhase = case_data.phases[index]
	_phase_label.text = "Фаза %d / %d — %s" % [index + 1, case_data.phases.size(), phase.milestone_name]
	_vnbox.play(phase.dialogue_sequence)


func _on_vn_finished() -> void:
	if _phase_index + 1 < case_data.phases.size():
		_start_phase(_phase_index + 1)
	else:
		_finish_case()


func _finish_case() -> void:
	set_process(false)
	GameManager.change_scene(GameManager.SCENE_EPILOGUE, 1.0)


func _on_choice_selected(choice: DialogueChoice) -> void:
	if choice.kind == "TACTIC":
		_log("Тактика: %s" % Case1Scolfield.TACTICS.get(choice.tactic_id, choice.label))
	else:
		_log("Вопрос: %s" % choice.label)
	_refresh_status()


func _on_meta_clicked(url: String) -> void:
	if GameManager.clicked_urls.has(url):
		_log("Это уже закреплено.")
		return
	if not GameManager.consume_pinned_slot():
		_log("Слоты закрепления закончились.")
		return
	GameManager.clicked_urls[url] = true
	var entry: Dictionary = case_data.url_registry.get(url, {})
	var kind: String = entry.get("type", "flavor")
	match kind:
		"trait":
			GameManager.unlock_trait(entry.get("value", ""))
			_log(entry.get("log", "Черта разблокирована."))
		"clue":
			GameManager.register_clue(entry.get("value", ""))
			if entry.has("tactic"):
				GameManager.unlock_tactic(entry["tactic"])
			_log(entry.get("log", "Улика закреплена."))
		"confession":
			_trigger_confession(url, entry)
		_:
			_log(entry.get("log", ""))
	_vnbox.refresh()
	_refresh_status()


func _trigger_confession(_url: String, entry: Dictionary) -> void:
	var phase_index: int = entry.get("phase", _phase_index)
	var milestone: String = entry.get("milestone", "")
	GameManager.set_admissibility("CLEAN")
	GameManager.mark_milestone(phase_index, milestone)
	_log("МАЙЛСТОУН ВЗЯТ: %s" % milestone)
	_golden_pulse()
	GameManager.play_cue(1046.5, 0.24, -4.0)


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
