extends SceneTree

## Headless tests for the windows decoded from aLogin.exe in docs/re/*_window.md:
## Form_ThrowMoney, Form_ThrowThing (quantity), Form_pickup, Form_ExpBox, Form_ReceiveReward,
## Form_Huminfo (info visibility), Form_ActionList (activities), Form_BattleSkill, Form_Inn (pet inn)
## and the Form_EquipStore skin of ShopWindow. Checks geometry against the decoded immediates,
## chroma-key removal and each window's handler logic.

const ThrowMoneyScene = preload("res://scenes/ui/forms/throw_money_window.tscn")
const QuantityScene = preload("res://scenes/ui/forms/quantity_window.tscn")
const PickupScene = preload("res://scenes/ui/forms/pickup_window.tscn")
const ExpBoxScene = preload("res://scenes/ui/forms/exp_box_window.tscn")
const RewardScene = preload("res://scenes/ui/forms/receive_reward_window.tscn")
const InfoScene = preload("res://scenes/ui/forms/info_visibility_window.tscn")
const ActivityScene = preload("res://scenes/ui/forms/activity_list_window.tscn")
const BattleSkillScene = preload("res://scenes/ui/forms/battle_skill_window.tscn")
const InnScene = preload("res://scenes/ui/forms/pet_inn_window.tscn")
const ShopScene = preload("res://scenes/ui/shop/shop_window.tscn")

var _fail: int = 0
var _count: int = 0


class FakeInventory:
	extends RefCounted
	var inventory_data: Array = []
	var current_gold: int = 0

	func _init(slots: int, gold: int) -> void:
		inventory_data.resize(slots)
		for i in range(slots):
			inventory_data[i] = {}
		current_gold = gold

	func update_gold(amount: int) -> void:
		current_gold = amount


func _init() -> void:
	for n in ["ArchiveLoader:res://scripts/core/archive_loader.gd", "GameDatabase:res://scripts/database/game_database.gd"]:
		var parts: PackedStringArray = n.split(":", true, 1)
		if not root.has_node(parts[0]):
			var node: Node = load(parts[1]).new()
			node.name = parts[0]
			root.add_child(node)
	_test_throw_money()
	_test_quantity()
	_test_pickup()
	_test_exp_box()
	_test_reward()
	_test_info_visibility()
	_test_activities()
	_test_battle_skill()
	_test_pet_inn()
	_test_equip_store()
	print("--- %d checks, %d failed ---" % [_count, _fail])
	quit(1 if _fail > 0 else 0)


func _check(cond: bool, name: String, detail: String = "") -> void:
	_count += 1
	if cond:
		print("  [PASS] " + name)
	else:
		_fail += 1
		printerr("  [FAIL] %s %s" % [name, detail])


func _skin_ok(w: Control, expected: Vector2, label: String) -> void:
	var tex: Texture2D = w.background.texture
	_check(tex != null and tex.get_size() == expected, "%s skin %dx%d" % [label, int(expected.x), int(expected.y)], str(tex.get_size() if tex else null))
	if tex:
		var img: Image = tex.get_image()
		var green: int = 0
		for y in range(0, img.get_height(), 2):
			for x in range(img.get_width()):
				var c: Color = img.get_pixel(x, y)
				if c.a > 0.0 and c.r < 0.02 and c.g > 0.98 and c.b < 0.02:
					green += 1
		_check(green == 0, "%s chroma key removed (no opaque pure green)" % label, str(green))


func _messages(w: Object) -> Array:
	var out: Array = []
	w.message.connect(func(t: String) -> void: out.append(t))
	return out


func _test_throw_money() -> void:
	print(">>> ThrowMoney (0x2771ec)")
	var w = ThrowMoneyScene.instantiate()
	root.add_child(w)
	_check(w.size == Vector2(209, 87), "window 209x87")
	_skin_ok(w, Vector2(209, 87), "Form_ThrowMoney")
	_check(w.amount_edit.get_parent().position == Vector2(70, 29) and w.amount_edit.get_parent().size == Vector2(76, 24), "edit box (70,29) 76x24")
	_check(w.btn_ok.position == Vector2(34, 59) and w.btn_cancel.position == Vector2(119, 59), "OK/Cancel y=59")
	_check(w.btn_arrow_l.position == Vector2(34, 32) and w.btn_arrow_r.position == Vector2(154, 32), "arrows (34,32)/(154,32)")
	_check(w.btn_ok.texture_normal != null and w.btn_arrow_l.texture_normal != null, "button art loaded")
	var inv := FakeInventory.new(10, 100)
	var msgs := _messages(w)
	var drops: Array = []
	w.drop_requested.connect(func(a: int) -> void: drops.append(a))
	w.open(inv, 0)
	w.increment()
	_check(w.get_amount() == 1, "Arrow_L3 +1")
	w.amount_edit.text = "10"
	w.decrement()
	_check(w.get_amount() == 10, "Arrow_R3 does not go below 10")
	w.amount_edit.text = "12"
	w.decrement()
	_check(w.get_amount() == 11, "Arrow_R3 -1 above 10")
	w.amount_edit.text = "abc"
	_check(not w.confirm() and w.amount_edit.text == "0", "non-number resets to 0")
	w.amount_edit.text = "500"
	_check(not w.confirm() and msgs.back() == "Not enough Gold", "Not enough Gold")
	w.amount_edit.text = "5"
	_check(not w.confirm() and drops.is_empty(), "below 10 ignored")
	w.at_home = true
	w.amount_edit.text = "50"
	_check(not w.confirm() and msgs.back() == "Can't drop at home", "Can't drop at home")
	w.at_home = false
	w.current_map_id = 10701
	_check(not w.confirm() and msgs.back() == "Temporary unavailable", "map 10701 blocked")
	w.current_map_id = 0
	_check(w.confirm() and drops == [50] and inv.current_gold == 50 and not w.visible, "drop 50 gold -> gold 50, closed")
	w.queue_free()


func _test_quantity() -> void:
	print(">>> Quantity / Form_ThrowThing (0x3724a8)")
	var w = QuantityScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(209, 87), "Form_ThrowThing")
	_check(w.amount_edit.get_parent().position == Vector2(64, 33) and w.amount_edit.get_parent().size == Vector2(81, 15), "Panel26 edit box (64,33) 81x15")
	_check(w.btn_arrow_l.position == Vector2(37, 32) and w.btn_arrow_r.position == Vector2(155, 32), "arrows 17x17 at (37,32)/(155,32)")
	_check(w.btn_ok.position == Vector2(34, 59) and w.btn_cancel.position == Vector2(119, 59), "OK/Cancel")
	var got: Array = []
	w.quantity_confirmed.connect(func(m: int, s: int, a: int) -> void: got.append([m, s, a]))
	w.open(1, 4, 7)
	_check(w.get_amount() == 7, "starts at stack count")
	w.increment()
	_check(not w.confirm() and got.is_empty(), "mode 1: 8 > stack 7 refused")
	w.amount_edit.text = "0"
	w.decrement()
	_check(w.get_amount() == 0, "Arrow_R5 stops at 0")
	_check(not w.confirm(), "0 refused")
	w.amount_edit.text = "3"
	_check(w.confirm() and got == [[1, 4, 3]] and not w.visible, "mode 1 confirm 3")
	_check(w.limit_for_mode(7, 99) == 50 and w.limit_for_mode(6, 1) == 255 and w.limit_for_mode(15, 1) == 255, "mode limits 50/255/255")
	var destroy: Array = []
	w.destroy_confirm_requested.connect(func(t: String, s: int, a: int) -> void: destroy.append([t, s, a]))
	w.open(8, 2, 5, 5)
	_check(w.confirm() and destroy.size() == 1 and destroy[0][0].begins_with("Item will be destroyed"), "mode 8 asks destroy confirmation")
	w.queue_free()


func _test_pickup() -> void:
	print(">>> Pickup / pet forage (0x214998)")
	var w = PickupScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(188, 213), "Form_pickup")
	_check(w.slots.size() == 3 and w.slots[0].position == Vector2(39, 124) and w.slots[2].position == Vector2(117, 124), "3 cells x=39*i y=124")
	_check(w.slots[0].size == Vector2(30, 30), "cells 30x30")
	_check(w.btn_ok.position == Vector2(35, 172) and w.btn_cancel.position == Vector2(75, 172) and w.btn_close.position == Vector2(115, 172), "buttons y=172")
	_check(w.btn_ok.size == Vector2(39, 20), "Btn_OK_2 39x20")
	var msgs := _messages(w)
	var started: Array = []
	var canceled: Array = []
	w.search_started.connect(func(items: Array) -> void: started.append(items))
	w.search_canceled.connect(func() -> void: canceled.append(true))
	w.open()
	w.set_slot_item(0, {"id": 46001, "name": "Dog Bone", "count": 1})
	w.has_suitable_pet = false
	_check(not w.start_search() and msgs.back() == "No suitable pet", "No suitable pet")
	w.has_suitable_pet = true
	_check(w.start_search() and started.size() == 1 and started[0].size() == 1, "search started with 1 item")
	_check(not w.start_search() and msgs.back() == "Item seach active", "second start refused")
	w.close_window()
	_check(not w.visible and not w.slots[0].is_empty(), "Close while searching keeps cells")
	w.open()
	w.cancel_search()
	_check(canceled.size() == 1 and w.slots[0].is_empty() and not w.visible and not w.search_active, "Cancel stops search, resets, closes")
	w.queue_free()


func _test_exp_box() -> void:
	print(">>> ExpBox (0x1c4858)")
	var w = ExpBoxScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(223, 195), "Form_ExpBox")
	_check(w.pockets.size() == 10 and w.pockets[0].position == Vector2(31, 53) and w.pockets[9].position == Vector2(167, 87), "10 pockets (31+34c, 53+34r)", str(w.pockets[9].position))
	_check(w.check_box.position == Vector2(25, 136) and w.check_box.size == Vector2(16, 16), "check box (25,136)")
	_check(w.btn_confirm.position == Vector2(40, 160) and w.btn_cancel.position == Vector2(118, 160), "Confirm/Cancel y=160")
	var inv := FakeInventory.new(2, 0)
	var msgs := _messages(w)
	var changes: Array = []
	w.auto_use_changed.connect(func(on: bool) -> void: changes.append(on))
	w.open(inv)
	w.set_pockets([{"id": 47001, "name": "EXP Potion", "count": 1}])
	_check(w.withdraw(0) and w.pockets[0].is_empty() and int(inv.inventory_data[0].get("id", 0)) == 47001, "withdraw pocket to bag")
	inv.inventory_data[1] = {"id": 1, "count": 1}
	w.set_pockets([{"id": 47001, "name": "EXP Potion", "count": 1}])
	_check(not w.withdraw(0) and msgs.back() == "Inventory is full", "Inventory is full")
	var normal_before: Texture2D = w.check_box.texture_normal
	w.toggle_auto_use()
	_check(w.auto_use_pending and w.check_box.texture_normal != normal_before, "check box toggles art")
	w.confirm()
	_check(changes == [true] and msgs.back() == "Auto-use EXP Potion is on" and not w.visible, "confirm -> auto-use on")
	w.open(inv)
	w.confirm()
	_check(changes.size() == 1, "unchanged confirm sends nothing")
	w.queue_free()


func _test_reward() -> void:
	print(">>> ReceiveReward (0x2cba24)")
	var w = RewardScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(353, 251), "Form_ReceiveReward")
	_check(w.btn_reward.position == Vector2(100, 60) and w.btn_reward.size == Vector2(171, 171), "Btn_Reward (100,60) 171x171")
	_check(w.btn_close.position == Vector2(150, 210) and w.close_button.position == Vector2(305, 24), "close buttons")
	_check(w.btn_reward.texture_normal != null and w.btn_reward.texture_normal.get_size() == Vector2(171, 171), "Btn_Reward frame 171x171")
	var full := FakeInventory.new(1, 0)
	full.inventory_data[0] = {"id": 1, "count": 1}
	var msgs := _messages(w)
	w.open(full, [{"id": 32011, "name": "Bread", "count": 2}])
	_check(w.btn_reward.visible, "reward button shown while a reward is pending")
	_check(not w.claim() and msgs.back() == "Free some inventory space to receive reward", "needs free slot")
	var inv := FakeInventory.new(3, 0)
	var claimed: Array = []
	w.reward_claimed.connect(func(items: Array) -> void: claimed.append(items))
	w.open(inv, [{"id": 32011, "name": "Bread", "count": 2}])
	_check(w.claim() and claimed.size() == 1 and int(inv.inventory_data[0].get("id", 0)) == 32011 and not w.visible, "claim puts items in bag and closes")
	w.queue_free()


func _test_info_visibility() -> void:
	print(">>> InfoVisibility / Form_Huminfo (0x29c55c)")
	var w = InfoScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(186, 379), "Form_HumInfo_1")
	_check(w.check_boxes.size() == 11 and w.check_boxes[0].position == Vector2(19, 43) and w.check_boxes[10].position == Vector2(19, 343), "11 boxes at (19, 43+30i)")
	_check(w.btn_ok.position == Vector2(51, 372) and w.btn_close.position == Vector2(97, 372), "OK (51,372) Close (97,372)")
	_check(not w.applied.has(false), "all options start checked")
	var applied: Array = []
	var msgs := _messages(w)
	w.settings_applied.connect(func(f: Array) -> void: applied.append(f))
	w.open()
	w.toggle(9)
	_check(msgs.back() == "Unavailable" and w.pending[9], "option 10 Unavailable")
	w.toggle(0)
	w.close_window()
	_check(w.applied[0] and w.pending[0], "Close reverts")
	w.open()
	w.toggle(3)
	w.apply_and_close()
	_check(applied.size() == 1 and applied[0][3] == false and not w.applied[3], "OK applies")
	w.queue_free()


func _test_activities() -> void:
	print(">>> Activities / Form_ActionList (0x1c0204)")
	var w = ActivityScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(552, 365), "Form_ActionList_2")
	_check(w.btn_leave.position == Vector2(308, 332) and w.btn_transmi.position == Vector2(183, 332), "Leave/Transmi y=332")
	_check(w.btn_prev.position == Vector2(218, 300) and w.btn_next.position == Vector2(308, 300) and w.btn_prev.size == Vector2(56, 20), "page arrows 56x20 at y=300")
	_check(w.close_button.position == Vector2(504, 25), "close sphere (504,25)")
	_check(w.query_buttons.size() == 5 and w.query_buttons[4].position == Vector2(503, 255), "query buttons (503, 91+41i)")
	var list: Array = []
	for i in range(7):
		list.append({"name": "Event %d" % i, "start": "20:00", "end": "21:00", "status": "Open" if i != 1 else "Soon",
			"started": i != 1, "min_level": 10 if i == 2 else 0, "details": "x" if i == 0 else ""})
	var msgs := _messages(w)
	var teleports: Array = []
	w.teleport_requested.connect(func(a: Dictionary) -> void: teleports.append(a))
	w.open(list, 5)
	_check(w.row_text(0, "Name") == "Event 0" and w.row_text(0, "Start") == "20:00", "row 0 filled")
	_check(w.query_buttons[0].visible and not w.query_buttons[1].visible, "query only for rows with details")
	_check(not w.teleport() and msgs.back() == "Select activity", "Select activity")
	w.select_row(1)
	_check(not w.teleport() and msgs.back() == "Event hasn't started", "not started")
	w.select_row(2)
	_check(not w.teleport() and msgs.back() == "Level is too low", "level too low")
	w.next_page()
	_check(w.page == 1 and w.row_text(0, "Name") == "Event 5" and w.row_text(2, "Name") == "", "page 2")
	w.next_page()
	_check(w.page == 1, "no page past the end")
	w.select_row(1)
	_check(w.teleport() and teleports.size() == 1 and teleports[0]["name"] == "Event 6", "teleport to Event 6")
	w.queue_free()


func _test_battle_skill() -> void:
	print(">>> BattleSkill (0x2b5774)")
	var w = BattleSkillScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(274, 353), "Form_BattleSkill_1")
	_check(w.btn_up.position == Vector2(130, 127) and w.btn_down.position == Vector2(130, 292), "arrows (130,127)/(130,292)")
	_check(w.btn_close.position == Vector2(111, 318) and w.btn_close.size == Vector2(56, 20), "Close (111,318)")
	_check(w.upper_rows.size() == 3 and w.upper_rows[0].position == Vector2(17, 42) and w.upper_rows[2].position == Vector2(17, 98), "upper grid 3 rows pitch 28")
	_check(w.lower_rows.size() == 5 and w.lower_rows[0].position == Vector2(17, 151) and w.lower_rows[4].position + w.lower_rows[4].size == Vector2(259, 288), "lower grid 5 rows inside (17,151) 242x137")
	var skills: Array = []
	for i in range(7):
		skills.append({"id": 11000 + i, "name": "Skill %d" % i, "sp": 5 + i})
	skills.append({"id": 0x3b76, "name": "Blocked", "sp": 1, "seal_class": 1})
	var chosen: Array = []
	var msgs := _messages(w)
	w.skill_chosen.connect(func(id: int) -> void: chosen.append(id))
	w.open(skills, [{"id": 10001, "name": "Pinned", "sp": 0}])
	_check(w.btn_up.disabled and not w.btn_down.disabled, "scroll arrows state")
	w.scroll_down()
	w.scroll_down()
	w.scroll_down()
	w.scroll_down()
	_check(w.scroll == 3, "scroll stops at size-5", str(w.scroll))
	_check((w.lower_rows[0].get_node("Name") as Label).text == "Skill 3", "rows follow scroll")
	w.sealed = true
	_check(w.choose(w.row_skill(false, 0)) == -1 and msgs.back() == "Skill is sealed", "sealed refuses")
	_check(w.choose(skills[7]) == -1, "blocked id refused under seal even with allowed class")
	w.sealed = false
	_check(w.choose(w.row_skill(true, 0)) == 10001 and chosen == [10001] and not w.visible, "pick pinned skill closes")
	w.queue_free()


func _test_pet_inn() -> void:
	print(">>> Pet inn / Form_Inn (0x23d308)")
	var w = InnScene.instantiate()
	root.add_child(w)
	_skin_ok(w, Vector2(472, 476), "Form_Inn_1")
	_check(w.btn_close.position == Vector2(208, 440) and w.close_button.position == Vector2(422, 24), "Close (208,440), sphere (422,24)")
	_check(w.btn_take.position == Vector2(221, 108) and w.btn_store.position == Vector2(221, 144), "ArrowR_8 (221,108) / ArrowL_8 (221,144)")
	_check(w.inn_rows.size() == 10 and w.inn_rows[9].position == Vector2(17, 396) and w.follow_rows.size() == 4 and w.follow_rows[3].position == Vector2(244, 174), "rows pitch 37")
	_check(not w.restrain_panel.visible, "restrain panel hidden")
	var msgs := _messages(w)
	var follow: Array = [{"id": 1, "name": "Puppy", "level": 3, "hp": 40, "max_hp": 50, "loyalty": 80},
		{"id": 2, "name": "Horse", "mounted": true}, {"id": 3, "name": "Guard", "kind": "merc"}]
	w.open([{"id": 9, "name": "Old cat", "level": 7, "hp": 10, "max_hp": 70, "loyalty": 50}], follow)
	w.select(false, 1)
	_check(not w.store_selected() and msgs.back() == "Can't store when mounted", "mounted refused")
	w.select(false, 2)
	_check(not w.store_selected() and msgs.back() == "Can't store Merc", "merc refused")
	w.select(false, 0)
	_check(w.lv_label.text == "3" and w.hp_label.text == "40/50" and w.loyalty_label.text == "80", "card shows LV/HP/loyalty")
	_check(w.store_selected() and w.inn_pets.size() == 2 and w.follow_pets.size() == 2, "store Puppy")
	_check((w.inn_rows[1].get_node("Name") as Label).text == "Puppy", "Puppy listed in the inn")
	w.follow_pets.append({"id": 4, "name": "A"})
	w.follow_pets.append({"id": 5, "name": "B"})
	w.select(true, 0)
	_check(not w.withdraw_selected() and msgs.back() == "Inventory full", "follow list full")
	w.follow_pets.pop_back()
	w.select(true, 0)
	_check(w.withdraw_selected() and w.follow_pets.size() == 4 and w.inn_pets.size() == 1, "take out Old cat")
	w.queue_free()


func _test_equip_store() -> void:
	print(">>> ShopWindow Form_EquipStore skin (0x383a48)")
	var w = ShopScene.instantiate()
	root.add_child(w)
	_check(w.set_store_kind(w.StoreKind.EQUIP), "set_store_kind(EQUIP)")
	_check(w.background_rect.texture != null and w.background_rect.texture.get_size() == Vector2(409, 525), "Form_EquipStore_1 409x525")
	_check(w.set_store_kind(w.StoreKind.ACTIVITY_EXCHANGE) and w.store_kind == 3, "ActivityExchange skin")
	_check(not w.set_store_kind(99) and w.store_kind == 3, "unknown kind keeps skin")
	w.queue_free()
