extends SceneTree

## Gift Exchange Card selector: request bytes, reward list parsing, and the confirm packet (Go item_cards.go layout).

const GiftCardWindow = preload("res://scripts/ui/hud/gift_card_window.gd")

var _checks := 0
var _failed := 0
var _sent: Array = []


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _capture(p: PackedByteArray) -> void:
	_sent.append(p)


func _run() -> void:
	print("--- Gift Card Window Suite ---")
	await process_frame
	var w = GiftCardWindow.new()
	root.add_child(w)
	w.configure(Callable(self, "_capture"), Callable(self, "_name"))
	await process_frame

	w.request_card(3, 50001)
	_record(_sent.size() == 1 and _sent[0] == PackedByteArray([23, 133, 1, 3, 0x51, 0xC3, 0]), "request is AC23:133 mode 1 (slot, item, zero)")

	# Reply: AC23:108 type 2, one card 50001 with two rewards (34086 x1, 34090 x2).
	var details := PackedByteArray([23, 108, 2, 1, 0, 0x51, 0xC3, 1, 2, 0x46, 0x85, 1, 0x4A, 0x85, 2])
	_record(w.handle_packet(23, 108, details), "details reply is handled")
	_record(w.visible, "details open the selector")
	_record(w._rewards.size() == 2 and w._rewards[1].quantity == 2, "the two rewards are parsed with quantities")

	w._select(0)
	w._exchange()
	_record(_sent.size() == 2 and _sent[1] == PackedByteArray([23, 133, 2, 3, 1, 1, 0x46, 0x85]), "confirm sends mode 2 with slot, index 1 and reward 34086")
	_record(w._waiting, "the window waits for the server")

	w.handle_packet(23, 108, PackedByteArray([23, 108, 3, 0x51, 0xC3, 1, 0x46, 0x85, 1]))
	_record(not w.visible, "a redeemed reply closes the selector")

	w.request_card(3, 50001)
	_record(w._rewards.is_empty(), "requesting again clears the previous rewards")
	await _check_hud()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _check_hud() -> void:
	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	_sent.clear()
	hud.open_gift_card(2, 50001, Callable(self, "_capture"))
	_record(hud.gift_card_window != null and _sent.size() == 1 and _sent[0] == PackedByteArray([23, 133, 1, 2, 0x51, 0xC3, 0]), "the HUD opens the selector and sends the card request")
	_record(hud.handle_gift_packet(23, 108, PackedByteArray([23, 108, 2, 1, 0, 0x51, 0xC3, 1, 1, 0x46, 0x85, 1])), "the HUD routes the details reply to the selector")
	_record(hud.gift_card_window.visible, "the routed details open the selector in the HUD")
	_record(not hud.handle_gift_packet(23, 99, PackedByteArray([23, 99, 2])), "unrelated AC23 sub packets are not consumed")
	hud.gift_card_window.close()
	inst.queue_free()


func _name(id: int) -> String:
	return "Card %d" % id
