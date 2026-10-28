extends SceneTree

## Automated Headless Test Suite for Team Window & Companion Management.
## Validates:
## 1. Team Window scene loading, geometry (371x539), background skin, and authentic 18x18 close button.
## 2. 4 Party Member Slots: Slot 0 Leader card, avatar bust, element badge, HP/SP bars, OrgLeader badge.
## 3. Slots 1..3 empty states, member additions, selection highlighting, dismissal, and leader promotion.
## 4. Companion card display (Roca, Kelang, S. Monkey), authentic toggle buttons, and summon/rest state machine.
## 5. MapView integration: _party_companions sync, NpcStateEvaluator suppression, overland follower spawning & tracking.

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const TeamWindowClass = preload("res://scripts/ui/hud/team_window.gd")
const MapViewClass = preload("res://scripts/map/map_view.gd")
const NpcEntityClass = preload("res://scripts/world/npc.gd")
const PlayerClass = preload("res://scripts/world/player.gd")

var _pass_count: int = 0
var _fail_count: int = 0

func _init() -> void:
	print("=================================================================")
	print("STARTING TEST SUITE: Team Window & Companion Management")
	print("=================================================================")
	
	run_all_tests()
	
	print("=================================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_pass_count, _fail_count])
	print("=================================================================")
	
	if _fail_count > 0:
		quit(1)
	else:
		quit(0)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		_fail_count += 1
		print("  [FAIL] %s" % test_name)

func assert_eq(val1: Variant, val2: Variant, test_name: String) -> void:
	if val1 == val2:
		_pass_count += 1
		print("  [PASS] %s: %s == %s" % [test_name, str(val1), str(val2)])
	else:
		_fail_count += 1
		print("  [FAIL] %s: Expected %s, got %s" % [test_name, str(val2), str(val1)])

func run_all_tests() -> void:
	test_team_window_scene_and_geometry()
	test_party_member_slots_and_leader()
	test_party_member_actions_dismiss_and_promote()
	test_companion_cards_and_summon_state_machine()
	test_mapview_companion_follower_integration()

func test_team_window_scene_and_geometry() -> void:
	print("\n--- 1. Testing Team Window Scene & Geometry ---")
	var scene = load("res://scenes/ui/hud/team_window.tscn")
	assert_true(scene != null, "team_window.tscn loads successfully")
	if not scene:
		return

	var win: TeamWindowClass = scene.instantiate() as TeamWindowClass
	assert_true(win != null, "Instantiated node is TeamWindow class")
	root.add_child(win)
	win.setup()

	assert_eq(win.size, Vector2(371, 539), "Team window dimensions are 371x539")
	assert_true(win.background != null, "Background node exists")
	assert_true(win.background.texture != null, "Background texture is assigned")
	assert_true("form_team_2" in win.background.texture.resource_path.to_lower(), "Background uses form_team_2 asset")

	# Close button
	assert_true(win.close_button != null, "Close button exists")
	assert_eq(win.close_button.position, Vector2(321, 20), "Close button sits on the baked x sphere (321, 20)")
	assert_eq(win.close_button.size, Vector2(20, 20), "Close button size is 20x20")
	assert_eq(win.close_button.text, "", "Close button text is empty (no synthetic 'X')")
	assert_eq(win.close_button.mouse_default_cursor_shape, Control.CURSOR_POINTING_HAND, "Close button cursor is pointing hand")

	# Action buttons
	assert_true(win.btn_leave_team != null, "Leave Team button exists")
	assert_true(win.btn_dismiss_team != null, "Dismiss Member button exists")
	assert_true(win.btn_assign_leader != null, "Promote Leader button exists")
	assert_eq(win.btn_leave_team.position, Vector2(26, 504), "Leave Team button at (26, 504)")
	assert_eq(win.btn_dismiss_team.position, Vector2(150, 504), "Dismiss Member button at (150, 504)")
	assert_eq(win.btn_assign_leader.position, Vector2(274, 504), "Promote Leader button at (274, 504)")

	win.queue_free()

func test_party_member_slots_and_leader() -> void:
	print("\n--- 2. Testing Party Member Slots & Slot 0 Leader Card ---")
	var win: TeamWindowClass = TeamWindowClass.new()
	root.add_child(win)
	win.setup()

	assert_eq(win.member_cards.size(), 4, "Window has exactly 4 party member card slots")
	assert_true(win.party_members.size() >= 1, "Party has default leader in Slot 0")

	var leader = win.party_members[0]
	assert_eq(leader.name, "Daniel", "Slot 0 leader default name is Daniel")
	assert_eq(leader.is_leader, true, "Slot 0 has is_leader = true")

	# Check UI widgets on slot 0
	assert_true(win.member_leader_badges[0].visible == false, "Pet rows never show a leader badge")
	assert_true(win.member_empty_labels[0].visible == false, "Slot 0 empty label is hidden")
	assert_eq(win.member_name_labels[0].text, "Roca", "Top row 0 lists the first pet")
	assert_eq(win.member_level_labels[0].text, "Lv. 12", "Top row 0 level label matches the pet")
	assert_eq(win.member_hp_labels[0].text, "320/320", "Top row 0 HP readout is 320/320")
	assert_eq(win.member_sp_labels[0].text, "150/150", "Top row 0 SP readout is 150/150")
	assert_true(not win.companion_name_labels[0].visible, "The teammate boxes are empty while the player is alone")

	# Check empty state on slots 1..3
	for i in range(3, 4):
		assert_true(win.member_empty_labels[i].visible, "Pet row %d shows empty placeholder" % i)
		assert_true(win.member_name_labels[i].visible == false, "Pet row %d name label is hidden" % i)
		assert_true(win.member_leader_badges[i].visible == false, "Pet row %d leader badge is hidden" % i)

	# Test set_player_data updates slot 0
	win.set_player_data({
		"name": "Betty",
		"role_id": 2,
		"level": 25,
		"element": "Water",
		"hp": 520,
		"max_hp": 520,
		"sp": 300,
		"max_sp": 300
	})
	assert_eq(win.party_members[0].name, "Betty", "Slot 0 name updated to Betty")
	assert_eq(win.party_members[0].level, 25, "Slot 0 level updated to 25")
	assert_eq(win.party_members[0].hp, 520, "Slot 0 HP updated to 520")

	win.queue_free()

func test_party_member_actions_dismiss_and_promote() -> void:
	print("\n--- 3. Testing Member Actions: Add, Select, Dismiss, Promote ---")
	var win: TeamWindowClass = TeamWindowClass.new()
	root.add_child(win)
	win.setup()

	# Initially no member selected, action buttons disabled
	assert_true(win.btn_dismiss_team.disabled, "Dismiss button disabled with no member selected")
	assert_true(win.btn_assign_leader.disabled, "Promote Leader button disabled with no member selected")

	# Add party members into Slot 1 and Slot 2
	var added1: bool = win.add_party_member({
		"name": "Nina",
		"role_id": 4,
		"level": 14,
		"element": "Wind",
		"hp": 280,
		"max_hp": 280,
		"sp": 160,
		"max_sp": 160
	})
	assert_true(added1, "Added Nina to Slot 1")
	assert_true(win.companion_name_labels[0].visible, "Teammate box 0 is now occupied")
	assert_true(win.companion_name_labels[0].text.begins_with("Nina"), "Teammate box 0 shows Nina")

	var added2: bool = win.add_party_member({
		"name": "Sam",
		"role_id": 5,
		"level": 12,
		"element": "Earth",
		"hp": 310,
		"max_hp": 310,
		"sp": 110,
		"max_sp": 110
	})
	assert_true(added2, "Added Sam to Slot 2")
	assert_eq(win.party_members.size(), 3, "Party size is now 3")

	# Select Slot 1 (Nina)
	var member_selected_signal_emitted: Array = [false]
	win.member_selected.connect(func(idx: int, _data: Dictionary) -> void:
		if idx == 1: member_selected_signal_emitted[0] = true
	)
	win.select_member_slot(1)
	assert_true(member_selected_signal_emitted[0], "member_selected signal emitted for Slot 1")
	assert_true(not win.btn_dismiss_team.disabled, "Dismiss button enabled after selecting Slot 1")
	assert_true(not win.btn_assign_leader.disabled, "Promote Leader button enabled after selecting Slot 1")

	# Promote Nina (Slot 1) to Leader
	var leader_promoted_signal_emitted: Array = [false]
	win.leader_promoted.connect(func(_idx: int, data: Dictionary) -> void:
		if data.get("name") == "Nina": leader_promoted_signal_emitted[0] = true
	)
	var promoted: bool = win.promote_leader(1)
	assert_true(promoted, "promote_leader returned true")
	assert_true(leader_promoted_signal_emitted[0], "leader_promoted signal emitted")
	assert_eq(win.party_members[0].name, "Nina", "Nina is now Slot 0 Leader")
	assert_true(win.party_members[0].is_leader, "Slot 0 has is_leader = true")
	assert_eq(win.party_members[1].name, "Daniel", "Daniel is now Slot 1 member")

	# Dismiss Daniel (Slot 1)
	win.select_member_slot(1)
	var dismissed_signal_emitted: Array = [false]
	win.member_dismissed.connect(func(_idx: int, data: Dictionary) -> void:
		if data.get("name") == "Daniel": dismissed_signal_emitted[0] = true
	)
	var dismissed: bool = win.dismiss_selected_member()
	assert_true(dismissed, "dismiss_selected_member returned true")
	assert_true(dismissed_signal_emitted[0], "member_dismissed signal emitted for Daniel")
	assert_eq(win.party_members.size(), 2, "Party size reduced to 2")
	assert_eq(win.party_members[0].name, "Nina", "Leader remains Nina")
	assert_eq(win.party_members[1].name, "Sam", "Slot 1 is now Sam")
	assert_true(not win.companion_name_labels[1].visible, "Teammate box 1 is now empty")

	# Leave Team
	var team_left_emitted: Array = [false]
	win.team_left.connect(func() -> void: team_left_emitted[0] = true)
	win.leave_team()
	assert_true(team_left_emitted[0], "team_left signal emitted")
	assert_eq(win.party_members.size(), 1, "Party members cleared down to single player")

	win.queue_free()

func test_companion_cards_and_summon_state_machine() -> void:
	print("\n--- 4. Testing Companion Cards & Summon/Rest State Machine ---")
	var win: TeamWindowClass = TeamWindowClass.new()
	root.add_child(win)
	win.setup()

	assert_eq(win.companion_cards.size(), 3, "Companion section has 3 cards (Active + 2 Reserves)")
	assert_eq(win.active_companion.name, "Roca", "Default active companion is Roca")
	assert_eq(win.active_companion.id, 8090, "Roca id is 8090")
	assert_eq(win.active_companion.is_summoned, false, "Roca is initially resting")

	assert_true(not win.active_companion.is_summoned, "The active pet starts resting")
	assert_true(win.is_companion_summoned() == false, "is_companion_summoned returns false")

	# Toggle Summon Roca
	var summon_toggled_emitted: Array = [false]
	var summon_signal_emitted: Array = [false]
	win.companion_toggled.connect(func(cid: int, sum: bool) -> void:
		if cid == 8090 and sum == true: summon_toggled_emitted[0] = true
	)
	win.companion_summoned.connect(func(cid: int, cname: String) -> void:
		if cid == 8090 and cname == "Roca": summon_signal_emitted[0] = true
	)

	var is_sum: bool = win.toggle_companion_summon()
	assert_true(is_sum, "toggle_companion_summon returned true (summoned)")
	assert_true(summon_toggled_emitted[0], "companion_toggled signal emitted with summoned=true")
	assert_true(summon_signal_emitted[0], "companion_summoned signal emitted with Roca")
	assert_true(win.active_companion.is_summoned, "The active pet is marked summoned")
	assert_true(win.is_companion_summoned(), "is_companion_summoned returns true")

	# Toggle Rest Roca
	var recalled_signal_emitted: Array = [false]
	win.companion_recalled.connect(func(cid: int) -> void:
		if cid == 8090: recalled_signal_emitted[0] = true
	)
	var is_rest: bool = win.toggle_companion_summon()
	assert_true(is_rest == false, "toggle_companion_summon returned false (resting)")
	assert_true(recalled_signal_emitted[0], "companion_recalled signal emitted for Roca")
	assert_true(not win.active_companion.is_summoned, "The active pet is resting again")
	assert_eq(win.row_battle_buttons[0].text, "Battle", "Row 0 button displays 'Battle' when resting")
	
	# Press Battle button on Row 0
	win.row_battle_buttons[0].pressed.emit()
	assert_true(win.active_companion.is_summoned, "The row's Battle button summons the pet")
	assert_eq(win.row_battle_buttons[0].text, "Rest", "Row 0 button switches to 'Rest' when summoned")

	# Dismiss button on Row 0 rests the pet
	win.row_dismiss_buttons[0].pressed.emit()
	assert_true(not win.active_companion.is_summoned, "The row's Dismiss button rests the pet")
	assert_eq(win.row_battle_buttons[0].text, "Battle", "Row 0 button switches back to 'Battle'")

	# Single Battle Mode Enforcement:
	# 1. Summon Roca first
	win.row_battle_buttons[0].pressed.emit()
	assert_true(win.active_companion.is_summoned, "Roca is summoned")
	# 2. Click Battle on Kelang (Row 1)
	win.row_battle_buttons[1].pressed.emit()
	assert_eq(win.active_companion.name, "Kelang", "Active companion switched to Kelang")
	assert_true(win.active_companion.is_summoned, "Kelang is now summoned in Battle mode")
	assert_true(not win.reserve_companions[0].is_summoned, "Previous pet Roca is automatically rested")
	
	# Verify strictly ONE pet in battle mode across all party pets
	var total_battle_mode: int = 1 if bool(win.active_companion.get("is_summoned", false)) else 0
	for rc in win.reserve_companions:
		if bool(rc.get("is_summoned", false)):
			total_battle_mode += 1
	assert_eq(total_battle_mode, 1, "Strictly ONE pet is in battle mode at any time")
	assert_eq(win.row_battle_buttons[0].text, "Rest", "Row 0 (Kelang) button displays 'Rest'")
	assert_eq(win.row_battle_buttons[1].text, "Battle", "Row 1 (Roca) button displays 'Battle'")

	# 3. Toggling 'Rest' on active pet sets 0 pets in battle mode
	win.row_battle_buttons[0].pressed.emit()
	assert_true(not win.active_companion.is_summoned, "Active pet Kelang is now resting")
	total_battle_mode = 1 if bool(win.active_companion.get("is_summoned", false)) else 0
	for rc in win.reserve_companions:
		if bool(rc.get("is_summoned", false)):
			total_battle_mode += 1
	assert_eq(total_battle_mode, 0, "0 pets in battle mode when active pet is recalled")

	# 4. Verify S. Monkey model JMP is 1103.jmp (not 1118 boulder)
	var monkey_found: bool = false
	for comp in [win.active_companion] + win.reserve_companions:
		if comp.get("name") == "S. Monkey":
			monkey_found = true
			assert_eq(comp.get("model_jmp"), "1103.jmp", "S. Monkey model JMP is 1103.jmp, not boulder 1118.jmp")
	assert_true(monkey_found, "S. Monkey found in companion list")

	# 5. Verify Authentic Avatars: Never human player roles (Betty, Daniel, Moritaka)
	var roca_tex: Texture2D = win._resolve_companion_avatar(8090, "Roca")
	assert_true(roca_tex != null, "Roca avatar resolves successfully")
	assert_true(not ("avatar_role_2" in roca_tex.resource_path), "Roca does not use Betty (role 2) human portrait")
	assert_true("roca_avatar" in roca_tex.resource_path, "Roca uses authentic roca_avatar asset")

	var kelang_tex: Texture2D = win._resolve_companion_avatar(14062, "Kelang")
	assert_true(kelang_tex != null, "Kelang avatar resolves successfully")
	assert_true(not ("avatar_role_6" in kelang_tex.resource_path), "Kelang does not use Daniel (role 6) human portrait")
	assert_true("kelang_avatar" in kelang_tex.resource_path, "Kelang uses authentic kelang_avatar asset")

	var monkey_tex: Texture2D = win._resolve_companion_avatar(17162, "S. Monkey")
	assert_true(monkey_tex != null, "S. Monkey avatar resolves successfully")
	assert_true(not ("avatar_role_13" in monkey_tex.resource_path), "S. Monkey does not use Moritaka (role 13) human portrait")
	assert_true("s_monkey_avatar" in monkey_tex.resource_path, "S. Monkey uses authentic s_monkey_avatar asset")

	win.queue_free()

func test_mapview_companion_follower_integration() -> void:
	print("\n--- 5. Testing MapView & Companion Follower Integration ---")
	var map_view: MapViewClass = MapViewClass.new()
	root.add_child(map_view)

	var entities_node = Node2D.new()
	entities_node.name = "Entities"
	map_view.add_child(entities_node)
	map_view.entities = entities_node

	var player = PlayerClass.new()
	player.name = "Player"
	player.world_position = Vector2(500.0, 500.0)
	player.current_heading = IsometricMath.Heading.SOUTH
	entities_node.add_child(player)
	map_view.player = player

	# Initially no companions in party
	assert_eq(map_view._party_companions.size(), 0, "MapView._party_companions starts empty")
	assert_true(map_view._companion_follower == null, "No companion follower initially")

	# Test 1: Spawn companion follower (Roca)
	var follower = map_view.spawn_companion_follower({
		"npc_id": 8090,
		"id": 8090,
		"name": "Roca",
		"model_jmp": "1221.jmp"
	})
	assert_true(follower != null, "Companion follower spawned")
	assert_eq(map_view._companion_follower, follower, "_companion_follower references spawned follower")
	assert_eq(follower.npc_name, "Roca", "Follower name is Roca")
	assert_eq(follower.npc_id, 8090, "Follower ID is 8090")
	assert_true(map_view._party_companions.has(8090), "MapView._party_companions contains 8090")

	# Test 2: NpcStateEvaluator hides map NPC if companion is in active party
	var eve_mock = null
	var should_show: bool = NpcStateEvaluator.should_npc_be_visible(
		12000, 10, {}, map_view._party_companions, [], false, eve_mock
	)
	# Guidepost 10 is permanent, so it shows
	assert_true(should_show, "Scenery guidepost remains visible")

	# Test 3: Follower position behind player
	var expected_offset: Vector2 = -IsometricMath.get_heading_vector(IsometricMath.Heading.SOUTH).normalized() * 48.0
	var expected_pos: Vector2 = player.world_position + expected_offset
	assert_true(follower.world_position.distance_to(expected_pos) < 5.0, "Follower spawned behind player")
	assert_eq(follower.is_moving, false, "Follower starts standing with is_moving = false")

	# Test 4: Follower updates position & sets is_moving = true as player moves
	player.world_position = Vector2(800.0, 600.0)
	player.current_heading = IsometricMath.Heading.EAST
	map_view.update_companion_follower_position(player.world_position, 0.016)
	assert_true(follower.world_position.distance_to(Vector2(500.0, 500.0)) > 1.0, "Follower adjusted position towards player")
	assert_eq(follower.is_moving, true, "Follower sets is_moving = true to play walk animation while following")
	
	# Test 4b: No teleporting during normal overland movement (e.g. 500px away)
	follower.world_position = Vector2(100.0, 100.0)
	player.world_position = Vector2(600.0, 100.0)
	map_view.update_companion_follower_position(player.world_position, 0.016)
	assert_true(follower.world_position.x < 150.0, "Follower walks smoothly instead of teleporting across 500px")
	assert_eq(follower.is_moving, true, "Follower continues walking towards breadcrumb")

	# Test 4c: Follower halts walking (is_moving = false) when within 48px of stopped player
	player.is_moving = false
	follower.world_position = player.world_position + Vector2(-30.0, 10.0) # dist = ~31.6px <= 48px
	map_view.update_companion_follower_position(player.world_position, 0.016)
	assert_eq(follower.is_moving, false, "Follower stops walking (is_moving = false) when close to stopped player")
	assert_eq(follower.heading, IsometricMath.get_heading(follower.world_position, player.world_position), "Follower heading faces player when idle")

	# Test 4d: find_npc_near_world_pos ignores follower to prevent movement click interception
	var clicked_candidate = map_view.find_npc_near_world_pos(follower.world_position)
	assert_true(clicked_candidate == null, "find_npc_near_world_pos excludes _companion_follower from dialogue interception")

	# Test 5: Despawn companion follower
	map_view.despawn_companion_follower()
	assert_true(map_view._companion_follower == null, "Companion follower despawned and nulled")
	assert_true(not map_view._party_companions.has(8090), "Roca removed from _party_companions")

	# Test 6: S. Monkey follower spawns with model 1103.jmp (never boulder 1118.jmp)
	var monkey_follower = map_view.spawn_companion_follower({
		"npc_id": 17162,
		"id": 17162,
		"name": "S. Monkey"
	})
	assert_true(monkey_follower != null, "S. Monkey follower spawned")
	assert_eq(monkey_follower.model_jmp, "1103.jmp", "S. Monkey overland model is 1103.jmp (curious monkey, not boulder)")
	map_view.despawn_companion_follower()

	map_view.queue_free()
