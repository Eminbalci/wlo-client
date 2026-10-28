class_name FriendsWindow
extends Control

const PillScript = preload("res://scripts/ui/hud/pill_button.gd")
const SkinButtonScript = preload("res://scripts/ui/hud/skin_button.gd")
const AuthAudioScript = preload("res://scripts/ui/auth/auth_audio.gd")

## Controller and view for Wonderland Online Friends Window (Form_Friend_2).
## Built exclusively with authentic Wonderland Online skin bitmaps (Form_Friend_2.bmp,
## Bmp_Friend_1.bmp, btn_delFriend_1.bmp, Btn_AddNew_1.bmp, Btn_FriendIcon_1.bmp,
## Form_Talk_3.bmp, btn_ok_1.bmp, Btn_Cancel_1.bmp), zero generic flat gray boxes.
## Manages friends list rendering, online/offline status indicators, element affinity badges,
## character level and location tracking, friend selection, add/delete dialog modals,
## direct whisper chat routing to ChatDock (hud_chat.gd), and JSON persistence.

signal friend_selected(friend_data: Dictionary)
signal friend_added(friend_data: Dictionary)
signal friend_deleted(friend_name: String)
signal whisper_requested(target_name: String)
signal window_closed

const WINDOW_WIDTH: float = 356.0
const WINDOW_HEIGHT: float = 493.0
const ROW_SIZE: Vector2 = Vector2(304, 62) ## one baked row of Form_Friend_2 (pitch 65 with the 3 px list separation)
const MAX_FRIENDS: int = 50
const FRIENDS_FILE_PATH: String = "user://friends_list.json"

const DEFAULT_FRIENDS: Array[Dictionary] = [
	{
		"name": "Betty",
		"level": 18,
		"element": "Water",
		"online": true,
		"location": "Welling Village"
	},
	{
		"name": "Daniel",
		"level": 24,
		"element": "Fire",
		"online": true,
		"location": "South Island"
	},
	{
		"name": "Kelang",
		"level": 30,
		"element": "Earth",
		"online": false,
		"location": "Kranor Village"
	},
	{
		"name": "Roca",
		"level": 22,
		"element": "Fire",
		"online": true,
		"location": "Kelan Village"
	},
	{
		"name": "Satoru",
		"level": 15,
		"element": "Wind",
		"online": false,
		"location": "Beach"
	}
]

var _friends: Array[Dictionary] = []
var _selected_friend_index: int = -1
var _hud: Control = null
var _is_building: bool = false

# UI Node References
var background: TextureRect = null
var title_badge: TextureRect = null
var title_label: Label = null
var close_button: Button = null
var summary_label: Label = null

var scroll_container: ScrollContainer = null
var list_container: VBoxContainer = null

var btn_add_friend: Button = null
var btn_delete_friend: Button = null
var btn_whisper: Button = null

# Modal Dialogs (Form_Talk_3 skin)
var add_modal: Control = null
var add_input: LineEdit = null
var add_confirm_btn: Button = null
var add_cancel_btn: Button = null
var add_error_label: Label = null

var delete_modal: Control = null
var delete_prompt_label: Label = null
var delete_confirm_btn: Button = null
var delete_cancel_btn: Button = null

func _init() -> void:
	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)

func _ready() -> void:
	_build_ui_if_needed()
	load_friends_list()

func setup(hud: Control = null) -> void:
	_hud = hud
	_build_ui_if_needed()
	load_friends_list()

## Builds all internal UI components using authentic Wonderland Online skins
func _build_ui_if_needed() -> void:
	if _is_building:
		return
	_is_building = true

	size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	custom_minimum_size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)

	# 1. Authentic Background TextureRect (Form_Friend_2.bmp 356x493)
	background = get_node_or_null("Background") as TextureRect
	if not background:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
	background.position = Vector2.ZERO
	background.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_PASS

	if not background.texture:
		var tex := _load_texture_file("assets/hud/form_friend_2.png")
		if not tex:
			var st := Engine.get_main_loop() as SceneTree
			var loader: Node = st.root.get_node_or_null("ArchiveLoader") if (st and st.root) else null
			if loader and loader.has_method("get_ui_texture"):
				tex = loader.get_ui_texture("menu/Skins/white/Form_Friend_2.bmp")
		if tex:
			background.texture = tex

	# 2. Authentic Title Graphic (Bmp_Friend_1.bmp 41x15) & Label
	title_badge = get_node_or_null("TitleBadge") as TextureRect
	if not title_badge:
		title_badge = TextureRect.new()
		title_badge.name = "TitleBadge"
		add_child(title_badge)
	title_badge.position = Vector2(20, 10)
	title_badge.size = Vector2(41, 15)
	title_badge.texture = _load_texture_file("assets/hud/bmp_friend_title.png")
	title_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_badge.visible = false # the skin already bakes the "social" title

	title_label = get_node_or_null("TitleLabel") as Label
	if not title_label:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		add_child(title_label)
	title_label.position = Vector2(68, 8)
	title_label.size = Vector2(160, 20)
	title_label.text = "Friends [F]"
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 1)
	title_label.visible = false

	# 3. Authentic 18x18 Close Button at Vector2(326, 8)
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

	# 4. Authentic Summary Label (Friends count, online count)
	summary_label = get_node_or_null("SummaryLabel") as Label
	if not summary_label:
		summary_label = Label.new()
		summary_label.name = "SummaryLabel"
		add_child(summary_label)
	summary_label.position = Vector2(20, 42)
	summary_label.size = Vector2(316, 20)
	summary_label.add_theme_font_size_override("font_size", 11)
	summary_label.add_theme_color_override("font_color", Color(0.18, 0.16, 0.12, 1.0))
	summary_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.6))
	summary_label.add_theme_constant_override("shadow_offset_x", 1)
	summary_label.add_theme_constant_override("shadow_offset_y", 1)
	summary_label.text = "Friends: 0 / 50 (Online: 0)"

	# 5. ScrollContainer for Friends List (Covers pre-rendered slot region Y=68..448)
	scroll_container = get_node_or_null("ScrollContainer") as ScrollContainer
	if not scroll_container:
		scroll_container = ScrollContainer.new()
		scroll_container.name = "ScrollContainer"
		add_child(scroll_container)
	scroll_container.position = Vector2(25, 68)
	scroll_container.size = Vector2(304, 325)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	list_container = scroll_container.get_node_or_null("FriendsListContainer") as VBoxContainer
	if not list_container:
		list_container = VBoxContainer.new()
		list_container.name = "FriendsListContainer"
		scroll_container.add_child(list_container)
	list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_container.add_theme_constant_override("separation", 3)

	# 6. Authentic Bottom Action Buttons in the empty strip under the five baked rows (Y = 410)
	# Add Friend button using Btn_AddNew_1.bmp (56x20)
	btn_add_friend = get_node_or_null("BtnAddFriend") as Button
	if not btn_add_friend:
		btn_add_friend = _create_authentic_button("btn_add_new_1", Vector2(30, 412), Vector2(56, 20), "+ Add Friend")
		btn_add_friend.name = "BtnAddFriend"
		add_child(btn_add_friend)
	btn_add_friend.tooltip_text = "Add a player to your friends list"
	for conn in btn_add_friend.pressed.get_connections():
		btn_add_friend.pressed.disconnect(conn.callable)
	btn_add_friend.pressed.connect(_on_btn_add_friend_pressed)

	# Delete Friend button using btn_delFriend_1.bmp (61x20)
	btn_delete_friend = get_node_or_null("BtnDeleteFriend") as Button
	if not btn_delete_friend:
		btn_delete_friend = _create_authentic_button("btn_del_friend_1", Vector2(94, 412), Vector2(61, 20), "- Delete")
		btn_delete_friend.name = "BtnDeleteFriend"
		add_child(btn_delete_friend)
	btn_delete_friend.tooltip_text = "Remove selected friend from list"
	for conn in btn_delete_friend.pressed.get_connections():
		btn_delete_friend.pressed.disconnect(conn.callable)
	btn_delete_friend.pressed.connect(_on_btn_delete_friend_pressed)

	# Send Whisper button using Btn_FriendIcon_1.bmp (66x21)
	btn_whisper = get_node_or_null("BtnWhisper") as Button
	if not btn_whisper:
		btn_whisper = _create_authentic_button("btn_friend_icon_1", Vector2(256, 411), Vector2(66, 21), "Send Whisper")
		btn_whisper.name = "BtnWhisper"
		add_child(btn_whisper)
	btn_whisper.tooltip_text = "Send private whisper to selected friend"
	for conn in btn_whisper.pressed.get_connections():
		btn_whisper.pressed.disconnect(conn.callable)
	btn_whisper.pressed.connect(send_whisper_to_selected)

	_build_real_client_controls()

	# 7. Authentic Add Friend Modal Popup (Form_Talk_3.bmp 324x168)
	_build_add_modal()

	# 8. Authentic Delete Confirmation Modal Popup (Form_Talk_3.bmp 324x168)
	_build_delete_modal()

	_is_building = false

var text_tabs: Array[Button] = []
var pager_label: Label = null
var bottom_close_button: Button = null
var active_tab: int = 0


## Tabs (Friend / Emote / Set Up), pager and Close of the real social window (docs/re/ui_windows.md).
func _build_real_client_controls() -> void:
	if not text_tabs.is_empty():
		return
	if summary_label:
		summary_label.visible = false # the real window shows a pager instead of the count line
	var specs := [["Friend", 28, 58], ["Emote", 90, 62], ["Set Up", 154, 62]]
	for i in specs.size():
		var tab := PillScript.make(specs[i][0], Vector2(specs[i][1], 40), Vector2(specs[i][2], 18), 10)
		tab.name = "TextTab_%d" % i
		var tab_idx: int = i
		tab.pressed.connect(func() -> void:
			active_tab = tab_idx
			_refresh_real_client_controls())
		add_child(tab)
		text_tabs.append(tab)
	var prev := SkinButtonScript.make("ArrowL_4", Vector2(128, 394), "PagerPrev")
	add_child(prev)
	var next := SkinButtonScript.make("ArrowR_4", Vector2(212, 394), "PagerNext")
	add_child(next)
	pager_label = Label.new()
	pager_label.name = "PagerLabel"
	pager_label.position = Vector2(148, 393)
	pager_label.size = Vector2(62, 18)
	pager_label.text = "1 / 1"
	pager_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pager_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pager_label.add_theme_font_size_override("font_size", 11)
	pager_label.add_theme_color_override("font_color", Color(0.10, 0.16, 0.45, 1.0))
	add_child(pager_label)
	bottom_close_button = PillScript.make("Close", Vector2(150, 446), Vector2(56, 18))
	bottom_close_button.name = "BtnBottomClose"
	bottom_close_button.pressed.connect(close_window)
	add_child(bottom_close_button)
	_refresh_real_client_controls()


func _refresh_real_client_controls() -> void:
	for i in text_tabs.size():
		if i == active_tab:
			PillScript.style(text_tabs[i], Color(0.10, 0.16, 0.45, 1.0), PillScript.BORDER, Color(1.0, 1.0, 1.0, 1.0))
		else:
			PillScript.style(text_tabs[i], PillScript.INK)
	if scroll_container:
		scroll_container.visible = active_tab == 0


## Builds the Add Friend modal dialog using Form_Talk_3 skin
func _build_add_modal() -> void:
	add_modal = get_node_or_null("AddFriendModal") as Control
	if not add_modal:
		add_modal = Control.new()
		add_modal.name = "AddFriendModal"
		add_child(add_modal)
	add_modal.position = Vector2.ZERO
	add_modal.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	add_modal.visible = false
	add_modal.mouse_filter = Control.MOUSE_FILTER_STOP

	# Backdrop dim overlay
	var backdrop := add_modal.get_node_or_null("Backdrop") as ColorRect
	if not backdrop:
		backdrop = ColorRect.new()
		backdrop.name = "Backdrop"
		add_modal.add_child(backdrop)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	# Authentic Form_Talk_3 skin frame (324x168)
	var frame := add_modal.get_node_or_null("Frame") as TextureRect
	if not frame:
		frame = TextureRect.new()
		frame.name = "Frame"
		add_modal.add_child(frame)
	frame.position = Vector2(16, 140)
	frame.size = Vector2(324, 168)
	frame.texture = _load_texture_file("assets/hud/form_talk_3.png")
	frame.mouse_filter = Control.MOUSE_FILTER_STOP

	var title := Label.new()
	title.text = "Add Friend"
	title.position = Vector2(20, 8)
	title.size = Vector2(280, 20)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	frame.add_child(title)

	var prompt := Label.new()
	prompt.text = "Enter character name to add:"
	prompt.position = Vector2(30, 48)
	prompt.size = Vector2(260, 20)
	prompt.add_theme_font_size_override("font_size", 11)
	prompt.add_theme_color_override("font_color", Color(0.18, 0.16, 0.12, 1.0))
	frame.add_child(prompt)

	add_input = LineEdit.new()
	add_input.name = "AddInput"
	add_input.position = Vector2(30, 72)
	add_input.size = Vector2(264, 26)
	add_input.placeholder_text = "Character name..."
	add_input.max_length = 20
	add_input.add_theme_font_size_override("font_size", 11)
	var in_sb := StyleBoxFlat.new()
	in_sb.bg_color = Color(0.96, 0.95, 0.92, 1.0)
	in_sb.border_color = Color(0.45, 0.38, 0.28, 1.0)
	in_sb.set_border_width_all(1)
	in_sb.set_corner_radius_all(2)
	add_input.add_theme_stylebox_override("normal", in_sb)
	add_input.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1, 1.0))
	add_input.caret_blink = true
	frame.add_child(add_input)

	add_error_label = Label.new()
	add_error_label.name = "AddErrorLabel"
	add_error_label.position = Vector2(30, 102)
	add_error_label.size = Vector2(264, 16)
	add_error_label.text = ""
	add_error_label.add_theme_font_size_override("font_size", 10)
	add_error_label.add_theme_color_override("font_color", Color(0.85, 0.15, 0.15, 1.0))
	frame.add_child(add_error_label)

	# Authentic OK & Cancel buttons (btn_ok_1 and btn_cancel_1: 56x20)
	add_confirm_btn = _create_authentic_button("btn_ok_1", Vector2(90, 126), Vector2(56, 20), "OK")
	add_confirm_btn.name = "AddConfirmBtn"
	frame.add_child(add_confirm_btn)
	add_confirm_btn.pressed.connect(_on_add_modal_confirm)

	add_cancel_btn = _create_authentic_button("btn_cancel_1", Vector2(178, 126), Vector2(56, 20), "Cancel")
	add_cancel_btn.name = "AddCancelBtn"
	frame.add_child(add_cancel_btn)
	add_cancel_btn.pressed.connect(_on_add_modal_cancel)

## Builds the Delete confirmation modal dialog using Form_Talk_3 skin
func _build_delete_modal() -> void:
	delete_modal = get_node_or_null("DeleteFriendModal") as Control
	if not delete_modal:
		delete_modal = Control.new()
		delete_modal.name = "DeleteFriendModal"
		add_child(delete_modal)
	delete_modal.position = Vector2.ZERO
	delete_modal.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	delete_modal.visible = false
	delete_modal.mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := delete_modal.get_node_or_null("Backdrop") as ColorRect
	if not backdrop:
		backdrop = ColorRect.new()
		backdrop.name = "Backdrop"
		delete_modal.add_child(backdrop)
	backdrop.position = Vector2.ZERO
	backdrop.size = Vector2(WINDOW_WIDTH, WINDOW_HEIGHT)
	backdrop.color = Color(0, 0, 0, 0.45)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP

	var frame := delete_modal.get_node_or_null("Frame") as TextureRect
	if not frame:
		frame = TextureRect.new()
		frame.name = "Frame"
		delete_modal.add_child(frame)
	frame.position = Vector2(16, 140)
	frame.size = Vector2(324, 168)
	frame.texture = _load_texture_file("assets/hud/form_talk_3.png")
	frame.mouse_filter = Control.MOUSE_FILTER_STOP

	var title := Label.new()
	title.text = "Delete Friend"
	title.position = Vector2(20, 8)
	title.size = Vector2(280, 20)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	frame.add_child(title)

	delete_prompt_label = Label.new()
	delete_prompt_label.name = "DeletePromptLabel"
	delete_prompt_label.position = Vector2(24, 52)
	delete_prompt_label.size = Vector2(276, 50)
	delete_prompt_label.text = "Are you sure you want to remove\nselected player from friends?"
	delete_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_prompt_label.add_theme_font_size_override("font_size", 11)
	delete_prompt_label.add_theme_color_override("font_color", Color(0.18, 0.16, 0.12, 1.0))
	frame.add_child(delete_prompt_label)

	delete_confirm_btn = _create_authentic_button("btn_ok_1", Vector2(90, 126), Vector2(56, 20), "Delete")
	delete_confirm_btn.name = "DeleteConfirmBtn"
	frame.add_child(delete_confirm_btn)
	delete_confirm_btn.pressed.connect(_on_delete_modal_confirm)

	delete_cancel_btn = _create_authentic_button("btn_cancel_1", Vector2(178, 126), Vector2(56, 20), "Cancel")
	delete_cancel_btn.name = "DeleteCancelBtn"
	frame.add_child(delete_cancel_btn)
	delete_cancel_btn.pressed.connect(_on_delete_modal_cancel)

# ==================== WINDOW CONTROL APIS ====================

func open_window() -> void:
	visible = true
	move_to_front()
	refresh_list_view()

func close_window() -> void:
	AuthAudioScript.play_click()
	visible = false
	window_closed.emit()

func toggle_window() -> void:
	if visible:
		close_window()
	else:
		open_window()

# ==================== FRIENDS DATA & PERSISTENCE ====================

func get_friends() -> Array[Dictionary]:
	return _friends.duplicate(true)

func set_friends(friends: Array) -> void:
	_friends.clear()
	for f in friends:
		if f is Dictionary:
			_friends.append(f.duplicate(true))
	_selected_friend_index = -1
	save_friends_list()
	refresh_list_view()

func load_friends_list() -> Array[Dictionary]:
	_friends.clear()
	if FileAccess.file_exists(FRIENDS_FILE_PATH):
		var file := FileAccess.open(FRIENDS_FILE_PATH, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Array:
				for item in parsed:
					if item is Dictionary and item.has("name"):
						_friends.append(item)
	
	if _friends.is_empty():
		for def in DEFAULT_FRIENDS:
			_friends.append(def.duplicate(true))
		save_friends_list()

	_selected_friend_index = -1
	refresh_list_view()
	return _friends

func save_friends_list() -> bool:
	var file := FileAccess.open(FRIENDS_FILE_PATH, FileAccess.WRITE)
	if not file:
		return false
	var json_str := JSON.stringify(_friends, "\t")
	file.store_string(json_str)
	file.close()
	return true

func add_friend(p_name: String, p_level: int = 1, p_element: Variant = "Earth", p_online: bool = true, p_location: String = "Welling Village") -> bool:
	var clean_name := p_name.strip_edges()
	if clean_name.is_empty():
		return false

	for f in _friends:
		if str(f.get("name", "")).to_lower() == clean_name.to_lower():
			return false

	if _friends.size() >= MAX_FRIENDS:
		return false

	var new_friend: Dictionary = {
		"name": clean_name,
		"level": clampi(p_level, 1, 200),
		"element": _normalize_element(p_element),
		"online": p_online,
		"location": p_location
	}
	_friends.append(new_friend)
	save_friends_list()
	refresh_list_view()
	friend_added.emit(new_friend)
	return true

func delete_friend(name_or_index: Variant) -> bool:
	var target_idx: int = -1
	if name_or_index is int:
		target_idx = name_or_index
	elif name_or_index is String:
		var target_name: String = str(name_or_index).to_lower()
		for i in range(_friends.size()):
			if str(_friends[i].get("name", "")).to_lower() == target_name:
				target_idx = i
				break

	if target_idx < 0 or target_idx >= _friends.size():
		return false

	var deleted_name: String = str(_friends[target_idx].get("name", ""))
	_friends.remove_at(target_idx)
	if _selected_friend_index == target_idx:
		_selected_friend_index = -1
	elif _selected_friend_index > target_idx:
		_selected_friend_index -= 1

	save_friends_list()
	refresh_list_view()
	friend_deleted.emit(deleted_name)
	return true

func select_friend(idx: int) -> void:
	if idx < 0 or idx >= _friends.size():
		_selected_friend_index = -1
	else:
		_selected_friend_index = idx
		AuthAudioScript.play_click()
		friend_selected.emit(_friends[_selected_friend_index])

	_update_card_highlights()

func get_selected_friend() -> Dictionary:
	if _selected_friend_index >= 0 and _selected_friend_index < _friends.size():
		return _friends[_selected_friend_index].duplicate(true)
	return {}

# ==================== DIRECT WHISPER INTEGRATION ====================

func send_whisper_to_selected() -> void:
	AuthAudioScript.play_click()
	if _selected_friend_index < 0 or _selected_friend_index >= _friends.size():
		return
	var friend_data: Dictionary = _friends[_selected_friend_index]
	var friend_name: String = str(friend_data.get("name", "")).strip_edges()
	if friend_name.is_empty():
		return
	whisper_to_friend(friend_name)

func whisper_to_friend(target_name: String) -> void:
	var clean_target := target_name.strip_edges()
	if clean_target.is_empty():
		return

	whisper_requested.emit(clean_target)

	if _hud:
		if _hud.has_method("whisper_to_player"):
			_hud.whisper_to_player(clean_target)
			return
		var chat_dock_node = _hud.get_node_or_null("ChatDock")
		if chat_dock_node and chat_dock_node.has_method("set_whisper_target"):
			chat_dock_node.set_whisper_target(clean_target)
			return

	var tree := get_tree()
	if tree and tree.root:
		var hud_candidate = tree.root.find_child("HUD", true, false)
		if hud_candidate and hud_candidate.has_method("whisper_to_player"):
			hud_candidate.whisper_to_player(clean_target)
			return
		var chat_candidate = tree.root.find_child("ChatDock", true, false)
		if chat_candidate and chat_candidate.has_method("set_whisper_target"):
			chat_candidate.set_whisper_target(clean_target)
			return

# ==================== VIEW RENDERING ====================

func refresh_list_view() -> void:
	if not list_container:
		return

	for child in list_container.get_children():
		child.queue_free()

	var online_count: int = 0
	for i in range(_friends.size()):
		var f: Dictionary = _friends[i]
		if f.get("online", false):
			online_count += 1
		var card := _create_friend_card(f, i)
		list_container.add_child(card)

	if summary_label:
		summary_label.text = "Friends: %d / %d  (Online: %d)" % [_friends.size(), MAX_FRIENDS, online_count]

	_update_card_highlights()

## Creates a friend entry that fills one of the five rows baked into Form_Friend_2:
## blue avatar block on the left, "nickname:" / "guild:" captions, and the "tick" checkbox on the right.
func _create_friend_card(f: Dictionary, idx: int) -> Control:
	var btn := Button.new()
	btn.name = "FriendCard_%d" % idx
	btn.custom_minimum_size = Vector2(ROW_SIZE)
	btn.size = ROW_SIZE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.flat = true

	var is_online: bool = bool(f.get("online", false))
	var fname: String = str(f.get("name", "Unknown"))
	var flevel: int = int(f.get("level", 1))
	var felem: String = _normalize_element(f.get("element", "Earth"))
	var floc: String = str(f.get("location", "Unknown"))
	var ink := Color(0.14, 0.22, 0.42, 1.0) if is_online else Color(0.50, 0.53, 0.60, 1.0)

	var panel := Panel.new()
	panel.name = "CardPanel"
	panel.position = Vector2.ZERO
	panel.size = ROW_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.add_child(panel)

	# Online status light in the corner of the avatar block
	var light := ColorRect.new()
	light.name = "StatusLight"
	light.position = Vector2(6, 6)
	light.size = Vector2(9, 9)
	light.color = Color(0.22, 0.88, 0.35, 1.0) if is_online else Color(0.55, 0.58, 0.62, 0.8)
	light.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(light)

	# Element badge centred in the avatar block (block is x 0..62)
	var elem_rect := TextureRect.new()
	elem_rect.name = "ElementBadge"
	elem_rect.position = Vector2(15, 15)
	elem_rect.size = Vector2(32, 32)
	elem_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	elem_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	elem_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	var elem_id := _element_name_to_id(felem)
	var elem_tex := _load_texture_file("assets/hud/icon_element_%d.png" % elem_id)
	if elem_tex:
		elem_rect.texture = elem_tex
	elem_rect.tooltip_text = "Element: %s" % felem
	panel.add_child(elem_rect)

	# Level in the top strip of the text area
	var lvl_lbl := Label.new()
	lvl_lbl.name = "LevelLabel"
	lvl_lbl.position = Vector2(68, 4)
	lvl_lbl.size = Vector2(70, 14)
	lvl_lbl.text = "Lv. %d" % flevel
	lvl_lbl.add_theme_font_size_override("font_size", 10)
	lvl_lbl.add_theme_color_override("font_color", ink)
	panel.add_child(lvl_lbl)

	# Name sits right of the baked "nickname:" caption (ends at x = 105)
	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.position = Vector2(110, 22)
	name_lbl.size = Vector2(130, 16)
	name_lbl.text = fname
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", ink)
	panel.add_child(name_lbl)

	# Location sits right of the baked "guild :" caption
	var loc_lbl := Label.new()
	loc_lbl.name = "LocationLabel"
	loc_lbl.position = Vector2(110, 41)
	loc_lbl.size = Vector2(130, 16)
	loc_lbl.text = floc
	loc_lbl.clip_text = true
	loc_lbl.add_theme_font_size_override("font_size", 10)
	loc_lbl.add_theme_color_override("font_color", ink)
	panel.add_child(loc_lbl)

	# Selection mark inside the baked "tick" checkbox
	var tick := ColorRect.new()
	tick.name = "TickMark"
	tick.position = Vector2(283, 42)
	tick.size = Vector2(9, 9)
	tick.color = Color(0.14, 0.22, 0.42, 1.0)
	tick.visible = false
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tick)

	# Quick whisper button above the baked "tick" caption (btn_friend_icon_1, 66x21 scaled)
	var quick_whisper := Button.new()
	quick_whisper.name = "QuickWhisperBtn"
	quick_whisper.position = Vector2(236, 3)
	quick_whisper.size = Vector2(54, 19)
	quick_whisper.custom_minimum_size = Vector2(54, 19)
	quick_whisper.text = "Tell"
	quick_whisper.tooltip_text = "Direct Whisper to %s" % fname
	quick_whisper.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	quick_whisper.add_theme_font_size_override("font_size", 10)
	quick_whisper.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	quick_whisper.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	quick_whisper.add_theme_constant_override("outline_size", 2)

	_apply_button_state_textures(quick_whisper, "btn_friend_icon_1")
	if quick_whisper.has_theme_stylebox_override("normal"):
		quick_whisper.text = "" # the texture bakes the "Friend" caption
	quick_whisper.pressed.connect(func() -> void:
		select_friend(idx)
		whisper_to_friend(fname)
	)
	panel.add_child(quick_whisper)

	btn.pressed.connect(select_friend.bind(idx))
	return btn

## Updates card background textures based on selection state
func _update_card_highlights() -> void:
	if not list_container:
		return
	var cards := list_container.get_children()
	var tex_norm := _load_texture_file("assets/hud/friend_row_bg.png")
	var tex_sel := _load_texture_file("assets/hud/friend_row_bg_selected.png")

	for i in range(cards.size()):
		var card := cards[i] as Button
		if not card:
			continue
		var panel := card.get_node_or_null("CardPanel") as Panel
		if not panel:
			continue

		var selected: bool = (i == _selected_friend_index)
		var sb := StyleBoxTexture.new()
		sb.texture = (tex_sel if tex_sel else tex_norm) if selected else tex_norm
		panel.add_theme_stylebox_override("panel", sb)
		var tick := panel.get_node_or_null("TickMark") as ColorRect
		if tick:
			tick.visible = selected

# ==================== MODAL DIALOG HANDLERS ====================

func _on_btn_add_friend_pressed() -> void:
	AuthAudioScript.play_click()
	if add_modal:
		add_modal.visible = true
		if add_input:
			add_input.text = ""
			add_input.grab_focus()
		if add_error_label:
			add_error_label.text = ""

func _on_add_modal_confirm() -> void:
	AuthAudioScript.play_click()
	if not add_input:
		return
	var clean := add_input.text.strip_edges()
	if clean.is_empty():
		if add_error_label:
			add_error_label.text = "Name cannot be empty!"
		return

	for f in _friends:
		if str(f.get("name", "")).to_lower() == clean.to_lower():
			if add_error_label:
				add_error_label.text = "Player is already in your friends list!"
			return

	add_friend(clean, 1, "Earth", true, "Welling Village")
	if add_modal:
		add_modal.visible = false

func _on_add_modal_cancel() -> void:
	AuthAudioScript.play_click()
	if add_modal:
		add_modal.visible = false

func _on_btn_delete_friend_pressed() -> void:
	AuthAudioScript.play_click()
	if _selected_friend_index < 0 or _selected_friend_index >= _friends.size():
		return
	var fname := str(_friends[_selected_friend_index].get("name", ""))
	if delete_modal:
		delete_modal.visible = true
		if delete_prompt_label:
			delete_prompt_label.text = "Are you sure you want to remove\n'%s' from your friends list?" % fname

func _on_delete_modal_confirm() -> void:
	AuthAudioScript.play_click()
	if _selected_friend_index >= 0 and _selected_friend_index < _friends.size():
		delete_friend(_selected_friend_index)
	if delete_modal:
		delete_modal.visible = false

func _on_delete_modal_cancel() -> void:
	AuthAudioScript.play_click()
	if delete_modal:
		delete_modal.visible = false

# ==================== AUTHENTIC STYLING & HELPERS ====================

func _create_authentic_button(prefix: String, pos: Vector2, sz: Vector2, fallback_text: String = "") -> Button:
	var btn := Button.new()
	btn.position = pos
	btn.size = sz
	btn.custom_minimum_size = sz
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.text = fallback_text

	_apply_button_state_textures(btn, prefix)
	if btn.has_theme_stylebox_override("normal"):
		# The skin texture bakes its own caption ("Add", "Del Friend", "Friend"); flat buttons would hide it.
		btn.flat = false
		btn.text = ""
	else:
		btn.flat = true
	return btn

func _apply_button_state_textures(btn: Button, prefix: String) -> void:
	var tex_norm := _load_texture_file("assets/hud/%s_normal.png" % prefix)
	var tex_hov := _load_texture_file("assets/hud/%s_hover.png" % prefix)
	var tex_prs := _load_texture_file("assets/hud/%s_pressed.png" % prefix)

	if tex_norm:
		var norm := StyleBoxTexture.new()
		norm.texture = tex_norm
		var hov := StyleBoxTexture.new()
		hov.texture = tex_hov if tex_hov else tex_norm
		var prs := StyleBoxTexture.new()
		prs.texture = tex_prs if tex_prs else tex_norm

		btn.add_theme_stylebox_override("normal", norm)
		btn.add_theme_stylebox_override("hover", hov)
		btn.add_theme_stylebox_override("pressed", prs)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_stylebox_override("disabled", norm)

func _apply_close_button_textures(btn: Button) -> void:
	# The close button is a transparent hit area over the x sphere baked into the skin (WindowCloseButton).
	pass

func _normalize_element(elem: Variant) -> String:
	if elem is int:
		match elem:
			1: return "Earth"
			2: return "Water"
			3: return "Fire"
			4: return "Wind"
			_: return "Earth"
	var s := str(elem).to_lower()
	if s == "earth": return "Earth"
	elif s == "water": return "Water"
	elif s == "fire": return "Fire"
	elif s == "wind": return "Wind"
	return "Earth"

func _element_name_to_id(elem_name: String) -> int:
	match elem_name.to_lower():
		"earth": return 1
		"water": return 2
		"fire": return 3
		"wind": return 4
		_: return 1

func _load_texture_file(rel_path: String) -> Texture2D:
	var res_path := "res://" + rel_path.trim_prefix("res://")
	if ResourceLoader.exists(res_path):
		return load(res_path) as Texture2D
	return null
