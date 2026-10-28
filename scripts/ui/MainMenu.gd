extends Control

var _menu: MenuScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	_menu = MenuScreen.new()
	add_child(_menu)
	_menu.configure(MenuScreen.Mode.MAIN)
	_menu.action_selected.connect(_on_action)


func _on_action(action_id: String) -> void:
	match action_id:
		"new_game":
			GameManager.start_new_game()
		"load_game":
			MenuController.open_load_screen()
		"settings":
			MenuController.open_settings()
		"exit":
			get_tree().quit()
