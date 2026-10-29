extends Node
class_name PlayerInteractor

signal interaction_target_focused(prompt_text: String, screen_position: Vector2)
signal interaction_target_lost()

const INTERACTION_LAYER := 1 << 3

@export var max_interaction_distance := 2.0

var _focused: Interactable3D
var _ray: RayCast3D


func _ready() -> void:
	var camera := _find_camera()
	if camera == null:
		return
	_ray = RayCast3D.new()
	_ray.name = "InteractionRay"
	_ray.target_position = Vector3(0, 0, -max_interaction_distance)
	_ray.collision_mask = INTERACTION_LAYER
	_ray.collide_with_areas = true
	_ray.collide_with_bodies = false
	_ray.enabled = true
	camera.add_child(_ray)


func _find_camera() -> Camera3D:
	var parent := get_parent()
	if parent is Node3D:
		var camera := parent.get_node_or_null("Head/Camera3D") as Camera3D
		if camera != null:
			return camera
	return get_viewport().get_camera_3d()


func _physics_process(_delta: float) -> void:
	if _focused != null and not is_instance_valid(_focused):
		_focused = null
		interaction_target_lost.emit()
	if GameManager.current_state != GameManager.GameState.EXPLORATION_3D:
		_set_focus(null)
		return
	_set_focus(_resolve_target(true))


func _resolve_target(force_update: bool) -> Interactable3D:
	if _ray == null:
		return null
	if force_update:
		_ray.force_raycast_update()
	var collider := _ray.get_collider()
	if collider == null:
		return null
	var volume := collider as InteractionVolume
	if volume == null:
		return null
	var interactable := volume.get_interactable()
	if interactable == null or not is_instance_valid(interactable) or not interactable.is_active:
		return null
	var player := get_parent()
	if player is Node3D:
		var distance := (player as Node3D).global_position.distance_to(interactable.global_position)
		if distance > max_interaction_distance:
			return null
	return interactable


func _set_focus(target: Interactable3D) -> void:
	if _focused == target:
		return
	if _focused != null:
		if is_instance_valid(_focused):
			_focused.set_highlight(false)
		interaction_target_lost.emit()
	_focused = target
	if _focused != null and is_instance_valid(_focused):
		_focused.set_highlight(true)
		interaction_target_focused.emit(_focused.get_prompt_text(), _screen_position(_focused))


func _screen_position(target: Interactable3D) -> Vector2:
	var camera := _find_camera()
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
	var focused := _focused
	if focused == null or not is_instance_valid(focused) or not focused.is_focused:
		return
	var target := _resolve_target(true)
	if target != focused:
		_set_focus(target)
		return
	_set_focus(null)
	focused.execute_interaction(get_parent())
	get_viewport().set_input_as_handled()
