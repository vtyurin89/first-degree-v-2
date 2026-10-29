extends Interactable3D
class_name PickupInteractable3D

var on_pickup: Callable


func _init() -> void:
	interaction_type = InteractionType.PICKUP


func _ready() -> void:
	super._ready()


func execute_interaction(player) -> void:
	if not is_active:
		return
	if on_pickup.is_valid():
		on_pickup.call(player)
	_consume()


func _consume() -> void:
	is_active = false
	visible = false
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	monitorable = false
	queue_free()
