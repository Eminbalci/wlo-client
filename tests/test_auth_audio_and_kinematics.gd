extends SceneTree

## Unit test suite for Wonderland Online auth audio, sprite walk-cycle kinematics,
## and preview color modulation parity.
##
## Direction convention: IsometricMath.Heading (authentic JMP sprite rows):
## 0 N, 1 NW, 2 W, 3 SW, 4 S, 5 SE, 6 E, 7 NE. Default preview facing is SOUTH_WEST.

const AuthAudio = preload("res://scripts/ui/auth/auth_audio.gd")
const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")
const TEST_ACCOUNT: String = "test_kinematics_account"

var _failures: int = 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  PASS: %s" % msg)
	else:
		_failures += 1
		push_error("[FAIL] %s" % msg)

func _initialize() -> void:
	call_deferred("_run_all")

func _run_all() -> void:
	print("==================================================================")
	print("--- Running Auth Audio & Asset Kinematics Automated Test Suite ---")
	print("==================================================================")

	_test_audio()
	_test_character_select_kinematics()
	_test_character_create_kinematics()

	CharacterManager.clear_all_characters(TEST_ACCOUNT)
	print("\n==================================================================")
	if _failures == 0:
		print("ALL AUTH AUDIO & ASSET KINEMATICS TESTS PASSED")
	else:
		print("AUTH AUDIO & ASSET KINEMATICS TESTS FAILED: %d" % _failures)
	print("==================================================================")
	quit(0 if _failures == 0 else 1)

func _test_audio() -> void:
	print("\n[PART 1] Auth audio system")
	_check(ResourceLoader.exists(AuthAudio.SFX_CLICK_PATH), "Click SFX present: %s" % AuthAudio.SFX_CLICK_PATH)
	_check(ResourceLoader.exists(AuthAudio.SFX_ERROR_PATH), "Error SFX present: %s" % AuthAudio.SFX_ERROR_PATH)
	_check(ResourceLoader.load(AuthAudio.SFX_CLICK_PATH) is AudioStream, "Click SFX loads as AudioStream")
	_check(ResourceLoader.load(AuthAudio.SFX_ERROR_PATH) is AudioStream, "Error SFX loads as AudioStream")

	var audio_helper: Node = AuthAudio.new()
	audio_helper.name = "AuthAudioTestHelper"
	root.add_child(audio_helper)
	var pool: Array = audio_helper.get("_player_pool")
	_check(pool.size() == AuthAudio.POOL_SIZE, "Player pool holds %d players" % AuthAudio.POOL_SIZE)

	for i in range(AuthAudio.POOL_SIZE + 4):
		audio_helper.call("play_ui_click")
	audio_helper.call("play_ui_error")
	_check((audio_helper.get("_player_pool") as Array).size() >= AuthAudio.POOL_SIZE, "Round-robin playback beyond pool size is stable")

	AuthAudio.play_click()
	AuthAudio.play_error()
	_check(true, "Static play_click()/play_error() callable")
	audio_helper.queue_free()

func _test_character_select_kinematics() -> void:
	print("\n[PART 2] CharacterSelect walk cycle and heading")
	var cs: CharacterSelect = (load("res://scenes/ui/auth/character_select.tscn") as PackedScene).instantiate()
	root.add_child(cs)

	_check(cs._slot_rotations.get(0, -1) == IsometricMath.Heading.SOUTH_WEST, "Default slot heading is SOUTH_WEST")

	for _step in range(8):
		var cur: int = cs._slot_rotations.get(0, 0)
		cs._rotate_slot_character(0, 1)
		var nxt: int = cs._slot_rotations.get(0, 0)
		if nxt != (cur + 1) % 8:
			_check(false, "Rotation step %d -> %d" % [cur, nxt])
			break
	_check(cs._slot_rotations.get(0, -1) == IsometricMath.Heading.SOUTH_WEST, "Full 8-way rotation cycle returns to default")

	var rot: int = cs._slot_rotations[0]
	cs._anim_timer = 0.0
	var f0: int = (rot % 8) * 4 + (int(cs._anim_timer * 8.0) % 4)
	cs._anim_timer = 0.125
	var f1: int = (rot % 8) * 4 + (int(cs._anim_timer * 8.0) % 4)
	_check(f1 == f0 + 1, "Walk frame advances by 1 every 1/8 s (f0=%d, f1=%d)" % [f0, f1])
	cs.queue_free()

func _test_character_create_kinematics() -> void:
	print("\n[PART 3] CharacterCreate walk cycle, tint, and validation")
	var cc: CharacterCreate = (load("res://scenes/ui/auth/character_create.tscn") as PackedScene).instantiate()
	cc.account_name = TEST_ACCOUNT
	root.add_child(cc)

	_check(cc._current_direction == CharacterCreate.DEFAULT_HEADING, "Preview direction defaults to DEFAULT_HEADING")
	_check(CharacterCreate.DEFAULT_HEADING == IsometricMath.Heading.SOUTH_WEST, "DEFAULT_HEADING equals SOUTH_WEST")
	_check(is_equal_approx(CharacterCreate.WALK_FPS, 8.0), "WALK_FPS is 8.0")

	cc._turn_character(1)
	_check(cc._current_direction == (CharacterCreate.DEFAULT_HEADING + 1) % 8, "Turn +1 advances heading")
	cc._turn_character(-1)
	_check(cc._current_direction == CharacterCreate.DEFAULT_HEADING, "Turn -1 restores heading")

	cc._walk_anim_timer = 0.25
	var sub: int = int(cc._walk_anim_timer * CharacterCreate.WALK_FPS) % 4
	_check(sub == 2, "Walk sub-frame at 0.25 s is 2")

	var tint := Color(0.85, 0.45, 0.15, 1.0)
	cc.selected_hair_color = tint
	cc._update_walking_sprite_frame()
	if cc.walking_sprite and cc.walking_sprite.is_visible_in_tree():
		_check(cc.walking_sprite.modulate.is_equal_approx(tint), "Walking sprite modulate follows selected hair color")

	cc.first_name_input.text = ""
	cc.family_name_input.text = ""
	cc._on_confirm_create()
	_check(cc.step4_error_label.text.contains("Please enter"), "Empty name rejected")

	cc.first_name_input.text = "Abcdefgh"
	cc.family_name_input.text = "Ijklmnop"
	cc._on_confirm_create()
	_check(cc.step4_error_label.text.contains("cannot exceed 14"), "Name over 14 characters rejected")

	var created: Array[Dictionary] = []
	cc.character_created.connect(func(data: Dictionary) -> void: created.append(data))
	cc.first_name_input.text = "HeroDaniel"
	cc.family_name_input.text = ""
	cc._on_confirm_create()
	_check(created.size() == 1 and str(created[0].get("name", "")) == "HeroDaniel", "Valid name creates character")
	cc.queue_free()
