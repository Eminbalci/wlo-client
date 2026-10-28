class_name TurnTimelineDock
extends PanelContainer

## Wonderland Online - Battle Turn Timeline & Initiative Order Dock.
## Displays a responsive horizontal queue of active combatants sorted by SPD descending.
## Visualizes:
## - Round & Turn indicator.
## - Combatant mini-cards with name, level, element badge, and SPD.
## - Active actor highlight with gold border pulse.
## - Defeated status markers.

# --- Signals ---
signal combatant_card_clicked(is_enemy: bool, slot: int)

# --- Geometry & Style ---
const DOCK_MIN_SIZE: Vector2 = Vector2(560.0, 48.0)

# --- Subnodes ---
var scroll_container: ScrollContainer = null
var cards_container: HBoxContainer = null
var round_badge: Label = null

# Map: "p_0", "e_1" -> PanelContainer card
var card_widgets: Dictionary = {}

func _init() -> void:
	custom_minimum_size = DOCK_MIN_SIZE

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	mouse_filter = MOUSE_FILTER_PASS
	
	# Parchment / dark battle slate style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.13, 0.88)
	style.border_color = Color(0.3, 0.45, 0.6, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	add_theme_stylebox_override("panel", style)
	
	var main_hbox := HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 8)
	main_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	# Turn / Round Indicator Pill
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(72.0, 38.0)
	var pill_style := StyleBoxFlat.new()
	pill_style.bg_color = Color(0.12, 0.16, 0.24, 0.95)
	pill_style.border_color = Color(0.9, 0.75, 0.25, 0.9)
	pill_style.set_border_width_all(1)
	pill_style.set_corner_radius_all(4)
	pill.add_theme_stylebox_override("panel", pill_style)
	
	round_badge = Label.new()
	round_badge.name = "RoundBadge"
	round_badge.text = "TURN 1\nINIT"
	round_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_badge.add_theme_font_size_override("font_size", 10)
	round_badge.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	pill.add_child(round_badge)
	main_hbox.add_child(pill)
	
	# Scrollable Cards Container
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.custom_minimum_size = Vector2(460.0, 38.0)
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	cards_container = HBoxContainer.new()
	cards_container.add_theme_constant_override("separation", 6)
	cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(cards_container)
	main_hbox.add_child(scroll_container)
	
	add_child(main_hbox)

## Updates the timeline display from initiative data.
func update_timeline(timeline: Array[Dictionary], current_turn: int = 1) -> void:
	if not cards_container:
		return
	if round_badge:
		round_badge.text = "TURN %d\nINIT" % current_turn
		
	# Clear previous cards
	for child in cards_container.get_children():
		child.queue_free()
	card_widgets.clear()
	
	for i in range(timeline.size()):
		var data: Dictionary = timeline[i]
		var is_enemy: bool = bool(data.get("is_enemy", false))
		var slot: int = int(data.get("slot", 0))
		var key: String = "%s_%d" % ["e" if is_enemy else "p", slot]
		
		var card := _create_combatant_card(data, i + 1)
		cards_container.add_child(card)
		card_widgets[key] = card

func _create_combatant_card(data: Dictionary, rank: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(88.0, 36.0)
	card.mouse_filter = MOUSE_FILTER_PASS
	
	var is_enemy: bool = bool(data.get("is_enemy", false))
	var is_active: bool = bool(data.get("is_active", false))
	var elem: int = int(data.get("element", 0))
	var elem_color: Color = data.get("element_color", Color(0.7, 0.7, 0.7, 1.0))
	
	# Card styling
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 2.0
	
	if is_active:
		style.bg_color = Color(0.25, 0.22, 0.10, 0.95)
		style.border_color = Color(1.0, 0.85, 0.25, 1.0) # Glowing Gold
		style.set_border_width_all(2)
	elif is_enemy:
		style.bg_color = Color(0.18, 0.08, 0.08, 0.85)
		style.border_color = Color(0.8, 0.3, 0.25, 0.7)
		style.set_border_width_all(1)
	else:
		style.bg_color = Color(0.08, 0.14, 0.22, 0.85)
		style.border_color = Color(0.25, 0.55, 0.8, 0.7)
		style.set_border_width_all(1)
		
	card.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	
	# Top line: Rank & Name
	var hbox_top := HBoxContainer.new()
	hbox_top.add_theme_constant_override("separation", 2)
	
	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.add_theme_font_size_override("font_size", 9)
	rank_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.3, 1.0) if is_active else Color(0.6, 0.65, 0.7, 1.0))
	hbox_top.add_child(rank_lbl)
	
	var name_lbl := Label.new()
	var raw_name: String = String(data.get("name", "Actor"))
	name_lbl.text = raw_name if raw_name.length() <= 7 else raw_name.substr(0, 6) + "."
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_top.add_child(name_lbl)
	vbox.add_child(hbox_top)
	
	# Bottom line: Element badge & Speed
	var hbox_bottom := HBoxContainer.new()
	hbox_bottom.add_theme_constant_override("separation", 4)
	
	var elem_rect := ColorRect.new()
	elem_rect.custom_minimum_size = Vector2(8.0, 8.0)
	elem_rect.color = elem_color
	elem_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox_bottom.add_child(elem_rect)
	
	var spd_lbl := Label.new()
	spd_lbl.text = "SPD %d" % int(data.get("spd", 10))
	spd_lbl.add_theme_font_size_override("font_size", 8)
	spd_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 1.0))
	hbox_bottom.add_child(spd_lbl)
	
	if is_active:
		var act_lbl := Label.new()
		act_lbl.text = "ACT"
		act_lbl.add_theme_font_size_override("font_size", 8)
		act_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
		act_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox_bottom.add_child(act_lbl)
		
	vbox.add_child(hbox_bottom)
	card.add_child(vbox)
	
	# Rich tooltip
	card.tooltip_text = "%s (Lv.%d %s)\nHP: %d/%d | SP: %d/%d\nSpeed: %d" % [
		data.get("name", "Actor"),
		data.get("level", 1),
		data.get("element_name", "None"),
		data.get("hp", 100),
		data.get("max_hp", 100),
		data.get("sp", 50),
		data.get("max_sp", 50),
		data.get("spd", 10)
	]
	
	var slot: int = int(data.get("slot", 0))
	card.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			combatant_card_clicked.emit(is_enemy, slot)
	)
	
	return card

## Highlights the specified actor in the timeline.
func highlight_actor(is_enemy: bool, slot: int) -> void:
	var target_key: String = "%s_%d" % ["e" if is_enemy else "p", slot]
	for key in card_widgets.keys():
		var card: PanelContainer = card_widgets[key]
		if not is_instance_valid(card):
			continue
		var is_this_active: bool = (key == target_key)
		var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			if is_this_active:
				style.bg_color = Color(0.25, 0.22, 0.10, 0.95)
				style.border_color = Color(1.0, 0.85, 0.25, 1.0)
				style.set_border_width_all(2)
			else:
				var e: bool = key.begins_with("e_")
				style.bg_color = Color(0.18, 0.08, 0.08, 0.85) if e else Color(0.08, 0.14, 0.22, 0.85)
				style.border_color = Color(0.8, 0.3, 0.25, 0.7) if e else Color(0.25, 0.55, 0.8, 0.7)
				style.set_border_width_all(1)
