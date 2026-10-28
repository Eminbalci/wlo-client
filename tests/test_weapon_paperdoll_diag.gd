extends SceneTree

const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")
const GameDatabaseScript = preload("res://scripts/database/game_database.gd")

func _init() -> void:
	print("--- Running test_weapon_paperdoll_diag.gd ---")
	var loader: Node = root.get_node_or_null("ArchiveLoader")
	if not loader:
		loader = ArchiveLoaderScript.new()
		root.add_child(loader)
		loader.initialize_archives()
	
	var gdb: Node = root.get_node_or_null("GameDatabase")
	if not gdb:
		gdb = GameDatabaseScript.new()
		root.add_child(gdb)
		gdb.load_all()
	
	var parser_004w = loader._jma_archives.get("004w.jma")
	if parser_004w:
		print("004w.jma entry count:", parser_004w._entries.size())
		var sample_keys = parser_004w._entries.keys().slice(0, 30)
		print("004w.jma sample entries:", sample_keys)
	else:
		print("004w.jma NOT loaded in _jma_archives")
		
	var parser_003w = loader._jma_archives.get("003w.jma")
	if parser_003w:
		print("003w.jma entry count:", parser_003w._entries.size())
		var sample_keys = parser_003w._entries.keys().slice(0, 30)
		print("003w.jma sample entries:", sample_keys)

	# Check matching JMPs
	if parser_004w:
		for jmp_name in parser_004w._entries.keys():
			if "4040" in jmp_name or "3040" in jmp_name or "040" in jmp_name:
				print("004w matching jmp:", jmp_name)
	if parser_003w:
		for jmp_name in parser_003w._entries.keys():
			if "4040" in jmp_name or "3040" in jmp_name or "040" in jmp_name:
				print("003w matching jmp:", jmp_name)

	# Let's inspect weapon animations
	var anim_004w = loader.get_jma_animation("004w.jma", "4040.jmp")
	if anim_004w:
		print("004w 4040.jmp total frames:", anim_004w.frames.size())
		var f48 = anim_004w.get_frame(48)
		if f48:
			print("004w 4040.jmp frame 48:", "name=", f48.name, "w=", f48.width, "h=", f48.height, "px=", f48.pivot_x, "py=", f48.pivot_y, "bw=", f48.bound_w, "bh=", f48.bound_h)
		var f0 = anim_004w.get_frame(0)
		if f0:
			print("004w 4040.jmp frame 0:", "name=", f0.name, "w=", f0.width, "h=", f0.height, "px=", f0.pivot_x, "py=", f0.pivot_y, "bw=", f0.bound_w, "bh=", f0.bound_h)

	var anim_003w = loader.get_jma_animation("003w.jma", "3040.jmp")
	if anim_003w:
		print("003w 3040.jmp total frames:", anim_003w.frames.size())
		var f48 = anim_003w.get_frame(48)
		if f48:
			print("003w 3040.jmp frame 48:", "name=", f48.name, "w=", f48.width, "h=", f48.height, "px=", f48.pivot_x, "py=", f48.pivot_y, "bw=", f48.bound_w, "bh=", f48.bound_h)

	# Also let's check body frames for role 6 and role 2 at frame 48
	var anim_004 = loader.get_jma_animation("004.jma", "4000.jmp")
	if anim_004:
		var f48 = anim_004.get_frame(48)
		if f48:
			print("004 4000.jmp body frame 48:", "name=", f48.name, "w=", f48.width, "h=", f48.height, "px=", f48.pivot_x, "py=", f48.pivot_y)

	var anim_003 = loader.get_jma_animation("003.jma", "3000.jmp")
	if anim_003:
		var f48 = anim_003.get_frame(48)
		if f48:
			print("003 3000.jmp body frame 48:", "name=", f48.name, "w=", f48.width, "h=", f48.height, "px=", f48.pivot_x, "py=", f48.pivot_y)

	quit()
