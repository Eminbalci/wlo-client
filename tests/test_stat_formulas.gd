extends SceneTree

## Combat stats decoded from aLogin.exe (stat getter 0x430580, ids 41..45) with the Formula.dat coefficients.

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
	print("\n--- Coefficients read from Formula.dat ---")
	assert_eq(FormulaDataClass.combat_coefficients("atk"), [2.0, 1.4, 1.0, 0.6] as Array[float], "ATK")
	assert_eq(FormulaDataClass.combat_coefficients("def"), [1.75, 2.0, 1.0, 0.6] as Array[float], "DEF")
	assert_eq(FormulaDataClass.combat_coefficients("matk"), [2.0, 1.4, 1.0, 0.2] as Array[float], "MATK")
	assert_eq(FormulaDataClass.combat_coefficients("mdef"), [2.2, 2.0, 1.0, 0.2] as Array[float], "MDEF")
	assert_eq(FormulaDataClass.combat_coefficients("spd"), [1.8, 1.6, 1.0, 0.5] as Array[float], "SPD")

	print("\n--- combat_stat ---")
	# Daniel-like: STR 14, LV1, Fire: 28 + 1.4 + 0.6 = 30
	assert_eq(FormulaDataClass.combat_stat("atk", 14, 1, 0, 3), 30, "ATK STR14 LV1 Fire")
	assert_eq(FormulaDataClass.combat_stat("atk", 14, 1, 0, 2), 29, "ATK without the Fire bonus (29.4 rounds down)")
	assert_eq(FormulaDataClass.combat_stat("atk", 14, 1, 8, 3), 38, "Weapon ATK +8 is added")
	# DEF CON 12, LV10, Earth: 21 + 20 + 6 = 47
	assert_eq(FormulaDataClass.combat_stat("def", 12, 10, 0, 1), 47, "DEF CON12 LV10 Earth")
	# SPD AGI 18, LV3, Wind: 32.4 + 4.8 + 1.5 = 38.7 -> 39
	assert_eq(FormulaDataClass.combat_stat("spd", 18, 3, 0, 4), 39, "SPD AGI18 LV3 Wind")
	# MDEF WIS 15, LV1, no Earth bonus: 33 + 2 = 35
	assert_eq(FormulaDataClass.combat_stat("mdef", 15, 1, 0, 0), 35, "MDEF WIS15 LV1")
	# Job bonus: ATK job 1 adds Round(base * 0.1): base 30 -> +3
	assert_eq(FormulaDataClass.combat_stat("atk", 14, 1, 0, 3, 1), 33, "ATK job 1 +10%")
	assert_eq(FormulaDataClass.combat_stat("atk", 14, 1, 0, 3, 2), 30, "Job 2 does not boost ATK")
	# Reborn adds 100 levels: 28 + 101 * 1.4 + 101 * 0.6 = 230
	assert_eq(FormulaDataClass.combat_stat("atk", 14, 1, 0, 3, 0, true), 230, "Reborn ATK")

	# Half rounds up (0x1297d8): DEF CON 2, LV1: 3.5 + 2 = 5.5 -> 6
	assert_eq(FormulaDataClass.combat_stat("def", 2, 1), 6, "x.5 rounds up")

	print("\n--- Max HP / SP (server formula) ---")
	assert_eq(FormulaDataClass.max_hp(1, 10), 221, "MaxHP LV1 CON10")
	assert_eq(FormulaDataClass.max_hp(10, 12), 268, "MaxHP LV10 CON12")
	assert_eq(FormulaDataClass.max_sp(1, 6), 126, "MaxSP LV1 WIS6")

	print("\n--- HUDCharacterStatus uses the formulas ---")
	var cs = HUDCharacterStatusClass.new()
	cs.update_character_stats("Tester", 10, "Fire", 100, 100, 50, 50, 0, 100, 11, 10, 6, 6, 18, 0)
	assert_eq(cs.base_atk, 42, "base ATK (STR11 LV10 Fire)")
	assert_eq(cs.get_combat_stats({"atk": 8})["atk"], 50, "ATK with an ATK +8 weapon")
	assert_eq(cs.base_spd, 48, "base SPD (AGI18 LV10, no Wind bonus): 48.4 rounds down")

	print("\nRESULTS: %d PASSED, %d FAILED" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
