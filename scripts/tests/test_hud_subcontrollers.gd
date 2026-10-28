extends Node

const HUDInventory = preload("res://scripts/ui/hud/hud_inventory.gd")
const HUDCharacterStatus = preload("res://scripts/ui/hud/hud_character_status.gd")
const HUDChat = preload("res://scripts/ui/hud/hud_chat.gd")
const HUDDialogue = preload("res://scripts/ui/hud/hud_dialogue.gd")

func _ready() -> void:
	print("--- Running In-Engine Verification of HUD Sub-controllers ---")
	test_hud_inventory()
	test_hud_character_status()
	test_hud_chat()
	test_hud_dialogue()
	print("[ALL PASS] All HUD Sub-controllers verified successfully!")
	get_tree().quit(0)

func test_hud_inventory() -> void:
	print("Testing HUDInventory...")
	var dummy_hud := Control.new()
	var grid := Control.new()
	var gold := Label.new()
	var status := Control.new()
	dummy_hud.add_child(grid)
	dummy_hud.add_child(gold)
	dummy_hud.add_child(status)

	var inv := HUDInventory.new()
	inv.setup(dummy_hud, {
		"inventory_grid": grid,
		"gold_label": gold,
		"status_dock": status
	})

	assert(inv.inventory_slots.size() == 45, "Must have 45 inventory slots")
	assert(inv.inventory_data.size() == 45, "Must have 45 inventory data records")
	assert(inv.get_inventory_slot(0) != null, "Slot 0 button must exist")
	assert(inv.get_inventory_slot(44) != null, "Slot 44 button must exist")

	# Test gold
	inv.update_gold(12345)
	assert(gold.text == "12345", "Gold label must update")

	# Test add item
	var added := inv.add_inventory_item(99999, 5, "Test Potion", 100)
	assert(added == true, "Must add item")

	# Test set / get
	inv.set_inventory_item(20, 1050, 3, 2050, "Magic Stone")
	assert(inv.inventory_data[20]["id"] == 2050, "Item ID must match")
	assert(inv.inventory_data[20]["count"] == 3, "Count must match")

	# Test drag data
	var drag_data = inv.get_inventory_drag_data(20)
	assert(drag_data is Dictionary, "Drag data must be dictionary")
	assert(drag_data["type"] == "inventory", "Drag type must be inventory")

	# Test drop swap
	assert(inv.can_drop_on_inventory_slot(21, drag_data) == true, "Can drop on slot 21")
	inv.drop_on_inventory_slot(21, drag_data)
	assert(inv.inventory_data[21]["id"] == 2050, "Item moved to slot 21")
	assert(inv.inventory_data[20].is_empty() or inv.inventory_data[20].get("id", 0) == 0, "Slot 20 must be empty")

	# Test clear
	inv.clear_inventory_slot(21)
	assert(inv.inventory_data[21].is_empty() or inv.inventory_data[21].get("id", 0) == 0, "Slot 21 must be cleared")

	dummy_hud.free()
	print("[PASS] HUDInventory verified")

func test_hud_character_status() -> void:
	print("Testing HUDCharacterStatus...")
	var dummy_hud := Control.new()
	var char_win := Control.new()
	var paper_doll := TextureRect.new()
	dummy_hud.add_child(char_win)
	char_win.add_child(paper_doll)

	var s_name := Label.new()
	var s_lvl := Label.new()
	var s_elem := Label.new()
	var s_hp := Label.new()
	var s_sp := Label.new()
	var s_exp := Label.new()
	var s_atk := Label.new()
	var s_def := Label.new()
	var s_matk := Label.new()
	var s_mdef := Label.new()
	var s_spd := Label.new()
	var s_str := Label.new()
	var s_con := Label.new()
	var s_int := Label.new()
	var s_wis := Label.new()
	var s_agi := Label.new()
	var s_free := Label.new()

	var char_status := HUDCharacterStatus.new()
	char_status.setup(dummy_hud, {
		"char_window": char_win,
		"char_paper_doll": paper_doll,
		"stat_name": s_name,
		"stat_level": s_lvl,
		"stat_element": s_elem,
		"stat_left_hp": s_hp,
		"stat_left_sp": s_sp,
		"stat_left_exp": s_exp,
		"stat_atk": s_atk,
		"stat_def": s_def,
		"stat_matk": s_matk,
		"stat_mdef": s_mdef,
		"stat_spd": s_spd,
		"stat_str": s_str,
		"stat_con": s_con,
		"stat_int": s_int,
		"stat_wis": s_wis,
		"stat_agi": s_agi,
		"stat_free": s_free,
	})

	assert(char_status.equipment_slots.has("head"), "Must have head slot")
	assert(char_status.equipment_slots.has("body"), "Must have body slot")
	assert(char_status.equipment_slots.has("weapon"), "Must have weapon slot")
	assert(char_status.equipment_slots.has("wrist"), "Must have wrist slot")
	assert(char_status.equipment_slots.has("shoes"), "Must have shoes slot")
	assert(char_status.equipment_slots.has("special"), "Must have special slot")

	# Test update stats
	char_status.update_character_stats("Kira", 25, "Fire", 500, 500, 200, 200, 8000, 10000, 30, 20, 10, 10, 25, 5)
	assert(s_name.text == "Kira", "Name must match")
	assert(s_lvl.text == "25", "Level must match")
	assert(s_elem.text == "Fire", "Element must match")

	# Test equip / unequip
	char_status.equip_item("weapon", "003w.jma", "3040.jmp", 2466, "Epic Blade")
	assert(char_status.equipment_data.has("weapon"), "Weapon must be equipped")
	var eq = char_status.get_equipment()
	assert(eq.has("weapon"), "Equipment layers must contain weapon")

	var drag = char_status.get_equipment_drag_data("weapon")
	assert(drag is Dictionary, "Drag data must be dictionary")
	assert(drag["type"] == "equipment", "Type must be equipment")

	char_status.unequip_item("weapon")
	assert(not char_status.equipment_data.has("weapon"), "Weapon must be unequipped")

	dummy_hud.free()
	print("[PASS] HUDCharacterStatus verified")

func test_hud_chat() -> void:
	print("Testing HUDChat...")
	var dummy_hud := Control.new()
	var history := RichTextLabel.new()
	var in_line := LineEdit.new()
	var panel := PanelContainer.new()
	panel.add_child(history)
	dummy_hud.add_child(panel)
	dummy_hud.add_child(in_line)

	var chat := HUDChat.new()
	chat.setup(dummy_hud, {
		"chat_history_panel": panel,
		"chat_history": history,
		"chat_input": in_line
	})

	chat.add_chat_message("Alice", "Hello World!", "Local")
	assert(chat._chat_messages.size() == 1, "Must store 1 message")
	assert("Hello World!" in history.text or "Hello World!" in chat._chat_messages[0]["line"], "Message must be formatted")

	chat.select_chat_tab("Whisper")
	assert(chat._active_chat_tab == "Whisper", "Tab must be Whisper")

	dummy_hud.free()
	print("[PASS] HUDChat verified")

func test_hud_dialogue() -> void:
	print("Testing HUDDialogue...")
	var dummy_hud := Control.new()
	var d_dock := Control.new()
	var b_dock := Control.new()
	var s_label := Label.new()
	var d_text := RichTextLabel.new()
	var choices_vbox := VBoxContainer.new()
	d_dock.add_child(s_label)
	d_dock.add_child(d_text)
	b_dock.add_child(choices_vbox)
	dummy_hud.add_child(d_dock)
	dummy_hud.add_child(b_dock)

	var dlg := HUDDialogue.new()
	dlg.setup(dummy_hud, {
		"dialogue_dock": d_dock,
		"branching_dock": b_dock,
		"speaker_label": s_label,
		"dialogue_text": d_text,
		"choices_container": choices_vbox
	})

	var pages: Array[String] = ["Welcome aboard!", "Set sail for Adventure Island."]
	dlg.show_dialogue_sequence("Captain", pages, 8025)
	assert(d_dock.visible == true, "Dialogue dock must be visible")
	assert(s_label.text == "Captain", "Speaker must be Captain")
	assert(d_text.text == "Welcome aboard!", "Page 1 text must match")

	dlg.advance_dialogue()
	assert(d_text.text == "Set sail for Adventure Island.", "Page 2 text must match")

	dlg.advance_dialogue()
	assert(d_dock.visible == false, "Dialogue dock must close after last page")

	# Test choices
	var choice_result := [-1]
	dlg.show_choices(["Yes", "No"], func(idx: int, _txt: String): choice_result[0] = idx)
	assert(b_dock.visible == true, "Branching dock must be visible")
	assert(choices_vbox.get_child_count() == 2, "Must create 2 choice buttons")

	var btn0 := choices_vbox.get_child(0) as Button
	btn0.emit_signal("pressed")
	assert(choice_result[0] == 0, "Callback must receive choice 0")
	assert(b_dock.visible == false, "Branching dock must close after choice")

	dummy_hud.free()
	print("[PASS] HUDDialogue verified")
