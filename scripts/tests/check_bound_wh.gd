extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	for jmp in ["1088.jmp", "1035.jmp", "1029.jmp"]:
		var anim = loader.get_jma_animation("001.jma", jmp)
		if anim:
			var f = anim.frames[0]
			print(jmp, " frame 0: bound=(", f.bound_w, ", ", f.bound_h, ") pivot=(", f.pivot_x, ", ", f.pivot_y, ") size=(", f.width, ", ", f.height, ")")
			var tex = loader.get_npc_texture(jmp.to_int(), 0)
			if tex:
				print("  get_npc_texture size: ", tex.get_size())
	quit(0)
