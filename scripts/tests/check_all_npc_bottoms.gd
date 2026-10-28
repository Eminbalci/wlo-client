extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	var jmps = [
		["001.jma", "1038.jmp", "Captain Robinson"],
		["001.jma", "1037.jmp", "Sailor"],
		["001.jma", "1009.jmp", "Girl"],
		["001.jma", "1010.jmp", "Jack"],
		["001.jma", "1012.jmp", "Visitor"],
		["001.jma", "1029.jmp", "Astrologian"],
		["001.jma", "1035.jmp", "Cat"],
		["001.jma", "1207.jmp", "Ross"]
	]
	
	for entry in jmps:
		var jma = entry[0]
		var jmp = entry[1]
		var name = entry[2]
		var anim = loader.get_jma_animation(jma, jmp)
		if not anim or anim.frames.is_empty():
			print(name, " (", jmp, "): NOT FOUND")
			continue
			
		var max_bottom = 0
		var min_bottom = 999
		var bottoms = []
		for f in anim.frames:
			var b = f.pivot_y + f.height
			bottoms.append(b)
			if b > max_bottom: max_bottom = b
			if b < min_bottom: min_bottom = b
			
		# Check stand frames (e.g. 16..31 or 32..47)
		var stand_bottoms = []
		var start_idx = 32 if anim.frames.size() >= 64 else (16 if anim.frames.size() >= 32 else 0)
		for i in range(start_idx, min(start_idx + 16, anim.frames.size())):
			var f = anim.frames[i]
			stand_bottoms.append(f.pivot_y + f.height)
			
		print(name, " (", jmp, ", frames=", anim.frames.size(), "):")
		print("  all frames bottom_y: min=", min_bottom, " max=", max_bottom)
		print("  stand frames bottom_y: ", stand_bottoms)

	quit(0)
