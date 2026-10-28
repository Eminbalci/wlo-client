extends SceneTree

## Comprehensive Verification Test Suite for Chat Dock Parity & Polish

func _init() -> void:
	print("\n=================================================================")
	print("--- Running In-Engine Verification of Chat Dock Polish & Parity ---")
	print("=================================================================\n")

	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "ERROR: Failed to load res://scenes/ui/hud.tscn")

	var hud: Control = hud_scene.instantiate() as Control
	assert(hud != null, "ERROR: Failed to instantiate HUD")
	root.add_child(hud)

	await process_frame
	await process_frame

	_test_channel_tabs_styling(hud)
	_test_chat_scrollbar_and_typography(hud)
	_test_bottom_bar_geometry_and_alignment(hud)
	_test_whisper_auto_layout(hud)
	_test_channel_colors_and_filtering(hud)
	_test_resizing_and_framing(hud)
	_render_chat_dock_verification_snapshot(hud)

	print("\n=================================================================")
	print("--- ALL CHAT DOCK POLISH VERIFICATIONS PASSED (100% ZERO-ERROR) -")
	print("=================================================================\n")
	quit(0)

func _test_channel_tabs_styling(hud: Control) -> void:
	print(">>> [TEST 1] Verifying Channel Tabs Styling & Active States...")
	var tabs = [
		hud.btn_tab_all, hud.btn_tab_current, hud.btn_tab_team,
		hud.btn_tab_guild, hud.btn_tab_whisper, hud.btn_tab_system
	]
	for btn in tabs:
		assert(btn != null, "Tab button must exist")
		assert(btn.has_theme_stylebox_override("normal"), "Tab button must have custom normal StyleBoxFlat")
		assert(btn.has_theme_stylebox_override("hover"), "Tab button must have custom hover StyleBoxFlat")
		assert(btn.has_theme_stylebox_override("pressed"), "Tab button must have custom pressed StyleBoxFlat")
		var normal_sb = btn.get_theme_stylebox("normal") as StyleBoxFlat
		assert(normal_sb != null, "Normal style must be StyleBoxFlat")
		assert(normal_sb.corner_radius_top_left == 3, "Tab must have rounded top-left corner")

	# Test active tab styling change
	hud.select_chat_tab("Team")
	assert(hud._active_chat_tab == "Team", "Active chat tab should be Team")
	var team_btn = hud.btn_tab_team
	var team_sb = team_btn.get_theme_stylebox("normal") as StyleBoxFlat
	assert(team_sb.border_width_top == 2, "Active tab must have prominent 2px top gold border")
	assert(team_btn.get_theme_color("font_color") == Color(1.0, 0.92, 0.35, 1.0), "Active tab font color must be radiant gold")

	# Inactive tab check
	var all_btn = hud.btn_tab_all
	var all_sb = all_btn.get_theme_stylebox("normal") as StyleBoxFlat
	assert(all_sb.border_width_top == 1, "Inactive tab must have subtle 1px border")
	print("  [OK] Channel tabs custom StyleBoxFlat, active/inactive states & typography verified.")

func _test_chat_scrollbar_and_typography(hud: Control) -> void:
	print(">>> [TEST 2] Verifying Custom Sleek Scrollbar & Typography...")
	var chat_hist: RichTextLabel = hud.chat_history
	assert(chat_hist != null, "ChatHistory node must exist")
	assert(chat_hist.get_theme_font_size("normal_font_size") == 12, "Font size must be 12px")
	assert(chat_hist.get_theme_constant("line_separation") == 2, "Line separation must be 2px")

	var v_scroll: VScrollBar = chat_hist.get_v_scroll_bar()
	assert(v_scroll != null, "VScrollBar must exist")
	assert(v_scroll.custom_minimum_size.x == 6.0, "VScrollBar width must be sleek 6px")
	assert(v_scroll.has_theme_stylebox_override("scroll"), "VScrollBar must have custom scroll StyleBox")
	assert(v_scroll.has_theme_stylebox_override("grabber"), "VScrollBar must have custom grabber StyleBox")
	var grabber_sb = v_scroll.get_theme_stylebox("grabber") as StyleBoxFlat
	assert(grabber_sb != null, "Grabber must be StyleBoxFlat")
	assert(grabber_sb.border_width_left == 1, "Grabber must have subtle border")
	print("  [OK] Custom 6px parchment scrollbar and crisp typography verified.")

func _test_bottom_bar_geometry_and_alignment(hud: Control) -> void:
	print(">>> [TEST 3] Verifying Bottom Bar Geometry & Slot Alignment...")
	var btn_mail = hud.btn_mail
	assert(btn_mail != null, "BtnMail must exist")
	assert(btn_mail.position.x == 3.0, "BtnMail position.x must be 3.0 (aligned with slot)")
	assert(btn_mail.size.x == 26.0, "BtnMail size.x must be 26.0 (fitting mailbox slot)")
	assert(btn_mail.size.y == 21.0, "BtnMail size.y must be 21.0")
	assert(btn_mail.texture_normal != null, "BtnMail must have envelope texture")

	var btn_channel = hud.btn_channel
	assert(btn_channel != null, "BtnChannel must exist")
	assert(btn_channel.position.x == 30.0, "BtnChannel position.x must be 30.0 (aligned with channel slot)")
	assert(btn_channel.size.x == 42.0, "BtnChannel size.x must be 42.0 (fitting channel slot)")
	assert(btn_channel.size.y == 21.0, "BtnChannel size.y must be 21.0")

	var btn_emote = hud.btn_emote
	assert(btn_emote != null, "BtnEmote must exist")
	assert(btn_emote.position.x == hud._dock_width - 27.0, "BtnEmote must be at right margin (%f)" % (hud._dock_width - 27.0))
	assert(btn_emote.texture_normal != null, "BtnEmote must have expression icon")
	print("  [OK] Bottom bar slots (Mail 3..29, Channel 30..72, Emote right edge) verified.")

func _test_whisper_auto_layout(hud: Control) -> void:
	print(">>> [TEST 4] Verifying Dynamic WhisperTarget & ChatInput Auto-Fitting...")
	# The real client always shows the recipient field (x 74, width 86) beside the message field (x 163)
	hud._select_channel("Local")
	assert(hud.whisper_target.visible == true, "The recipient field is always visible")
	assert(hud.whisper_target.position.x == 74.0, "Recipient field at 74.0")
	assert(hud.whisper_target.size.x == 86.0, "Recipient field width must be 86.0")
	assert(hud.chat_input.position.x == 163.0, "ChatInput starts at 163.0 in Local mode")
	assert(hud.chat_input.size.x >= 300.0, "ChatInput expands across the bar")

	hud._select_channel("Whisper")
	assert(hud.chat_input.position.x == 163.0, "ChatInput stays at 163.0 in Whisper mode")
	hud._select_channel("Local")
	assert(hud.chat_input.position.x == 163.0, "ChatInput stays at 163.0 when returning to Local")
	print("  [OK] Dynamic input bar auto-fitting between Local and Whisper modes verified.")

func _test_channel_colors_and_filtering(hud: Control) -> void:
	print(">>> [TEST 5] Verifying Authentic Channel Colors & Tab Filtering...")
	hud.chat_history.clear()
	hud.add_chat_message("Server", "Welcome to Wonderland Online!", "System")
	hud.add_chat_message("Traveler", "Hello world!", "Local")
	hud.add_chat_message("Captain", "All aboard!", "Team")
	hud.add_chat_message("Leader", "Guild castle secured.", "Guild")
	hud.add_chat_message("Friend", "Secret whisper msg.", "Whisper")

	hud.select_chat_tab("All")
	var parsed: String = hud.chat_history.get_parsed_text()
	assert(parsed.contains("Welcome to Wonderland Online"), "System message must be in All tab")
	assert(parsed.contains("Hello world"), "Local message must be in All tab")
	assert(parsed.contains("All aboard"), "Team message must be in All tab")
	assert(parsed.contains("Guild castle secured"), "Guild message must be in All tab")
	assert(parsed.contains("Secret whisper msg"), "Whisper message must be in All tab")

	hud.select_chat_tab("System")
	var sys_parsed: String = hud.chat_history.get_parsed_text()
	assert(sys_parsed.contains("Welcome to Wonderland Online"), "System message must be in System tab")
	assert(not sys_parsed.contains("Hello world"), "Local message must NOT be in System tab")

	hud.select_chat_tab("Whisper")
	var w_parsed: String = hud.chat_history.get_parsed_text()
	assert(w_parsed.contains("Secret whisper msg"), "Whisper message must be in Whisper tab")
	assert(not w_parsed.contains("All aboard"), "Team message must NOT be in Whisper tab")
	print("  [OK] Authentic channel formatting and tab filtering verified.")

func _test_resizing_and_framing(hud: Control) -> void:
	print(">>> [TEST 6] Verifying Resizing, Tab Synchronization & Framing...")
	var initial_top = hud.chat_history_panel.offset_top
	hud.btn_chat_size.pressed.emit()
	assert(hud.chat_history_panel.offset_top == -140.0, "Step 1 top offset mismatch")
	assert(hud.channel_tabs.offset_bottom == -140.0, "ChannelTabs bottom must sync with ChatHistoryPanel top")
	assert(hud.channel_tabs.offset_top == -161.0, "ChannelTabs top must be offset -21px from panel top")

	# Chat Box Switch (observed in the real client): hides the log, a second press brings it back
	assert(hud.is_chat_box_collapsed() == false, "Initially the chat box is shown")
	hud.btn_chat_switch.pressed.emit()
	assert(hud.is_chat_box_collapsed() == true, "Chat Box Switch collapses the box")
	assert(hud.chat_history.visible == false, "The log is hidden while collapsed")
	hud.btn_chat_switch.pressed.emit()
	assert(hud.is_chat_box_collapsed() == false, "A second press restores the box")
	assert(hud.chat_history.visible == true, "The log is visible again")

	# Reset height
	hud.set_chat_height(-86.0)
	assert(hud.chat_history_panel.offset_top == -86.0, "Reset height verified")
	print("  [OK] Chat resizing, synchronized tab tracking, and framing toggles verified.")

func _render_chat_dock_verification_snapshot(hud: Control) -> void:
	print(">>> [TEST 7] Rendering Verification Snapshot of Chat Dock...")
	hud.select_chat_tab("All")
	await hud.get_tree().process_frame
	await hud.get_tree().process_frame
	var img = hud.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://tests/chat_dock_verified_render.png")
		print("  [OK] Rendered verification snapshot to res://tests/chat_dock_verified_render.png")
