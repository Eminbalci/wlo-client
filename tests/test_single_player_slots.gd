extends SceneTree

## Single-player save slots: write/read/delete per slot, and the slot screen's buttons match the slot state.

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


func _clear_all() -> void:
	for i in range(SaveGame.SLOT_COUNT):
		SaveGame.delete_slot(i)


func _run() -> void:
	print("--- Single Player Slots Suite ---")
	_clear_all()

	_record(SaveGame.SLOT_COUNT == 5, "five save slots")
	_record(not SaveGame.has_slot(0), "slot 0 starts empty")

	var snap := {"name": "Daniel", "level": 7, "map_id": 10002, "gold": 420, "inventory": [{"id": 30028, "count": 1}]}
	_record(SaveGame.write_slot(0, snap), "write slot 0")
	_record(SaveGame.has_slot(0), "slot 0 exists after writing")
	var back := SaveGame.read_slot(0)
	_record(back.get("name") == "Daniel" and int(back.get("level")) == 7, "slot 0 reads back name and level")
	_record(int(back.get("gold")) == 420, "slot 0 keeps gold")
	_record(back.get("inventory", []).size() == 1, "slot 0 keeps inventory")
	var summary := SaveGame.slot_summary(0)
	_record(summary.get("name") == "Daniel" and int(summary.get("map_id")) == 10002, "summary has name and map id")

	_record(SaveGame.write_slot(1, {"name": "Nina", "level": 3}), "write a second slot")
	_record(SaveGame.has_slot(1) and SaveGame.has_slot(0), "two saves coexist")
	_record(SaveGame.read_slot(0).get("name") == "Daniel", "writing slot 1 leaves slot 0 untouched")

	_record(SaveGame.write_slot(0, {"name": "Daniel", "level": 8}), "overwrite slot 0")
	_record(int(SaveGame.read_slot(0).get("level")) == 8, "overwrite replaces the level")

	var vec := SaveGame.array_to_vec(SaveGame.vec_to_array(Vector2(12.5, -3.0)))
	_record(vec == Vector2(12.5, -3.0), "position round-trips as an array")

	_record(SaveGame.delete_slot(1), "delete slot 1")
	_record(not SaveGame.has_slot(1), "slot 1 gone after delete")
	_record(SaveGame.delete_slot(1), "deleting an empty slot is not an error")

	var screen_packed := load("res://scenes/ui/single_player_slots.tscn") as PackedScene
	_record(screen_packed != null, "slot screen scene loads")
	var screen: Control = screen_packed.instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var slots: Dictionary = screen.slot_buttons
	_record(slots.size() == SaveGame.SLOT_COUNT, "screen builds one row per slot")
	_record(slots[0]["continue"] != null and slots[0]["delete"] != null, "filled slot 0 shows Continue and Delete")
	_record(slots[0]["new"] == null, "filled slot 0 has no New Game")
	_record(slots[1]["new"] != null and slots[1]["continue"] == null, "empty slot 1 shows New Game only")

	screen._on_delete_pressed(0)
	await process_frame
	_record(not SaveGame.has_slot(0), "Delete button removes slot 0")
	_record(screen.slot_buttons[0]["new"] != null, "after delete slot 0 offers New Game")

	screen._on_new_game_pressed(2)
	_record(screen.selected_slot == 2 and screen.is_new_game, "New Game on slot 3 selects it")
	screen._on_continue_pressed(0)
	_record(screen.selected_slot == 0 and not screen.is_new_game, "Continue selects its slot")

	_clear_all()
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
