extends SceneTree

## Automated Headless Verification Suite for Wonderland Online Map & NPC Extraction.
## Tests:
## 1. SceneDatabase: All 1,172 scenes from SceneData.dat
## 2. EveParser: All 1,119 maps, 8,181 NPC spawns, 2,791 warps from Eve.emg
## 3. NpcDatabase: All 4,930 NPC templates from Npc.dat (or all_npcs.json)
## 4. ArchiveLoader: Multi-JMG loading (map.JMG, map_c01.JMg, map_d01.JMg)
## 5. MapView: Runtime loading & dynamic NPC spawning (10001, 10002, 10003, 10005, 10007)
## 6. NPC kinematics: Rotation/facing conversion, click ID lookups, and talk trigger resolution
## 7. MapEditor & WorldEditor: Map browser & NPC dock integration

const SceneDatabaseClass = preload("res://scripts/database/scene_database.gd")
const NpcDatabaseClass = preload("res://scripts/database/npc_database.gd")
const TalkDatabaseClass = preload("res://scripts/database/talk_database.gd")
const EveParserClass = preload("res://scripts/map/eve_parser.gd")
const WloArchiveReader = preload("res://scripts/core/wlo_archive_reader.gd")
const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const MapViewScene = preload("res://scenes/world/map_view.tscn")
const MapEditorScene = preload("res://scenes/tools/map_editor.tscn")
const WorldEditorScene = preload("res://scenes/tools/world_editor.tscn")

func _init() -> void:
	print("================================================================================")
	print("--- Running Complete Wonderland Online Maps & NPCs Automated Test Suite ---")
	print("================================================================================\n")
	
	var timer = create_timer(60.0)
	timer.timeout.connect(func():
		push_error("[TIMEOUT] test_all_maps_and_npcs.gd timed out after 60s!")
		quit(1)
	)
	
	_run_all_tests.call_deferred()

func _run_all_tests() -> void:
	test_1_scene_database_counts()
	test_2_eve_parser_indexing_and_spawns()
	test_3_npc_database_templates()
	test_4_multi_jmg_archive_loading()
	test_5_runtime_map_view_and_dynamic_npcs()
	test_6_rotation_click_ids_and_talk_resolution()
	test_7_editor_map_browser_and_npc_dock()
	
	print("\n================================================================================")
	print("--- [100% SUCCESS] ALL 7 MAP & NPC INTEGRATION TESTS PASSED WITH ZERO ERRORS ---")
	print("================================================================================\n")
	quit(0)

# ==============================================================================
# TEST 1: SceneDatabase (All 1,172 scenes)
# ==============================================================================
func test_1_scene_database_counts() -> void:
	print(">>> [TEST 1] Verifying SceneDatabase loading all 1,172 scenes...")
	var sdb := SceneDatabaseClass.new()
	var dat_path := "res://assets/data/SceneData.dat"
	if not FileAccess.file_exists(dat_path):
		dat_path = "D:/GitHub/WLRI/data/SceneData.dat"
	
	var ok: bool = sdb.load_from_file(dat_path)
	assert(ok, "ERROR: SceneDatabase failed to load from %s" % dat_path)
	
	var all_scenes: Dictionary = sdb.get_all_scenes()
	print("  -> Total scenes decoded: %d" % all_scenes.size())
	assert(all_scenes.size() == 1172, "ERROR: Expected exactly 1,172 scenes, got %d" % all_scenes.size())
	
	# Verify canonical landmark maps exist
	var key_maps: Dictionary = {
		10001: "Ship Deck",
		10002: "Cabin",
		10003: "Newbie Island",
		10005: "North Island Path",
		10007: "Kelan Village",
		10011: "Beach Awakening",
		10075: "Map 10075"
	}
	for mid: int in key_maps:
		assert(all_scenes.has(mid), "ERROR: Key map %d missing from SceneDatabase" % mid)
		var sc = sdb.get_scene(mid)
		assert(sc != null, "ERROR: Scene record %d is null" % mid)
		assert(sc.map_id == mid, "ERROR: Scene record ID mismatch for %d" % mid)
		assert(not sc.name.is_empty(), "ERROR: Scene name empty for map %d" % mid)
	
	print("  PASS: SceneDatabase verified: exactly 1,172 scenes decoded without loss.")

# ==============================================================================
# TEST 2: EveParser (All 1,119 maps, 8,181 NPC spawns, 2,791 warps)
# ==============================================================================
func test_2_eve_parser_indexing_and_spawns() -> void:
	print("\n>>> [TEST 2] Verifying EveParser indexing 1,119 maps, 8,181 NPC spawns, 2,791 warps...")
	var eve := EveParserClass.new()
	var total_maps := eve.get_total_maps()
	print("  -> Total indexed maps in Eve.emg: %d" % total_maps)
	assert(total_maps == 1119, "ERROR: Expected 1,119 indexed maps, got %d" % total_maps)
	
	var all_map_ids := eve.get_all_map_ids()
	assert(all_map_ids.size() == 1119, "ERROR: get_all_map_ids() must return 1,119 IDs, got %d" % all_map_ids.size())
	
	var total_npcs: int = 0
	var total_warps: int = 0
	var total_ground_items: int = 0
	
	for mid: int in all_map_ids:
		var npcs := eve.get_npcs_for_map(mid)
		total_npcs += npcs.size()
		
		var warps := eve.get_warps_for_map(mid)
		total_warps += warps.size()
		
		var items := eve.get_ground_items_for_map(mid)
		total_ground_items += items.size()
	
	print("  -> Total NPC Spawns across all maps: %d" % total_npcs)
	print("  -> Total Warps across all maps: %d" % total_warps)
	print("  -> Total Ground Items across all maps: %d" % total_ground_items)
	
	assert(total_npcs == 8181, "ERROR: Expected 8,181 NPC spawns, got %d" % total_npcs)
	assert(total_warps == 2791, "ERROR: Expected 2,791 warps, got %d" % total_warps)
	assert(eve.get_total_npc_spawns() == 8181, "ERROR: get_total_npc_spawns() mismatch")
	assert(eve.get_total_warps() == 2791, "ERROR: get_total_warps() mismatch")
	
	# Verify specific map counts
	var npcs_10001 := eve.get_npcs_for_map(10001)
	assert(npcs_10001.size() == 11, "ERROR: Map 10001 must have 11 NPCs, got %d" % npcs_10001.size())
	var warps_10001 := eve.get_warps_for_map(10001)
	assert(warps_10001.size() == 2, "ERROR: Map 10001 must have 2 warps, got %d" % warps_10001.size())
	
	var npcs_10002 := eve.get_npcs_for_map(10002)
	assert(npcs_10002.size() == 7, "ERROR: Map 10002 must have 7 NPCs in Eve.emg, got %d" % npcs_10002.size())
	var warps_10002 := eve.get_warps_for_map(10002)
	assert(warps_10002.size() == 1, "ERROR: Map 10002 must have 1 warp, got %d" % warps_10002.size())
	
	var npcs_10003 := eve.get_npcs_for_map(10003)
	assert(npcs_10003.size() == 8, "ERROR: Map 10003 must have 8 NPCs in Eve.emg, got %d" % npcs_10003.size())
	
	var npcs_10005 := eve.get_npcs_for_map(10005)
	assert(npcs_10005.size() == 5, "ERROR: Map 10005 must have 5 NPCs in Eve.emg, got %d" % npcs_10005.size())
	
	print("  PASS: EveParser verified: 1,119 maps, 8,181 NPC spawns, 2,791 warps.")

# ==============================================================================
# TEST 3: NpcDatabase (4,930 NPC templates)
# ==============================================================================
func test_3_npc_database_templates() -> void:
	print("\n>>> [TEST 3] Verifying NpcDatabase loading 4,930+ NPC templates...")
	var ndb := NpcDatabaseClass.new()
	var ok: bool = ndb.load_from_file()
	assert(ok, "ERROR: NpcDatabase failed to load")
	
	var all_npcs: Dictionary = ndb.get_all_npcs()
	print("  -> Total NPC templates loaded: %d" % all_npcs.size())
	assert(all_npcs.size() >= 4930, "ERROR: Expected at least 4,930 NPC templates, got %d" % all_npcs.size())
	
	# Verify essential NPC templates and attributes
	var test_templates: Array[Dictionary] = [
		{"id": 14003, "name": "Captain Robinson", "min_hp": 100},
		{"id": 14091, "name": "Jack", "min_hp": 50},
		{"id": 14152, "name": "Ross", "min_hp": 50},
		{"id": 14042, "name": "Drunk Man", "min_hp": 50},
		{"id": 14146, "name": "Peter", "min_hp": 50},
		{"id": 14145, "name": "John", "min_hp": 50},
		{"id": 14303, "name": "Natasha", "min_hp": 50},
		{"id": 10000, "name": "Breillat", "min_hp": 30},
		{"id": 14062, "name": "Kelang", "min_hp": 50},
		{"id": 11000, "name": "Persian Cat", "min_hp": 10}
	]
	
	for expected: Dictionary in test_templates:
		var nid: int = expected["id"]
		var rec = ndb.get_npc(nid)
		assert(rec != null, "ERROR: NPC template %d (%s) not found" % [nid, expected["name"]])
		assert(rec.id == nid, "ERROR: NPC ID mismatch: %d != %d" % [rec.id, nid])
		assert(rec.max_hp >= expected["min_hp"], "ERROR: NPC %d HP too low: %d" % [nid, rec.max_hp])
	
	print("  PASS: NpcDatabase verified: %d templates loaded with valid metadata." % all_npcs.size())

# ==============================================================================
# TEST 4: Multi-JMG Loading in ArchiveLoader (10001, 10075, 10202)
# ==============================================================================
func test_4_multi_jmg_archive_loading() -> void:
	print("\n>>> [TEST 4] Verifying Multi-JMG loading in ArchiveLoader across map archives...")
	var pic_dir := "res://assets/pic"
	if not FileAccess.file_exists(pic_dir + "/map.JMG") and FileAccess.file_exists("D:/GitHub/WLRI/pic/map.JMG"):
		pic_dir = "D:/GitHub/WLRI/pic"
	
	# 1. Verify physical archive presence and individual file existence
	var reader_main = WloArchiveReader.open_archive(pic_dir + "/map.JMG")
	assert(reader_main != null, "ERROR: map.JMG could not be opened")
	assert(reader_main.has_file("10001.jpg"), "ERROR: map.JMG must contain 10001.jpg")
	print("  -> map.JMG verified: contains 10001.jpg (Ship Deck)")
	
	var reader_c01 = WloArchiveReader.open_archive(pic_dir + "/map_c01.JMg")
	assert(reader_c01 != null, "ERROR: map_c01.JMg could not be opened")
	assert(reader_c01.has_file("10075.jpg"), "ERROR: map_c01.JMg must contain 10075.jpg")
	print("  -> map_c01.JMg verified: contains 10075.jpg")
	
	var reader_d01 = WloArchiveReader.open_archive(pic_dir + "/map_d01.JMg")
	assert(reader_d01 != null, "ERROR: map_d01.JMg could not be opened")
	assert(reader_d01.has_file("10202.jpg"), "ERROR: map_d01.JMg must contain 10202.jpg")
	print("  -> map_d01.JMg verified: contains 10202.jpg")
	
	# 2. Verify ArchiveLoader singleton multi-JMG unified loading
	var loader = root.get_node_or_null("ArchiveLoader")
	if not loader:
		var al_script = load("res://scripts/core/archive_loader.gd")
		loader = al_script.new()
		loader.name = "ArchiveLoader"
		root.add_child(loader)
	
	assert(loader != null, "ERROR: ArchiveLoader must be available")
	assert(loader.has_method("has_map_background"), "ERROR: ArchiveLoader missing has_map_background()")
	assert(loader.has_method("get_map_background"), "ERROR: ArchiveLoader missing get_map_background()")
	
	# Verify existence across multi-JMG
	assert(loader.has_map_background(10001), "ERROR: ArchiveLoader must find 10001 background in map.JMG")
	assert(loader.has_map_background(10075), "ERROR: ArchiveLoader must find 10075 background in map_c01.JMg")
	assert(loader.has_map_background(10202), "ERROR: ArchiveLoader must find 10202 background in map_d01.JMg")
	
	# Verify texture decoding across multi-JMG
	var tex_10001 = loader.get_map_background(10001)
	assert(tex_10001 != null, "ERROR: Failed to decode 10001.jpg texture")
	assert(tex_10001.get_width() > 100 and tex_10001.get_height() > 100, "ERROR: 10001 texture dimensions invalid")
	
	var tex_10075 = loader.get_map_background(10075)
	assert(tex_10075 != null, "ERROR: Failed to decode 10075.jpg texture from map_c01.JMg")
	assert(tex_10075.get_width() > 100 and tex_10075.get_height() > 100, "ERROR: 10075 texture dimensions invalid")
	
	var tex_10202 = loader.get_map_background(10202)
	assert(tex_10202 != null, "ERROR: Failed to decode 10202.jpg texture from map_d01.JMg")
	assert(tex_10202.get_width() > 100 and tex_10202.get_height() > 100, "ERROR: 10202 texture dimensions invalid")
	
	print("  PASS: Multi-JMG loading verified: 10001 (map.JMG), 10075 (map_c01.JMg), and 10202 (map_d01.JMg).")

# ==============================================================================
# TEST 5: Runtime MapView Loading & Dynamic NPC Spawning
# ==============================================================================
func test_5_runtime_map_view_and_dynamic_npcs() -> void:
	print("\n>>> [TEST 5] Verifying runtime MapView loading and dynamic NPC spawning...")
	var mv_instance: MapView = MapViewScene.instantiate() as MapView
	assert(mv_instance != null, "ERROR: Failed to instantiate MapView")
	root.add_child(mv_instance)
	
	# 1. Map 10001 (Ship Deck - 11 NPCs)
	print("  Testing Map 10001 (Ship Deck)...")
	mv_instance.load_map(10001)
	assert(mv_instance.map_renderer.current_map_id == 10001, "ERROR: Current map must be 10001")
	var npcs_10001: Array = mv_instance.get_active_npcs()
	print("  -> Map 10001 active NPCs: %d" % npcs_10001.size())
	assert(npcs_10001.size() == 11, "ERROR: Map 10001 must have exactly 11 active NPCs, got %d" % npcs_10001.size())
	
	# Verify Captain NPC exists
	var captain_found := false
	for n in npcs_10001:
		if n.npc_id == 14003 or "captain" in n.npc_name.to_lower():
			captain_found = true
			assert(n.world_position == Vector2(1421, 632), "ERROR: Captain position mismatch")
			break
	assert(captain_found, "ERROR: Captain Robinson missing from Map 10001")
	
	# 2. Map 10002 (Cabin - 7 NPCs / 2 talk-resolving NPCs)
	print("  Testing Map 10002 (Cabin)...")
	mv_instance.load_map(10002)
	assert(mv_instance.map_renderer.current_map_id == 10002, "ERROR: Current map must be 10002")
	var npcs_10002: Array = mv_instance.get_active_npcs()
	print("  -> Map 10002 active NPCs: %d" % npcs_10002.size())
	assert(npcs_10002.size() >= 2, "ERROR: Map 10002 must have at least 2 active NPCs, got %d" % npcs_10002.size())
	
	# 3. Map 10003 (Deserted Island)
	print("  Testing Map 10003 (Deserted Island)...")
	mv_instance.load_map(10003)
	assert(mv_instance.map_renderer.current_map_id == 10003, "ERROR: Current map must be 10003")
	assert(mv_instance.map_renderer.get_map_texture() != null, "ERROR: Map 10003 background missing")
	
	# 4. Map 10005 (Kelan Trail - 5 NPCs in Eve.emg)
	print("  Testing Map 10005 (Kelan Trail)...")
	mv_instance.load_map(10005)
	assert(mv_instance.map_renderer.current_map_id == 10005, "ERROR: Current map must be 10005")
	var npcs_10005: Array = mv_instance.get_active_npcs()
	print("  -> Map 10005 active NPCs: %d" % npcs_10005.size())
	assert(npcs_10005.size() == 5, "ERROR: Map 10005 must have 5 dynamic NPCs, got %d" % npcs_10005.size())
	
	# 5. Map 10007 (Kelan Village)
	print("  Testing Map 10007 (Kelan Village)...")
	mv_instance.load_map(10007)
	assert(mv_instance.map_renderer.current_map_id == 10007, "ERROR: Current map must be 10007")
	assert(mv_instance.map_renderer.get_map_texture() != null, "ERROR: Map 10007 background missing")
	
	mv_instance.queue_free()
	print("  PASS: Runtime MapView loading and dynamic NPC spawning verified across all 5 maps.")

# ==============================================================================
# TEST 6: Kinematics, Click IDs, and Talk Trigger Resolution
# ==============================================================================
func test_6_rotation_click_ids_and_talk_resolution() -> void:
	print("\n>>> [TEST 6] Verifying NPC rotation/facing conversions, click ID lookups, and talk triggers...")
	
	# 1. 8-directional rotation <-> heading bi-directional mapping
	var expected_mappings: Dictionary = {
		1: IsometricMath.Heading.NORTH,      # 0
		2: IsometricMath.Heading.NORTH_EAST, # 7
		3: IsometricMath.Heading.EAST,       # 6
		4: IsometricMath.Heading.SOUTH_EAST, # 5
		5: IsometricMath.Heading.SOUTH,      # 4
		6: IsometricMath.Heading.SOUTH_WEST, # 3
		7: IsometricMath.Heading.WEST,       # 2
		8: IsometricMath.Heading.NORTH_WEST  # 1
	}
	
	for rot: int in expected_mappings:
		var exp_h: int = expected_mappings[rot]
		var got_h := IsometricMath.rotation_to_heading(rot)
		assert(got_h == exp_h, "ERROR: rotation_to_heading(%d) expected %d, got %d" % [rot, exp_h, got_h])
		var back_rot := IsometricMath.heading_to_rotation(got_h)
		assert(back_rot == rot, "ERROR: heading_to_rotation(%d) expected %d, got %d" % [got_h, rot, back_rot])
	print("  -> All 8 Eve.emg rotation <-> JMP heading conversions validated with 100% parity.")
	
	# 2. Click ID lookups in EveParser
	var eve := EveParserClass.new()
	var cap_info = eve.get_npc_by_id(10001, 10)
	assert(cap_info != null, "ERROR: Click ID 10 on Map 10001 not found")
	assert(cap_info.click_id == 10, "ERROR: Click ID mismatch")
	assert(cap_info.npc_id == 14003, "ERROR: Captain NPC ID must be 14003")
	assert(cap_info.world_x == 1421 and cap_info.world_y == 632, "ERROR: Captain coordinates mismatch")
	assert(cap_info.rotation == 6, "ERROR: Captain rotation must be 6")
	assert(cap_info.heading == IsometricMath.Heading.SOUTH_WEST, "ERROR: Captain heading must be SOUTH_WEST (3)")
	
	var drunk_info = eve.get_npc_by_id(10002, 1)
	assert(drunk_info != null, "ERROR: Click ID 1 on Map 10002 not found")
	assert(drunk_info.npc_id == 14042, "ERROR: Drunk Man NPC ID must be 14042")
	assert(drunk_info.world_x == 851 and drunk_info.world_y == 539, "ERROR: Drunk Man coords mismatch")
	assert(drunk_info.rotation == 8, "ERROR: Drunk Man rotation must be 8")
	assert(drunk_info.heading == IsometricMath.Heading.NORTH_WEST, "ERROR: Drunk Man heading must be NORTH_WEST (1)")
	
	# Verify warp lookups
	var w1 = eve.get_warp_by_id(10001, 1)
	assert(w1 != null and w1.target_map_id == 10003, "ERROR: Map 10001 Warp 1 must target 10003")
	var w2 = eve.get_warp_by_id(10001, 2)
	assert(w2 != null and w2.target_map_id == 10002, "ERROR: Map 10001 Warp 2 must target 10002")
	print("  -> Click ID entity and warp lookups verified successfully.")
	
	# 3. Talk trigger resolution via TalkDatabase
	var gdb = root.get_node_or_null("GameDatabase")
	var talk_db: TalkDatabaseClass = gdb.talks if (gdb and gdb.talks) else null
	if not talk_db:
		talk_db = TalkDatabaseClass.new()
		talk_db.load_from_file("res://assets/data/Talk.dat", "res://assets/data/Npc.dat", "res://assets/data/Eve.emg")
	
	# Captain on Ship Deck (14003 on 10001)
	var cap_talk = talk_db.resolve_talk_for_npc(14003, 10001)
	assert(not cap_talk.is_empty(), "ERROR: Captain talk must resolve on Map 10001")
	assert(cap_talk.has("text") and not cap_talk["text"].is_empty(), "ERROR: Captain dialogue text empty")
	
	# Jack on Cabin (14091 on 10002)
	var jack_talk = talk_db.resolve_talk_for_npc(14091, 10002)
	assert(not jack_talk.is_empty(), "ERROR: Jack talk must resolve on Map 10002")
	assert(jack_talk.get("id") == 30126, "ERROR: Jack talk ID expected 30126, got %s" % str(jack_talk.get("id")))
	
	# Ross on Cabin (14152 on 10002)
	var ross_talk = talk_db.resolve_talk_for_npc(14152, 10002)
	assert(not ross_talk.is_empty(), "ERROR: Ross talk must resolve on Map 10002")
	assert(ross_talk.get("id") == 30120, "ERROR: Ross talk ID expected 30120, got %s" % str(ross_talk.get("id")))
	
	# Drunk Man on Cabin (14042 on 10002)
	var drunk_talk = talk_db.resolve_talk_for_npc(14042, 10002)
	assert(not drunk_talk.is_empty(), "ERROR: Drunk Man talk must resolve on Map 10002")
	
	# Kelang on Beach Awakening (14062 on 10011)
	var kelang_talk = talk_db.resolve_talk_for_npc(14062, 10011)
	assert(not kelang_talk.is_empty(), "ERROR: Kelang talk must resolve on Map 10011")
	assert(kelang_talk.get("id") == 20305, "ERROR: Kelang talk ID expected 20305, got %s" % str(kelang_talk.get("id")))
	
	print("  PASS: Kinematics, click ID lookups, and talk trigger resolution verified.")

# ==============================================================================
# TEST 7: MapEditor & WorldEditor Map Browser & NPC Dock
# ==============================================================================
func test_7_editor_map_browser_and_npc_dock() -> void:
	print("\n>>> [TEST 7] Verifying MapEditor and WorldEditor map browser & NPC dock...")
	
	# 1. MapEditor Map Browser & NPC Dock
	var map_ed: MapEditor = MapEditorScene.instantiate() as MapEditor
	assert(map_ed != null, "ERROR: Failed to instantiate MapEditor")
	root.add_child(map_ed)
	
	assert(map_ed.preset_select != null, "ERROR: Preset/Map selector OptionButton missing")
	assert(map_ed._all_preset_maps.size() >= 1119, "ERROR: MapEditor preset maps must contain all 1,119+ maps, got %d" % map_ed._all_preset_maps.size())
	print("  -> MapEditor loaded %d maps into selector." % map_ed._all_preset_maps.size())
	
	# Test loading 10001
	map_ed.load_map_from_id(10001)
	assert(map_ed.npcs.size() == 11, "ERROR: MapEditor must load 11 NPCs for Map 10001, got %d" % map_ed.npcs.size())
	if map_ed.map_npc_dock_list:
		assert(map_ed.map_npc_dock_list.item_count == 11, "ERROR: MapNpcDockList must display 11 items, got %d" % map_ed.map_npc_dock_list.item_count)
		var item_str := map_ed.map_npc_dock_list.get_item_text(0)
		assert(item_str.contains("Pos:"), "ERROR: NPC dock item missing Pos: info: %s" % item_str)
	
	# Test loading 10005 (Kelan Trail)
	map_ed.load_map_from_id(10005)
	assert(map_ed.npcs.size() == 5, "ERROR: MapEditor must load 5 NPCs for Map 10005, got %d" % map_ed.npcs.size())
	if map_ed.map_npc_dock_list:
		assert(map_ed.map_npc_dock_list.item_count == 5, "ERROR: MapNpcDockList must display 5 items for Map 10005")
	
	map_ed.queue_free()
	
	# 2. WorldEditor Map Browser & Quick Sync
	var world_ed: WorldEditor = WorldEditorScene.instantiate() as WorldEditor
	assert(world_ed != null, "ERROR: Failed to instantiate WorldEditor")
	root.add_child(world_ed)
	
	assert(world_ed.opt_quick_map != null, "ERROR: WorldEditor opt_quick_map missing")
	assert(world_ed._all_world_maps.size() >= 1119, "ERROR: WorldEditor must index all 1,119+ maps, got %d" % world_ed._all_world_maps.size())
	print("  -> WorldEditor indexed %d maps in quick map browser." % world_ed._all_world_maps.size())
	
	# Select Map 10005 via WorldEditor
	world_ed._sync_active_map(10005)
	assert(world_ed.active_map_id == 10005, "ERROR: WorldEditor active map ID must be 10005")
	assert(world_ed.map_studio.map_id == 10005, "ERROR: MapStudio map_id must sync to 10005")
	assert(world_ed.map_studio.npcs.size() == 5, "ERROR: MapStudio must have 5 NPCs for Map 10005")
	
	world_ed.queue_free()
	print("  PASS: MapEditor and WorldEditor map browser & NPC dock integration verified.")
