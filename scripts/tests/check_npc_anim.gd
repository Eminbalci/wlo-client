extends SceneTree

const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var al = ArchiveLoaderClass.new()
	root.add_child(al)
	al._ready()
	
	var a = al.get_jma_animation("007.jma", "7006.jmp")
	if a:
		print("--- 7006.jmp total frames: ", a.frames.size())
		for i in [0, 1, 2, 3, 4, 8, 16, 24, 32, 33, 34, 35, 40, 48, 56, 64]:
			if i < a.frames.size():
				var f = a.frames[i]
				print("Frame %d: %s (%dx%d)" % [i, f.name, f.width, f.height])
	var a2 = al.get_jma_animation("007.jma", "7035.jmp")
	if a2:
		print("--- 7035.jmp total frames: ", a2.frames.size())
	quit(0)
