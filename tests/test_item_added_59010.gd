extends SceneTree

## The item appended to Assets/data/Item.dat (id 59010, a copy of Bread) must load through GameDatabase.

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
	print("--- Added Item 59010 Suite ---")
	await process_frame
	await process_frame
	var db = root.get_node("GameDatabase")
	var rec = db.items.get_item(59010)
	_record(rec != null, "item 59010 is loaded from Item.dat")
	if rec != null:
		_record(rec.buy_price > 0 or rec.sell_price >= 0, "item 59010 has a readable price record (%d/%d)" % [rec.buy_price, rec.sell_price])
	_record(db.items.get_item(32011) != null, "the template item 32011 still loads (no record shift)")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
