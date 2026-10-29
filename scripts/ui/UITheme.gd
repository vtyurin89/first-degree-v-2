extends RefCounted
class_name UITheme

const DISPLAY := "FDDisplay"
const SUBTITLE := "FDSubtitle"
const QUOTE := "FDQuote"
const NARRATION := "FDNarration"
const BODY := "FDBody"
const VERSION := "FDVersion"
const MENU_ITEM := "FDMenuItem"
const BUTTON := "FDButton"
const MODAL_TITLE := "FDModalTitle"
const MODAL_MESSAGE := "FDModalMessage"
const MODAL_SUB := "FDModalSub"
const STATUS := "FDStatus"
const CHAPTER := "FDChapter"
const LOG := "FDLog"
const NAME := "FDName"
const HINT := "FDHint"
const PORTRAIT := "FDPortrait"
const TACTIC_TITLE := "FDTacticTitle"
const HUD := "FDHud"
const PROMPT := "FDPrompt"
const SMALL := "FDSmall"
const SCREEN_TITLE := "FDScreenTitle"
const INPUT := "FDInput"
const CHECK := "FDCheck"


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = default_font()
	theme.default_font_size = 16

	_register_rich(theme, DISPLAY, 64)
	_register_rich(theme, SUBTITLE, 17)
	_register_rich(theme, QUOTE, 14)
	_register_rich(theme, NARRATION, 24)
	_register_rich(theme, BODY, 20)

	_register_label(theme, VERSION, 12)
	_register_label(theme, MODAL_TITLE, 18)
	_register_label(theme, MODAL_MESSAGE, 22)
	_register_label(theme, MODAL_SUB, 14)
	_register_label(theme, STATUS, 15)
	_register_label(theme, CHAPTER, 16)
	_register_label(theme, LOG, 17)
	_register_label(theme, NAME, 22)
	_register_label(theme, HINT, 14)
	_register_label(theme, PORTRAIT, 72)
	_register_label(theme, TACTIC_TITLE, 18)
	_register_label(theme, HUD, 18)
	_register_label(theme, PROMPT, 20)
	_register_label(theme, SMALL, 14)
	_register_label(theme, SCREEN_TITLE, 42)

	_register_button(theme, MENU_ITEM, 20)
	_register_button(theme, BUTTON, 18)

	_register_line(theme, INPUT, 18)
	_register_check(theme, CHECK, 18)

	return theme


static func default_font() -> Font:
	return ThemeDB.fallback_font


static func _register_rich(theme: Theme, variation: String, font_size: int) -> void:
	theme.set_type_variation(variation, "RichTextLabel")
	theme.set_font_size("normal_font_size", variation, font_size)
	theme.set_font_size("bold_font_size", variation, font_size)
	theme.set_font_size("italics_font_size", variation, font_size)
	theme.set_font_size("bold_italics_font_size", variation, font_size)
	theme.set_font_size("mono_font_size", variation, font_size)


static func _register_label(theme: Theme, variation: String, font_size: int) -> void:
	theme.set_type_variation(variation, "Label")
	theme.set_font_size("font_size", variation, font_size)


static func _register_button(theme: Theme, variation: String, font_size: int) -> void:
	theme.set_type_variation(variation, "Button")
	theme.set_font_size("font_size", variation, font_size)


static func _register_line(theme: Theme, variation: String, font_size: int) -> void:
	theme.set_type_variation(variation, "LineEdit")
	theme.set_font_size("font_size", variation, font_size)


static func _register_check(theme: Theme, variation: String, font_size: int) -> void:
	theme.set_type_variation(variation, "CheckBox")
	theme.set_font_size("font_size", variation, font_size)
