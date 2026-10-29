extends Area3D
class_name AudioZone3D

@export var zone_name := "corridor"
@export var reverb_room_size := 0.6
@export var reverb_damping := 0.35
@export var lowpass_cutoff := 20000.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		AudioManager.set_zone(zone_name, reverb_room_size, reverb_damping, lowpass_cutoff)
