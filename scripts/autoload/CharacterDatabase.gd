extends Node

const CHARACTER_DIR := "res://data/characters"
const CHARACTER_IDS := ["anna", "weller", "scolfield", "greenway"]

var _characters: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in CHARACTER_IDS:
		var path := "%s/%s.tres" % [CHARACTER_DIR, id]
		if not ResourceLoader.exists(path):
			push_error("[CharacterDatabase] не найден ресурс: %s" % path)
			continue
		var resource = ResourceLoader.load(path)
		if resource is CharacterData:
			_characters[id] = resource
		else:
			push_error("[CharacterDatabase] ресурс не является CharacterData: %s" % path)


func get_character(id: String) -> CharacterData:
	var value = _characters.get(id)
	if value is CharacterData:
		return value
	return null


func get_display_name(id: String, fallback: String = "") -> String:
	var character := get_character(id)
	if character != null:
		return character.get_display_name()
	return fallback if fallback != "" else id


func get_full_name(id: String, fallback: String = "") -> String:
	var character := get_character(id)
	if character != null:
		return character.get_full_name()
	return fallback if fallback != "" else id


func get_role(id: String) -> String:
	var character := get_character(id)
	if character != null:
		return character.get_role()
	return ""


func get_name_color(id: String, fallback := Color(0.3, 0.3, 0.32)) -> Color:
	var character := get_character(id)
	if character != null:
		return character.name_color
	return fallback


func get_portrait(id: String, emotion: String = "") -> Texture2D:
	var character := get_character(id)
	if character != null:
		return character.get_portrait(emotion)
	return null


func get_sprite_texture(id: String) -> Texture2D:
	var character := get_character(id)
	if character != null:
		return character.sprite_texture
	return null


func get_sprite_color(id: String, fallback := Color(0.3, 0.3, 0.32)) -> Color:
	var character := get_character(id)
	if character != null:
		return character.sprite_color
	return fallback


func get_sprite_pixel_size(id: String, fallback := 0.021) -> float:
	var character := get_character(id)
	if character != null:
		return character.sprite_pixel_size
	return fallback


func get_sprite_ground_offset(id: String, fallback := 1.0) -> float:
	var character := get_character(id)
	if character != null:
		return character.sprite_ground_offset
	return fallback
