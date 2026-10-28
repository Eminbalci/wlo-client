extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	var anim = loader.get_jma_animation("001.jma", "1029.jmp")
	if anim:
		for i in [52, 53, 54, 55]:
			if i < anim.frames.size():
				var f = anim.frames[i]
				print("  Frame ", i, ": name=", f.name, " size=(", f.width, ", ", f.height, ") pivot=(", f.pivot_x, ", ", f.pivot_y, ") bottom_y=", f.pivot_y + f.height)
	quit(0)
