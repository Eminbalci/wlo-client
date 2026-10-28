extends SceneTree

const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var al = ArchiveLoaderClass.new()
	root.add_child(al)
	al._ready()
	var anim = al.get_jma_animation("002.jma", "2000.jmp")
	if anim:
		for i in [0, 4, 8, 12, 16, 20, 24, 28]:
			var dir_idx: int = i / 4
			var tex: ImageTexture = anim.decode_frame(i)
			if tex:
				var img: Image = tex.get_image()
				img.save_png("C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/dir_%d.png" % dir_idx)
		print("Successfully saved dir_0.png .. dir_7.png")
	else:
		print("Failed to load 2000.jmp")
	quit(0)
