extends Interactable3D
class_name InspectInteractable3D

var on_inspect: Callable


func _init() -> void:
	interaction_type = InteractionType.INSPECT


func _ready() -> void:
	super._ready()


func execute_interaction(player) -> void:
	if not is_active:
		return
	if on_inspect.is_valid():
		on_inspect.call(player)
