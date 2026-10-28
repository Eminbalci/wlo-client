extends SceneTree

## Headless test for Map Collision, Vehicle Gates & Item Database Parity.

const MapData = preload("res://scripts/map/map_data.gd")
const ItemDatabase = preload("res://scripts/database/item_database.gd")
const WloArchiveReader = preload("res://scripts/core/wlo_archive_reader.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test Collision, Vehicle Gates & Item Parity ---")
	print("=================================================================")
	
	# -------------------------------------------------------------
	# 1. MAP COLLISION & VEHICLE TRAVERSAL CHECKS
	# -------------------------------------------------------------
	print("\n[PART 1] Verifying MapData Traversal Matrix & Vehicle Gates...")
	
	# Test Land (0x00)
	var land_check_foot = MapData.check_traversal(MapData.TileCollisionFlags.WALKABLE, 0)
	assert(land_check_foot["allowed"] == true, "Foot must traverse walkable land")
	
	# Test Solid Wall (0x01)
	var wall_check = MapData.check_traversal(MapData.TileCollisionFlags.SOLID_WALL, 0)
	assert(wall_check["allowed"] == false, "Solid wall must block foot")
	assert(wall_check["reason"] == "Path is blocked by an obstacle.", "Incorrect wall reason")
	
	var wall_check_plane = MapData.check_traversal(MapData.TileCollisionFlags.SOLID_WALL, 4)
	assert(wall_check_plane["allowed"] == false, "Solid wall must block plane")
	
	# Test Water (0x02 and 0x40)
	var water_check_foot = MapData.check_traversal(MapData.TileCollisionFlags.WATER, 0)
	assert(water_check_foot["allowed"] == false, "Foot must NOT traverse water")
	assert(water_check_foot["reason"] == "You need a vehicle to traverse water!", "Water error message mismatch: %s" % water_check_foot["reason"])
	print("  PASS: On foot blocked on water with feedback: '%s'" % water_check_foot["reason"])
	
	var shallow_water_check_foot = MapData.check_traversal(MapData.TileCollisionFlags.SHALLOW_WATER, 0)
	assert(shallow_water_check_foot["allowed"] == false, "Foot must NOT traverse shallow water")
	assert(shallow_water_check_foot["reason"] == "You need a vehicle to traverse water!", "Shallow water error message mismatch")
	print("  PASS: On foot blocked on shallow water with feedback: '%s'" % shallow_water_check_foot["reason"])
	
	var water_check_raft = MapData.check_traversal(MapData.TileCollisionFlags.WATER, 1) # RAFT
	assert(water_check_raft["allowed"] == true, "Raft must traverse water")
	print("  PASS: Raft traverses water successfully")
	
	var water_check_boat = MapData.check_traversal(MapData.TileCollisionFlags.WATER, 2) # BOAT
	assert(water_check_boat["allowed"] == true, "Boat must traverse water")
	print("  PASS: Boat traverses water successfully")
	
	# Test Deep Ocean (0x04)
	var ocean_check_foot = MapData.check_traversal(MapData.TileCollisionFlags.DEEP_OCEAN, 0)
	assert(ocean_check_foot["allowed"] == false, "Foot must NOT traverse deep ocean")
	assert(ocean_check_foot["reason"] == "You need a ship or advanced vehicle to traverse deep ocean!", "Deep ocean foot mismatch")
	
	var ocean_check_raft = MapData.check_traversal(MapData.TileCollisionFlags.DEEP_OCEAN, 1) # RAFT
	assert(ocean_check_raft["allowed"] == false, "Raft must NOT traverse deep ocean")
	print("  PASS: Raft blocked on deep ocean with feedback: '%s'" % ocean_check_raft["reason"])
	
	var ocean_check_ship = MapData.check_traversal(MapData.TileCollisionFlags.DEEP_OCEAN, 3) # SHIP
	assert(ocean_check_ship["allowed"] == true, "Ship must traverse deep ocean")
	print("  PASS: Ship traverses deep ocean successfully")
	
	# Test Mountain (0x08 / 0x80)
	var mountain_check_foot = MapData.check_traversal(MapData.TileCollisionFlags.MOUNTAIN, 0)
	assert(mountain_check_foot["allowed"] == false, "Foot must NOT traverse mountain")
	assert(mountain_check_foot["reason"] == "You need a flying vehicle to cross this terrain!", "Mountain foot mismatch")
	print("  PASS: Foot blocked on mountain with feedback: '%s'" % mountain_check_foot["reason"])
	
	var mountain_check_raft = MapData.check_traversal(MapData.TileCollisionFlags.MOUNTAIN, 1)
	assert(mountain_check_raft["allowed"] == false, "Raft must NOT traverse mountain")
	
	var mountain_check_plane = MapData.check_traversal(MapData.TileCollisionFlags.MOUNTAIN, 4) # PLANE
	assert(mountain_check_plane["allowed"] == true, "Plane must traverse mountain")
	print("  PASS: Plane flies over mountain successfully")
	
	# -------------------------------------------------------------
	# 2. PLAYER ENTITY VEHICLE STATE & COLLISION BLOCKING
	# -------------------------------------------------------------
	print("\n[PART 2] Testing PlayerEntity Kinematics & Interactive Gates...")
	
	var player_scene = load("res://scenes/world/player.tscn")
	assert(player_scene != null, "player.tscn must load")
	var player = player_scene.instantiate()
	root.add_child(player)
	
	# Build synthetic collision map for unit testing:
	# Tile (50, 50) [px 1000, 1000]: Land (0x00)
	# Tile (55, 50) [px 1100, 1000]: Water (0x02)
	# Tile (60, 50) [px 1200, 1000]: Deep Ocean (0x04)
	# Tile (65, 50) [px 1300, 1000]: Mountain (0x08)
	var test_map := MapData.new()
	var test_block := MapData.MapBlock.new()
	test_block.grid_x = 45
	test_block.grid_y = 45
	test_block.block_dim_x = 30
	test_block.block_dim_y = 10
	test_block.is_uniform = false
	test_block.collision_matrix.resize(30 * 10)
	test_block.collision_matrix.fill(0) # Default land
	
	# Set water at local (10, 5) -> grid (55, 50) -> px (1100, 1000)
	test_block.collision_matrix[5 * 30 + 10] = MapData.TileCollisionFlags.WATER
	# Set deep ocean at local (15, 5) -> grid (60, 50) -> px (1200, 1000)
	test_block.collision_matrix[5 * 30 + 15] = MapData.TileCollisionFlags.DEEP_OCEAN
	# Set mountain at local (20, 5) -> grid (65, 50) -> px (1300, 1000)
	test_block.collision_matrix[5 * 30 + 20] = MapData.TileCollisionFlags.MOUNTAIN
	test_map.blocks.append(test_block)
	
	player.map_data = test_map
	player.world_position = Vector2(1000.0, 1000.0) # On land
	
	var blocked_reasons: Array[String] = []
	player.movement_blocked.connect(func(reason: String, _pos: Vector2):
		blocked_reasons.append(reason)
	)
	
	# Test A: Player on foot attempts to move to water tile (direct gate check without fallback)
	assert(player.current_vehicle == player.VehicleType.NONE, "Player must start on foot")
	var move_ok = player.set_target_world_position(Vector2(1100.0, 1000.0), false)
	assert(move_ok == false, "Player on foot must be blocked from moving to water")
	assert(player.is_moving == false, "Player must not be moving when blocked")
	assert(blocked_reasons.size() == 1, "Expected 1 movement blocked signal")
	assert(blocked_reasons[0] == "You need a vehicle to traverse water!", "Reason mismatch: %s" % blocked_reasons[0])
	print("  PASS: PlayerEntity blocked on water: '%s'" % blocked_reasons[0])
	
	# Test B: Player mounts Raft
	player.mount_vehicle(player.VehicleType.RAFT)
	assert(player.current_vehicle == player.VehicleType.RAFT, "Player must be mounted on Raft")
	assert(player.is_mounted() == true, "is_mounted must be true")
	
	move_ok = player.set_target_world_position(Vector2(1100.0, 1000.0))
	assert(move_ok == true, "Mounted player must be allowed to move to water tile")
	assert(player.is_moving == true, "Player should now be moving")
	print("  PASS: PlayerEntity mounted on Raft moves to water tile successfully")
	
	# Test C: Raft attempts to cross into Deep Ocean (direct gate check without fallback)
	player.world_position = Vector2(1100.0, 1000.0) # On water
	blocked_reasons.clear()
	move_ok = player.set_target_world_position(Vector2(1200.0, 1000.0), false)
	assert(move_ok == false, "Raft must be blocked from deep ocean")
	assert(blocked_reasons.size() == 1, "Deep ocean blocked signal expected")
	print("  PASS: Raft blocked from deep ocean: '%s'" % blocked_reasons[0])
	
	# Test D: Mount Plane and fly over deep ocean and mountain
	player.mount_vehicle(player.VehicleType.PLANE)
	move_ok = player.set_target_world_position(Vector2(1200.0, 1000.0))
	assert(move_ok == true, "Plane must traverse deep ocean")
	
	move_ok = player.set_target_world_position(Vector2(1300.0, 1000.0))
	assert(move_ok == true, "Plane must traverse mountain")
	print("  PASS: Plane flies over deep ocean and mountain successfully")
	
	# Test E: Dismount returns to foot
	player.dismount_vehicle()
	assert(player.current_vehicle == player.VehicleType.NONE, "Player must be on foot after dismount")
	assert(player.is_mounted() == false, "is_mounted must be false")
	
	player.queue_free()
	
	# -------------------------------------------------------------
	# 3. ITEM DATABASE PARITY, NAMES, ICONS & DESCRIPTIONS
	# -------------------------------------------------------------
	print("\n[PART 3] Verifying Item Database Decryption & Appearance Parity...")
	
	var item_db := ItemDatabase.new()
	var loaded := item_db.load_from_file("res://assets/data/Item.dat")
	assert(loaded == true, "Item database must load successfully")
	assert(item_db.get_all_items().size() >= 4818, "Item database must have at least 4,818 items")
	print("  PASS: Loaded %d authentic item records" % item_db.get_all_items().size())
	
	# Test Item 10002 (Plate)
	var plate = item_db.get_item(10002)
	assert(plate != null, "Item 10002 (Plate) must exist")
	assert(plate.name.to_lower() == "plate", "Item 10002 name mismatch: '%s'" % plate.name)
	assert(plate.icon_id == 1120, "Item 10002 icon mismatch: expected 1120, got %d" % plate.icon_id)
	assert(plate.equip_pos == 3, "Item 10002 equip_pos mismatch: expected 3, got %d" % plate.equip_pos)
	assert(plate.description == "A plate used for holding the food", "Plate description mismatch: '%s'" % plate.description)
	print("  PASS: Item 10002 (Plate): Name='%s', Icon=%d, EquipPos=%d, Desc='%s'" % [plate.name, plate.icon_id, plate.equip_pos, plate.description])
	
	# Test Item 10003 (Violin)
	var violin = item_db.get_item(10003)
	assert(violin != null, "Item 10003 (Violin) must exist")
	assert(violin.name.to_lower() == "violin", "Item 10003 name mismatch: '%s'" % violin.name)
	assert(violin.icon_id == 1122, "Item 10003 icon mismatch: expected 1122, got %d" % violin.icon_id)
	assert(violin.equip_pos == 3, "Item 10003 equip_pos mismatch: expected 3, got %d" % violin.equip_pos)
	assert(violin.description.begins_with("A western classical"), "Violin description mismatch: '%s'" % violin.description)
	print("  PASS: Item 10003 (Violin): Name='%s', Icon=%d, EquipPos=%d" % [violin.name, violin.icon_id, violin.equip_pos])
	
	# Test Item 10004 (Syringe)
	var syringe = item_db.get_item(10004)
	assert(syringe != null, "Item 10004 (Syringe) must exist")
	assert(syringe.name.to_lower() == "syringe", "Item 10004 name mismatch: '%s'" % syringe.name)
	assert(syringe.icon_id == 1087, "Item 10004 icon mismatch: expected 1087, got %d" % syringe.icon_id)
	print("  PASS: Item 10004 (Syringe): Name='%s', Icon=%d" % [syringe.name, syringe.icon_id])
	
	# Test Item 10031 (Copper Knife)
	var c_knife = item_db.get_item(10031)
	assert(c_knife != null, "Item 10031 must exist")
	assert(c_knife.name == "Copper Knife", "Item 10031 name mismatch: '%s'" % c_knife.name)
	assert(c_knife.icon_id == 2312, "Item 10031 icon mismatch: expected 2312, got %d" % c_knife.icon_id)
	assert(c_knife.equip_pos == 3, "Item 10031 equip_pos mismatch: expected 3, got %d" % c_knife.equip_pos)
	assert(c_knife.description == "A knife made from copper", "Description mismatch: '%s'" % c_knife.description)
	print("  PASS: Item 10031 (Copper Knife): Name='%s', Icon=%d, EquipPos=%d, Desc='%s'" % [c_knife.name, c_knife.icon_id, c_knife.equip_pos, c_knife.description])
	
	# Test Item 10033 (Iron Knife)
	var i_knife = item_db.get_item(10033)
	assert(i_knife != null, "Item 10033 must exist")
	assert(i_knife.name == "Iron Knife", "Item 10033 name mismatch: '%s'" % i_knife.name)
	assert(i_knife.icon_id == 1136, "Item 10033 icon mismatch: expected 1136, got %d" % i_knife.icon_id)
	assert(i_knife.description == "A knife made from iron", "Description mismatch: '%s'" % i_knife.description)
	print("  PASS: Item 10033 (Iron Knife): Name='%s', Icon=%d, Desc='%s'" % [i_knife.name, i_knife.icon_id, i_knife.description])
	
	# Test Item 10034 (Pure Iron Knife)
	var pi_knife = item_db.get_item(10034)
	assert(pi_knife != null, "Item 10034 must exist")
	assert(pi_knife.name.begins_with("Pure Iron Knif"), "Item 10034 name mismatch: '%s'" % pi_knife.name)
	assert(pi_knife.icon_id == 2311, "Item 10034 icon mismatch: expected 2311, got %d" % pi_knife.icon_id)
	print("  PASS: Item 10034 (Pure Iron Knife): Name='%s', Icon=%d" % [pi_knife.name, pi_knife.icon_id])
	
	# Test Item 32011 (Bread)
	var bread = item_db.get_item(32011)
	assert(bread != null, "Item 32011 (Bread) must exist")
	assert(bread.name == "Bread", "Item 32011 name mismatch: '%s'" % bread.name)
	assert(bread.icon_id == 1011, "Item 32011 icon mismatch: expected 1011, got %d" % bread.icon_id)
	print("  PASS: Item 32011 (Bread): Name='%s', Icon=%d" % [bread.name, bread.icon_id])
	
	# Test Item 48010 (Raft)
	var raft = item_db.get_item(48010)
	assert(raft != null, "Item 48010 (Raft) must exist")
	assert(raft.name == "Raft", "Item 48010 name mismatch: '%s'" % raft.name)
	assert(raft.icon_id == 8000, "Item 48010 icon mismatch: expected 8000, got %d" % raft.icon_id)
	print("  PASS: Item 48010 (Raft): Name='%s', Icon=%d" % [raft.name, raft.icon_id])
	
	# Test Item 34169 (Bamboo Dragonfly)
	var dragonfly = item_db.get_item(34169)
	assert(dragonfly != null, "Item 34169 (Bamboo Dragonfly) must exist")
	assert(dragonfly.name == "Bamboo Dragonfly", "Item 34169 name mismatch: '%s'" % dragonfly.name)
	assert(dragonfly.icon_id == 3025, "Item 34169 icon mismatch: expected 3025, got %d" % dragonfly.icon_id)
	print("  PASS: Item 34169 (Bamboo Dragonfly): Name='%s', Icon=%d" % [dragonfly.name, dragonfly.icon_id])
	
	# -------------------------------------------------------------
	# 4. ARCHIVE ICON SPRITE EXISTENCE CHECK
	# -------------------------------------------------------------
	print("\n[PART 4] Checking that authentic icon bitmaps exist in item.BMg and item1.BMg...")
	var bmg_archive := WloArchiveReader.open_archive("res://assets/pic/item.BMg")
	assert(bmg_archive != null, "item.BMg archive must open")
	var bmg1_archive := WloArchiveReader.open_archive("res://assets/pic/item1.BMg")
	assert(bmg1_archive != null, "item1.BMg archive must open")
	
	var standard_icons = [1120, 1122, 1087, 2311, 2312, 2313, 1136, 1011, 3025]
	for icon in standard_icons:
		var fname := "%d.bmp" % icon
		assert(bmg_archive.has_file(fname), "Missing icon bitmap in item.BMg: %s" % fname)
		var tex = bmg_archive.extract_texture(fname)
		assert(tex != null, "Failed to decode icon texture for %s" % fname)
		print("  PASS: Extracted authentic icon %s from item.BMg, size=%s" % [fname, str(tex.get_size())])
	
	# Raft icon (8000.bmp) in item1.BMg
	assert(bmg1_archive.has_file("8000.bmp"), "Missing Raft icon bitmap in item1.BMg: 8000.bmp")
	var raft_tex = bmg1_archive.extract_texture("8000.bmp")
	assert(raft_tex != null, "Failed to decode Raft icon texture from item1.BMg")
	print("  PASS: Extracted authentic Raft icon 8000.bmp from item1.BMg, size=%s" % str(raft_tex.get_size()))
	
	print("\n=================================================================")
	print("--- ALL COLLISION, VEHICLE GATE & ITEM TESTS PASSED ---")
	print("=================================================================")
	quit(0)
