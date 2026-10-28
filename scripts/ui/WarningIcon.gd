extends Control
class_name WarningIcon

const ICON_SIZE := 52.0


func _ready() -> void:
	custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var w := ICON_SIZE
	var h := ICON_SIZE
	var color := UIPalette.GREY
	var top := Vector2(w * 0.5, 4.0)
	var right := Vector2(w - 4.0, h - 4.0)
	var left := Vector2(4.0, h - 4.0)
	draw_polyline(PackedVector2Array([top, right, left, top]), color, 2.0)
	draw_line(Vector2(w * 0.5, h * 0.34), Vector2(w * 0.5, h * 0.62), color, 2.5)
	draw_circle(Vector2(w * 0.5, h * 0.73), 2.0, color)
