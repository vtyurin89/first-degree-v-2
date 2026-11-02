extends Interactable3D
class_name MentholGumPickup

const FLAG_TAKEN := "menthol_gum_taken"

var _visual: MeshInstance3D


func _init() -> void:
	interaction_type = InteractionType.PICKUP
	interaction_size = Vector3(0.36, 0.18, 0.30)
	interaction_offset = Vector3(0, 0.05, 0)
	highlight_enabled = true


func _ready() -> void:
	super._ready()
	prompt_key = "PROMPT_TAKE_MENTHOL_GUM"
	_build_visual()


func _build_visual() -> void:
	var wrapper := StandardMaterial3D.new()
	wrapper.albedo_color = Color(0.36, 0.74, 0.6)
	wrapper.roughness = 0.72

	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.17, 0.032, 0.11)
	_visual.mesh = mesh
	_visual.material_override = wrapper
	_visual.position = Vector3(0, 0.018, 0)
	add_child(_visual)

	var label := MeshInstance3D.new()
	var label_mesh := BoxMesh.new()
	label_mesh.size = Vector3(0.11, 0.006, 0.062)
	label.mesh = label_mesh
	var label_material := StandardMaterial3D.new()
	label_material.albedo_color = Color(0.93, 0.94, 0.9)
	label_material.roughness = 0.85
	label.material_override = label_material
	label.position = Vector3(0, 0.036, 0)
	add_child(label)


func execute_interaction(_player) -> void:
	if not is_active:
		return
	is_active = false
	set_highlight(false)
	GameManager.add_flag(FLAG_TAKEN)
	GameManager.add_energy(1)
	queue_free()
