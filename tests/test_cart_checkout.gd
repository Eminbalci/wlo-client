extends SceneTree

## Cart checkout buys each cart entry through the shop's buy path and deducts gold (Props Shop prices).

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
	print("--- Cart Checkout Suite ---")
	var hud = load("res://scenes/ui/hud.tscn").instantiate()
	root.add_child(hud)
	hud._ready()
	var shop = hud.get_or_create_shop_window()
	shop.open_shop(0, "Props Shop")
	hud.update_gold(500)
	shop.refresh_gold()
	var ok: bool = shop.buy_cart([{"id": 32011, "quantity": 3}, {"id": 32002, "quantity": 1}])
	_record(ok, "checkout of Bread x3 and Rice Wine x1 succeeds")
	_record(shop.player_gold == 420, "gold deducted by 30 + 50 = 80 (500 -> 420, got %d)" % shop.player_gold)
	var bad: bool = shop.buy_cart([{"id": 99999, "quantity": 1}])
	_record(not bad, "an item not in the catalog fails the checkout")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
