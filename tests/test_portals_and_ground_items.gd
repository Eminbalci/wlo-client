extends SceneTree

## Automated test suite for Map Warp Portals (Wem.MMG, Ground.MMG, Eve.emg)
## and Ground Resource Harvesting (Eve.emg ItemAreas, item.BMg icons, HUD banner).

const GroundParser = preload("res://scripts/map/ground_parser.gd")
const EveParser = preload("res://scripts/map/eve_parser.gd")
const Portal = preload("res://scripts/map/portal.gd")
const GroundItem = preload("res://scripts/map/ground_item.gd")
const WloArchiveReader = preload("res://scripts/core/wlo_archive_reader.gd")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test Portals, Warps & Ground Harvesting Suite ---")
	print("=================================================================")
	
	await process_frame
	_run_all_tests()

func _run_all_tests() -> void:
	# -------------------------------------------------------------
	# 1. GROUND.MMG & WEM.MMG BINARY PARSING CHECKS
	# -------------------------------------------------------------
	print("\n[PART 1] Verifying Ground.MMG & Wem.MMG Parser...")
	var ground_parser := GroundParser.new()
	assert(ground_parser != null, "GroundParser must instantiate")
	
	var total_maps := ground_parser.get_map_count()
	var total_events := ground_parser.get_event_count()
	print("  Ground.MMG indexed maps: %d" % total_maps)
	print("  Wem.MMG indexed events: %d" % total_events)
	assert(total_maps > 0, "Ground.MMG must contain indexed maps")
	assert(total_events == 5761, "Wem.MMG must contain exactly 5,761 indexed events (got %d)" % total_events)
	print("  PASS: Wem.MMG index verified: 5,761 events")
	
	# Check specific WemEvent records
	var wem_10001005 := ground_parser.load_wem_event(10001005)
	assert(wem_10001005 != null, "10001005.wem must exist")
	assert(wem_10001005.event_id == 10001005, "Event ID mismatch")
	assert(wem_10001005.trigger_type == 4, "Trigger type 4 expected for intra-map slide")
	assert(wem_10001005.dest_x == 588 and wem_10001005.dest_y == 1668, "Destination coords mismatch")
	print("  PASS: Wem 10001005 decoded: type=%d, dest=(%d, %d)" % [wem_10001005.trigger_type, wem_10001005.dest_x, wem_10001005.dest_y])
	
	var wem_10001040 := ground_parser.load_wem_event(10001040)
	assert(wem_10001040 != null, "10001040.wem must exist")
	assert(wem_10001040.warp_id == 2, "Warp ID must be 2 (Cabin Entrance) on Map 10001")
	assert(wem_10001040.trigger_type == 1, "Trigger type must be 1 for warp")
	print("  PASS: Wem 10001040 decoded: warp_id=%d, type=%d" % [wem_10001040.warp_id, wem_10001040.trigger_type])
	
	var wem_10002001 := ground_parser.load_wem_event(10002001)
	assert(wem_10002001 != null, "10002001.wem must exist")
	assert(wem_10002001.trigger_type == 1, "Trigger type must be 1")
	print("  PASS: Wem 10002001 decoded successfully")
	
	# -------------------------------------------------------------
	# 2. EVE.EMG WARPLOC & ITEMAREAS REVERSE-ENGINEERING CHECKS
	# -------------------------------------------------------------
	print("\n[PART 2] Verifying Eve.emg Authoritative Warps & ItemAreas...")
	var eve_parser := EveParser.new()
	assert(eve_parser != null and eve_parser.initialize(), "EveParser must initialize")
	print("  Total maps indexed in Eve.emg: %d" % eve_parser.get_total_maps())
	assert(eve_parser.get_total_maps() == 1119, "Eve.emg must contain 1,119 maps (got %d)" % eve_parser.get_total_maps())
	
	# Check Map 10001 Warps
	var warps_10001 := eve_parser.get_warps_for_map(10001)
	assert(warps_10001.size() == 2, "Map 10001 must have exactly 2 authoritative warps")
	assert(warps_10001[0].target_map_id == 10003, "Warp 0 target map must be 10003 (Island Beach)")
	assert(warps_10001[0].dest_x == 1038 and warps_10001[0].dest_y == 2235, "Warp 0 target coords mismatch")
	assert(warps_10001[1].target_map_id == 10002, "Warp 1 target map must be 10002 (Cabin)")
	assert(warps_10001[1].dest_x == 674 and warps_10001[1].dest_y == 1067, "Warp 1 target coords mismatch")
	print("  PASS: Map 10001 Warps verified -> Island (10003 at 1038, 2235) and Cabin (10002 at 674, 1067)")
	
	# Check Map 10002 Warps
	var warps_10002 := eve_parser.get_warps_for_map(10002)
	assert(warps_10002.size() == 1, "Map 10002 must have 1 exit warp")
	assert(warps_10002[0].target_map_id == 10001, "Map 10002 exit warp must lead to 10001 (Deck)")
	assert(warps_10002[0].dest_x == 1814 and warps_10002[0].dest_y == 904, "Deck destination coords mismatch")
	print("  PASS: Map 10002 Exit Warp verified -> Deck (10001 at 1814, 904)")
	
	# Check Map 10003 (Beach) Native Ground Items (ItemAreas)
	var items_10003 := eve_parser.get_ground_items_for_map(10003)
	assert(items_10003.size() == 2, "Map 10003 must have 2 native ground items (got %d)" % items_10003.size())
	
	var item_shell := items_10003[0]
	assert(item_shell.item_id == 46113, "Item 1 must be Shell (46113)")
	assert(item_shell.world_x == 2262 and item_shell.world_y == 4325, "Shell coords mismatch")
	assert(item_shell.respawn_seconds == 120, "Shell respawn seconds mismatch")
	assert(item_shell.slot == 1, "Shell slot mismatch")
	print("  PASS: Ground Item 1 on Beach: Shell (ID 46113) at (%d, %d), respawn=%ds, slot=%d" % [
		item_shell.world_x, item_shell.world_y, item_shell.respawn_seconds, item_shell.slot
	])
	
	var item_coconut := items_10003[1]
	assert(item_coconut.item_id == 41066, "Item 2 must be Coconut (41066)")
	assert(item_coconut.world_x == 1756 and item_coconut.world_y == 3385, "Coconut coords mismatch")
	assert(item_coconut.respawn_seconds == 180, "Coconut respawn seconds mismatch")
	assert(item_coconut.slot == 2, "Coconut slot mismatch")
	print("  PASS: Ground Item 2 on Beach: Coconut (ID 41066) at (%d, %d), respawn=%ds, slot=%d" % [
		item_coconut.world_x, item_coconut.world_y, item_coconut.respawn_seconds, item_coconut.slot
	])
	
	# Check Map 11016 (Kelan Island) Native Ground Items
	var items_11016 := eve_parser.get_ground_items_for_map(11016)
	assert(items_11016.size() == 2, "Map 11016 must have 2 ground items")
	assert(items_11016[0].item_id == 41066 and items_11016[1].item_id == 41066, "Both items on 11016 must be Coconuts (41066)")
	print("  PASS: Map 11016 ground items verified")
	
	# -------------------------------------------------------------
	# 3. PORTAL ENTITY & ADDITIVE DOORLIGHT BLENDING CHECKS
	# -------------------------------------------------------------
	print("\n[PART 3] Verifying Portal Entity with Additive DoorLight Blending...")
	var portal := Portal.new()
	portal.position = Vector2(1814.0, 904.0)
	portal.target_map_id = 10002
	portal.target_coords = Vector2(674.0, 1067.0)
	portal.trigger_radius = 56.0
	root.add_child(portal)
	
	assert(portal._doorlight_sprite != null, "DoorLightSprite must exist")
	assert(portal._doorlight_sprite.material is CanvasItemMaterial, "Material must be CanvasItemMaterial")
	var mat: CanvasItemMaterial = portal._doorlight_sprite.material
	assert(mat.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "Material must use BLEND_MODE_ADD")
	assert(portal._doorlight_frames.size() == 13, "Must load all 13 DoorLight animation frames (got %d)" % portal._doorlight_frames.size())
	print("  PASS: Portal instantiated with 13 Atlas_DoorLight frames and additive BLEND_MODE_ADD")
	
	# Test portal trigger signal
	var portal_sig := {
		"received": false,
		"map": 0,
		"pos": Vector2.ZERO
	}
	portal.portal_triggered.connect(func(_p, t_map, t_pos):
		portal_sig["received"] = true
		portal_sig["map"] = t_map
		portal_sig["pos"] = t_pos
	)
	
	portal.portal_triggered.emit(portal, portal.target_map_id, portal.target_coords)
	assert(portal_sig["received"] == true, "Portal signal must emit")
	assert(portal_sig["map"] == 10002, "Target map must match 10002")
	assert(portal_sig["pos"] == Vector2(674, 1067), "Target coords must match (674, 1067)")
	print("  PASS: Portal trigger signal and coordinates verified")
	portal.queue_free()
	
	# -------------------------------------------------------------
	# 4. GROUND ITEM ENTITY & PROXIMITY HARVESTING CHECKS
	# -------------------------------------------------------------
	print("\n[PART 4] Verifying GroundItem Entity & Proximity Harvesting...")
	var g_item := GroundItem.new()
	g_item.position = Vector2(500.0, 500.0)
	g_item.set_item_data(46113, 1, 1, "Shell", 120.0, 1452)
	root.add_child(g_item)
	
	# Verify icon extraction from item.BMg via ArchiveLoader
	var bmg_archive := WloArchiveReader.open_archive("res://assets/pic/item.BMg")
	assert(bmg_archive != null, "item.BMg must open")
	assert(bmg_archive.has_file("1452.bmp"), "1452.bmp (Shell icon) must exist in item.BMg")
	var shell_tex = bmg_archive.extract_texture("1452.bmp")
	assert(shell_tex != null, "Shell texture must be decoded")
	assert(shell_tex.get_size() == Vector2(32.0, 32.0), "Shell icon must be authentic 32x32 bitmap")
	print("  PASS: Shell (ID 46113) authentic 32x32 icon (1452.bmp) verified")
	
	assert(bmg_archive.has_file("1379.bmp"), "1379.bmp (Coconut icon) must exist in item.BMg")
	var coconut_tex = bmg_archive.extract_texture("1379.bmp")
	assert(coconut_tex != null, "Coconut texture must be decoded")
	assert(coconut_tex.get_size() == Vector2(32.0, 32.0), "Coconut icon must be authentic 32x32 bitmap")
	print("  PASS: Coconut (ID 41066) authentic 32x32 icon (1379.bmp) verified")
	
	# Test Proximity Checking (dist <= 180px)
	var mock_player := Node2D.new()
	mock_player.position = Vector2(500.0, 500.0) # At item position (dist 0px)
	root.add_child(mock_player)
	
	assert(g_item.can_pickup(mock_player) == true, "Player at distance 0 must be eligible for pickup")
	
	# Move player to 170px (<= 180px threshold)
	mock_player.position = Vector2(670.0, 500.0)
	assert(g_item.can_pickup(mock_player) == true, "Player at distance 170px must be eligible for pickup (threshold <= 180px)")
	
	# Move player to 250px (> 180px threshold)
	mock_player.position = Vector2(750.0, 500.0)
	assert(g_item.can_pickup(mock_player) == false, "Player at distance 250px must NOT be eligible for pickup")
	print("  PASS: Proximity threshold (dist <= 180px) verified: allowed at 170px, blocked at 250px")
	
	# Test Harvesting (Pickup into inventory & state change)
	mock_player.position = Vector2(550.0, 500.0) # 50px away
	var pickup_sig := {"received": false}
	g_item.item_picked_up.connect(func(_it, _pl): pickup_sig["received"] = true)
	
	var harvest_success := g_item.try_pickup(mock_player)
	assert(harvest_success == true, "Pickup attempt within 180px must succeed")
	assert(pickup_sig["received"] == true, "item_picked_up signal must fire")
	assert(g_item.is_picked_up == true, "Item state must be marked as picked up")
	assert(g_item.visible == false, "Item visual must hide upon pickup")
	print("  PASS: Item harvested successfully (state=picked_up, visible=false)")
	
	# Test Respawn Logic
	g_item.respawn_seconds = 1.0 # Shorten for test
	g_item._process(1.5) # Advance past respawn duration
	assert(g_item.is_picked_up == false, "Item must respawn after respawn_seconds")
	assert(g_item.visible == true, "Item visual must become visible again upon respawn")
	print("  PASS: Ground Item respawn cycle verified")
	
	g_item.queue_free()
	mock_player.queue_free()
	
	# -------------------------------------------------------------
	# 5. MAPVIEW DYNAMIC PORTALS & GROUND ITEM HARVESTING INTEGRATION
	# -------------------------------------------------------------
	print("\n[PART 5] Verifying MapView Dynamic Spawning, Warping & HUD Banner...")
	var map_view_scene = load("res://scenes/world/map_view.tscn")
	assert(map_view_scene != null, "map_view.tscn must load")
	
	var map_view = map_view_scene.instantiate()
	root.add_child(map_view)
	await process_frame
	
	var mv_player = map_view.get_node_or_null("Entities/Player")
	var mv_renderer = map_view.get_node_or_null("MapRenderer")
	var mv_hud = map_view.get_node_or_null("CanvasLayer/HUD")
	assert(mv_player != null and mv_renderer != null and mv_hud != null, "MapView components must exist")
	
	# Check that dynamic portals were spawned for Map 10001
	assert(map_view._dynamic_portals.size() >= 2, "MapView must dynamically spawn at least 2 portals for Map 10001 (got %d)" % map_view._dynamic_portals.size())
	print("  PASS: MapView dynamically spawned %d warp portals for Map 10001" % map_view._dynamic_portals.size())
	
	# Test HUD banner display & inventory addition
	var banner_sig := {"text": ""}
	if mv_hud.has_signal("banner_emitted"):
		mv_hud.banner_emitted.connect(func(txt): banner_sig["text"] = txt)
	
	mv_hud.show_banner("Harvested Shell x1")
	assert(banner_sig["text"] == "Harvested Shell x1", "HUD banner signal must emit correct text")
	assert(mv_hud._banner_panel != null and mv_hud._banner_panel.visible == true, "HUD banner panel must be visible")
	print("  PASS: HUD banner emitted: '%s'" % banner_sig["text"])
	
	# Test inventory insertion
	var inv_ok: bool = mv_hud.add_inventory_item(46113, 1, "Shell", 1452, "A shiny seashell")
	assert(inv_ok == true, "HUD add_inventory_item must return true")
	
	var found_in_inv: bool = false
	for slot_dict in mv_hud._inventory_data:
		if not slot_dict.is_empty() and int(slot_dict.get("id", 0)) == 46113:
			found_in_inv = true
			break
	assert(found_in_inv == true, "Shell item (ID 46113) must be present in HUD inventory")
	print("  PASS: Item 46113 (Shell) stored into HUD inventory slot successfully")
	
	# Test Seamless Map Warp Transition
	print("Testing seamless portal warp from Deck (10001) to Cabin (10002)...")
	var cabin_dest := Vector2(674.0, 1067.0)
	map_view._on_portal_triggered(null, 10002, cabin_dest)
	
	assert(mv_renderer.current_map_id == 10002, "MapRenderer must update current_map_id to 10002")
	assert(mv_player.world_position == cabin_dest, "Player must be teleported to Cabin spawn (674, 1067)")
	assert(map_view._dynamic_portals.size() >= 1, "Map 10002 must have dynamic exit portal")
	print("  PASS: Seamless transition to Cabin (10002) completed at %s" % mv_player.world_position)
	
	# Test Seamless Warp to Beach (Map 10003) & Dynamic Ground Items Spawning
	print("Testing seamless portal warp to Beach (10003)...")
	var beach_dest := Vector2(1038.0, 2235.0)
	map_view._on_portal_triggered(null, 10003, beach_dest)
	
	assert(mv_renderer.current_map_id == 10003, "MapRenderer must update to Map 10003")
	assert(map_view._dynamic_ground_items.size() == 2, "MapView must dynamically spawn 2 ground items on Map 10003 (got %d)" % map_view._dynamic_ground_items.size())
	print("  PASS: Seamless transition to Beach (10003) spawned 2 authentic ground items (Shell & Coconut)")
	
	# Test clicking ground item on Beach
	var beach_shell: GroundItem = map_view._dynamic_ground_items[0]
	assert(beach_shell.item_id == 46113, "First ground item must be Shell")
	
	# Place player in proximity to beach shell
	mv_player.world_position = beach_shell.position + Vector2(40.0, 0) # 40px away (<= 180px)
	var shell_sig := {"harvested": false}
	map_view.ground_item_harvested.connect(func(it, _pl):
		if it.item_id == 46113:
			shell_sig["harvested"] = true
	)
	
	map_view._on_ground_item_clicked(beach_shell)
	assert(beach_shell.is_picked_up == true, "Beach shell must be marked as picked up")
	assert(shell_sig["harvested"] == true, "MapView ground_item_harvested signal must emit")
	print("  PASS: In-world interactive ground item harvest executed cleanly on Map 10003")
	
	map_view.queue_free()
	
	print("\n=================================================================")
	print("--- ALL PORTAL, WARP & GROUND HARVESTING TESTS PASSED (100%) ---")
	print("=================================================================")
	quit(0)
