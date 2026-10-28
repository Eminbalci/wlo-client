class_name SkillWindow
extends Control

const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")
const PillScript = preload("res://scripts/ui/hud/pill_button.gd")
const SkinButtonScript = preload("res://scripts/ui/hud/skin_button.gd")
const SkillDatabaseScript = preload("res://scripts/database/skill_database.gd")

## Sub-controller and view for Wonderland Online Skill Window (form_skill_1, 290x459).
## Displays the five skill categories of the original client (Physical, Magical, Assistant, Life,
## Intro), switched with the arrows baked into the skin; a scrollable skill list populated from the
## skill database; a detail card laid over the baked "Grade / attack way / proficiency / weapon"
## captions; and drag-and-drop / click-to-assign binding to HUD Hotbar slots (F1..F8).
##
## Category rules (from the Skill.dat category byte and skill type):
##   Physical / Magical / Assistant: skills of that type for the player's element plus common (no element) ones
##   Life:  category 9 (Collection, Cutting, Mining, forging ...)
##   Intro: category 0 (basic actions: Hand Attack, Defense, Flee ...)
## Category 10 (internal / monster skills) is never listed, except the role's own starter stunt.

signal skill_selected(skill_data: Dictionary)
signal skill_assigned_to_hotbar(slot_index: int, skill_data: Dictionary)
signal tab_changed(tab_index: int)
signal window_closed

const WINDOW_WIDTH: float = 290.0
const WINDOW_HEIGHT: float = 459.0

const TAB_PHYSICAL: int = 0
const TAB_MAGICAL: int = 1
const TAB_ASSIST: int = 2
const TAB_LIFE: int = 3
const TAB_INTRO: int = 4

const TAB_NAMES: Array[String] = ["Physical", "Magical", "Assistant", "Life", "Intro"]

const CATEGORY_BASIC: int = 0
const CATEGORY_LIFE: int = 9
const CATEGORY_INTERNAL: int = 10

## Baked category arrows in Form_Skill_1 (card-local) and the caption slots of the detail card
const CATEGORY_ARROW_LEFT: Vector2 = Vector2(75, 43)
const CATEGORY_ARROW_RIGHT: Vector2 = Vector2(193, 43)

var _hud: Control = null
var _is_building: bool = false
var _active_tab: int = TAB_PHYSICAL
var _player_element: int = 3 # Fire until the HUD reports the character's element
var _selected_skill_id: int = -1
var _selected_skill_data: Dictionary = {}

var learned_skills_only: bool = false
var _learned_skill_ids: Dictionary = {}

var _displayed_skills: Array[Dictionary] = []

# Node references
var background: TextureRect = null
var title_label: Label = null
var close_button: Button = null
var tabs_container: Control = null
var tab_buttons: Array[TextureButton] = []
var category_label: Label = null
var btn_category_prev: Button = null
var btn_category_next: Button = null
var detail_grade_label: Label = null
var detail_way_label: Label = null
var detail_proficiency_label: Label = null
var detail_weapon_label: Label = null

var scroll_container: ScrollContainer = null
var list_container: VBoxContainer = null
var empty_label: Label = null

var detail_panel: Control = null
var detail_slot_bg: TextureRect = null
var detail_icon: TextureRect = null
var detail_name_label: Label = null
var detail_type_label: Label = null
var detail_desc_label: Label = null
var detail_effect_label: Label = null

var quick_bind_container: Control = null
var quick_bind_label: Label = null
var quick_bind_buttons: Array[Button] = []

func _init() -> void:
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)

func _ready() -> void:
	_build_ui_if_needed()
	_update_player_element_tab()
	refresh_skill_list()
	_connect_visibility_refresh()

func setup(hud: Control = null) -> void:
	_hud = hud
	_build_ui_if_needed()
	_update_player_element_tab()
	refresh_skill_list()
	_connect_visibility_refresh()

## The skill database and the character may not be ready when the HUD builds this window, so the
## list is refreshed every time the window is shown.
func _connect_visibility_refresh() -> void:
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_update_player_element_tab()
		refresh_skill_list()

## Closes the skill window and notifies listeners
func close_window() -> void:
	visible = false
	AuthAudioScript.play_click()
	window_closed.emit()
	if _hud and "window_manager_ctrl" in _hud and _hud.window_manager_ctrl:
		_hud.window_manager_ctrl.window_toggled.emit("SkillWindow", false)

## Determines active player element from HUD and chooses default tab
func _update_player_element_tab() -> void:
	var elem_str := "Fire"
	if _hud:
		var char_ctrl = _hud.get("character_status_ctrl")
		if not char_ctrl:
			char_ctrl = _hud.get("char_status_ctrl")
		if char_ctrl and "current_element" in char_ctrl:
			elem_str = str(char_ctrl.current_element)
	
	match elem_str.to_lower():
		"earth":
			_player_element = SkillDatabaseScript.Element.EARTH
		"water":
			_player_element = SkillDatabaseScript.Element.WATER
		"wind":
			_player_element = SkillDatabaseScript.Element.WIND
		_:
			_player_element = SkillDatabaseScript.Element.FIRE

func is_skill_learned(skill_id: int) -> bool:
	return _learned_skill_ids.has(skill_id)

func learn_skill(skill_id: int) -> void:
	_learned_skill_ids[skill_id] = true
	if visible and learned_skills_only:
		refresh_skill_list()

func unlearn_skill(skill_id: int) -> void:
	_learned_skill_ids.erase(skill_id)
	if visible and learned_skills_only:
		refresh_skill_list()

func set_learned_skills_only(enabled: bool) -> void:
	learned_skills_only = enabled
	if visible:
		refresh_skill_list()

func get_learned_skill_ids() -> Array[int]:
	var out: Array[int] = []
	for k in _learned_skill_ids.keys():
		out.append(int(k))
	return out

func init_default_learned_skills(role_id: int = 1, element: int = 3) -> void:
	_learned_skill_ids.clear()
	# Basic intro skills
	_learned_skill_ids[10001] = true # Hand Attack
	_learned_skill_ids[60021] = true # Defense
	_learned_skill_ids[60041] = true # Flee
	# Starter stunt for role
	var stunt_id: int = int(SkillDatabaseScript.STARTER_SKILLS.get(role_id, 15038))
	_learned_skill_ids[stunt_id] = true
	# Starter element skill
	match element:
		SkillDatabaseScript.Element.EARTH:
			_learned_skill_ids[11001] = true # Rock Attack
		SkillDatabaseScript.Element.WATER:
			_learned_skill_ids[12001] = true # Water Bullet
			_learned_skill_ids[15042] = true # Recover
		SkillDatabaseScript.Element.FIRE:
			_learned_skill_ids[13001] = true # Fire Ball
			_learned_skill_ids[13002] = true # Fiery Attack
		SkillDatabaseScript.Element.WIND:
			_learned_skill_ids[14001] = true # Wind Blade
	# Life skills
	_learned_skill_ids[10021] = true # Collection
	_learned_skill_ids[10022] = true # Cutting
	_learned_skill_ids[10023] = true # Mining

## Builds all internal UI nodes idempotently
func _build_ui_if_needed() -> void:
	if _is_building:
		return
	_is_building = true

	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)

	# 1. Background TextureRect
	background = get_node_or_null("Background") as TextureRect
	if not background:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
	background.position = Vector2.ZERO
	background.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_PASS

	if not background.texture:
		if ResourceLoader.exists("res://assets/hud/form_skill_2.png"):
			background.texture = load("res://assets/hud/form_skill_2.png")
		elif ResourceLoader.exists("res://assets/hud/hud_skills.png"):
			background.texture = load("res://assets/hud/hud_skills.png")

	# 2. Title Label (Hidden by default to preserve authentic Delphi chrome)
	title_label = get_node_or_null("TitleLabel") as Label
	if not title_label:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		add_child(title_label)
	title_label.position = Vector2(18, 8)
	title_label.size = Vector2(140, 20)
	title_label.visible = false
	title_label.text = "Skills [S]"

	# 3. Authentic 18x18 Close Button at Vector2(260, 8)
	close_button = get_node_or_null("CloseButton") as Button
	if not close_button:
		close_button = Button.new()
		close_button.name = "CloseButton"
		add_child(close_button)
	WindowCloseButton.apply(close_button, WINDOW_WIDTH) # sits on the baked x sphere

	_apply_close_button_textures(close_button)

	for conn in close_button.pressed.get_connections():
		close_button.pressed.disconnect(conn.callable)
	close_button.pressed.connect(close_window)

	# 4. Tab Buttons Container (Y = 38..59)
	tabs_container = get_node_or_null("TabsContainer") as Control
	if not tabs_container:
		tabs_container = Control.new()
		tabs_container.name = "TabsContainer"
		tabs_container.position = Vector2(0, 38)
		tabs_container.size = Vector2(WINDOW_WIDTH, 24)
		add_child(tabs_container)
	
	_setup_tab_buttons()
	tabs_container.visible = false # icon tabs stay as the API; the text tabs below are what is shown
	_setup_category_navigation()
	_build_real_client_controls()

	# 5. Upper Box: ScrollContainer with Skill List (X: 24..264, Y: 68..294)
	scroll_container = get_node_or_null("SkillScrollContainer") as ScrollContainer
	if not scroll_container:
		scroll_container = ScrollContainer.new()
		scroll_container.name = "SkillScrollContainer"
		scroll_container.position = Vector2(24, 82)
		scroll_container.size = Vector2(242, 246)
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(scroll_container)

	list_container = scroll_container.get_node_or_null("SkillListContainer") as VBoxContainer
	if not list_container:
		list_container = VBoxContainer.new()
		list_container.name = "SkillListContainer"
		list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list_container.add_theme_constant_override("separation", 3)
		scroll_container.add_child(list_container)

	empty_label = get_node_or_null("EmptySkillLabel") as Label
	if not empty_label:
		empty_label = Label.new()
		empty_label.name = "EmptySkillLabel"
		empty_label.position = Vector2(30, 160)
		empty_label.size = Vector2(230, 30)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.text = "No skills in this category."
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", Color(0.35, 0.38, 0.45, 1.0))
		empty_label.visible = false
		add_child(empty_label)

	# 6. Lower Box: Skill Detail Panel (X: 24..264, Y: 308..392)
	detail_panel = get_node_or_null("DetailPanel") as Control
	if not detail_panel:
		detail_panel = Control.new()
		detail_panel.name = "DetailPanel"
		detail_panel.position = Vector2(24, 337)
		detail_panel.size = Vector2(242, 50)
		detail_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(detail_panel)

	_setup_detail_panel()

	# 7. Quick Bind / Hotbar Assignment Bar (Y: 402..448)
	quick_bind_container = get_node_or_null("QuickBindContainer") as Control
	if not quick_bind_container:
		quick_bind_container = Control.new()
		quick_bind_container.name = "QuickBindContainer"
		quick_bind_container.position = Vector2(24, 410)
		quick_bind_container.size = Vector2(242, 48)
		quick_bind_container.visible = false # the real window has no bind row; skills are dragged to the hotbar
		quick_bind_container.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(quick_bind_container)

	_setup_quick_bind_controls()

## Overlays the arrows baked at the top of the skin and shows the active category name between them
func _setup_category_navigation() -> void:
	category_label = get_node_or_null("CategoryLabel") as Label
	if not category_label:
		category_label = Label.new()
		category_label.name = "CategoryLabel"
		add_child(category_label)
	category_label.position = Vector2(98, 44)
	category_label.size = Vector2(96, 18)
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	category_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	category_label.add_theme_font_size_override("font_size", 12)
	category_label.add_theme_color_override("font_color", Color(0.36, 0.43, 0.64, 1.0))

	btn_category_prev = _ensure_arrow_overlay("BtnCategoryPrev", CATEGORY_ARROW_LEFT, -1)
	btn_category_next = _ensure_arrow_overlay("BtnCategoryNext", CATEGORY_ARROW_RIGHT, 1)
	_refresh_category_label()

func _ensure_arrow_overlay(node_name: String, pos: Vector2, step: int) -> Button:
	var btn := get_node_or_null(node_name) as Button
	if not btn:
		btn = Button.new()
		btn.name = node_name
		add_child(btn)
		var clear := StyleBoxEmpty.new()
		btn.flat = true
		btn.text = ""
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state, clear)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func() -> void:
			select_tab(wrapi(_active_tab + step, 0, TAB_NAMES.size()))
		)
	btn.position = pos
	btn.size = Vector2(24, 20)
	btn.tooltip_text = "Previous category" if step < 0 else "Next category"
	return btn

func _refresh_category_label() -> void:
	if category_label:
		category_label.text = TAB_NAMES[clampi(_active_tab, 0, TAB_NAMES.size() - 1)]
	_refresh_real_client_controls()


var text_tabs: Array[Button] = []
var name_label: Label = null
var bottom_close_button: Button = null


## Text tabs under the character name and the Close button of the real window (docs/re/ui_windows.md).
func _build_real_client_controls() -> void:
	if not text_tabs.is_empty():
		return
	var tab_specs := [[19, 40], [60, 40], [101, 46], [148, 30], [179, 34]]
	for i in TAB_NAMES.size():
		var tab := PillScript.make(TAB_NAMES[i], Vector2(tab_specs[i][0] + 4, 60), Vector2(tab_specs[i][1], 18), 9)
		tab.name = "TextTab_%d" % i
		var tab_idx: int = i
		tab.pressed.connect(func() -> void: select_tab(tab_idx))
		add_child(tab)
		text_tabs.append(tab)
	name_label = Label.new()
	name_label.name = "CharacterNameLabel"
	name_label.position = Vector2(98, 42)
	name_label.size = Vector2(96, 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.12, 0.16, 0.62, 1.0))
	add_child(name_label)
	if category_label:
		category_label.visible = false # the real row shows the character name instead
	for pair in [[btn_category_prev, "ArrowL_4"], [btn_category_next, "ArrowR_4"]]:
		if pair[0] != null and pair[0].get_node_or_null("Visual") == null:
			var visual: TextureButton = SkinButtonScript.make(pair[1], Vector2.ZERO, "Visual")
			visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pair[0].add_child(visual)
	bottom_close_button = PillScript.make("Close", Vector2(117, 431), Vector2(56, 18))
	bottom_close_button.name = "BtnBottomClose"
	bottom_close_button.pressed.connect(close_window)
	add_child(bottom_close_button)
	_refresh_real_client_controls()


func _refresh_real_client_controls() -> void:
	for i in text_tabs.size():
		if i == _active_tab:
			PillScript.style(text_tabs[i], Color(0.10, 0.16, 0.45, 1.0), PillScript.BORDER, Color(1.0, 1.0, 1.0, 1.0))
		else:
			PillScript.style(text_tabs[i], PillScript.INK)
	if name_label:
		var game_db: Node = null
		if Engine.get_main_loop() is SceneTree:
			game_db = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GameDatabase")
		var char_name := "Daniel"
		if game_db and "active_character" in game_db and game_db.active_character is Dictionary:
			char_name = str(game_db.active_character.get("name", char_name))
		name_label.text = char_name

## Sets up the 5 category tab buttons (Physical, Magical, Assistant, Life, Intro)
func _setup_tab_buttons() -> void:
	tab_buttons.clear()
	
	var tab_xs: Array[float] = [24.0, 72.0, 120.0, 168.0, 216.0]
	for i in range(5):
		var btn_name := "TabButton_%d" % i
		var btn := tabs_container.get_node_or_null(btn_name) as TextureButton
		if not btn:
			btn = TextureButton.new()
			btn.name = btn_name
			tabs_container.add_child(btn)
		
		btn.position = Vector2(tab_xs[i], 0.0)
		btn.size = Vector2(38, 21)
		btn.custom_minimum_size = Vector2(38, 21)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.tooltip_text = "%s Skills" % TAB_NAMES[i]
		
		var icon_idx := i + 1
		var norm_path := "res://assets/hud/btn_skill_icon_%d_normal.png" % icon_idx
		var hov_path := "res://assets/hud/btn_skill_icon_%d_hover.png" % icon_idx
		var prs_path := "res://assets/hud/btn_skill_icon_%d_pressed.png" % icon_idx
		
		if ResourceLoader.exists(norm_path): btn.texture_normal = load(norm_path)
		if ResourceLoader.exists(hov_path): btn.texture_hover = load(hov_path)
		if ResourceLoader.exists(prs_path): btn.texture_pressed = load(prs_path)
		
		var tab_idx: int = i
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		btn.pressed.connect(func() -> void: select_tab(tab_idx))
		
		tab_buttons.append(btn)
	
	_highlight_active_tab()

## Highlights the selected tab visually
func _highlight_active_tab() -> void:
	for i in range(tab_buttons.size()):
		var btn := tab_buttons[i]
		if i == _active_tab:
			btn.modulate = Color(1.15, 1.15, 1.15, 1.0)
		else:
			btn.modulate = Color(0.85, 0.85, 0.85, 0.9)

## Switches active tab and refreshes list
func select_tab(tab_index: int) -> void:
	if tab_index < 0 or tab_index >= 5:
		return
	_active_tab = tab_index
	AuthAudioScript.play_click()
	_highlight_active_tab()
	_refresh_category_label()
	refresh_skill_list()
	tab_changed.emit(_active_tab)

func get_active_tab() -> int:
	return _active_tab

## Configures the lower detail panel widgets
func _setup_detail_panel() -> void:
	detail_slot_bg = detail_panel.get_node_or_null("DetailSlotBg") as TextureRect
	if not detail_slot_bg:
		detail_slot_bg = TextureRect.new()
		detail_slot_bg.name = "DetailSlotBg"
		detail_slot_bg.position = Vector2(4, 4)
		detail_slot_bg.size = Vector2(28, 28)
		detail_slot_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		detail_slot_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if ResourceLoader.exists("res://assets/hud/slot_grid_1x1.png"):
			detail_slot_bg.texture = load("res://assets/hud/slot_grid_1x1.png")
		detail_panel.add_child(detail_slot_bg)

	detail_icon = detail_panel.get_node_or_null("DetailIcon") as TextureRect
	if not detail_icon:
		detail_icon = TextureRect.new()
		detail_icon.name = "DetailIcon"
		detail_icon.position = Vector2(6, 6)
		detail_icon.size = Vector2(24, 24)
		detail_icon.custom_minimum_size = Vector2(24, 24)
		detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		detail_panel.add_child(detail_icon)

	detail_name_label = detail_panel.get_node_or_null("DetailNameLabel") as Label
	if not detail_name_label:
		detail_name_label = Label.new()
		detail_name_label.name = "DetailNameLabel"
		detail_name_label.position = Vector2(36, -1)
		detail_name_label.size = Vector2(202, 17)
		detail_name_label.add_theme_font_size_override("font_size", 12)
		detail_name_label.add_theme_color_override("font_color", Color(0.22, 0.15, 0.08, 1.0))
		detail_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
		detail_name_label.add_theme_constant_override("shadow_offset_x", 1)
		detail_name_label.add_theme_constant_override("shadow_offset_y", 1)
		detail_name_label.text = "Select a Skill"
		detail_panel.add_child(detail_name_label)

	detail_type_label = detail_panel.get_node_or_null("DetailTypeLabel") as Label
	if not detail_type_label:
		detail_type_label = Label.new()
		detail_type_label.name = "DetailTypeLabel"
		detail_type_label.position = Vector2(36, 12)
		detail_type_label.size = Vector2(202, 14)
		detail_type_label.clip_text = true
		detail_type_label.add_theme_font_size_override("font_size", 9)
		detail_type_label.add_theme_color_override("font_color", Color(0.15, 0.35, 0.65, 1.0))
		detail_type_label.text = "Element: None | Target: Single | SP: 0"
		detail_panel.add_child(detail_type_label)

	detail_desc_label = detail_panel.get_node_or_null("DetailDescLabel") as Label
	if not detail_desc_label:
		detail_desc_label = Label.new()
		detail_desc_label.name = "DetailDescLabel"
		detail_desc_label.position = Vector2(36, 31)
		detail_desc_label.size = Vector2(202, 14)
		detail_desc_label.clip_text = true
		detail_desc_label.add_theme_font_size_override("font_size", 9)
		detail_desc_label.add_theme_color_override("font_color", Color(0.22, 0.18, 0.12, 1.0))
		detail_desc_label.text = "Click a skill from the list above to view details."
		detail_panel.add_child(detail_desc_label)

	detail_effect_label = detail_panel.get_node_or_null("DetailEffectLabel") as Label
	if not detail_effect_label:
		detail_effect_label = Label.new()
		detail_effect_label.name = "DetailEffectLabel"
		detail_effect_label.position = Vector2(2, 92)
		detail_effect_label.size = Vector2(238, 14)
		detail_effect_label.add_theme_font_size_override("font_size", 9)
		detail_effect_label.add_theme_color_override("font_color", Color(0.55, 0.35, 0.10, 1.0))
		detail_effect_label.text = ""
		detail_panel.add_child(detail_effect_label)

	# The baked captions (Grade / proficiency / attack way / weapon) fill the lower half of the detail
	# panel in the real window, so only the name and type line stay above them.
	detail_desc_label.visible = false
	detail_effect_label.visible = false

	# Values beside the captions baked into the card: Grade, attack way, proficiency, weapon
	detail_grade_label = _ensure_caption_value("DetailGradeLabel", Vector2(46, 46), Vector2(36, 14))
	detail_way_label = _ensure_caption_value("DetailWayLabel", Vector2(156, 46), Vector2(84, 14))
	detail_proficiency_label = _ensure_caption_value("DetailProficiencyLabel", Vector2(72, 67), Vector2(28, 14))
	detail_weapon_label = _ensure_caption_value("DetailWeaponLabel", Vector2(152, 67), Vector2(88, 14))

func _ensure_caption_value(node_name: String, pos: Vector2, sz: Vector2) -> Label:
	var label := detail_panel.get_node_or_null(node_name) as Label
	if not label:
		label = Label.new()
		label.name = node_name
		label.clip_text = true
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.18, 0.26, 0.46, 1.0))
		detail_panel.add_child(label)
	label.position = pos
	label.size = sz
	return label

## Configures the bottom quick bind hotbar buttons (F1..F8)
func _setup_quick_bind_controls() -> void:
	quick_bind_buttons.clear()

	quick_bind_label = quick_bind_container.get_node_or_null("QuickBindLabel") as Label
	if not quick_bind_label:
		quick_bind_label = Label.new()
		quick_bind_label.name = "QuickBindLabel"
		quick_bind_label.position = Vector2(0, 0)
		quick_bind_label.size = Vector2(242, 16)
		quick_bind_label.text = "Quick Bind to Hotbar:"
		quick_bind_label.add_theme_font_size_override("font_size", 10)
		quick_bind_label.add_theme_color_override("font_color", Color(0.22, 0.15, 0.08, 1.0))
		quick_bind_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
		quick_bind_label.add_theme_constant_override("shadow_offset_x", 1)
		quick_bind_label.add_theme_constant_override("shadow_offset_y", 1)
		quick_bind_container.add_child(quick_bind_label)

	# 8 small buttons F1..F8 with authentic WLO button styling
	for i in range(8):
		var btn_name := "BtnQuickSlot_%d" % (i + 1)
		var btn := quick_bind_container.get_node_or_null(btn_name) as Button
		if not btn:
			btn = Button.new()
			btn.name = btn_name
			quick_bind_container.add_child(btn)
		
		btn.position = Vector2(float(i * 30), 18.0)
		btn.size = Vector2(26, 22)
		btn.custom_minimum_size = Vector2(26, 22)
		btn.text = "F%d" % (i + 1)
		btn.tooltip_text = "Bind selected skill to Hotbar Slot F%d" % (i + 1)
		btn.add_theme_font_size_override("font_size", 10)
		btn.add_theme_color_override("font_color", Color(0.18, 0.14, 0.08, 1.0))
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		var b_style := StyleBoxFlat.new()
		b_style.bg_color = Color(0.92, 0.94, 0.97, 0.85)
		b_style.border_color = Color(0.72, 0.65, 0.52, 0.9)
		b_style.set_border_width_all(1)
		b_style.set_corner_radius_all(2)
		btn.add_theme_stylebox_override("normal", b_style)
		
		var slot_idx := i
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		btn.pressed.connect(func() -> void: bind_skill_to_hotbar(slot_idx))
		
		quick_bind_buttons.append(btn)

## Resolves SkillDatabase from scene tree or static instance
func _get_skill_database() -> Object:
	var gdb: Node = get_node_or_null("/root/GameDatabase") if is_inside_tree() else null
	if not gdb and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st and st.root:
			gdb = st.root.get_node_or_null("GameDatabase")
	if gdb and "skills" in gdb:
		return gdb.skills
	return SkillDatabaseScript.get_instance()

## Populates skill list according to active category tab
func refresh_skill_list() -> void:
	if not list_container:
		return
	
	# Clear previous list
	for child in list_container.get_children():
		child.queue_free()
	
	_displayed_skills.clear()
	
	var raw_skills: Array = []
	var db = _get_skill_database()

	# Identify player starter stunt skill to pin at top
	var starter_id: int = -1
	var role_id: int = 6
	if _hud:
		var char_ctrl = _hud.get("character_status_ctrl")
		if not char_ctrl:
			char_ctrl = _hud.get("char_status_ctrl")
		if char_ctrl and "current_role_id" in char_ctrl:
			role_id = int(char_ctrl.current_role_id)
	if db and db.has_method("get_starter_stunt_id"):
		starter_id = db.get_starter_stunt_id(role_id)

	if db:
		for record in db.get_all_skills().values():
			if _skill_in_tab(record, _active_tab, starter_id):
				raw_skills.append(record.to_dict())
	else:
		# Fallback sample skills for testing / offline
		raw_skills = _get_fallback_skills_for_tab(_active_tab)

	# Filter for learned skills if enabled
	if learned_skills_only:
		if _learned_skill_ids.is_empty():
			init_default_learned_skills(role_id, _player_element)
		var filtered: Array = []
		for s in raw_skills:
			var sid: int = int(s.get("id", 0))
			if is_skill_learned(sid):
				filtered.append(s)
		raw_skills = filtered

	# Sort skills: starter stunt first, then by ID
	raw_skills.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id: int = int(a.get("id", 0))
		var b_id: int = int(b.get("id", 0))
		if a_id == starter_id:
			return true
		if b_id == starter_id:
			return false
		return a_id < b_id
	)

	_displayed_skills.clear()
	for s in raw_skills:
		if s is Dictionary:
			_displayed_skills.append(s)

	if _displayed_skills.is_empty():
		if empty_label: empty_label.visible = true
		_clear_detail_panel()
		return

	if empty_label: empty_label.visible = false

	# Instantiate rows
	for skill_data in _displayed_skills:
		var row := _create_skill_row(skill_data)
		list_container.add_child(row)

	# Auto-select first skill or preserve selection
	var select_target := -1
	if _selected_skill_id > 0 and _has_skill_dict(_displayed_skills, _selected_skill_id):
		select_target = _selected_skill_id
	elif not _displayed_skills.is_empty():
		select_target = int(_displayed_skills[0].get("id", 0))
	
	if select_target > 0:
		select_skill(select_target)

## True when a skill record belongs in the given category tab for the current character
func _skill_in_tab(record, tab: int, starter_id: int) -> bool:
	var is_starter: bool = int(record.id) == starter_id
	var category: int = int(record.category)
	if category == CATEGORY_INTERNAL and not is_starter:
		return false
	var element: int = int(record.element)
	if element != SkillDatabaseScript.Element.NONE and element != _player_element and not is_starter:
		return false
	match tab:
		TAB_LIFE:
			return category == CATEGORY_LIFE
		TAB_INTRO:
			return category == CATEGORY_BASIC
	if category == CATEGORY_LIFE or category == CATEGORY_BASIC:
		return false
	var skill_type: int = int(record.skill_type)
	match tab:
		TAB_PHYSICAL:
			return skill_type == SkillDatabaseScript.SkillType.PHYSICAL
		TAB_MAGICAL:
			return skill_type == SkillDatabaseScript.SkillType.MAGIC
		TAB_ASSIST:
			return skill_type == SkillDatabaseScript.SkillType.ASSIST or skill_type == SkillDatabaseScript.SkillType.STATUS
	return false

func _has_skill_dict(arr: Array, id_val: int) -> bool:
	for item in arr:
		if int(item.get("id", 0)) == id_val:
			return true
	return false

## Creates an interactive skill row button with drag & drop support
func _create_skill_row(skill_data: Dictionary) -> Button:
	var btn := Button.new()
	btn.name = "SkillRow_%d" % int(skill_data.get("id", 0))
	btn.custom_minimum_size = Vector2(238, 26)
	btn.size = Vector2(238, 26)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = false
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# The real list is plain text on the baked panel; only hover / selection get a tint
	var norm_sb := StyleBoxEmpty.new()
	var hov_sb := StyleBoxFlat.new()
	hov_sb.bg_color = Color(0.78, 0.86, 0.98, 0.8)
	hov_sb.set_corner_radius_all(2)
	btn.add_theme_stylebox_override("normal", norm_sb)
	btn.add_theme_stylebox_override("hover", hov_sb)
	btn.add_theme_stylebox_override("pressed", hov_sb)
	btn.add_theme_stylebox_override("focus", hov_sb)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.position = Vector2(2, 1)
	icon.size = Vector2(24, 24)
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _resolve_skill_icon(skill_data)
	btn.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.position = Vector2(32, 4)
	name_lbl.size = Vector2(124, 18)
	name_lbl.text = str(skill_data.get("name", "Skill"))
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.10, 0.12, 0.22, 1.0))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(name_lbl)

	var info_lbl := Label.new()
	info_lbl.name = "InfoLabel"
	info_lbl.position = Vector2(150, 4)
	info_lbl.size = Vector2(80, 18)
	var sp_cost: int = int(skill_data.get("sp_cost", 0))
	info_lbl.text = "%d sp" % sp_cost if sp_cost > 0 else ""
	info_lbl.add_theme_font_size_override("font_size", 11)
	info_lbl.add_theme_color_override("font_color", Color(0.10, 0.12, 0.22, 1.0))
	info_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(info_lbl)

	var s_id := int(skill_data.get("id", 0))
	btn.pressed.connect(func() -> void:
		select_skill(s_id)
		AuthAudioScript.play_click()
	)

	# Drag and Drop support
	btn.set_script(preload("res://scripts/ui/hud/skill_row_button.gd"))
	btn.set("skill_data", skill_data)

	return btn

## Resolves an icon texture for a skill
func _resolve_skill_icon(skill_data: Dictionary) -> Texture2D:
	var elem: int = int(skill_data.get("element", 0))
	var path := ""
	match elem:
		1: path = "res://assets/hud/icon_element_1.png"
		2: path = "res://assets/hud/icon_element_2.png"
		3: path = "res://assets/hud/icon_element_3.png"
		4: path = "res://assets/hud/icon_element_4.png"
		_:
			if ResourceLoader.exists("res://assets/hud/icon_use_compound_skill.png"):
				path = "res://assets/hud/icon_use_compound_skill.png"
			else:
				path = "res://assets/hud/test_Btn_SkillIcon_1.png"
	
	if ResourceLoader.exists(path):
		return load(path)
	return null

## Selects a skill by ID and populates detail panel
func select_skill(skill_id: int) -> void:
	_selected_skill_id = skill_id
	var found_data := {}
	for item in _displayed_skills:
		if int(item.get("id", 0)) == skill_id:
			found_data = item
			break
	
	if found_data.is_empty():
		var db = _get_skill_database()
		if db and db.has_skill(skill_id):
			found_data = db.get_skill(skill_id).to_dict()

	_selected_skill_data = found_data
	_update_detail_panel(found_data)
	_highlight_selected_row(skill_id)
	skill_selected.emit(found_data)

func get_selected_skill() -> Dictionary:
	return _selected_skill_data

func get_displayed_skills() -> Array[Dictionary]:
	return _displayed_skills

## Updates selection styling across list buttons
func _highlight_selected_row(selected_id: int) -> void:
	if not list_container:
		return
	for child in list_container.get_children():
		if child is Button:
			var s_id: int = int(child.name.replace("SkillRow_", ""))
			if s_id == selected_id:
				var sel_sb := StyleBoxFlat.new()
				sel_sb.bg_color = Color(0.82, 0.89, 0.98, 1.0)
				sel_sb.border_color = Color(0.85, 0.68, 0.25, 1.0) # WLO Gold accent
				sel_sb.set_border_width_all(1)
				sel_sb.set_corner_radius_all(3)
				sel_sb.content_margin_left = 34.0
				sel_sb.content_margin_right = 6.0
				child.add_theme_stylebox_override("normal", sel_sb)
			else:
				var norm_sb := StyleBoxFlat.new()
				norm_sb.bg_color = Color(0.92, 0.94, 0.97, 0.7)
				norm_sb.border_color = Color(0.72, 0.77, 0.85, 0.8)
				norm_sb.set_border_width_all(1)
				norm_sb.set_corner_radius_all(3)
				norm_sb.content_margin_left = 34.0
				norm_sb.content_margin_right = 6.0
				child.add_theme_stylebox_override("normal", norm_sb)

## Updates the lower detail card with skill attributes
func _update_detail_panel(data: Dictionary) -> void:
	if data.is_empty():
		_clear_detail_panel()
		return
	
	if detail_icon:
		detail_icon.texture = _resolve_skill_icon(data)
	
	var sname: String = str(data.get("name", "Skill"))
	var elem_name: String = str(data.get("element_name", "None"))
	var sp_cost: int = int(data.get("sp_cost", 0))
	var stype: String = str(data.get("skill_type_name", "Physical"))
	var target: String = str(data.get("target_scope_name", "Single"))
	var desc: String = str(data.get("description", ""))
	var base_dmg: int = int(data.get("base_damage", 0))
	var mult1: float = float(data.get("damage_multiplier_1", 1.0))
	var rank: int = int(data.get("rank", 1))

	if desc.is_empty():
		desc = "Deals combat damage to enemy target."

	if detail_name_label:
		detail_name_label.text = sname
	if detail_type_label:
		detail_type_label.text = "%s | %s | %s | SP: %d" % [elem_name, stype, target, sp_cost]
	if detail_desc_label:
		detail_desc_label.text = desc
		detail_desc_label.tooltip_text = desc
	if detail_effect_label:
		detail_effect_label.text = "Base DMG: %d  |  Multiplier: %.2fx" % [base_dmg, mult1]
	if detail_grade_label:
		detail_grade_label.text = str(rank)
	if detail_way_label:
		detail_way_label.text = "%s / %s" % [stype, target]
	var prof: int = int(data.get("proficiency_required", data.get("rank", 1)))
	var wep: String = str(data.get("weapon_requirement", "Any"))
	if detail_proficiency_label:
		detail_proficiency_label.text = "Grade %d" % prof if prof > 0 else "-"
	if detail_weapon_label:
		detail_weapon_label.text = wep

func _clear_detail_panel() -> void:
	if detail_icon: detail_icon.texture = null
	if detail_name_label: detail_name_label.text = "No Skill Selected"
	if detail_type_label: detail_type_label.text = "Element: None | Target: Single | SP: 0"
	if detail_desc_label: detail_desc_label.text = "Select a skill to inspect it."
	if detail_effect_label: detail_effect_label.text = ""
	for caption_value in [detail_grade_label, detail_way_label, detail_proficiency_label, detail_weapon_label]:
		if caption_value:
			caption_value.text = ""

## Binds a skill to HUD Hotbar slot F1..F8 (slot_index 0..7)
func bind_skill_to_hotbar(slot_index: int, skill_id: int = -1) -> bool:
	if slot_index < 0 or slot_index >= 8:
		return false
	
	var target_id: int = skill_id if skill_id > 0 else _selected_skill_id
	if target_id <= 0 and not _selected_skill_data.is_empty():
		target_id = int(_selected_skill_data.get("id", 0))
	
	if target_id <= 0:
		if _hud and _hud.has_method("add_chat_message"):
			_hud.call("add_chat_message", "System", "Select a skill first to assign to Hotbar F%d." % (slot_index + 1), "System")
		return false

	var sdata: Dictionary = {}
	if target_id == _selected_skill_id and not _selected_skill_data.is_empty():
		sdata = _selected_skill_data
	else:
		for s in _displayed_skills:
			if int(s.get("id", 0)) == target_id:
				sdata = s
				break
	
	var sname: String = str(sdata.get("name", "Skill %d" % target_id))
	var stex: Texture2D = _resolve_skill_icon(sdata)

	var success: bool = false
	if _hud:
		var hotbar_ctrl = _hud.get("hotbar_ctrl")
		if hotbar_ctrl and hotbar_ctrl.has_method("bind_skill"):
			success = hotbar_ctrl.bind_skill(slot_index, target_id, sname, stex)
		elif hotbar_ctrl and hotbar_ctrl.has_method("drop_on_slot"):
			hotbar_ctrl.drop_on_slot(slot_index, {
				"type": "skill",
				"id": target_id,
				"name": sname,
				"icon_tex": stex
			})
			success = true
	
	if success:
		AuthAudioScript.play_click()
		skill_assigned_to_hotbar.emit(slot_index, sdata)
	
	return success

## Applies authentic 18x18 three-state close button textures
static func _apply_close_button_textures(btn: Button) -> void:
	# The close button is a transparent hit area over the x sphere baked into the skin (WindowCloseButton).
	pass

## Provides fallback skill records when database is unavailable (offline test suites)
func _get_fallback_skills_for_tab(tab_idx: int) -> Array:
	var list: Array = []
	match tab_idx:
		TAB_PHYSICAL:
			list.append({
				"id": 15038, "name": "Overarm Stumble", "element": 3, "element_name": "Fire",
				"sp_cost": 14, "rank": 1, "base_damage": 50, "damage_multiplier_1": 1.35,
				"target_scope_name": "Single", "skill_type_name": "Physical", "category": 7,
				"description": "Throws target with blazing force."
			})
			list.append({
				"id": 12036, "name": "Leap", "element": 4, "element_name": "Wind",
				"sp_cost": 12, "rank": 1, "base_damage": 42, "damage_multiplier_1": 1.2,
				"target_scope_name": "Single", "skill_type_name": "Physical", "category": 4,
				"description": "Vaults high into the sky for aerial strike."
			})
		TAB_MAGICAL:
			list.append({
				"id": 15039, "name": "Wine Flame", "element": 3, "element_name": "Fire",
				"sp_cost": 20, "rank": 1, "base_damage": 65, "damage_multiplier_1": 1.4,
				"target_scope_name": "Single", "skill_type_name": "Magic", "category": 7,
				"description": "Ignites alcohol vapor to scorch targets."
			})
		TAB_ASSIST:
			list.append({
				"id": 15042, "name": "Recover Normal", "element": 2, "element_name": "Water",
				"sp_cost": 15, "rank": 1, "base_damage": 60, "damage_multiplier_1": 1.0,
				"target_scope_name": "Single", "skill_type_name": "Assist", "category": 2,
				"description": "Restores vitality using pure spring waters."
			})
		TAB_LIFE:
			list.append({
				"id": 15983, "name": "Collection", "element": 0, "element_name": "None",
				"sp_cost": 0, "rank": 1, "base_damage": 0, "damage_multiplier_1": 0.0,
				"target_scope_name": "Single", "skill_type_name": "Special", "category": 9,
				"description": "Gather materials from the land."
			})
		TAB_INTRO:
			list.append({
				"id": 10001, "name": "Hand Attack", "element": 0, "element_name": "None",
				"sp_cost": 0, "rank": 1, "base_damage": 30, "damage_multiplier_1": 1.0,
				"target_scope_name": "Single", "skill_type_name": "Physical", "category": 0,
				"description": "Basic unarmed strike."
			})
	return list
