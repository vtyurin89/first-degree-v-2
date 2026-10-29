extends Node

const PAUSE_LAYER := 90
const MODAL_LAYER := 100
const SCREEN_LAYER := 95
const INDICATOR_LAYER := 110

var _pause_layer: CanvasLayer
var _pause_menu: MenuScreen
var _modal_layer: CanvasLayer
var _modal: ModalDialog
var _settings_dialog: SettingsDialog
var _screen_layer: CanvasLayer
var _screen: SaveLoadScreen
var _indicator_layer: CanvasLayer
var _indicator: Label
var _indicator_tween: Tween
var _state_before_pause: int = -1
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = MODAL_LAYER
	_modal_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_modal_layer)
	_create_indicator()
	SaveManager.load_started.connect(_on_load_started)
	SaveManager.save_started.connect(_on_save_started)
	SaveManager.save_completed.connect(_on_save_completed)
	SaveManager.load_completed.connect(_on_load_completed)
	SaveManager.save_corrupted.connect(_on_save_corrupted)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _modal != null:
		_dismiss_modal()
		get_viewport().set_input_as_handled()
	elif _settings_dialog != null:
		_close_settings()
		get_viewport().set_input_as_handled()
	elif _screen != null:
		close_screen()
		get_viewport().set_input_as_handled()
	elif _pause_menu != null:
		resume_game()
		get_viewport().set_input_as_handled()
	elif GameManager.is_gameplay_state():
		pause_game()
		get_viewport().set_input_as_handled()


func pause_game() -> void:
	if _pause_menu != null or not GameManager.is_gameplay_state():
		return
	_state_before_pause = GameManager.current_state
	_prev_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.set_state(GameManager.GameState.PAUSED)

	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = PAUSE_LAYER
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)

	_pause_menu = MenuScreen.new()
	_pause_menu.theme = ThemeManager.get_theme()
	_pause_layer.add_child(_pause_menu)
	_pause_menu.configure(MenuScreen.Mode.PAUSE)
	_pause_menu.action_selected.connect(_on_pause_action)
	get_tree().paused = true


func resume_game() -> void:
	if _pause_menu == null:
		return
	get_tree().paused = false
	_pause_menu.queue_free()
	_pause_menu = null
	_pause_layer.queue_free()
	_pause_layer = null
	if _state_before_pause >= 0:
		GameManager.set_state(_state_before_pause)
	_state_before_pause = -1
	Input.mouse_mode = _prev_mouse_mode


func open_save_screen() -> void:
	_open_screen(SaveLoadScreen.Mode.SAVE)


func open_load_screen() -> void:
	_open_screen(SaveLoadScreen.Mode.LOAD)


func _open_screen(mode: int) -> void:
	_dismiss_modal()
	_close_settings()
	_close_screen_internal()
	_screen_layer = CanvasLayer.new()
	_screen_layer.layer = SCREEN_LAYER
	_screen_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_screen_layer)
	_screen = SaveLoadScreen.new()
	_screen.theme = ThemeManager.get_theme()
	_screen_layer.add_child(_screen)
	_screen.configure(mode)
	_screen.closed.connect(close_screen)


func close_screen() -> void:
	_close_screen_internal()


func _close_screen_internal() -> void:
	if _screen != null:
		_screen.queue_free()
		_screen = null
	if _screen_layer != null:
		_screen_layer.queue_free()
		_screen_layer = null


func has_modal() -> bool:
	return _modal != null or _settings_dialog != null


func show_modal(title: String, message: String, options: Array, on_result: Callable = Callable(), sub_message: String = "", show_icon: bool = true) -> ModalDialog:
	_dismiss_modal()
	_modal = ModalDialog.new()
	_modal.theme = ThemeManager.get_theme()
	_modal_layer.add_child(_modal)
	_modal.configure(title, message, options, sub_message, show_icon)
	_modal.option_selected.connect(func(value: String) -> void:
		var callback := on_result
		_dismiss_modal()
		if callback.is_valid():
			callback.call(value)
	)
	_modal.closed.connect(_dismiss_modal)
	return _modal


func show_input_modal(title: String, message: String, placeholder: String, on_confirm: Callable, initial_text: String = "", sub_message: String = "") -> ModalDialog:
	_dismiss_modal()
	_modal = ModalDialog.new()
	_modal.theme = ThemeManager.get_theme()
	_modal_layer.add_child(_modal)
	_modal.configure(
		title,
		message,
		[
			{"text": tr("COMMON_SAVE"), "value": "ok", "primary": true},
			{"text": tr("COMMON_CANCEL"), "value": "cancel"},
		],
		sub_message,
		false,
		true,
		placeholder,
		initial_text
	)
	_modal.option_selected.connect(func(value: String) -> void:
		var dialog := _modal
		var text := ""
		if dialog != null:
			text = dialog.get_input_text()
		_dismiss_modal()
		if value == "ok" and on_confirm.is_valid():
			on_confirm.call(text)
	)
	_modal.closed.connect(_dismiss_modal)
	return _modal


func _on_load_started() -> void:
	_dismiss_modal()
	_close_settings()
	_close_screen_internal()
	if _pause_menu != null:
		_pause_menu.queue_free()
		_pause_menu = null
		_pause_layer.queue_free()
		_pause_layer = null
		_state_before_pause = -1
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _dismiss_modal() -> void:
	if _modal == null:
		return
	var dialog := _modal
	_modal = null
	dialog.queue_free()


func _on_pause_action(action_id: String) -> void:
	match action_id:
		"continue":
			resume_game()
		"save_game":
			open_save_screen()
		"load_game":
			open_load_screen()
		"settings":
			open_settings()
		"exit":
			_confirm_exit()


func _confirm_exit() -> void:
	show_modal(
		tr("EXIT_TITLE"),
		tr("EXIT_MESSAGE"),
		[
			{"text": tr("YES_EXIT"), "value": "exit", "primary": true, "danger": true},
			{"text": tr("STAY"), "value": "stay"},
		],
		_on_exit_choice,
		tr("EXIT_WARNING"),
		true
	)


func _on_exit_choice(value: String) -> void:
	if value == "exit":
		get_tree().quit()


func open_settings() -> void:
	_dismiss_modal()
	_close_settings()
	_settings_dialog = SettingsDialog.new()
	_settings_dialog.theme = ThemeManager.get_theme()
	_modal_layer.add_child(_settings_dialog)
	_settings_dialog.closed.connect(_close_settings)


func _close_settings() -> void:
	if _settings_dialog == null:
		return
	var dialog := _settings_dialog
	_settings_dialog = null
	dialog.queue_free()


func _create_indicator() -> void:
	_indicator_layer = CanvasLayer.new()
	_indicator_layer.layer = INDICATOR_LAYER
	_indicator_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_indicator_layer)
	_indicator = Label.new()
	_indicator.theme = ThemeManager.get_theme()
	_indicator.theme_type_variation = UITheme.SMALL
	_indicator.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_indicator.anchor_left = 1.0
	_indicator.anchor_right = 1.0
	_indicator.anchor_top = 1.0
	_indicator.anchor_bottom = 1.0
	_indicator.offset_left = -320
	_indicator.offset_right = -24
	_indicator.offset_top = -44
	_indicator.offset_bottom = -16
	_indicator.modulate.a = 0.0
	_indicator_layer.add_child(_indicator)


func _show_indicator(text: String, color: Color = UIPalette.TEXT_DIM) -> void:
	if _indicator == null:
		return
	_indicator.text = text
	_indicator.add_theme_color_override("font_color", color)
	if _indicator_tween != null and _indicator_tween.is_valid():
		_indicator_tween.kill()
	_indicator.modulate.a = 1.0
	_indicator_tween = create_tween()
	_indicator_tween.tween_interval(1.4)
	_indicator_tween.tween_property(_indicator, "modulate:a", 0.0, 0.5)


func _on_save_started(_slot_id: String) -> void:
	_show_indicator(tr("INDICATOR_SAVING"))


func _on_save_completed(_slot_id: String, success: bool) -> void:
	if success:
		_show_indicator(tr("INDICATOR_SAVED"), UIPalette.TEXT)
	else:
		_show_indicator(tr("INDICATOR_SAVE_ERROR"), UIPalette.RED_BRIGHT)


func _on_load_completed(success: bool) -> void:
	if success:
		_show_indicator(tr("INDICATOR_LOADED"), UIPalette.TEXT)
	else:
		_show_indicator(tr("INDICATOR_LOAD_ERROR"), UIPalette.RED_BRIGHT)


func _on_save_corrupted(_slot_id: String) -> void:
	_show_indicator(tr("INDICATOR_CORRUPTED"), UIPalette.RED_BRIGHT)
