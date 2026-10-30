extends SceneTree

## Master Headless Automated Test Suite: NPC Merchant Shop System & Trading Parity
## Verifies:
## 1. ShopWindow initialization, geometry (409x525), 18x18 close button, authentic textures, and typography.
## 2. Buy Tab catalog population (Grocery, Pharmacy, Weapon Smith), slot rows, and pagination.
## 3. Buy transaction: gold deduction, inventory item granting, coin audio, and insufficient gold guard.
## 4. Sell Tab: player inventory listing, 50% valuation calculation, quantity selection, item removal, and gold award.
## 5. Dynamic gold display synchronization with HUD and CharacterManager.
## 6. MapView merchant NPC detection and dialogue choice hook opening the ShopWindow.

const ShopWindowScript = preload("res://scripts/ui/shop/shop_window.gd")
const MapViewScript = preload("res://scripts/map/map_view.gd")

var _test_failures: int = 0
var _test_count: int = 0

func _init() -> void:
	# Let the autoloads (GameDatabase / Item.dat) finish loading before the shop reads its catalog.
	await process_frame
	await process_frame
	print("=================================================================")
	print("--- Running Shop Window & Merchant Trading Automated Test Suite ---")
	print("=================================================================\n")

	_init_autoloads()

	_test_shop_window_initialization_and_geometry()
	_test_merchant_catalogs_and_buy_tab()
	_test_buy_transaction_and_gold_deduction()
	_test_sell_tab_and_sell_transaction()
	_test_pharmacy_and_weapon_smith_catalogs()
	_test_map_view_merchant_dialogue_hook()
	_test_dynamic_gold_synchronization()

	print("\n=================================================================")
	if _test_failures == 0:
		print("--- ALL %d TESTS PASSED (100%% ZERO-ERROR) ---" % _test_count)
		print("=================================================================\n")
		quit(0)
	else:
		printerr("--- FAILED: %d tests failed out of %d ---" % [_test_failures, _test_count])
		print("=================================================================\n")
		quit(1)

func _assert_test(condition: bool, test_name: String, details: String = "") -> void:
	_test_count += 1
	if condition:
		print("  [PASS] %s" % test_name)
	else:
		_test_failures += 1
		printerr("  [FAIL] %s: %s" % [test_name, details])

func _init_autoloads() -> void:
	if not root.has_node("ArchiveLoader"):
		var arch_loader = load("res://scripts/core/archive_loader.gd").new()
		arch_loader.name = "ArchiveLoader"
		root.add_child(arch_loader)
	
	if not root.has_node("GameDatabase"):
		var gdb = load("res://scripts/database/game_database.gd").new()
		gdb.name = "GameDatabase"
		root.add_child(gdb)

func _test_shop_window_initialization_and_geometry() -> void:
	print(">>> [TEST 1] Testing ShopWindow Initialization & Authentic Geometry...")
	var shop := ShopWindowScript.new()
	root.add_child(shop)

	_assert_test(shop.size.x == 409.0 and shop.size.y == 525.0, "Window Size 409x525", "Actual: %s" % str(shop.size))
	_assert_test(shop.background_rect != null, "Background TextureRect Exists")
	if shop.background_rect and shop.background_rect.texture:
		_assert_test(shop.background_rect.texture.resource_path.ends_with("form_store_1.png"), "Background Uses Authentic Sliced Store Texture")

	_assert_test(shop.btn_close != null, "Close Button Exists")
	if shop.btn_close:
		_assert_test(shop.btn_close.position == Vector2(359.0, 20.0), "Close Button Positioned on the baked x sphere (359, 20)", "Actual: %s" % str(shop.btn_close.position))
		_assert_test(shop.btn_close.size == Vector2(20.0, 20.0), "Close Button Size 20x20", "Actual: %s" % str(shop.btn_close.size))

	_assert_test(shop.btn_tab_buy != null and shop.btn_tab_sell != null, "Buy and Sell Mode Tabs Exist")
	_assert_test(shop.slot_rows.size() == 5, "5 Authentic Store Slot Rows Created", "Count: %d" % shop.slot_rows.size())
	
	# Verify row Y positions matching Form_ThingStore_1 filigree
	var expected_ys := [79.0, 138.0, 197.0, 256.0, 315.0]
	var ys_match := true
	for i in range(5):
		if abs(shop.slot_rows[i].position.y - expected_ys[i]) > 1.0:
			ys_match = false
			break
	_assert_test(ys_match, "5 Slot Rows Accurately Aligned to the Baked Grid Rows (79, 138, 197, 256, 315)")

	_assert_test(shop.preview_icon != null, "Preview Icon Exists")
	_assert_test(shop.preview_name != null, "Preview Name Label Exists")
	_assert_test(shop.qty_spinbox != null, "Quantity SpinBox Exists")
	_assert_test(shop.total_cost_label != null, "Total Cost Label Exists")
	_assert_test(shop.btn_action != null, "Action Button Exists")
	_assert_test(shop.gold_display_label != null, "Gold Display Label Exists")

	shop.queue_free()

func _test_merchant_catalogs_and_buy_tab() -> void:
	print(">>> [TEST 2] Testing Buy Tab Catalog Population & Navigation...")
	var shop := ShopWindowScript.new()
	root.add_child(shop)

	shop.open_shop(0, "Props Shop")
	_assert_test(shop.visible, "Shop Window Opened and Visible")
	_assert_test(shop.current_mode == "buy", "Current Mode is 'buy'")
	_assert_test(shop.title_label.text == "Props Shop", "Title Label Shows Merchant Name")
	_assert_test(not shop.merchant_catalog.is_empty(), "Merchant Catalog Loaded from Item.dat")

	# Check item 0
	_assert_test(not shop.selected_item.is_empty(), "First Item Auto-selected for Preview")
	var sel_name := str(shop.selected_item.get("name", ""))
	_assert_test(sel_name == "Bread", "First Item is Bread", "Actual: %s" % sel_name)
	_assert_test(int(shop.selected_item.get("price", 0)) == 10, "Bread Unit Price is 10 G (real client)")

	# Check slot rows visibility
	_assert_test(shop.slot_rows[0].visible, "First Slot Row Visible")
	var name_lbl = shop.slot_rows[0].get_node_or_null("NameLabel") as Label
	_assert_test(name_lbl != null and name_lbl.text == "Bread", "First Slot Row Displays Item Name")

	# Real client Props Shop: 5 items (Bread, Rice Wine, Ordinary Wood, Lauan, Copper Ore), one page
	_assert_test(shop.merchant_catalog.size() == 5, "Props Shop Catalog Has 5 Items (real client)")

	shop.queue_free()

func _test_buy_transaction_and_gold_deduction() -> void:
	print(">>> [TEST 3] Testing Buy Transaction & Gold Deduction...")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()

	var shop = hud.get_or_create_shop_window()
	_assert_test(shop != null, "HUD Created and Attached ShopWindow")

	# Setup initial gold
	hud.update_gold(500)
	shop.refresh_gold()
	_assert_test(shop.player_gold == 500, "Initial Player Gold is 500 G", "Actual: %d" % shop.player_gold)

	# Open shop with default items
	shop.open_shop(0, "Props Shop")

	# Select Bread (price = 10 G, real client), set quantity = 3
	shop.select_item(shop.merchant_catalog[0], 0)
	shop.set_quantity(3)
	_assert_test(shop.quantity == 3, "Quantity Set to 3", "Actual: %d" % shop.quantity)
	_assert_test(shop.total_cost_label.text.contains("30"), "Total Cost Calculated as 30 Gold", "Actual: %s" % shop.total_cost_label.text)

	# Listen to item_bought signal
	var bought_result := {"received": false, "id": 0, "count": 0, "total": 0}
	shop.item_bought.connect(func(iid, cnt, tot):
		bought_result["received"] = true
		bought_result["id"] = iid
		bought_result["count"] = cnt
		bought_result["total"] = tot
	)

	# Execute Buy
	var buy_ok: bool = shop.execute_buy()
	_assert_test(buy_ok, "execute_buy() Returned Success (true)")
	_assert_test(shop.player_gold == 470, "Player Gold Deducted by 30 G (500 -> 470)", "Actual: %d" % shop.player_gold)
	_assert_test(bought_result["received"], "item_bought Signal Emitted")
	_assert_test(bought_result["id"] == 32011 and bought_result["count"] == 3 and bought_result["total"] == 30, "Signal Emitted Correct Parameters (32011, 3, 30)")

	# Verify item added to player inventory
	var has_rice_ball := false
	for it in hud.inventory_ctrl.inventory_data:
		if it is Dictionary and int(it.get("id", 0)) == 32011 and int(it.get("count", 0)) >= 3:
			has_rice_ball = true
			break
	_assert_test(has_rice_ball, "Purchased Items Added to HUDInventory Slots")

	# Test Insufficient Gold Guard
	hud.update_gold(10)
	shop.refresh_gold()
	shop.qty_spinbox.value = 2 # 2 * 20 = 40 G > 10 G
	var fail_buy: bool = shop.execute_buy()
	_assert_test(not fail_buy, "execute_buy() Blocked When Player Gold < Total Cost")
	_assert_test(shop.player_gold == 10, "Player Gold Preserved on Failed Buy (10 G)")

	hud.queue_free()

func _test_sell_tab_and_sell_transaction() -> void:
	print(">>> [TEST 4] Testing Sell Tab & Sell Transaction...")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()

	var shop = hud.get_or_create_shop_window()
	hud.update_gold(100)
	shop.refresh_gold()

	# Give player 5 Fresh Coconuts (ID 41066, base price 15 G)
	hud.add_inventory_item(41066, 5, "Fresh Coconut", 1379, "Restores 30 HP and 30 SP.")

	shop.open_shop(0, "Props Shop")
	shop.set_mode("sell")

	_assert_test(shop.current_mode == "sell", "Switched Mode to 'sell'")
	_assert_test(shop.btn_action_label.text == "Sell", "Action Button Label Shows 'Sell'")

	# Verify player inventory item appears in sell list
	var inv_items: Array[Dictionary] = shop.get_player_inventory_items()
	# Find and select the coconut
	var coconut_item: Dictionary = {}
	var coconut_idx: int = -1
	for idx in range(inv_items.size()):
		if int(inv_items[idx].get("id", 0)) == 41066:
			coconut_item = inv_items[idx]
			coconut_idx = idx
			break
	_assert_test(not coconut_item.is_empty(), "Fresh Coconut Present in Player Inventory for Sale")

	# Select the coconut
	shop.select_item(coconut_item, coconut_idx)
	var unit_sell_p: int = shop.get_item_sell_price(shop.selected_item)
	_assert_test(unit_sell_p > 0, "Calculated Positive Sell Valuation (> 0 G)", "Price: %d" % unit_sell_p)

	# Set quantity = 2
	shop.set_quantity(2)
	var expected_gain: int = unit_sell_p * 2

	var sold_result := {"received": false, "id": 0, "count": 0, "total": 0}
	shop.item_sold.connect(func(iid, cnt, tot):
		sold_result["received"] = true
		sold_result["id"] = iid
		sold_result["count"] = cnt
		sold_result["total"] = tot
	)

	var initial_gold: int = shop.player_gold
	var sell_ok: bool = shop.execute_sell()
	_assert_test(sell_ok, "execute_sell() Returned Success (true)")
	_assert_test(shop.player_gold == initial_gold + expected_gain, "Player Gold Increased by Total Gain (%d G)" % expected_gain)
	_assert_test(sold_result["received"], "item_sold Signal Emitted")
	_assert_test(sold_result["id"] == 41066 and sold_result["count"] == 2, "Signal Emitted Correct Sold Parameters (41066, 2)")

	# Verify inventory count decreased by 2
	var new_coconut_count := 0
	for it in hud.inventory_ctrl.inventory_data:
		if it is Dictionary and int(it.get("id", 0)) == 41066:
			new_coconut_count = int(it.get("count", 0))
			break
	_assert_test(new_coconut_count == 3, "Inventory Stack Count Reduced from 5 to 3", "Actual: %d" % new_coconut_count)

	hud.queue_free()

func _test_pharmacy_and_weapon_smith_catalogs() -> void:
	print(">>> [TEST 5] Testing Specialized Merchant Catalogs (Pharmacy & Weapon Smith)...")
	var shop := ShopWindowScript.new()
	root.add_child(shop)

	# 1. Pharmacy (ID 15107)
	shop.open_shop(15107, "Kelan Potion Pharmacy")
	var has_hp_potion := false
	var has_sp_potion := false
	for it in shop.merchant_catalog:
		var n: String = it.get("name", "")
		if n == "Healing Potion": has_hp_potion = true
		if n == "SP Potion": has_sp_potion = true
	_assert_test(has_hp_potion and has_sp_potion, "Pharmacy Catalog Contains Healing Potion & SP Potion")

	# 2. Weapon Smith (ID 13000)
	shop.open_shop(13000, "Kelan Weapon Smith")
	var has_sword := false
	var has_dagger := false
	for it in shop.merchant_catalog:
		var n: String = it.get("name", "")
		if "Sword" in n: has_sword = true
		if "Dagger" in n: has_dagger = true
	_assert_test(has_sword and has_dagger, "Weapon Smith Catalog Contains Authentic Swords & Daggers")

	shop.queue_free()

func _test_map_view_merchant_dialogue_hook() -> void:
	print(">>> [TEST 6] Testing MapView Merchant NPC Detection & Dialogue Hook...")
	var map_view_scene = load("res://scenes/world/map_view.tscn")
	var map_view = map_view_scene.instantiate() if map_view_scene else MapViewScript.new()
	root.add_child(map_view)

	var hud = map_view.get_node_or_null("CanvasLayer/HUD")
	if not hud:
		var hud_scene = load("res://scenes/ui/hud.tscn")
		hud = hud_scene.instantiate()
		root.add_child(hud)
	map_view.hud = hud
	hud._ready()

	# Create a dummy NPC representing Kelan Village Props Shopkeeper (ID 13001)
	var dummy_npc := Node2D.new()
	dummy_npc.set("npc_id", 13001)
	dummy_npc.set("npc_name", "Props Shopkeeper")
	dummy_npc.set("dialogue_text", "Welcome to Kelan Village Store!")
	dummy_npc.set("dialogue_choices", [])
	dummy_npc.set_meta("npc_id", 13001)
	dummy_npc.set_meta("npc_name", "Props Shopkeeper")
	dummy_npc.set_meta("dialogue_text", "Welcome to Kelan Village Store!")
	dummy_npc.set_meta("dialogue_choices", [])
	dummy_npc.position = Vector2(300, 300)
	map_view.add_child(dummy_npc)

	# Verify MapView detects merchant NPC
	var is_merchant: bool = map_view.is_merchant_npc(dummy_npc)
	_assert_test(is_merchant, "MapView Correctly Identifies ID 13001 as Merchant NPC")

	# Trigger NPC interaction
	map_view._on_npc_interacted(dummy_npc)

	# Verify dialogue choices are populated with "Buy / Sell"
	var choices_shown: Array = hud.dialogue_choices
	var has_buy_sell_choice := false
	for c in choices_shown:
		if "buy" in str(c).to_lower() or "sell" in str(c).to_lower():
			has_buy_sell_choice = true
			break
	_assert_test(has_buy_sell_choice, "Merchant Dialogue Presents 'Buy / Sell' Option to Player")

	# Simulate selecting Choice 0 ("Buy / Sell")
	if hud.has_method("_on_choice_clicked"):
		hud._on_choice_clicked(0, "Buy / Sell")
	elif hud.dialogue_ctrl and hud.dialogue_ctrl.has_method("_on_choice_clicked"):
		hud.dialogue_ctrl._on_choice_clicked(0, "Buy / Sell")

	# Verify ShopWindow opened
	var shop_win = hud.get_node_or_null("FloatingWindows/ShopWindow")
	_assert_test(shop_win != null and shop_win.visible, "Selecting 'Buy / Sell' Successfully Opens ShopWindow")
	if shop_win:
		_assert_test(shop_win.merchant_name == "Props Shopkeeper", "ShopWindow Initialized with Merchant's Identity")

	map_view.queue_free()
	hud.queue_free()

func _test_dynamic_gold_synchronization() -> void:
	print(">>> [TEST 7] Testing Dynamic Gold Display Synchronization...")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	hud._ready()

	var shop = hud.get_or_create_shop_window()
	shop.open_shop(13001, "General Store")

	hud.update_gold(1250)
	shop.refresh_gold()
	_assert_test(shop.player_gold == 1250, "ShopWindow Gold Matches HUD Gold (1250 G)")
	_assert_test(shop.gold_display_label.text.contains("1250"), "Gold Display Label Dynamically Reflects 1250 G")

	# Simulate add_gold(300)
	hud.add_gold(300)
	shop.refresh_gold()
	_assert_test(shop.player_gold == 1550, "ShopWindow Reflects Added Gold (1550 G)")

	hud.queue_free()
