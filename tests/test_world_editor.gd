extends SceneTree

## Automated Headless Verification Suite for WorldEditor & Database Inspector
## Tests instantiation, tab navigation, Database queries, Map Studio, NPC Studio, and Simulator lifecycle.

const WorldEditor = preload("res://scripts/tools/world_editor.gd")

func _init() -> void:
	print("[TestWorldEditor] Starting World Editor automated test suite...")
	var timer = create_timer(15.0)
	timer.timeout.connect(func():
		push_error("[TestWorldEditor] Test timed out after 15s!")
		quit(1)
	)
	
	_run_tests.call_deferred()

func _run_tests() -> void:
	# 1. Load and Instantiate Scene
	var scene_res = ResourceLoader.load("res://scenes/tools/world_editor.tscn")
	if not scene_res:
		push_error("[TestWorldEditor] FAILED to load res://scenes/tools/world_editor.tscn")
		quit(1)
		return
	print("[TestWorldEditor] Loaded world_editor.tscn successfully.")
	
	var editor_node: WorldEditor = scene_res.instantiate() as WorldEditor
	if not editor_node:
		push_error("[TestWorldEditor] FAILED to instantiate WorldEditor node")
		quit(1)
		return
	
	root.add_child(editor_node)
	await process_frame
	await process_frame
	
	# 2. Check TabContainer & 4 Tabs
	var tabs: TabContainer = editor_node.main_tab_container
	assert(tabs != null, "MainTabContainer must exist")
	assert(tabs.get_tab_count() == 11, "Must have 11 tabs, found: %d" % tabs.get_tab_count())
	print("[TestWorldEditor] Tab count verified: 11 tabs found.")
	
	var tab_names: Array[String] = []
	for i in range(tabs.get_tab_count()):
		tab_names.append(tabs.get_tab_title(i))
	print("[TestWorldEditor] Tab titles: ", tab_names)
	
	# 3. Check Database Inspector Functionality
	print("[TestWorldEditor] Testing Database Inspector...")
	var gdb = root.get_node_or_null("GameDatabase")
	assert(gdb != null, "GameDatabase autoload must be present")
	
	var item_cnt = gdb.items.get_all_items().size()
	var npc_cnt = gdb.npcs.get_all_npcs().size()
	var talk_cnt = gdb.talks.get_count()
	var scene_cnt = gdb.scenes.get_all_scenes().size()
	print("[TestWorldEditor] Database counts: Items=%d, NPCs=%d, Talks=%d, Scenes=%d" % [
		item_cnt, npc_cnt, talk_cnt, scene_cnt
	])
	assert(item_cnt >= 7000, "Items must be >= 7000, got: %d" % item_cnt)
	assert(npc_cnt >= 4000, "NPCs must be >= 4000, got: %d" % npc_cnt)
	assert(talk_cnt >= 17000, "Talks must be >= 17000, got: %d" % talk_cnt)
	assert(scene_cnt >= 86, "Scenes must be >= 86, got: %d" % scene_cnt)
	
	# Switch Database categories
	print("All scene keys: ", gdb.scenes.get_all_scenes().keys().slice(0, 10))
	tabs.current_tab = 2 # Database Inspector
	editor_node.opt_db_category.selected = 0 # Items
	editor_node._on_db_category_selected(0)
	assert(editor_node.db_filtered_ids.size() == item_cnt, "Filtered items must match total")
	editor_node._on_db_item_selected(0)
	assert(editor_node.panel_item_details.visible, "Item details panel must be visible")
	
	editor_node.opt_db_category.selected = 1 # NPCs
	editor_node._on_db_category_selected(1)
	assert(editor_node.db_filtered_ids.size() == npc_cnt, "Filtered NPCs must match total")
	editor_node._on_db_item_selected(0)
	assert(editor_node.panel_npc_details.visible, "NPC details panel must be visible")
	
	editor_node.opt_db_category.selected = 2 # Dialogues
	editor_node._on_db_category_selected(2)
	assert(editor_node.db_filtered_ids.size() == talk_cnt, "Filtered dialogues must match total")
	editor_node._on_db_item_selected(0)
	assert(editor_node.panel_talk_details.visible, "Talk details panel must be visible")
	
	editor_node.opt_db_category.selected = 3 # Scenes
	editor_node._on_db_category_selected(3)
	assert(editor_node.db_filtered_ids.size() == scene_cnt, "Filtered scenes must match total")
	editor_node._on_db_item_selected(0)
	assert(editor_node.panel_scene_details.visible, "Scene details panel must be visible")
	
	# Test Search Filtering
	var sample_scene_id = gdb.scenes.get_all_scenes().keys()[0]
	editor_node._on_db_search_text_changed(str(sample_scene_id))
	assert(editor_node.db_filtered_ids.size() >= 1, "Searching sample_scene_id must yield results")
	print("[TestWorldEditor] Scene search '%s' yielded: %d results" % [str(sample_scene_id), editor_node.db_filtered_ids.size()])
	editor_node._on_db_search_text_changed("") # Clear
	
	# 4. Check Map Studio Embedded Integration
	print("[TestWorldEditor] Testing Map Studio Embedded...")
	tabs.current_tab = 0 # Map Studio
	assert(editor_node.map_studio != null, "Map Studio instance must be present")
	editor_node._sync_active_map(10001)
	assert(editor_node.active_map_id == 10001, "Active map should be 10001")
	print("[TestWorldEditor] Map Studio active map synced: 10001.")
	
	# 5. Check NPC Studio Embedded Integration
	print("[TestWorldEditor] Testing NPC Studio Embedded...")
	tabs.current_tab = 1 # NPC Studio
	assert(editor_node.npc_studio != null, "NPC Studio instance must be present")
	editor_node._on_btn_new_npc_pressed()
	print("[TestWorldEditor] NPC Studio New NPC action invoked.")
	
	# 6. Check Live Playtest & Simulator
	print("[TestWorldEditor] Testing Live Playtest & Simulator...")
	tabs.current_tab = 3 # Simulator
	editor_node.start_playtest()
	await process_frame
	await process_frame
	
	assert(editor_node.is_simulator_running, "Simulator should be running")
	assert(editor_node._simulator_instance != null, "Simulator instance must be valid")
	print("[TestWorldEditor] Simulator started successfully with MapView instance.")
	
	editor_node.stop_playtest()
	await process_frame
	assert(not editor_node.is_simulator_running, "Simulator should be stopped")
	assert(editor_node._simulator_instance == null, "Simulator instance should be nullified")
	print("[TestWorldEditor] Simulator stopped cleanly.")
	
	print("\n=======================================================")
	print("[TestWorldEditor] ALL WORLD EDITOR TESTS PASSED 100%!")
	print("=======================================================\n")
	quit(0)
