class_name HUDPillButton
extends RefCounted

## Small rounded button of the classic skin (light blue fill, blue border, centred caption).
## The caption is a child label so the button keeps exactly the size it was given: a Button's own
## text would inflate it to the font's line height.

const INK := Color(0.24, 0.30, 0.55, 1.0)
const BORDER := Color(0.42, 0.52, 0.76, 1.0)
const FILL := Color(0.86, 0.92, 1.0, 1.0)
const ON_INK := Color(0.10, 0.50, 0.28, 1.0)
const OFF_INK := Color(0.82, 0.16, 0.16, 1.0)


static func make(caption: String, pos: Vector2, pill_size: Vector2, font_size: int = 10) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = pill_size
	btn.custom_minimum_size = pill_size
	btn.clip_contents = true
	btn.text = ""
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var label := Label.new()
	label.name = "Caption"
	label.text = caption
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	btn.add_child(label)
	style(btn, INK, BORDER, FILL)
	return btn


## Re-colours a pill (used for On/Off toggles and active tabs).
static func style(btn: Button, ink: Color, border: Color = BORDER, fill: Color = FILL) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = fill if state != "hover" else fill.lightened(0.45)
		box.border_color = border
		box.set_border_width_all(1)
		box.set_corner_radius_all(3)
		box.set_content_margin_all(0.0)
		btn.add_theme_stylebox_override(state, box)
	var label := btn.get_node_or_null("Caption") as Label
	if label:
		label.add_theme_color_override("font_color", ink)


static func set_caption(btn: Button, caption: String) -> void:
	var label := btn.get_node_or_null("Caption") as Label
	if label:
		label.text = caption


## On / Off look: green "On", red "Off".
static func style_toggle(btn: Button, is_on: bool) -> void:
	set_caption(btn, "On" if is_on else "Off")
	if is_on:
		style(btn, ON_INK, Color(0.30, 0.70, 0.45, 1.0), Color(0.90, 1.0, 0.93, 1.0))
	else:
		style(btn, OFF_INK, Color(0.85, 0.40, 0.40, 1.0), Color(1.0, 0.92, 0.92, 1.0))
