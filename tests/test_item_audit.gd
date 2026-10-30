extends SceneTree

## Item audit against aLogin.exe (docs/re/item_window_and_tooltip.md):
## Item.dat field decoding, status names, type names, tooltip line order/format,
## stack limit 50 and equip_pos -> socket rules.

const ItemDatabaseClass = preload("res://scripts/database/item_database.gd")
const ItemTooltipClass = preload("res://scripts/ui/item_tooltip.gd")

var _passed: int = 0
var _failed: int = 0

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: " + msg)
	else:
		_failed += 1
		printerr("  FAIL: " + msg)

func _init() -> void:
	var db = ItemDatabaseClass.new()
	var ok: bool = db.load_from_file("res://assets/data/Item.dat")
	_check(ok, "Item.dat loads")
	_test_fields(db)
	_test_names()
	_test_tooltip_lines(db)
	_test_tooltip_node(db)
	_test_inventory_rules()
	print("RESULTS: %d PASSED, %d FAILED" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _test_fields(db) -> void:
	print("--- Item.dat fields ---")
	var knife = db.get_item(10031) # Copper Knife
	_check(knife != null and knife.has_dat_record, "10031 decoded from Item.dat")
	_check(knife.rank == 2 and knife.get_rank() == 2, "Copper Knife rank = rec+0x2D = 2 (got %d)" % knife.get_rank())
	_check(knife.level == 2, "Copper Knife LV Req = rec+0x71 = 2")
	_check(knife.buy_price == 30 and knife.sell_price == 2, "Copper Knife buy/sell = rec+0x72/0x76 = 30/2")
	_check(knife.status_types == [210, 211] and knife.status_values == [102, 102], "Copper Knife status codes 210/211 values 102/102")
	_check(knife.item_type == 1 and knife.get_type_name() == "Saber", "type 1 -> 'Saber'")
	_check(knife.grid_w == 1 and knife.grid_h == 1, "footprint 1x1 (rec+0x196/0x197)")
	var suit = db.get_item(21001) # Boy's Suit
	_check(suit.is_non_tradeable(), "Boy's Suit flags 95 has bit 2 -> non-tradeable")
	_check(not knife.is_non_tradeable(), "Copper Knife flags 0 -> tradeable")
	var wood = db.get_item(45002) # Oak Wood: hard-coded table said 3, Item.dat says 4
	_check(wood.get_rank() == 4, "Oak Wood rank comes from Item.dat (4), not the old table")
	var bread = db.get_item(32011)
	_check(bread.get_hp_restore() == 50, "Bread Hp restore still 50 (value 150 - 100)")

func _test_names() -> void:
	print("--- status/type names ---")
	_check(ItemDatabaseClass.get_status_name(211) == "DEF", "status 211 = DEF (switch 0x2a28c0)")
	_check(ItemDatabaseClass.get_status_name(210) == "ATK", "status 210 = ATK")
	_check(ItemDatabaseClass.get_status_name(214) == "SPD" and ItemDatabaseClass.get_status_name(215) == "MATK" and ItemDatabaseClass.get_status_name(216) == "MDEF", "214/215/216 = SPD/MATK/MDEF")
	_check(ItemDatabaseClass.get_status_name(25) == "Hp" and ItemDatabaseClass.get_status_name(100) == "Shoot RES", "25 = Hp, 100 = Shoot RES")
	_check(ItemDatabaseClass.format_status_line(211, -3) == "DEF: -3", "negative stat format 'DEF: -3'")
	_check(ItemDatabaseClass.get_item_type_name(16) == "Special Eq" and ItemDatabaseClass.get_item_type_name(30) == "Prop", "type 16 'Special Eq', unknown -> 'Prop'")
	_check(ItemDatabaseClass.durability_state(0)[0] == "Good" and ItemDatabaseClass.durability_state(160)[0] == "Used"
		and ItemDatabaseClass.durability_state(210)[1] == true and ItemDatabaseClass.durability_state(250)[0] == "Broken", "wear -> Good/Used/Wearing/Broken thresholds 150/200/250")

func _test_tooltip_lines(db) -> void:
	print("--- tooltip line order ---")
	var knife = db.get_item(10031)
	var lines: Array = ItemDatabaseClass.build_tooltip_lines(knife, {"forge": 3, "wear": 0})
	var texts: Array = lines.map(func(l): return str(l["text"]))
	var expected: Array = ["[ Copper Knife+3 ]", "ATK: +2 ", "DEF: +2 ", "Type: Saber", "Rank: 2", "LV Req: 2", "State: Good"]
	_check(texts.slice(0, expected.size()) == expected, "Copper Knife lines %s" % str(texts))
	_check(texts.size() == expected.size() + (1 if not knife.description.is_empty() else 0), "description is the last line")
	var suit = db.get_item(21001)
	var s_texts: Array = ItemDatabaseClass.build_tooltip_lines(suit).map(func(l): return str(l["text"]))
	_check(s_texts[1] == "<Non-tradeable>" and s_texts[2] == "DEF: +1 ", "Boy's Suit: '<Non-tradeable>' right after the name, then 'DEF: +1 '")
	var broken: Array = ItemDatabaseClass.build_tooltip_lines(knife, {"wear": 255})
	var state_line: Dictionary = {}
	for l in broken:
		if l.has("state_word"):
			state_line = l
	_check(state_line.get("state_word", "") == "Broken" and state_line.get("state_color") == ItemDatabaseClass.TOOLTIP_WARN_COLOR, "Broken state drawn in red (0xF800)")
	var compound: Array = ItemDatabaseClass.build_tooltip_lines(knife, {"compound": true}).map(func(l): return str(l["text"]))
	_check(not compound.has(knife.description) or knife.description.is_empty(), "description hidden in compound window")

func _test_tooltip_node(db) -> void:
	print("--- ItemTooltip node ---")
	var tip = ItemTooltipClass.new()
	root.add_child(tip)
	tip.display_item({"id": 10034, "name": "Iron Sword", "level": 10, "equip_pos": 3, "item_type": 2,
		"rank": 5, "description": "A sword.", "attributes": {"ATK": 12, "SPD": -2}})
	var t: PackedStringArray = tip.get_lines_text()
	_check(tip.visible and tip._title_label.text == "[ Iron Sword ]", "title '[ Iron Sword ]'")
	_check(tip._stats_container.get_child_count() == 2, "two stat labels")
	_check(t.has("ATK: +12 ") and t.has("SPD: -2 ") and t.has("Type: Sword") and t.has("Rank: 5") and t.has("LV Req: 10"), "lines %s" % str(t))
	_check(tip.size.x >= ItemTooltipClass.TOOLTIP_WIDTH, "tooltip is at least 196 px wide")
	tip.position_at(Vector2(100, 100), Vector2(34, 34))
	_check(is_equal_approx(tip.global_position.x, 136.0), "placed at slot right + 2")
	tip.queue_free()

func _test_inventory_rules() -> void:
	print("--- inventory constants ---")
	_check(ItemDatabaseClass.STACK_LIMIT == 50, "stack limit 50")
	_check(ItemDatabaseClass.BAG_SLOTS == 50 and ItemDatabaseClass.BAG_COLUMNS * ItemDatabaseClass.BAG_ROWS == 50, "bag 5x10 = 50 cells")
	var hud_inv_script = load("res://scripts/ui/hud/hud_inventory.gd")
	var inv = hud_inv_script.new()
	_check(inv._is_item_compatible_with_socket({"id": 1, "equip_pos": 6}, "special"), "equip_pos 6 -> special socket")
	_check(not inv._is_item_compatible_with_socket({"id": 1, "equip_pos": 7}, "special"), "equip_pos 7 is not equipment")
	_check(inv._is_item_compatible_with_socket({"id": 1, "equip_pos": 4}, "wrist"), "equip_pos 4 -> wrist (Hands)")
	var empty: Array[Dictionary] = [{}, {}, {}]
	inv.inventory_data = empty
	inv.add_inventory_item(32011, 30, "Bread", 1011)
	inv.add_inventory_item(32011, 45, "Bread", 1011)
	var counts: Array = inv.inventory_data.map(func(d): return int(d.get("count", 0)))
	_check(counts == [50, 25, 0], "75 Bread stack as 50 + 25 (got %s)" % str(counts))
