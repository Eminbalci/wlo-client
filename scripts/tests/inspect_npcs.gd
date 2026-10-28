extends SceneTree

const NpcDatabase = preload("res://scripts/database/npc_database.gd")

func _init() -> void:
	var npcs = NpcDatabase.new()
	npcs.load_from_file("res://assets/data/Npc.dat")
	
	var ids = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
	print("--- Map 10001 NPC Details from Npc.dat ---")
	for id in ids:
		var npc = npcs.get_npc(id)
		if npc:
			print("NPC ID %d: Name='%s', Level=%d" % [npc.id, npc.name, npc.level])
		else:
			print("NPC ID %d not found" % id)
	quit(0)
