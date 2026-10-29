extends Area3D
class_name PlayerInteractor

signal interaction_target_focused(prompt_text: String, screen_position: Vector2)
signal interaction_target_lost()

@export var detection_radius := 2.4

var _focused: Interactable3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	var has_shape := false
	for child in get_children():
		if child is CollisionShape3D:
			has_shape = true
	if not has_shape:
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = detection_radius
		shape.shape = sphere
		add_child(shape)


func _physics_process(_delta: float) -> void:
	if _focused != null and not is_instance_valid(_focused):
		_focused = null
		interaction_target_lost.emit()
	if GameManager.current_state != GameManager.GameState.EXPLORATION_3D:
		_set_focus(null)
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_set_focus(null)
		return
	var forward := -camera.global_transform.basis.z
	var best: Interactable3D = null
	var best_score := 0.15
	for area in get_overlapping_areas():
		var interactable := area as Interactable3D
		if interactable == null or not interactable.is_active:
			continue
		var to_target := interactable.global_position - camera.global_position
		var distance := to_target.length()
		if distance < 0.01:
			continue
		var dot := forward.dot(to_target / distance)
		var score := dot - distance * 0.02
		if score > best_score:
			best_score = score
			best = interactable
	_set_focus(best)


func _set_focus(target: Interactable3D) -> void:
	if _focused == target:
		return
	if _focused != null:
		interaction_target_lost.emit()
	_focused = target
	if _focused != null and is_instance_valid(_focused):
		interaction_target_focused.emit(_focused.get_prompt_text(), _screen_position(_focused))


func _screen_position(target: Interactable3D) -> Vector2:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.ZERO
	return camera.unproject_position(target.global_position + Vector3(0, 0.25, 0))


func refresh_focus() -> void:
	if _focused != null and is_instance_valid(_focused):
		interaction_target_focused.emit(_focused.get_prompt_text(), _screen_position(_focused))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if GameManager.current_state != GameManager.GameState.EXPLORATION_3D:
		return
	if _focused == null or not is_instance_valid(_focused) or not _focused.is_active:
		return
	_focused.execute_interaction(get_parent())
	get_viewport().set_input_as_handled()
