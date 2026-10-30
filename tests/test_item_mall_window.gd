extends SceneTree

## Item Mall (top bar icon 711) opens the mall points window on the Form_Shopping_1 skin.

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
	print("--- Item Mall Window Suite ---")
	await process_frame
	await process_frame

	var win := ItemMallWindow.new()
	root.add_child(win)
	await process_frame
	_record(not win.visible, "the mall window starts hidden")
	_record(win.get_node_or_null("Skin") != null and (win.get_node("Skin") as TextureRect).texture != null, "the Form_Shopping_1 skin loads")

	win.set_points(1200, 35)
	_record(win.current_label.text.ends_with("1200") and win.bonus_label.text.ends_with("35"), "points show the current and bonus balances")
	win.set_points(-5, 0)
	_record(win.current_points == 0, "negative balances are clamped to 0")

	win.open()
	_record(win.visible, "open() shows the window")
	win.close()
	_record(not win.visible, "close() hides the window")

	var inst: Node = (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in range(60):
		await process_frame
	var hud = inst.get("hud")
	hud.open_item_mall()
	_record(hud.item_mall_window != null and hud.item_mall_window.visible, "the HUD opens the mall window")
	hud.open_item_mall()
	_record(get_nodes_in_group_count(hud) == 1, "a second open reuses the same window")

	hud.item_mall_window.close()
	var top_bar = hud.get("top_action_bar")
	if top_bar and top_bar.has_method("_on_action_requested"):
		top_bar._on_action_requested("item_mall")
		_record(hud.item_mall_window.visible, "the top bar item_mall action opens the mall")
	else:
		_record(false, "the top bar is reachable from the HUD")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func get_nodes_in_group_count(hud: Node) -> int:
	var count := 0
	for child in hud.get_children():
		if child is ItemMallWindow:
			count += 1
	return count
