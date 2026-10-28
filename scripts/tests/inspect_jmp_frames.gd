extends SceneTree

const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var al = ArchiveLoaderClass.new()
	root.add_child(al)
	al._ready()
	
	var anim = al.get_jma_animation("002.jma", "2000.jmp")
	if anim:
		print("--- 2000.jmp Frames: Total ", anim.frames.size(), " ---")
		for i in range(anim.frames.size()):
			var f = anim.frames[i]
			print("Frame %d: name='%s' size=%dx%d pivot=(%d,%d)" % [
				i, f.name, f.width, f.height, f.pivot_x, f.pivot_y
			])
	else:
		print("Failed to load 2000.jmp")
	quit(0)
