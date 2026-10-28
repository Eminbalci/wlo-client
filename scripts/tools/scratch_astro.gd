extends SceneTree
func _init():
	var loader = load("res://scripts/core/archive_loader.gd").new()
	loader.initialize_archives()
	var tex = loader.get_npc_texture(1029, 5)
	if tex:
		print("get_npc_texture(1029, 5) size: ", tex.get_size())
	else:
		print("get_npc_texture(1029, 5) returned NULL!")
	quit()
