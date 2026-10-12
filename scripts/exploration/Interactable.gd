extends Area3D
class_name Interactable

@export var interact_id: String = ""
@export var prompt: String = "Осмотреть"


func _ready() -> void:
	add_to_group("interactable")
