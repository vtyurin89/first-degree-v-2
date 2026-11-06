extends Control
class_name SpiralBinding

var hole_radius := 4.5
var hole_spacing := 30.0
var edge_padding := 6.0
var hole_color := Color(0.34, 0.33, 0.35)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, hole_radius * 2.0 + 2.0)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var usable := size.x - edge_padding * 2.0
	if usable <= 0.0:
		return
	var count := maxi(2, int(floor(usable / hole_spacing)) + 1)
	var step := usable / float(count - 1)
	var center_y := size.y * 0.5
	for index in count:
		var x := edge_padding + step * float(index)
		draw_circle(Vector2(x, center_y), hole_radius, hole_color)
