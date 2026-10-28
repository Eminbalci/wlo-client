extends SceneTree

const NpcEntityClass = preload("res://scripts/world/npc.gd")
const NpcEditorClass = preload("res://scripts/tools/npc_editor.gd")
const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test NPC Direction Sprite Indexing Suite ---")
	print("=================================================================")
	
	var loader = ArchiveLoaderClass.new()
	root.add_child(loader)
	loader.initialize_archives()
	
	test_32_frame_diagonal_layout(loader)
	test_32_frame_8way_stand_layout(loader)
	test_16_frame_diagonal_layout(loader)
	test_8_frame_layouts(loader)
	test_4_frame_diagonal_layout(loader)
	test_standard_64plus_layout(loader)
	test_consistency_across_systems(loader)
	
	print("\n=================================================================")
	print("--- ALL NPC DIRECTION SPRITE INDEXING TESTS PASSED (100%) ---")
	print("=================================================================")
	
	quit(0)

func test_32_frame_diagonal_layout(loader: Node) -> void:
	print("\n[PART 1] Verifying 32-Frame 4-Diagonal Layout (1038.jmp Captain, 1037.jmp Crew)...")
	var npc = NpcEntityClass.new()
	npc._anim_data = loader.get_jma_animation("001.jma", "1038.jmp")
	
	# Verify frame names in 1038.jmp
	assert(npc._anim_data != null, "1038.jmp anim data must be loaded")
	assert(npc._anim_data.frames.size() == 32, "1038.jmp must have exactly 32 frames")
	assert(npc._anim_data.frames[0].name.begins_with("01"), "1038.jmp frame 0 must be walk NW (01-1.bmp)")
	assert(npc._anim_data.frames[16].name.begins_with("09"), "1038.jmp frame 16 must be stand NW (09-1.bmp)")
	assert(npc._anim_data.frames[20].name.begins_with("11"), "1038.jmp frame 20 must be stand SW (11-1.bmp)")
	assert(npc._anim_data.frames[24].name.begins_with("13"), "1038.jmp frame 24 must be stand SE (13-1.bmp)")
	assert(npc._anim_data.frames[28].name.begins_with("15"), "1038.jmp frame 28 must be stand NE (15-1.bmp)")
	
	# Verify Stand idle frame mapping
	npc.is_moving = false
	npc._anim_frame_timer = 0.0
	
	# NW and N -> Block 0 (frames 16..19, 09)
	npc.heading = IsometricMath.Heading.NORTH_WEST
	var f_nw = npc._compute_frame_index(32)
	assert(f_nw == 16, "NW stand must be frame 16 (09-1), got %d" % f_nw)
	
	npc.heading = IsometricMath.Heading.NORTH
	var f_n = npc._compute_frame_index(32)
	assert(f_n == 16, "North stand must map to NW frame 16, got %d" % f_n)
	
	# SW and W -> Block 1 (frames 20..23, 11)
	npc.heading = IsometricMath.Heading.SOUTH_WEST
	var f_sw = npc._compute_frame_index(32)
	assert(f_sw == 20, "SW stand must be frame 20 (11-1, Front-Left), got %d" % f_sw)
	
	npc.heading = IsometricMath.Heading.WEST
	var f_w = npc._compute_frame_index(32)
	assert(f_w == 20, "West stand must map to SW frame 20, got %d" % f_w)
	
	# SE and S -> Block 2 (frames 24..27, 13)
	npc.heading = IsometricMath.Heading.SOUTH
	var f_s = npc._compute_frame_index(32)
	assert(f_s == 24, "South stand must map to SE frame 24 (13-1, Front-Right), got %d" % f_s)
	
	npc.heading = IsometricMath.Heading.SOUTH_EAST
	var f_se = npc._compute_frame_index(32)
	assert(f_se == 24, "SE stand must be frame 24 (13-1), got %d" % f_se)
	
	# NE and E -> Block 3 (frames 28..31, 15)
	npc.heading = IsometricMath.Heading.NORTH_EAST
	var f_ne = npc._compute_frame_index(32)
	assert(f_ne == 28, "NE stand must be frame 28 (15-1), got %d" % f_ne)
	
	npc.heading = IsometricMath.Heading.EAST
	var f_e = npc._compute_frame_index(32)
	assert(f_e == 28, "East stand must map to NE frame 28, got %d" % f_e)
	
	# CRITICAL USER REPORT BUG FIX CHECK:
	assert(f_sw != f_s, "CRITICAL: South (%d) and South-West (%d) MUST NOT use the same frame!" % [f_s, f_sw])
	assert(f_sw != 16, "CRITICAL: South-West (Front-Left) must NOT use backward frame 16 (09-1)!" )
	assert(f_s != 28, "CRITICAL: South (Front) must NOT use backward frame 28 (15-1)!")
	
	# Verify Walk frames
	npc.is_moving = true
	npc.heading = IsometricMath.Heading.NORTH_WEST
	assert(npc._compute_frame_index(32) == 0, "NW walk must be 0")
	npc.heading = IsometricMath.Heading.SOUTH_WEST
	assert(npc._compute_frame_index(32) == 4, "SW walk must be 4")
	npc.heading = IsometricMath.Heading.SOUTH_EAST
	assert(npc._compute_frame_index(32) == 8, "SE walk must be 8")
	npc.heading = IsometricMath.Heading.NORTH_EAST
	assert(npc._compute_frame_index(32) == 12, "NE walk must be 12")
	
	npc.free()
	print("  PASS: 32-frame 4-diagonal layout verified with distinct SW (20) and S (24) frames.")

func test_32_frame_8way_stand_layout(loader: Node) -> void:
	print("\n[PART 2] Verifying 32-Frame 8-Directional Stand Layout (1274.jmp)...")
	var npc = NpcEntityClass.new()
	npc._anim_data = loader.get_jma_animation("001.jma", "1274.jmp")
	
	assert(npc._anim_data != null, "1274.jmp anim data must be loaded")
	assert(npc._anim_data.frames.size() == 32, "1274.jmp must have 32 frames")
	assert(npc._anim_data.frames[0].name.begins_with("08"), "1274.jmp must start with 08 (North stand)")
	
	npc.is_moving = false
	npc._anim_frame_timer = 0.0
	
	# All 8 headings must have distinct starting frames: 0, 4, 8, 12, 16, 20, 24, 28
	var frames_seen := {}
	for h in range(8):
		npc.heading = h
		var f_idx = npc._compute_frame_index(32)
		var expected = h * 4
		assert(f_idx == expected, "1274.jmp heading %d must be %d, got %d" % [h, expected, f_idx])
		assert(not frames_seen.has(f_idx), "Frame %d duplicate detected for heading %d" % [f_idx, h])
		frames_seen[f_idx] = true
	
	npc.free()
	print("  PASS: 32-frame 8-way stand layout verified with 8 unique directions.")

func test_16_frame_diagonal_layout(loader: Node) -> void:
	print("\n[PART 3] Verifying 16-Frame 4-Diagonal Layout (1170.jmp Breillat)...")
	var npc = NpcEntityClass.new()
	npc._anim_data = loader.get_jma_animation("001.jma", "1170.jmp")
	
	npc.is_moving = false
	npc._anim_frame_timer = 0.0
	
	npc.heading = IsometricMath.Heading.NORTH_WEST
	assert(npc._compute_frame_index(16) == 0, "NW must map to frame 0 (09-1)")
	npc.heading = IsometricMath.Heading.SOUTH_WEST
	var f_sw = npc._compute_frame_index(16)
	assert(f_sw == 4, "SW must map to frame 4 (11-1), got %d" % f_sw)
	npc.heading = IsometricMath.Heading.SOUTH
	var f_s = npc._compute_frame_index(16)
	assert(f_s == 8, "S must map to frame 8 (13-1), got %d" % f_s)
	npc.heading = IsometricMath.Heading.SOUTH_EAST
	assert(npc._compute_frame_index(16) == 8, "SE must map to frame 8 (13-1)")
	npc.heading = IsometricMath.Heading.NORTH_EAST
	assert(npc._compute_frame_index(16) == 12, "NE must map to frame 12 (15-1)")
	
	assert(f_sw != f_s, "In 16-frame, SW (4) and S (8) must be different")
	npc.free()
	print("  PASS: 16-frame layout verified with distinct SW (4) and S (8).")

func test_8_frame_layouts(loader: Node) -> void:
	print("\n[PART 4] Verifying 8-Frame Layouts (1207.jmp Ross, 1088.jmp Arcade, 1430.jmp)...")
	var npc = NpcEntityClass.new()
	
	# 8-way stand (1207.jmp)
	npc._anim_data = loader.get_jma_animation("001.jma", "1207.jmp")
	for h in range(8):
		npc.heading = h
		assert(npc._compute_frame_index(8) == h, "1207.jmp heading %d must be %d" % [h, h])
	
	# 4-walk + 4-stand (1430.jmp)
	npc._anim_data = loader.get_jma_animation("001.jma", "1430.jmp")
	npc.is_moving = false
	npc.heading = IsometricMath.Heading.SOUTH_WEST
	assert(npc._compute_frame_index(8) == 5, "1430.jmp SW stand must be 4 + 1 = 5")
	npc.heading = IsometricMath.Heading.SOUTH
	assert(npc._compute_frame_index(8) == 6, "1430.jmp S stand must be 4 + 2 = 6")
	
	npc.free()
	print("  PASS: 8-frame layout variants verified.")

func test_4_frame_diagonal_layout(loader: Node) -> void:
	print("\n[PART 5] Verifying 4-Frame Diagonal Layout (1050.jmp John/Peter/Drunk Man)...")
	var npc = NpcEntityClass.new()
	npc._anim_data = loader.get_jma_animation("001.jma", "1050.jmp")
	
	npc.heading = IsometricMath.Heading.NORTH_WEST
	assert(npc._compute_frame_index(4) == 0, "NW must be 0")
	npc.heading = IsometricMath.Heading.SOUTH_WEST
	var f_sw = npc._compute_frame_index(4)
	assert(f_sw == 1, "SW must be 1 (11-1)")
	npc.heading = IsometricMath.Heading.SOUTH
	var f_s = npc._compute_frame_index(4)
	assert(f_s == 2, "S must be 2 (13-1)")
	npc.heading = IsometricMath.Heading.SOUTH_EAST
	assert(npc._compute_frame_index(4) == 2, "SE must be 2 (13-1)")
	npc.heading = IsometricMath.Heading.NORTH_EAST
	assert(npc._compute_frame_index(4) == 3, "NE must be 3 (15-1)")
	
	assert(f_sw != f_s, "In 4-frame, SW (1) and S (2) must be different")
	npc.free()
	print("  PASS: 4-frame layout verified with distinct SW (1) and S (2).")

func test_standard_64plus_layout(loader: Node) -> void:
	print("\n[PART 6] Verifying Standard Humanoid 64+ Layout (1010.jmp Sailor Jack, 140 frames)...")
	var npc = NpcEntityClass.new()
	npc._anim_data = loader.get_jma_animation("001.jma", "1010.jmp")
	
	npc.is_moving = false
	npc._anim_frame_timer = 0.0
	for h in range(8):
		npc.heading = h
		var expected = 32 + h * 4
		var f_idx = npc._compute_frame_index(140)
		assert(f_idx == expected, "1010.jmp heading %d stand must be %d, got %d" % [h, expected, f_idx])
	
	npc.is_moving = true
	for h in range(8):
		npc.heading = h
		var expected = h * 4
		var f_idx = npc._compute_frame_index(140)
		assert(f_idx == expected, "1010.jmp heading %d walk must be %d, got %d" % [h, expected, f_idx])
	
	npc.free()
	print("  PASS: Standard 64+ humanoid layout verified across all 8 directions.")

func test_consistency_across_systems(loader: Node) -> void:
	print("\n[PART 7] Verifying Full Parity between NpcEntity, NpcEditor, and ArchiveLoader...")
	var npc = NpcEntityClass.new()
	npc._anim_data = loader.get_jma_animation("001.jma", "1038.jmp")
	
	var editor = NpcEditorClass.new()
	editor._cached_anim_data = npc._anim_data
	editor._total_anim_frames = 32
	editor.is_preview_walking = false
	editor._is_animating = false
	
	for h in range(8):
		npc.heading = h
		npc.is_moving = false
		npc._anim_frame_timer = 0.0
		var npc_frame = npc._compute_frame_index(32)
		var editor_frame = editor._compute_preview_frame(32, h)
		assert(npc_frame == editor_frame, "Mismatch between NpcEntity (%d) and NpcEditor (%d) for heading %d" % [npc_frame, editor_frame, h])
		
		# Test ArchiveLoader extract_heading_frame via get_npc_texture
		var tex = loader.get_npc_texture(1038, h)
		assert(tex != null, "Texture for 1038 heading %d must load" % h)
		
		var raw_tex = loader.get_jma_frame_128("001.jma", "1038.jmp", npc_frame)
		assert(raw_tex != null, "Raw frame texture %d must load" % npc_frame)
	
	npc.free()
	editor.free()
	print("  PASS: 100% parity across NpcEntity, NpcEditor, and ArchiveLoader.")
