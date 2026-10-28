extends SceneTree

func _init() -> void:
	var gdb = preload("res://scripts/database/game_database.gd").new()
	gdb.load_all()
	var t_kel = gdb.talks.resolve_talk_for_npc(14062, 10003)
	print("Kelang talk: ", JSON.stringify(t_kel))
	if t_kel and not t_kel.is_empty():
		var next_id = t_kel.get("next_talk_id", 0)
		print("Kelang next talk ID: ", next_id)
		if next_id > 0:
			var next_talk = gdb.talks.get_talk(next_id)
			print("Kelang next talk: ", JSON.stringify(next_talk))
	quit()
