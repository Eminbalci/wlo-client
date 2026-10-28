extends SceneTree

func _init() -> void:
	# Load GameDatabase and ArchiveLoader singletons
	var archive_loader = preload("res://scripts/core/archive_loader.gd").new()
	archive_loader.name = "ArchiveLoader"
	root.add_child(archive_loader)
	
	var game_database = preload("res://scripts/database/game_database.gd").new()
	game_database.name = "GameDatabase"
	root.add_child(game_database)
	
	print("Instantiating MapView...")
	var map_view_scene = load("res://scenes/world/map_view.tscn")
	var map_view = map_view_scene.instantiate()
	root.add_child(map_view)
	
	# Load map 12003
	print("Loading map 12003...")
	map_view.load_map(12003)
	
	var entities = map_view.get_node_or_null("Entities")
	if not entities:
		print("ERROR: Entities node not found in map_view")
		quit(1)
		return
		
	print("Entities child count: ", entities.get_child_count())
	for child in entities.get_children():
		print("\nEntity: ", child.name, " Class: ", child.get_class(), " Script: ", child.get_script().resource_path if child.get_script() else "none")
		if child is NpcEntity:
			var npc = child as NpcEntity
			print("  npc_name: ", npc.npc_name)
			print("  npc_id: ", npc.npc_id, " sprite_id in rec: ", game_database.npcs.get_npc(npc.npc_id).sprite_id if game_database.npcs.get_npc(npc.npc_id) else "none")
			print("  world_pos: ", npc.world_position)
			print("  node position: ", npc.position)
			print("  heading: ", npc.heading)
			print("  model_jmp: ", npc.model_jmp, " model_jma: ", npc.model_jma)
			if npc.sprite:
				print("  sprite position: ", npc.sprite.position)
				print("  sprite offset: ", npc.sprite.offset)
				print("  sprite centered: ", npc.sprite.centered)
				if npc.sprite.texture:
					print("  sprite texture size: ", npc.sprite.texture.get_size())
				else:
					print("  sprite texture is null")
			if npc.nameplate:
				print("  nameplate offset_top: ", npc.nameplate.offset_top, " offset_bottom: ", npc.nameplate.offset_bottom)
			if npc.click_area:
				print("  click_area position: ", npc.click_area.position)
				
	quit(0)
