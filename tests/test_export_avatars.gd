extends SceneTree

func _init() -> void:
	var al_cls = load("res://scripts/core/archive_loader.gd")
	var loader = al_cls.new()
	loader.initialize_archives()
	for role_id in range(1, 15):
		var frames = loader.get_avatar_frames(role_id)
		print("Role ", role_id, " frames: ", frames.size())
		if frames.size() > 0:
			var img = frames[0].get_image()
			img.save_png("D:/Godot/WonderlandOnline/wonderland-online-client/assets/hud/test_avatar_role_%d.png" % role_id)
	quit(0)
