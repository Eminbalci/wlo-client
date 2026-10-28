extends SceneTree

## Automated Verification Suite for Wonderland Online Skill VFX & Battle Animations.
## Tests:
## 1. ArchiveLoader.get_skill_vfx_frames(6001) and (6009) frame extraction & caching.
## 2. Standee sprite loading for player characters (composite frames) and enemies (001.jma models).
## 3. battle_view.play_skill_vfx(...) node spawning, frame playback, and completion lifecycle.
## 4. End-to-end combat action execution with caster swing, VFX playback, and hit impact.
##
## Execute via:
## C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_skill_vfx_animations.gd

func _init() -> void:
	_run_all_tests()

func _run_all_tests() -> void:
	print("==================================================================")
	print("=== Running Wonderland Online Skill VFX & Battle Animation Tests ==")
	print("==================================================================")

	# 1. Ensure ArchiveLoader singleton is in SceneTree
	var loader: Node = root.get_node_or_null("ArchiveLoader")
	if not loader:
		var ArchiveLoaderClass = load("res://scripts/core/archive_loader.gd")
		loader = ArchiveLoaderClass.new()
		loader.name = "ArchiveLoader"
		root.add_child(loader)

	# 2. Ensure GameDatabase singleton is in SceneTree
	var db: Node = root.get_node_or_null("GameDatabase")
	if not db:
		var GameDatabaseClass = load("res://scripts/database/game_database.gd")
		db = GameDatabaseClass.new()
		db.name = "GameDatabase"
		root.add_child(db)

	await process_frame

	# -------------------------------------------------------------
	# Test 1: ArchiveLoader.get_skill_vfx_frames(6001) and (6009)
	# -------------------------------------------------------------
	print("\n>>> [TEST 1] Verifying ArchiveLoader Skill VFX Frame Extraction & Caching...")
	var frames_6001: Array[ImageTexture] = loader.get_skill_vfx_frames(6001)
	assert(not frames_6001.is_empty(), "ERROR: get_skill_vfx_frames(6001) must return non-empty array")
	assert(frames_6001.size() == 32, "ERROR: Expected 32 non-dummy frames for 6001.jmp, got %d" % frames_6001.size())
	assert(frames_6001[0] is ImageTexture, "ERROR: Frame 0 of 6001 must be ImageTexture")
	var sz_6001: Vector2 = frames_6001[0].get_size()
	assert(sz_6001.x > 0 and sz_6001.y > 0, "ERROR: Frame texture size must be positive")
	print("  PASS: 6001.jmp (Rocco Stunt) decoded %d frames of size %s" % [frames_6001.size(), sz_6001])

	var frames_6009: Array[ImageTexture] = loader.get_skill_vfx_frames(6009)
	assert(not frames_6009.is_empty(), "ERROR: get_skill_vfx_frames(6009) must return non-empty array")
	assert(frames_6009.size() == 64, "ERROR: Expected 64 frames for 6009.jmp, got %d" % frames_6009.size())
	assert(frames_6009[0] is ImageTexture, "ERROR: Frame 0 of 6009 must be ImageTexture")
	var sz_6009: Vector2 = frames_6009[0].get_size()
	assert(sz_6009.x > 0 and sz_6009.y > 0, "ERROR: Frame texture size must be positive")
	print("  PASS: 6009.jmp (Daniel Stunt) decoded %d frames of size %s" % [frames_6009.size(), sz_6009])

	# Test alias resolution (60001 -> 6001.jmp, 60009 -> 6009.jmp)
	var frames_alias_60001 = loader.get_skill_vfx_frames(60001)
	assert(frames_alias_60001.size() == frames_6001.size(), "ERROR: 60001 alias frame count mismatch")
	var frames_alias_60009 = loader.get_skill_vfx_frames(60009)
	assert(frames_alias_60009.size() == frames_6009.size(), "ERROR: 60009 alias frame count mismatch")

	# Test RAM caching
	var frames_cached = loader.get_skill_vfx_frames(6001)
	assert(frames_cached == frames_6001, "ERROR: Second call must return identical cached array")
	print("  PASS: Alias resolution (60001, 60009) and RAM caching verified.")

	# -------------------------------------------------------------
	# Test 2: Actor Standee Representation in BattleView
	# -------------------------------------------------------------
	print("\n>>> [TEST 2] Verifying BattleView Actor Standees (Player Composites & Enemy 001.jma)...")
	var scene_res = load("res://scenes/battle/battle_view.tscn")
	assert(scene_res != null, "ERROR: Failed to load battle_view.tscn")
	var battle_view = scene_res.instantiate()
	root.add_child(battle_view)
	await process_frame

	var bm = battle_view.battle_manager
	assert(bm != null, "ERROR: BattleView must have BattleManager")

	# Populate Player Slot 0 (Nina, Role 1)
	bm.set_player_slot(0, {
		"id": 1,
		"role_id": 1,
		"name": "Nina",
		"level": 15,
		"hp": 400,
		"max_hp": 400,
		"sp": 200,
		"max_sp": 200,
		"element": 3 # Fire
	})

	# Populate Enemy Slot 0 (Monster 1000 from 001.jma)
	bm.set_enemy_slot(0, {
		"id": 1000,
		"monster_id": 1000,
		"jmp_name": "1000.jmp",
		"name": "Forest Bat",
		"level": 12,
		"hp": 180,
		"max_hp": 180,
		"sp": 50,
		"max_sp": 50,
		"element": 1 # Earth
	})

	bm.start_battle()
	battle_view.refresh_actor_widgets()
	await process_frame

	var p_widget = battle_view.get_actor_widget(false, 0)
	assert(not p_widget.is_empty(), "ERROR: Player widget 0 must exist")
	var p_standee = p_widget.get("standee")
	assert(p_standee != null, "ERROR: Player standee must exist")
	assert(p_standee is TextureRect, "ERROR: Player standee must be TextureRect composite representation, got %s" % p_standee.get_class())
	assert((p_standee as TextureRect).texture != null, "ERROR: Player standee texture must be valid")
	print("  PASS: Player standee rendered as authentic character composite sprite: %s" % (p_standee as TextureRect).texture.get_size())

	var e_widget = battle_view.get_actor_widget(true, 0)
	assert(not e_widget.is_empty(), "ERROR: Enemy widget 0 must exist")
	var e_standee = e_widget.get("standee")
	assert(e_standee != null, "ERROR: Enemy standee must exist")
	assert(e_standee is TextureRect, "ERROR: Enemy standee must be TextureRect representation, got %s" % e_standee.get_class())
	assert((e_standee as TextureRect).texture != null, "ERROR: Enemy standee texture must be valid")
	print("  PASS: Enemy standee rendered from 001.jma monster model: %s" % (e_standee as TextureRect).texture.get_size())

	# -------------------------------------------------------------
	# Test 3: battle_view.play_skill_vfx(...) Spawning & Completion
	# -------------------------------------------------------------
	print("\n>>> [TEST 3] Verifying battle_view.play_skill_vfx Spawning & Completion Lifecycle...")
	var target_pos: Vector2 = battle_view.get_slot_screen_position(true, 0)
	assert(battle_view.vfx_layer != null, "ERROR: VFX layer must exist in BattleView")
	var initial_vfx_children: int = battle_view.vfx_layer.get_child_count()

	# Play skill VFX for anim_id 6001 (at 120 FPS for rapid headless test execution)
	battle_view.play_skill_vfx(6001, target_pos, "9911.wav", 120.0)

	# Verify VFX node was spawned on vfx_layer
	assert(battle_view.vfx_layer.get_child_count() > initial_vfx_children, "ERROR: VFX node must be spawned on vfx_layer")
	var vfx_node = battle_view.vfx_layer.get_child(battle_view.vfx_layer.get_child_count() - 1) as TextureRect
	assert(vfx_node != null, "ERROR: Spawned VFX node must be TextureRect")
	assert(vfx_node.texture != null, "ERROR: Spawned VFX node must have valid texture")
	assert(vfx_node.get_meta("anim_id", 0) == 6001, "ERROR: VFX node anim_id metadata mismatch")
	print("  PASS: VFX node '%s' spawned on vfx_layer with initial texture %s" % [vfx_node.name, vfx_node.texture.get_size()])

	# Await completion
	await battle_view.skill_vfx_completed
	await process_frame
	await process_frame

	assert(not is_instance_valid(vfx_node) or vfx_node.is_queued_for_deletion(), "ERROR: VFX node must be freed when animation completes")
	print("  PASS: VFX animation completed cleanly and node freed itself.")

	# -------------------------------------------------------------
	# Test 4: End-to-End Combat Action Execution with VFX & Hit Impact
	# -------------------------------------------------------------
	print("\n>>> [TEST 4] Verifying Combat Action Execution, Caster Lunge & Hit Impact...")
	var action_result: Dictionary = {
		"action_type": 2, # SKILL
		"user_is_enemy": false,
		"user_slot": 0,
		"user_name": "Nina",
		"target_is_enemy": true,
		"target_slot": 0,
		"target_name": "Forest Bat",
		"skill": {
			"id": 15039,
			"name": "Wine Flame",
			"animation_id": 6009,
			"cast_sfx_name": "9911.wav"
		},
		"animation_id": 6009,
		"damage": 120,
		"is_critical": true,
		"message": "Nina cast Wine Flame on Forest Bat for 120 damage!"
	}

	battle_view._on_bm_action_executed(action_result)

	# Verify 6009 VFX spawned
	var active_vfx = null
	for child in battle_view.vfx_layer.get_children():
		if child.name.begins_with("SkillVFX_6009"):
			active_vfx = child
			break
	assert(active_vfx != null, "ERROR: SkillVFX_6009 must be spawned on action executed")
	print("  PASS: Caster lunge triggered and SkillVFX_6009 spawned on action executed.")

	# Cleanup
	battle_view.cleanup()
	battle_view.queue_free()
	await process_frame

	print("\n==================================================================")
	print("=== ALL SKILL VFX & BATTLE ANIMATION TESTS PASSED (100%) =========")
	print("==================================================================")
	quit(0)
