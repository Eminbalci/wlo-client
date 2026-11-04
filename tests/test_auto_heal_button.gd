extends SceneTree

## Status dock "+" button: uses the first HP/SP restoring item in the bag (real client tooltip
## "Restore HP/SP using Potions and Bottles").

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _run() -> void:
	print("--- Auto Heal Button Suite ---")
	await process_frame
	await process_frame

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	var inv = hud.inventory_ctrl
	var ccs = hud.character_status_ctrl

	_record(hud.get_node_or_null("PlayerStatusDock/AutoHealButton") != null, "the status dock has the \"+\" button")

	# Bag with no restoring item: the button does nothing.
	inv.inventory_data.assign([{"id": 34038, "name": "Notepad", "count": 1}])
	_record(inv.find_auto_heal_slot() == -1, "no restoring item means no slot")
	_record(inv.auto_heal_from_bag() == false, "the button reports nothing to use")

	# Bag with a restoring item in slot 1.
	inv.inventory_data.assign([
		{"id": 34038, "name": "Notepad", "count": 1},
		{"id": 32011, "name": "Potion", "count": 2, "hp_restore": 50},
	])
	_record(inv.find_auto_heal_slot() == 1, "the first restoring item is found (slot 1)")

	ccs.current_hp = 10
	var before: int = int(ccs.current_hp)
	var used: bool = inv.auto_heal_from_bag()
	for i in range(3):
		await process_frame
	_record(used, "the button uses an item when one is in the bag")
	_record(int(ccs.current_hp) > before, "HP goes up after the button (%d -> %d)" % [before, int(ccs.current_hp)])
	_record(int(inv.inventory_data[1].get("count", 0)) == 1, "one potion is used up (2 -> 1)")

	# The "+" button press itself.
	ccs.current_hp = 10
	var btn: Button = hud.get_node_or_null("PlayerStatusDock/AutoHealButton") as Button
	if btn:
		btn.pressed.emit()
	for i in range(3):
		await process_frame
	_record(int(ccs.current_hp) > 10, "pressing the \"+\" button restores HP")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
