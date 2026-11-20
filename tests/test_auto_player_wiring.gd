extends SceneTree

## AutoPlayer wiring in the HUD: a move decision walks the player, and a supply decision uses the first
## bag item whose name reads like a supply.

const AutoPlayerController = preload("res://scripts/ui/hud/auto_player_controller.gd")

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
	print("--- AutoPlayer Wiring Suite ---")
	await process_frame
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	var runner = hud.make_auto_player_runner()
	_record(runner.on_move.is_valid() and runner.on_use_supply.is_valid(), "the runner gets both HUD callables")
	for i in range(hud.inventory_ctrl.inventory_data.size()):
		hud.inventory_ctrl.inventory_data[i] = {}
	_record(hud.find_supply_slot() == -1, "an empty bag has no supply slot")

	var db := root.get_node("/root/GameDatabase")
	var potion_id := 0
	for id in db.items.get_all_items().keys():
		var rec = db.items.get_item(int(id))
		if rec and int(rec.equip_pos) == 8:
			potion_id = int(id)
			break
	_record(potion_id > 0, "the item database has a battle consumable (equip slot 8) to test with")
	hud.inventory_ctrl.inventory_data[2] = {"id": potion_id, "count": 1}
	_record(hud.find_supply_slot() == 2, "the first battle consumable in the bag is found")

	_record(hud.player != null, "the world scene has a player")
	var before: Vector2 = hud.player.global_position
	runner.apply({"action": AutoPlayerController.ACTION_MOVE}, null)
	for i in range(40):
		await create_timer(0.05).timeout
	_record(hud.player.global_position != before, "a move decision really moves the player")

	var supply_id := 0
	for id in db.items.get_all_items().keys():
		var srec = db.items.get_item(int(id))
		if srec and int(srec.equip_pos) == 8 and srec.get_hp_restore() > 0:
			supply_id = int(id)
			break
	for i in range(hud.inventory_ctrl.inventory_data.size()):
		hud.inventory_ctrl.inventory_data[i] = {}
	hud.inventory_ctrl.inventory_data[0] = {"id": supply_id, "count": 3}
	runner.apply({"action": AutoPlayerController.ACTION_USE_SUPPLY}, null)
	await create_timer(0.3).timeout
	_record(int(hud.inventory_ctrl.inventory_data[0].get("count", 0)) == 2, "a supply decision uses one item from the stack")
	inst.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
