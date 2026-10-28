extends SceneTree

func _init() -> void:
	print("=================================================================")
	print("--- Running Complete Undo / Redo & Responsive Editor Test Suite ---")
	print("=================================================================")
	
	# -------------------------------------------------------------
	# 1. MapEditor Undo / Redo
	# -------------------------------------------------------------
	print("\n>>> [TEST 1] Testing MapEditor Collision, Portal, Item, NPC Undo / Redo...")
	var MapEditorScript = load("res://scripts/tools/map_editor.gd")
	var map_ed = MapEditorScript.new()
	map_ed.init_empty_map(200, 200, 99991, "Test Undo Map")
	
	var initial_flag: int = map_ed.get_collision_at(2, 2)
	assert(initial_flag == 0, "Initial tile should be walkable")
	
	# Paint solid wall at (2, 2)
	map_ed._paint_stroke_before = map_ed.collision_grid.duplicate()
	map_ed.set_collision_at(2, 2, 1)
	map_ed.record_action({"type": "collision", "before": map_ed._paint_stroke_before, "after": map_ed.collision_grid.duplicate()})
	assert(map_ed.get_collision_at(2, 2) == 1, "Tile should be solid after painting")
	
	# Test Undo
	assert(map_ed.undo() == true, "Undo should succeed")
	assert(map_ed.get_collision_at(2, 2) == 0, "Tile should revert to walkable after Undo")
	
	# Test Redo
	assert(map_ed.redo() == true, "Redo should succeed")
	assert(map_ed.get_collision_at(2, 2) == 1, "Tile should be solid after Redo")
	print("  PASS: Collision paint Undo / Redo verified cleanly")
	
	# Test Portal Undo / Redo
	var portal_count_before: int = map_ed.portals.size()
	map_ed.add_portal(Vector2(100, 100), 10002, Vector2(500, 500), "Secret Portal")
	assert(map_ed.portals.size() == portal_count_before + 1, "Portal should be added")
	assert(map_ed.undo() == true, "Undo portal add should succeed")
	assert(map_ed.portals.size() == portal_count_before, "Portal should be removed after Undo")
	assert(map_ed.redo() == true, "Redo portal add should succeed")
	assert(map_ed.portals.size() == portal_count_before + 1, "Portal should be restored after Redo")
	print("  PASS: Portal add/remove Undo / Redo verified cleanly")
	
	# Test Item Undo / Redo
	var item_count_before: int = map_ed.ground_items.size()
	map_ed.add_ground_item(Vector2(60, 60), 46113, "Golden Shell", 1, 60.0)
	assert(map_ed.ground_items.size() == item_count_before + 1, "Ground item should be added")
	assert(map_ed.undo() == true, "Undo ground item should succeed")
	assert(map_ed.ground_items.size() == item_count_before, "Ground item should be removed after Undo")
	assert(map_ed.redo() == true, "Redo ground item should succeed")
	assert(map_ed.ground_items.size() == item_count_before + 1, "Ground item should be restored after Redo")
	print("  PASS: Ground Item add/remove Undo / Redo verified cleanly")
	
	# Test NPC Undo / Redo
	var npc_count_before: int = map_ed.npcs.size()
	map_ed.add_npc(Vector2(80, 80), 14001, "Patrol Crew")
	assert(map_ed.npcs.size() == npc_count_before + 1, "NPC should be added")
	assert(map_ed.undo() == true, "Undo NPC should succeed")
	assert(map_ed.npcs.size() == npc_count_before, "NPC should be removed after Undo")
	assert(map_ed.redo() == true, "Redo NPC should succeed")
	assert(map_ed.npcs.size() == npc_count_before + 1, "NPC should be restored after Redo")
	print("  PASS: NPC add/remove Undo / Redo verified cleanly")
	map_ed.free()

	# -------------------------------------------------------------
	# 2. TentEditor Undo / Redo
	# -------------------------------------------------------------
	print("\n>>> [TEST 2] Testing TentEditor Furniture & Collision Undo / Redo...")
	var TentEditorScript = load("res://scripts/tools/tent_editor.gd")
	var tent_ed = TentEditorScript.new()
	var f_inst = tent_ed.place_furniture(204, Vector2i(3, 3)) # Dining Table
	assert(f_inst != null, "Furniture should be placed")
	assert(tent_ed.placed_furniture.size() == 1, "Placed furniture count should be 1")
	
	# Undo placement
	assert(tent_ed.undo() == true, "Undo furniture place should succeed")
	assert(tent_ed.placed_furniture.is_empty(), "Placed furniture should be empty after Undo")
	
	# Redo placement
	assert(tent_ed.redo() == true, "Redo furniture place should succeed")
	assert(tent_ed.placed_furniture.size() == 1, "Placed furniture count should be restored to 1")
	
	# Rotate furniture
	var old_heading: int = tent_ed.placed_furniture[0].heading
	tent_ed.rotate_furniture(tent_ed.placed_furniture[0].instance_id, true)
	assert(tent_ed.placed_furniture[0].heading != old_heading, "Heading should change on rotate")
	assert(tent_ed.undo() == true, "Undo rotate should succeed")
	assert(tent_ed.placed_furniture[0].heading == old_heading, "Heading should revert after Undo")
	assert(tent_ed.redo() == true, "Redo rotate should succeed")
	assert(tent_ed.placed_furniture[0].heading != old_heading, "Heading should be rotated after Redo")
	print("  PASS: Tent furniture place & rotate Undo / Redo verified cleanly")
	tent_ed.free()

	# -------------------------------------------------------------
	# 3. NpcEditor Undo / Redo
	# -------------------------------------------------------------
	print("\n>>> [TEST 3] Testing NpcEditor Waypoints & Choices Undo / Redo...")
	var NpcEditorScript = load("res://scripts/tools/npc_editor.gd")
	var npc_ed = NpcEditorScript.new()
	
	# Add choice
	npc_ed._dialogue_choices.append("I am ready!")
	npc_ed.record_action({"type": "add_choice", "text": "I am ready!"})
	assert(npc_ed._dialogue_choices.size() == 1, "Choice count should be 1")
	assert(npc_ed.undo() == true, "Undo add_choice should succeed")
	assert(npc_ed._dialogue_choices.is_empty(), "Choices should be empty after Undo")
	assert(npc_ed.redo() == true, "Redo add_choice should succeed")
	assert(npc_ed._dialogue_choices.size() == 1, "Choice should be restored after Redo")
	
	# Add waypoint
	npc_ed._walksteps.append(Vector2(500, 500))
	npc_ed._walkstep_delays.append(2.0)
	npc_ed.record_action({"type": "add_waypoint", "pos": Vector2(500, 500), "delay": 2.0})
	assert(npc_ed._walksteps.size() == 1, "Waypoint count should be 1")
	assert(npc_ed.undo() == true, "Undo add_waypoint should succeed")
	assert(npc_ed._walksteps.is_empty(), "Waypoints should be empty after Undo")
	assert(npc_ed.redo() == true, "Redo add_waypoint should succeed")
	assert(npc_ed._walksteps.size() == 1, "Waypoint should be restored after Redo")
	print("  PASS: NPC Waypoints & Choices Undo / Redo verified cleanly")
	npc_ed.free()

	# -------------------------------------------------------------
	# 4. WorldEditor Integration & Hotkeys
	# -------------------------------------------------------------
	print("\n>>> [TEST 4] Testing WorldEditor Suite Undo/Redo Dispatch & Responsive Setup...")
	var WorldEditorScene = load("res://scenes/tools/world_editor.tscn")
	var world_ed = WorldEditorScene.instantiate()
	root.add_child(world_ed)
	world_ed._ensure_studio_node_refs()
	
	# Check dispatch to MapStudio on Tab 0
	world_ed.main_tab_container.current_tab = 0
	world_ed.map_studio.add_portal(Vector2(200, 200), 10003, Vector2(300, 300), "Warp Gateway")
	var p_count: int = world_ed.map_studio.portals.size()
	
	world_ed.perform_undo()
	assert(world_ed.map_studio.portals.size() == p_count - 1, "WorldEditor perform_undo should undo portal in MapStudio")
	assert("Action reversed in Map Studio" in world_ed.status_label.text, "Status label should report undo success")
	
	world_ed.perform_redo()
	assert(world_ed.map_studio.portals.size() == p_count, "WorldEditor perform_redo should redo portal in MapStudio")
	assert("Action reapplied in Map Studio" in world_ed.status_label.text, "Status label should report redo success")
	
	print("  PASS: WorldEditor Undo/Redo unified toolbar & status feedback verified cleanly")
	world_ed.free()
	
	print("\n=================================================================")
	print("--- ALL UNDO / REDO & RESPONSIVE SUITE TESTS PASSED (100%) ---")
	print("=================================================================")
	quit(0)
