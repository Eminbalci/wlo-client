extends SceneTree

func _init() -> void:
	print("--- BEGIN TEST: Multi-JMG Map Archives & NPC Texture Verification ---")
	print("Root children at start:")
	for child in root.get_children():
		print("  - ", child.name, " (", child.get_class(), ")")
	
	# 1. Access or instantiate ArchiveLoader
	var loader = root.get_node_or_null("ArchiveLoader")
	if not loader:
		var ArchiveLoaderScript = load("res://scripts/core/archive_loader.gd")
		loader = ArchiveLoaderScript.new()
		loader.name = "ArchiveLoader"
		root.add_child(loader)
	
	loader.initialize_archives()
	
	# Verify _map_archives array count and entries
	print("Map archives loaded: ", loader._map_archives.size())
	if loader._map_archives.size() < 3:
		print("FAILED: Expected at least 3 map archives, found: ", loader._map_archives.size())
		quit(1)
		return
	
	# Count total map backgrounds across all archives
	var total_entries: int = 0
	for arch in loader._map_archives:
		total_entries += arch.get_file_list().size()
	print("Total map entries across all JMG archives: ", total_entries)
	assert(total_entries == 357, "Expected exactly 357 map entries across all archives!")
	
	# 2. Verify backgrounds extraction for specific scenes
	var test_maps: Dictionary = {
		10001: "Ship Deck (map.JMG)",
		10002: "Ship Cabin (map.JMG)",
		10003: "Deserted Island (map.JMG)",
		10075: "Interior Scene (map_c01.JMg)",
		10202: "Expansion Scene (map_d01.JMg)"
	}
	
	for map_id in test_maps:
		var tex: ImageTexture = loader.get_map_background(map_id)
		if not tex:
			print("FAILED: Background texture for map %d (%s) returned null!" % [map_id, test_maps[map_id]])
			quit(1)
			return
		var sz: Vector2 = tex.get_size()
		print("SUCCESS: Map %d (%s) -> Size: (%dx%d)" % [map_id, test_maps[map_id], int(sz.x), int(sz.y)])
		assert(sz.x > 0 and sz.y > 0, "Texture dimensions must be positive")
	
	# Verify scene 10011 fallback to 10003
	var tex_10011: ImageTexture = loader.get_map_background(10011)
	if not tex_10011:
		print("FAILED: Background texture for map 10011 (Deserted Island Beach) returned null!")
		quit(1)
		return
	print("SUCCESS: Map 10011 (Beach Awakening) -> Size: ", tex_10011.get_size())
	
	# 3. Verify get_npc_texture
	print("\n--- Verifying get_npc_texture ---")
	
	# Playable Role (Betty = 2)
	var betty_tex: ImageTexture = loader.get_npc_texture(2, 0)
	if not betty_tex:
		print("FAILED: Playable role 2 (Betty) NPC texture returned null!")
		quit(1)
		return
	print("SUCCESS: Playable role 2 (Betty) -> Size: ", betty_tex.get_size())
	
	# Captain Robinson from 001.jma (sprite 1038)
	var cap_tex: ImageTexture = loader.get_npc_texture(1038, 0)
	if not cap_tex:
		print("FAILED: NPC sprite 1038 (Captain Robinson) returned null!")
		quit(1)
		return
	print("SUCCESS: NPC sprite 1038 (Captain Robinson) -> Size: ", cap_tex.get_size())
	
	# Breillat from 001.jma (sprite 1170)
	var breillat_tex: ImageTexture = loader.get_npc_texture(1170, 0)
	if not breillat_tex:
		print("FAILED: NPC sprite 1170 (Breillat) returned null!")
		quit(1)
		return
	print("SUCCESS: NPC sprite 1170 (Breillat) -> Size: ", breillat_tex.get_size())
	
	# NPC model from 007.jma (sprite 7000)
	var npc_7000_tex: ImageTexture = loader.get_npc_texture(7000, 0)
	if not npc_7000_tex:
		print("FAILED: NPC sprite 7000 from 007.jma returned null!")
		quit(1)
		return
	print("SUCCESS: NPC sprite 7000 (007.jma) -> Size: ", npc_7000_tex.get_size())
	
	# Clean error fallback for invalid sprite
	var invalid_tex: ImageTexture = loader.get_npc_texture(999999, 0)
	assert(invalid_tex == null, "Invalid sprite_id must return null")
	print("SUCCESS: Invalid sprite_id 999999 cleanly returned null")
	
	# 4. Verify MapRenderer camera limits and background size
	print("\n--- Verifying MapRenderer camera limits and background size ---")
	var MapRendererScript = load("res://scripts/map/map_renderer.gd")
	if not MapRendererScript:
		print("FAILED: Could not load map_renderer.gd")
		quit(1)
		return
	
	# Create MapRenderer and Camera2D under a parent Node2D
	var world_node := Node2D.new()
	root.add_child(world_node)
	
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	world_node.add_child(cam)
	
	var map_renderer = MapRendererScript.new()
	map_renderer.archive_loader = loader
	world_node.add_child(map_renderer)
	
	for map_id in [10001, 10075, 10202]:
		map_renderer.load_map(map_id)
		var bg_sz: Vector2 = map_renderer.get_map_pixel_size()
		print("MapRenderer loaded map %d -> background_size: %s, camera limits: [L:%d, R:%d, T:%d, B:%d]" % [
			map_id, bg_sz, cam.limit_left, cam.limit_right, cam.limit_top, cam.limit_bottom
		])
		assert(bg_sz.x > 0 and bg_sz.y > 0, "MapRenderer background size must be positive")
		assert(cam.limit_right >= int(bg_sz.x), "Camera right limit must cover map width")
		assert(cam.limit_bottom >= int(bg_sz.y), "Camera bottom limit must cover map height")
	
	print("\n--- ALL TESTS PASSED SUCCESSFULLY! ---")
	quit(0)
