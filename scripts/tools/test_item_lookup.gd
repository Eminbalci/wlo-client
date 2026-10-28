extends SceneTree

func _init() -> void:
	var gdb = load("res://scripts/database/game_database.gd").new()
	root.add_child(gdb)
	gdb.load_all()
	
	var test_ids = [21001, 21002, 21003, 21004, 21005, 24001, 24002, 24003, 24004, 24005, 11033]
	for id in test_ids:
		var item = gdb.items.get_item(id)
		if item:
			print("Item %d: name='%s', icon_id=%d, large_icon_id=%d, type=%d, equip_pos=%d" % [
				item.id, item.name, item.icon_id, item.large_icon_id, item.item_type, item.equip_pos
			])
		else:
			print("Item %d: NOT FOUND" % id)
	
	quit(0)
