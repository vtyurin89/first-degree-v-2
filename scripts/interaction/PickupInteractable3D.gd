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
	set_highlight(false)
	visible = false
	for node in find_children("*", "CollisionShape3D", true, false):
		var shape := node as CollisionShape3D
		if shape != null:
			shape.set_deferred("disabled", true)
	if _volume != null:
		_volume.monitorable = false
	queue_free()
