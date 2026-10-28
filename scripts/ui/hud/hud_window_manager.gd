class_name HUDWindowManager
extends RefCounted

const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")

## Sub-controller for Wonderland Online HUD Floating VCL Windows and Window Dragging.
## Encapsulates CharacterWindow, SkillWindow, QuestWindow, TeamWindow, FriendsWindow,
## SystemWindow, FightWindow, and InventoryWindow.
## Handles title bar dragging with bounds clamping, close buttons, and window toggles.

signal window_toggled(window_name: String, is_visible: bool)
signal logout_requested

var _hud: Control = null

# Node references
var floating_windows: Control = null
var char_window: Control = null
var char_bg: TextureRect = null
var skill_window: Control = null
var skill_bg: TextureRect = null
var quest_window: Control = null
var quest_bg: TextureRect = null
var team_window: Control = null
var team_bg: TextureRect = null
var friends_window: Control = null
var friends_bg: TextureRect = null
var system_window: Control = null
var system_bg: TextureRect = null
var fight_window: Control = null
var fight_bg: TextureRect = null
var inventory_window: Control = null
var inventory_bg: TextureRect = null
var shop_window: Control = null

# Window dragging state
var _dragging_window: Control = null
var _drag_offset: Vector2 = Vector2.ZERO

## Initializes references, loads authentic skin textures, creates close buttons and drag bars
func setup(hud: Control, nodes: Dictionary = {}) -> void:
	_hud = hud
	
	floating_windows = nodes.get("floating_windows", hud.get_node_or_null("FloatingWindows"))
	char_window = nodes.get("char_window", hud.get_node_or_null("FloatingWindows/CharacterWindow"))
	char_bg = nodes.get("char_bg", hud.get_node_or_null("FloatingWindows/CharacterWindow/Background"))
	skill_window = nodes.get("skill_window", hud.get_node_or_null("FloatingWindows/SkillWindow"))
	skill_bg = nodes.get("skill_bg", hud.get_node_or_null("FloatingWindows/SkillWindow/Background"))
	quest_window = nodes.get("quest_window", hud.get_node_or_null("FloatingWindows/QuestWindow"))
	quest_bg = nodes.get("quest_bg", hud.get_node_or_null("FloatingWindows/QuestWindow/Background"))
	team_window = nodes.get("team_window", hud.get_node_or_null("FloatingWindows/TeamWindow"))
	team_bg = nodes.get("team_bg", hud.get_node_or_null("FloatingWindows/TeamWindow/Background"))
	friends_window = nodes.get("friends_window", hud.get_node_or_null("FloatingWindows/FriendsWindow"))
	friends_bg = nodes.get("friends_bg", hud.get_node_or_null("FloatingWindows/FriendsWindow/Background"))
	system_window = nodes.get("system_window", hud.get_node_or_null("FloatingWindows/SystemWindow"))
	system_bg = nodes.get("system_bg", hud.get_node_or_null("FloatingWindows/SystemWindow/Background"))
	fight_window = nodes.get("fight_window", hud.get_node_or_null("FloatingWindows/FightWindow"))
	fight_bg = nodes.get("fight_bg", hud.get_node_or_null("FloatingWindows/FightWindow/Background"))
	inventory_window = nodes.get("inventory_window", hud.get_node_or_null("FloatingWindows/InventoryWindow"))
	inventory_bg = nodes.get("inventory_bg", hud.get_node_or_null("FloatingWindows/InventoryWindow/Background"))

	if system_window:
		if not system_window.get_script():
			var sys_script = load("res://scripts/ui/hud/system_window.gd")
			if sys_script:
				system_window.set_script(sys_script)
		if system_window.has_method("setup"):
			system_window.setup(_hud)
		if system_window.has_signal("window_closed"):
			var on_sys_closed := func() -> void:
				window_toggled.emit("SystemWindow", false)
			if not system_window.window_closed.is_connected(on_sys_closed):
				system_window.window_closed.connect(on_sys_closed)
		if system_window.has_signal("logout_requested"):
			var on_sys_logout := func() -> void:
				logout_requested.emit()
			if not system_window.logout_requested.is_connected(on_sys_logout):
				system_window.logout_requested.connect(on_sys_logout)

	if fight_window:
		if not fight_window.get_script():
			var fight_script = load("res://scripts/ui/hud/fight_window.gd")
			if fight_script:
				fight_window.set_script(fight_script)
		if fight_window.has_method("setup"):
			fight_window.setup(_hud)

	shop_window = nodes.get("shop_window", hud.get_node_or_null("FloatingWindows/ShopWindow"))
	if shop_window:
		if not shop_window.get_script():
			var shop_script = load("res://scripts/ui/shop/shop_window.gd")
			if shop_script:
				shop_window.set_script(shop_script)
		if shop_window.has_method("setup"):
			shop_window.setup(_hud)
		if shop_window.has_signal("window_closed"):
			var on_shop_closed := func() -> void:
				window_toggled.emit("ShopWindow", false)
			if not shop_window.window_closed.is_connected(on_shop_closed):
				shop_window.window_closed.connect(on_shop_closed)
		if fight_window.has_signal("window_closed"):
			var on_fight_closed := func() -> void:
				window_toggled.emit("FightWindow", false)
			if not fight_window.window_closed.is_connected(on_fight_closed):
				fight_window.window_closed.connect(on_fight_closed)

	if friends_window:
		if not friends_window.get_script():
			var friends_script = load("res://scripts/ui/hud/friends_window.gd")
			if friends_script:
				friends_window.set_script(friends_script)
		if friends_window.has_method("setup"):
			friends_window.setup(_hud)
		if friends_window.has_signal("window_closed"):
			var on_friends_closed := func() -> void:
				window_toggled.emit("FriendsWindow", false)
			if not friends_window.window_closed.is_connected(on_friends_closed):
				friends_window.window_closed.connect(on_friends_closed)
		if friends_window.has_signal("whisper_requested"):
			var on_whisper := func(tname: String) -> void:
				if _hud and _hud.has_method("whisper_to_player"):
					_hud.whisper_to_player(tname)
			if not friends_window.whisper_requested.is_connected(on_whisper):
				friends_window.whisper_requested.connect(on_whisper)

	if skill_window:
		if not skill_window.get_script():
			var skill_script = load("res://scripts/ui/hud/skill_window.gd")
			if skill_script:
				skill_window.set_script(skill_script)
		if skill_window.has_method("setup"):
			skill_window.setup(_hud)
		if skill_window.has_signal("window_closed"):
			var on_skill_closed := func() -> void:
				window_toggled.emit("SkillWindow", false)
			if not skill_window.window_closed.is_connected(on_skill_closed):
				skill_window.window_closed.connect(on_skill_closed)

	if team_window:
		if not team_window.get_script():
			var team_script = load("res://scripts/ui/hud/team_window.gd")
			if team_script:
				team_window.set_script(team_script)
		if team_window.has_method("setup"):
			team_window.setup(_hud)
		if team_window.has_signal("window_closed"):
			var on_team_closed := func() -> void:
				window_toggled.emit("TeamWindow", false)
			if not team_window.window_closed.is_connected(on_team_closed):
				team_window.window_closed.connect(on_team_closed)
	
	_load_window_skins()
	_setup_floating_windows()
	
	if _hud:
		var vp: Viewport = _hud.get_viewport()
		if vp and not vp.size_changed.is_connected(clamp_open_windows):
			vp.size_changed.connect(clamp_open_windows)

## Loads authentic window textures from ArchiveLoader
func _load_window_skins() -> void:
	var loader: Node = null
	if _hud and _hud.is_inside_tree():
		loader = _hud.get_node_or_null("/root/ArchiveLoader")
	if not loader and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			loader = st.root.get_node_or_null("ArchiveLoader")
	
	if not loader or not loader.has_method("get_ui_texture"):
		return
	
	if char_bg:
		var char_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_RoleStatus_1.bmp")
		if char_tex: char_bg.texture = char_tex
	
	if inventory_bg:
		var inv_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_ThingGrid5x5_1.bmp")
		if inv_tex: inventory_bg.texture = inv_tex
	
	if fight_bg:
		var fight_tex: ImageTexture = loader.get_ui_texture("menu/Skins/default/BattleStatus_1.bmp") if (loader and loader.has_method("get_ui_texture")) else null
		if fight_tex:
			fight_bg.texture = fight_tex
		elif ResourceLoader.exists("res://assets/hud/form_fight_1.png"):
			fight_bg.texture = load("res://assets/hud/form_fight_1.png")
	
	if skill_bg:
		if ResourceLoader.exists("res://assets/hud/form_skill_1.png"):
			skill_bg.texture = load("res://assets/hud/form_skill_1.png")
		else:
			var skill_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/form_skill_1.bmp")
			if not skill_tex: skill_tex = loader.get_ui_texture("menu/Skins/white/form_skill.bmp")
			if skill_tex: skill_bg.texture = skill_tex
	
	if team_bg:
		var team_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_Team_2.bmp")
		if team_tex: team_bg.texture = team_tex
	
	if quest_bg:
		var quest_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/form_taskview_1.bmp")
		if quest_tex: quest_bg.texture = quest_tex
	
	if friends_bg:
		var friends_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_Friend_2.bmp")
		if friends_tex: friends_bg.texture = friends_tex
	
	if system_bg:
		var system_tex: ImageTexture = loader.get_ui_texture("menu/Skins/white/Form_System_2.bmp")
		if system_tex:
			system_bg.texture = system_tex
		elif ResourceLoader.exists("res://assets/hud/form_system_2.png"):
			system_bg.texture = load("res://assets/hud/form_system_2.png")

## Configures close buttons and dragging headers for all floating windows
func _setup_floating_windows() -> void:
	if quest_window:
		var q_rt := quest_window.get_node_or_null("QuestLogRichText") as RichTextLabel
		if not q_rt:
			q_rt = RichTextLabel.new()
			q_rt.name = "QuestLogRichText"
			quest_window.add_child(q_rt)
		_style_quest_log(q_rt)
		if q_rt.text.is_empty():
			q_rt.text = "[b]Active Quests:[/b]\n1. [color=yellow]The Awakening Voyage[/color]\n   - Talk to Captain Hook at the dock.\n   - Explore the mysterious island.\n\n[b]Completed Quests:[/b]\n- Tutorial: Welcome to Wonderland Online."

	var windows: Array[Control] = [
		char_window, inventory_window, fight_window,
		skill_window, team_window, quest_window,
		friends_window, system_window
	]
	
	var loader: Node = null
	if _hud and _hud.is_inside_tree():
		loader = _hud.get_node_or_null("/root/ArchiveLoader")
	if not loader and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st.root:
			loader = st.root.get_node_or_null("ArchiveLoader")
	
	var tex_close_norm: Texture2D = null
	var tex_close_hov: Texture2D = null
	var tex_close_prs: Texture2D = null
	if ResourceLoader.exists("res://assets/hud/btn_close_normal.png"):
		tex_close_norm = load("res://assets/hud/btn_close_normal.png")
	if ResourceLoader.exists("res://assets/hud/btn_close_hover.png"):
		tex_close_hov = load("res://assets/hud/btn_close_hover.png")
	if ResourceLoader.exists("res://assets/hud/btn_close_pressed.png"):
		tex_close_prs = load("res://assets/hud/btn_close_pressed.png")

	var close_tex: ImageTexture = loader.get_ui_texture("menu/Skins/default/btn_close_s_1.bmp") if (loader and loader.has_method("get_ui_texture")) else null
	
	for win in windows:
		if not win:
			continue
		
		# Hide redundant synthetic TitleLabel text labels (Delphi skin bitmaps have titles pre-printed)
		# The combat settings window has no baked title, so its label stays visible.
		var title_lbl := win.get_node_or_null("TitleLabel")
		if title_lbl and win != fight_window:
			title_lbl.visible = false
			title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Ensure CloseButton exists and has accurate hit-box
		var close_btn := win.get_node_or_null("CloseButton") as Button
		if not close_btn:
			close_btn = Button.new()
			close_btn.name = "CloseButton"
			win.add_child(close_btn)
		
		var win_w: float = win.size.x
		if win == fight_window:
			# The combat settings window has no baked x sphere; it keeps its own corner button.
			close_btn.position = Vector2(win_w - 30.0, 8.0)
			close_btn.size = Vector2(18.0, 18.0)
			close_btn.custom_minimum_size = Vector2(18.0, 18.0)
			close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
			close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			close_btn.flat = true
			close_btn.text = ""
		else:
			WindowCloseButton.apply(close_btn, win_w) # sits on the baked x sphere

		var on_close := func() -> void:
			AuthAudioScript.play_click()
			if win.has_method("close_window"):
				win.close_window()
			else:
				win.visible = false
			window_toggled.emit(win.name, false)
		
		for conn in close_btn.pressed.get_connections():
			close_btn.pressed.disconnect(conn.callable)
		close_btn.pressed.connect(on_close)
		
		if win.name == "QuestWindow" and not win.has_node("QuestLogRichText"):
			var q_rt := RichTextLabel.new()
			q_rt.name = "QuestLogRichText"
			win.add_child(q_rt)
			q_rt.position = Vector2(28, 52)
			q_rt.size = Vector2(376, 285)
			q_rt.bbcode_enabled = true
			q_rt.scroll_following = false
			q_rt.add_theme_font_size_override("normal_font_size", 12)
			q_rt.add_theme_color_override("default_color", Color(0.95, 0.95, 0.9, 1.0))
			q_rt.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.95))
			q_rt.add_theme_constant_override("outline_size", 2)
			q_rt.text = "[b]Active Quests:[/b]\n - [color=yellow]Voyage on the Ocean Star[/color] [In Progress]\n   Speak with Captain Robinson at the helm of the Ocean Star."
		
		_make_draggable(win)

## Adds drag handling to a floating window
func _make_draggable(control: Control) -> void:
	if not control:
		return
	
	# Header drag area (Y from 0 to 45)
	var header := control.get_node_or_null("HeaderBar") as Control
	if not header:
		header = Control.new()
		header.name = "HeaderBar"
		control.add_child(header)
		control.move_child(header, 1) # below close button and contents
	
	header.position = Vector2(0, 0)
	header.size = Vector2(control.size.x, 45.0)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.mouse_default_cursor_shape = Control.CURSOR_MOVE
	
	header.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_window_drag(control, event.global_position)
	)
	
	control.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.position.y <= 45.0:
				start_window_drag(control, event.global_position)
	)
	
	var bg := control.get_node_or_null("Background") as Control
	if bg:
		bg.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if event.position.y <= 45.0:
					start_window_drag(control, event.global_position)
		)

## Begins dragging the specified window
func start_window_drag(win: Control, global_mouse_pos: Vector2) -> void:
	if not win or not win.visible:
		return
	_dragging_window = win
	_drag_offset = global_mouse_pos - win.position
	win.move_to_front()

## Handles mouse dragging motion and release input
func handle_input(event: InputEvent) -> bool:
	if _dragging_window:
		if not _dragging_window.visible:
			_dragging_window = null
			return false
		
		if event is InputEventMouseMotion:
			var vp_size: Vector2 = _hud.get_viewport_rect().size if _hud else Vector2(800, 600)
			var new_pos: Vector2 = event.position - _drag_offset
			var win_size: Vector2 = _dragging_window.size
			new_pos.x = clampf(new_pos.x, 0.0, maxf(0.0, vp_size.x - win_size.x))
			new_pos.y = clampf(new_pos.y, 0.0, maxf(0.0, vp_size.y - win_size.y))
			_dragging_window.position = new_pos
			if _hud and _hud.get_viewport():
				_hud.get_viewport().set_input_as_handled()
			return true
		
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_dragging_window = null
			if _hud and _hud.get_viewport():
				_hud.get_viewport().set_input_as_handled()
			return true
	
	return false

## Toggles character status window ('C')
func toggle_character_status() -> void:
	if char_window:
		char_window.visible = not char_window.visible
		if char_window.visible:
			char_window.move_to_front()
			if _hud and "character_status" in _hud and _hud.character_status:
				_hud.character_status.update_character_paper_doll()
		window_toggled.emit("CharacterWindow", char_window.visible)

## Toggles floating inventory window ('I') - integrated into CharacterWindow in authentic client
func toggle_inventory() -> void:
	toggle_character_status()

## Geometry measured from form_taskview_1: ten baked list rows on the left (x 17, y 53, pitch 24)
## and the "Taskview" panel on the right (x 218..410, y 53..318).
const QUEST_ROW_COUNT: int = 10
const QUEST_ROW_ORIGIN: Vector2 = Vector2(14, 53)
const QUEST_ROW_SIZE: Vector2 = Vector2(202, 22)
const QUEST_ROW_PITCH: float = 24.0
const QUEST_DETAIL_POS: Vector2 = Vector2(220, 54)
const QUEST_DETAIL_SIZE: Vector2 = Vector2(196, 238)
const QUEST_PAGE_PREV_POS: Vector2 = Vector2(72, 298)
const QUEST_PAGE_NEXT_POS: Vector2 = Vector2(136, 298)

var _quest_rows: Array = []
var _quest_titles: Array = [] # {"title": String, "completed": bool, "paragraph": int}
var _quest_page: int = 0

func _style_quest_log(q_rt: RichTextLabel) -> void:
	q_rt.position = QUEST_DETAIL_POS
	q_rt.size = QUEST_DETAIL_SIZE
	q_rt.bbcode_enabled = true
	q_rt.scroll_following = false
	q_rt.add_theme_font_size_override("normal_font_size", 10)
	q_rt.add_theme_font_size_override("bold_font_size", 10)
	q_rt.add_theme_color_override("default_color", Color(0.16, 0.22, 0.40, 1.0))
	q_rt.add_theme_constant_override("outline_size", 0)

func _ensure_quest_list_ui() -> void:
	if not quest_window or not _quest_rows.is_empty():
		return
	var clear := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 0.85, 0.3, 0.25)
	for i in range(QUEST_ROW_COUNT):
		var row := quest_window.get_node_or_null("QuestRow_%d" % i) as Button
		if not row:
			row = Button.new()
			row.name = "QuestRow_%d" % i
			row.flat = true
			row.alignment = HORIZONTAL_ALIGNMENT_LEFT
			row.clip_text = true
			row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			row.add_theme_font_size_override("font_size", 10)
			row.add_theme_color_override("font_color", Color(0.16, 0.22, 0.40, 1.0))
			row.add_theme_color_override("font_hover_color", Color(0.05, 0.12, 0.35, 1.0))
			row.add_theme_color_override("font_pressed_color", Color(0.05, 0.12, 0.35, 1.0))
			row.add_theme_color_override("font_disabled_color", Color(0.16, 0.22, 0.40, 1.0))
			for state in ["normal", "pressed", "focus", "disabled"]:
				row.add_theme_stylebox_override(state, clear)
			row.add_theme_stylebox_override("hover", hover)
			quest_window.add_child(row)
			row.pressed.connect(_on_quest_row_pressed.bind(i))
		row.position = QUEST_ROW_ORIGIN + Vector2(0, QUEST_ROW_PITCH * i)
		row.size = QUEST_ROW_SIZE
		_quest_rows.append(row)
	for entry in [["QuestPagePrev", QUEST_PAGE_PREV_POS, -1], ["QuestPageNext", QUEST_PAGE_NEXT_POS, 1]]:
		var btn := quest_window.get_node_or_null(entry[0]) as Button
		if not btn:
			btn = Button.new()
			btn.name = entry[0]
			btn.flat = true
			btn.text = ""
			for state in ["normal", "hover", "pressed", "focus", "disabled"]:
				btn.add_theme_stylebox_override(state, clear)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			quest_window.add_child(btn)
			btn.pressed.connect(_on_quest_page.bind(int(entry[2])))
		btn.position = entry[1]
		btn.size = Vector2(26, 22)

## Close pill, "1 / N" pager text and the hidden "Taskview" caption of the real mission window.
func _ensure_quest_extras() -> void:
	if not quest_window or quest_window.get_node_or_null("QuestPagerLabel") != null:
		return
	var cover := ColorRect.new()
	cover.name = "QuestCaptionCover"
	cover.position = Vector2(222, 298)
	cover.size = Vector2(62, 14)
	cover.color = Color(0.95, 0.97, 1.0, 1.0)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_window.add_child(cover)
	var pager := Label.new()
	pager.name = "QuestPagerLabel"
	pager.position = Vector2(100, 297)
	pager.size = Vector2(38, 18)
	pager.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pager.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pager.add_theme_font_size_override("font_size", 10)
	pager.add_theme_color_override("font_color", Color(0.10, 0.16, 0.62, 1.0))
	quest_window.add_child(pager)
	var close_pill := HUDPillButton.make("Close", Vector2(184, 328), Vector2(56, 18))
	close_pill.name = "QuestBottomClose"
	close_pill.pressed.connect(func() -> void:
		quest_window.visible = false
		window_toggled.emit("QuestWindow", false))
	quest_window.add_child(close_pill)


func _on_quest_page(step: int) -> void:
	var page_count: int = maxi(1, ceili(float(_quest_titles.size()) / QUEST_ROW_COUNT))
	_quest_page = clampi(_quest_page + step, 0, page_count - 1)
	_refresh_quest_rows()

func _on_quest_row_pressed(row_index: int) -> void:
	var entry_index: int = _quest_page * QUEST_ROW_COUNT + row_index
	if entry_index >= _quest_titles.size() or not quest_window:
		return
	var q_rt := quest_window.get_node_or_null("QuestLogRichText") as RichTextLabel
	if q_rt:
		q_rt.scroll_to_paragraph(int(_quest_titles[entry_index].get("paragraph", 0)))

func _refresh_quest_rows() -> void:
	_ensure_quest_extras()
	var pager := quest_window.get_node_or_null("QuestPagerLabel") as Label if quest_window else null
	if pager:
		var pages: int = maxi(1, ceili(float(_quest_titles.size()) / QUEST_ROW_COUNT))
		pager.text = "%d/%d" % [_quest_page + 1, pages]
	for i in range(_quest_rows.size()):
		var row: Button = _quest_rows[i]
		var entry_index: int = _quest_page * QUEST_ROW_COUNT + i
		var mark := row.get_node_or_null("DoneMark") as Label
		if mark == null:
			mark = Label.new()
			mark.name = "DoneMark"
			mark.text = "\u2713"
			mark.position = Vector2(5, 0)
			mark.size = Vector2(16, QUEST_ROW_SIZE.y)
			mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.add_theme_font_size_override("font_size", 13)
			mark.add_theme_color_override("font_color", Color(0.88, 0.1, 0.1, 1.0))
			row.add_child(mark)
		var title_lbl := row.get_node_or_null("TitleLabel") as Label
		if title_lbl == null:
			title_lbl = Label.new()
			title_lbl.name = "TitleLabel"
			title_lbl.position = Vector2(22, 0)
			title_lbl.size = Vector2(QUEST_ROW_SIZE.x - 24, QUEST_ROW_SIZE.y)
			title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			title_lbl.add_theme_font_size_override("font_size", 10)
			title_lbl.add_theme_color_override("font_color", Color(0.16, 0.22, 0.40, 1.0))
			row.add_child(title_lbl)
		row.text = ""
		if entry_index < _quest_titles.size():
			var entry: Dictionary = _quest_titles[entry_index]
			var t_str: String = str(entry.get("title", "Quest"))
			title_lbl.text = t_str
			row.tooltip_text = t_str
			mark.visible = bool(entry.get("completed", false))
			row.disabled = false
			row.visible = true
		else:
			title_lbl.text = ""
			row.tooltip_text = ""
			mark.visible = false
			row.visible = false

## Toggles floating skill window ('S')
func toggle_skill_window() -> void:
	if skill_window:
		skill_window.visible = not skill_window.visible
		if skill_window.visible: skill_window.move_to_front()
		window_toggled.emit("SkillWindow", skill_window.visible)

## Toggles floating team window ('T')
func toggle_team_window() -> void:
	if team_window:
		team_window.visible = not team_window.visible
		if team_window.visible: team_window.move_to_front()
		window_toggled.emit("TeamWindow", team_window.visible)

## Toggles floating quest window ('Q')
func toggle_quest_window() -> void:
	if quest_window:
		quest_window.visible = not quest_window.visible
		if quest_window.visible: quest_window.move_to_front()
		window_toggled.emit("QuestWindow", quest_window.visible)

## Toggles floating friends window ('F')
func toggle_friends_window() -> void:
	if friends_window:
		if friends_window.has_method("toggle_window"):
			friends_window.toggle_window()
		else:
			friends_window.visible = not friends_window.visible
		if friends_window.visible: friends_window.move_to_front()
		window_toggled.emit("FriendsWindow", friends_window.visible)

## Toggles floating system window ('Esc')
func toggle_system_window() -> void:
	if system_window:
		if system_window.has_method("toggle_window"):
			system_window.toggle_window()
		else:
			system_window.visible = not system_window.visible
		if system_window.visible:
			system_window.move_to_front()
		window_toggled.emit("SystemWindow", system_window.visible)

## Toggles fight menu ('P')
func toggle_fight_menu() -> void:
	if fight_window:
		if fight_window.has_method("toggle_window"):
			fight_window.toggle_window()
		else:
			fight_window.visible = not fight_window.visible
		if fight_window.visible:
			fight_window.move_to_front()
		window_toggled.emit("FightWindow", fight_window.visible)

## Toggles shop window
func toggle_shop_window() -> void:
	if _hud and _hud.has_method("toggle_shop_window"):
		_hud.toggle_shop_window()
	elif shop_window:
		shop_window.visible = not shop_window.visible
		if shop_window.visible:
			shop_window.move_to_front()
		window_toggled.emit("ShopWindow", shop_window.visible)

## Closes all floating windows
## Closes top-most open floating window or toggles system window on Escape
func close_top_or_system_window() -> bool:
	var windows: Array[Control] = [
		system_window, friends_window, quest_window, team_window,
		skill_window, fight_window, inventory_window, char_window
	]
	for win in windows:
		if win and win.visible:
			if win.has_method("close_window"):
				win.close_window()
			else:
				win.visible = false
				window_toggled.emit(win.name, false)
			return true
	toggle_system_window()
	return true

func clamp_open_windows() -> void:
	if not _hud:
		return
	var vp_size: Vector2 = _hud.get_viewport_rect().size
	var windows: Array[Control] = [
		char_window, inventory_window, fight_window,
		skill_window, team_window, quest_window,
		friends_window, system_window
	]
	for win in windows:
		if win and win.visible:
			var win_size: Vector2 = win.size
			win.position.x = clampf(win.position.x, 0.0, maxf(0.0, vp_size.x - win_size.x))
			win.position.y = clampf(win.position.y, 0.0, maxf(0.0, vp_size.y - win_size.y))

## Updates QuestWindow/QuestLogRichText with formatted BBCode, step descriptions, and reward summaries
func update_quest_log(quests: Variant) -> void:
	if not quest_window:
		return
	var q_rt := quest_window.get_node_or_null("QuestLogRichText") as RichTextLabel
	if not q_rt:
		q_rt = RichTextLabel.new()
		q_rt.name = "QuestLogRichText"
		quest_window.add_child(q_rt)
	_style_quest_log(q_rt)
	_ensure_quest_list_ui()
	_quest_titles.clear()
	
	var active_list: Array = []
	var completed_list: Array = []

	var quest_array: Array = []
	if quests is Array:
		quest_array = quests
	elif quests is Dictionary:
		if quests.has("active") and quests["active"] is Array:
			active_list = quests["active"]
		if quests.has("completed") and quests["completed"] is Array:
			completed_list = quests["completed"]
		if active_list.is_empty() and completed_list.is_empty():
			for v in quests.values():
				if v is Dictionary:
					quest_array.append(v)

	for q in quest_array:
		if q is Dictionary:
			var st: String = str(q.get("status", "In Progress")).to_lower()
			if "complet" in st:
				completed_list.append(q)
			else:
				active_list.append(q)
		elif q is String:
			active_list.append({"title": q, "status": "In Progress"})

	var bb := "[b][color=#8a6100]--- ACTIVE QUESTS ---[/color][/b]\n"
	if active_list.is_empty():
		bb += "[color=#6f7a96]No active quests in log.[/color]\n\n"
	else:
		for q in active_list:
			if q is Dictionary:
				var title: String = str(q.get("title", "Quest"))
				var cur_step: int = int(q.get("current_step", 0))
				var objs: Array = q.get("objectives", [])
				var total_steps: int = int(q.get("total_steps", objs.size()))
				var reward_str: String = str(q.get("reward", ""))
				
				_quest_titles.append({"title": title, "completed": false, "paragraph": bb.count("\n")})
				bb += "[color=#2a8f3f]●[/color] [b][color=#1f2f5c]%s[/color][/b]" % title
				if total_steps > 0:
					bb += " [color=#5b6b8c](Step %d/%d)[/color]\n" % [mini(cur_step + 1, total_steps), total_steps]
				else:
					bb += "\n"

				# List all step objectives or current objective
				if not objs.is_empty():
					for idx in range(objs.size()):
						var step_obj = objs[idx]
						var desc: String = ""
						if step_obj is Dictionary:
							desc = str(step_obj.get("description", step_obj.get("dialogue_preview", "")))
						else:
							desc = str(step_obj)
						if idx < cur_step:
							bb += "   [color=#2e8b4a][x] %s[/color]\n" % desc
						elif idx == cur_step:
							bb += "   [color=#8a5a00][→] %s[/color]\n" % desc
						else:
							bb += "   [color=#7a8399][ ] %s[/color]\n" % desc
				else:
					var single_obj: String = str(q.get("objective", q.get("description", "")))
					if not single_obj.is_empty():
						bb += "   [color=#8a5a00]→ %s[/color]\n" % single_obj

				if not reward_str.is_empty():
					bb += "   [color=#8a6100]Rewards: %s[/color]\n\n" % reward_str
				else:
					bb += "\n"

	bb += "[b][color=#1f6f9f]--- COMPLETED QUESTS ---[/color][/b]\n"
	if completed_list.is_empty():
		bb += "[color=#6f7a96]No completed quests yet.[/color]\n"
	else:
		for q in completed_list:
			if q is Dictionary:
				var title: String = str(q.get("title", "Quest"))
				var reward_str: String = str(q.get("reward", ""))
				_quest_titles.append({"title": title, "completed": true, "paragraph": bb.count("\n")})
				bb += "[color=#2e8b4a]✓[/color] [color=#4a5578]%s[/color] [color=#2e8b4a](Completed)[/color]\n" % title
				if not reward_str.is_empty():
					bb += "   [color=#5b6b8c]Earned: %s[/color]\n" % reward_str
			elif q is String:
				_quest_titles.append({"title": str(q), "completed": true, "paragraph": bb.count("\n")})
				bb += "[color=#2e8b4a]✓[/color] [color=#4a5578]%s[/color]\n" % q

	q_rt.text = bb
	_quest_page = 0
	_refresh_quest_rows()

## Returns true if any floating window is currently visible and under mouse position
func is_mouse_over_window(mouse_pos: Vector2 = Vector2.INF) -> bool:
	var mpos: Vector2 = mouse_pos
	if mpos == Vector2.INF and _hud:
		mpos = _hud.get_viewport().get_mouse_position()
	var windows: Array[Control] = [
		char_window, inventory_window, fight_window,
		skill_window, team_window, quest_window,
		friends_window, system_window
	]
	for win in windows:
		if win and win.visible:
			if Rect2(win.global_position, win.size).has_point(mpos):
				return true
	return false
