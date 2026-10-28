class_name TestCompoundWindowParity
extends SceneTree

const CompoundWindowClass = preload("res://scripts/ui/hud/compound_window.gd")

func _init() -> void:
	print("\n=================================================================")
	print("--- Running TestCompoundWindowParity (Authentic Cauldron & Parity) ---")
	print("=================================================================\n")

	_test_cauldron_graphics_and_connectors()
	_test_main_slot_watermark_and_item_state()
	_test_inventory_bag_grid_population_and_interaction()

	print("\n=================================================================")
	print("--- ALL COMPOUND WINDOW PARITY TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)

func _test_cauldron_graphics_and_connectors() -> void:
	print(">>> [TEST 1] Verifying authentic cauldron picture and plus connectors...")
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()

	assert(win.cauldron_rect != null, "cauldron_rect must exist")
	assert(win.cauldron_rect.texture != null, "cauldron_rect must have texture")
	assert(win.cauldron_rect.position == Vector2(198, 70), "cauldron_rect position must be (198, 70), got %s" % str(win.cauldron_rect.position))
	assert(win.cauldron_rect.size == Vector2(80, 95), "cauldron_rect size must be 80x95, got %s" % str(win.cauldron_rect.size))

	assert(win.plus_connectors.size() == 4, "Must have 4 plus connectors, got %d" % win.plus_connectors.size())
	for i in range(4):
		var p = win.plus_connectors[i]
		assert(p != null and p.texture != null, "Connector %d must have valid texture" % i)
		assert(p.size == Vector2(16, 16), "Connector %d must be 16x16" % i)

	print("  [PASS] Cauldron illustration and plus connectors verified.")
	win.queue_free()

func _test_main_slot_watermark_and_item_state() -> void:
	print(">>> [TEST 2] Verifying main slot watermark and item state...")
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()

	var main_icon: TextureRect = win.main_slot_btn.get_node_or_null("Icon") as TextureRect
	assert(main_icon != null, "Main slot Icon must exist")
	assert(main_icon.texture != null, "Main slot empty state must show cauldron watermark texture")
	assert(main_icon.modulate.a < 0.9, "Main slot watermark must be semi-transparent, got %f" % main_icon.modulate.a)

	# Place item in main slot
	var sword := {"id": 11033, "name": "Iron Sword", "icon_id": 2466, "count": 1}
	win._on_bag_item_clicked(sword, 0)
	assert(not win.main_slot_data.is_empty(), "Main slot must contain item")
	assert(main_icon.modulate == Color.WHITE, "Main slot modulate must be opaque white when filled")

	# Click main slot to return to bag
	win._on_main_slot_clicked()
	assert(win.main_slot_data.is_empty(), "Main slot must be empty after clicking")
	assert(main_icon.texture != null, "Main slot must show watermark again")
	assert(main_icon.modulate.a < 0.9, "Main slot must return to semi-transparent watermark")

	print("  [PASS] Main slot watermark and item state transitions verified.")
	win.queue_free()

func _test_inventory_bag_grid_population_and_interaction() -> void:
	print(">>> [TEST 3] Verifying 50-slot inventory bag grid population and interactions...")
	var win = CompoundWindowClass.new()
	root.add_child(win)
	win._ready()

	assert(win.grid_container != null, "GridBag must exist")
	assert(win.grid_container.columns == 5, "GridBag columns must be 5")
	assert(win._bag_slot_buttons.size() == 50, "GridBag must have 50 slot buttons, got %d" % win._bag_slot_buttons.size())

	# Bag should have default materials populated when HUD inventory is absent
	assert(win._inventory_items.size() > 0, "Bag must have items populated")
	var first_item: Dictionary = win._inventory_items[0]
	assert(int(first_item.get("id", 0)) > 0, "First item must have valid id")

	# Transfer to main slot and sub slots
	var initial_count: int = win._inventory_items.size()
	win._on_bag_item_clicked(win._inventory_items[0], 0)
	assert(not win.main_slot_data.is_empty(), "Main slot must be filled")
	win._on_bag_item_clicked(win._inventory_items[0], 0)
	assert(not win.sub_slots_data[0].is_empty(), "Sub slot 0 must be filled")

	# Close window returns all placed items
	win.close_window()
	assert(win.main_slot_data.is_empty(), "Main slot must be cleared on close")
	assert(win.sub_slots_data[0].is_empty(), "Sub slot 0 must be cleared on close")

	print("  [PASS] Inventory bag grid population and slot transfer interactions verified.")
	win.queue_free()
