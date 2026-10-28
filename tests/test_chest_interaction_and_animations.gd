extends SceneTree

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const MapViewScene = preload("res://scenes/world/map_view.tscn")
const HudScene = preload("res://scenes/ui/hud.tscn")
const NpcScene = preload("res://scenes/world/npc.tscn")
const PlayerScene = preload("res://scenes/world/player.tscn")

func _init() -> void:
	print("\n=================================================================")
	print("--- Running Chest Interaction, Paperdoll & Animations Test Suite ---")
	print("=================================================================\n")
	
	_test_bottom_action_dock_clean_background()
	_test_status_dock_avatar_calibrated_position()
	_test_paperdoll_stance_and_breathing_cycle()
	_test_player_animation_transitions()
	_test_npc_breathing_cadence()
	_test_chest_container_item_granting_and_dialogue_bypass()
	
	print("\n=================================================================")
	print("--- ALL CHEST INTERACTION & ANIMATION TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)

func _test_bottom_action_dock_clean_background() -> void:
	print(">>> [TEST 1] Verifying Bottom Action Dock has lowered blue bar cradling buttons from underneath...")
	var hud = HudScene.instantiate()
	root.add_child(hud)
	
	var dock = hud.get_node_or_null("BottomActionDock")
	assert(dock != null, "BottomActionDock must exist")
	
	var bg = dock.get_node_or_null("ActionBackground") as TextureRect
	assert(bg != null, "ActionBackground must exist")
	assert(bg.visible == true, "ActionBackground must be visible")
	assert(bg.position == Vector2(7, 34), "ActionBackground must be lowered to cradle buttons at Vector2(7, 34), was %s" % str(bg.position))
	
	var btn_quest = dock.get_node_or_null("ButtonContainer/BtnQuest") as TextureButton
	assert(btn_quest != null, "BtnQuest must exist")
	assert(btn_quest.tooltip_text.contains("Compound"), "BtnQuest tooltip must be Compound, was %s" % btn_quest.tooltip_text)
	
	print("  [PASS] Bottom Action Dock lowered blue cradle presentation verified.")
	hud.queue_free()

func _test_status_dock_avatar_calibrated_position() -> void:
	print(">>> [TEST 2] Verifying Status Dock avatar portrait position cradled in filigree bezel...")
	var hud = HudScene.instantiate()
	root.add_child(hud)
	
	var dock = hud.get_node_or_null("PlayerStatusDock")
	assert(dock != null, "PlayerStatusDock must exist")
	
	var avatar_rect = dock.get_node_or_null("AvatarRect") as TextureRect
	assert(avatar_rect != null, "AvatarRect must exist")
	assert(avatar_rect.position == Vector2(30, -4), "AvatarRect must be calibrated at Vector2(30, -4), was %s" % str(avatar_rect.position))
	assert(avatar_rect.size == Vector2(72, 72), "AvatarRect must be sized 72x72")
	
	print("  [PASS] Status Dock avatar position Vector2(30, -4) verified.")
	hud.queue_free()

func _test_paperdoll_stance_and_breathing_cycle() -> void:
	print(">>> [TEST 3] Verifying Paperdoll Character 3/4 isometric stance (SOUTH_WEST) & idle breathing animation...")
	var hud = HudScene.instantiate()
	root.add_child(hud)
	if not hud.character_status_ctrl:
		hud._ready()
	
	var char_ctrl = hud.character_status_ctrl
	assert(char_ctrl != null, "character_status_ctrl must exist")
	assert(char_ctrl.get_paper_doll_heading() == IsometricMath.Heading.SOUTH_WEST, "Paperdoll heading must be SOUTH_WEST (Heading 3)")
	assert(char_ctrl._paper_doll_base_frame == 44, "Paperdoll base frame must be 44 (32 + 3 * 4)")
	
	# Mock 64 frames to simulate composite player frames
	var mock_frames: Array[ImageTexture] = []
	for i in range(64):
		var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		mock_frames.append(ImageTexture.create_from_image(img))
	
	char_ctrl._paper_doll_frames = mock_frames
	char_ctrl.char_window.visible = true
	
	# Initial frame at timer = 0.0s
	char_ctrl._paper_doll_timer = 0.0
	assert(char_ctrl.get_paper_doll_frame_index() == 44, "Initial breathing frame must be 44")
	
	# Advance 0.35s (~1 frame at 3.0 fps)
	char_ctrl.process(0.35)
	assert(char_ctrl.get_paper_doll_frame_index() == 45, "Breathing frame at 0.35s must be 45")
	
	# Advance another 0.35s
	char_ctrl.process(0.35)
	assert(char_ctrl.get_paper_doll_frame_index() == 46, "Breathing frame at 0.70s must be 46")
	
	# Advance another 0.35s
	char_ctrl.process(0.35)
	assert(char_ctrl.get_paper_doll_frame_index() == 47, "Breathing frame at 1.05s must be 47")
	
	# Advance another 0.35s (wraps back to 44)
	char_ctrl.process(0.35)
	assert(char_ctrl.get_paper_doll_frame_index() == 44, "Breathing frame at 1.40s must loop back to 44")
	
	assert(char_ctrl.char_paper_doll.texture == mock_frames[44], "char_paper_doll texture must match looped frame 44")
	print("  [PASS] Paperdoll SOUTH_WEST stance and 4-frame breathing cycle verified.")
	hud.queue_free()

func _test_player_animation_transitions() -> void:
	print(">>> [TEST 4] Verifying Player movement and combat auto-recovery animation transitions...")
	var player = PlayerScene.instantiate()
	root.add_child(player)
	
	assert(player.current_heading == IsometricMath.Heading.SOUTH_WEST, "Player default heading must be SOUTH_WEST")
	assert(player.motion_state == PlayerEntity.MotionState.IDLE, "Initial state must be IDLE")
	
	# 1. Sit -> Walk immediately on movement
	player.play_sit_animation()
	assert(player.motion_state == PlayerEntity.MotionState.SIT, "Player in SIT state")
	player.is_moving = true
	player._update_animation(0.016)
	assert(player.motion_state == PlayerEntity.MotionState.WALK, "Moving from SIT must transition to WALK")
	
	# 2. Stop moving -> IDLE
	player.is_moving = false
	player._update_animation(0.016)
	assert(player.motion_state == PlayerEntity.MotionState.IDLE, "Stopping movement must transition to IDLE")
	
	# 3. Attack strike auto-recovery to IDLE after 4 frames (0.5s at 8.0 FPS)
	player.play_attack_animation()
	assert(player.motion_state == PlayerEntity.MotionState.ATTACK, "Player in ATTACK state")
	player._update_animation(0.6) # advance beyond 4 frames
	assert(player.motion_state == PlayerEntity.MotionState.IDLE, "ATTACK must auto-recover to IDLE")
	
	# 4. Defend/hurt auto-recovery to IDLE after 4 frames (0.67s at 6.0 FPS)
	player.play_hurt_animation()
	assert(player.motion_state == PlayerEntity.MotionState.DEFEND, "Player in DEFEND state")
	player._update_animation(0.7)
	assert(player.motion_state == PlayerEntity.MotionState.IDLE, "DEFEND must auto-recover to IDLE")
	
	# 5. Victory celebration auto-recovery
	player.play_victory_animation()
	assert(player.motion_state == PlayerEntity.MotionState.VICTORY, "Player in VICTORY state")
	player._update_animation(2.1)
	assert(player.motion_state == PlayerEntity.MotionState.IDLE, "VICTORY must auto-recover to IDLE")
	
	print("  [PASS] Player movement transitions and combat auto-recovery verified.")
	player.queue_free()

func _test_npc_breathing_cadence() -> void:
	print(">>> [TEST 5] Verifying NPC standing breathing cadence (2.5 FPS)...")
	var npc = NpcScene.instantiate()
	root.add_child(npc)
	
	# Total 64 frames (walk 0..31, stand 32..63)
	var idx_0: int = npc._compute_frame_index(64)
	npc._anim_frame_timer = 0.4 # 1 frame at 2.5 FPS = 0.4s
	var idx_1: int = npc._compute_frame_index(64)
	assert(idx_1 == idx_0 + 1, "NPC frame index must advance by 1 after 0.4s at 2.5 FPS")
	
	# Check 2-frame broken / container frames
	npc.is_broken = false
	assert(npc._compute_frame_index(2) == 0, "Unopened 2-frame container must return frame 0")
	npc.is_broken = true
	assert(npc._compute_frame_index(2) == 1, "Opened 2-frame container must return frame 1")
	
	print("  [PASS] NPC breathing cadence and container 2-frame toggle verified.")
	npc.queue_free()

func _test_chest_container_item_granting_and_dialogue_bypass() -> void:
	print(">>> [TEST 6] Verifying Chest / Container item granting on interaction & dialogue bypass...")
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	if not map_view.entities:
		map_view._ready()
	
	var hud = map_view.get_node_or_null("CanvasLayer/HUD")
	if not hud:
		hud = map_view.hud
	assert(hud != null, "HUD must exist in MapView")
	if not hud.inventory_ctrl:
		hud._ready()
	
	var player = map_view.player
	if not player:
		player = map_view.get_node_or_null("Entities/Player")
	assert(player != null, "Player must exist in MapView")
	
	# Create a mock treasure chest NPC (template 16000)
	var chest = NpcScene.instantiate()
	chest.npc_name = "Treasure Chest"
	chest.npc_id = 16000
	chest.template_id = 16000
	chest.is_broken = false
	chest.world_position = player.world_position + Vector2(30, 30)
	map_view.entities.add_child(chest)
	
	assert(map_view.is_container_npc(chest) == true, "Treasure Chest must be recognized by is_container_npc()")
	
	# Also test casks
	var cask = NpcScene.instantiate()
	cask.npc_name = "Cask"
	cask.npc_id = 19034
	assert(map_view.is_container_npc(cask) == true, "Cask (19034) must be recognized by is_container_npc()")
	cask.queue_free()
	
	# Record initial player gold & inventory count
	var initial_gold: int = 500
	if hud.inventory_ctrl and hud.inventory_ctrl.gold_label and hud.inventory_ctrl.gold_label.text.is_valid_int():
		initial_gold = hud.inventory_ctrl.gold_label.text.to_int()
	
	# FIRST INTERACTION: Unopened Chest
	map_view.interact_with_npc(chest)
	
	# Verify chest state changed to broken (opened)
	assert(chest.is_broken == true, "Chest must be marked is_broken = true")
	
	# Verify DialogueBox is NOT opened
	assert(hud.dialogue_dock.visible == false, "DialogueBox MUST NOT open when interacting with a chest")
	
	# Verify item granted to inventory (White Rice for 16000)
	var has_reward_item: bool = false
	var reward_item_count: int = 0
	for itm in hud.inventory_ctrl.inventory_data:
		if not itm.is_empty() and int(itm.get("id", 0)) == 32001: # White Rice
			has_reward_item = true
			reward_item_count = int(itm.get("count", 0))
			break
	assert(has_reward_item == true, "Inventory must contain White Rice rewarded by chest")
	assert(reward_item_count >= 5, "Reward count must be at least 5")
	
	# Verify gold was granted (+250G)
	var new_gold: int = hud.inventory_ctrl.gold_label.text.to_int() if hud.inventory_ctrl.gold_label else 0
	assert(new_gold == initial_gold + 250, "Gold must increase by 250 (from %d to %d, was %d)" % [initial_gold, initial_gold + 250, new_gold])
	
	# SECOND INTERACTION: Already Opened Chest
	var gold_before_reclick: int = new_gold
	map_view.interact_with_npc(chest)
	
	# DialogueBox still NOT opened
	assert(hud.dialogue_dock.visible == false, "DialogueBox MUST NOT open on already opened chest")
	
	# Gold and item count must not increase again
	var gold_after_reclick: int = hud.inventory_ctrl.gold_label.text.to_int() if hud.inventory_ctrl.gold_label else 0
	assert(gold_after_reclick == gold_before_reclick, "Empty chest must not award gold again")
	
	# Verify empty speech bubble was triggered
	assert(chest.speech_bubble_label != null, "Speech bubble label must exist on chest")
	assert(chest.speech_bubble_label.text.contains("empty"), "Speech bubble must state chest is empty, was: '%s'" % chest.speech_bubble_label.text)
	
	print("  [PASS] Chest item granting, gold award, speech bubble, and dialogue bypass fully verified.")
	map_view.queue_free()
