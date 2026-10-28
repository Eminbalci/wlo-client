extends SceneTree

func _init() -> void:
	var ArchiveLoaderClass = load("res://scripts/core/archive_loader.gd")
	var l = ArchiveLoaderClass.new()
	var a = l.get_jma_animation('001.jma', '1010.jmp')
	if a:
		print("1010.jmp frames count: ", a.frames.size())
		var names = []
		for i in range(a.frames.size()):
			names.append(str(i) + ":" + a.frames[i].name)
		for chunk in range(0, names.size(), 16):
			var end_idx = mini(chunk + 16, names.size())
			print("Frames ", chunk, "..", end_idx - 1, ": ", ", ".join(names.slice(chunk, end_idx)))
	quit()
