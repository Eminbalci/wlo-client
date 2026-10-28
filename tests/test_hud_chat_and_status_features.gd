extends SceneTree

func _init() -> void:
	print("--- Running In-Engine Verification of Chat Dock & Player Status Enhancements ---")
	
	var hud_scene = preload("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	
	# Wait one frame for _ready
	await process_frame
	
	# --------------------------------------------------------------------------
	# 1. Verify PlayerStatusDock: Element Icon & Role Avatar
	# --------------------------------------------------------------------------
	print("[TEST 1] Verifying PlayerStatusDock Element Icon & Role Avatar...")
	var status_dock = hud.get_node("PlayerStatusDock")
	assert(status_dock != null, "PlayerStatusDock missing")
	
	var elem_icon = status_dock.get_node("ElementIcon") as TextureRect
	assert(elem_icon != null, "ElementIcon missing")
	assert(elem_icon.texture != null, "ElementIcon texture missing")
	
	# Test element switching (Earth=1, Water=2, Fire=3, Wind=4)
	hud.set_player_element("Earth")
	assert(elem_icon.texture.resource_path.ends_with("icon_element_1.png"), "Element Earth mismatch: %s" % elem_icon.texture.resource_path)
	
	hud.set_player_element("Water")
	assert(elem_icon.texture.resource_path.ends_with("icon_element_2.png"), "Element Water mismatch: %s" % elem_icon.texture.resource_path)
	
	hud.set_player_element("Fire")
	assert(elem_icon.texture.resource_path.ends_with("icon_element_3.png"), "Element Fire mismatch: %s" % elem_icon.texture.resource_path)
	
	hud.set_player_element("Wind")
	assert(elem_icon.texture.resource_path.ends_with("icon_element_4.png"), "Element Wind mismatch: %s" % elem_icon.texture.resource_path)
	
	hud.set_player_element(1)
	assert(elem_icon.texture.resource_path.ends_with("icon_element_1.png"), "Element int 1 mismatch")
	
	print("  PASS: Element icon dynamic mapping and texture updates verified for all 4 elements")
	
	# Test Role Avatar mappings
	var avatar_rect = status_dock.get_node("AvatarRect") as TextureRect
	assert(avatar_rect != null, "AvatarRect missing")
	assert(avatar_rect.texture != null, "AvatarRect texture missing")
	
	# Role 6 = Daniel
	hud.set_player_role(6)
	assert(hud._avatar_frames.size() >= 1, "Role 6 frames not loaded")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Role 6 texture mismatch")
	
	# Role 2 = Betty
	hud.set_player_role(2)
	assert(hud._avatar_frames.size() >= 1, "Role 2 frames not loaded")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Role 2 texture mismatch")
	
	# Role 1 = Nina
	hud.set_player_role(1)
	assert(hud._avatar_frames.size() >= 1, "Role 1 frames not loaded")
	assert(avatar_rect.texture == hud._avatar_frames[0], "Role 1 texture mismatch")
	
	print("  PASS: Role avatar switching verified (Daniel, Betty, Nina)")
	
	# --------------------------------------------------------------------------
	# 2. Verify ChatDock Controls: Switch, Lock, Size, Channel, Whisper, Emotes
	# --------------------------------------------------------------------------
	print("[TEST 2] Verifying ChatDock Authentic Controls...")
	var chat_dock = hud.get_node("ChatDock")
	assert(chat_dock != null, "ChatDock missing")
	
	# Test Chat Box Switch (real client: hides / restores the whole log)
	var btn_switch = hud.btn_chat_switch
	assert(btn_switch != null, "btn_chat_switch missing")
	assert(hud.is_chat_box_collapsed() == false, "Chat should start shown")
	btn_switch.pressed.emit()
	assert(hud.is_chat_box_collapsed() == true, "Chat switch collapses the chat box")
	btn_switch.pressed.emit()
	assert(hud.is_chat_box_collapsed() == false, "Chat switch restores the chat box")
	assert(btn_switch.tooltip_text == "Chat Box Switch", "Switch tooltip matches the real client")
	print("  PASS: Chat Box Switch collapses and restores the chat box")
	
	# Test Message Lock
	var btn_lock = hud.btn_msg_lock
	assert(btn_lock != null, "btn_msg_lock missing")
	assert(hud._chat_is_locked == false, "Chat lock should start unlocked")
	
	btn_lock.pressed.emit()
	assert(hud._chat_is_locked == true, "Chat lock should toggle to true")
	assert(hud.chat_history.scroll_following == false, "Scroll following should be disabled when locked")
	
	btn_lock.pressed.emit()
	assert(hud._chat_is_locked == false, "Chat lock should toggle to false")
	assert(hud.chat_history.scroll_following == true, "Scroll following should be enabled when unlocked")
	print("  PASS: Chat message lock button toggles autoscroll behavior")
	
	# Test Chat Size Resize Button
	var btn_size = hud.btn_chat_size
	assert(btn_size != null, "btn_chat_size missing")
	var initial_top = hud.chat_history_panel.offset_top
	btn_size.pressed.emit()
	assert(hud.chat_history_panel.offset_top == -140.0, "Chat height step 1 mismatch: %f" % hud.chat_history_panel.offset_top)
	btn_size.pressed.emit()
	assert(hud.chat_history_panel.offset_top == -200.0, "Chat height step 2 mismatch: %f" % hud.chat_history_panel.offset_top)
	btn_size.pressed.emit()
	assert(hud.chat_history_panel.offset_top == -86.0, "Chat height step 0 mismatch: %f" % hud.chat_history_panel.offset_top)
	print("  PASS: Chat size button cycles heights (-86, -140, -200)")
	
	# Test Channel Dropdown Selection
	var btn_channel = hud.btn_channel
	assert(btn_channel != null, "btn_channel missing")
	assert(btn_channel.text == "Local", "Default channel should be Local")
	
	hud._select_channel("Guild")
	assert(hud._current_channel == "Guild", "Current channel mismatch: %s" % hud._current_channel)
	assert(btn_channel.text == "Guild", "Button text mismatch: %s" % btn_channel.text)
	
	hud._select_channel("Team")
	assert(hud._current_channel == "Team", "Current channel mismatch: %s" % hud._current_channel)
	assert(btn_channel.text == "Team", "Button text mismatch: %s" % btn_channel.text)
	
	hud._select_channel("Local")
	assert(hud._current_channel == "Local", "Current channel mismatch: %s" % hud._current_channel)
	print("  PASS: Channel dropdown selection works cleanly")
	
	# Test Whisper Target Routing
	var whisper = hud.whisper_target
	assert(whisper != null, "whisper_target missing")
	whisper.text = "PlayerTwo"
	whisper.text_changed.emit("PlayerTwo")
	assert(hud._current_channel == "Whisper", "Whisper channel should be auto-selected on target entry")
	assert(btn_channel.text == "Whisper", "Button text should display Whisper")
	
	hud.chat_input.text = "Hello there!"
	hud.send_button.pressed.emit()
	# Check that whisper formatted message was added to chat history
	var ch_text: String = hud.chat_history.get_parsed_text()
	assert(ch_text.contains("To PlayerTwo") or hud.chat_history.text.contains("To PlayerTwo"), "Chat history missing whisper formatted text: parsed='%s', raw='%s'" % [ch_text, hud.chat_history.text])
	print("  PASS: Whisper target automatically updates channel and formats chat output")
	
	# Test Emote Picker Popup and 31 Emote Icons
	var btn_emote = hud.btn_emote
	assert(btn_emote != null, "btn_emote missing")
	var emote_popup = hud.emote_popup
	assert(emote_popup != null, "emote_popup missing")
	assert(emote_popup.visible == false, "Emote popup should start hidden")
	
	btn_emote.pressed.emit()
	assert(emote_popup.visible == true, "Emote popup should be visible after button press")
	
	var emote_grid = hud.emote_grid
	assert(emote_grid != null, "emote_grid missing")
	assert(emote_grid.get_child_count() == 31, "Emote grid must have exactly 31 emote buttons (got %d)" % emote_grid.get_child_count())
	
	# Click emote button 1 (#01)
	var emitted_bubble := [""]
	hud.overhead_bubble_emitted.connect(func(c): emitted_bubble[0] = c)

	var first_emote_btn = emote_grid.get_child(0) as TextureButton
	assert(first_emote_btn != null, "First emote button missing")
	first_emote_btn.pressed.emit()
	assert(hud.chat_input.text.contains("#01"), "Chat input should contain #01 after clicking first emote, got: %s" % hud.chat_input.text)
	assert(emote_popup.visible == false, "Emote popup should close after selecting emote")
	assert(emitted_bubble[0] == "#01", "Emote selection must trigger overhead speech bubble emission (got '%s')" % emitted_bubble[0])
	print("  PASS: Emote popup with 31 authentic emotes verified, inserting code and emitting overhead bubble")

	# Test Vertical Draggable Resizer Handle
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.global_position = Vector2(500, 500)
	hud._on_chat_size_gui_input(mouse_down)
	assert(hud._chat_is_resizing == true, "Chat should be in resizing state")

	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.global_position = Vector2(500, 450)
	hud._on_chat_size_gui_input(mouse_motion)
	assert(hud.chat_history_panel.offset_top < -86.0, "Chat height should expand upwards on drag")

	var mouse_up := InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	hud._on_chat_size_gui_input(mouse_up)
	assert(hud._chat_is_resizing == false, "Chat resizing should stop on mouse release")
	print("  PASS: Vertical draggable resizer handle verified")

	# Test Channel Tabs (All, Current, Team, Guild, Whisper, System)
	assert(hud.channel_tabs != null, "Channel tabs container missing")
	assert(hud.btn_tab_all != null, "BtnTabAll missing")
	assert(hud.btn_tab_current != null, "BtnTabCurrent missing")
	assert(hud.btn_tab_team != null, "BtnTabTeam missing")
	assert(hud.btn_tab_guild != null, "BtnTabGuild missing")
	assert(hud.btn_tab_whisper != null, "BtnTabWhisper missing")
	assert(hud.btn_tab_system != null, "BtnTabSystem missing")

	# Add messages across various channels
	hud.add_chat_message("Captain", "Ahoy mates!", "Local")
	hud.add_chat_message("Ally", "Team rally point set.", "Team")
	hud.add_chat_message("Leader", "Guild meeting at 8.", "Guild")

	# Filter by Team tab
	hud.select_chat_tab("Team")
	assert(hud._active_chat_tab == "Team", "Active chat tab should be Team")
	var team_text: String = hud.chat_history.get_parsed_text()
	assert(team_text.contains("Team rally point set"), "Team tab must contain team message")
	assert(not team_text.contains("Guild meeting at 8"), "Team tab must NOT contain guild message")

	# Filter by Guild tab
	hud.select_chat_tab("Guild")
	assert(hud._active_chat_tab == "Guild", "Active chat tab should be Guild")
	var guild_text: String = hud.chat_history.get_parsed_text()
	assert(guild_text.contains("Guild meeting at 8"), "Guild tab must contain guild message")
	assert(not guild_text.contains("Team rally point set"), "Guild tab must NOT contain team message")

	# Filter by All tab
	hud.select_chat_tab("All")
	var all_text: String = hud.chat_history.get_parsed_text()
	assert(all_text.contains("Team rally point set") and all_text.contains("Guild meeting at 8"), "All tab must display all channel messages")
	print("  PASS: Channel tabs (All, Current, Team, Guild, Whisper, System) filtering verified")

	# Test /target command syntax
	hud._on_chat_submitted("/target Jack Hey Jack let's party")
	assert(hud.whisper_target.text == "Jack", "Whisper target should be Jack after /target")
	assert(hud._current_channel == "Whisper", "Channel should switch to Whisper")
	var w_parsed: String = hud.chat_history.get_parsed_text()
	assert(w_parsed.contains("To Jack") and w_parsed.contains("Hey Jack let's party"), "Whisper message to Jack missing from chat history")
	print("  PASS: /target syntax correctly sets whisper target and dispatches private message")

	# Test clicking player name to whisper
	hud._on_chat_meta_clicked("whisper:Ross")
	assert(hud.whisper_target.text == "Ross", "Clicking Ross's name must update whisper target to Ross")
	assert(hud._current_channel == "Whisper", "Clicking Ross's name must switch channel to Whisper")
	print("  PASS: Clicking player name in chat automatically routes to whisper targeting")

	print("--- ALL CHAT DOCK & PLAYER STATUS TESTS PASSED (0 ERRORS) ---")
	quit(0)
