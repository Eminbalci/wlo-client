class_name TeamWindow
extends Control

## Sub-controller and view for Wonderland Online Team / Party Window (Form_Team_2, 371x539).
## Employs authentic Wonderland Online Delphi client assets:
## - Form_Team_2.bmp skin backdrop
## - Authentic 18x18 close button at Vector2(341, 8)
## - Sliced authentic action buttons: Btn_LeaveTeam_1, Btn_DismissTeam_1, Btn_AssignLeader_1
## - Sliced authentic companion toggle buttons: Btn_AssignFight_1 (Summon), Btn_AssignRest_1 (Rest)
## - Authentic OrgLeader.bmp badge for party leader
## - Authentic Pet_Word_Hp and Pet_Word_Sp badges with textured bars
## - Authentic 2000s MMORPG typography: 11px/12px with 2px black outline
## Integrates directly with MapView._party_companions, NpcStateEvaluator, and overland followers.

signal window_closed
signal member_selected(slot_index: int, member_data: Dictionary)
signal member_dismissed(slot_index: int, member_data: Dictionary)
signal leader_promoted(new_leader_index: int, new_leader_data: Dictionary)
signal team_left
signal companion_toggled(companion_id: int, summoned: bool)
signal companion_summoned(companion_id: int, companion_name: String)
signal companion_recalled(companion_id: int)
signal companion_mounted(companion: Dictionary)
signal companion_dismounted(companion: Dictionary)
signal companion_ride_toggled(is_riding: bool)

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")

const WINDOW_WIDTH: float = 371.0
const WINDOW_HEIGHT: float = 539.0
const MAX_MEMBERS: int = 4

# Node references
var background: TextureRect = null
var title_label: Label = null
var close_button: Button = null

# Party member card containers (Slots 0..3)
var member_cards: Array[Control] = []
var member_avatar_rects: Array[TextureRect] = []
var member_name_labels: Array[Label] = []
var member_level_labels: Array[Label] = []
var member_element_rects: Array[TextureRect] = []
var member_leader_badges: Array[TextureRect] = []
var member_hp_bars: Array[ProgressBar] = []
var member_hp_labels: Array[Label] = []
var member_sp_bars: Array[ProgressBar] = []
var member_sp_labels: Array[Label] = []
var member_empty_labels: Array[Label] = []
var member_select_buttons: Array[Button] = []

# Companion section nodes (3 Cards: Slot 4 Active + Reserves)
var companion_cards: Array[Control] = []
var companion_avatar_rects: Array[TextureRect] = []
var companion_name_labels: Array[Label] = []
var companion_amity_labels: Array[Label] = []
var companion_hp_bars: Array[ProgressBar] = []
var companion_hp_labels: Array[Label] = []
var companion_sp_bars: Array[ProgressBar] = []
var companion_sp_labels: Array[Label] = []
var companion_status_labels: Array[Label] = []
var companion_summon_buttons: Array[Button] = []
var companion_ride_buttons: Array[Button] = []

# Controls of the real client's group window (docs/re/ui_windows.md): Party/Instance tabs,
# Battle/Ride/Dismiss buttons on every occupied row and a Close button at the bottom
var tab_buttons: Array[Button] = []
var row_battle_buttons: Array[Button] = []
var row_ride_buttons: Array[Button] = []
var row_dismiss_buttons: Array[Button] = []
var bottom_close_button: Button = null
var active_tab: int = 0

# Action buttons
var btn_leave_team: Button = null
var btn_dismiss_team: Button = null
var btn_assign_leader: Button = null

# Data state
var _hud: Control = null
var _is_building: bool = false
var _selected_member_slot: int = -1

var party_members: Array[Dictionary] = []
var active_companion: Dictionary = {}
var reserve_companions: Array[Dictionary] = []

func _init() -> void:
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	_init_default_data()

func _enter_tree() -> void:
	_init_default_data()
	_build_ui_if_needed()
	_refresh_all()

func _ready() -> void:
	_init_default_data()
	_build_ui_if_needed()
	_refresh_all()

func setup(hud: Control = null) -> void:
	_hud = hud
	_init_default_data()
	_build_ui_if_needed()
	_refresh_all()

func _init_default_data() -> void:
	if party_members.is_empty():
		# Slot 0 is local Player character (Leader)
		party_members.append({
			"name": "Daniel",
			"role_id": 6,
			"level": 10,
			"element": "Fire",
			"hp": 245,
			"max_hp": 245,
			"sp": 180,
			"max_sp": 180,
			"is_leader": true,
			"is_player": true
		})
	
	if active_companion.is_empty():
		active_companion = {
			"id": 8090,
			"npc_id": 8090,
			"name": "Roca",
			"title": "Chieftain's Daughter",
			"element": "Earth",
			"level": 12,
			"hp": 320,
			"max_hp": 320,
			"sp": 150,
			"max_sp": 150,
			"model_jmp": "1221.jmp",
			"talk_image": 8090,
			"sprite_id": 1221,
			"amity": 100,
			"is_summoned": false,
			"is_ridden": false
		}
	
	if reserve_companions.is_empty():
		reserve_companions.append({
			"id": 14062,
			"npc_id": 14062,
			"name": "Kelang",
			"title": "Village Leader",
			"element": "Fire",
			"level": 15,
			"hp": 450,
			"max_hp": 450,
			"sp": 200,
			"max_sp": 200,
			"model_jmp": "1131.jmp",
			"talk_image": 8038,
			"sprite_id": 1131,
			"amity": 100,
			"is_summoned": false,
			"is_ridden": false
		})
		reserve_companions.append({
			"id": 17162,
			"npc_id": 17162,
			"name": "S. Monkey",
			"title": "Curious Monkey",
			"element": "Water",
			"level": 8,
			"hp": 180,
			"max_hp": 180,
			"sp": 80,
			"max_sp": 80,
			"model_jmp": "1103.jmp",
			"talk_image": 0,
			"sprite_id": 1103,
			"amity": 85,
			"is_summoned": false,
			"is_ridden": false
		})

## Builds or binds UI controls
func _build_ui_if_needed() -> void:
	if _is_building:
		return
	_is_building = true

	# 1. Background
	background = get_node_or_null("Background") as TextureRect
	if not background:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
	background.position = Vector2.ZERO
	background.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_PASS

	if not background.texture:
		if ResourceLoader.exists("res://assets/hud/form_team_2.png"):
			background.texture = load("res://assets/hud/form_team_2.png")
		elif ResourceLoader.exists("res://assets/menu/Skins/white/Form_Team_2.bmp"):
			var st := Engine.get_main_loop() as SceneTree
			var loader: Node = st.root.get_node_or_null("ArchiveLoader") if (st and st.root) else null
			if loader and loader.has_method("get_ui_texture"):
				var tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_Team_2.bmp")
				if tex:
					background.texture = tex

	# 2. Title Label (Authentic skin has pre-rendered title, label is invisible by default)
	title_label = get_node_or_null("TitleLabel") as Label
	if not title_label:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		add_child(title_label)
	title_label.position = Vector2(20, 8)
	title_label.size = Vector2(160, 20)
	title_label.visible = false
	title_label.text = "Team [T]"

	# 3. Authentic 18x18 Close Button at Vector2(341, 8)
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

	# 4. Party Member Slots (4 Slots at y=68, 103, 137, 171)
	_build_party_member_slots()

	# 5. Companion Cards (3 Box Rows at y=262, 337, 412)
	_build_companion_cards()

	# 6. Bottom Action Buttons at y=504
	_build_action_buttons()

	# 7. Tabs, per-row buttons and Close as seen in the real client
	_build_real_client_controls()

	_is_building = false

## Builds the 4 party member cards in the upper section
func _build_party_member_slots() -> void:
	member_cards.clear()
	member_avatar_rects.clear()
	member_name_labels.clear()
	member_level_labels.clear()
	member_element_rects.clear()
	member_leader_badges.clear()
	member_hp_bars.clear()
	member_hp_labels.clear()
	member_sp_bars.clear()
	member_sp_labels.clear()
	member_empty_labels.clear()
	member_select_buttons.clear()

	var slot_y_positions: Array[float] = [68.0, 103.0, 137.0, 171.0]

	for i in range(MAX_MEMBERS):
		var card_name := "MemberCard_%d" % i
		var card := get_node_or_null(card_name) as Control
		if not card:
			card = Control.new()
			card.name = card_name
			add_child(card)
		card.position = Vector2(26.0, slot_y_positions[i])
		card.size = Vector2(314.0, 33.0)
		card.mouse_filter = Control.MOUSE_FILTER_PASS

		# Selection button overlay
		var btn := card.get_node_or_null("SelectBtn") as Button
		if not btn:
			btn = Button.new()
			btn.name = "SelectBtn"
			card.add_child(btn)
		btn.position = Vector2.ZERO
		btn.size = Vector2(314.0, 33.0)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_member_select_style(btn, false)
		var slot_idx: int = i
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		btn.pressed.connect(func() -> void: select_member_slot(slot_idx))

		# Small Avatar Rect
		var av := card.get_node_or_null("AvatarRect") as TextureRect
		if not av:
			av = TextureRect.new()
			av.name = "AvatarRect"
			card.add_child(av)
		av.position = Vector2(3.0, 3.0)
		av.size = Vector2(27.0, 27.0)
		av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Element Icon Rect
		var el := card.get_node_or_null("ElementRect") as TextureRect
		if not el:
			el = TextureRect.new()
			el.name = "ElementRect"
			card.add_child(el)
		el.position = Vector2(33.0, 8.0)
		el.size = Vector2(16.0, 16.0)
		el.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		el.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		el.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Name Label
		var n_lbl := card.get_node_or_null("NameLabel") as Label
		if not n_lbl:
			n_lbl = Label.new()
			n_lbl.name = "NameLabel"
			card.add_child(n_lbl)
		n_lbl.position = Vector2(52.0, 2.0)
		n_lbl.size = Vector2(90.0, 16.0)
		_apply_wlo_typography(n_lbl, 11, Color(1.0, 0.98, 0.92, 1.0))
		n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Level Label
		var lv_lbl := card.get_node_or_null("LevelLabel") as Label
		if not lv_lbl:
			lv_lbl = Label.new()
			lv_lbl.name = "LevelLabel"
			card.add_child(lv_lbl)
		lv_lbl.position = Vector2(52.0, 17.0)
		lv_lbl.size = Vector2(90.0, 14.0)
		_apply_wlo_typography(lv_lbl, 10, Color(1.0, 0.88, 0.45, 1.0))
		lv_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Authentic OrgLeader.bmp Badge
		var l_bdg := card.get_node_or_null("LeaderBadge") as TextureRect
		if not l_bdg:
			l_bdg = TextureRect.new()
			l_bdg.name = "LeaderBadge"
			card.add_child(l_bdg)
		l_bdg.position = Vector2(100.0, 17.0)
		l_bdg.size = Vector2(44.0, 14.0)
		l_bdg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		l_bdg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		l_bdg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists("res://assets/hud/org_leader_badge.png"):
			l_bdg.texture = load("res://assets/hud/org_leader_badge.png")

		# HP Bar & Label
		var hp_bar := card.get_node_or_null("HpBar") as ProgressBar
		if not hp_bar:
			hp_bar = ProgressBar.new()
			hp_bar.name = "HpBar"
			card.add_child(hp_bar)
		hp_bar.position = Vector2(150.0, 8.0)
		hp_bar.size = Vector2(60.0, 6.0)
		hp_bar.show_percentage = false
		hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_textured_bar_style(hp_bar, "hp")

		var hp_lbl := card.get_node_or_null("HpLabel") as Label
		if not hp_lbl:
			hp_lbl = Label.new()
			hp_lbl.name = "HpLabel"
			card.add_child(hp_lbl)
		hp_lbl.position = Vector2(150.0, 8.0)
		hp_lbl.size = Vector2(60.0, 6.0)
		hp_lbl.modulate.a = 0.0 # the real row shows bars only
		_apply_wlo_typography(hp_lbl, 9, Color(0.95, 0.95, 0.95, 1.0))
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# SP Bar & Label
		var sp_bar := card.get_node_or_null("SpBar") as ProgressBar
		if not sp_bar:
			sp_bar = ProgressBar.new()
			sp_bar.name = "SpBar"
			card.add_child(sp_bar)
		sp_bar.position = Vector2(150.0, 18.0)
		sp_bar.size = Vector2(60.0, 6.0)
		sp_bar.show_percentage = false
		sp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_textured_bar_style(sp_bar, "sp")

		var sp_lbl := card.get_node_or_null("SpLabel") as Label
		if not sp_lbl:
			sp_lbl = Label.new()
			sp_lbl.name = "SpLabel"
			card.add_child(sp_lbl)
		sp_lbl.position = Vector2(150.0, 18.0)
		sp_lbl.size = Vector2(60.0, 6.0)
		sp_lbl.modulate.a = 0.0
		_apply_wlo_typography(sp_lbl, 9, Color(0.95, 0.95, 0.95, 1.0))
		sp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Empty Slot Placeholder Label
		var emp_lbl := card.get_node_or_null("EmptyLabel") as Label
		if not emp_lbl:
			emp_lbl = Label.new()
			emp_lbl.name = "EmptyLabel"
			card.add_child(emp_lbl)
		emp_lbl.position = Vector2(10.0, 6.0)
		emp_lbl.size = Vector2(294.0, 20.0)
		emp_lbl.text = "-- (Empty Slot) --"
		_apply_wlo_typography(emp_lbl, 11, Color(0.65, 0.7, 0.8, 0.85))
		emp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		member_cards.append(card)
		member_avatar_rects.append(av)
		member_element_rects.append(el)
		member_name_labels.append(n_lbl)
		member_level_labels.append(lv_lbl)
		member_leader_badges.append(l_bdg)
		member_hp_bars.append(hp_bar)
		member_hp_labels.append(hp_lbl)
		member_sp_bars.append(sp_bar)
		member_sp_labels.append(sp_lbl)
		member_empty_labels.append(emp_lbl)
		member_select_buttons.append(btn)

## Builds the 3 companion cards in the lower section (y=262, 337, 412)
func _build_companion_cards() -> void:
	companion_cards.clear()
	companion_avatar_rects.clear()
	companion_name_labels.clear()
	companion_amity_labels.clear()
	companion_hp_bars.clear()
	companion_hp_labels.clear()
	companion_sp_bars.clear()
	companion_sp_labels.clear()
	companion_status_labels.clear()
	companion_summon_buttons.clear()

	var comp_y_positions: Array[float] = [262.0, 337.0, 412.0]

	for i in range(3):
		var card_name := "CompanionCard_%d" % i
		var card := get_node_or_null(card_name) as Control
		if not card:
			card = Control.new()
			card.name = card_name
			add_child(card)
		card.position = Vector2(26.0, comp_y_positions[i])
		card.size = Vector2(314.0, 70.0)
		card.mouse_filter = Control.MOUSE_FILTER_PASS

		# Avatar Rect (68x68) on left aperture
		var av := card.get_node_or_null("AvatarRect") as TextureRect
		if not av:
			av = TextureRect.new()
			av.name = "AvatarRect"
			card.add_child(av)
		av.position = Vector2(1.0, 1.0)
		av.size = Vector2(68.0, 68.0)
		av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Name & Level Label
		var n_lbl := card.get_node_or_null("NameLabel") as Label
		if not n_lbl:
			n_lbl = Label.new()
			n_lbl.name = "NameLabel"
			card.add_child(n_lbl)
		n_lbl.position = Vector2(74.0, 4.0)
		n_lbl.size = Vector2(156.0, 18.0)
		_apply_wlo_typography(n_lbl, 12, Color(1.0, 0.98, 0.92, 1.0))
		n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Amity Label
		var am_lbl := card.get_node_or_null("AmityLabel") as Label
		if not am_lbl:
			am_lbl = Label.new()
			am_lbl.name = "AmityLabel"
			card.add_child(am_lbl)
		am_lbl.position = Vector2(74.0, 22.0)
		am_lbl.size = Vector2(150.0, 16.0)
		_apply_wlo_typography(am_lbl, 10, Color(1.0, 0.85, 0.4, 1.0))
		am_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# HP Bar & Label
		var hp_bar := card.get_node_or_null("HpBar") as ProgressBar
		if not hp_bar:
			hp_bar = ProgressBar.new()
			hp_bar.name = "HpBar"
			card.add_child(hp_bar)
		hp_bar.position = Vector2(74.0, 40.0)
		hp_bar.size = Vector2(72.0, 10.0)
		hp_bar.show_percentage = false
		hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_textured_bar_style(hp_bar, "hp")

		var hp_lbl := card.get_node_or_null("HpLabel") as Label
		if not hp_lbl:
			hp_lbl = Label.new()
			hp_lbl.name = "HpLabel"
			card.add_child(hp_lbl)
		hp_lbl.position = Vector2(74.0, 52.0)
		hp_lbl.size = Vector2(72.0, 14.0)
		_apply_wlo_typography(hp_lbl, 9, Color(0.95, 0.95, 0.95, 1.0))
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# SP Bar & Label
		var sp_bar := card.get_node_or_null("SpBar") as ProgressBar
		if not sp_bar:
			sp_bar = ProgressBar.new()
			sp_bar.name = "SpBar"
			card.add_child(sp_bar)
		sp_bar.position = Vector2(150.0, 40.0)
		sp_bar.size = Vector2(72.0, 10.0)
		sp_bar.show_percentage = false
		sp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_textured_bar_style(sp_bar, "sp")

		var sp_lbl := card.get_node_or_null("SpLabel") as Label
		if not sp_lbl:
			sp_lbl = Label.new()
			sp_lbl.name = "SpLabel"
			card.add_child(sp_lbl)
		sp_lbl.position = Vector2(150.0, 52.0)
		sp_lbl.size = Vector2(72.0, 14.0)
		_apply_wlo_typography(sp_lbl, 9, Color(0.95, 0.95, 0.95, 1.0))
		sp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Status Label
		var st_lbl := card.get_node_or_null("StatusLabel") as Label
		if not st_lbl:
			st_lbl = Label.new()
			st_lbl.name = "StatusLabel"
			card.add_child(st_lbl)
		st_lbl.position = Vector2(236.0, 14.0)
		st_lbl.size = Vector2(71.0, 16.0)
		_apply_wlo_typography(st_lbl, 10, Color(0.4, 0.9, 0.45, 1.0))
		st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Authentic Sliced Toggle Button: Btn_AssignFight_1 / Btn_AssignRest_1
		var sm_btn := card.get_node_or_null("SummonBtn") as Button
		if not sm_btn:
			sm_btn = Button.new()
			sm_btn.name = "SummonBtn"
			card.add_child(sm_btn)
		sm_btn.position = Vector2(250.0, 36.0)
		sm_btn.size = Vector2(43.0, 20.0)
		sm_btn.custom_minimum_size = Vector2(43.0, 20.0)
		sm_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		sm_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		sm_btn.flat = true
		sm_btn.text = ""
		_apply_companion_toggle_textures(sm_btn, false)

		var c_idx: int = i
		for conn in sm_btn.pressed.get_connections():
			sm_btn.pressed.disconnect(conn.callable)
		sm_btn.pressed.connect(func() -> void: _on_companion_card_button_pressed(c_idx))

		# Authentic Ride Button: Btn_AssignRide_1
		var rd_btn := card.get_node_or_null("RideBtn") as Button
		if not rd_btn:
			rd_btn = Button.new()
			rd_btn.name = "RideBtn"
			card.add_child(rd_btn)
		rd_btn.position = Vector2(250.0, 12.0)
		rd_btn.size = Vector2(43.0, 20.0)
		rd_btn.custom_minimum_size = Vector2(43.0, 20.0)
		rd_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		rd_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		rd_btn.flat = true
		rd_btn.text = ""
		_apply_ride_button_textures(rd_btn, false)

		var ride_c_idx: int = i
		for conn in rd_btn.pressed.get_connections():
			rd_btn.pressed.disconnect(conn.callable)
		rd_btn.pressed.connect(func() -> void: _on_companion_card_ride_pressed(ride_c_idx))

		companion_cards.append(card)
		companion_avatar_rects.append(av)
		companion_name_labels.append(n_lbl)
		companion_amity_labels.append(am_lbl)
		companion_hp_bars.append(hp_bar)
		companion_hp_labels.append(hp_lbl)
		companion_sp_bars.append(sp_bar)
		companion_sp_labels.append(sp_lbl)
		companion_status_labels.append(st_lbl)
		companion_summon_buttons.append(sm_btn)
		companion_ride_buttons.append(rd_btn)

## Builds bottom action buttons using authentic sliced BMP assets
func _build_action_buttons() -> void:
	# 1. Leave Team (x=26, y=504, size=71x20)
	btn_leave_team = get_node_or_null("BtnLeaveTeam") as Button
	if not btn_leave_team:
		btn_leave_team = Button.new()
		btn_leave_team.name = "BtnLeaveTeam"
		add_child(btn_leave_team)
	btn_leave_team.position = Vector2(26.0, 504.0)
	btn_leave_team.size = Vector2(71.0, 20.0)
	btn_leave_team.custom_minimum_size = Vector2(71.0, 20.0)
	btn_leave_team.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_leave_team.flat = true
	btn_leave_team.text = ""
	btn_leave_team.tooltip_text = "Leave current party"
	_apply_action_button_textures(btn_leave_team, "btn_leave_team")
	for conn in btn_leave_team.pressed.get_connections():
		btn_leave_team.pressed.disconnect(conn.callable)
	btn_leave_team.pressed.connect(leave_team)

	# 2. Dismiss Member (x=150, y=504, size=71x20)
	btn_dismiss_team = get_node_or_null("BtnDismissTeam") as Button
	if not btn_dismiss_team:
		btn_dismiss_team = Button.new()
		btn_dismiss_team.name = "BtnDismissTeam"
		add_child(btn_dismiss_team)
	btn_dismiss_team.position = Vector2(150.0, 504.0)
	btn_dismiss_team.size = Vector2(71.0, 20.0)
	btn_dismiss_team.custom_minimum_size = Vector2(71.0, 20.0)
	btn_dismiss_team.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_dismiss_team.flat = true
	btn_dismiss_team.text = ""
	btn_dismiss_team.tooltip_text = "Dismiss selected member from party"
	_apply_action_button_textures(btn_dismiss_team, "btn_dismiss_team")
	for conn in btn_dismiss_team.pressed.get_connections():
		btn_dismiss_team.pressed.disconnect(conn.callable)
	btn_dismiss_team.pressed.connect(dismiss_selected_member)

	# 3. Promote Leader (x=274, y=504, size=71x20)
	btn_assign_leader = get_node_or_null("BtnAssignLeader") as Button
	if not btn_assign_leader:
		btn_assign_leader = Button.new()
		btn_assign_leader.name = "BtnAssignLeader"
		add_child(btn_assign_leader)
	btn_assign_leader.position = Vector2(274.0, 504.0)
	btn_assign_leader.size = Vector2(71.0, 20.0)
	btn_assign_leader.custom_minimum_size = Vector2(71.0, 20.0)
	btn_assign_leader.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_assign_leader.flat = true
	btn_assign_leader.text = ""
	btn_assign_leader.tooltip_text = "Promote selected member to party leader"
	_apply_action_button_textures(btn_assign_leader, "btn_assign_leader")
	for conn in btn_assign_leader.pressed.get_connections():
		btn_assign_leader.pressed.disconnect(conn.callable)
	btn_assign_leader.pressed.connect(func() -> void:
		if _selected_member_slot > 0:
			promote_leader(_selected_member_slot)
	)

## Refreshes all UI displays (members, companions, action buttons)
func _refresh_all() -> void:
	_refresh_member_slots()
	_refresh_companion_cards()
	_refresh_action_buttons()
	_refresh_real_client_controls()


## Small pill button of the real client; its caption is a child label so the button keeps the exact size
## given (a Button's own text would inflate it to the font's line height).
func _make_pill(caption: String, pos: Vector2, pill_size: Vector2) -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = pill_size
	btn.custom_minimum_size = pill_size
	btn.clip_contents = true
	btn.text = ""
	_style_pill_button(btn)
	var label := Label.new()
	label.name = "Caption"
	label.text = caption
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.24, 0.3, 0.55, 1.0))
	btn.add_child(label)
	return btn


func _style_pill_button(btn: Button, active: bool = false) -> void:
	var fill := Color(0.86, 0.92, 1.0, 1.0) if not active else Color(1.0, 1.0, 1.0, 1.0)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = fill if state != "hover" else Color(0.93, 0.97, 1.0, 1.0)
		box.border_color = Color(0.42, 0.52, 0.76, 1.0)
		box.set_border_width_all(1)
		box.set_corner_radius_all(3)
		box.set_content_margin_all(0.0)
		btn.add_theme_stylebox_override(state, box)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _build_real_client_controls() -> void:
	if not tab_buttons.is_empty():
		return
	# The old bottom buttons are not part of the real window; they stay available to code only.
	for old_btn in [btn_leave_team, btn_dismiss_team, btn_assign_leader]:
		if old_btn:
			old_btn.visible = false
	var tab_specs := [["Party", Vector2(20, 48), Vector2(60, 20)], ["Instance", Vector2(83, 48), Vector2(67, 20)]]
	for i in tab_specs.size():
		var tab := _make_pill(tab_specs[i][0], tab_specs[i][1], tab_specs[i][2])
		tab.name = "Tab%s" % tab_specs[i][0]
		var tab_idx: int = i
		tab.pressed.connect(func() -> void:
			active_tab = tab_idx
			_refresh_real_client_controls())
		add_child(tab)
		tab_buttons.append(tab)
	for i in MAX_MEMBERS:
		var card: Control = member_cards[i]
		var battle := _make_pill("Battle", Vector2(178, 8), Vector2(40, 18))
		battle.name = "BtnRowBattle_%d" % i
		card.add_child(battle)
		var ride := _make_pill("Ride", Vector2(221, 8), Vector2(38, 18))
		ride.name = "BtnRowRide_%d" % i
		card.add_child(ride)
		var dismiss := _make_pill("Dismiss", Vector2(262, 8), Vector2(46, 18))
		dismiss.name = "BtnRowDismiss_%d" % i
		var slot_idx: int = i
		battle.pressed.connect(func() -> void: _on_pet_row_button(slot_idx, "battle"))
		ride.pressed.connect(func() -> void: _on_pet_row_button(slot_idx, "ride"))
		dismiss.pressed.connect(func() -> void: _on_pet_row_button(slot_idx, "dismiss"))
		card.add_child(dismiss)
		row_battle_buttons.append(battle)
		row_ride_buttons.append(ride)
		row_dismiss_buttons.append(dismiss)
	bottom_close_button = _make_pill("Close", Vector2(155, 491), Vector2(60, 20))
	bottom_close_button.name = "BtnBottomClose"
	bottom_close_button.pressed.connect(close_window)
	add_child(bottom_close_button)
	_refresh_real_client_controls()


## Battle sends the pet into the fight (or rests if already in battle).
## Ride mounts the pet for overland traversal.
## Dismiss puts it back to rest.
## Enforces strictly ONE pet active in Battle or Ride mode at any time.
func _on_pet_row_button(row: int, action: Variant = "battle") -> void:
	var action_str: String = "battle"
	if action is bool:
		action_str = "battle" if action else "dismiss"
	elif action is String:
		action_str = (action as String).to_lower()

	var pets: Array[Dictionary] = _pet_entries()
	if row >= pets.size():
		return
	var pet: Dictionary = pets[row]
	var pet_id: int = int(pet.get("id", pet.get("npc_id", 0)))
	var summoned: bool = bool(pet.get("is_summoned", false))
	var ridden: bool = bool(pet.get("is_ridden", false))

	match action_str:
		"battle":
			if summoned:
				toggle_companion_summon(pet_id)
			elif ridden:
				dismount_companion()
				toggle_companion_summon(pet_id)
			else:
				dismount_companion()
				toggle_companion_summon(pet_id)
		"ride":
			if ridden:
				dismount_companion()
			else:
				if summoned:
					toggle_companion_summon(pet_id)
				mount_companion(pet_id)
		"dismiss":
			if summoned:
				toggle_companion_summon(pet_id)
			if ridden:
				dismount_companion()
	_refresh_real_client_controls()


func _refresh_real_client_controls() -> void:
	for i in tab_buttons.size():
		_style_pill_button(tab_buttons[i], i == active_tab)
	var pets: Array[Dictionary] = _pet_entries()
	for i in MAX_MEMBERS:
		if i >= member_cards.size() or i >= row_battle_buttons.size():
			continue
		var has_member: bool = i < pets.size()
		member_cards[i].visible = active_tab == 0
		row_battle_buttons[i].visible = has_member
		if i < row_ride_buttons.size():
			row_ride_buttons[i].visible = has_member
		row_dismiss_buttons[i].visible = has_member
		if has_member:
			var pet: Dictionary = pets[i]
			var is_sum: bool = bool(pet.get("is_summoned", false))
			var is_rid: bool = bool(pet.get("is_ridden", false))

			# Battle / Rest button
			var btn := row_battle_buttons[i]
			var caption_lbl := btn.get_node_or_null("Caption") as Label
			var btn_txt := "Rest" if is_sum else "Battle"
			btn.text = btn_txt
			if caption_lbl:
				caption_lbl.text = btn_txt
				if is_sum:
					caption_lbl.add_theme_color_override("font_color", Color(0.1, 0.45, 0.15, 1.0))
				else:
					caption_lbl.add_theme_color_override("font_color", Color(0.24, 0.3, 0.55, 1.0))
			_style_pill_button(btn, is_sum)

			# Ride / Dismount button
			if i < row_ride_buttons.size():
				var r_btn := row_ride_buttons[i]
				var r_caption := r_btn.get_node_or_null("Caption") as Label
				var r_txt := "Dismount" if is_rid else "Ride"
				r_btn.text = r_txt
				if r_caption:
					r_caption.text = r_txt
					if is_rid:
						r_caption.add_theme_color_override("font_color", Color(0.1, 0.45, 0.15, 1.0))
					else:
						r_caption.add_theme_color_override("font_color", Color(0.24, 0.3, 0.55, 1.0))
				_style_pill_button(r_btn, is_rid)

		if i < member_empty_labels.size():
			member_empty_labels[i].text = ""

## The real client lists the player's pets in the top table (with Battle / Dismiss buttons) and the
## teammates in the boxes of the lower "status" section.
func _pet_entries() -> Array[Dictionary]:
	var pets: Array[Dictionary] = []
	if not active_companion.is_empty():
		pets.append(active_companion)
	for rc in reserve_companions:
		if not rc.is_empty():
			pets.append(rc)
	return pets.slice(0, MAX_MEMBERS)


func _teammate_entries() -> Array[Dictionary]:
	var mates: Array[Dictionary] = []
	for i in range(1, party_members.size()):
		if not party_members[i].is_empty():
			mates.append(party_members[i])
	return mates.slice(0, 3)


func _refresh_member_slots() -> void:
	_refresh_pet_rows()
	_refresh_teammate_cards()


func _refresh_companion_cards() -> void:
	_refresh_pet_rows()
	_refresh_teammate_cards()


## Refreshes the 4 pet rows of the top table
func _refresh_pet_rows() -> void:
	var pets: Array[Dictionary] = _pet_entries()
	for i in range(MAX_MEMBERS):
		var has_member: bool = i < pets.size()
		var card := member_cards[i] if i < member_cards.size() else null
		if not card:
			continue

		var av := member_avatar_rects[i]
		var el := member_element_rects[i]
		var n_lbl := member_name_labels[i]
		var lv_lbl := member_level_labels[i]
		var l_bdg := member_leader_badges[i]
		var hp_bar := member_hp_bars[i]
		var hp_lbl := member_hp_labels[i]
		var sp_bar := member_sp_bars[i]
		var sp_lbl := member_sp_labels[i]
		var emp_lbl := member_empty_labels[i]
		var sel_btn := member_select_buttons[i]

		if has_member:
			var m: Dictionary = pets[i]
			emp_lbl.visible = false
			av.visible = true
			el.visible = true
			n_lbl.visible = true
			lv_lbl.visible = true
			hp_bar.visible = true
			hp_lbl.visible = true
			sp_bar.visible = true
			sp_lbl.visible = true

			# Avatar
			av.texture = _resolve_companion_avatar(int(m.get("id", m.get("npc_id", 0))), str(m.get("name", "")))

			# Element badge
			el.texture = _resolve_element_icon(m.get("element", "Fire"))

			# Labels
			n_lbl.text = str(m.get("name", "Player"))
			lv_lbl.text = "Lv. %d" % int(m.get("level", 1))

			# Leader badge
			l_bdg.visible = false

			# HP/SP
			var cur_hp: int = int(m.get("hp", 100))
			var max_hp: int = int(m.get("max_hp", 100))
			var cur_sp: int = int(m.get("sp", 50))
			var max_sp: int = int(m.get("max_sp", 50))

			hp_bar.max_value = max(1, max_hp)
			hp_bar.value = cur_hp
			hp_lbl.text = "%d/%d" % [cur_hp, max_hp]

			sp_bar.max_value = max(1, max_sp)
			sp_bar.value = cur_sp
			sp_lbl.text = "%d/%d" % [cur_sp, max_sp]

			_apply_member_select_style(sel_btn, (_selected_member_slot == i))
		else:
			emp_lbl.visible = true
			av.visible = false
			el.visible = false
			n_lbl.visible = false
			lv_lbl.visible = false
			l_bdg.visible = false
			hp_bar.visible = false
			hp_lbl.visible = false
			sp_bar.visible = false
			sp_lbl.visible = false
			_apply_member_select_style(sel_btn, false)

## Refreshes the 3 boxes of the lower section with the teammates (slots 1..3 of the party)
func _refresh_teammate_cards() -> void:
	var mates: Array[Dictionary] = _teammate_entries()
	for i in range(3):
		if i >= companion_cards.size():
			continue
		var card := companion_cards[i]
		card.visible = true
		var filled: bool = i < mates.size()
		for child in card.get_children():
			if child is CanvasItem:
				child.visible = filled
		var sm_btn := companion_summon_buttons[i]
		sm_btn.visible = false
		if i < companion_ride_buttons.size():
			companion_ride_buttons[i].visible = false
		if not filled:
			continue
		var m: Dictionary = mates[i]
		companion_avatar_rects[i].texture = _resolve_role_avatar(int(m.get("role_id", 6)))
		companion_name_labels[i].text = "%s - Lv. %d (%s)" % [str(m.get("name", "Player")), int(m.get("level", 1)), str(m.get("element", "Neutral"))]
		companion_amity_labels[i].text = "Leader" if bool(m.get("is_leader", false)) else ""
		var max_hp: int = int(m.get("max_hp", 100))
		var max_sp: int = int(m.get("max_sp", 50))
		companion_hp_bars[i].max_value = max(1, max_hp)
		companion_hp_bars[i].value = int(m.get("hp", max_hp))
		companion_hp_labels[i].text = "%d/%d" % [int(m.get("hp", max_hp)), max_hp]
		companion_sp_bars[i].max_value = max(1, max_sp)
		companion_sp_bars[i].value = int(m.get("sp", max_sp))
		companion_sp_labels[i].text = "%d/%d" % [int(m.get("sp", max_sp)), max_sp]
		companion_status_labels[i].text = ""


## Refreshes action buttons enablement state
func _refresh_action_buttons() -> void:
	var is_member_selected: bool = (_selected_member_slot > 0 and _selected_member_slot < party_members.size())
	if btn_dismiss_team:
		btn_dismiss_team.disabled = not is_member_selected
		btn_dismiss_team.modulate = Color(1, 1, 1, 1) if is_member_selected else Color(0.5, 0.5, 0.5, 0.6)
	if btn_assign_leader:
		btn_assign_leader.disabled = not is_member_selected
		btn_assign_leader.modulate = Color(1, 1, 1, 1) if is_member_selected else Color(0.5, 0.5, 0.5, 0.6)

# --- Public API & Actions ---

## Sets the local player character data into Slot 0
func set_player_data(char_data: Dictionary) -> void:
	if party_members.is_empty():
		party_members.append({})
	var p: Dictionary = party_members[0]
	for k in char_data.keys():
		p[k] = char_data[k]
	p["is_leader"] = p.get("is_leader", true)
	p["is_player"] = true
	party_members[0] = p
	_refresh_member_slots()

## Overwrites full party member list
func set_party_members(members: Array[Dictionary]) -> void:
	party_members.clear()
	for i in range(min(MAX_MEMBERS, members.size())):
		party_members.append(members[i].duplicate(true))
	if not party_members.is_empty():
		party_members[0]["is_leader"] = true
	_selected_member_slot = -1
	_refresh_member_slots()
	_refresh_action_buttons()

## Adds a new party member into the first open slot
func add_party_member(member: Dictionary) -> bool:
	if party_members.size() >= MAX_MEMBERS:
		return false
	var m := member.duplicate(true)
	m["is_leader"] = (party_members.is_empty())
	party_members.append(m)
	_refresh_member_slots()
	_refresh_action_buttons()
	return true

## Removes a member at slot_idx
func remove_party_member(slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= party_members.size():
		return false
	var dismissed: Dictionary = party_members[slot_idx]
	party_members.remove_at(slot_idx)
	if _selected_member_slot == slot_idx:
		_selected_member_slot = -1
	elif _selected_member_slot > slot_idx:
		_selected_member_slot -= 1
	if not party_members.is_empty():
		party_members[0]["is_leader"] = true
	_refresh_member_slots()
	_refresh_action_buttons()
	member_dismissed.emit(slot_idx, dismissed)
	return true

## Selects a member slot for dismissal or leader promotion
func select_member_slot(slot_idx: int) -> void:
	AuthAudioScript.play_click()
	if slot_idx == _selected_member_slot:
		_selected_member_slot = -1
	else:
		_selected_member_slot = slot_idx
	_refresh_member_slots()
	_refresh_action_buttons()
	var m_data := party_members[slot_idx] if (slot_idx >= 0 and slot_idx < party_members.size()) else {}
	member_selected.emit(slot_idx, m_data)

## Dismisses the currently selected member (Slot 1..3)
func dismiss_selected_member() -> bool:
	if _selected_member_slot <= 0 or _selected_member_slot >= party_members.size():
		return false
	AuthAudioScript.play_click()
	return remove_party_member(_selected_member_slot)

## Promotes a member to Party Leader (swaps into Slot 0)
func promote_leader(slot_idx: int) -> bool:
	if slot_idx <= 0 or slot_idx >= party_members.size():
		return false
	AuthAudioScript.play_click()
	var old_leader := party_members[0]
	var new_leader := party_members[slot_idx]
	old_leader["is_leader"] = false
	new_leader["is_leader"] = true
	party_members[0] = new_leader
	party_members[slot_idx] = old_leader
	_selected_member_slot = -1
	_refresh_member_slots()
	_refresh_action_buttons()
	leader_promoted.emit(0, new_leader)
	return true

## Leaves current team (disbands party or removes player)
func leave_team() -> void:
	AuthAudioScript.play_click()
	if party_members.size() > 1:
		var player_member := party_members[0]
		party_members.clear()
		party_members.append(player_member)
	_selected_member_slot = -1
	_refresh_member_slots()
	_refresh_action_buttons()
	team_left.emit()

## Sets primary active companion
func set_active_companion(companion_data: Dictionary) -> void:
	active_companion = companion_data.duplicate(true)
	_refresh_companion_cards()

## Sets list of reserve companions
func set_reserve_companions(companions: Array[Dictionary]) -> void:
	reserve_companions.clear()
	for c in companions:
		reserve_companions.append(c.duplicate(true))
	_refresh_companion_cards()

## Toggles summon/rest on active companion or a specific companion_id
func toggle_companion_summon(companion_id: int = 0) -> bool:
	AuthAudioScript.play_click()
	var target_comp: Dictionary = {}
	var target_idx: int = -1

	var all_comps: Array[Dictionary] = []
	if not active_companion.is_empty():
		all_comps.append(active_companion)
	for rc in reserve_companions:
		all_comps.append(rc)

	if companion_id == 0:
		if not active_companion.is_empty():
			target_comp = active_companion
			target_idx = 0
	else:
		for i in range(all_comps.size()):
			var cid: int = int(all_comps[i].get("id", all_comps[i].get("npc_id", 0)))
			if cid == companion_id:
				target_comp = all_comps[i]
				target_idx = i
				break

	if target_comp.is_empty():
		return false

	var was_summoned: bool = bool(target_comp.get("is_summoned", false))
	var new_summoned: bool = not was_summoned

	# If summoning, recall any other currently summoned companion
	if new_summoned:
		for c in all_comps:
			if bool(c.get("is_ridden", false)):
				c["is_ridden"] = false
				companion_dismounted.emit(c)
				companion_ride_toggled.emit(false)
			if c != target_comp and bool(c.get("is_summoned", false)):
				c["is_summoned"] = false
				var old_id: int = int(c.get("id", c.get("npc_id", 0)))
				companion_toggled.emit(old_id, false)
				companion_recalled.emit(old_id)

	target_comp["is_summoned"] = new_summoned
	target_comp["is_ridden"] = false

	# If summoned companion was in reserves, make it active companion
	if target_idx > 0 and new_summoned:
		var prev_active := active_companion
		active_companion = target_comp
		reserve_companions.remove_at(target_idx - 1)
		reserve_companions.insert(0, prev_active)

	var cid: int = int(target_comp.get("id", target_comp.get("npc_id", 0)))
	var cname: String = str(target_comp.get("name", "Companion"))

	companion_toggled.emit(cid, new_summoned)
	if new_summoned:
		companion_summoned.emit(cid, cname)
	else:
		companion_recalled.emit(cid)

	_refresh_companion_cards()
	_refresh_real_client_controls()
	return new_summoned

## Checks if active companion is summoned
func is_companion_summoned() -> bool:
	return bool(active_companion.get("is_summoned", false))

## Checks if active companion or a specific companion is currently mounted in Ride mode
func is_companion_ridden(companion_id: int = -1) -> bool:
	if companion_id == -1:
		return bool(active_companion.get("is_ridden", false))
	var a_id: int = int(active_companion.get("id", active_companion.get("npc_id", 0)))
	if a_id == companion_id:
		return bool(active_companion.get("is_ridden", false))
	for rc in reserve_companions:
		var r_id: int = int(rc.get("id", rc.get("npc_id", 0)))
		if r_id == companion_id:
			return bool(rc.get("is_ridden", false))
	return false

## Returns dictionary of currently mounted companion or empty dictionary
func get_ridden_companion() -> Dictionary:
	if bool(active_companion.get("is_ridden", false)):
		return active_companion
	for rc in reserve_companions:
		if bool(rc.get("is_ridden", false)):
			return rc
	return {}

## Mounts a companion into Ride mode, enforcing single pet mutual exclusion
func mount_companion(companion_id: int = -1) -> bool:
	AuthAudioScript.play_click()
	if companion_id == -1:
		companion_id = int(active_companion.get("id", active_companion.get("npc_id", 0)))

	# Mutual exclusion: recall any companion in battle
	var all_comps: Array[Dictionary] = []
	if not active_companion.is_empty():
		all_comps.append(active_companion)
	for rc in reserve_companions:
		all_comps.append(rc)

	for c in all_comps:
		if bool(c.get("is_summoned", false)):
			c["is_summoned"] = false
			var old_id: int = int(c.get("id", c.get("npc_id", 0)))
			companion_toggled.emit(old_id, false)
			companion_recalled.emit(old_id)
		c["is_ridden"] = false

	var target_found: bool = false
	var target_comp: Dictionary = {}
	var target_idx: int = -1

	if companion_id == 0:
		if not active_companion.is_empty():
			target_comp = active_companion
			target_idx = 0
			target_found = true
	else:
		for i in range(all_comps.size()):
			var cid: int = int(all_comps[i].get("id", all_comps[i].get("npc_id", 0)))
			if cid == companion_id:
				target_comp = all_comps[i]
				target_idx = i
				target_found = true
				break

	if not target_found or target_comp.is_empty():
		return false

	target_comp["is_ridden"] = true
	target_comp["is_summoned"] = false

	# If ridden companion was in reserves, make it active companion
	if target_idx > 0:
		var prev_active := active_companion
		active_companion = target_comp
		reserve_companions.remove_at(target_idx - 1)
		reserve_companions.insert(0, prev_active)

	companion_mounted.emit(target_comp)
	companion_ride_toggled.emit(true)

	_refresh_companion_cards()
	_refresh_real_client_controls()
	return true

## Dismounts any currently mounted companion
func dismount_companion() -> void:
	AuthAudioScript.play_click()
	var was_ridden := false
	var pet_dict: Dictionary = {}
	if bool(active_companion.get("is_ridden", false)):
		active_companion["is_ridden"] = false
		was_ridden = true
		pet_dict = active_companion
	for rc in reserve_companions:
		if bool(rc.get("is_ridden", false)):
			rc["is_ridden"] = false
			was_ridden = true
			if pet_dict.is_empty():
				pet_dict = rc
	if was_ridden:
		companion_dismounted.emit(pet_dict)
		companion_ride_toggled.emit(false)
	_refresh_companion_cards()
	_refresh_real_client_controls()

## Toggles between mounting and dismounting the companion
func toggle_companion_ride(companion_id: int = -1) -> bool:
	if companion_id == -1:
		companion_id = int(active_companion.get("id", active_companion.get("npc_id", 0)))
	if is_companion_ridden(companion_id):
		dismount_companion()
		return false
	else:
		return mount_companion(companion_id)

func _on_companion_card_ride_pressed(card_idx: int) -> void:
	var all_comps: Array[Dictionary] = []
	if not active_companion.is_empty():
		all_comps.append(active_companion)
	for rc in reserve_companions:
		all_comps.append(rc)

	if card_idx < all_comps.size():
		var cid: int = int(all_comps[card_idx].get("id", all_comps[card_idx].get("npc_id", 0)))
		toggle_companion_ride(cid)

func _on_companion_card_button_pressed(card_idx: int) -> void:
	var all_comps: Array[Dictionary] = []
	if not active_companion.is_empty():
		all_comps.append(active_companion)
	for rc in reserve_companions:
		all_comps.append(rc)

	if card_idx < all_comps.size():
		var cid: int = int(all_comps[card_idx].get("id", all_comps[card_idx].get("npc_id", 0)))
		toggle_companion_summon(cid)

func close_window() -> void:
	AuthAudioScript.play_click()
	visible = false
	window_closed.emit()

func open_window() -> void:
	AuthAudioScript.play_click()
	visible = true
	move_to_front()
	_refresh_all()

func toggle_window() -> void:
	if visible:
		close_window()
	else:
		open_window()

# --- Authentic Texture & Styling Helpers ---

func _apply_wlo_typography(label: Label, size_px: int, text_color: Color) -> void:
	if not label: return
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

func _resolve_role_avatar(role_id: int) -> Texture2D:
	var path := "res://assets/hud/avatar_role_%d_0.png" % role_id
	if ResourceLoader.exists(path):
		return load(path)
	var fallback := "res://assets/hud/avatar_role_6_0.png"
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return null

func _resolve_element_icon(element: Variant) -> Texture2D:
	var el_id: int = 1
	if element is int:
		el_id = element
	elif element is String:
		match element.to_lower():
			"earth": el_id = 1
			"water": el_id = 2
			"fire": el_id = 3
			"wind": el_id = 4
			_: el_id = 1
	var path := "res://assets/hud/icon_element_%d.png" % el_id
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _resolve_companion_avatar(npc_id: int, companion_name: String) -> Texture2D:
	var clean_name := companion_name.to_lower().replace(" ", "_").replace(".", "").strip_edges()
	var named_path := "res://assets/hud/%s_avatar.png" % clean_name
	if ResourceLoader.exists(named_path):
		return load(named_path)

	# Known companion aliases
	if clean_name in ["kelan_leader", "kelan"] and ResourceLoader.exists("res://assets/hud/kelang_avatar.png"):
		return load("res://assets/hud/kelang_avatar.png")
	if clean_name in ["smonkey", "monkey", "curious_monkey"] and ResourceLoader.exists("res://assets/hud/s_monkey_avatar.png"):
		return load("res://assets/hud/s_monkey_avatar.png")
	if clean_name in ["fred"] and ResourceLoader.exists("res://assets/hud/frederico_avatar.png"):
		return load("res://assets/hud/frederico_avatar.png")

	# Check ArchiveLoader dynamically if available in tree
	var st := Engine.get_main_loop() as SceneTree
	var loader: Node = st.root.get_node_or_null("ArchiveLoader") if (st and st.root) else null
	if not loader and st and st.root:
		loader = st.root.find_child("ArchiveLoader", true, false)

	if loader:
		var talk_img: int = 0
		var spr_id: int = 0
		match npc_id:
			8090, 14161, 14162, 15002:
				talk_img = 8090
				spr_id = 1221
			14062:
				talk_img = 8038
				spr_id = 1131
			12032, 14003:
				talk_img = 8067
				spr_id = 1195
			14081, 15267:
				talk_img = 8091
				spr_id = 1223
			12059, 12217:
				talk_img = 8097
				spr_id = 1260
			17162, 14997, 10727:
				talk_img = 0
				spr_id = 1103

		if talk_img == 0 and spr_id == 0:
			var gdb: Node = st.root.get_node_or_null("GameDatabase") if (st and st.root) else null
			if gdb and "npcs" in gdb and gdb.npcs:
				var rec = gdb.npcs.get_npc(npc_id)
				if rec:
					talk_img = int(rec.talk_image)
					spr_id = int(rec.sprite_id)

		if talk_img > 0 and loader.has_method("get_npc_portrait"):
			var p_tex: Texture2D = loader.get_npc_portrait(talk_img)
			if p_tex:
				return p_tex
		if spr_id > 0 and loader.has_method("get_npc_texture"):
			var s_tex: Texture2D = loader.get_npc_texture(spr_id, 0)
			if s_tex:
				return s_tex

	# Generic authentic fallback: use Roca's portrait if nothing else resolves
	if ResourceLoader.exists("res://assets/hud/roca_avatar.png"):
		return load("res://assets/hud/roca_avatar.png")
	return null

func _apply_close_button_textures(btn: Button) -> void:
	# The close button is a transparent hit area over the x sphere baked into the skin (WindowCloseButton).
	pass

func _apply_action_button_textures(btn: Button, base_name: String) -> void:
	if not btn: return
	var p_norm := "res://assets/hud/%s_normal.png" % base_name
	var p_hov := "res://assets/hud/%s_hover.png" % base_name
	var p_prs := "res://assets/hud/%s_pressed.png" % base_name

	if ResourceLoader.exists(p_norm):
		var t_norm: Texture2D = load(p_norm)
		var t_hov: Texture2D = load(p_hov) if ResourceLoader.exists(p_hov) else t_norm
		var t_prs: Texture2D = load(p_prs) if ResourceLoader.exists(p_prs) else t_norm

		var norm := StyleBoxTexture.new()
		norm.texture = t_norm
		var hov := StyleBoxTexture.new()
		hov.texture = t_hov
		var prs := StyleBoxTexture.new()
		prs.texture = t_prs

		btn.add_theme_stylebox_override("normal", norm)
		btn.add_theme_stylebox_override("hover", hov)
		btn.add_theme_stylebox_override("pressed", prs)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.text = ""

func _apply_companion_toggle_textures(btn: Button, is_summoned: bool) -> void:
	if not btn: return
	# Sliced authentic Btn_AssignRest_1 vs Btn_AssignFight_1 (43x20)
	var prefix := "btn_assign_rest" if is_summoned else "btn_assign_fight"
	var p_norm := "res://assets/hud/%s_normal.png" % prefix
	var p_hov := "res://assets/hud/%s_hover.png" % prefix
	var p_prs := "res://assets/hud/%s_pressed.png" % prefix

	if ResourceLoader.exists(p_norm):
		var t_norm: Texture2D = load(p_norm)
		var t_hov: Texture2D = load(p_hov) if ResourceLoader.exists(p_hov) else t_norm
		var t_prs: Texture2D = load(p_prs) if ResourceLoader.exists(p_prs) else t_norm

		var norm := StyleBoxTexture.new()
		norm.texture = t_norm
		var hov := StyleBoxTexture.new()
		hov.texture = t_hov
		var prs := StyleBoxTexture.new()
		prs.texture = t_prs

		btn.add_theme_stylebox_override("normal", norm)
		btn.add_theme_stylebox_override("hover", hov)
		btn.add_theme_stylebox_override("pressed", prs)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.text = ""
	else:
		btn.text = "Rest" if is_summoned else "Summon"

func _apply_ride_button_textures(btn: Button, is_riding: bool) -> void:
	if not btn: return
	var p_norm := "res://assets/hud/btn_assign_ride_normal.png"
	var p_hov := "res://assets/hud/btn_assign_ride_hover.png"
	var p_prs := "res://assets/hud/btn_assign_ride_pressed.png"

	if ResourceLoader.exists(p_norm):
		var t_norm: Texture2D = load(p_norm)
		var t_hov: Texture2D = load(p_hov) if ResourceLoader.exists(p_hov) else t_norm
		var t_prs: Texture2D = load(p_prs) if ResourceLoader.exists(p_prs) else t_norm

		var norm := StyleBoxTexture.new()
		norm.texture = t_norm
		var hov := StyleBoxTexture.new()
		hov.texture = t_hov
		var prs := StyleBoxTexture.new()
		prs.texture = t_prs

		btn.add_theme_stylebox_override("normal", norm)
		btn.add_theme_stylebox_override("hover", hov)
		btn.add_theme_stylebox_override("pressed", prs)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.text = ""
		btn.modulate = Color(0.85, 1.0, 0.85, 1.0) if is_riding else Color(1.0, 1.0, 1.0, 1.0)
	else:
		btn.text = "Dismount" if is_riding else "Ride"

func _apply_member_select_style(btn: Button, is_selected: bool) -> void:
	if not btn: return
	if is_selected:
		var sel_sb := StyleBoxFlat.new()
		sel_sb.bg_color = Color(1.0, 0.88, 0.35, 0.28)
		sel_sb.border_width_left = 2
		sel_sb.border_width_top = 2
		sel_sb.border_width_right = 2
		sel_sb.border_width_bottom = 2
		sel_sb.border_color = Color(1.0, 0.9, 0.3, 1.0)
		sel_sb.corner_radius_top_left = 3
		sel_sb.corner_radius_top_right = 3
		sel_sb.corner_radius_bottom_right = 3
		sel_sb.corner_radius_bottom_left = 3
		btn.add_theme_stylebox_override("normal", sel_sb)
		btn.add_theme_stylebox_override("hover", sel_sb)
		btn.add_theme_stylebox_override("pressed", sel_sb)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	else:
		var hov_sb := StyleBoxFlat.new()
		hov_sb.bg_color = Color(0.4, 0.6, 0.9, 0.15)
		hov_sb.border_width_left = 1
		hov_sb.border_width_top = 1
		hov_sb.border_width_right = 1
		hov_sb.border_width_bottom = 1
		hov_sb.border_color = Color(0.6, 0.75, 1.0, 0.4)
		hov_sb.corner_radius_top_left = 2
		hov_sb.corner_radius_top_right = 2
		hov_sb.corner_radius_bottom_right = 2
		hov_sb.corner_radius_bottom_left = 2
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("hover", hov_sb)
		btn.add_theme_stylebox_override("pressed", hov_sb)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _apply_textured_bar_style(bar: ProgressBar, bar_type: String) -> void:
	if not bar: return
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.04, 0.05, 0.07, 0.9)
	bg_sb.border_width_left = 1
	bg_sb.border_width_top = 1
	bg_sb.border_width_right = 1
	bg_sb.border_width_bottom = 1
	bg_sb.border_color = Color(0.0, 0.0, 0.0, 1.0)
	bg_sb.corner_radius_top_left = 1
	bg_sb.corner_radius_top_right = 1
	bg_sb.corner_radius_bottom_right = 1
	bg_sb.corner_radius_bottom_left = 1

	var fill_color: Color = Color(0.2, 0.8, 0.25, 1.0) if bar_type == "hp" else Color(0.2, 0.5, 0.95, 1.0)
	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = fill_color
	fill_sb.border_width_top = 1
	fill_sb.border_color = Color(1.0, 1.0, 1.0, 0.35)
	fill_sb.corner_radius_top_left = 1
	fill_sb.corner_radius_top_right = 1
	fill_sb.corner_radius_bottom_right = 1
	fill_sb.corner_radius_bottom_left = 1

	bar.add_theme_stylebox_override("background", bg_sb)
	bar.add_theme_stylebox_override("fill", fill_sb)
