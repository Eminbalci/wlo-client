extends SceneTree

func _init() -> void:
	var loader = load("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	var tests = [
		["002f.jma", "2600.jmp"],
		["003f.jma", "3600.jmp"],
		["004f.jma", "4600.jmp"],
		["005f.jma", "5600.jmp"]
	]
	
	for t in tests:
		var anim = loader.get_jma_animation(t[0], t[1])
		print("%s:%s -> %s" % [t[0], t[1], "FOUND" if anim != null else "MISSING"])
	
	quit(0)
