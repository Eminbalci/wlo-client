extends SceneTree

const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var al = ArchiveLoaderClass.new()
	root.add_child(al)
	al._ready()
	
	var anim = al.get_jma_animation("002.jma", "2000.jmp")
	if anim:
		for dir in range(8):
			var fidx = dir * 4
			var frame_tex = anim.decode_frame(fidx)
			if frame_tex:
				var img = frame_tex.get_image()
				img.save_png("C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/daniel_dir_%d.png" % dir)
				print("Saved daniel_dir_%d.png from frame %d (%s)" % [dir, fidx, anim.frames[fidx].name])
	quit(0)
