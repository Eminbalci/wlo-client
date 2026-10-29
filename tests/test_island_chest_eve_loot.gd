extends SceneTree

## Deserted island chests give the authentic Eve loot (not the hand-written table), and an opened chest does not pay again.

var _checks := 0
var _failed := 0
const EVE_CHEST_ITEMS := [32075, 32074, 32032, 32073, 41066, 48016]


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _item_ids(hud) -> Array:
	var ids := []
	for slot in hud.inventory_ctrl.inventory_data:
		if slot is Dictionary and int(slot.get("id", 0)) > 0:
			ids.append(int(slot["id"]))
	return ids


func _run() -> void:
	print("--- Island Chest Eve Loot Suite ---")
	await process_frame
	await process_frame
	var gdb = root.get_node("GameDatabase")
	gdb.active_character = {"name": "Daniel", "level": 3, "role_id": 6, "map_id": 10003, "gold": 0}
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	inst.load_map(10003)
	for i in range(60):
		await process_frame

	var hud = inst.get("hud")
	var chests: Array = []
	var entities = inst.get("entities")
	if entities:
		for c in entities.get_children():
			if c.has_meta("eve_events") and not (c.get_meta("eve_events") as Array).is_empty() and str(c.get("npc_name")).to_lower().contains("chest"):
				chests.append(c)
	_record(chests.size() > 0, "island has chest NPCs with Eve events (%d)" % chests.size())

	var received: Array = []
	for c in chests:
		var before_ids := _item_ids(hud)
		inst.call("_handle_container_npc_interaction", c)
		for i in range(10):
			await process_frame
		var after_ids := _item_ids(hud)
		var gained := []
		for it in after_ids:
			if before_ids.count(it) < after_ids.count(it) and not gained.has(it):
				gained.append(it)
		received.append(gained)

	var all_items: Array = []
	for r in received:
		for it in r:
			if not all_items.has(it):
				all_items.append(it)
	var allowed := true
	for it in all_items:
		if not EVE_CHEST_ITEMS.has(it):
			allowed = false
	_record(allowed, "every item from the chests is an authentic Eve reward: %s" % [all_items])
	_record(not all_items.has(34014), "the hand-written Tao Rice Ball (34014) is not given")

	if chests.size() > 0:
		var again_before := _item_ids(hud)
		inst.call("_handle_container_npc_interaction", chests[0])
		for i in range(10):
			await process_frame
		var again_after := _item_ids(hud)
		_record(again_after.size() == again_before.size(), "an opened chest pays nothing a second time")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
