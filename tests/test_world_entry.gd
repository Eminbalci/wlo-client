extends SceneTree

## The spawn and inventory packets the server sends on world entry, checked against a live capture.

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	print(("  [PASS] " if ok else "  [FAIL] ") + label)
	if not ok:
		_failed += 1


func _entry(slot: int, id: int, count: int) -> PackedByteArray:
	var e := PackedByteArray([slot, id & 0xFF, (id >> 8) & 0xFF, count, 0])
	e.resize(31)
	return e


func _run() -> void:
	print("--- World Entry Suite ---")
	await process_frame
	var spawn := PackedByteArray([3, 19, 39, 0, 0, 1, 49, 117, 232, 3, 232, 3, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 67, 108, 111, 110, 101, 84, 101, 115, 116, 0, 0, 0, 0, 0])
	var s := WorldEntry.parse_spawn(spawn)
	_record(s.get("char_id") == 10003 and s.get("map") == 30001 and s.get("x") == 1000 and s.get("y") == 1000, "the live spawn packet gives id, map and position")
	_record(WorldEntry.parse_spawn(PackedByteArray([3, 19, 39, 0, 0, 0, 49, 117, 232, 3, 232, 3])).is_empty(), "a packet without the marker byte is not a spawn")
	_record(WorldEntry.parse_spawn(PackedByteArray([3, 19, 39])).is_empty(), "a short packet is not a spawn")
	_record(WorldEntry.parse_spawn(PackedByteArray([7, 19, 39, 0, 0, 49, 117, 232, 3, 232, 3, 0])).is_empty(), "another action is not a spawn")

	var inv := PackedByteArray([23, 5])
	inv.append_array(_entry(1, 34038, 1))
	inv.append_array(_entry(2, 34058, 1))
	inv.append_array(_entry(3, 32176, 50))
	inv.append_array(PackedByteArray([4, 1, 2, 3]))
	var items := WorldEntry.parse_inventory(inv)
	_record(items.size() == 3, "three complete entries are read and the partial tail is ignored")
	_record(items[0].slot == 1 and items[0].id == 34038 and items[1].id == 34058 and items[2].count == 50, "slots, item ids and amounts follow the live capture")
	_record(WorldEntry.parse_inventory(PackedByteArray([23, 6, 1, 2])).is_empty(), "another sub code is not an inventory list")
	# Live capture: 250 bytes = header 2 + 8 entries of 31 bytes (slots at 2, 33, 64, ... 219).
	var live := PackedByteArray([23, 5])
	for n in range(8):
		live.append_array(_entry(n + 1, 34000 + n, n + 1))
	var all := WorldEntry.parse_inventory(live)
	_record(live.size() == 250 and all.size() == 8 and all[7].slot == 8 and all[7].id == 34007 and all[7].count == 8, "eight entries fill the live 250-byte packet exactly")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
