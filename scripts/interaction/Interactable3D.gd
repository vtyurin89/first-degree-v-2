extends Area3D
class_name Interactable3D

enum InteractionType { PICKUP, INSPECT, TRIGGER }

@export var prompt_text := ""
@export var prompt_key := ""
@export var interaction_type: InteractionType = InteractionType.TRIGGER
@export var is_active := true


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true


func get_prompt_text() -> String:
	if prompt_key != "":
		return tr(prompt_key)
	return prompt_text


func execute_interaction(_player) -> void:
	pass
