extends SceneTree

var _done: bool = false

func _process(_delta: float) -> bool:
	if _done:
		return true
	var loader = root.get_node_or_null("ArchiveLoader")
	if not loader:
		return false
	_done = true
	
	print("--- Running Daniel composite test ---")
	var body_anim = loader.get_jma_animation("004.jma", "4000.jmp")
	var hair_anim = loader.get_jma_animation("004h.jma", "4100.jmp")
	var clothes_anim = loader.get_jma_animation("004e.jma", "4300.jmp")
	var shoes_anim = loader.get_jma_animation("004s.jma", "4400.jmp")
	
	print("Anims: body=%s, hair=%s, clothes=%s, shoes=%s" % [
		body_anim != null, hair_anim != null, clothes_anim != null, shoes_anim != null
	])
	
	var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	for anim in [body_anim, hair_anim, clothes_anim, shoes_anim]:
		var jf = anim.get_frame(48)
		var img = anim.decode_frame_image(48)
		if img and jf:
			print("Drawing %s at pivot (%d, %d), size (%d, %d)" % [
				anim.name, jf.pivot_x, jf.pivot_y, jf.width, jf.height
			])
			canvas.blend_rect(img, Rect2i(0, 0, jf.width, jf.height), Vector2i(jf.pivot_x, jf.pivot_y))
	
	canvas.save_png("C:/Users/muham/AppData/Local/Temp/daniel_composite_48.png")
	print("Successfully saved daniel_composite_48.png")
	quit(0)
	return true
