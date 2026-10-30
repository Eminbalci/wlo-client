extends SceneTree

## The HUD opens the trade, warehouse, repair, potential, title and pet-status windows on demand.

const HudScene = preload("res://scenes/ui/hud.tscn")

var _passed: int = 0
var _failed: int = 0

func check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		print("  [FAIL] %s" % msg)

func _init() -> void:
	var hud = HudScene.instantiate()
	root.add_child(hud)
	await process_frame
	var trade = hud.open_trade("Merchant", [], 50)
	check(trade != null and trade.visible, "Trade window opens")
	check(hud.get_or_create_window("TradeWindow", "res://scenes/ui/trade/trade_window.tscn") == trade, "Trade window is reused")
	trade.cancel_trade()
	var bank = hud.open_warehouse()
	check(bank != null and bank.visible, "Warehouse opens")
	bank.close_window()
	var repair = hud.open_repair()
	check(repair != null and repair.visible, "Repair opens")
	repair.close_window()
	var pot = hud.open_potential()
	check(pot != null and pot.visible, "Potential opens")
	pot.close_window()
	hud.character_status_ctrl._on_potential_button_pressed()
	check(pot.visible, "Item window Potential button opens it")
	pot.close_window()
	var titles = hud.open_player_titles([0, 1], 0)
	check(titles != null and titles.visible, "Title window opens")
	titles.close_window()
	var pet = hud.open_pet_status(1, {"name": "Roca"})
	check(pet != null and pet.visible, "Pet status popup opens")
	var world = hud.toggle_world_map()
	check(world != null and world.visible, "World map toggles open")
	hud.toggle_world_map()
	check(not world.visible, "World map toggles closed")
	var gps = hud.open_gps()
	check(gps != null and gps.visible, "GPS opens")
	gps.close()
	var box = hud.open_mailbox()
	check(box != null and box.visible, "Mailbox opens")
	box.compose_requested.emit("Doll")
	var send = hud.get_or_create_code_window("MailSendWindow", func() -> Control: return null)
	check(send != null and send.visible, "Compose opens from the mailbox")
	var chan = hud.open_channel_filter()
	check(chan != null and chan.visible, "Channel filter opens")
	print("\nRESULTS: %d PASSED, %d FAILED" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
