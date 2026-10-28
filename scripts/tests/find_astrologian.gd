extends SceneTree

func _init() -> void:
	var eve = preload("res://scripts/map/eve_parser.gd").new()
	eve.initialize()
	for map_id in eve.get_all_map_ids():
		var npcs = eve.get_npcs_for_map(map_id)
		for npc in npcs:
			if npc.npc_id == 14512 or "Astro" in npc.name:
				print("Found in map_id: ", map_id, " npc: ", npc.name, " id: ", npc.npc_id, " x: ", npc.world_x, " y: ", npc.world_y, " rot: ", npc.rotation)
	quit(0)
