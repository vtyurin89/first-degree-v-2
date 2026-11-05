extends Control
class_name CostHint

var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	custom_minimum_size = Vector2(54, 30)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_panel.add_child(_label)
	visible = false


func show_cost(cost: int, insufficient: bool) -> void:
	if _panel == null:
		return
	var color := Color(0.32, 0.8, 0.98) if not insufficient else Color(0.9, 0.25, 0.22)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.1, 0.14, 0.96)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(7)
	_panel.add_theme_stylebox_override("panel", style)
	_label.text = "⚡ %d" % cost
	_label.add_theme_color_override("font_color", color)
	visible = true


func follow_mouse(position: Vector2) -> void:
	if not visible:
		return
	global_position = position + Vector2(12, -42)


func hide_hint() -> void:
	visible = false
