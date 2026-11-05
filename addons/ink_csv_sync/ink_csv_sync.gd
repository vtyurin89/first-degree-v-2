@tool
extends EditorPlugin

const INK_DIR := "res://data/ink/chapter1"
const CSV_DIR := "res://data/translations/dialogues/chapter1"
const FALLBACK_CSV := "dialogues.csv"
const CSV_HEADER := "\"keys\",\"en\",\"ru\""
const SOURCE_LOCALE := "ru"

var _timer: Timer


func _enter_tree() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 0.35
	_timer.timeout.connect(_run_sync)
	add_child(_timer)

	var filesystem = get_editor_interface().get_resource_filesystem()
	if filesystem != null and filesystem.has_signal("filesystem_changed"):
		filesystem.filesystem_changed.connect(_on_filesystem_changed)
	call_deferred("_run_sync")


func _on_filesystem_changed() -> void:
	if _timer == null:
		return
	_timer.start()


func _run_sync() -> void:
	var directory := DirAccess.open(INK_DIR)
	if directory == null:
		return
	var total_added := 0
	var total_updated := 0
	for file_name in directory.get_files():
		if not file_name.ends_with(".ink"):
			continue
		var ink_path := "%s/%s" % [INK_DIR, file_name]
		var result := _sync_ink_file(ink_path)
		total_added += int(result.get("added", 0))
		total_updated += int(result.get("updated", 0))
	if total_added > 0 or total_updated > 0:
		print("[InkCsvSync] Updated %d row(s), added %d row(s)." % [total_updated, total_added])


func _sync_ink_file(ink_path: String) -> Dictionary:
	var source := FileAccess.get_file_as_string(ink_path)
	if source.is_empty():
		return {"added": 0, "updated": 0}
	var entries := _parse_ink(source)
	if entries.is_empty():
		return {"added": 0, "updated": 0}
	var base := ink_path.get_file().get_basename()
	var csv_path := "%s/%s.csv" % [CSV_DIR, base]
	if not FileAccess.file_exists(csv_path):
		csv_path = "%s/%s" % [CSV_DIR, FALLBACK_CSV]
	return _sync_csv(csv_path, entries)


func _parse_ink(source: String) -> Array:
	var entries: Array = []
	var seen_ids := {}
	var id_regex := RegEx.new()
	id_regex.compile("#\\s*id\\s*:\\s*([A-Za-z0-9_]+)")
	for raw_line in source.replace("\r", "").split("\n"):
		var line := String(raw_line)
		var id_match := id_regex.search(line)
		if id_match == null:
			continue
		var id := id_match.get_string(1)
		if id == "" or seen_ids.has(id):
			continue
		var text := _extract_text(line)
		if text == "":
			continue
		seen_ids[id] = true
		entries.append({"id": id, "text": text})
	return entries


func _extract_text(line: String) -> String:
	var stripped := line.strip_edges()
	if stripped.begins_with("*") or stripped.begins_with("+"):
		var opening := stripped.find("[")
		var closing := stripped.find("]", opening + 1)
		if opening >= 0 and closing > opening:
			return _strip_tags(stripped.substr(opening + 1, closing - opening - 1))
		return ""
	var tag_index := stripped.find(" #")
	var text := stripped if tag_index < 0 else stripped.substr(0, tag_index)
	return _strip_tags(text)


func _strip_tags(text: String) -> String:
	var tag_index := text.find(" #")
	if tag_index >= 0:
		text = text.substr(0, tag_index)
	return text.strip_edges()


func _sync_csv(csv_path: String, entries: Array) -> Dictionary:
	var raw := ""
	if FileAccess.file_exists(csv_path):
		raw = FileAccess.get_file_as_string(csv_path)
	if raw.is_empty():
		raw = CSV_HEADER + "\n"
	var newline := "\r\n" if raw.contains("\r\n") else "\n"
	var had_trailing_newline := raw.ends_with("\n")
	var normalized := raw.replace("\r", "")
	var lines := normalized.split("\n")
	if not lines.is_empty() and String(lines[lines.size() - 1]) == "":
		lines.remove_at(lines.size() - 1)
	if lines.is_empty():
		lines = [CSV_HEADER]
	var header := _parse_csv_line(String(lines[0]))
	var key_index := header.find("keys")
	var english_index := header.find("en")
	var source_index := header.find(SOURCE_LOCALE)
	if key_index < 0:
		key_index = 0
	if source_index < 0:
		source_index = header.size() - 1

	var source_by_id := {}
	for entry in entries:
		var id := String(entry.get("id", ""))
		if id != "":
			source_by_id[id] = String(entry.get("text", ""))

	var known := {}
	var updated := 0
	for i in range(1, lines.size()):
		var line := String(lines[i])
		if line.strip_edges() == "":
			continue
		var fields := _parse_csv_line(line)
		if fields.size() <= key_index:
			continue
		var id := String(fields[key_index])
		known[id] = true
		if not source_by_id.has(id) or source_index < 0:
			continue
		var source_text := String(source_by_id[id])
		while fields.size() <= source_index:
			fields.append("")
		if String(fields[source_index]) == source_text:
			continue
		fields[source_index] = source_text
		lines[i] = _csv_line(fields)
		updated += 1

	var added := 0
	for entry in entries:
		var id := String(entry.get("id", ""))
		if id == "" or known.has(id):
			continue
		var row: Array[String] = []
		for i in range(header.size()):
			row.append("")
		row[key_index] = id
		if source_index >= 0 and source_index < row.size():
			row[source_index] = String(entry.get("text", ""))
		if english_index >= 0 and english_index < row.size():
			row[english_index] = ""
		lines.append(_csv_line(row))
		known[id] = true
		added += 1

	if updated == 0 and added == 0:
		return {"added": 0, "updated": 0}
	var output := ""
	for i in range(lines.size()):
		if i > 0:
			output += newline
		output += lines[i]
	if had_trailing_newline or added > 0:
		output += newline
	var file := FileAccess.open(csv_path, FileAccess.WRITE)
	if file == null:
		push_error("[InkCsvSync] Cannot write: %s" % csv_path)
		return {"added": 0, "updated": 0}
	file.store_string(output)
	file.close()
	return {"added": added, "updated": updated}


func _csv_line(fields: Array[String]) -> String:
	var result := PackedStringArray()
	for field in fields:
		result.append("\"" + field.replace("\"", "\"\"") + "\"")
	return ",".join(result)


func _parse_csv_line(line: String) -> PackedStringArray:
	var fields := PackedStringArray()
	var current := ""
	var in_quotes := false
	var index := 0
	while index < line.length():
		var character := line.substr(index, 1)
		if in_quotes:
			if character == "\"":
				if index + 1 < line.length() and line.substr(index + 1, 1) == "\"":
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
