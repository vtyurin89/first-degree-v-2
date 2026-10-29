extends Node3D
class_name Door3D

@export var width := 1.0
@export var height := 2.15
@export var thickness := 0.06
@export var interact_id := "door:unnamed"
@export var locked := false

var _hinge: Node3D
var _anim: AnimationPlayer
var _is_open := false


func _ready() -> void:
	_build_panel()
	_build_animation()
	_build_interactable()


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func open() -> void:
	if _is_open:
		return
	_is_open = true
	_anim.play("swing")


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_anim.play_backwards("swing")


func is_open() -> bool:
	return _is_open


func _build_panel() -> void:
	_hinge = Node3D.new()
	_hinge.name = "Hinge"
	_hinge.position = Vector3(-width * 0.5, 0, 0)
	add_child(_hinge)

	var panel := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, height, thickness)
	panel.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.17, 0.14)
	material.roughness = 0.72
	material.metallic = 0.15
	panel.material_override = material
	panel.position = Vector3(width * 0.5, height * 0.5, 0)
	_hinge.add_child(panel)

	var handle := MeshInstance3D.new()
	var handle_mesh := SphereMesh.new()
	handle_mesh.radius = 0.035
	handle_mesh.height = 0.07
	handle.mesh = handle_mesh
	var handle_material := StandardMaterial3D.new()
	handle_material.albedo_color = Color(0.55, 0.55, 0.56)
	handle_material.metallic = 0.85
	handle_material.roughness = 0.22
	handle.material_override = handle_material
	handle.position = Vector3(width * 0.9, height * 0.5, thickness * 0.6)
	_hinge.add_child(handle)

	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, height, thickness)
	shape.shape = box
	shape.position = Vector3(width * 0.5, height * 0.5, 0)
	body.add_child(shape)
	_hinge.add_child(body)


func _build_animation() -> void:
	_anim = AnimationPlayer.new()
	add_child(_anim)
	_anim.root_node = NodePath("..")
	var animation := Animation.new()
	animation.length = 0.45
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("Hinge:rotation:y"))
	animation.track_insert_key(track, 0.0, 0.0)
	animation.track_insert_key(track, 0.45, -PI * 0.5)
	var library := AnimationLibrary.new()
	library.add_animation("swing", animation)
	_anim.add_animation_library("", library)


func _build_interactable() -> void:
	var area := TriggerInteractable3D.new()
	area.name = "DoorInteractable"
	area.prompt_key = "PROMPT_DOOR"
	area.is_active = not locked
	area.on_trigger = _on_triggered
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(width, 1.0), 2.2, 0.9)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3(0, 1.1, 0)
	add_child(area)


func _on_triggered(_player) -> void:
	if locked:
		return
	toggle()
