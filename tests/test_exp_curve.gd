extends SceneTree

## Level / EXP curve decoded from aLogin.exe (0x388628 / 0x388748 / 0x3886fc) and Formula.dat.
## Expected values: Round((n + 1)^3.1 + 5) per level step, Python round (half to even).

const FormulaDataClass = preload("res://scripts/database/formula_data.gd")
const HUDCharacterStatusClass = preload("res://scripts/ui/hud/hud_character_status.gd")

var _passed: int = 0
var _failed: int = 0

func assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		_passed += 1
		print("  [PASS] %s: %s" % [msg, str(a)])
	else:
		_failed += 1
		print("  [FAIL] %s: expected %s, got %s" % [msg, str(b), str(a)])

func _init() -> void:
	print("\n--- Formula.dat fields ---")
	assert_eq(FormulaDataClass.get_double(FormulaDataClass.OFFSET_EXP_EXPONENT), 3.1, "Exponent at 0xF1")
	assert_eq(FormulaDataClass.get_int32(FormulaDataClass.OFFSET_EXP_ADDEND), 5, "Addend at 0x169")

	print("\n--- Level steps ---")
	var expected_steps: Array[int] = [14, 35, 79, 152, 263, 422, 635, 913, 1264, 1697]
	for i in expected_steps.size():
		assert_eq(FormulaDataClass.exp_to_next_level(i + 1), expected_steps[i], "LV%d -> LV%d" % [i + 1, i + 2])
	assert_eq(FormulaDataClass.exp_to_next_level(198), 13379648, "LV198 -> LV199")
	assert_eq(FormulaDataClass.exp_of_level(1), 6, "f(1), the base the server adds to the total")

	print("\n--- Total EXP -> level (client 0x3886fc) ---")
	assert_eq(FormulaDataClass.level_from_total_exp(0), 1, "0 EXP")
	assert_eq(FormulaDataClass.level_from_total_exp(6 + 13), 1, "One short of LV2")
	assert_eq(FormulaDataClass.level_from_total_exp(6 + 14), 2, "Exactly LV2")
	assert_eq(FormulaDataClass.level_from_total_exp(6 + 14 + 35 + 79 + 152), 5, "Exactly LV5")
	assert_eq(FormulaDataClass.level_from_total_exp(2000000000), 199, "Capped at 199")
	assert_eq(FormulaDataClass.max_level(true), 190, "Reborn cap")
	assert_eq(FormulaDataClass.exp_of_level(10, true), int(pow(10.0, 3.3) + 50.0 + 0.5), "Reborn f(10)")

	print("\n--- HUDCharacterStatus.add_experience ---")
	var cs = HUDCharacterStatusClass.new()
	cs.current_level = 1
	cs.current_exp = 0
	cs.current_free = 0
	cs.current_max_hp = 100
	cs.current_max_sp = 50
	assert_eq(cs.add_experience(10), 10, "Added 10 EXP")
	assert_eq(cs.current_level, 1, "Still LV1")
	assert_eq(cs.current_max_exp, 14, "Bar denominator at LV1")
	cs.add_experience(4 + 35 + 5)
	assert_eq(cs.current_level, 3, "Two levels gained")
	assert_eq(cs.current_exp, 5, "Remainder inside LV3")
	assert_eq(cs.current_max_exp, 79, "Bar denominator at LV3")
	assert_eq(cs.current_free, 2 * cs.STAT_POINTS_PER_LEVEL, "Stat points for two levels")
	assert_eq(cs.current_max_hp, 100 + 2 * cs.HP_PER_LEVEL, "Max HP growth")
	cs.current_level = 199
	cs.current_exp = 0
	assert_eq(cs.add_experience(500), 0, "No EXP at the level cap")

	print("\nRESULTS: %d PASSED, %d FAILED" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
