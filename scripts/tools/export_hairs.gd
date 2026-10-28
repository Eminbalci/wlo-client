extends SceneTree

func _init() -> void:
	var loader = load("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	for hair in ["4100.jmp", "4101.jmp", "4102.jmp", "4103.jmp"]:
		var equip = {
			"clothes": {"jma": "004e.jma", "jmp": "4300.jmp"},
			"shoes": {"jma": "004s.jma", "jmp": "4400.jmp"},
			"hair": {"jma": "004h.jma", "jmp": hair}
		}
		var frames = loader.get_player_composite_frames(6, equip)
		if not frames.is_empty() and frames.size() > 48:
			var img = frames[48].get_image()
			var out = "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/daniel_hair_" + hair.replace(".jmp", "") + ".png"
			img.save_png(out)
			print("Saved: " + out)
	quit(0)
