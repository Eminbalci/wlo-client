extends SceneTree

## The shopping cart builds seven rows with its skin, a total and three buttons.

var _checks := 0
var _failed := 0


func _init() -> void:
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
	print("--- Shopping Cart Suite ---")
	var host := Control.new()
	root.add_child(host)
	var parts: Dictionary = ShoppingCartWindow.build(host)
	_record(parts.get("rows", []).size() == 7, "cart has 7 rows")
	var root_node: TextureRect = parts["root"]
	_record(root_node.texture != null, "cart uses the original ShoppingCar skin")
	_record(parts["total"] is Label and parts["continue"] is Button and parts["checkout"] is Button and parts["leave"] is Button, "total label and three buttons exist")
	var first_row: Control = parts["rows"][0]
	_record(is_equal_approx(first_row.position.y, 40.0), "first row sits at y 40")
	var last_row: Control = parts["rows"][6]
	_record(is_equal_approx(last_row.position.y, 40.0 + 59.0 * 6.0), "last row sits at y 394")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
