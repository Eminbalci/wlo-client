extends SceneTree

const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var loader: Node = ArchiveLoaderScript.new()
	root.add_child(loader)
	loader.initialize_archives()
	
	var anim_body = loader.get_jma_animation("004.jma", "4000.jmp")
	var anim_clothes = loader.get_jma_animation("004e.jma", "4300.jmp")
	var anim_shoes = loader.get_jma_animation("004s.jma", "4400.jmp")
	var anim_hair = loader.get_jma_animation("004h.jma", "4101.jmp")
	var anim_weapon = loader.get_jma_animation("004w.jma", "4040.jmp")
	
	var fb = anim_body.get_frame(48)
	var fc = anim_clothes.get_frame(48)
	var fs = anim_shoes.get_frame(48)
	var fh = anim_hair.get_frame(48)
	var fw = anim_weapon.get_frame(48)
	
	print("BODY:   w=", fb.width, " h=", fb.height, " px=", fb.pivot_x, " py=", fb.pivot_y, " bw=", fb.bound_w, " bh=", fb.bound_h)
	if fc: print("CLOTH:  w=", fc.width, " h=", fc.height, " px=", fc.pivot_x, " py=", fc.pivot_y, " bw=", fc.bound_w, " bh=", fc.bound_h)
	if fs: print("SHOES:  w=", fs.width, " h=", fs.height, " px=", fs.pivot_x, " py=", fs.pivot_y, " bw=", fs.bound_w, " bh=", fs.bound_h)
	if fh: print("HAIR:   w=", fh.width, " h=", fh.height, " px=", fh.pivot_x, " py=", fh.pivot_y, " bw=", fh.bound_w, " bh=", fh.bound_h)
	if fw: print("WEAPON: w=", fw.width, " h=", fw.height, " px=", fw.pivot_x, " py=", fw.pivot_y, " bw=", fw.bound_w, " bh=", fw.bound_h)
	
	# Let's inspect other frames for body and weapon!
	# For instance, frame 0 (Walk North), frame 32 (Stand North), frame 48 (Stand South)
	for idx in [0, 8, 16, 24, 32, 40, 48, 56]:
		var b = anim_body.get_frame(idx)
		var w = anim_weapon.get_frame(idx)
		print("Frame ", idx, " (", b.name, "): body_pivot=(", b.pivot_x, ",", b.pivot_y, ") weapon_pivot=(", w.pivot_x, ",", w.pivot_y, ") weapon_name=", w.name)

	quit()
