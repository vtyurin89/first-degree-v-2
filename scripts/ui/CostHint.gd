extends PanelContainer
class_name CostHint

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	add_child(_label)
	visible = false


func show_cost(cost: int, insufficient: bool) -> void:
	var color := Color(0.32, 0.8, 0.98) if not insufficient else Color(0.9, 0.25, 0.22)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.1, 0.14, 0.96)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(7)
	add_theme_stylebox_override("panel", style)
	_label.text = "⚡ %d" % cost
	_label.add_theme_color_override("font_color", color)
	var font := _label.get_theme_font("font")
	if font == null:
		font = ThemeDB.fallback_font
	var font_size := _label.get_theme_font_size("font_size")
	var text_size := font.get_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var badge_size := Vector2(ceilf(text_size.x) + 14.0, ceilf(font.get_height(font_size)) + 14.0)
	custom_minimum_size = badge_size
	size = badge_size
	visible = true


func display_at(rect: Rect2, cost: int, insufficient: bool) -> void:
	if cost <= 0:
		hide_hint()
		return
	show_cost(cost, insufficient)
	if rect.size == Vector2.ZERO:
		return
	var target := Vector2(rect.get_center().x - size.x * 0.5, rect.position.y - size.y - 6.0)
	var viewport := get_viewport_rect().size
	target.x = clampf(target.x, 6.0, viewport.x - size.x - 6.0)
	target.y = maxf(target.y, 6.0)
	global_position = target


func follow_mouse(position: Vector2) -> void:
	if not visible:
		return
	global_position = position + Vector2(12, -42)


func hide_hint() -> void:
	visible = false
