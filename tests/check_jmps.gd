extends SceneTree

func _init() -> void:
	var ArchiveLoaderClass = load("res://scripts/core/archive_loader.gd")
	var l = ArchiveLoaderClass.new()
	var jmps = ['1038.jmp', '1010.jmp', '1068.jmp', '1131.jmp', '1144.jmp', '1050.jmp', '1207.jmp', '1037.jmp', '1223.jmp', '1221.jmp', '1155.jmp', '11000.jmp']
	for j in jmps:
		var a = l.get_jma_animation('001.jma', j)
		print(j, ': ', a.frames.size() if a else 'none')
	
	# Also test player role 6 (Daniel) or 2 (Betty) in 004.jma / 003.jma
	var role_jmps = ['004.jma:4000.jmp', '003.jma:3000.jmp', '002.jma:2000.jmp', '005.jma:5000.jmp']
	for rj in role_jmps:
		var parts = rj.split(':')
		var a = l.get_jma_animation(parts[0], parts[1])
		print(rj, ': ', a.frames.size() if a else 'none')
	
	var JmaParserClass = load("res://scripts/core/jma_parser.gd")
	var p7 = JmaParserClass.open_jma('assets/data/007.jma')
	if p7:
		var fl = p7.get_file_list()
		print("007.jma total files: ", fl.size())
		if fl.size() > 0:
			print("Sample 007.jma files: ", fl.slice(0, 10))
			var a7 = p7.parse_jmp(fl[0])
			print("007.jma first file frames: ", a7.frames.size() if a7 else 'none')

	quit()
