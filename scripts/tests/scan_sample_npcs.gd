extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	var jma_files = ["001.jma", "007.jma"]
	var sample_jmps = [
		"1000.jmp", "1001.jmp", "1009.jmp", "1010.jmp", "1012.jmp", "1020.jmp",
		"1029.jmp", "1035.jmp", "1037.jmp", "1038.jmp", "1050.jmp", "1068.jmp",
		"1088.jmp", "1089.jmp", "1100.jmp", "1170.jmp", "1200.jmp", "1207.jmp"
	]
	
	for jmp in sample_jmps:
		var anim = null
		for jma in jma_files:
			anim = loader.get_jma_animation(jma, jmp)
			if anim and not anim.frames.is_empty():
				break
		if not anim or anim.frames.is_empty():
			continue
			
		var max_b = 0
		for f in anim.frames:
			var b = f.pivot_y + f.height
			if b > max_b: max_b = b
			
		var stand_b = 0
		var start_i = 32 if anim.frames.size() >= 64 else (16 if anim.frames.size() >= 32 else 0)
		for i in range(start_i, min(start_i + 8, anim.frames.size())):
			var b = anim.frames[i].pivot_y + anim.frames[i].height
			if b > stand_b: stand_b = b
			
		print(jmp, " total_frames=", anim.frames.size(), " stand_bottom_y=", stand_b, " max_bottom_y=", max_b)
		
	quit(0)
