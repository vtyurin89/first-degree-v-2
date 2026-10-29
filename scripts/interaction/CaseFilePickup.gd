extends Interactable3D
class_name CaseFilePickup

var _visual: MeshInstance3D


func _init() -> void:
	interaction_type = InteractionType.PICKUP
	interaction_size = Vector3(0.62, 0.36, 0.52)
	interaction_offset = Vector3(0, 0.15, 0)
	highlight_enabled = true


func _ready() -> void:
	super._ready()
	prompt_key = "PROMPT_TAKE_CASE_FILE"
	_build_visual()


func _build_visual() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.6, 0.32)
	material.roughness = 0.85

	_visual = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.38, 0.05, 0.28)
	_visual.mesh = mesh
	_visual.material_override = material
	_visual.position = Vector3(0, 0.03, 0)
	add_child(_visual)

	var tab := MeshInstance3D.new()
	var tab_mesh := BoxMesh.new()
	tab_mesh.size = Vector3(0.16, 0.055, 0.06)
	tab.mesh = tab_mesh
	tab.material_override = material
	tab.position = Vector3(-0.08, 0.035, 0.14)
	add_child(tab)

	var label := MeshInstance3D.new()
	var label_mesh := BoxMesh.new()
	label_mesh.size = Vector3(0.16, 0.012, 0.09)
	label.mesh = label_mesh
	var label_material := StandardMaterial3D.new()
	label_material.albedo_color = Color(0.9, 0.88, 0.8)
	label_material.roughness = 0.95
	label.material_override = label_material
	label.position = Vector3(0.06, 0.058, -0.02)
	add_child(label)


func execute_interaction(_player) -> void:
	if not is_active:
		return
	is_active = false
	set_highlight(false)
	GameManager.has_case_file = true
	ObjectiveManager.complete_objective("take_case")
	GameManager.play_paper_sound()
	if _visual != null:
		_visual.visible = false
	queue_free()
