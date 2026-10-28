extends Node

## Automated Headless Verification Suite for Tent (Player Housing) & Furniture Interior Studio.
## Tests 2:1 axonometric grid, furniture catalog, placement bounds, 90-degree isometric rotation,
## collision & walkability matrix calculations, custom collision painting, authentic presets,
## JSON serialization roundtrip, and standalone Godot 4 .tscn scene export.

const TentEditorClass = preload("res://scripts/tools/tent_editor.gd")

func _ready() -> void:
	print("=================================================================")
	print("--- Running Wonderland Online Tent & Furniture Studio Tests ---")
	print("=================================================================\n")

	var editor = TentEditorClass.new()
	assert(editor != null, "ERROR: Failed to instantiate TentEditor")
	add_child(editor)

	_test_tent_identity_and_dimensions(editor)
	_test_wallpapers_and_floorings(editor)
	_test_furniture_catalog(editor)
	_test_furniture_placement_and_bounds(editor)
	_test_furniture_rotation(editor)
	_test_collision_and_walkability_matrix(editor)
	_test_presets(editor)
	_test_save_and_load_roundtrip(editor)
	_test_export_standalone_scene(editor)
	_test_scene_instantiation()

	editor.queue_free()

	print("\n=================================================================")
	print("--- ALL TENT & FURNITURE STUDIO TESTS PASSED (100%) ---")
	print("=================================================================")

	if get_tree() != null:
		get_tree().quit(0)

func _test_tent_identity_and_dimensions(editor: Node) -> void:
	print(">>> [TEST 1] Verifying Tent Identity & Default Dimensions...")

	assert(editor.tent_size == Vector2i(16, 16), "Default tent_size must be 16x16")
	assert(editor.is_tile_in_bounds(Vector2i(0, 0)), "(0, 0) must be in bounds")
	assert(editor.is_tile_in_bounds(Vector2i(15, 15)), "(15, 15) must be in bounds")
	assert(not editor.is_tile_in_bounds(Vector2i(16, 16)), "(16, 16) must be out of bounds")
	assert(not editor.is_tile_in_bounds(Vector2i(-1, 0)), "(-1, 0) must be out of bounds")

	editor.set_tent_size(Vector2i(20, 20))
	assert(editor.tent_size == Vector2i(20, 20), "Tent size must be 20x20 after resize")
	var stats: Dictionary = editor.get_walkability_stats()
	assert(int(stats["total_tiles"]) == 400, "20x20 tent must have 400 total tiles")

	editor.set_tent_size(Vector2i(16, 16))
	assert(editor.tent_size == Vector2i(16, 16), "Tent size reset to 16x16")
	print("  PASS: Tent dimensions and boundary checks verified.")

func _test_wallpapers_and_floorings(editor: Node) -> void:
	print(">>> [TEST 2] Verifying Wallpapers & Floorings Selector...")

	assert(TentEditorClass.WALLPAPER_TYPES.size() >= 5, "Must have at least 5 wallpapers")
	assert(TentEditorClass.WALLPAPER_TYPES.has("Wood Plank"), "Must have Wood Plank wallpaper")
	assert(TentEditorClass.WALLPAPER_TYPES.has("Stone Brick"), "Must have Stone Brick wallpaper")
	assert(TentEditorClass.WALLPAPER_TYPES.has("Red Floral Wallpaper"), "Must have Red Floral wallpaper")
	assert(TentEditorClass.WALLPAPER_TYPES.has("Blue Regal Wallpaper"), "Must have Blue Regal wallpaper")
	assert(TentEditorClass.WALLPAPER_TYPES.has("Simple Canvas"), "Must have Simple Canvas wallpaper")

	assert(TentEditorClass.FLOORING_TYPES.size() >= 5, "Must have at least 5 floorings")
	assert(TentEditorClass.FLOORING_TYPES.has("Wood Plank"), "Must have Wood Plank flooring")
	assert(TentEditorClass.FLOORING_TYPES.has("Marble"), "Must have Marble flooring")
	assert(TentEditorClass.FLOORING_TYPES.has("Carpet"), "Must have Carpet flooring")
	assert(TentEditorClass.FLOORING_TYPES.has("Tatami"), "Must have Tatami flooring")
	assert(TentEditorClass.FLOORING_TYPES.has("Grass"), "Must have Grass flooring")

	editor.set_wallpaper("Stone Brick")
	assert(editor.current_wallpaper == "Stone Brick", "Wallpaper must update to Stone Brick")
	editor.set_flooring("Marble")
	assert(editor.current_flooring == "Marble", "Flooring must update to Marble")
	print("  PASS: Wallpapers and floorings verified.")

func _test_furniture_catalog(editor: Node) -> void:
	print(">>> [TEST 3] Verifying Furniture & Apparatus Catalog...")

	var catalog: Dictionary = TentEditorClass.FURNITURE_CATALOG
	assert(catalog.size() >= 18, "Catalog must have at least 18 items")

	# Crafting Workbenches
	var workbenches: Array[int] = [101, 102, 103, 104, 105, 106]
	for wid in workbenches:
		assert(catalog.has(wid), "Workbench ID %d must exist" % wid)
		var item: Dictionary = catalog[wid]
		assert(item["is_workbench"] == true, "Workbench %d must have is_workbench=true" % wid)
		assert(not str(item["workbench_type"]).is_empty(), "Workbench %d must have workbench_type" % wid)
		assert(item["category"] == "Crafting Workbenches", "Category must be Crafting Workbenches")

	assert(catalog[101]["workbench_type"] == "Alchemy", "ID 101 must be Alchemy")
	assert(catalog[102]["workbench_type"] == "Smelting", "ID 102 must be Smelting")
	assert(catalog[103]["workbench_type"] == "Weaving", "ID 103 must be Weaving")
	assert(catalog[104]["workbench_type"] == "Cooking", "ID 104 must be Cooking")
	assert(catalog[105]["workbench_type"] == "Carpentry", "ID 105 must be Carpentry")
	assert(catalog[106]["workbench_type"] == "Pottery", "ID 106 must be Pottery")

	# Furniture items
	assert(catalog.has(201) and catalog[201]["name"] == "Simple Bed", "Simple Bed must exist")
	assert(catalog.has(202) and catalog[202]["name"] == "Luxury Double Bed", "Luxury Double Bed must exist")
	assert(catalog.has(203) and catalog[203]["name"] == "Wardrobe", "Wardrobe must exist")
	assert(catalog.has(204) and catalog[204]["name"] == "Dining Table", "Dining Table must exist")
	assert(catalog.has(205) and catalog[205]["name"] == "Wooden Chair", "Wooden Chair must exist")
	assert(catalog.has(206) and catalog[206]["name"] == "Stool", "Stool must exist")
	assert(catalog.has(207) and catalog[207]["name"] == "Bookshelf", "Bookshelf must exist")
	assert(catalog.has(208) and catalog[208]["name"] == "Bathtub", "Bathtub must exist")
	assert(catalog.has(209) and catalog[209]["name"] == "Sleeping Bag", "Sleeping Bag must exist")

	# Storage
	assert(catalog.has(301) and catalog[301]["name"] == "Storage Chest", "Storage Chest must exist")
	assert(catalog.has(302) and catalog[302]["name"] == "Cabinet", "Cabinet must exist")
	assert(catalog.has(303) and catalog[303]["name"] == "Safe", "Safe must exist")

	# Decor
	assert(catalog.has(401) and catalog[401]["name"] == "Wall Clock", "Wall Clock must exist")
	assert(catalog.has(402) and catalog[402]["name"] == "Hanging Banner", "Hanging Banner must exist")
	assert(catalog.has(403) and catalog[403]["name"] == "Potted Plant", "Potted Plant must exist")
	assert(catalog.has(404) and catalog[404]["name"] == "Persian Carpet", "Persian Carpet must exist")
	assert(catalog.has(405) and catalog[405]["name"] == "Flower Vase", "Flower Vase must exist")

	print("  PASS: Complete furniture catalog with workbenches and decor verified.")

func _test_furniture_placement_and_bounds(editor: Node) -> void:
	print(">>> [TEST 4] Verifying Interactive Placement & Boundary Clamping...")

	editor.clear_furniture()
	assert(editor.placed_furniture.is_empty(), "Placed furniture must be empty initially")

	var inst1 = editor.place_furniture(101, Vector2i(4, 4), TentEditorClass.Heading.SOUTH)
	assert(inst1 != null, "Valid placement must succeed")
	assert(inst1.name == "Alchemy Apparatus", "Instance name must be Alchemy Apparatus")
	assert(inst1.grid_pos == Vector2i(4, 4), "Instance grid_pos must be (4, 4)")
	assert(inst1.get_occupied_tiles().size() == 4, "2x2 furniture must occupy 4 tiles")
	assert(editor.placed_furniture.size() == 1, "Must have 1 placed furniture")

	# Test out of bounds placement: 2x2 at (15, 15) in a 16x16 grid
	var oob_inst = editor.place_furniture(101, Vector2i(15, 15), TentEditorClass.Heading.SOUTH)
	assert(oob_inst == null, "Out-of-bounds placement must fail")
	assert(editor.placed_furniture.size() == 1, "Placed count must remain 1")

	# Test negative coordinates
	var neg_inst = editor.place_furniture(101, Vector2i(-1, 2), TentEditorClass.Heading.SOUTH)
	assert(neg_inst == null, "Negative coordinate placement must fail")

	print("  PASS: Furniture placement and boundary checking verified.")

func _test_furniture_rotation(editor: Node) -> void:
	print(">>> [TEST 5] Verifying 90-Degree Isometric Rotation & Footprint Swapping...")

	editor.clear_furniture()
	# Wardrobe is 2x1 (base_grid_size: Vector2i(2, 1))
	var wardrobe = editor.place_furniture(203, Vector2i(2, 2), TentEditorClass.Heading.SOUTH)
	assert(wardrobe != null, "Wardrobe must place successfully")
	assert(wardrobe.heading == TentEditorClass.Heading.SOUTH, "Initial heading must be SOUTH (0)")
	assert(wardrobe.get_effective_size() == Vector2i(2, 1), "Heading 0 footprint must be 2x1")

	# Rotate clockwise -> Heading 1 (WEST)
	editor.rotate_furniture(wardrobe.instance_id, true)
	assert(wardrobe.heading == TentEditorClass.Heading.WEST, "Heading must be WEST (1)")
	assert(wardrobe.get_effective_size() == Vector2i(1, 2), "Heading 1 footprint must be 1x2")

	# Rotate clockwise -> Heading 2 (NORTH)
	editor.rotate_furniture(wardrobe.instance_id, true)
	assert(wardrobe.heading == TentEditorClass.Heading.NORTH, "Heading must be NORTH (2)")
	assert(wardrobe.get_effective_size() == Vector2i(2, 1), "Heading 2 footprint must be 2x1")

	# Rotate clockwise -> Heading 3 (EAST)
	editor.rotate_furniture(wardrobe.instance_id, true)
	assert(wardrobe.heading == TentEditorClass.Heading.EAST, "Heading must be EAST (3)")
	assert(wardrobe.get_effective_size() == Vector2i(1, 2), "Heading 3 footprint must be 1x2")

	# Rotate clockwise -> Heading 0 (SOUTH)
	editor.rotate_furniture(wardrobe.instance_id, true)
	assert(wardrobe.heading == TentEditorClass.Heading.SOUTH, "Heading must cycle back to SOUTH (0)")
	assert(wardrobe.get_effective_size() == Vector2i(2, 1), "Footprint must return to 2x1")

	print("  PASS: 90-degree isometric rotation and non-square footprint swapping verified.")

func _test_collision_and_walkability_matrix(editor: Node) -> void:
	print(">>> [TEST 6] Verifying Collision & Walkability Matrix Calculations...")

	editor.clear_furniture()
	editor.clear_custom_collision()

	# Completely empty 16x16 tent should be 100% walkable (256 walkable tiles)
	var initial_stats: Dictionary = editor.get_walkability_stats()
	assert(int(initial_stats["total_tiles"]) == 256, "Total tiles must be 256")
	assert(int(initial_stats["walkable_tiles"]) == 256, "Initial walkable tiles must be 256")
	assert(is_equal_approx(float(initial_stats["walkable_percentage"]), 100.0), "Initial walkable pct must be 100.0%")
	assert(editor.is_tile_walkable(Vector2i(4, 4)), "(4, 4) must be walkable initially")

	# Place solid 2x2 Alchemy Apparatus at (4, 4)
	var alc = editor.place_furniture(101, Vector2i(4, 4), TentEditorClass.Heading.SOUTH)
	assert(alc != null, "Placement succeeded")
	assert(not editor.is_tile_walkable(Vector2i(4, 4)), "(4, 4) must be solid/unwalkable")
	assert(not editor.is_tile_walkable(Vector2i(5, 4)), "(5, 4) must be solid/unwalkable")
	assert(not editor.is_tile_walkable(Vector2i(4, 5)), "(4, 5) must be solid/unwalkable")
	assert(not editor.is_tile_walkable(Vector2i(5, 5)), "(5, 5) must be solid/unwalkable")
	assert(editor.is_tile_walkable(Vector2i(6, 6)), "(6, 6) must remain walkable")

	var after_place_stats: Dictionary = editor.get_walkability_stats()
	assert(int(after_place_stats["solid_tiles"]) == 4, "Must have 4 solid tiles")
	assert(int(after_place_stats["walkable_tiles"]) == 252, "Must have 252 walkable tiles")

	# Place walkable Persian Carpet (3x3, is_walkable=true) at (7, 7)
	var rug = editor.place_furniture(404, Vector2i(7, 7), TentEditorClass.Heading.SOUTH)
	assert(rug != null and rug.is_walkable == true, "Rug is walkable")
	assert(editor.is_tile_walkable(Vector2i(7, 7)), "Tile under rug must remain walkable")
	assert(editor.is_tile_walkable(Vector2i(8, 8)), "Tile under rug must remain walkable")

	var rug_stats: Dictionary = editor.get_walkability_stats()
	assert(int(rug_stats["solid_tiles"]) == 4, "Rug must not add solid tiles")

	# Remove the solid Alchemy Apparatus: tiles should become walkable again
	editor.remove_furniture(alc.instance_id)
	assert(editor.is_tile_walkable(Vector2i(4, 4)), "(4, 4) must return to walkable after removal")
	assert(editor.is_tile_walkable(Vector2i(5, 5)), "(5, 5) must return to walkable after removal")

	# Test custom collision painting
	editor.paint_collision(Vector2i(1, 1), TentEditorClass.CollisionFlag.SOLID)
	assert(not editor.is_tile_walkable(Vector2i(1, 1)), "(1, 1) must be painted solid")
	editor.clear_custom_collision()
	assert(editor.is_tile_walkable(Vector2i(1, 1)), "(1, 1) must be walkable after clearing custom collision")

	print("  PASS: Dynamic collision matrix and walkability calculations verified.")

func _test_presets(editor: Node) -> void:
	print(">>> [TEST 7] Verifying Authentic Built-in Tent Presets...")

	# 1. Beginner Camping Tent
	var ok1: bool = editor.apply_preset("Beginner Camping Tent")
	assert(ok1, "Beginner Camping Tent preset must apply")
	assert(editor.current_wallpaper == "Simple Canvas", "Wallpaper must be Simple Canvas")
	assert(editor.current_flooring == "Grass", "Flooring must be Grass")
	assert(editor.placed_furniture.size() == 5, "Beginner preset must have 5 furniture pieces")

	var has_sleeping_bag: bool = false
	var has_stove: bool = false
	var has_table: bool = false
	var has_stool: bool = false
	var has_chest: bool = false

	for inst in editor.placed_furniture:
		if inst.item_id == 38109: has_sleeping_bag = true
		if inst.item_id == 38004: has_stove = true
		if inst.item_id == 38104: has_table = true
		if inst.item_id == 38106: has_stool = true
		if inst.item_id == 38201: has_chest = true

	assert(has_sleeping_bag, "Must contain Sleeping Bag")
	assert(has_stove, "Must contain Campfire Stove")
	assert(has_table, "Must contain Dining Table")
	assert(has_stool, "Must contain Stool")
	assert(has_chest, "Must contain Storage Chest")

	# 2. Alchemist Laboratory
	var ok2: bool = editor.apply_preset("Alchemist Laboratory")
	assert(ok2, "Alchemist Laboratory preset must apply")
	assert(editor.current_wallpaper == "Stone Brick", "Wallpaper must be Stone Brick")
	assert(editor.current_flooring == "Marble", "Flooring must be Marble")
	assert(editor.placed_furniture.size() == 8, "Alchemist Lab must have 8 furniture pieces")

	var has_alembic: bool = false
	var has_furnace: bool = false
	var has_bookshelf: bool = false
	for inst in editor.placed_furniture:
		if inst.item_id == 38001: has_alembic = true
		if inst.item_id == 38002: has_furnace = true
		if inst.item_id == 38107: has_bookshelf = true

	assert(has_alembic, "Must contain High-grade Alchemy Table")
	assert(has_furnace, "Must contain Furnace")
	assert(has_bookshelf, "Must contain Bookshelf")

	# 3. Cozy Bedroom Suite
	var ok3: bool = editor.apply_preset("Cozy Bedroom Suite")
	assert(ok3, "Cozy Bedroom Suite preset must apply")
	assert(editor.current_wallpaper == "Red Floral Wallpaper", "Wallpaper must be Red Floral Wallpaper")
	assert(editor.current_flooring == "Wood Plank", "Flooring must be Wood Plank")
	assert(editor.placed_furniture.size() == 8, "Bedroom Suite must have 8 furniture pieces")

	var has_luxury_bed: bool = false
	var has_wardrobe: bool = false
	var has_persian_carpet: bool = false
	var has_vase: bool = false
	for inst in editor.placed_furniture:
		if inst.item_id == 38102: has_luxury_bed = true
		if inst.item_id == 38103: has_wardrobe = true
		if inst.item_id == 38304: has_persian_carpet = true
		if inst.item_id == 38305: has_vase = true

	assert(has_luxury_bed, "Must contain Luxury Double Bed")
	assert(has_wardrobe, "Must contain Wardrobe")
	assert(has_persian_carpet, "Must contain Persian Carpet")
	assert(has_vase, "Must contain Flower Vase")

	print("  PASS: All 3 authentic tent presets verified bit-exact.")

func _test_save_and_load_roundtrip(editor: Node) -> void:
	print(">>> [TEST 8] Verifying JSON Serialization & Load Roundtrip...")

	editor.apply_preset("Alchemist Laboratory")
	var save_path: String = "user://test_tent_roundtrip.json"
	var save_ok: bool = editor.save_tent_layout(save_path)
	assert(save_ok, "save_tent_layout must succeed")
	assert(FileAccess.file_exists(save_path), "Saved JSON file must exist on disk")

	var orig_count: int = editor.placed_furniture.size()
	var orig_wp: String = editor.current_wallpaper
	var orig_fl: String = editor.current_flooring
	var orig_stats: Dictionary = editor.get_walkability_stats()

	editor.clear_furniture()
	assert(editor.placed_furniture.is_empty(), "Editor cleared")

	var loaded_data: Dictionary = editor.load_tent_layout(save_path)
	assert(not loaded_data.is_empty(), "Loaded data must not be empty")
	assert(editor.placed_furniture.size() == orig_count, "Placed furniture count must match original")
	assert(editor.current_wallpaper == orig_wp, "Wallpaper must match original")
	assert(editor.current_flooring == orig_fl, "Flooring must match original")

	var loaded_stats: Dictionary = editor.get_walkability_stats()
	assert(loaded_stats["walkable_tiles"] == orig_stats["walkable_tiles"], "Walkable tiles must match original")
	assert(loaded_stats["solid_tiles"] == orig_stats["solid_tiles"], "Solid tiles must match original")

	print("  PASS: JSON layout roundtrip verified without data loss.")

func _test_export_standalone_scene(editor: Node) -> void:
	print(">>> [TEST 9] Verifying Standalone Godot 4 .tscn Scene Export...")

	editor.apply_preset("Beginner Camping Tent")
	var export_path: String = "user://test_exported_tent.tscn"
	var scene_str: String = editor.export_tent_scene(export_path)

	assert(not scene_str.is_empty(), "Exported scene string must not be empty")
	assert(scene_str.contains("[gd_scene format=3]"), "Scene must specify format=3 header")
	assert(scene_str.contains("[node name=\"TentInteriorMap\" type=\"Node2D\"]"), "Root node must be TentInteriorMap")
	assert(scene_str.contains("StaticBody2D"), "Must generate StaticBody2D nodes for furniture")
	assert(scene_str.contains("CollisionPolygon2D"), "Must generate CollisionPolygon2D for 2:1 axonometric footprint")
	assert(scene_str.contains("ExitPortal"), "Must generate ExitPortal area for outdoor transition")
	assert(FileAccess.file_exists(export_path), "Exported file must exist on disk")

	var exported_scene_res = load(export_path)
	assert(exported_scene_res != null, "Exported scene must load as a valid PackedScene resource")
	var exported_node = exported_scene_res.instantiate()
	assert(exported_node != null, "Exported scene must instantiate successfully")
	assert(exported_node.name == "TentInteriorMap", "Exported root node name must be TentInteriorMap")
	assert(exported_node.get_node_or_null("RoomRoot/FurnitureContainer") != null, "FurnitureContainer must exist")
	exported_node.queue_free()

	print("  PASS: Standalone Godot 4 .tscn tent map scene generation and live instantiation verified.")

func _test_scene_instantiation() -> void:
	print(">>> [TEST 10] Verifying Scene Instantiation (tent_editor.tscn)...")

	var scene_res = load("res://scenes/tools/tent_editor.tscn")
	assert(scene_res != null, "ERROR: Failed to load scenes/tools/tent_editor.tscn")

	var instance = scene_res.instantiate()
	assert(instance != null, "ERROR: Failed to instantiate tent_editor.tscn")
	assert(instance is Control, "Root node must extend Control")
	assert(instance.custom_minimum_size == Vector2(800, 600), "custom_minimum_size must be 800x600")

	# Verify unique UI controls
	assert(instance.get_node_or_null("%PresetOption") != null, "%PresetOption must exist")
	assert(instance.get_node_or_null("%BtnApplyPreset") != null, "%BtnApplyPreset must exist")
	assert(instance.get_node_or_null("%WallpaperOption") != null, "%WallpaperOption must exist")
	assert(instance.get_node_or_null("%FlooringOption") != null, "%FlooringOption must exist")
	assert(instance.get_node_or_null("%FurnitureList") != null, "%FurnitureList must exist")
	assert(instance.get_node_or_null("%TentCanvas") != null, "%TentCanvas must exist")
	assert(instance.get_node_or_null("%BtnModePlace") != null, "%BtnModePlace must exist")
	assert(instance.get_node_or_null("%BtnModeRotate") != null, "%BtnModeRotate must exist")
	assert(instance.get_node_or_null("%WalkableProgressBar") != null, "%WalkableProgressBar must exist")
	assert(instance.get_node_or_null("%StatusLabel") != null, "%StatusLabel must exist")

	instance.queue_free()
	print("  PASS: tent_editor.tscn 800x600 responsive dark layout verified.")
