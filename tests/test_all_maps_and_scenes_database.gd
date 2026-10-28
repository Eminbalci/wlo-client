extends SceneTree

const SceneDatabase = preload("res://scripts/database/scene_database.gd")
const EveParser = preload("res://scripts/map/eve_parser.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test All Maps & Scenes Database Suite ---")
	print("=================================================================")
	
	_run_all_tests()
	quit(0)

func _run_all_tests() -> void:
	# -------------------------------------------------------------
	# 1. SCENEDATABASE COMPREHENSIVE VERIFICATION
	# -------------------------------------------------------------
	print("\n[PART 1] Verifying SceneDatabase (1,172 Scenes)...")
	var scene_db := SceneDatabase.new()
	var loaded_scenes := scene_db.load_from_file("res://assets/data/SceneData.dat")
	assert(loaded_scenes, "SceneDatabase must load scenes from file")
	
	var total_scenes := scene_db.get_total_scenes()
	print("  Total scenes indexed in SceneDatabase: %d" % total_scenes)
	assert(total_scenes == 1172, "SceneDatabase must index exactly 1,172 scenes (got %d)" % total_scenes)
	
	var scene_map_ids := scene_db.get_all_map_ids()
	assert(scene_map_ids.size() == 1172, "Scene map IDs list size must be 1,172")
	
	# Check specific authentic scene decodings
	var s_10001 := scene_db.get_scene(10001)
	assert(s_10001 != null, "Scene 10001 must exist")
	assert(s_10001.name == "Ship Deck", "Scene 10001 name must be 'Ship Deck' (got '%s')" % s_10001.name)
	assert(s_10001.bgm_name == "BGM0007", "Scene 10001 BGM must be 'BGM0007' (got '%s')" % s_10001.bgm_name)
	assert(s_10001.bgm_id == 7, "Scene 10001 bgm_id must be 7")
	print("  PASS: Scene 10001 decoded -> Name: '%s', BGM: '%s' (ID: %d)" % [s_10001.name, s_10001.bgm_name, s_10001.bgm_id])
	
	var s_10003 := scene_db.get_scene(10003)
	assert(s_10003 != null, "Scene 10003 must exist")
	assert(s_10003.name == "Newbie Island", "Scene 10003 name must be 'Newbie Island' (got '%s')" % s_10003.name)
	assert(s_10003.bgm_name == "BGM0024", "Scene 10003 BGM must be 'BGM0024' (got '%s')" % s_10003.bgm_name)
	assert(s_10003.bgm_id == 24, "Scene 10003 bgm_id must be 24")
	print("  PASS: Scene 10003 decoded -> Name: '%s', BGM: '%s' (ID: %d)" % [s_10003.name, s_10003.bgm_name, s_10003.bgm_id])
	
	# Check search_maps_by_name on SceneDatabase
	var search_res_deck := scene_db.search_maps_by_name("Ship Deck")
	assert(not search_res_deck.is_empty(), "Search for 'Ship Deck' must return results")
	var found_10001 := false
	for r in search_res_deck:
		if r["map_id"] == 10001:
			found_10001 = true
			break
	assert(found_10001, "Search for 'Ship Deck' must contain map 10001")
	print("  PASS: search_maps_by_name('Ship Deck') returned %d results, containing Map 10001" % search_res_deck.size())

	# -------------------------------------------------------------
	# 2. EVE_PARSER FULL MAPS VERIFICATION
	# -------------------------------------------------------------
	print("\n[PART 2] Verifying EveParser (1,119 Maps & Metadata)...")
	var eve_parser := EveParser.new()
	assert(eve_parser.initialize(), "EveParser must initialize successfully")
	
	var total_maps := eve_parser.get_total_maps()
	print("  Total maps indexed in EveParser: %d" % total_maps)
	assert(total_maps == 1119, "EveParser must contain exactly 1,119 maps (got %d)" % total_maps)
	
	var map_ids := eve_parser.get_all_map_ids()
	assert(map_ids.size() == 1119, "Map IDs list size must be 1,119")
	assert(map_ids[0] == 10000, "First map ID must be 10000")
	assert(map_ids[-1] == 60015, "Last map ID must be 60015")
	
	# Check get_map_summary for Map 10001 (Ship Deck)
	var sum_10001 := eve_parser.get_map_summary(10001)
	assert(not sum_10001.is_empty(), "Summary for 10001 must not be empty")
	assert(sum_10001["map_id"] == 10001, "Map ID mismatch")
	assert(sum_10001["scene_id"] == 10001, "Scene ID mismatch")
	assert(sum_10001["name"] == "Ship Deck", "Name mismatch on 10001 (got '%s')" % sum_10001["name"])
	assert(sum_10001["bgm_name"] == "BGM0007", "BGM mismatch on 10001")
	assert(sum_10001["bgm_id"] == 7, "BGM ID mismatch on 10001")
	assert(sum_10001["has_bg"] == true, "Map 10001 must have background graphic")
	assert(sum_10001["bg_file"] == "10001.jpg", "Map 10001 bg_file must be 10001.jpg")
	assert(sum_10001["bg_archive"] == "map.JMG", "Map 10001 bg_archive must be map.JMG")
	assert(sum_10001["warp_count"] == 2, "Map 10001 must have 2 warps")
	assert(sum_10001["npc_count"] == 11, "Map 10001 must have 11 NPCs")
	print("  PASS: get_map_summary(10001) verified: Name='%s', BGM='%s', Archive='%s', Warps=%d, NPCs=%d" % [
		sum_10001["name"], sum_10001["bgm_name"], sum_10001["bg_archive"], sum_10001["warp_count"], sum_10001["npc_count"]
	])
	
	# Check get_map_summary for Map 10003 (Newbie Island)
	var sum_10003 := eve_parser.get_map_summary(10003)
	assert(not sum_10003.is_empty(), "Summary for 10003 must not be empty")
	assert(sum_10003["name"] == "Newbie Island", "Name mismatch on 10003")
	assert(sum_10003["item_count"] == 2, "Map 10003 must have 2 ground items")
	assert(sum_10003["has_bg"] == true, "Map 10003 must have background graphic")
	print("  PASS: get_map_summary(10003) verified: Name='%s', Items=%d, HasBG=%s" % [
		sum_10003["name"], sum_10003["item_count"], sum_10003["has_bg"]
	])
	
	# Check search_maps_by_name on EveParser
	var search_island := eve_parser.search_maps_by_name("Island")
	assert(not search_island.is_empty(), "Search for 'Island' must return results")
	var found_10003 := false
	for r in search_island:
		if r["map_id"] == 10003:
			found_10003 = true
			break
	assert(found_10003, "Search for 'Island' must find Map 10003")
	print("  PASS: search_maps_by_name('Island') returned %d results, containing Map 10003" % search_island.size())
	
	# -------------------------------------------------------------
	# 3. AUTHORITATIVE JSON DATABASE VERIFICATION
	# -------------------------------------------------------------
	print("\n[PART 3] Verifying Authoritative JSON Datasets...")
	
	# 3a. all_maps.json
	var f_maps := FileAccess.open("res://assets/data/all_maps.json", FileAccess.READ)
	assert(f_maps != null, "all_maps.json must exist in assets/data/")
	var json_maps = JSON.parse_string(f_maps.get_as_text())
	assert(json_maps is Dictionary, "all_maps.json must parse as a Dictionary")
	assert(json_maps.size() == 1119, "all_maps.json must contain exactly 1,119 map records (got %d)" % json_maps.size())
	print("  PASS: all_maps.json verified: %d maps loaded" % json_maps.size())
	
	# 3b. all_scenes.json
	var f_scenes := FileAccess.open("res://assets/data/all_scenes.json", FileAccess.READ)
	assert(f_scenes != null, "all_scenes.json must exist in assets/data/")
	var json_scenes = JSON.parse_string(f_scenes.get_as_text())
	assert(json_scenes is Dictionary, "all_scenes.json must parse as a Dictionary")
	assert(json_scenes.size() == 1172, "all_scenes.json must contain exactly 1,172 scene records (got %d)" % json_scenes.size())
	print("  PASS: all_scenes.json verified: %d scenes loaded" % json_scenes.size())

	print("\n=================================================================")
	print("--- ALL MAPS & SCENES DATABASE TESTS PASSED (100%) ---")
	print("=================================================================")
