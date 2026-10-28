extends SceneTree

func _init() -> void:
	var db := ItemDatabase.new()
	db.load_from_file("res://assets/data/Item.dat")
	
	var targets := [10031, 10032, 10033, 10056, 10057, 10058, 10060, 10084, 10106, 42008, 42011, 45001]
	for tid in targets:
		var item := db.get_item(tid)
		if item:
			print("Item %5d '%-16s': Mats=%-30s | Rank=%d" % [item.id, item.name, str(item.get_materials()), item.get_rank()])
	quit()
