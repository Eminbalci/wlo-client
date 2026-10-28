extends SceneTree
func _init():
	var gp = load("res://scripts/map/ground_parser.gd").new()
	var gmap = gp.load_map(12000)
	if gmap:
		print("Map 12000 size: ", gmap.width_px, "x", gmap.height_px, " default_spawn: ", gmap.default_spawn, " triggers: ", gmap.triggers.size())
		for t in gmap.triggers:
			print("trigger eid: ", t.event_id, " pos: (", t.world_x, ", ", t.world_y, ")")
	quit()
