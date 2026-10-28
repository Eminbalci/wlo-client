class_name TestItemTooltipAndClickMarker
extends SceneTree

const ItemTooltipScene = preload("res://scripts/ui/item_tooltip.gd")
const ClickRippleScene = preload("res://scenes/fx/click_ripple.tscn")
const HUDScene = preload("res://scenes/ui/hud.tscn")

func _init() -> void:
	print("=================================================================")
	print("--- Running Test Item Tooltip & Ground Click Marker Suite ---")
	print("=================================================================")
	
	_test_click_marker()
	_test_item_tooltip()
	_test_hud_tooltip_integration()
	
	print("=================================================================")
	print("--- ALL TOOLTIP & CLICK MARKER TESTS PASSED WITH ZERO ERRORS ---")
	print("=================================================================")
	quit(0)

func _test_click_marker() -> void:
	print("\n[PART 1] Verifying Ground Click Marker...")
	var marker = ClickRippleScene.instantiate()
	assert(marker != null, "ClickMarker must instantiate")
	root.add_child(marker)
	marker._ready()
	
	assert(marker._frames.size() == 4, "ClickMarker must have 4 authentic animation frames (got %d)" % marker._frames.size())
	for i in range(4):
		assert(marker._frames[i] != null, "Frame %d must be loaded" % i)
		assert(marker._frames[i].get_size() == Vector2(64, 64), "Frame %d must be 64x64" % i)
	print("  PASS: 4 authentic 64x64 animation frames loaded")
	
	# Test frame progression
	marker._process(0.13)
	assert(marker._current_frame == 1, "Should advance to frame 1 after 0.13s (got %d)" % marker._current_frame)
	marker._process(0.13)
	assert(marker._current_frame == 2, "Should advance to frame 2 after 0.26s (got %d)" % marker._current_frame)
	print("  PASS: Frame progression at authentic 10 FPS verified")
	
	marker.queue_free()

func _test_item_tooltip() -> void:
	print("\n[PART 2] Verifying Item Tooltip Formatting & Positioning...")
	var tooltip = ItemTooltipScene.new()
	assert(tooltip != null, "ItemTooltip must instantiate")
	root.add_child(tooltip)
	
	var sample_item := {
		"id": 10034,
		"name": "Iron Sword",
		"level": 10,
		"equip_pos": 3, # Weapon
		"durability": 50,
		"max_durability": 50,
		"description": "A sturdy forged iron broadsword.",
		"attributes": {
			"ATK": 12,
			"SPD": -2
		}
	}
	
	tooltip.display_item(sample_item)
	assert(tooltip.visible, "Tooltip must become visible")
	assert(tooltip._title_label.text == "Iron Sword", "Title must match 'Iron Sword'")
	assert(tooltip._type_label.text.contains("Weapon"), "Type must indicate Weapon")
	assert(tooltip._type_label.text.contains("Req. Lv: 10"), "Type must indicate Req. Lv: 10")
	assert(tooltip._durability_label.text == "Durability: 50 / 50", "Durability must be displayed")
	assert(tooltip._desc_label.text == "A sturdy forged iron broadsword.", "Description must match")
	assert(tooltip._stats_container.get_child_count() == 2, "Must show 2 stat labels")
	print("  PASS: Item Tooltip stats, durability, type, and description formatted authentically")
	
	# Test positioning near bottom right
	tooltip.position_at(Vector2(700, 500), Vector2(34, 34))
	assert(tooltip.global_position.x < 700.0, "Tooltip must clamp to the left of slot near right edge")
	print("  PASS: Tooltip automatic bounding box positioning verified")
	
	tooltip.queue_free()

func _test_hud_tooltip_integration() -> void:
	print("\n[PART 3] Verifying HUD Tooltip Hover Hooks...")
	var hud: HUD = HUDScene.instantiate()
	assert(hud != null, "HUD must instantiate")
	root.add_child(hud)
	hud._ready()
	
	assert(hud._item_tooltip != null, "HUD must own an ItemTooltip instance")
	assert(not hud._item_tooltip.visible, "Tooltip must initially be hidden")
	
	# Seed inventory slot 0
	hud._inventory_data[0] = {
		"id": 10002,
		"name": "Bread",
		"level": 1,
		"equip_pos": 8, # Consumable
		"description": "Restores 50 HP when consumed."
	}
	
	hud.show_inventory_item_tooltip(0, Vector2(500, 300), Vector2(34, 34))
	assert(hud._item_tooltip.visible, "Tooltip must show when hovering populated slot")
	assert(hud._item_tooltip._title_label.text == "Bread", "Tooltip title must be 'Bread'")
	
	hud.hide_item_tooltip()
	assert(not hud._item_tooltip.visible, "Tooltip must hide on mouse exit")
	print("  PASS: HUD inventory slot hover & exit tooltip hooks verified")
	
	hud.queue_free()
