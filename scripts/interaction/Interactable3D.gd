extends Node3D
class_name Interactable3D

enum InteractionType { PICKUP, INSPECT, TRIGGER }

@export var prompt_text := ""
@export var prompt_key := ""
@export var interaction_type: InteractionType = InteractionType.TRIGGER
@export var is_active := true
@export var interaction_size := Vector3(1, 1, 1)
@export var interaction_offset := Vector3.ZERO
@export var highlight_root: Node3D
@export var highlight_enabled := false

var is_focused := false

var _volume: InteractionVolume
var _outline_material: ShaderMaterial
var _highlighted_meshes: Array[MeshInstance3D] = []
var _proxy: MeshInstance3D


func _ready() -> void:
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = load("res://shaders/interaction_outline.gdshader")
	_build_volume()


func _build_volume() -> void:
	for child in get_children():
		if child is InteractionVolume:
			_volume = child as InteractionVolume
			break
	if _volume == null:
		_volume = InteractionVolume.new()
		_volume.name = "InteractionVolume"
		_volume.position = interaction_offset
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = interaction_size
		shape.shape = box
		_volume.add_child(shape)
		add_child(_volume)
	if _volume.owner_interactable == null:
		_volume.owner_interactable = self


func get_prompt_text() -> String:
	if prompt_key != "":
		return tr(prompt_key)
	return prompt_text


func set_highlight(enabled: bool) -> void:
	is_focused = enabled
	if not highlight_enabled or not enabled:
		_clear_highlight()
		return
	var meshes := _find_highlight_meshes()
	if meshes.is_empty():
		_ensure_proxy()
		if _proxy != null:
			_proxy.visible = true
		return
	if _proxy != null:
		_proxy.visible = false
	_highlighted_meshes = meshes
	for mesh in _highlighted_meshes:
		mesh.material_overlay = _outline_material


func _clear_highlight() -> void:
	for mesh in _highlighted_meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = null
	_highlighted_meshes.clear()
	if _proxy != null:
		_proxy.visible = false


func _find_highlight_meshes() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if highlight_root == null or highlight_root == self:
		for node in find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			if mesh == null or mesh == _proxy:
				continue
			if not mesh.is_visible_in_tree():
				continue
			result.append(mesh)
		return result
	if _volume == null:
		return result
	var margin := Vector3(0.4, 0.4, 0.4)
	var volume_min := _volume.global_position - interaction_size * 0.5 - margin
	var volume_max := _volume.global_position + interaction_size * 0.5 + margin
	for node in highlight_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh == null or mesh == _proxy:
			continue
		if not mesh.is_visible_in_tree():
			continue
		var mesh_aabb := mesh.global_transform * mesh.get_aabb()
		if mesh_aabb.position.x < volume_min.x or mesh_aabb.end.x > volume_max.x:
			continue
		if mesh_aabb.position.y < volume_min.y or mesh_aabb.end.y > volume_max.y:
			continue
		if mesh_aabb.position.z < volume_min.z or mesh_aabb.end.z > volume_max.z:
			continue
		result.append(mesh)
	return result


func _ensure_proxy() -> void:
	if _proxy != null:
		return
	_proxy = MeshInstance3D.new()
	_proxy.name = "HighlightOutline"
	var box := BoxMesh.new()
	box.size = interaction_size + Vector3(0.03, 0.03, 0.03)
	_proxy.mesh = box
	_proxy.material_override = _outline_material
	_proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_proxy.position = interaction_offset
	_proxy.visible = false
	add_child(_proxy)


func execute_interaction(_player) -> void:
	pass
