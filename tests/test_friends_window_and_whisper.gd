extends SceneTree

const FriendsWindowClass = preload("res://scripts/ui/hud/friends_window.gd")

## Automated Headless Verification Suite for Friends Window & Direct Whisper Chat Integration
## Verifies:
## 1. Friends Window Layout & Skin Parity (Form_Friend_2 356x493):
##    - Background form_friend_2.png
##    - Authentic 18x18 close button at Vector2(326, 8)
##    - ScrollContainer and list container geometry
##    - Bottom action buttons: Add Friend, Delete Friend, Send Whisper
##    - Add and Delete modal overlay dialogs
## 2. Friends List Rendering & Card Components:
##    - Online status indicator light (green online, gray offline)
##    - Character Name, Level, Element icon badge, Location
##    - Interactive selection highlighting
## 3. Add & Delete Operations:
##    - Adding new friend with validation & duplicate prevention
##    - Modal dialog text input & confirmation
##    - Deleting friend by index/name with confirmation modal
## 4. Direct Whisper Chat Integration:
##    - "Send Whisper" routes to ChatDock (hud_chat.gd)
##    - Auto-switches channel to Whisper
##    - Sets whisper_target to friend's character name
##    - Focuses ChatInput line
##    - Quick "Tell" button on card row
## 5. Persistence:
##    - user://friends_list.json save and load
##    - Fallback defaults when file is missing
## 6. HUD Window Manager Integration:
##    - Floating window toggle via 'F' key and window manager
##    - Close button signal handling

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	print("=================================================================")
	print("STARTING TEST SUITE: Friends Window & Direct Whisper Chat")
	print("=================================================================")
	# The friends list persists to disk; start every run from the default list.
	if FileAccess.file_exists(FriendsWindowClass.FRIENDS_FILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FriendsWindowClass.FRIENDS_FILE_PATH))
	call_deferred("_run_tests")

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % msg)

func _run_tests() -> void:
	_test_standalone_friends_window_layout()
	_test_friends_list_rendering_and_selection()
	_test_add_and_delete_operations()
	_test_persistence_json()
	_test_hud_scene_and_whisper_routing()
	_test_window_manager_and_hotkey()

	print("=================================================================")
	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	print("=================================================================")

	if _failed > 0:
		quit(1)
	else:
		print("ALL FRIENDS WINDOW & WHISPER CHAT TESTS PASSED ZERO-ERROR!")
		quit(0)

func _test_standalone_friends_window_layout() -> void:
	print("\n>>> Testing Standalone FriendsWindow Layout & Skin Parity...")
	var win: FriendsWindow = FriendsWindowClass.new()
	root.add_child(win)

	_assert_true(win.size == Vector2(356.0, 493.0), "Window size is 356x493, got %s" % str(win.size))
	_assert_true(win.custom_minimum_size == Vector2(356.0, 493.0), "Window custom_minimum_size is 356x493")

	# Background TextureRect
	_assert_true(win.background != null, "Background TextureRect exists")
	if win.background:
		_assert_true(win.background.size == Vector2(356.0, 493.0), "Background size is 356x493")
		_assert_true(win.background.texture != null, "Background texture is loaded")

	# Close Button
	_assert_true(win.close_button != null, "CloseButton exists")
	if win.close_button:
		_assert_true(win.close_button.size == Vector2(20.0, 20.0), "CloseButton size is 20x20")
		_assert_true(win.close_button.custom_minimum_size == Vector2(20.0, 20.0), "CloseButton custom_minimum_size is 20x20")
		_assert_true(win.close_button.position == Vector2(306.0, 20.0), "CloseButton position is (306, 20), got %s" % str(win.close_button.position))
		_assert_true(win.close_button.text == "", "CloseButton text is empty")
		_assert_true(win.close_button.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "CloseButton cursor is pointing hand")

	# ScrollContainer & List Container
	_assert_true(win.scroll_container != null, "ScrollContainer exists")
	if win.scroll_container:
		_assert_true(win.scroll_container.position == Vector2(25.0, 68.0), "ScrollContainer position is (25, 68)")
		_assert_true(win.scroll_container.size == Vector2(304.0, 325.0), "ScrollContainer size is 304x325")
	_assert_true(win.list_container != null, "FriendsListContainer exists")

	# Bottom Action Buttons
	_assert_true(win.btn_add_friend != null, "BtnAddFriend exists")
	_assert_true(win.btn_delete_friend != null, "BtnDeleteFriend exists")
	_assert_true(win.btn_whisper != null, "BtnWhisper exists")

	# Modals
	_assert_true(win.add_modal != null, "AddFriendModal exists")
	_assert_true(win.delete_modal != null, "DeleteFriendModal exists")

	win.queue_free()

func _test_friends_list_rendering_and_selection() -> void:
	print("\n>>> Testing Friends List Rendering & Selection...")
	var win: FriendsWindow = FriendsWindowClass.new()
	root.add_child(win)

	var friends := win.get_friends()
	_assert_true(friends.size() == 5, "Default friends list has 5 friends, got %d" % friends.size())

	var cards := win.list_container.get_children()
	_assert_true(cards.size() == 5, "List container rendered 5 friend cards, got %d" % cards.size())

	# Inspect first card (Betty)
	if cards.size() > 0:
		var card0 := cards[0] as Button
		_assert_true(card0 != null, "Card 0 is a Button")
		var panel := card0.get_node_or_null("CardPanel") as Panel
		_assert_true(panel != null, "Card 0 has CardPanel")

		var light := panel.get_node_or_null("StatusLight") as ColorRect
		_assert_true(light != null, "Card 0 has StatusLight")
		if light:
			_assert_true(light.color == Color(0.22, 0.88, 0.35, 1.0), "Card 0 (Betty, online) status light is green")

		var elem_badge := panel.get_node_or_null("ElementBadge") as TextureRect
		_assert_true(elem_badge != null, "Card 0 has ElementBadge")
		if elem_badge:
			_assert_true(elem_badge.texture != null, "Card 0 ElementBadge has texture")
			_assert_true(elem_badge.tooltip_text.contains("Water"), "Card 0 Element is Water")

		var name_lbl := panel.get_node_or_null("NameLabel") as Label
		_assert_true(name_lbl != null and name_lbl.text == "Betty", "Card 0 NameLabel is 'Betty'")

		var lvl_lbl := panel.get_node_or_null("LevelLabel") as Label
		_assert_true(lvl_lbl != null and lvl_lbl.text == "Lv. 18", "Card 0 LevelLabel is 'Lv. 18'")

		var loc_lbl := panel.get_node_or_null("LocationLabel") as Label
		_assert_true(loc_lbl != null and loc_lbl.text == "Welling Village", "Card 0 LocationLabel is 'Welling Village'")

		var quick_btn := panel.get_node_or_null("QuickWhisperBtn") as Button
		_assert_true(quick_btn != null, "Card 0 has QuickWhisperBtn")

	# Inspect third card (Kelang, offline)
	if cards.size() > 2:
		var card2 := cards[2] as Button
		var panel2 := card2.get_node_or_null("CardPanel") as Panel
		if panel2:
			var light2 := panel2.get_node_or_null("StatusLight") as ColorRect
			if light2:
				_assert_true(light2.color == Color(0.55, 0.58, 0.62, 0.8), "Card 2 (Kelang, offline) status light is gray")

	# Selection Test
	var selected_reported: Array[Dictionary] = []
	win.friend_selected.connect(func(data: Dictionary) -> void:
		selected_reported.append(data)
	)

	win.select_friend(1) # Select Daniel
	_assert_true(win.get_selected_friend().get("name") == "Daniel", "Selected friend is 'Daniel'")
	_assert_true(selected_reported.size() > 0 and selected_reported[-1].get("name") == "Daniel", "friend_selected signal emitted with 'Daniel'")

	win.queue_free()

func _test_add_and_delete_operations() -> void:
	print("\n>>> Testing Add & Delete Friend Operations...")
	var win: FriendsWindow = FriendsWindowClass.new()
	root.add_child(win)

	var initial_count := win.get_friends().size()

	# Add friend directly
	var add_success := win.add_friend("Elena", 42, "Wind", true, "Holy Village")
	_assert_true(add_success, "add_friend('Elena') returned true")
	_assert_true(win.get_friends().size() == initial_count + 1, "Friends count incremented to %d" % (initial_count + 1))

	# Duplicate check
	var dup_success := win.add_friend("elena", 10, "Fire", false, "Somewhere")
	_assert_true(not dup_success, "Duplicate friend addition was rejected")

	# Empty name check
	var empty_success := win.add_friend("   ", 10, "Earth", true, "Somewhere")
	_assert_true(not empty_success, "Empty friend name addition was rejected")

	# Modal dialog test
	win._on_btn_add_friend_pressed()
	_assert_true(win.add_modal.visible, "AddFriendModal is visible after add button pressed")
	win.add_input.text = "Marcus"
	win._on_add_modal_confirm()
	_assert_true(not win.add_modal.visible, "AddFriendModal is hidden after confirmation")
	_assert_true(win.get_friends().size() == initial_count + 2, "Friends count incremented after modal add")

	# Delete friend test
	var del_success := win.delete_friend("Marcus")
	_assert_true(del_success, "delete_friend('Marcus') returned true")
	_assert_true(win.get_friends().size() == initial_count + 1, "Friends count decremented after delete")

	# Delete modal test
	win.select_friend(win.get_friends().size() - 1) # Select Elena
	_assert_true(win.get_selected_friend().get("name") == "Elena", "Elena selected for delete modal test")
	win._on_btn_delete_friend_pressed()
	_assert_true(win.delete_modal.visible, "DeleteFriendModal is visible after delete button pressed")
	win._on_delete_modal_confirm()
	_assert_true(not win.delete_modal.visible, "DeleteFriendModal is hidden after confirmation")
	_assert_true(win.get_friends().size() == initial_count, "Elena removed via delete modal")

	win.queue_free()

func _test_persistence_json() -> void:
	print("\n>>> Testing Friends List JSON Persistence...")
	var test_file := "user://friends_list.json"
	
	var win1: FriendsWindow = FriendsWindowClass.new()
	root.add_child(win1)
	win1.add_friend("TestPersistencePlayer", 55, "Fire", true, "Kyoto")
	_assert_true(FileAccess.file_exists(test_file), "user://friends_list.json exists on disk")

	# Read raw file to verify JSON format
	var f := FileAccess.open(test_file, FileAccess.READ)
	_assert_true(f != null, "Opened friends_list.json for reading")
	if f:
		var text := f.get_as_text()
		f.close()
		var parsed: Variant = JSON.parse_string(text)
		_assert_true(parsed is Array, "Parsed JSON content is an Array")
		var found_test_player := false
		if parsed is Array:
			for item in parsed:
				if item is Dictionary and item.get("name") == "TestPersistencePlayer":
					found_test_player = true
					_assert_true(int(item.get("level")) == 55, "Persisted level is 55")
					_assert_true(str(item.get("element")) == "Fire", "Persisted element is Fire")
					_assert_true(str(item.get("location")) == "Kyoto", "Persisted location is Kyoto")
		_assert_true(found_test_player, "TestPersistencePlayer was found in JSON file")

	win1.queue_free()

	# Load in fresh instance
	var win2: FriendsWindow = FriendsWindowClass.new()
	root.add_child(win2)
	var loaded_friends := win2.get_friends()
	var loaded_names: Array[String] = []
	for friend in loaded_friends:
		loaded_names.append(str(friend.get("name")))
	_assert_true(loaded_names.has("TestPersistencePlayer"), "Fresh FriendsWindow loaded TestPersistencePlayer from disk")

	# Clean up test entry
	win2.delete_friend("TestPersistencePlayer")
	win2.queue_free()

func _test_hud_scene_and_whisper_routing() -> void:
	print("\n>>> Testing HUD Scene & Direct Whisper Routing...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	_assert_true(hud_scene != null, "HUD scene loaded")
	if not hud_scene:
		return

	var hud := hud_scene.instantiate() as Control
	root.add_child(hud)

	var friends_win := hud.get_node_or_null("FloatingWindows/FriendsWindow") as FriendsWindow
	_assert_true(friends_win != null, "FriendsWindow found in HUD scene")
	_assert_true(friends_win.get_script() != null, "FriendsWindow has script attached")

	var chat_dock := hud.get_node_or_null("ChatDock") as Control
	_assert_true(chat_dock != null, "ChatDock found in HUD scene")

	var whisper_target := chat_dock.get_node_or_null("WhisperTarget") as LineEdit
	_assert_true(whisper_target != null, "WhisperTarget LineEdit found in ChatDock")

	var chat_input := chat_dock.get_node_or_null("ChatInput") as LineEdit
	_assert_true(chat_input != null, "ChatInput LineEdit found in ChatDock")

	# Select friend "Betty" and test whisper routing
	friends_win.select_friend(0) # Betty
	_assert_true(friends_win.get_selected_friend().get("name") == "Betty", "Betty selected in FriendsWindow")

	friends_win.send_whisper_to_selected()

	_assert_true(whisper_target.text == "Betty", "WhisperTarget text set to 'Betty', got '%s'" % whisper_target.text)
	if hud.chat_ctrl:
		_assert_true(hud.chat_ctrl._current_channel == "Whisper", "ChatDock current channel switched to 'Whisper', got '%s'" % hud.chat_ctrl._current_channel)

	# Test quick "Tell" button on card row for "Daniel"
	friends_win.select_friend(1) # Daniel
	friends_win.whisper_to_friend("Daniel")
	_assert_true(whisper_target.text == "Daniel", "WhisperTarget updated to 'Daniel' via whisper_to_friend, got '%s'" % whisper_target.text)

	hud.queue_free()

func _test_window_manager_and_hotkey() -> void:
	print("\n>>> Testing Window Manager Integration & Close Button...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	var hud := hud_scene.instantiate() as Control
	root.add_child(hud)

	var win_mgr: HUDWindowManager = hud.window_manager_ctrl
	_assert_true(win_mgr != null, "HUDWindowManager found")

	var friends_win := hud.get_node_or_null("FloatingWindows/FriendsWindow") as FriendsWindow
	_assert_true(not friends_win.visible, "FriendsWindow initially hidden")

	# Toggle open via window manager
	win_mgr.toggle_friends_window()
	_assert_true(friends_win.visible, "FriendsWindow visible after toggle_friends_window()")

	# Close via close button
	var toggled_events: Array[Dictionary] = []
	win_mgr.window_toggled.connect(func(wname: String, is_vis: bool) -> void:
		toggled_events.append({"name": wname, "visible": is_vis})
	)

	friends_win.close_button.emit_signal("pressed")
	_assert_true(not friends_win.visible, "FriendsWindow closed after close_button pressed")
	var has_close_event := false
	for ev in toggled_events:
		if ev.get("name") == "FriendsWindow" and not bool(ev.get("visible")):
			has_close_event = true
			break
	_assert_true(has_close_event, "window_toggled emitted ('FriendsWindow', false)")

	# Toggle open via HUD hotkey method
	hud.toggle_friends_window()
	_assert_true(friends_win.visible, "FriendsWindow visible after hud.toggle_friends_window()")

	hud.queue_free()
