extends RefCounted
class_name Case1Scolfield

const CASE_ID := "CASE_1_SCOLFIELD"
const SUSPECT := "Edward Scolfield"


static func get_prologue() -> Array:
	return LocalizationManager.get_narrative_section("prologue")


static func get_epilogue() -> Array:
	return LocalizationManager.get_narrative_section("epilogue")
