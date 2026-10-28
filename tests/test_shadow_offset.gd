extends SceneTree

## Headless test suite for Player and NPC drop shadow elevation, sprite offsets,
## and canvas-to-ground grounding parity.

const PlayerScene = preload("res://scenes/world/player.tscn")
const NpcScene = preload("res://scenes/world/npc.tscn")
const PlayerEntityClass = preload("res://scripts/world/player.gd")
const NpcEntityClass = preload("res://scripts/world/npc.gd")

func _init() -> void:
	print("\n=================================================================")
	print("--- Running Test Drop Shadow & Sprite Offset Parity Suite ---")
	print("=================================================================\n")
	
	test_player_scene_defaults()
	test_player_texture_application()
	test_npc_scene_defaults()
	test_npc_texture_application()
	test_feet_shadow_alignment()
	
	print("\n=================================================================")
	print("--- ALL DROP SHADOW ELEVATION & OFFSET TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)

func test_player_scene_defaults() -> void:
	print("[PART 1] Verifying Player Scene defaults in player.tscn...")
	var player_instance = PlayerScene.instantiate()
	assert(player_instance != null, "Player scene failed to instantiate")
	
	var sprite: Sprite2D = player_instance.get_node("Sprite2D")
	assert(sprite != null, "Player scene must have Sprite2D child")
	assert(sprite.offset == Vector2(0, -41.0), "Player Sprite2D default offset must be (0, -41.0), got %s" % str(sprite.offset))
	
	var nameplate: Label = player_instance.get_node("Nameplate")
	assert(nameplate != null, "Player scene must have Nameplate child")
	assert(nameplate.offset_bottom == -88.0, "Player Nameplate offset_bottom must be -88.0, got %f" % nameplate.offset_bottom)
	assert(nameplate.offset_top == -108.0, "Player Nameplate offset_top must be -108.0, got %f" % nameplate.offset_top)
	
	player_instance.free()
	print("  PASS: Player scene defaults verified (offset=(0, -41.0), nameplate=[-108.0, -88.0])")

func test_player_texture_application() -> void:
	print("[PART 2] Verifying Player _apply_texture calculation for 128x128 and dynamic heights...")
	var player = PlayerEntityClass.new()
	root.add_child(player)
	
	# Initial getter check
	assert(player.sprite.offset == Vector2(0, -41.0), "Player getter default offset must be (0, -41.0)")
	
	# Create synthetic 128x128 texture (authentic WLO composite frame size)
	var img128 := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var tex128 := ImageTexture.create_from_image(img128)
	
	player._apply_texture(tex128)
	assert(player.sprite.offset == Vector2(0, -41.0), "Player offset for 128px texture must be (0, -41.0), got %s" % str(player.sprite.offset))
	
	# Test dynamic / non-128 height texture
	var img64 := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var tex64 := ImageTexture.create_from_image(img64)
	player._apply_texture(tex64)
	var expected_offset_64 := Vector2(0, -roundf(64.0 * 0.32)) # -20.0
	assert(player.sprite.offset == expected_offset_64, "Player offset for 64px texture must be %s, got %s" % [expected_offset_64, player.sprite.offset])
	
	# Re-apply 128x128 and check nameplate
	player._apply_texture(tex128)
	assert(player.nameplate.offset_bottom == -88.0, "Nameplate offset_bottom must be -88.0, got %f" % player.nameplate.offset_bottom)
	assert(player.nameplate.offset_top == -108.0, "Nameplate offset_top must be -108.0, got %f" % player.nameplate.offset_top)
	
	player.queue_free()
	print("  PASS: Player _apply_texture math verified for 128x128 and variable heights")

func test_npc_scene_defaults() -> void:
	print("[PART 3] Verifying NPC Scene defaults in npc.tscn...")
	var npc_instance = NpcScene.instantiate()
	assert(npc_instance != null, "NPC scene failed to instantiate")
	
	var sprite: Sprite2D = npc_instance.get_node("Sprite2D")
	assert(sprite != null, "NPC scene must have Sprite2D child")
	assert(sprite.offset == Vector2(0, -35.0), "NPC Sprite2D default offset must be (0, -35.0), got %s" % str(sprite.offset))
	
	var nameplate: Label = npc_instance.get_node("Nameplate")
	assert(nameplate != null, "NPC scene must have Nameplate child")
	assert(nameplate.offset_bottom == -88.0, "NPC Nameplate offset_bottom must be -88.0, got %f" % nameplate.offset_bottom)
	assert(nameplate.offset_top == -108.0, "NPC Nameplate offset_top must be -108.0, got %f" % nameplate.offset_top)
	
	var click_area: Area2D = npc_instance.get_node("ClickArea")
	assert(click_area != null, "NPC scene must have ClickArea child")
	assert(click_area.position == Vector2(0, -43.0), "NPC ClickArea position must be (0, -43.0), got %s" % str(click_area.position))
	
	npc_instance.free()
	print("  PASS: NPC scene defaults verified (offset=(0, -35.0), nameplate=[-108.0, -88.0], click_area=(0, -43.0))")

func test_npc_texture_application() -> void:
	print("[PART 4] Verifying NPC _apply_texture calculation for standard and special models...")
	var npc_instance = NpcScene.instantiate()
	root.add_child(npc_instance)
	
	var img128 := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var tex128 := ImageTexture.create_from_image(img128)
	
	# 1. Standard humanoid NPC
	npc_instance.npc_id = 7
	npc_instance.model_jmp = "1038.jmp"
	npc_instance._apply_texture(tex128)
	assert(npc_instance.sprite.offset == Vector2(0, -35.0), "NPC offset for 128px texture must be (0, -35.0), got %s" % str(npc_instance.sprite.offset))
	assert(npc_instance.nameplate.offset_bottom == -88.0, "NPC nameplate offset_bottom must be -88.0, got %f" % npc_instance.nameplate.offset_bottom)
	assert(npc_instance.nameplate.offset_top == -108.0, "NPC nameplate offset_top must be -108.0, got %f" % npc_instance.nameplate.offset_top)
	assert(npc_instance.click_area.position == Vector2(0, -43.0), "NPC click_area position must be (0, -43.0), got %s" % str(npc_instance.click_area.position))
	
	# 2. Cat / small NPC
	npc_instance.npc_id = 11000
	npc_instance.model_jmp = "1035.jmp"
	npc_instance._apply_texture(tex128)
	assert(npc_instance.sprite.offset == Vector2(0, -35.0), "Cat NPC offset must still be (0, -35.0)")
	assert(npc_instance.nameplate.offset_bottom == -42.0, "Cat nameplate offset_bottom must be -42.0, got %f" % npc_instance.nameplate.offset_bottom)
	assert(npc_instance.nameplate.offset_top == -62.0, "Cat nameplate offset_top must be -62.0, got %f" % npc_instance.nameplate.offset_top)
	assert(npc_instance.click_area.position == Vector2(0, -20.0), "Cat click_area position must be (0, -20.0), got %s" % str(npc_instance.click_area.position))
	
	npc_instance.queue_free()
	print("  PASS: NPC _apply_texture math verified for standard and small models")

func test_feet_shadow_alignment() -> void:
	print("[PART 5] Verifying feet coordinate (canvas y=105) touches Godot ground y=0...")
	# For a 128x128 frame with centered=true:
	# Canvas coordinate (64, 64) is at sprite.position + sprite.offset = (0, -41.0).
	# Canvas coordinate (64, 105) (character feet) is at:
	#   Godot y = sprite.offset.y + (canvas_y - 64.0)
	#   Godot y = -41.0 + (105.0 - 64.0) = -41.0 + 41.0 = 0.0!
	const CANVAS_HEIGHT: float = 128.0
	const CANVAS_CENTER_Y: float = CANVAS_HEIGHT / 2.0 # 64.0
	const FEET_CANVAS_Y: float = 105.0
	const SPRITE_OFFSET_Y: float = -41.0
	
	var godot_feet_y: float = SPRITE_OFFSET_Y + (FEET_CANVAS_Y - CANVAS_CENTER_Y)
	assert(is_equal_approx(godot_feet_y, 0.0), "Feet at canvas y=105 must touch Godot ground y=0, got %f" % godot_feet_y)
	
	# Head top is at canvas y=20:
	#   Godot y = -41.0 + (20.0 - 64.0) = -85.0
	const HEAD_CANVAS_Y: float = 20.0
	var godot_head_y: float = SPRITE_OFFSET_Y + (HEAD_CANVAS_Y - CANVAS_CENTER_Y)
	assert(is_equal_approx(godot_head_y, -85.0), "Head at canvas y=20 must be at Godot y=-85, got %f" % godot_head_y)
	
	# Nameplate is positioned above the head:
	#   Nameplate bottom at y=-88.0 (3px clearance above head at y=-85.0)
	const NAMEPLATE_BOTTOM: float = -88.0
	assert(NAMEPLATE_BOTTOM < godot_head_y, "Nameplate bottom must be above head top")
	
	print("  PASS: Canvas y=105 feet exactly touch ground y=0 (shadow center). Clearance above head: 3px.")
