extends SceneTree

## Training Ticket (item 34253): using it asks "Go to Training Isle?" and, on Yes, moves the
## player to Training Island (map 13050). The ticket is not consumed yet (server rules pending).

const TRAINING_TICKET_ID: int = 34253
const TRAINING_ISLAND_MAP_ID: int = 13050

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
	print("--- Training Ticket Suite ---")
	await process_frame
	await process_frame

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	var inv = hud.inventory_ctrl
	var start_map: int = int(inst.map_renderer.current_map_id)

	# Using the ticket must not teleport on its own; it asks first.
	inv.inventory_data.assign([{"id": TRAINING_TICKET_ID, "name": "Training Ticket", "count": 5}])
	var asked := {"value": false}
	hud.training_island_requested.connect(func(_m: int) -> void: asked["value"] = true)
	inv.use_or_equip_inventory_item(0)
	for i in range(3):
		await process_frame
	_record(not asked["value"], "using the ticket does not teleport before confirming")
	_record(int(inv.inventory_data[0].get("count", 0)) == 5, "the ticket is not consumed yet")

	# "No" keeps the player where they are.
	hud._on_training_island_choice(1, "No")
	for i in range(3):
		await process_frame
	_record(not asked["value"], "answering No does not start the trip")

	# "Yes" moves the player to Training Island.
	hud._on_training_island_choice(0, "Yes")
	for i in range(60):
		await process_frame
	_record(asked["value"], "answering Yes emits training_island_requested")
	_record(int(inst.map_renderer.current_map_id) == TRAINING_ISLAND_MAP_ID, "the player is on Training Island (%d -> %d)" % [start_map, int(inst.map_renderer.current_map_id)])

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
