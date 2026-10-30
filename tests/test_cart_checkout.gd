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
	shop.cart_entries.clear()
	_record(shop.add_to_cart(32011, 2), "add Bread x2 to the cart")
	_record(shop.add_to_cart(32011, 1), "adding Bread again raises its amount")
	_record(shop.cart_entries.size() == 1 and int(shop.cart_entries[0].get("amount", 0)) == 3, "cart holds one Bread line with amount 3")
	_record(shop.add_to_cart(32002, 1), "add Rice Wine x1 to the cart")
	var cart_total: int = shop.show_cart()
	_record(cart_total == 80, "cart total is 3 x 10 + 1 x 50 = 80 (%d)" % cart_total)
	_record(shop._cart_parts["root"].visible, "cart panel is shown")
	shop.hide_cart()
	_record(not shop._cart_parts["root"].visible, "cart panel can be hidden")
	# Real client: clicking a buy row adds one to the purchase list (same item stacks)
	shop.cart_entries.clear()
	shop.set_mode("buy")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	shop._on_slot_gui_input(click, 0)
	shop._on_slot_gui_input(click, 0)
	shop._on_slot_gui_input(click, 1)
	_record(shop.cart_entries.size() == 2, "two buy-row clicks on different items make two purchase-list lines")
	_record(int(shop.cart_entries[0].get("amount", 0)) == 2, "clicking the same row twice stacks it to 2 (real: Bread x2)")
	var purchase_total: int = shop.show_cart()
	_record(purchase_total == 70, "purchase amount is 2 x 10 + 1 x 50 = 70 (%d)" % purchase_total)
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
