class_name FloatingCombatText
extends Control

## Wonderland Online - Floating Combat Text (FCT) Component.
## Renders animated floating combat numbers, critical badges, healing popups,
## miss notifications, and element advantage badges with smooth elevation and cubic fade-out.

enum PopupType {
	DAMAGE = 0,
	CRITICAL = 1,
	HEAL = 2,
	MISS = 3,
	STATUS = 4
}

# --- Visual Styling ---
const COLORS: Dictionary = {
	PopupType.DAMAGE: Color(1.0, 0.32, 0.22, 1.0),     # Vibrant Crimson / Orange-Red
	PopupType.CRITICAL: Color(1.0, 0.88, 0.18, 1.0),   # Bright Radiant Gold
	PopupType.HEAL: Color(0.22, 0.95, 0.40, 1.0),       # Emerald Green
	PopupType.MISS: Color(0.65, 0.85, 1.0, 1.0),        # Cyan Silver
	PopupType.STATUS: Color(0.85, 0.65, 1.0, 1.0)      # Purple / Violet
}

var main_label: Label = null
var badge_label: Label = null

func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

## Spawns and starts a floating combat text instance on the given parent layer.
static func spawn(
	parent_layer: Control,
	target_pos: Vector2,
	text: String,
	type: int = PopupType.DAMAGE,
	badge_text: String = ""
) -> FloatingCombatText:
	if not parent_layer:
		return null
		
	var fct := FloatingCombatText.new()
	fct.name = "FCT_" + str(randi() % 100000)
	fct.position = target_pos
	parent_layer.add_child(fct)
	fct._setup_and_play(text, type, badge_text)
	return fct

func _setup_and_play(text: String, type: int, badge_text: String) -> void:
	var col: Color = COLORS.get(type, Color.WHITE)
	var is_crit: bool = (type == PopupType.CRITICAL)
	
	var vbox := VBoxContainer.new()
	vbox.name = "FCTVBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	
	main_label = Label.new()
	main_label.name = "MainLabel"
	main_label.text = text
	main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_label.add_theme_font_size_override("font_size", 20 if is_crit else 16)
	main_label.add_theme_color_override("font_color", col)
	main_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	main_label.add_theme_constant_override("shadow_offset_x", 1)
	main_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(main_label)
	
	if not badge_text.is_empty():
		badge_label = Label.new()
		badge_label.name = "BadgeLabel"
		badge_label.text = badge_text
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.add_theme_font_size_override("font_size", 9)
		badge_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 0.95) if is_crit else Color(0.85, 0.9, 1.0, 0.9))
		badge_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
		badge_label.add_theme_constant_override("shadow_offset_x", 1)
		badge_label.add_theme_constant_override("shadow_offset_y", 1)
		vbox.add_child(badge_label)
		
	add_child(vbox)
	
	# Initial position offset centering
	vbox.position = Vector2(-60.0, -20.0)
	vbox.custom_minimum_size = Vector2(120.0, 0.0)
	
	# Tween Elevation & Fade-out
	var duration: float = 0.85
	var tween := create_tween()
	if tween:
		if is_crit:
			scale = Vector2(1.35, 1.35)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(self, "position:y", position.y - 42.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		else:
			scale = Vector2(1.15, 1.15)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(self, "position:y", position.y - 36.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)
	else:
		queue_free()
