extends SceneTree
func _init():
	var EveParser = load("res://scripts/map/eve_parser.gd")
	var eve = EveParser.new()
	eve.initialize()
	for sp in eve.get_npcs_for_map(12000):
		if sp.npc_id in [14141, 14140, 14118]:
			print("NPC ", sp.name.strip_edges(), " id=", sp.npc_id, " click=", sp.click_id, " events=", sp.events)
	var evs = eve.get_events_for_map(12000)
	print("EVENTS ", evs.size())
	var want := {}
	for sp in eve.get_npcs_for_map(12000):
		if sp.npc_id in [14141, 14140, 14118]:
			for e in sp.events: want[e] = true
	for ev in evs:
		if want.has(ev["click_id"]):
			print("EV ", ev["click_id"], " ", ev["name"].strip_edges())
			for sub in ev["subs"]:
				print("   sub ", sub["index"], " cond=", sub["cond_byte"], " w=", sub["words"], " ops=", sub["ops"].size())
				for op in sub["ops"]:
					print("      op", op["index"], " code=", op["opcode"], " d=", [op["d1"], op["d2"], op["d3"], op["d4"]])
	quit()
