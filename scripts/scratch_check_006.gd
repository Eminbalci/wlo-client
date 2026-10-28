extends SceneTree

func _init() -> void:
	for name in ["006.jma", "006_c01.jma", "006_c02.jma"]:
		var p = JmaParser.open_jma("D:/GitHub/WLRI/jma/" + name)
		if p:
			var files = p.get_file_list()
			print(name, " entries: ", files.size(), " sample: ", files.slice(0, 10))
	quit()
