extends SceneTree

func _init() -> void:
	var loader_script = load("res://scripts/core/archive_loader.gd")
	var loader = loader_script.new()
	get_root().add_child(loader)
	
	print("--- Testing Role 2 composite with 002 vs 003 ---")
	
	# Check 002.jma
	var anim_002 = loader.get_jma_animation("002.jma", "2000.jmp")
	print("002.jma 2000.jmp anim:", anim_002 != null)
	var anim_002h = loader.get_jma_animation("002h.jma", "2100.jmp")
	print("002h.jma 2100.jmp anim:", anim_002h != null)
	var anim_002e = loader.get_jma_animation("002e.jma", "2300.jmp")
	print("002e.jma 2300.jmp anim:", anim_002e != null)
	var anim_002s = loader.get_jma_animation("002s.jma", "2400.jmp")
	print("002s.jma 2400.jmp anim:", anim_002s != null)
	
	# Check 003.jma
	var anim_003 = loader.get_jma_animation("003.jma", "3000.jmp")
	print("003.jma 3000.jmp anim:", anim_003 != null)
	var anim_003h = loader.get_jma_animation("003h.jma", "3101.jmp")
	print("003h.jma 3101.jmp anim:", anim_003h != null)
	var anim_003e = loader.get_jma_animation("003e.jma", "3301.jmp")
	print("003e.jma 3301.jmp anim:", anim_003e != null)
	var anim_003s = loader.get_jma_animation("003s.jma", "3401.jmp")
	print("003s.jma 3401.jmp anim:", anim_003s != null)
	
	quit()
