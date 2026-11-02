extends Resource
class_name CharacterData

@export var id: String = ""
@export var name_key: String = ""
@export var full_name_key: String = ""
@export var role_key: String = ""
@export var name_color: Color = Color.WHITE
@export var default_portrait: Texture2D
@export var portraits: Dictionary = {}
@export var sprite_texture: Texture2D
@export var sprite_color: Color = Color(0.5, 0.5, 0.5)
@export var sprite_pixel_size: float = 0.021
@export var sprite_ground_offset: float = 1.0


func get_portrait(emotion: String = "") -> Texture2D:
	if emotion != "" and portraits.has(emotion):
		var value = portraits[emotion]
		if value is Texture2D:
			return value
	return default_portrait


func get_display_name() -> String:
	if name_key != "":
		return tr(name_key)
	return id


func get_full_name() -> String:
	if full_name_key != "":
		return tr(full_name_key)
	return get_display_name()


func get_role() -> String:
	if role_key != "":
		return tr(role_key)
	return ""
