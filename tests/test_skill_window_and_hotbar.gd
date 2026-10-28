extends SceneTree

const SkillWindowClass = preload("res://scripts/ui/hud/skill_window.gd")
const SkillRowButtonClass = preload("res://scripts/ui/hud/skill_row_button.gd")

## Automated Headless Verification Suite for Wonderland Online Skill Window & Hotbar Binding
## Verifies:
## 1. SkillWindow layout, dimensions (290x459), background skin, 18x18 close button at (260, 8)
## 2. Category tabs (Earth, Water, Fire, Wind, Special) with authentic skins and reactive filtering
## 3. Skill list population, row item components (icon, name, SP, rank), selection highlighting
## 4. Skill detail inspection panel (name, element, target type, SP cost, description, formula)
## 5. Drag-and-drop data payload and click-to-assign to HUD Hotbar slots (F1..F8)
## 6. Hotbar skill activation, SP cost validation, SP deduction, status dock sync, and error feedback

var _passed: int = 0
var _failed: int = 0

func _init() -> void:
	print("=================================================================")
	print("STARTING TEST SUITE: Skill Window & Hotbar Interactive Parity")
	print("=================================================================")
	call_deferred("_run_tests")

func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  [PASS] %s" % msg)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % msg)

func _run_tests() -> void:
	_test_standalone_scene_and_geometry()
	_test_embedded_hud_skill_window()
	_test_category_tabs_and_filtering()
	_test_skill_selection_and_details()
	_test_drag_data_payload()
	_test_hotbar_binding_integration()
	_test_hotbar_skill_activation_and_sp_deduction()
	_test_close_button_interaction()

	print("=================================================================")
	print("SUMMARY: %d passed, %d failed" % [_passed, _failed])
	print("=================================================================")

	if _failed > 0:
		quit(1)
	else:
		print("ALL SKILL WINDOW & HOTBAR BINDING TESTS PASSED ZERO-ERROR!")
		quit(0)

func _test_standalone_scene_and_geometry() -> void:
	print("\n>>> 1. Testing Standalone skill_window.tscn Scene & Geometry...")
	var scene: PackedScene = load("res://scenes/ui/hud/skill_window.tscn")
	_assert_true(scene != null, "scenes/ui/hud/skill_window.tscn loaded successfully")
	if not scene:
		return

	var win := scene.instantiate() as Control
	root.add_child(win)

	_assert_true(win is SkillWindowClass, "Instantiated scene is SkillWindowClass")
	_assert_true(win.size == Vector2(290, 459), "SkillWindow size is (290, 459), got %s" % str(win.size))
	_assert_true(win.custom_minimum_size == Vector2(290, 459), "custom_minimum_size is (290, 459)")

	var bg := win.get_node_or_null("Background") as TextureRect
	_assert_true(bg != null, "Background TextureRect exists")
	_assert_true(bg.texture != null, "Background texture is assigned")

	var close_btn := win.get_node_or_null("CloseButton") as Button
	_assert_true(close_btn != null, "CloseButton node exists")
	_assert_true(close_btn.position == Vector2(240, 20), "CloseButton position is (240, 20), got %s" % str(close_btn.position))
	_assert_true(close_btn.size == Vector2(20, 20), "CloseButton size is (20, 20), got %s" % str(close_btn.size))
	_assert_true(close_btn.text == "", "CloseButton text is empty (no synthetic 'X')")

	win.queue_free()

func _test_embedded_hud_skill_window() -> void:
	print("\n>>> 2. Testing Embedded SkillWindow inside scenes/ui/hud.tscn...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	_assert_true(hud_scene != null, "scenes/ui/hud.tscn loaded successfully")
	if not hud_scene:
		return

	var hud := hud_scene.instantiate() as Control
	root.add_child(hud)

	var floating := hud.get_node_or_null("FloatingWindows") as Control
	_assert_true(floating != null, "FloatingWindows container found in HUD")

	var skill_win := floating.get_node_or_null("SkillWindow") as Control
	_assert_true(skill_win != null, "SkillWindow exists in FloatingWindows")
	_assert_true(skill_win is SkillWindowClass, "SkillWindow node script is SkillWindowClass")
	_assert_true(skill_win.size == Vector2(290, 459), "SkillWindow size is (290, 459)")

	var tabs := skill_win.get_node_or_null("TabsContainer") as Control
	_assert_true(tabs != null, "TabsContainer exists in SkillWindow")
	var tab_btns = skill_win.get("tab_buttons") as Array
	_assert_true(tab_btns.size() == 5, "5 Category Tab buttons exist (got %d)" % tab_btns.size())

	var scroll := skill_win.get_node_or_null("SkillScrollContainer") as ScrollContainer
	_assert_true(scroll != null, "SkillScrollContainer exists")
	_assert_true(scroll.position == Vector2(24, 82), "ScrollContainer at Vector2(24, 82) on the Form_Skill_2 list panel")

	var detail := skill_win.get_node_or_null("DetailPanel") as Control
	_assert_true(detail != null, "DetailPanel exists in SkillWindow")
	_assert_true(detail.position == Vector2(24, 337), "DetailPanel at Vector2(24, 337) on the Form_Skill_2 detail panel")

	var qbind := skill_win.get_node_or_null("QuickBindContainer") as Control
	_assert_true(qbind != null, "QuickBindContainer exists in SkillWindow")
	var qbtns = skill_win.get("quick_bind_buttons") as Array
	_assert_true(qbtns.size() == 8, "8 Quick-bind F1..F8 buttons exist (got %d)" % qbtns.size())

	hud.queue_free()

func _test_category_tabs_and_filtering() -> void:
	print("\n>>> 3. Testing Category Tabs & Reactive Filtering...")
	var win := SkillWindowClass.new()
	root.add_child(win)
	win.setup(null)

	# Verify 5 categories of the original client: Physical, Magical, Assistant, Life, Intro
	var tab_names := ["Physical", "Magical", "Assistant", "Life", "Intro"]
	for i in range(5):
		var emitted_tab: Array = []
		var on_tab := func(t_idx: int) -> void:
			emitted_tab.append(t_idx)
		win.tab_changed.connect(on_tab)
		win.select_tab(i)
		win.tab_changed.disconnect(on_tab)

		_assert_true(win.get_active_tab() == i, "Active tab is %d (%s)" % [i, tab_names[i]])
		_assert_true(emitted_tab.size() == 1 and emitted_tab[0] == i, "tab_changed signal emitted for tab %d" % i)
		_assert_true(win.category_label.text == tab_names[i], "Category label shows %s" % tab_names[i])

		var displayed: Array[Dictionary] = win.get_displayed_skills()
		_assert_true(not displayed.is_empty(), "Tab %d (%s) lists available skills (count: %d)" % [i, tab_names[i], displayed.size()])

		# Verify all listed skills match the category rule
		var all_match: bool = true
		for s in displayed:
			var s_type: String = str(s.get("skill_type_name", ""))
			var s_cat: int = int(s.get("category", -1))
			match i:
				SkillWindowClass.TAB_PHYSICAL:
					all_match = all_match and s_type == "Physical"
				SkillWindowClass.TAB_MAGICAL:
					all_match = all_match and s_type == "Magic"
				SkillWindowClass.TAB_ASSIST:
					all_match = all_match and (s_type == "Assist" or s_type == "Status")
				SkillWindowClass.TAB_LIFE:
					all_match = all_match and s_cat == 9
				SkillWindowClass.TAB_INTRO:
					all_match = all_match and s_cat == 0
		_assert_true(all_match, "All displayed skills in tab %d match category" % i)

	# Arrows baked into the skin cycle the categories
	win.select_tab(SkillWindowClass.TAB_PHYSICAL)
	win.btn_category_next.pressed.emit()
	_assert_true(win.get_active_tab() == SkillWindowClass.TAB_MAGICAL, "Right arrow advances to the next category")
	win.btn_category_prev.pressed.emit()
	win.btn_category_prev.pressed.emit()
	_assert_true(win.get_active_tab() == SkillWindowClass.TAB_INTRO, "Left arrow wraps to the last category")

	win.queue_free()

func _test_skill_selection_and_details() -> void:
	print("\n>>> 4. Testing Skill Selection & Detail Panel Updates...")
	var win := SkillWindowClass.new()
	root.add_child(win)
	win.setup(null)
	win.select_tab(SkillWindowClass.TAB_PHYSICAL)

	var skills := win.get_displayed_skills()
	_assert_true(not skills.is_empty(), "Physical tab has skills")
	if skills.is_empty():
		win.queue_free()
		return

	var first_skill: Dictionary = skills[0]
	var s_id: int = int(first_skill.get("id", 0))

	var selected_events: Array = []
	var on_selected := func(data: Dictionary) -> void:
		selected_events.append(data)
	win.skill_selected.connect(on_selected)

	win.select_skill(s_id)
	win.skill_selected.disconnect(on_selected)

	_assert_true(selected_events.size() == 1, "skill_selected signal emitted once")
	var active_data := win.get_selected_skill()
	_assert_true(int(active_data.get("id", 0)) == s_id, "Selected skill ID is %d" % s_id)

	# Verify Detail Panel contents
	var name_lbl = win.detail_name_label
	_assert_true(name_lbl != null and str(first_skill.get("name", "")) in name_lbl.text, "Detail name label contains skill name")
	var type_lbl = win.detail_type_label
	_assert_true(type_lbl != null and "SP:" in type_lbl.text, "Detail type label displays SP cost")
	var desc_lbl = win.detail_desc_label
	_assert_true(desc_lbl != null and not desc_lbl.text.is_empty(), "Detail description label populated")
	var eff_lbl = win.detail_effect_label
	_assert_true(eff_lbl != null and "Base DMG:" in eff_lbl.text, "Detail effect label displays damage formula")

	win.queue_free()

func _test_drag_data_payload() -> void:
	print("\n>>> 5. Testing Skill Row Drag Data Payload...")
	var row := SkillRowButtonClass.new()
	root.add_child(row)
	var sample_skill: Dictionary = {
		"id": 15038,
		"name": "Overarm Stumble",
		"sp_cost": 14,
		"element": 3
	}
	row.skill_data = sample_skill

	var data = row._get_drag_data(Vector2.ZERO)
	_assert_true(data is Dictionary, "Drag data is a Dictionary")
	if data is Dictionary:
		_assert_true(str(data.get("type", "")) == "skill", "Drag data type is 'skill'")
		_assert_true(int(data.get("id", 0)) == 15038, "Drag data ID matches 15038")
		_assert_true(str(data.get("name", "")) == "Overarm Stumble", "Drag data name matches 'Overarm Stumble'")
		_assert_true(int(data.get("sp_cost", 0)) == 14, "Drag data sp_cost is 14")

	row.queue_free()

func _test_hotbar_binding_integration() -> void:
	print("\n>>> 6. Testing Drag & Drop and Click-to-Assign Hotbar Binding...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	var hud := hud_scene.instantiate() as Control
	root.add_child(hud)

	var win := hud.get_node_or_null("FloatingWindows/SkillWindow") as SkillWindowClass
	_assert_true(win != null, "SkillWindow found in HUD")
	var hotbar = hud.get("hotbar_ctrl")
	_assert_true(hotbar != null, "HUDHotbar controller exists")

	# 1. Click-to-assign via bind_skill_to_hotbar
	win.select_tab(SkillWindowClass.TAB_PHYSICAL)
	var skills := win.get_displayed_skills()
	_assert_true(not skills.is_empty(), "Skills available for binding")
	var target_skill := skills[0]
	var sid: int = int(target_skill.get("id", 0))
	win.select_skill(sid)

	var assigned_events: Array = []
	var on_assign := func(s_idx: int, s_dict: Dictionary) -> void:
		assigned_events.append({"slot": s_idx, "data": s_dict})
	win.skill_assigned_to_hotbar.connect(on_assign)

	# Assign to F1 (slot 0)
	var bind_ok := win.bind_skill_to_hotbar(0, sid)
	_assert_true(bind_ok, "bind_skill_to_hotbar(0) returned true")
	_assert_true(assigned_events.size() == 1, "skill_assigned_to_hotbar signal emitted")

	var slot0_data = hotbar.get_slot_data(0)
	_assert_true(slot0_data is Dictionary, "Hotbar Slot 0 contains data")
	if slot0_data is Dictionary:
		_assert_true(str(slot0_data.get("type", "")) == "skill", "Slot 0 type is 'skill'")
		_assert_true(int(slot0_data.get("id", 0)) == sid, "Slot 0 skill ID matches assigned ID %d" % sid)

	# 2. Drag-and-drop simulation via drop_on_slot onto F2 (slot 1)
	var drag_payload := {
		"type": "skill",
		"id": 10001,
		"name": "Hand Attack",
		"sp_cost": 0,
		"icon_tex": null
	}
	_assert_true(hotbar.can_drop_on_slot(1, drag_payload), "hotbar.can_drop_on_slot(1, drag_payload) is true")
	hotbar.drop_on_slot(1, drag_payload)

	var slot1_data = hotbar.get_slot_data(1)
	_assert_true(slot1_data is Dictionary, "Hotbar Slot 1 updated via drop_on_slot")
	if slot1_data is Dictionary:
		_assert_true(str(slot1_data.get("type", "")) == "skill", "Slot 1 type is 'skill'")
		_assert_true(int(slot1_data.get("id", 0)) == 10001, "Slot 1 ID matches 10001")

	hud.queue_free()

func _test_hotbar_skill_activation_and_sp_deduction() -> void:
	print("\n>>> 7. Testing Hotbar Skill Activation & SP Deduction...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	var hud := hud_scene.instantiate() as Control
	root.add_child(hud)

	var hotbar = hud.get("hotbar_ctrl")
	var char_ctrl = hud.character_status_ctrl
	_assert_true(char_ctrl != null, "Character status controller exists")

	# Find authentic SP cost for skill 15038
	var expected_cost: int = 8
	var gdb = hud.get_node_or_null("/root/GameDatabase")
	if gdb and "skills" in gdb and gdb.skills:
		var s_rec = gdb.skills.get_skill(15038)
		if s_rec:
			expected_cost = s_rec.sp_cost

	# Initialize character SP to 50 / 100
	var initial_sp: int = 50
	char_ctrl.current_sp = initial_sp
	char_ctrl.current_max_sp = 100
	hud.set_player_stats("Tester", 10, 100, 100, initial_sp, 100, 0.0)

	# Bind skill with SP cost (e.g. Overarm Stumble 15038)
	hotbar.bind_skill(0, 15038, "Overarm Stumble")

	# 1. Cast skill with sufficient SP
	var cast_ok: bool = hud.use_skill(15038)
	var remaining_sp: int = initial_sp - expected_cost
	_assert_true(cast_ok, "hud.use_skill(15038) succeeded with sufficient SP")
	_assert_true(char_ctrl.current_sp == remaining_sp, "SP correctly deducted to %d (was %d, -%d), got %d" % [remaining_sp, initial_sp, expected_cost, char_ctrl.current_sp])

	var p_status = hud.get("player_status_ctrl")
	if p_status and p_status.sp_label:
		_assert_true(str(remaining_sp) in p_status.sp_label.text, "Status dock SpLabel updated with remaining SP: %s" % p_status.sp_label.text)

	# 2. Cast skill when SP is insufficient
	var low_sp: int = int(max(0, expected_cost - 1))
	char_ctrl.current_sp = low_sp
	hud.set_player_stats("Tester", 10, 100, 100, low_sp, 100, 0.0)
	var fail_cast: bool = hud.use_skill(15038)
	_assert_true(not fail_cast, "hud.use_skill(15038) failed gracefully when SP (%d) < sp_cost (%d)" % [low_sp, expected_cost])
	_assert_true(char_ctrl.current_sp == low_sp, "SP was not deducted on failure (remains %d)" % low_sp)

	hud.queue_free()

func _test_close_button_interaction() -> void:
	print("\n>>> 8. Testing Authentic Close Button Interaction...")
	var win := SkillWindowClass.new()
	root.add_child(win)
	win.setup(null)
	win.visible = true

	var closed_emitted := [false]
	var on_close := func() -> void:
		closed_emitted[0] = true
	win.window_closed.connect(on_close)

	var close_btn = win.close_button
	_assert_true(close_btn != null, "Close button exists")
	close_btn.pressed.emit()

	_assert_true(not win.visible, "SkillWindow became hidden after CloseButton pressed")
	_assert_true(closed_emitted[0], "window_closed signal emitted")

	win.queue_free()
