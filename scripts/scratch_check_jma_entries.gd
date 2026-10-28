extends SceneTree

func _init() -> void:
	var jma4 = JmaParser.open_jma("D:/GitHub/WLRI/jma/004.jma")
	if jma4:
		var anim = jma4.parse_jmp("4000.jmp")
		if anim:
			print("Total frames: ", anim.frames.size())
			var names = []
			for i in range(anim.frames.size()):
				names.append(anim.frames[i].name)
			print("Frame names: ", names)
	quit()
