extends RefCounted
class_name UIPalette

const BG_DEEP := Color(0.031, 0.031, 0.039)
const BG_PANEL := Color(0.071, 0.071, 0.078)
const BG_BAR := Color(0.102, 0.102, 0.114)
const OVERLAY := Color(0.0, 0.0, 0.0, 0.86)

const TEXT := Color(0.820, 0.808, 0.784)
const TEXT_DIM := Color(0.525, 0.514, 0.494)
const TEXT_FAINT := Color(0.337, 0.325, 0.310)
const WHITE := Color(0.929, 0.922, 0.902)
const GREY := Color(0.561, 0.549, 0.525)
const GREY_LINE := Color(0.227, 0.220, 0.208)

const SELECTED_BG := Color(0.800, 0.788, 0.765)
const SELECTED_TEXT := Color(0.047, 0.047, 0.051)

const RED := Color(0.698, 0.133, 0.122)
const RED_BRIGHT := Color(0.851, 0.224, 0.204)
const RED_DIM := Color(0.420, 0.102, 0.094)


static func html(color: Color) -> String:
	return "#" + color.to_html(false)


static func make_style(bg: Color, border_color: Color = Color(0, 0, 0, 0), border_width: int = 0, radius: int = 2, margin: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style
