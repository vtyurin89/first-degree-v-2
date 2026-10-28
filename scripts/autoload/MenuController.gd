extends Node

const PAUSE_LAYER := 90
const MODAL_LAYER := 100

var _pause_layer: CanvasLayer
var _pause_menu: MenuScreen
var _modal_layer: CanvasLayer
var _modal: ModalDialog
var _state_before_pause: int = -1
var _prev_mouse_mode: int = Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_modal_layer = CanvasLayer.new()
	_modal_layer.layer = MODAL_LAYER
	_modal_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_modal_layer)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _modal != null:
		_dismiss_modal()
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


func show_modal(title: String, message: String, options: Array, on_result: Callable = Callable(), sub_message: String = "", show_icon: bool = true) -> ModalDialog:
	_dismiss_modal()
	_modal = ModalDialog.new()
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
			show_modal("СОХРАНЕНИЕ", "Сохранение пока не реализовано.", _ok_options())
		"load_game":
			show_modal("ЗАГРУЗКА ИГРЫ", "Загрузка пока не реализована.", _ok_options())
		"settings":
			show_modal("НАСТРОЙКИ", "Настройки пока не реализованы.", _ok_options())
		"exit":
			_confirm_exit()


func _confirm_exit() -> void:
	show_modal(
		"ВЫХОД ИЗ ИГРЫ",
		"Вы уверены, что хотите выйти?",
		[
			{"text": "ДА, ВЫЙТИ", "value": "exit", "primary": true, "danger": true},
			{"text": "ОСТАТЬСЯ", "value": "stay"},
		],
		_on_exit_choice,
		"Несохранённый прогресс будет потерян.",
		true
	)


func _on_exit_choice(value: String) -> void:
	if value == "exit":
		get_tree().quit()


func _ok_options() -> Array:
	return [{"text": "ЗАКРЫТЬ", "value": "ok", "primary": true}]
