extends SceneTree

func _init() -> void:
	var gp_script = preload("res://scripts/map/ground_parser.gd")
	var gp = gp_script.new()
	var gmap = gp.load_map(10001)
	if gmap:
		var solid_count = 0
		var center_solids = []
		for gx in range(gmap.cols):
			for gy in range(gmap.rows):
				var t = gmap.get_tile_type(gx, gy)
				if t != 0:
					solid_count += 1
					var wpos = gmap.grid_to_world(Vector2i(gx, gy))
					if wpos.x >= 800 and wpos.x <= 1300 and wpos.y >= 700 and wpos.y <= 1300:
						center_solids.append(wpos)
		print("Total solids in 10001.map: ", solid_count)
		print("Solids in center area: ", center_solids.size())
		for p in center_solids:
			print("  Solid at ", p)
	quit(0)
