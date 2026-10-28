class_name SkillRowButton
extends Button

## Interactive skill list row for Wonderland Online SkillWindow.
## Supports clicking to inspect details, double-clicking to assign to active hotbar slot,
## and drag-and-drop to HUD Hotbar slots F1..F8.

var skill_data: Dictionary = {}
var _icon: TextureRect = null
var _name_label: Label = null
var _info_label: Label = null

func _ready() -> void:
	_icon = get_node_or_null("Icon") as TextureRect
	_name_label = get_node_or_null("NameLabel") as Label
	_info_label = get_node_or_null("InfoLabel") as Label

func _get_drag_data(_at_position: Vector2) -> Variant:
	if skill_data.is_empty():
		return null
	
	var s_id: int = int(skill_data.get("id", 0))
	var s_name: String = str(skill_data.get("name", "Skill %d" % s_id))
	var sp_cost: int = int(skill_data.get("sp_cost", 0))
	var icon_tex: Texture2D = _icon.texture if _icon else null

	# Create drag preview
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(140, 28)
	
	var bg := Panel.new()
	bg.size = Vector2(140, 28)
	bg.position = Vector2(-14, -14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.22, 0.9)
	style.border_color = Color(0.85, 0.75, 0.35, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	bg.add_theme_stylebox_override("panel", style)
	preview.add_child(bg)
	
	if icon_tex:
		var p_icon := TextureRect.new()
		p_icon.texture = icon_tex
		p_icon.position = Vector2(-10, -10)
		p_icon.size = Vector2(20, 20)
		p_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(p_icon)
		
	var p_lbl := Label.new()
	p_lbl.position = Vector2(14, -12)
	p_lbl.size = Vector2(110, 24)
	p_lbl.text = s_name
	p_lbl.add_theme_font_size_override("font_size", 11)
	p_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8, 1.0))
	p_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	p_lbl.add_theme_constant_override("outline_size", 2)
	p_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_child(p_lbl)
	
	var vp := get_viewport()
	if vp and vp.gui_is_dragging():
		set_drag_preview(preview)

	return {
		"type": "skill",
		"id": s_id,
		"name": s_name,
		"sp_cost": sp_cost,
		"icon_tex": icon_tex
	}
