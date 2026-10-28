extends Node

signal locale_changed(locale: String)

const SUPPORTED_LOCALES := ["ru", "en"]
const DEFAULT_LOCALE := "ru"
const FALLBACK_LOCALE := "en"
const DATA_ROOT := "res://data"
const CSV_PATH := "res://data/translations.csv"
const SETTINGS_PATH := "user://settings.cfg"

var current_locale := DEFAULT_LOCALE

var _narrative_cache: Dictionary = {}
var _narrative_locale := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_translations()
	var saved := _load_saved_locale()
	var start_locale := saved if SUPPORTED_LOCALES.has(saved) else DEFAULT_LOCALE
	_apply_locale(start_locale, false)


func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		return
	if locale == current_locale:
		return
	_apply_locale(locale, true)


func _apply_locale(locale: String, emit_signal: bool) -> void:
	current_locale = locale
	TranslationServer.set_locale(locale)
	_narrative_cache.clear()
	_narrative_locale = ""
	_save_locale(locale)
	if emit_signal:
		locale_changed.emit(locale)


func case_script_path() -> String:
	return "%s/%s/case1_scolfield.json" % [DATA_ROOT, current_locale]


func narrative_path(locale: String = "") -> String:
	var loc := locale if locale != "" else current_locale
	return "%s/%s/narrative.json" % [DATA_ROOT, loc]


func document_path(id: String, locale: String = "") -> String:
	var loc := locale if locale != "" else current_locale
	return "%s/items/%s/%s.tres" % [DATA_ROOT, loc, id]


func fallback_locale() -> String:
	return FALLBACK_LOCALE if current_locale != FALLBACK_LOCALE else "ru"


func get_narrative() -> Dictionary:
	if _narrative_locale == current_locale:
		return _narrative_cache
	var data := _load_json(narrative_path())
	if data.is_empty():
		data = _load_json(narrative_path(fallback_locale()))
	_narrative_cache = data
	_narrative_locale = current_locale
	return _narrative_cache


func get_narrative_section(section: String) -> Array:
	var data := get_narrative()
	var value = data.get(section, [])
	if value is Array:
		return value
	return []


func get_office_flavor(interact_id: String) -> Array:
	var data := get_narrative()
	var office = data.get("office", {})
	if not (office is Dictionary):
		return []
	var flavor = office.get("flavor", {})
	if not (flavor is Dictionary):
		return []
	var value = flavor.get(interact_id, [])
	if value is Array:
		return value
	return []


func _load_translations() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		push_error("[Localization] Не найден translations.csv: %s" % CSV_PATH)
		return
	var text := FileAccess.get_file_as_string(CSV_PATH).replace("\r", "")
	var lines := text.split("\n", false)
	if lines.is_empty():
		return
	var header := _parse_csv_line(lines[0])
	if header.size() < 2:
		push_error("[Localization] Некорректный заголовок translations.csv")
		return
	var translations: Dictionary = {}
	for index in range(1, header.size()):
		var locale := header[index].strip_edges()
		if locale == "":
			continue
		var translation := Translation.new()
		translation.locale = locale
		translations[locale] = translation
	for line_index in range(1, lines.size()):
		var line := lines[line_index]
		if line.strip_edges() == "":
			continue
		var fields := _parse_csv_line(line)
		if fields.is_empty():
			continue
		var key := fields[0].strip_edges()
		if key == "":
			continue
		for index in range(1, header.size()):
			var locale := header[index].strip_edges()
			if not translations.has(locale):
				continue
			var value := ""
			if index < fields.size():
				value = fields[index]
			translations[locale].add_message(key, value)
	for loc in translations.keys():
		TranslationServer.add_translation(translations[loc])


func _parse_csv_line(line: String) -> PackedStringArray:
	var fields := PackedStringArray()
	var current := ""
	var in_quotes := false
	var index := 0
	while index < line.length():
		var character := line[index]
		if in_quotes:
			if character == "\"":
				if index + 1 < line.length() and line[index + 1] == "\"":
					current += "\""
					index += 1
				else:
					in_quotes = false
			else:
				current += character
		else:
			if character == "\"":
				in_quotes = true
			elif character == ",":
				fields.append(current)
				current = ""
			else:
				current += character
		index += 1
	fields.append(current)
	return fields


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}


func _load_saved_locale() -> String:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		return String(config.get_value("general", "locale", DEFAULT_LOCALE))
	return DEFAULT_LOCALE


func _save_locale(locale: String) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("general", "locale", locale)
	config.save(SETTINGS_PATH)
