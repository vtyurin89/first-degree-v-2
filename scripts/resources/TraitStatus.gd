extends RefCounted
class_name TraitStatus

enum Level {
	UNKNOWN,
	SUSPECTED,
	CONFIRMED
}

const NARCISSISM := "NARCISSISM"
const AUTHORITARIAN := "AUTHORITARIAN"
const GENDER_BIAS := "GENDER_BIAS"

const ALL_TRAITS := [NARCISSISM, AUTHORITARIAN, GENDER_BIAS]

const DISPLAY_KEYS := {
	NARCISSISM: "TRAIT_NARCISSISM",
	AUTHORITARIAN: "TRAIT_AUTHORITARIAN",
	GENDER_BIAS: "TRAIT_GENDER_BIAS",
}


static func get_display_key(trait_id: String) -> String:
	return String(DISPLAY_KEYS.get(trait_id, ""))
