extends SceneTree

## Automated Unit & Integration Tests for MapEditor Tool.

const MapEditorScene = preload("res://scenes/tools/map_editor.tscn")
const MapData = preload("res://scripts/map/map_data.gd")
const IsometricMath = preload("res://scripts/map/isometric_math.gd")

func _init() -> void:
	print("\n=== RUNNING MAP EDITOR COMPREHENSIVE TEST SUITE ===")
	var passed: int = 0
	var failed: int = 0
	
	var editor = MapEditorScene.instantiate()
	root.add_child(editor)
	
	# Wait one frame for _ready
	await process_frame
	
	# Test 1: Instantiation & Defaults
	if editor != null and editor.map_id == 10001 and editor.cols > 0 and editor.rows > 0:
		print("[PASS] Test 1: Instantiation & initial map setup (cols: %d, rows: %d)" % [editor.cols, editor.rows])
		passed += 1
	else:
		print("[FAIL] Test 1: Failed to instantiate or load initial map")
		failed += 1

	# Test 2: Coordinate math
	var test_world: Vector2 = Vector2(40.0, 60.0)
	var test_grid: Vector2i = editor.world_to_grid(test_world)
	var expected_grid: Vector2i = Vector2i(2, 3)
	if test_grid == expected_grid:
		print("[PASS] Test 2: world_to_grid math (40, 60) -> (2, 3)")
		passed += 1
	else:
		print("[FAIL] Test 2: world_to_grid returned %s, expected %s" % [test_grid, expected_grid])
		failed += 1
	
	var back_world: Vector2 = editor.grid_to_world(test_grid)
	if back_world == test_world:
		print("[PASS] Test 2b: grid_to_world math (2, 3) -> (40, 60)")
		passed += 1
	else:
		print("[FAIL] Test 2b: grid_to_world returned %s, expected %s" % [back_world, test_world])
		failed += 1

	# Test 3: Screen to World & World to Screen
	editor.pan_offset = Vector2(100.0, 50.0)
	editor.zoom_level = 2.0
	var scr: Vector2 = editor.world_to_screen(test_world)
	var expected_scr: Vector2 = test_world * 2.0 + Vector2(100.0, 50.0)
	var back_w: Vector2 = editor.screen_to_world(scr)
	if scr == expected_scr and back_w.is_equal_approx(test_world):
		print("[PASS] Test 3: Screen/World bi-directional transformation")
		passed += 1
	else:
		print("[FAIL] Test 3: Transformation mismatch (scr: %s, expected: %s)" % [scr, expected_scr])
		failed += 1

	# Test 4: Collision editing: set/get, brush, flood fill, clear, invert
	editor.init_empty_map(200, 200, 99001, "Test Grid")
	if editor.cols == 10 and editor.rows == 10 and editor.collision_grid.size() == 100:
		print("[PASS] Test 4a: init_empty_map created 10x10 tile grid (100 tiles)")
		passed += 1
	else:
		print("[FAIL] Test 4a: Incorrect dimensions cols=%d rows=%d size=%d" % [editor.cols, editor.rows, editor.collision_grid.size()])
		failed += 1

	editor.set_collision_at(5, 5, MapData.TileCollisionFlags.SOLID_WALL)
	if editor.get_collision_at(5, 5) == MapData.TileCollisionFlags.SOLID_WALL:
		print("[PASS] Test 4b: set_collision_at / get_collision_at")
		passed += 1
	else:
		print("[FAIL] Test 4b: Failed to set or get collision")
		failed += 1

	# Test brush 3x3
	editor.paint_brush(5, 5, MapData.TileCollisionFlags.WATER, 3)
	var brush_ok: bool = true
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if editor.get_collision_at(5 + dx, 5 + dy) != MapData.TileCollisionFlags.WATER:
				brush_ok = false
	if brush_ok:
		print("[PASS] Test 4c: paint_brush 3x3 centered at (5, 5)")
		passed += 1
	else:
		print("[FAIL] Test 4c: 3x3 brush failed")
		failed += 1

	# Test flood fill
	editor.clear_collision()
	# Surround a region:
	editor.set_collision_at(1, 1, MapData.TileCollisionFlags.SOLID_WALL)
	editor.set_collision_at(2, 1, MapData.TileCollisionFlags.SOLID_WALL)
	editor.set_collision_at(3, 1, MapData.TileCollisionFlags.SOLID_WALL)
	editor.set_collision_at(1, 2, MapData.TileCollisionFlags.SOLID_WALL)
	editor.set_collision_at(3, 2, MapData.TileCollisionFlags.SOLID_WALL)
	editor.set_collision_at(1, 3, MapData.TileCollisionFlags.SOLID_WALL)
	editor.set_collision_at(2, 3, MapData.TileCollisionFlags.SOLID_WALL)
	editor.set_collision_at(3, 3, MapData.TileCollisionFlags.SOLID_WALL)
	# Center (2, 2) is walkable. Flood fill (2, 2) with DEEP_OCEAN
	editor.flood_fill(2, 2, MapData.TileCollisionFlags.DEEP_OCEAN)
	if editor.get_collision_at(2, 2) == MapData.TileCollisionFlags.DEEP_OCEAN and editor.get_collision_at(0, 0) == MapData.TileCollisionFlags.WALKABLE:
		print("[PASS] Test 4d: flood_fill filled enclosed tile without leaking")
		passed += 1
	else:
		print("[FAIL] Test 4d: flood_fill failed or leaked")
		failed += 1

	# Test 5: Entity additions (Portals, Items, NPCs)
	var p = editor.add_portal(Vector2(200, 300), 10002, Vector2(500, 500), "Cabin Gate", 64.0)
	if editor.portals.size() == 1 and editor.portals[0].portal_name == "Cabin Gate":
		print("[PASS] Test 5a: add_portal")
		passed += 1
	else:
		print("[FAIL] Test 5a: Failed to add portal")
		failed += 1

	var it = editor.add_ground_item(Vector2(250, 350), 46113, "Beach Shell", 2, 180.0)
	if editor.ground_items.size() == 1 and editor.ground_items[0].item_id == 46113:
		print("[PASS] Test 5b: add_ground_item")
		passed += 1
	else:
		print("[FAIL] Test 5b: Failed to add ground item")
		failed += 1

	var npc = editor.add_npc(Vector2(400, 450), 14003, "Captain Robinson", "1038.jmp", "001.jma", IsometricMath.Heading.SOUTH, "Welcome aboard!", ["Ahoy!"])
	if editor.npcs.size() == 1 and editor.npcs[0].npc_name == "Captain Robinson":
		print("[PASS] Test 5c: add_npc")
		passed += 1
	else:
		print("[FAIL] Test 5c: Failed to add NPC")
		failed += 1

	# Test 6: Export & Verify Binary .MapData
	var test_bin_path: String = "res://test_output_map.MapData"
	var bin_ok: bool = editor.export_mapdata_binary(test_bin_path)
	if bin_ok and FileAccess.file_exists(test_bin_path):
		var loaded_map = MapData.load_from_mapdata_file(test_bin_path, 99001)
		if loaded_map != null and loaded_map.blocks.size() == 1:
			var b = loaded_map.blocks[0]
			if b.block_dim_x == editor.cols and b.block_dim_y == editor.rows:
				var flag_match: bool = true
				for r in range(editor.rows):
					for c in range(editor.cols):
						if loaded_map.get_collision_byte(c, r) != editor.get_collision_at(c, r):
							flag_match = false
				if flag_match:
					print("[PASS] Test 6: export_mapdata_binary & verification with MapData.load_from_mapdata_file (Exact Byte Match)")
					passed += 1
				else:
					print("[FAIL] Test 6: Collision matrix mismatch after binary export")
					failed += 1
			else:
				print("[FAIL] Test 6: Block dimensions mismatch: %dx%d vs %dx%d" % [b.block_dim_x, b.block_dim_y, editor.cols, editor.rows])
				failed += 1
		else:
			print("[FAIL] Test 6: Failed to load exported MapData with MapData class")
			failed += 1
		# Clean up temporary test file
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_bin_path))
	else:
		print("[FAIL] Test 6: export_mapdata_binary returned false")
		failed += 1

	# Test 7: Export & Import JSON
	var test_json_path: String = "res://test_output_map.json"
	var json_ok: bool = editor.export_map_json(test_json_path)
	if json_ok and FileAccess.file_exists(test_json_path):
		var test_importer = MapEditorScene.instantiate()
		root.add_child(test_importer)
		await process_frame
		var import_ok: bool = test_importer.import_map_json(test_json_path)
		if import_ok and test_importer.portals.size() == 1 and test_importer.ground_items.size() == 1 and test_importer.npcs.size() == 1:
			if test_importer.portals[0].portal_name == "Cabin Gate" and test_importer.npcs[0].npc_name == "Captain Robinson":
				print("[PASS] Test 7: export_map_json & import_map_json roundtrip verified")
				passed += 1
			else:
				print("[FAIL] Test 7: Imported entity attributes mismatch")
				failed += 1
		else:
			print("[FAIL] Test 7: import_map_json failed or counts mismatch")
			failed += 1
		test_importer.queue_free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_json_path))
	else:
		print("[FAIL] Test 7: export_map_json returned false")
		failed += 1

	# Test 8: Export .tscn Scene & ResourceLoader verification
	var test_scene_path: String = "res://scenes/maps/test_generated_map.tscn"
	var scene_ok: bool = editor.export_map_scene(test_scene_path)
	if scene_ok and FileAccess.file_exists(test_scene_path):
		var loaded_scene = ResourceLoader.load(test_scene_path)
		if loaded_scene != null and loaded_scene is PackedScene:
			var instance = loaded_scene.instantiate()
			if instance != null and instance.has_node("MapRenderer") and instance.has_node("Entities"):
				print("[PASS] Test 8: export_map_scene generated valid, loadable PackedScene with MapRenderer and Entities")
				passed += 1
			else:
				print("[FAIL] Test 8: Scene instantiated but lacked expected nodes")
				failed += 1
			if instance:
				instance.queue_free()
		else:
			print("[FAIL] Test 8: ResourceLoader failed to load exported .tscn")
			failed += 1
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_scene_path))
	else:
		print("[FAIL] Test 8: export_map_scene returned false")
		failed += 1

	# Clean up
	editor.queue_free()

	print("\n=== MAP EDITOR TESTS COMPLETED ===")
	print("PASSED: %d" % passed)
	print("FAILED: %d" % failed)
	quit(0 if failed == 0 else 1)
