extends Area3D
class_name InteractionVolume

const INTERACTION_LAYER := 1 << 3

var owner_interactable: Interactable3D


func _ready() -> void:
	collision_layer = INTERACTION_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true


func get_interactable() -> Interactable3D:
	return owner_interactable
