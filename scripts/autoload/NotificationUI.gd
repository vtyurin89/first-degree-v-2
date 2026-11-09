extends CanvasLayer

var _stack: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_stack = VBoxContainer.new()
	_stack.anchor_left = 1.0
	_stack.anchor_right = 1.0
	_stack.anchor_top = 0.0
	_stack.anchor_bottom = 0.0
	_stack.offset_left = -430
	_stack.offset_right = -24
	_stack.offset_top = 68
	_stack.offset_bottom = 340
	_stack.add_theme_constant_override("separation", 10)
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stack)


func show_event_notification(event: DiscoveryEvent) -> void:
	if event == null or _stack == null:
		return
	var header_text := tr(event.notification_header_key) if event.notification_header_key != "" else ""
	var title_text := tr(event.notification_title_key) if event.notification_title_key != "" else ""
	if header_text == "" and title_text == "":
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(400, 86)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.055, 0.065, 0.95)
	style.border_color = event.notification_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	_stack.add_child(panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var header := Label.new()
	header.text = header_text
	header.add_theme_color_override("font_color", event.notification_color)
	header.add_theme_font_size_override("font_size", 13)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)

	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", Color(0.92, 0.9, 0.86))
	title.add_theme_font_size_override("font_size", 16)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(3.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)
