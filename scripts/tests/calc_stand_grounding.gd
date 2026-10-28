extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	var jmps = [
		"1000.jmp", "1001.jmp", "1009.jmp", "1010.jmp", "1012.jmp", "1020.jmp",
		"1029.jmp", "1035.jmp", "1037.jmp", "1038.jmp", "1050.jmp", "1068.jmp",
		"1088.jmp", "1089.jmp", "1100.jmp", "1170.jmp", "1200.jmp", "1207.jmp"
	]
	
	for jmp in jmps:
		var anim = loader.get_jma_animation("001.jma", jmp)
		if not anim or anim.frames.is_empty():
			anim = loader.get_jma_animation("007.jma", jmp)
		if not anim or anim.frames.is_empty():
			continue
			
		var total = anim.frames.size()
		var stand_indices = []
		if total >= 64:
			for i in range(32, min(64, total)): stand_indices.append(i)
		elif total == 32:
			var base = 0 if anim.frames[0].name.begins_with("08") else 16
			for i in range(base, min(base + 16, total)): stand_indices.append(i)
		elif total == 16:
			for i in range(total): stand_indices.append(i)
		elif total == 8:
			var base = 4 if anim.frames[0].name.begins_with("01") else 0
			for i in range(base, total): stand_indices.append(i)
		else:
			for i in range(total): stand_indices.append(i)
			
		var sum_bottom = 0.0
		var max_bottom = 0.0
		var min_bottom = 999.0
		for idx in stand_indices:
			var f = anim.frames[idx]
			var b = float(f.pivot_y + f.height)
			sum_bottom += b
			if b > max_bottom: max_bottom = b
			if b < min_bottom: min_bottom = b
		var avg_bottom = sum_bottom / float(stand_indices.size())
		
		# Also find lowest non-transparent pixel across stand frames on 128 canvas
		var canvas_lowest = 0
		for idx in stand_indices:
			var tex128 = loader.get_jma_frame_128("001.jma", jmp, idx)
			if not tex128:
				tex128 = loader.get_jma_frame_128("007.jma", jmp, idx)
			if tex128:
				var img = tex128.get_image()
				for y in range(img.get_height() - 1, -1, -1):
					var row_has = false
					for x in range(img.get_width()):
						if img.get_pixel(x, y).a > 0.1:
							row_has = true
							break
					if row_has:
						if y > canvas_lowest: canvas_lowest = y
						break
						
		print("%s (frames=%d, bound=%dx%d): stand_bottom avg=%.1f [min=%.1f, max=%.1f], canvas_lowest=%d" % [
			jmp, total, anim.frames[0].bound_w, anim.frames[0].bound_h, avg_bottom, min_bottom, max_bottom, canvas_lowest
		])

	quit(0)
