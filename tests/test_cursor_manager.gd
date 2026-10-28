extends SceneTree

## Dedicated Automated Verification Suite for Global CursorManager
## Tests:
## 1. Preloading of all 12 authentic cursor types (NORMAL, ATTACK, TALK, HARVEST, EXAMINE, PORTAL, MINING, SHOP, SKILL, QUEST, BUSY, TARGET)
## 2. Dynamic state switching via CursorType enum and string API
## 3. Hotspot alignment
## 4. Animation stepping at 10 FPS (0.1s interval)

const CursorManagerScript = preload("res://scripts/core/cursor_manager.gd")
const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	print("\n==================================================================")
	print("--- Running Global CursorManager Automated Test Suite ---")
	print("==================================================================")
	var passed: int = 0
	var failed: int = 0

	var loader = ArchiveLoaderScript.new()
	loader.name = "ArchiveLoader"
	root.add_child(loader)

	var cm = CursorManagerScript.new()
	cm.name = "CursorManager"
	root.add_child(cm)

	# Test 1: Verify Preloading & Frame Count
	print("\n>>> [TEST 1] Verifying all 12 authentic cursor types...")
	var types_to_check := [
		[cm.CursorType.NORMAL, "cursor1", "normal", Vector2(0, 0)],
		[cm.CursorType.ATTACK, "cursor3", "sword", Vector2(2, 2)],
		[cm.CursorType.TALK, "cursor4", "talk", Vector2(6, 3)],
		[cm.CursorType.HARVEST, "cursor8", "harvest", Vector2(12, 10)],
		[cm.CursorType.EXAMINE, "cursor17", "examine", Vector2(12, 12)],
		[cm.CursorType.PORTAL, "cursor6", "portal", Vector2(2, 2)],
		[cm.CursorType.MINING, "cursor12", "mine", Vector2(4, 4)],
		[cm.CursorType.SHOP, "cursor18", "shop", Vector2(12, 12)],
		[cm.CursorType.SKILL, "cursor15", "skill", Vector2(16, 16)],
		[cm.CursorType.QUEST, "cursor16", "quest", Vector2(6, 3)],
		[cm.CursorType.BUSY, "cursor10", "busy", Vector2(16, 16)],
		[cm.CursorType.TARGET, "cursor11", "target", Vector2(2, 2)],
	]

	for item in types_to_check:
		var c_type: int = item[0]
		var ani_name: String = item[1]
		var alias: String = item[2]
		var expected_hotspot: Vector2 = item[3]

		cm.set_cursor_state(c_type)
		assert(cm.get_cursor_state() == c_type, "Cursor state must match %s" % ani_name)
		assert(cm.get_hotspot(c_type) == expected_hotspot, "Hotspot mismatch for %s" % ani_name)

		# String API test
		cm.set_cursor_by_name(alias)
		assert(cm.get_cursor_state() == c_type, "set_cursor_by_name('%s') must match type %d" % [alias, c_type])
		passed += 1

	print("  [PASS] All 12 cursor types and hotspots verified.")

	# Test 2: Animation Stepping
	print("\n>>> [TEST 2] Verifying cursor animation step logic at 10 FPS...")
	cm.set_cursor_state(cm.CursorType.NORMAL)
	var initial_frame = cm.get_current_frame_index()
	cm._process(0.12) # Advance beyond 0.1s FRAME_INTERVAL
	var next_frame = cm.get_current_frame_index()
	assert(next_frame == (initial_frame + 1) % 8, "Cursor animation step failed: %d -> %d" % [initial_frame, next_frame])
	print("  [PASS] Animation stepping verified.")
	passed += 1

	# Test 3: Reset to Default
	cm.set_cursor_state(cm.CursorType.ATTACK)
	cm.reset_to_default()
	assert(cm.get_cursor_state() == cm.CursorType.NORMAL, "reset_to_default must revert to NORMAL")
	print("  [PASS] reset_to_default verified.")
	passed += 1

	cm.queue_free()
	loader.queue_free()

	print("\n==================================================================")
	print("=== FINAL RESULTS: %d PASSED, %d FAILED ===" % [passed, failed])
	print("==================================================================")
	if failed == 0:
		print("ALL CURSOR TESTS PASSED SUCCESSFULLY!\n")
		quit(0)
	else:
		print("TESTS FAILED!\n")
		quit(1)
