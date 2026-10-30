extends SceneTree

## Headless tests for TradeWindow (Form_TradeItem_1) and TradePetWindow (Form_TradePet_1):
## decoded geometry, offer/confirm/trade flow against the offline TradePartnerStub, gold checks,
## inventory exchange, cancel.

const TradeScene = preload("res://scenes/ui/trade/trade_window.tscn")
const TradePetScene = preload("res://scenes/ui/trade/trade_pet_window.tscn")

var _fail: int = 0
var _count: int = 0


func _init() -> void:
	for n in ["ArchiveLoader:res://scripts/core/archive_loader.gd", "GameDatabase:res://scripts/database/game_database.gd"]:
		var parts: PackedStringArray = n.split(":", true, 1)
		if not root.has_node(parts[0]):
			var node: Node = load(parts[1]).new()
			node.name = parts[0]
			root.add_child(node)
	_test_trade_geometry()
	_test_trade_flow()
	_test_trade_guards_and_cancel()
	_test_pet_trade()
	print("--- %d checks, %d failed ---" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(cond: bool, name: String, detail: String = "") -> void:
	_count += 1
	if cond:
		print("  [PASS] " + name)
	else:
		_fail += 1
		printerr("  [FAIL] %s %s" % [name, detail])


func _make_inventory(gold: int) -> HUDInventory:
	var inv := HUDInventory.new()
	inv.inventory_data.resize(45)
	for i in range(45):
		inv.inventory_data[i] = {}
	inv.current_gold = gold
	inv.set_inventory_data_item(0, {"id": 32011, "icon_id": 1011, "count": 10, "name": "Bread", "equip_slot": ""})
	inv.set_inventory_data_item(1, {"id": 32002, "icon_id": 1292, "count": 5, "name": "Rice Wine", "equip_slot": ""})
	inv.set_inventory_data_item(2, {"id": 34058, "icon_id": 1651, "count": 1, "name": "Remote Control", "equip_slot": "", "tradeable": false})
	return inv


func _test_trade_geometry() -> void:
	print(">>> TradeWindow geometry (0x37f744)")
	var w: TradeWindow = TradeScene.instantiate()
	root.add_child(w)
	_check(w.size == Vector2(401, 481), "window 401x481", str(w.size))
	_check(w.background.texture != null and w.background.texture.get_size() == Vector2(401, 481), "Form_TradeItem_1 skin loaded")
	var img: Image = w.background.texture.get_image()
	_check(img.get_pixel(0, 0).a == 0.0, "chroma key removed (corner transparent)")
	_check(w.other_slots.size() == 20 and w.my_slots.size() == 20 and w.bag_slots.size() == 50, "slot counts 20/20/50")
	_check(w.other_slots[0].position == Vector2(24, 69) and w.other_slots[19].position == Vector2(160, 171), "other offer grid", str(w.other_slots[19].position))
	_check(w.my_slots[0].position == Vector2(24, 250), "my offer grid origin")
	_check(w.bag_slots[0].position == Vector2(206, 68) and w.bag_slots[49].position == Vector2(342, 374), "bag grid", str(w.bag_slots[49].position))
	_check(w.btn_confirm.position == Vector2(100, 445) and w.btn_trade.position == Vector2(174, 445) and w.btn_cancel.position == Vector2(250, 445), "button row y=445")
	_check(w.btn_confirm.size == Vector2(56, 20) and w.btn_confirm.texture_normal != null, "Btn_confirm_1 56x20 textured")
	_check(not w.btn_trade.visible, "Btn_Trade_2 hidden until both confirmed")
	_check(not w.btn_arrow_l.visible and not w.btn_arrow_r.visible, "arrows hidden as in ctor")
	_check(w.close_button.position == Vector2(352, 25), "close sphere at (352,25)")
	_check(w.my_gold_edit.position == Vector2(92, 390) and w.my_gold_edit.max_length == 9, "money paid entry (92,390) max 9")
	_check(w.partner_gold_label.position == Vector2(92, 213), "money earned label (92,213)")
	w.queue_free()


func _test_trade_flow() -> void:
	print(">>> TradeWindow offer -> confirm -> trade with stub")
	var inv := _make_inventory(1000)
	var w: TradeWindow = TradeScene.instantiate()
	root.add_child(w)
	var sword := {"id": 11001, "icon_id": 0, "count": 1, "name": "Sword", "equip_slot": "weapon", "durability": 40, "max_durability": 50}
	var stub := TradePartnerStub.new("Betty", [sword], 250)
	stub.attach(w)
	var completed: Array = []
	w.trade_completed.connect(func(ri: Array, rg: int, gi: Array, gg: int) -> void: completed.append([ri, rg, gi, gg]))
	w.open_trade("Betty", inv)
	_check(w.visible and w.partner_name_label.text == "Betty", "opened with partner name")
	_check(w.bag_slots[0].item.get("name") == "Bread", "bag shows inventory")
	_check(w.offer_bag_item(0), "offer Bread")
	_check(not w.offer_bag_item(2), "non-tradeable refused")
	_check(w.my_slots[0].item.get("id") == 32011 and w.bag_slots[0].locked, "offer slot filled, bag cell marked")
	w.set_my_offer_gold(100)
	_check(w.confirm_offer(), "confirm")
	_check(not w.btn_confirm.visible and w.btn_trade.visible, "stub confirmed -> Trade button shown")
	_check(w.other_slots[0].item.get("name") == "Sword" and w.partner_gold_label.text == "250", "partner offer shown")
	_check(not w.offer_bag_item(1), "offer locked after confirm")
	_check(w.accept_trade(), "accept trade")
	_check(completed.size() == 1, "trade_completed emitted")
	_check(inv.current_gold == 1150, "gold 1000 - 100 + 250", str(inv.current_gold))
	var has_bread := false
	var sword_dur := -1
	for it in inv.inventory_data:
		if it is Dictionary and int(it.get("id", 0)) == 32011:
			has_bread = true
		if it is Dictionary and int(it.get("id", 0)) == 11001:
			sword_dur = int(it.get("durability", -1))
	_check(not has_bread, "Bread given away")
	_check(sword_dur == 40, "Sword received with its durability")
	_check(stub.received_gold == 100 and stub.received_items.size() == 1, "stub got the offer")
	_check(not w.visible, "window closed after trade")
	w.queue_free()


func _test_trade_guards_and_cancel() -> void:
	print(">>> TradeWindow guards and cancel")
	var inv := _make_inventory(50)
	var w: TradeWindow = TradeScene.instantiate()
	root.add_child(w)
	var msgs: Array = []
	w.message.connect(func(t: String) -> void: msgs.append(t))
	w.open_trade("Daniel", inv)
	w.set_my_offer_gold(500)
	_check(not w.confirm_offer() and msgs.has("Not enough Gold"), "gold above purse refused")
	w.set_my_offer_gold(0)
	w.offer_bag_item(1)
	var canceled := [false]
	w.trade_canceled.connect(func() -> void: canceled[0] = true)
	w.cancel_trade()
	_check(canceled[0] and not w.visible, "cancel closes and emits")
	_check(w.get_my_offer_items().is_empty() and w.my_gold_edit.text == "0", "cancel resets offer")
	_check(int(inv.inventory_data[1].get("count", 0)) == 5, "cancel leaves inventory untouched")
	# inventory full guard
	var full := _make_inventory(0)
	for i in range(45):
		if full.inventory_data[i].is_empty():
			full.set_inventory_data_item(i, {"id": 40000 + i, "count": 1, "name": "x", "equip_slot": ""})
	w.open_trade("Kelang", full)
	w.confirm_offer()
	w.set_partner_offer([{"id": 11001, "count": 1, "name": "Sword"}], 0)
	w.set_partner_confirmed(true)
	_check(not w.accept_trade() and msgs.has("Inventory full, can't trade"), "full bag refuses trade")
	w.queue_free()


func _test_pet_trade() -> void:
	print(">>> TradePetWindow (0x3351a8)")
	var inv := _make_inventory(500)
	var w: TradePetWindow = TradePetScene.instantiate()
	root.add_child(w)
	_check(w.size == Vector2(463, 455) and w.background.texture != null, "463x455 Form_TradePet_1")
	_check(w.my_skill_slots[0].position == Vector2(247, 308) and w.other_skill_slots[4].position == Vector2(177, 308), "skill rows")
	_check(w.btn_arrow_l.position == Vector2(255, 184) and w.btn_arrow_r.position == Vector2(399, 184), "pet arrows")
	_check(w.btn_confirm.position == Vector2(130, 418) and w.btn_cancel.position == Vector2(280, 418), "button row y=418")
	_check(w.my_gold_edit.position == Vector2(306, 380), "money paid entry")
	var pets := [{"name": "Wolf", "level": 5, "hp": 80, "max_hp": 80, "loyalty": 60}, {"name": "Turtle", "level": 3, "hp": 50, "max_hp": 60, "loyalty": 40}]
	var stub := TradePartnerStub.new("Roca", [], 30, {"name": "Fox", "level": 7, "hp": 90, "max_hp": 90, "loyalty": 70})
	stub.attach(w)
	w.open_trade("Roca", inv, pets)
	_check(w.my_pet_name.text == "Wolf", "first pet shown")
	w.btn_arrow_r.pressed.emit()
	_check(w.my_pet_name.text == "Turtle" and w.my_stats[1].text == "50/60", "arrow selects next pet")
	w.set_my_offer_gold(10)
	_check(w.confirm_offer() and w.other_pet_name.text == "Fox", "confirm, partner pet shown")
	_check(w.accept_trade(), "accept")
	var names: Array = []
	for p in w.my_pets:
		names.append(p["name"])
	_check(names == ["Wolf", "Fox"], "Turtle given, Fox received", str(names))
	_check(inv.current_gold == 520, "gold 500 - 10 + 30", str(inv.current_gold))
	w.queue_free()
