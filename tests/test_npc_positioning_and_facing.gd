extends SceneTree

## Headless test suite for NPC Positioning, Facing, Eve.emg Rotations, and JMP Animations.
## Verifies 100% authentic parity with Wonderland Online binary archives.

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const EveParser = preload("res://scripts/map/eve_parser.gd")
const NpcEntityClass = preload("res://scripts/world/npc.gd")
const MapViewScene = preload("res://scenes/world/map_view.tscn")

func _init() -> void:
	print("\n=================================================================")
	print("--- Running Test NPC Positioning & Facing Parity Suite ---")
	print("=================================================================\n")
	
	test_rotation_to_heading_math()
	test_eve_parser_map_10001_npcs()
	test_eve_parser_map_10002_npcs()
	test_npc_entity_frame_computation()
	test_map_view_scene_npc_parity()
	test_cabin_spawn_npc_parity()
	
	print("\n=================================================================")
	print("--- ALL NPC POSITIONING & FACING TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)

func test_rotation_to_heading_math() -> void:
	print("[PART 1] Verifying Eve.emg Clockwise (1..8) to IsometricMath Heading (0..7)...")
	
	# Authentic mappings verified against real client rendering:
	# Rot 1 (North) -> Heading.NORTH (0)
	# Rot 2 (North-East) -> Heading.NORTH_EAST (7)
	# Rot 3 (East) -> Heading.EAST (6)
	# Rot 4 (South-East) -> Heading.SOUTH_EAST (5)
	# Rot 5 (South) -> Heading.SOUTH (4)
	# Rot 6 (South-West) -> Heading.SOUTH_WEST (3)
	# Rot 7 (West) -> Heading.WEST (2)
	# Rot 8 (North-West) -> Heading.NORTH_WEST (1)
	
	var expected := {
		1: IsometricMath.Heading.NORTH,      # 0
		2: IsometricMath.Heading.NORTH_EAST,  # 7
		3: IsometricMath.Heading.EAST,        # 6
		4: IsometricMath.Heading.SOUTH_EAST,  # 5
		5: IsometricMath.Heading.SOUTH,       # 4
		6: IsometricMath.Heading.SOUTH_WEST,  # 3
		7: IsometricMath.Heading.WEST,        # 2
		8: IsometricMath.Heading.NORTH_WEST   # 1
	}
	
	for rot in expected:
		var heading: int = IsometricMath.rotation_to_heading(rot)
		assert(heading == expected[rot], "Rot %d must map to heading %d (got %d)" % [rot, expected[rot], heading])
		var back_rot: int = IsometricMath.heading_to_rotation(heading)
		assert(back_rot == rot, "Heading %d must map back to rot %d (got %d)" % [heading, rot, back_rot])
	
	# Boundary checks
	assert(IsometricMath.rotation_to_heading(0) == IsometricMath.Heading.SOUTH, "Rot 0 should default to SOUTH")
	
	print("  PASS: Bidirectional rotation-to-heading bijection verified (8 directions)")

func test_eve_parser_map_10001_npcs() -> void:
	print("[PART 2] Verifying Eve.emg Category 0 Decoding for Map 10001 (Ship Deck)...")
	var parser := EveParser.new()
	assert(parser.initialize(), "EveParser must initialize successfully")
	
	var npcs := parser.get_npcs_for_map(10001)
	assert(npcs.size() == 11, "Map 10001 must contain exactly 11 NPCs (got %d)" % npcs.size())
	
	var expected_10001 := {
		1: {"id": 14091, "pos": Vector2(117, 1303), "rot": 6, "heading": 3}, # Jack
		2: {"id": 14152, "pos": Vector2(102, 1312), "rot": 6, "heading": 3}, # Ross
		3: {"id": 14002, "pos": Vector2(343, 940),  "rot": 4, "heading": 5}, # Crew
		4: {"id": 14001, "pos": Vector2(1461, 315), "rot": 6, "heading": 3}, # Deck Crew
		5: {"id": 14080, "pos": Vector2(855, 1302), "rot": 4, "heading": 5}, # Visitor 1
		6: {"id": 14087, "pos": Vector2(814, 1313), "rot": 4, "heading": 5}, # Visitor 2
		7: {"id": 14065, "pos": Vector2(1013, 902), "rot": 6, "heading": 3}, # Girl
		8: {"id": 11000, "pos": Vector2(1027, 957), "rot": 6, "heading": 3}, # Cat
		9: {"id": 14002, "pos": Vector2(1393, 578), "rot": 6, "heading": 3}, # Crew
		10: {"id": 14003, "pos": Vector2(1421, 632), "rot": 6, "heading": 3}, # Captain Robinson
		11: {"id": 14001, "pos": Vector2(405, 925), "rot": 6, "heading": 3}, # Deck Crew
	}
	
	for n in npcs:
		assert(expected_10001.has(n.click_id), "Unexpected ClickID %d" % n.click_id)
		var exp: Dictionary = expected_10001[n.click_id]
		assert(n.npc_id == exp["id"], "ClickID %d NPC ID mismatch: exp %d got %d" % [n.click_id, exp["id"], n.npc_id])
		assert(n.world_pos == exp["pos"], "ClickID %d Pos mismatch: exp %s got %s" % [n.click_id, exp["pos"], n.world_pos])
		assert(n.rotation == exp["rot"], "ClickID %d Rot mismatch: exp %d got %d" % [n.click_id, exp["rot"], n.rotation])
		assert(n.heading == exp["heading"], "ClickID %d Heading mismatch: exp %d got %d" % [n.click_id, exp["heading"], n.heading])
	
	# Verify walksteps for Deck Crew 1 and Cat
	var deck_crew := parser.get_npc_by_id(10001, 4)
	assert(deck_crew.walksteps.size() == 2, "Deck Crew must have 2 walksteps")
	assert(deck_crew.walksteps[0] == Vector2(1462, 316) and deck_crew.walksteps[1] == Vector2(1982, 601), "Deck Crew walksteps verified")
	
	var cat := parser.get_npc_by_id(10001, 8)
	assert(cat.walksteps.size() == 2, "Cat must have 2 walksteps")
	assert(cat.walksteps[0] == Vector2(936, 942) and cat.walksteps[1] == Vector2(1126, 943), "Cat walksteps verified")
	assert(cat.walkstep_delays[0] == 3.0 and cat.walkstep_delays[1] == 3.0, "Cat walkstep delay must be 3.0s")
	
	print("  PASS: All 11 Map 10001 NPCs, coordinates, rotations, and walksteps verified")

func test_eve_parser_map_10002_npcs() -> void:
	print("[PART 3] Verifying Eve.emg Category 0 Decoding for Map 10002 (Cabin)...")
	var parser := EveParser.new()
	assert(parser.initialize(), "EveParser must initialize successfully")
	
	var npcs := parser.get_npcs_for_map(10002)
	assert(npcs.size() == 7, "Map 10002 must contain exactly 7 NPCs (got %d)" % npcs.size())
	
	var expected_10002 := {
		1: {"id": 14042, "pos": Vector2(851, 539),  "rot": 8, "heading": 1}, # Drunk Man
		2: {"id": 14146, "pos": Vector2(1302, 800), "rot": 2, "heading": 7}, # Peter
		3: {"id": 14145, "pos": Vector2(1309, 714), "rot": 4, "heading": 5}, # John
		4: {"id": 14303, "pos": Vector2(1440, 682), "rot": 6, "heading": 3}, # Natasha
		5: {"id": 10000, "pos": Vector2(1155, 580), "rot": 6, "heading": 3}, # Breillat
		6: {"id": 18000, "pos": Vector2(226, 795),  "rot": 5, "heading": 4}, # Game Machine a
		7: {"id": 18001, "pos": Vector2(141, 829),  "rot": 5, "heading": 4}, # Game Machine b
	}
	
	for n in npcs:
		assert(expected_10002.has(n.click_id), "Unexpected ClickID %d in 10002" % n.click_id)
		var exp: Dictionary = expected_10002[n.click_id]
		assert(n.npc_id == exp["id"], "Cabin ClickID %d NPC ID mismatch: exp %d got %d" % [n.click_id, exp["id"], n.npc_id])
		assert(n.world_pos == exp["pos"], "Cabin ClickID %d Pos mismatch: exp %s got %s" % [n.click_id, exp["pos"], n.world_pos])
		assert(n.rotation == exp["rot"], "Cabin ClickID %d Rot mismatch: exp %d got %d" % [n.click_id, exp["rot"], n.rotation])
		assert(n.heading == exp["heading"], "Cabin ClickID %d Heading mismatch: exp %d got %d" % [n.click_id, exp["heading"], n.heading])
	
	print("  PASS: All 7 Map 10002 NPCs, coordinates, and facing headings verified")

func test_npc_entity_frame_computation() -> void:
	print("[PART 4] Verifying NpcEntity Frame Computation for Different JMP Layouts...")
	var npc := NpcEntityClass.new()
	
	# 1. 140-frame layout (Jack 1010.jmp, Girl 1009.jmp, Natasha 1068.jmp)
	# Stand base = 32. Directions: 0..7 map to 32, 36, 40, 44, 48, 52, 56, 60
	npc.is_moving = false
	npc.heading = IsometricMath.Heading.SOUTH_WEST # 3
	var f_sw_stand: int = npc._compute_frame_index(140)
	assert(f_sw_stand >= 44 and f_sw_stand <= 47, "Heading 3 standing in 140 frames must be 44..47 (got %d)" % f_sw_stand)
	
	npc.heading = IsometricMath.Heading.SOUTH_EAST # 5
	var f_se_stand: int = npc._compute_frame_index(140)
	assert(f_se_stand >= 52 and f_se_stand <= 55, "Heading 5 standing in 140 frames must be 52..55 (got %d)" % f_se_stand)
	
	# 2. 32-frame layout (Captain 1038.jmp, Sailor 1037.jmp)
	# 4 diagonal directions * 4 walk frames (0..15) + 4 stand frames (16..31)
	# NW (diag 0: 16..19 / 0..3), SW (diag 1: 20..23 / 4..7), SE (diag 2: 24..27 / 8..11), NE (diag 3: 28..31 / 12..15)
	npc.heading = IsometricMath.Heading.SOUTH_WEST # 3
	var f_cap_sw: int = npc._compute_frame_index(32)
	assert(f_cap_sw >= 20 and f_cap_sw <= 23, "Captain heading 3 standing must map to stand frames 20..23 (got %d)" % f_cap_sw)
	
	npc.heading = IsometricMath.Heading.SOUTH_EAST # 5
	var f_cap_se: int = npc._compute_frame_index(32)
	assert(f_cap_se >= 24 and f_cap_se <= 27, "Captain heading 5 standing must map to stand frames 24..27 (got %d)" % f_cap_se)
	
	# Walk frames: SW (diag 1) -> Walk 4..7, SE (diag 2) -> Walk 8..11
	npc.is_moving = true
	npc.heading = IsometricMath.Heading.SOUTH_WEST # 3
	var f_cap_sw_walk: int = npc._compute_frame_index(32)
	assert(f_cap_sw_walk >= 4 and f_cap_sw_walk <= 7, "Captain heading 3 walking must map to walk frames 4..7 (got %d)" % f_cap_sw_walk)
	
	npc.heading = IsometricMath.Heading.SOUTH_EAST # 5
	var f_cap_se_walk: int = npc._compute_frame_index(32)
	assert(f_cap_se_walk >= 8 and f_cap_se_walk <= 11, "Captain heading 5 walking must map to walk frames 8..11 (got %d)" % f_cap_se_walk)
	npc.is_moving = false
	
	# 3. 16-frame layout (Breillat 1170.jmp, 4 diagonal directions * 4 frames)
	# Block 0: NW (1), Block 1: SW (3), Block 2: SE (5), Block 3: NE (7)
	npc.heading = IsometricMath.Heading.SOUTH_WEST # 3
	var f_breil_sw: int = npc._compute_frame_index(16)
	assert(f_breil_sw >= 4 and f_breil_sw <= 7, "Breillat heading 3 (SW) must map to frames 4..7 (got %d)" % f_breil_sw)
	
	npc.heading = IsometricMath.Heading.NORTH_WEST # 1
	var f_breil_nw: int = npc._compute_frame_index(16)
	assert(f_breil_nw >= 0 and f_breil_nw <= 3, "Breillat heading 1 (NW) must map to frames 0..3 (got %d)" % f_breil_nw)
	
	# 4. 8-frame layout (Ross 1207.jmp, Game Machine 1088.jmp/1089.jmp)
	# 8 directions * 1 frame
	npc.heading = IsometricMath.Heading.SOUTH_WEST # 3
	assert(npc._compute_frame_index(8) == 3, "Ross heading 3 must return frame 3")
	npc.heading = IsometricMath.Heading.SOUTH # 4
	assert(npc._compute_frame_index(8) == 4, "Game Machine heading 4 must return frame 4")
	
	# 5. 4-frame layout (Drunk Man / Peter / John 1050.jmp)
	# Frame 0: NW (1), Frame 1: SW (3), Frame 2: SE (5), Frame 3: NE (7)
	npc.heading = IsometricMath.Heading.NORTH_WEST # 1
	assert(npc._compute_frame_index(4) == 0, "Drunk Man heading 1 (NW) must return frame 0 (09-1)")
	npc.heading = IsometricMath.Heading.SOUTH_WEST # 3
	assert(npc._compute_frame_index(4) == 1, "Heading 3 (SW) must return frame 1 (11-1)")
	npc.heading = IsometricMath.Heading.SOUTH_EAST # 5
	assert(npc._compute_frame_index(4) == 2, "John heading 5 (SE) must return frame 2 (13-1)")
	npc.heading = IsometricMath.Heading.NORTH_EAST # 7
	assert(npc._compute_frame_index(4) == 3, "Peter heading 7 (NE) must return frame 3 (15-1)")
	
	npc.free()
	print("  PASS: All 5 JMP frame layout categories (140, 32, 16, 8, 4) verified")

func test_map_view_scene_npc_parity() -> void:
	print("[PART 5] Verifying map_view.tscn Node Hierarchy and NPC Data...")
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	
	var entities := map_view.get_node_or_null("Entities")
	assert(entities != null, "Entities container must exist in MapView")
	
	var captain := entities.get_node_or_null("CaptainNPC")
	assert(captain != null, "CaptainNPC node must exist")
	assert(captain.npc_id == 14003, "Captain npc_id must be 14003")
	assert(captain.npc_name == "Captain Robinson", "Captain name must be 'Captain Robinson' (got %s)" % captain.npc_name)
	assert(captain.world_position == Vector2(1421, 632), "Captain world_position must be (1421, 632)")
	assert(captain.heading == IsometricMath.Heading.SOUTH_WEST, "Captain heading must be SOUTH_WEST (3) (got %d)" % captain.heading)
	
	var crew_deck1 := entities.get_node_or_null("CrewDeck1NPC")
	assert(crew_deck1 != null, "CrewDeck1NPC node must exist")
	assert(crew_deck1.world_position == Vector2(1461, 315), "CrewDeck1NPC position must be (1461, 315)")
	assert(crew_deck1.heading == IsometricMath.Heading.SOUTH_WEST, "CrewDeck1NPC heading must be SOUTH_WEST (3)")
	assert(crew_deck1.walksteps.size() == 2 and crew_deck1.walksteps[0] == Vector2(1462, 316) and crew_deck1.walksteps[1] == Vector2(1982, 601), "CrewDeck1NPC walksteps must match Eve.emg [(1462,316), (1982,601)]")
	
	var jack := entities.get_node_or_null("JackNPC")
	assert(jack != null and jack.world_position == Vector2(117, 1303), "Jack position must be (117, 1303)")
	assert(jack.heading == IsometricMath.Heading.SOUTH_WEST, "Jack heading must be SOUTH_WEST (3)")
	
	var ross := entities.get_node_or_null("RossNPC")
	assert(ross != null and ross.world_position == Vector2(102, 1312), "Ross position must be (102, 1312)")
	assert(ross.heading == IsometricMath.Heading.SOUTH_WEST, "Ross heading must be SOUTH_WEST (3)")
	
	var girl := entities.get_node_or_null("GirlNPC")
	assert(girl != null and girl.world_position == Vector2(1013, 902), "Girl position must be (1013, 902)")
	assert(girl.heading == IsometricMath.Heading.SOUTH_WEST, "Girl heading must be SOUTH_WEST (3)")
	
	var cat := entities.get_node_or_null("CatNPC")
	assert(cat != null and cat.world_position == Vector2(1027, 957), "Cat position must be (1027, 957)")
	assert(cat.heading == IsometricMath.Heading.SOUTH_WEST, "Cat heading must be SOUTH_WEST (3)")
	
	var vis1 := entities.get_node_or_null("Visitor1NPC")
	assert(vis1 != null and vis1.world_position == Vector2(855, 1302), "Visitor 1 position must be (855, 1302)")
	assert(vis1.heading == IsometricMath.Heading.SOUTH_EAST, "Visitor 1 heading must be SOUTH_EAST (5)")
	
	var vis2 := entities.get_node_or_null("Visitor2NPC")
	assert(vis2 != null and vis2.world_position == Vector2(814, 1313), "Visitor 2 position must be (814, 1313)")
	assert(vis2.heading == IsometricMath.Heading.SOUTH_EAST, "Visitor 2 heading must be SOUTH_EAST (5)")
	
	var crew1 := entities.get_node_or_null("Crew1NPC")
	assert(crew1 != null and crew1.world_position == Vector2(343, 940), "Crew 1 position must be (343, 940)")
	assert(crew1.heading == IsometricMath.Heading.SOUTH_EAST, "Crew 1 heading must be SOUTH_EAST (5)")
	
	var crew2 := entities.get_node_or_null("Crew2NPC")
	assert(crew2 != null and crew2.world_position == Vector2(1393, 578), "Crew 2 position must be (1393, 578)")
	assert(crew2.heading == IsometricMath.Heading.SOUTH_WEST, "Crew 2 heading must be SOUTH_WEST (3)")
	
	var crew_deck2 := entities.get_node_or_null("CrewDeck2NPC")
	assert(crew_deck2 != null and crew_deck2.world_position == Vector2(405, 925), "CrewDeck 2 position must be (405, 925)")
	assert(crew_deck2.heading == IsometricMath.Heading.SOUTH_WEST, "CrewDeck 2 heading must be SOUTH_WEST (3)")
	
	map_view.queue_free()
	
	# Verify dedicated scenes/maps/map_10001_ship_deck.tscn scene loading
	var map_10001_scene = load("res://scenes/maps/map_10001_ship_deck.tscn")
	assert(map_10001_scene != null, "scenes/maps/map_10001_ship_deck.tscn must be loadable")
	var deck_instance = map_10001_scene.instantiate()
	assert(deck_instance != null, "map_10001_ship_deck.tscn must instantiate cleanly")
	var deck_captain = deck_instance.get_node_or_null("Entities/CaptainNPC")
	assert(deck_captain != null and deck_captain.npc_id == 14003, "Captain NPC must exist in map_10001_ship_deck.tscn")
	assert(deck_captain.world_position == Vector2(1421, 632), "Captain NPC position in map_10001_ship_deck.tscn must match (1421, 632)")
	deck_instance.queue_free()
	
	print("  PASS: All Deck NPCs in map_view.tscn and map_10001_ship_deck.tscn validated against authentic coordinates and headings")

func test_cabin_spawn_npc_parity() -> void:
	print("[PART 6] Verifying Cabin (Map 10002) Entity Spawning & Face-to-Face Table Alignment...")
	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	
	# Switch to Cabin (Map 10002)
	map_view._switch_map_entities(10002)
	
	var cabin_list: Array = map_view._cabin_entities
	assert(cabin_list.size() == 7, "Cabin must spawn exactly 7 entities (got %d)" % cabin_list.size())
	
	var npcs_by_id := {}
	for c in cabin_list:
		npcs_by_id[c.npc_id] = c
	
	# Verify Drunk Man
	var drunk = npcs_by_id[14042]
	assert(drunk.world_position == Vector2(851, 539), "Drunk Man pos must be (851, 539)")
	assert(drunk.heading == IsometricMath.Heading.NORTH_WEST, "Drunk Man heading must be NORTH_WEST (1)")
	
	# Verify Peter & John (Sitting across from each other)
	var peter = npcs_by_id[14146]
	var john = npcs_by_id[14145]
	assert(peter.world_position == Vector2(1302, 800), "Peter pos must be (1302, 800)")
	assert(john.world_position == Vector2(1309, 714), "John pos must be (1309, 714)")
	assert(peter.heading == IsometricMath.Heading.NORTH_EAST, "Peter must face NORTH_EAST (7) towards John")
	assert(john.heading == IsometricMath.Heading.SOUTH_EAST, "John must face SOUTH_EAST (5) towards Peter")
	
	# Verify Natasha & Breillat
	var natasha = npcs_by_id[14303]
	assert(natasha.world_position == Vector2(1440, 682), "Natasha pos must be (1440, 682)")
	assert(natasha.heading == IsometricMath.Heading.SOUTH_WEST, "Natasha heading must be SOUTH_WEST (3)")
	
	var breillat = npcs_by_id[10000]
	assert(breillat.world_position == Vector2(1155, 580), "Breillat pos must be (1155, 580)")
	assert(breillat.heading == IsometricMath.Heading.SOUTH_WEST, "Breillat heading must be SOUTH_WEST (3)")
	if breillat.sprite and breillat.sprite.texture:
		var b_img: Image = breillat.sprite.texture.get_image()
		assert(b_img.get_pixel(64, 95).a == 0.0, "Breillat lower legs behind bar counter must be clipped transparent")
	
	# Verify Arcade Machines
	var arcade_a = npcs_by_id[18000]
	var arcade_b = npcs_by_id[18001]
	assert(arcade_a.world_position == Vector2(226, 795), "Arcade a pos must be (226, 795)")
	assert(arcade_b.world_position == Vector2(141, 829), "Arcade b pos must be (141, 829)")
	assert(arcade_a.heading == IsometricMath.Heading.SOUTH, "Arcade a heading must be SOUTH (4)")
	assert(arcade_b.heading == IsometricMath.Heading.SOUTH, "Arcade b heading must be SOUTH (4)")
	if arcade_a.sprite and arcade_a.sprite.texture:
		assert(arcade_a.sprite.texture.get_width() == 256 and arcade_a.sprite.texture.get_height() == 256, "Arcade a texture must be unclipped 256x256")
		assert(arcade_a.sprite.offset == Vector2(-3.0, -96.0), "Arcade a offset must be (-3, -96)")
	if arcade_b.sprite and arcade_b.sprite.texture:
		assert(arcade_b.sprite.texture.get_width() == 256 and arcade_b.sprite.texture.get_height() == 256, "Arcade b texture must be unclipped 256x256")
		assert(arcade_b.sprite.offset == Vector2(0.0, -96.0), "Arcade b offset must be (0, -96)")
	
	map_view.queue_free()
	print("  PASS: Cabin NPC face-to-face table alignment, Breillat bar counter occlusion, and 256x256 Arcade Machines verified")
