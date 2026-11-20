extends SceneTree

## NetSession keeps the connection across scenes and routes replies to the HUD's windows.

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	print(("  [PASS] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failed += 1


func _run() -> void:
	print("--- NetSession Suite ---")
	await process_frame
	var net := root.get_node_or_null("NetSession")
	_record(net != null, "NetSession is an autoload")
	_record(not net.is_online() and not net.send(PackedByteArray([1])), "offline: is_online is false and send does nothing")

	var holder := Node.new()
	root.add_child(holder)
	var client := NetworkClient.new()
	holder.add_child(client)
	net.adopt(client)
	_record(client.get_parent() == net, "adopt moves the client under NetSession so it survives a scene change")
	var got := []
	net.packet_received.connect(func(a: int, p: PackedByteArray) -> void: got.append([a, p]))
	client.packet_received.emit(85, PackedByteArray([85, 4, 1]))
	_record(got.size() == 1 and got[0][0] == 85, "client packets are re-emitted by NetSession")

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	hud.team_window.tab_changed.emit(1)
	client.packet_received.emit(85, PackedByteArray([85, 4, 233, 3, 0, 0, 49, 117, 1, 4]))
	_record(hud.instance_window != null and hud.instance_window.room_id == 1001, "an AC85 reply from the session reaches the instance panel")
	hud.open_gift_card(2, 50001)
	client.packet_received.emit(23, PackedByteArray([23, 108, 2, 1, 0, 0x51, 0xC3, 1, 1, 0x46, 0x85, 1]))
	_record(hud.gift_card_window != null and hud.gift_card_window.visible, "an AC23 reply from the session reaches the gift card window")
	inst.queue_free()
	client.queue_free()
	holder.queue_free()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
