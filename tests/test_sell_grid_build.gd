extends SceneTree

## The sell grid (real client: 5 x 10 bag icon grid) is built lazily on sell mode, shown there, filled from the bag, and hidden in buy mode.

var _checks := 0
var _failed := 0


func _init() -> void:
	await process_frame
	await process_frame
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _run() -> void:
	print("--- Sell Grid Build Suite ---")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()
	var shop = hud.get_or_create_shop_window()
	shop.open_shop(0, "Props Shop")
	_record(shop.sell_grid_buttons.is_empty(), "no sell grid before sell mode")
	shop.set_mode("sell")
	_record(shop.sell_grid_buttons.size() == 50, "sell mode builds 50 grid cells (%d)" % shop.sell_grid_buttons.size())
	var panel = shop.sell_panel_refs.get("panel")
	_record(panel != null and panel.visible, "sell panel exists and is visible in sell mode")
	var grid = panel.get_node_or_null("SellGrid") if panel else null
	_record(grid != null and grid.visible and grid.position == Vector2(34, 67), "sell grid sits in the panel at (34, 67)")
	_record(panel.get_node("Title").text == "Select props to sell", "sell panel title is the real client title")
	shop.set_grid_cell(shop.sell_grid_buttons[0], {"id": 32011, "count": 3, "name": "Bread"})
	_record(shop.sell_grid_buttons[0].text == "3" and shop.sell_grid_buttons[0].tooltip_text == "Bread", "filled cell shows count and name")
	shop.set_grid_cell(shop.sell_grid_buttons[1], {})
	_record(shop.sell_grid_buttons[1].disabled, "empty cell is disabled")
	# Sell mode shows the grid and fills it from the bag
	hud.inventory_ctrl.inventory_data[0] = {"id": 32011, "count": 3, "name": "Bread", "icon_id": 1011}
	shop.set_mode("sell")
	var grid2 = panel.get_node_or_null("SellGrid")
	_record(grid2 != null and panel.visible, "sell mode shows the grid")
	_record(shop.sell_grid_buttons[0].text == "3", "grid cell 0 shows the bag count (3)")
	shop.set_mode("buy")
	_record(not panel.visible, "buy mode hides the sell panel")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
