extends CanvasLayer

const LAYER_INDEX := 89
const HIDDEN_SCENES := [
	"res://scenes/MainMenu.tscn",
	"res://scenes/Prologue.tscn",
	"res://scenes/Epilogue.tscn",
]

var _root: Control
var _dev_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = LAYER_INDEX
	_build()
	GameSettings.dev_tools_changed.connect(_on_dev_tools_changed)
	LocalizationManager.locale_changed.connect(_on_locale_changed)
	_on_dev_tools_changed(GameSettings.dev_tools_enabled)


func _process(_delta: float) -> void:
	_update_visibility()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_dev_button = _make_button(tr("TOP_BAR_DEV"))
	_dev_button.anchor_left = 1.0
	_dev_button.anchor_right = 1.0
	_dev_button.offset_left = -82.0
	_dev_button.offset_right = -18.0
	_dev_button.offset_top = 16.0
	_dev_button.offset_bottom = 46.0
	_dev_button.tooltip_text = tr("TOP_BAR_DEV_TOOLTIP")
	_dev_button.pressed.connect(_on_dev_pressed)
	_root.add_child(_dev_button)


func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.theme_type_variation = UITheme.BUTTON
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(64, 30)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", UIPalette.TEXT)
	button.add_theme_color_override("font_hover_color", UIPalette.WHITE)
	button.add_theme_color_override("font_pressed_color", UIPalette.WHITE)
	button.add_theme_stylebox_override("normal", UIPalette.make_style(UIPalette.BG_BAR, UIPalette.GREY_LINE, 1, 2, 4))
	button.add_theme_stylebox_override("hover", UIPalette.make_style(UIPalette.SELECTED_BG, UIPalette.SELECTED_BG, 1, 2, 4))
	button.add_theme_stylebox_override("pressed", UIPalette.make_style(UIPalette.SELECTED_BG.darkened(0.12), UIPalette.SELECTED_BG, 1, 2, 4))
	button.add_theme_stylebox_override("focus", UIPalette.make_style(Color(0, 0, 0, 0)))
	return button


func _on_dev_tools_changed(enabled: bool) -> void:
	if _dev_button != null:
		_dev_button.visible = enabled


func _on_locale_changed(_locale: String) -> void:
	if _dev_button != null:
		_dev_button.text = tr("TOP_BAR_DEV")
		_dev_button.tooltip_text = tr("TOP_BAR_DEV_TOOLTIP")


func _update_visibility() -> void:
	if _root == null:
		return
	var scene := get_tree().current_scene
	var hidden_scene := scene != null and HIDDEN_SCENES.has(scene.scene_file_path)
	_root.visible = GameManager.is_gameplay_state() and not get_tree().paused and not hidden_scene


func _on_dev_pressed() -> void:
	MenuController.open_dev_menu()
