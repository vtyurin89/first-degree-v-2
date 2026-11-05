extends Control
class_name HoldProgressRing

const RADIUS := 25.0
const THICKNESS := 5.0

var _progress := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 101
	custom_minimum_size = Vector2(RADIUS * 2 + THICKNESS * 2, RADIUS * 2 + THICKNESS * 2)
	size = custom_minimum_size
	visible = false


func show_ring(at: Vector2) -> void:
	visible = true
	modulate.a = 1.0
	global_position = at - size * 0.5


func follow(target: Vector2, delta: float) -> void:
	if not visible:
		return
	var desired := target - size * 0.5
	global_position = global_position.lerp(desired, clampf(delta * 18.0, 0.0, 1.0))


func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func hide_ring() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		visible = false
		modulate.a = 1.0
		_progress = 0.0
		queue_redraw()
	)


func _draw() -> void:
	var center := size * 0.5
	draw_arc(center, RADIUS, 0.0, TAU, 48, Color(0.12, 0.28, 0.34, 0.55), THICKNESS, true)
	draw_arc(center, RADIUS, -PI * 0.5, -PI * 0.5 + TAU * _progress, 48, Color(0.35, 0.9, 1.0, 0.95), THICKNESS + 2.0, true)
