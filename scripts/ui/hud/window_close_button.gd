class_name WindowCloseButton
extends RefCounted

## Places a window's close button on the "x" sphere that every window skin bakes into its
## top-right ornament. Measured on Form_RoleStatus_1, Form_ThingGrid5x5_1, Form_Skill_1,
## Form_Team_2, Form_TaskView_1, Form_Friend_2, Form_System_2 and Form_ThingStore_1: the sphere is
## about 20 px wide and its centre is always 40 px from the right edge and 30 px from the top.
##
## The button is a transparent hit area over the baked art (drawing the old 18x18 sprite as well
## would show a second "x"); hovering shows a thin ring so the target reads as clickable.

const SPHERE_CENTER_FROM_RIGHT: float = 40.0
const SPHERE_CENTER_Y: float = 30.0
const HIT_SIZE: Vector2 = Vector2(20.0, 20.0)


static func position_for(window_width: float) -> Vector2:
	return Vector2(window_width - SPHERE_CENTER_FROM_RIGHT, SPHERE_CENTER_Y) - HIT_SIZE * 0.5


static func apply(btn: Control, window_width: float) -> void:
	if btn == null:
		return
	btn.position = position_for(window_width)
	btn.size = HIT_SIZE
	btn.custom_minimum_size = HIT_SIZE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if btn is Button:
		(btn as Button).flat = true
		(btn as Button).text = ""
		var clear := StyleBoxEmpty.new()
		for state in ["normal", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state, clear)
		btn.add_theme_stylebox_override("hover", _ring(Color(1.0, 1.0, 1.0, 0.16)))
		btn.add_theme_stylebox_override("pressed", _ring(Color(0.0, 0.0, 0.0, 0.14)))
	elif btn is TextureButton:
		var texture_button := btn as TextureButton
		texture_button.texture_normal = null
		texture_button.texture_hover = null
		texture_button.texture_pressed = null
		texture_button.ignore_texture_size = true


static func _ring(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = Color(1.0, 0.86, 0.35, 0.95)
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	return box
