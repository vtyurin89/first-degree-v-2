extends Interactable3D
class_name TriggerInteractable3D

var on_trigger: Callable


func _init() -> void:
	interaction_type = InteractionType.TRIGGER


func _ready() -> void:
	super._ready()


func execute_interaction(player) -> void:
	if not is_active:
		return
	if on_trigger.is_valid():
		on_trigger.call(player)
