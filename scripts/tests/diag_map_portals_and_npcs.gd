extends SceneTree

func _init() -> void:
	print("=== DIAGNOSTIC: MAP PORTALS & NPCS ===")
	var ground_parser = preload("res://scripts/map/ground_parser.gd").new()
	var eve_parser = ground_parser.eve_parser
	var game_db = preload("res://scripts/database/game_database.gd").new()

	var test_maps = [10001, 10002, 10003, 10011, 12000, 12001, 12002, 12003, 12004, 12005, 60000, 60001]
	
	for mid in test_maps:
		print("\n--- MAP %d ---" % mid)
		var portals = ground_parser.get_map_warp_portals(mid)
		print("  Portals count: %d" % portals.size())
		for p in portals:
			print("    Portal: id=%s, name='%s', pos=%s, target_map=%s, target_coords=%s, style=%s" % [
				p.get("portal_id"), p.get("portal_name"), p.get("world_pos"), p.get("target_map_id"), p.get("target_coords"), p.get("portal_style")
			])
		
		var npcs = eve_parser.get_npcs_for_map(mid) if eve_parser else []
		print("  Eve.emg NPCs count: %d" % npcs.size())
		for n in npcs:
			var rec = game_db.npcs.get_npc(n.npc_id) if game_db.npcs else null
			var disp_name = rec.name if rec else n.name
			print("    NPC: click_id=%d, template_id=%d, raw_name='%s', db_name='%s', pos=(%d, %d)" % [
				n.click_id, n.npc_id, n.name, disp_name, n.world_x, n.world_y
			])
	
	print("\n=== DIAGNOSTIC FINISHED ===")
	quit(0)
