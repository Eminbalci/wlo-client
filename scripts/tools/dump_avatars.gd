extends SceneTree

func _init() -> void:
	var loader = load("res://scripts/core/archive_loader.gd").new()
	root.add_child(loader)
	
	for i in range(1, 15):
		var frames = loader.get_avatar_frames(i)
		if not frames.is_empty():
			var img = frames[0].get_image()
			img.save_png("C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/avatar_role_" + str(i) + ".png")
			print("Role " + str(i) + " size: " + str(img.get_size()))
	quit(0)
