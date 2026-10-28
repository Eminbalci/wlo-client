extends SceneTree

## Automated Test Suite: Companion Ride Mode (Pet Mounting System)
## Verifies AdjustRidePetPos parsing, rider kinematics offsets, Ride button UI states,
## strict mutual exclusion between Ride and Battle modes, and PlayerEntity mount attachment.

const TeamWindowClass = preload("res://scripts/ui/hud/team_window.gd")
const PlayerClass = preload("res://scripts/world/player.gd")
const MapViewClass = preload("res://scripts/map/map_view.gd")
const RideDataClass = preload("res://scripts/world/ride_data.gd")

var _passed: int = 0
var _failed: int = 0

func assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		print("  [FAIL] %s" % msg)

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		_passed += 1
		print("  [PASS] %s: %s == %s" % [msg, str(a), str(b)])
	else:
		_failed += 1
		print("  [FAIL] %s: expected %s, got %s" % [msg, str(b), str(a)])

func _init() -> void:
	print("\n=================================================================")
	print("STARTING TEST SUITE: Companion Ride Mode & Mount Kinematics")
	print("=================================================================\n")

	test_ride_data_parser()
	test_team_window_ride_ui_and_state_machine()
	test_player_entity_mount_kinematics()
	test_map_view_ride_integration()

	print("\n=================================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [_passed, _failed])
	print("=================================================================\n")

	if _failed > 0:
		quit(1)
	else:
		quit(0)

func test_ride_data_parser() -> void:
	print("--- 1. Testing AdjustRidePetPos.txt Parser & Offsets ---")
	RideDataClass.ensure_initialized()
	assert_true(RideDataClass.has_ride_profile(1867), "Profile 1867 exists in AdjustRidePetPos")
	assert_true(RideDataClass.has_ride_profile(1767), "Profile 1767 exists in AdjustRidePetPos")
	assert_true(RideDataClass.has_ride_profile(1879), "Profile 1879 exists in AdjustRidePetPos")

	var spec_1867: Dictionary = RideDataClass.get_ride_spec(1867)
	assert_eq(spec_1867.get("pose"), "sit", "1867 pose is 'sit'")

	# Heading 0 (North), Role 1 (Daniel, Sex 1)
	var off_idle_0: Vector2 = RideDataClass.get_rider_offset(1867, 1, 0, false)
	assert_eq(off_idle_0, Vector2(0.0, -78.0), "1867 Role 1 Heading 0 Idle Offset is (0, -78)")

	# Heading 1 (North-East), Role 1 (Daniel, Sex 1) Move
	var off_move_1: Vector2 = RideDataClass.get_rider_offset(1867, 1, 1, true)
	assert_eq(off_move_1, Vector2(12.0, -75.0), "1867 Role 1 Heading 1 Move Offset is (12, -75)")

	# Role sex resolution
	assert_eq(RideDataClass.get_sex_for_role(1), 1, "Role 1 maps to Sex 1 (Adult Male)")
	assert_eq(RideDataClass.get_sex_for_role(2), 2, "Role 2 maps to Sex 2 (Adult Female)")
	assert_eq(RideDataClass.get_sex_for_role(13), 3, "Role 13 maps to Sex 3 (Boy)")
	assert_eq(RideDataClass.get_sex_for_role(6), 4, "Role 6 maps to Sex 4 (Girl)")

	# Fallback for unlisted pet (e.g. S. Monkey 1103)
	var fb_idle: Vector2 = RideDataClass.get_rider_offset(1103, 6, 2, false)
	assert_eq(fb_idle.y, -30.0, "Fallback idle Y offset is -30px")
	var fb_move: Vector2 = RideDataClass.get_rider_offset(1103, 6, 2, true)
	assert_eq(fb_move.y, -32.0, "Fallback move Y offset is -32px")

	# Speed bonus calculation
	var base_spd: float = 120.0
	assert_eq(RideDataClass.get_mount_speed(base_spd), 162.0, "Mount speed scales 1.35x (162.0 px/s)")

func test_team_window_ride_ui_and_state_machine() -> void:
	print("\n--- 2. Testing Team Window Ride Buttons & State Machine ---")
	var win = TeamWindowClass.new()
	root.add_child(win)
	win.setup()

	assert_eq(win.row_ride_buttons.size(), 4, "Window contains 4 pet row ride buttons")
	assert_eq(win.row_ride_buttons[0].text, "Ride", "Row 0 displays 'Ride' initially")

	var mounted_signal_fired: Array = []
	var dismounted_signal_fired: Array = []
	var ride_toggled_fired: Array = []

	win.companion_mounted.connect(func(comp: Dictionary) -> void: mounted_signal_fired.append(comp))
	win.companion_dismounted.connect(func(comp: Dictionary) -> void: dismounted_signal_fired.append(comp))
	win.companion_ride_toggled.connect(func(riding: bool) -> void: ride_toggled_fired.append(riding))

	# Mount active pet (Roca)
	var res_mount: bool = win.mount_companion()
	assert_true(res_mount, "mount_companion() succeeded")
	assert_true(win.is_companion_ridden(), "is_companion_ridden() returns true")
	assert_eq(mounted_signal_fired.size(), 1, "companion_mounted signal emitted")
	assert_eq(ride_toggled_fired.size(), 1, "companion_ride_toggled signal emitted with true")
	assert_eq(win.row_ride_buttons[0].text, "Dismount", "Row 0 displays 'Dismount' when ridden")
	assert_eq(win.row_battle_buttons[0].text, "Battle", "Row 0 Battle button displays 'Battle' while riding")

	# Mutual Exclusion: Toggle Battle on pet 1 (Kelang) while riding pet 0 (Roca)
	win.row_battle_buttons[1].pressed.emit()
	assert_true(not win.is_companion_ridden(), "Riding pet was automatically dismounted when entering battle")
	assert_true(win.is_companion_summoned(), "New pet (Kelang) is now in battle")
	assert_eq(win.row_battle_buttons[0].text, "Rest", "Row 0 (Kelang promoted to active) shows 'Rest'")
	assert_eq(win.row_ride_buttons[0].text, "Ride", "Row 0 Ride button displays 'Ride'")

	# Mutual Exclusion: Toggle Ride on pet 1 (Roca) while pet 0 (Kelang) is in Battle
	win.row_ride_buttons[1].pressed.emit()
	assert_true(win.is_companion_ridden(), "Roca is now mounted in Ride mode")
	assert_true(not win.is_companion_summoned(), "Battle mode pet was automatically recalled")
	assert_eq(win.row_ride_buttons[0].text, "Dismount", "Active pet button displays 'Dismount'")

	# Dismount
	win.row_ride_buttons[0].pressed.emit()
	assert_true(not win.is_companion_ridden(), "Companion is dismounted")
	assert_eq(win.row_ride_buttons[0].text, "Ride", "Button reverted to 'Ride'")
	assert_eq(dismounted_signal_fired.size() > 0, true, "companion_dismounted signal emitted")

	win.queue_free()

func test_player_entity_mount_kinematics() -> void:
	print("\n--- 3. Testing PlayerEntity Mount Attachment & Speed ---")
	var player = PlayerClass.new()
	root.add_child(player)

	assert_eq(player.is_riding(), false, "Player starts unmounted")
	assert_eq(player.move_speed, 120.0, "Base player speed is 120.0 px/s")

	var pet_data: Dictionary = {
		"id": 1867,
		"npc_id": 1867,
		"name": "Beast Mount",
		"model_jmp": "1867.jmp",
		"model_jma": "001.jma",
		"sprite_id": 1867
	}

	player.mount_pet(pet_data)
	player.role_id = 1 # Role 1 (Daniel, Sex 1)
	assert_true(player.is_riding(), "Player is now in riding mode")
	assert_eq(player.move_speed, 162.0, "Player move speed increased to 162.0 px/s (1.35x)")
	assert_true(player._mount_sprite != null, "MountSprite child created under Player")
	assert_true(player._mount_sprite.visible, "MountSprite is visible")
	assert_eq(player._mount_sprite.z_index, -1, "MountSprite renders beneath player rider")

	# Test sitting/rider offset updates during idle
	player.current_heading = 0
	player.is_moving = false
	player._update_animation(0.1)
	assert_eq(player.sprite.position, Vector2(0.0, -78.0), "Player rider sprite positioned at (0, -78) on 1867 idle")

	# Test sitting/rider offset updates during movement
	player.current_heading = 1
	player.is_moving = true
	player._update_animation(0.1)
	assert_eq(player.sprite.position, Vector2(12.0, -75.0), "Player rider sprite positioned at (12, -75) on 1867 move")

	# Dismount
	player.dismount_pet()
	assert_eq(player.is_riding(), false, "Player is dismounted")
	assert_eq(player.move_speed, 120.0, "Player speed restored to 120.0 px/s")
	assert_true(not player._mount_sprite.visible, "MountSprite hidden upon dismount")
	assert_eq(player.sprite.position, Vector2.ZERO, "Player sprite position reset to Vector2.ZERO")

	player.queue_free()

func test_map_view_ride_integration() -> void:
	print("\n--- 4. Testing MapView Ride Signals & Follower Suppression ---")
	var map_view = MapViewClass.new()
	root.add_child(map_view)

	var p_scene = load("res://scenes/world/player.tscn")
	if p_scene:
		map_view.player = p_scene.instantiate()
		map_view.add_child(map_view.player)

	var pet_sample: Dictionary = {
		"id": 8090,
		"npc_id": 8090,
		"name": "Roca",
		"model_jmp": "1221.jmp"
	}

	# Spawn overland follower
	var fol = map_view.spawn_companion_follower(pet_sample)
	assert_true(map_view._companion_follower != null, "Overland companion follower spawned on foot")

	# Mounting pet in Ride mode must despawn overland follower (player is now riding it)
	map_view._on_team_companion_mounted(pet_sample)
	assert_true(map_view._companion_follower == null, "Overland follower despawned because player is riding the pet")
	if map_view.player:
		assert_true(map_view.player.is_riding(), "Player entity entered pet riding mode")

	# Dismounting pet
	map_view._on_team_companion_dismounted(pet_sample)
	if map_view.player:
		assert_true(not map_view.player.is_riding(), "Player entity dismounted")

	map_view.queue_free()
