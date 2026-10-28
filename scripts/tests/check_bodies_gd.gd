extends SceneTree

func _init() -> void:
	var loader_script = load("res://scripts/core/archive_loader.gd")
	var loader = loader_script.new()
	get_root().add_child(loader)
	
	print("Checking ArchiveLoader bodies...")
	for rid in [1, 2, 3, 4, 5, 6]:
		var jma_name = "%03d.jma" % rid
		var jmp_name = "%d000.jmp" % rid
		var anim = loader.get_jma_animation(jma_name, jmp_name)
		if anim:
			print("JMA %s with %s: Found! Frame count = %d" % [jma_name, jmp_name, anim.frame_count])
		else:
			print("JMA %s with %s: NOT FOUND" % [jma_name, jmp_name])
	quit()
