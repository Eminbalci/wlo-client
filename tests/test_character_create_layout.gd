extends SceneTree

## Layout and behaviour suite for the 4-step character creation wizard.
## Each step must sit on the skin whose baked artwork matches it, and controls must overlay the baked art.

const SCENE_PATH: String = "res://scenes/ui/auth/character_create.tscn"
# Positions measured from the white skin JPGs (card-local pixels).
const NAME_BOX: Rect2 = Rect2(584, 74, 88, 18)
const PALETTE_CARD: Rect2 = Rect2(102, 0, 536, 352)
const PALETTE_BARS_Y: Array[float] = [213.0, 244.0, 276.0]

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


func _tex_name(rect: TextureRect) -> String:
	return rect.texture.resource_path.get_file() if rect and rect.texture else ""


func _run() -> void:
	print("--- Character Create Layout Suite ---")
	var cc: Control = (load(SCENE_PATH) as PackedScene).instantiate()
	cc.account_name = "layout_suite"
	root.add_child(cc)
	await process_frame
	await process_frame

	print(">>> Skin mapping")
	_check(_tex_name(cc.step1_bg) == "Form_CreateRole_1.jpg", "Step 1 uses the 'Name' skin")
	_check(_tex_name(cc.step2_bg) == "Form_CreateRole_4.jpg", "Step 2 (appearance) uses the 'Palette' skin")
	_check(_tex_name(cc.step3_bg) == "Form_CreateRole_3.jpg", "Step 3 (element) uses the 'Attributes' skin")
	_check(_tex_name(cc.step4_bg) == "Form_CreateRole_2.jpg", "Step 4 (points) uses the 'Role explication' skin")
	_check(Rect2(cc.step2_bg.offset_left, cc.step2_bg.offset_top, cc.step2_bg.offset_right - cc.step2_bg.offset_left, cc.step2_bg.offset_bottom - cc.step2_bg.offset_top) == PALETTE_CARD,
		"Palette card is 536x352, centred in the 740 window")

	print(">>> Step 1 name inputs")
	var first: Control = cc.first_name_input
	var abs_left: float = first.offset_left + 370.0
	_check(is_equal_approx(abs_left, NAME_BOX.position.x) and is_equal_approx(first.offset_top, NAME_BOX.position.y), "First-name input sits on the baked black box")
	_check(is_equal_approx(first.offset_right + 370.0, NAME_BOX.end.x), "First-name input matches the box width")
	_check(cc.family_name_input.offset_top >= NAME_BOX.end.y, "Family-name input sits just below the box")
	_check(cc.family_name_input.offset_bottom <= 112.0, "Family-name input stays above the baked 'Launched Character's Status' caption")

	print(">>> Step 2 palette overlay")
	cc.goto_step(2)
	var rows: Array = [cc.slider_r, cc.slider_g, cc.slider_b]
	for i in 3:
		var slider: Control = rows[i]
		var row: Control = slider.get_parent()
		var bar_center: float = row.offset_top + slider.offset_top + (slider.offset_bottom - slider.offset_top) * 0.5
		_check(absf(bar_center - (PALETTE_BARS_Y[i] + 4.5)) <= 3.0, "Slider %d is vertically aligned on its baked bar" % i)
		_check(is_equal_approx(slider.offset_left, PALETTE_CARD.position.x + 98.0), "Slider %d starts at the baked bar's left edge" % i)
	_check(cc.btn_minus_r.flat and cc.btn_minus_r.text == "", "Minus/plus buttons are transparent overlays over the baked arrows")
	cc._on_slider_changed("r", 128.0)
	_check(is_equal_approx(cc.selected_hair_color.r, 128.0 / 255.0), "Slider still drives the hair colour")

	print(">>> Step 3 flow")
	cc.goto_step(3)
	cc.select_element("Water")
	cc.step3_btn_finish.pressed.emit()
	_check(cc.current_step == 4, "Step 3 button advances to the points step (does not create)")

	print(">>> Step 4 points allocation")
	var str_before: int = int(cc.get_final_stats()["str"])
	_check(cc.points_pool == 4, "Four bonus points available")
	_check(cc.step4_points_label.text == "4", "Points label shows 4")
	cc._on_stat_button("str", 1)
	cc._on_stat_button("str", 1)
	_check(int(cc.get_final_stats()["str"]) == str_before + 2, "Plus raises STR by one per click")
	_check(cc.points_pool == 2 and cc.step4_points_label.text == "2", "Points pool and label drop to 2")
	cc._on_stat_button("agi", 1)
	cc._on_stat_button("agi", 1)
	cc._on_stat_button("agi", 1)
	_check(cc.points_pool == 0, "Pool never goes below zero")
	_check(cc.get_node("WindowRoot/Step4/StatsArea/BtnPlusSTR").disabled, "Plus buttons disable when no points remain")
	cc._on_stat_button("str", -1)
	_check(cc.points_pool == 1, "Minus refunds a point")
	cc._on_stat_button("con", -1)
	_check(cc.points_pool == 1, "Minus cannot take below the role's base value")
	_check(cc.step4_radar_chart.stats["str"] == cc.get_final_stats()["str"], "Radar chart follows the allocated stats")

	print(">>> Step 4 creation")
	cc.first_name_input.text = "Layout"
	cc.family_name_input.text = "Test"
	var created: Array = []
	cc.character_created.connect(func(c: Dictionary) -> void: created.append(c))
	cc.step4_btn_ok.pressed.emit()
	_check(created.size() == 1, "Create button emits character_created")
	if created.size() == 1:
		_check(created[0].get("name") == "Layout Test", "Created character carries the entered name")
		_check(created[0].get("element") == "Water", "Created character keeps the chosen element")

	var CM = load("res://scripts/ui/auth/character_manager.gd")
	CM.clear_all_characters("layout_suite")
	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
