extends RefCounted
class_name Case1Scolfield

const CASE_ID := "CASE_1_SCOLFIELD"
const SUSPECT := "Edward Scolfield"


static func get_prologue() -> Array:
	return LocalizationManager.get_narrative_section("prologue")


static func get_epilogue() -> Array:
	return LocalizationManager.get_narrative_section("epilogue")


static func get_briefing() -> Array[DialogueLine]:
	var seq: Array[DialogueLine] = []
	var data: Dictionary = LocalizationManager.get_narrative()
	var briefing = data.get("briefing", {})
	if not (briefing is Dictionary):
		return seq
	for entry in briefing.get("before", []):
		seq.append(_line_from(entry))
	var options: Array[DialogueChoice] = []
	for entry in briefing.get("choices", []):
		if not (entry is Dictionary):
			continue
		var reply = entry.get("reply", {})
		var reply_line := _line("", "")
		if reply is Dictionary:
			reply_line = _line(String(reply.get("speaker", "")), String(reply.get("text", "")))
		options.append(_choice(String(entry.get("label", "")), "PROBE", [reply_line], {
			"set_coping_style": String(entry.get("coping", "")),
			"trust": int(entry.get("trust", 0)),
		}))
	seq.append(_decision(options))
	for entry in briefing.get("after", []):
		seq.append(_line_from(entry))
	return seq


static func _line_from(entry) -> DialogueLine:
	if not (entry is Dictionary):
		return _line("", "")
	return _line(
		String(entry.get("speaker", "")),
		String(entry.get("text", "")),
		bool(entry.get("internal", false))
	)


static func _line(speaker: String, text: String, internal: bool = false, emotion: String = "", required: String = "") -> DialogueLine:
	var line := DialogueLine.new()
	line.speaker = speaker
	line.text = text
	line.internal_thought = internal
	line.portrait_emotion = emotion
	line.required_url = required
	return line


static func _choice(label: String, kind: String, response: Array, opts: Dictionary = {}) -> DialogueChoice:
	var choice := DialogueChoice.new()
	choice.label = label
	choice.kind = kind
	choice.response = response
	choice.tactic_id = opts.get("tactic_id", "")
	choice.requires_clue = opts.get("requires_clue", "")
	choice.set_coping_style = opts.get("set_coping_style", "")
	choice.weller_trust_delta = opts.get("trust", 0)
	choice.unlock_trait = opts.get("unlock_trait", "")
	return choice


static func _decision(choices: Array[DialogueChoice]) -> DialogueLine:
	var line := DialogueLine.new()
	line.choices = choices
	return line
