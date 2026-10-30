extends SceneTree

## The Kelan Village Props Shop catalog is read from Item.dat (name, icon, price, description), 5 items as on the real client.

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
	print("--- Props Shop Catalog Suite ---")
	await process_frame
	await process_frame
	var db = root.get_node("GameDatabase")
	var catalog: Array[Dictionary] = ShopWindow.get_default_catalog(0, "Props Shop")
	_record(catalog.size() == 5, "props shop lists 5 items (%d)" % catalog.size())

	var expected := {32011: ["Bread", 10], 32002: ["Rice Wine", 50], 45001: ["Ordinary Wood", 30], 45003: ["Lauan Wood", 50], 42008: ["Copper Ore", 10]}
	var all_match := true
	for entry in catalog:
		var id := int(entry.get("id", 0))
		if not expected.has(id):
			all_match = false
			continue
		var rec = db.items.get_item(id)
		if rec == null or str(entry.get("name", "")) != str(rec.name).strip_edges() or int(entry.get("price", -1)) != int(rec.buy_price):
			all_match = false
	_record(all_match, "every entry's name and price come from Item.dat")
	_record(catalog.size() > 0 and str(catalog[0].get("description", "")) == str(db.items.get_item(32011).description), "description is the Item.dat text")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
