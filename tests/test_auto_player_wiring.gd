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

	var before: Vector2 = hud.player.global_position if hud.player else Vector2.ZERO
	runner.apply({"action": AutoPlayerController.ACTION_MOVE}, null)
	_record(hud.player == null or hud.player.is_moving or hud.player.global_position != before, "a move decision walks the player")
	inst.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
