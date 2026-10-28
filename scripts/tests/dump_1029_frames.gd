extends SceneTree

func _init() -> void:
	var loader = preload("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	var anim = loader.get_jma_animation("001.jma", "1029.jmp")
	if not anim:
		print("No anim")
		quit(1)
		return
		
	var out_dir = "C:/Users/muham/.gemini/antigravity-cli/brain/f4319d9e-1891-486f-bd28-8da4aaa87b17/frames_1029"
	DirAccess.make_dir_absolute(out_dir)
	
	print("Dumping frames for 1029.jmp...")
	for i in range(anim.frames.size()):
		var f = anim.frames[i]
		var tex128 = loader.get_jma_frame_128("001.jma", "1029.jmp", i)
		if tex128:
			var img = tex128.get_image()
			img.save_png("%s/f128_%02d_%s.png" % [out_dir, i, f.name.replace(".", "_")])
			
		var raw_img = anim.decode_frame_image(i)
		if raw_img:
			raw_img.save_png("%s/raw_%02d_%s.png" % [out_dir, i, f.name.replace(".", "_")])
			
	print("Dumped ", anim.frames.size(), " frames to ", out_dir)
	quit(0)
