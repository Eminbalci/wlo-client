extends SceneTree

## The Notepad item opens the Notebook; Monster Book lists met monsters; Star Book is a full-screen sky.

var _count: int = 0
var _failures: int = 0


func _init() -> void:
	_run()


func _check(ok: bool, label: String) -> void:
	_count += 1
	if ok:
		print("  [PASS] ", label)
	else:
		_failures += 1
		print("  [FAIL] ", label)


func _run() -> void:
	print("--- Notebook Window Suite ---")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://monster_book.json"))
	var hud: Control = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame

	var notepad_slot := -1
	for i in hud.inventory_ctrl.inventory_data.size():
		if int(hud.inventory_ctrl.inventory_data[i].get("id", 0)) == 34038:
			notepad_slot = i
	_check(notepad_slot >= 0, "The starter inventory has the Notepad")
	hud.inventory_ctrl.use_or_equip_inventory_item(notepad_slot)
	await process_frame
	var nb = hud.notebook_window
	_check(nb != null and nb.menu_panel.visible, "Using the Notepad opens the Notebook menu")
	_check(nb.menu_panel.get_node_or_null("Btn_MissionBook") != null and nb.menu_panel.get_node_or_null("Btn_MonsterBook") != null and nb.menu_panel.get_node_or_null("Btn_StarBook") != null, "The menu has Quest Log, Monster Book and Star Book buttons")

	nb.menu_panel.get_node("Btn_MonsterBook").pressed.emit()
	_check(nb.book_panel.visible and not nb.menu_panel.visible, "Monster Book replaces the menu")
	_check(nb.pager_label.text == "1/1", "The pager shows 1/1")
	_check(nb.book_rows.size() == 10, "The collection book has ten list rows")

	hud.register_monster_seen(17001, "Mushroon Of The Deep Forest")
	_check(nb.entry_count() == 1, "A met monster is added to the book")
	hud.register_monster_seen(17001, "Mushroon Of The Deep Forest")
	_check(nb.entry_count() == 1, "The same monster is not added twice")
	_check(nb.book_rows[0].text == "Mushroon Of ", "List names are cut at 12 characters like the original")
	nb.book_rows[0].pressed.emit()
	_check(nb.detail_labels["hp"].text != "" or nb.detail_labels["name"].text != "", "Selecting a row fills the detail card")

	nb.close_all()
	_check(not nb.visible, "Close hides every panel")
	nb.open_star_book()
	_check(nb.sky_panel.visible and nb.sky_panel.get_child_count() > 3, "Star Book shows the sky with constellations")
	nb.get_node("StarSky/SkyClose").pressed.emit()
	_check(not nb.visible, "The sky's close button leaves the Star Book")

	var quest_opened: Array = [false]
	nb.quest_log_requested.connect(func() -> void: quest_opened[0] = true)
	nb.open_menu()
	nb.menu_panel.get_node("Btn_MissionBook").pressed.emit()
	_check(quest_opened[0] and hud.window_manager_ctrl.quest_window.visible, "Quest Log opens the mission window")

	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://monster_book.json"))
	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
