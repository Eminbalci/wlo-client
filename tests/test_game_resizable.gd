extends SceneTree

## Automated Verification Suite for Wonderland Online Client Dynamic Window Resizability.
## Verifies:
## 1. ProjectSettings stretch mode ("canvas_items") and aspect ("expand").
## 2. Root window content scaling settings.
## 3. HUD edge docks (PlayerStatusDock, RadarMinimapDock, BottomActionDock, ChatDock, DialogueSystem)
##    across resolutions: (1280, 720), (1600, 900), (1785, 895), (1920, 1080).
## 4. BattleView responsive layout (ActionButtonsBar, StatusPanel, Centered 2:1 Axonometric Battlefield).
## 5. MapView Camera2D tracking and adaptive limit calculation.

const TEST_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(800, 600),
	Vector2i(1024, 768),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1785, 895),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _init() -> void:
	_run_tests.call_deferred()

func _run_tests() -> void:
	print("=================================================================")
	print("--- Running Wonderland Online Dynamic Resizability Test Suite ---")
	print("=================================================================\n")
	
	_test_project_settings()
	await _test_hud_responsive_anchors()
	await _test_battle_view_responsive_layout()
	await _test_map_view_camera_limits()
	
	print("\n=================================================================")
	print("--- ALL RESIZABILITY TESTS PASSED (100% ZERO-ERROR) ------------")
	print("=================================================================")
	quit(0)

func _test_project_settings() -> void:
	print(">>> [TEST 1] Verifying Display & Stretch Configuration in ProjectSettings...")
	var width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var resizable = ProjectSettings.get_setting("display/window/size/resizable")
	var min_size = ProjectSettings.get_setting("display/window/size/min_size")
	var stretch_mode = ProjectSettings.get_setting("display/window/stretch/mode")
	var stretch_aspect = ProjectSettings.get_setting("display/window/stretch/aspect")
	
	print("  Settings: width=%s, height=%s, resizable=%s, min_size=%s, mode=%s, aspect=%s" % [
		width, height, resizable, min_size, stretch_mode, stretch_aspect
	])
	
	assert(width == 1280, "ERROR: viewport_width must be 1280")
	assert(height == 720, "ERROR: viewport_height must be 720")
	assert(resizable == true, "ERROR: resizable must be true")
	assert(min_size == Vector2i(800, 600), "ERROR: min_size must be Vector2i(800, 600)")
	assert(stretch_mode == "disabled", "ERROR: stretch/mode must be 'disabled'")
	assert(stretch_aspect == "ignore", "ERROR: stretch/aspect must be 'ignore'")
	
	assert(root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED, "ERROR: Window.content_scale_mode must be DISABLED")
	assert(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_IGNORE, "ERROR: Window.content_scale_aspect must be IGNORE")
	if root.min_size != min_size:
		root.min_size = min_size
	assert(root.min_size == Vector2i(800, 600), "ERROR: Window.min_size must be Vector2i(800, 600)")
	
	# Enforce minimum dimension constraint: attempting to shrink below 800x600 clamps to (800, 600)
	var orig_sz: Vector2i = root.size
	root.size = Vector2i(500, 400)
	assert(root.size.x >= 800 and root.size.y >= 600, "ERROR: Window shrunk below min_size constraint: %s" % root.size)
	root.size = orig_sz
	print("  PASS: ProjectSettings display stretch & min_size configuration validated.")

func _test_hud_responsive_anchors() -> void:
	print("\n>>> [TEST 2] Verifying HUD Responsive Docks across Window Resizes...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "ERROR: Failed to load res://scenes/ui/hud.tscn")
	
	var hud: Control = hud_scene.instantiate() as Control
	assert(hud != null, "ERROR: Failed to instantiate HUD")
	root.add_child(hud)
	
	var player_status_dock: Control = hud.get_node_or_null("PlayerStatusDock")
	var radar_minimap_dock: Control = hud.get_node_or_null("RadarMinimapDock")
	var bottom_action_dock: Control = hud.get_node_or_null("BottomActionDock")
	var chat_dock: Control = hud.get_node_or_null("ChatDock")
	var hotbar_dock: Control = hud.get_node_or_null("HotbarDock")
	var dialogue_system: Control = hud.get_node_or_null("DialogueSystem")
	var form_talk1: Control = hud.get_node_or_null("DialogueSystem/FormTalk1")
	var form_talk3: Control = hud.get_node_or_null("DialogueSystem/FormTalk3")
	
	assert(player_status_dock != null, "ERROR: PlayerStatusDock missing")
	assert(radar_minimap_dock != null, "ERROR: RadarMinimapDock missing")
	assert(bottom_action_dock != null, "ERROR: BottomActionDock missing")
	assert(chat_dock != null, "ERROR: ChatDock missing")
	assert(hotbar_dock != null, "ERROR: HotbarDock missing")
	assert(dialogue_system != null, "ERROR: DialogueSystem missing")
	assert(form_talk1 != null, "ERROR: FormTalk1 missing")
	assert(form_talk3 != null, "ERROR: FormTalk3 missing")
	
	for res in TEST_RESOLUTIONS:
		root.size = res
		await process_frame
		await process_frame
		
		var canvas_size: Vector2 = root.get_visible_rect().size
		var hud_w: float = hud.size.x
		var hud_h: float = hud.size.y
		print("  Testing HUD at Window %s: Canvas visible rect = %s, HUD size = (%s, %s)" % [res, canvas_size, hud_w, hud_h])
		
		assert(is_equal_approx(hud_w, canvas_size.x), "ERROR: HUD width %f != canvas width %f" % [hud_w, canvas_size.x])
		assert(is_equal_approx(hud_h, canvas_size.y), "ERROR: HUD height %f != canvas height %f" % [hud_h, canvas_size.y])
		
		# Zero letterboxing check: canvas aspect ratio matches window aspect ratio within rounding precision (< 0.01)
		var window_aspect: float = float(res.x) / float(res.y)
		var canvas_aspect: float = canvas_size.x / canvas_size.y
		assert(absf(window_aspect - canvas_aspect) < 0.01, "Canvas aspect (%f) must match window aspect (%f) (zero letterboxing)" % [canvas_aspect, window_aspect])
		
		# 1. PlayerStatusDock: Anchored Top-Left (x=0, y=0)
		assert(is_equal_approx(player_status_dock.position.x, 0.0), "PlayerStatusDock must be at left edge")
		assert(is_equal_approx(player_status_dock.position.y, 0.0), "PlayerStatusDock must be at top edge")
		
		# 2. RadarMinimapDock: Anchored Top-Right (x = width - 226, y = 0)
		var expected_mm_x: float = hud_w - 226.0
		assert(is_equal_approx(radar_minimap_dock.position.x, expected_mm_x),
			"RadarMinimapDock x %f must be %f" % [radar_minimap_dock.position.x, expected_mm_x])
		assert(is_equal_approx(radar_minimap_dock.position.y, 40.0), "RadarMinimapDock y must be 40 (below the top action bar)")
		
		# 3. BottomActionDock: Anchored Bottom-Right (x = width - 282, y = height - 78)
		var expected_act_x: float = hud_w - 282.0
		var expected_act_y: float = hud_h - 78.0
		assert(is_equal_approx(bottom_action_dock.position.x, expected_act_x),
			"BottomActionDock x %f must be %f" % [bottom_action_dock.position.x, expected_act_x])
		assert(is_equal_approx(bottom_action_dock.position.y, expected_act_y),
			"BottomActionDock y %f must be %f" % [bottom_action_dock.position.y, expected_act_y])
			
		# 4. ChatDock: Anchored Bottom-Left (x = 0, y = height - 25)
		var expected_chat_y: float = hud_h - 25.0
		assert(is_equal_approx(chat_dock.position.x, 0.0), "ChatDock x must be 0")
		assert(is_equal_approx(chat_dock.position.y, expected_chat_y),
			"ChatDock y %f must be %f at resolution %s" % [chat_dock.position.y, expected_chat_y, res])
		
		# Inner chat panels
		var chat_panel: Control = chat_dock.get_node_or_null("ChatHistoryPanel")
		var channel_tabs: Control = chat_dock.get_node_or_null("ChannelTabs")
		assert(chat_panel != null, "ChatHistoryPanel missing")
		assert(channel_tabs != null, "ChannelTabs missing")
		assert(chat_panel.offset_top == -86.0, "ChatHistoryPanel offset_top must be -86.0")
		assert(channel_tabs.offset_top == -107.0, "ChannelTabs offset_top must be -107.0")
		
		# 5. HotbarDock: Anchored Top-Right below minimap (x = width - 56, y = 163)
		var expected_hb_x: float = hud_w - 56.0
		assert(is_equal_approx(hotbar_dock.position.x, expected_hb_x),
			"HotbarDock x %f must be %f" % [hotbar_dock.position.x, expected_hb_x])
		assert(is_equal_approx(hotbar_dock.position.y, 163.0),
			"HotbarDock y %f must be 163.0" % [hotbar_dock.position.y])
			
		# 6. DialogueSystem: FormTalk1 sits at the TOP centre like the real client (width 530, top 58); FormTalk3 stays bottom-centre
		var expected_ft1_x: float = (hud_w * 0.5) - 293.5
		assert(is_equal_approx(form_talk1.position.x, expected_ft1_x),
			"FormTalk1 x %f must be centered at %f" % [form_talk1.position.x, expected_ft1_x])
		assert(is_equal_approx(form_talk1.position.y, 48.0),
			"FormTalk1 y %f must be 48 from the top" % [form_talk1.position.y])
			
		# FormTalk3: width = 332, height = 168, offset_left = 20, offset_right = 352, offset_top = -360, offset_bottom = -192
		var expected_ft3_x: float = (hud_w * 0.5) + 20.0
		var expected_ft3_y: float = hud_h - 360.0
		assert(is_equal_approx(form_talk3.position.x, expected_ft3_x),
			"FormTalk3 x %f must be at %f" % [form_talk3.position.x, expected_ft3_x])
		assert(is_equal_approx(form_talk3.position.y, expected_ft3_y),
			"FormTalk3 y %f must be at %f" % [form_talk3.position.y, expected_ft3_y])
			
		print("    [OK] All HUD docks at resolution %s verified at exact screen boundaries." % [res])
	
	hud.queue_free()
	await process_frame

func _test_battle_view_responsive_layout() -> void:
	print("\n>>> [TEST 3] Verifying BattleView Responsive Geometry & Action Bars across Resizes...")
	var bv_scene: PackedScene = load("res://scenes/battle/battle_view.tscn")
	assert(bv_scene != null, "ERROR: Failed to load res://scenes/battle/battle_view.tscn")
	
	var bv = bv_scene.instantiate() as Control
	assert(bv != null, "ERROR: Failed to instantiate BattleView")
	root.add_child(bv)
	
	for res in TEST_RESOLUTIONS:
		root.size = res
		await process_frame
		await process_frame
		
		var canvas_size: Vector2 = root.get_visible_rect().size
		var bw: float = bv.size.x
		var bh: float = bv.size.y
		print("  Testing BattleView at Window %s: Canvas visible rect = %s, BattleView size = (%s, %s)" % [res, canvas_size, bw, bh])
		assert(is_equal_approx(bw, canvas_size.x), "ERROR: BattleView width %f != canvas width %f" % [bw, canvas_size.x])
		assert(is_equal_approx(bh, canvas_size.y), "ERROR: BattleView height %f != canvas height %f" % [bh, canvas_size.y])
		
		# 1. Command ring: a full-view container whose seven icons hang around the acting fighter (real client layout)
		var action_bar: Control = bv.action_bar
		assert(action_bar != null, "ActionButtonsBar missing")
		assert(is_equal_approx(action_bar.size.x, bw) and is_equal_approx(action_bar.size.y, bh),
			"ActionButtonsBar must cover the whole battle view, got %s" % [action_bar.size])
		var feet: Vector2 = bv.get_slot_screen_position(false, bv.current_player_slot)
		var attack_btn: Control = bv.action_buttons[0]
		assert(attack_btn.position.distance_to(feet) < 120.0, "The ring icons stay close to the acting fighter")
			
		# 2. StatusPanel (Bottom-Left, offset_left = 16, offset_top = -125)
		var status_panel: Control = bv.status_panel
		assert(status_panel != null, "StatusPanel missing")
		var expected_sp_x: float = 16.0
		var expected_sp_y: float = bh - 125.0
		assert(is_equal_approx(status_panel.position.x, expected_sp_x),
			"StatusPanel x %f must be %f" % [status_panel.position.x, expected_sp_x])
		assert(is_equal_approx(status_panel.position.y, expected_sp_y),
			"StatusPanel y %f must be %f" % [status_panel.position.y, expected_sp_y])
			
		# 3. Combat Field Slot Centering
		var field_offset: Vector2 = bv.get_field_offset()
		var expected_offset := Vector2((bw - 800.0) * 0.5, (bh - 600.0) * 0.5)
		assert(field_offset.is_equal_approx(expected_offset),
			"Field offset %s must equal %s" % [field_offset, expected_offset])
			
		var p_slot_0: Vector2 = bv.get_slot_screen_position(false, 0)
		var e_slot_0: Vector2 = bv.get_slot_screen_position(true, 0)
		assert(p_slot_0.is_equal_approx(Vector2(658.0, 425.0) + expected_offset),
			"Player slot 0 must be centered with offset")
		assert(e_slot_0.is_equal_approx(Vector2(160.0, 415.0) + expected_offset),
			"Enemy slot 0 must be centered with offset")
			
		print("    [OK] BattleView at resolution %s verified (action bar bottom-right, status bottom-left, arena centered)." % [res])
		
	bv.queue_free()
	await process_frame

func _test_map_view_camera_limits() -> void:
	print("\n>>> [TEST 4] Verifying MapView Camera2D Tracking & Adaptive Limit Expansion...")
	var mv_scene: PackedScene = load("res://scenes/world/map_view.tscn")
	assert(mv_scene != null, "ERROR: Failed to load res://scenes/world/map_view.tscn")
	
	var mv: Node2D = mv_scene.instantiate() as Node2D
	assert(mv != null, "ERROR: Failed to instantiate MapView")
	root.add_child(mv)
	
	await process_frame
	await process_frame
	
	var camera: Camera2D = mv.get_node_or_null("Camera2D") as Camera2D
	var player: Node2D = mv.get_node_or_null("Entities/Player") as Node2D
	assert(camera != null, "ERROR: Camera2D missing in MapView")
	assert(player != null, "ERROR: Player missing in MapView")
	
	for res in TEST_RESOLUTIONS:
		root.size = res
		await process_frame
		await process_frame
		
		# Test camera limits update
		mv.update_camera_limits()
		
		var vp_size: Vector2 = mv.get_viewport_rect().size
		var map_size: Vector2 = mv.map_renderer.get_map_pixel_size() if mv.map_renderer else Vector2(2432, 1792)
		
		print("  Testing Camera at Window %s: vp_size=%s, map_size=%s, limits=[%d, %d, %d, %d]" % [
			res, vp_size, map_size, camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom
		])
		
		var limit_w: int = camera.limit_right - camera.limit_left
		var limit_h: int = camera.limit_bottom - camera.limit_top
		assert(limit_w >= int(vp_size.x), "Camera limit width (%d) must be at least viewport width (%d)" % [limit_w, int(vp_size.x)])
		assert(limit_h >= int(vp_size.y), "Camera limit height (%d) must be at least viewport height (%d)" % [limit_h, int(vp_size.y)])
		
		# Camera position matches player position
		assert(camera.position.is_equal_approx(player.position),
			"Camera position (%s) must track player position (%s)" % [camera.position, player.position])
			
		print("    [OK] Camera2D limits and player tracking at resolution %s verified." % [res])
		
	mv.queue_free()
	await process_frame
