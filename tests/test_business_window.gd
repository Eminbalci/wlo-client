extends SceneTree

## Toolbar Trade menu: hidden at start, gold text, Trade Items request, stub buttons disabled,
## close emits closed.

const BusinessWindow = preload("res://scripts/ui/hud/business_window.gd")

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
	print("--- Business Window Suite ---")
	await process_frame
	var gold := [1234]
	var w = BusinessWindow.new()
	w.configure(Callable(self, "_gold").bind(gold))
	root.add_child(w)
	await process_frame
	_record(not w.visible, "the trade menu starts hidden")
	_record(w.get_node("Background").texture != null, "the Form_Business_1 skin loads")
	w.open()
	_record(w.visible and w._gold_label.text == "1234", "open shows the player's gold")
	gold[0] = -5
	w.refresh()
	_record(w._gold_label.text == "0", "negative gold reads 0")

	var requests := [0]
	w.trade_items_requested.connect(func() -> void: requests[0] += 1)
	w._trade_items.pressed.emit()
	_record(requests[0] == 1, "Trade Items requests a trade")
	var stub: TextureButton = w.get_node("TradePets")
	_record(stub.disabled, "the pet trade button is disabled until its form is ported")

	var closed := [0]
	w.closed.connect(func() -> void: closed[0] += 1)
	w.toggle()
	_record(not w.visible and closed[0] == 1, "toggle closes it and emits closed")
	w.toggle()
	_record(w.visible, "toggle opens it again")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)


func _gold(holder: Array) -> int:
	return holder[0]
