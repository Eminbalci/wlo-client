class_name FormulaData
extends RefCounted

## Formula.dat (407 bytes) and the level/EXP curve of the real client.
##
## aLogin.exe loads Formula.dat verbatim and reads its fields by offset (base pointer at 0x4c973c, +4):
## - 0x388628 f(level, reborn): EXP of one level = Round(Power(level, A) + B).
##     Not reborn: A = double at 0xF1 (3.1), B = int32 at 0x169 (5).
##     Reborn: A = 3.3 (code constant), B = 50.0 up to level 150, else Power(level - 150, 4.9).
##     Round is the FPU default (fistp, round half to even).
## - 0x388748 g(n) = f(1) + ... + f(n): total EXP at which level n is reached (level 1 is free).
## - 0x3886fc level_from_total_exp: last n with g(n) <= total, capped at 199 (190 when reborn, 0x49f0ec).
## So going from level n to n + 1 costs f(n + 1): 14, 35, 79, 152, 263 ... (same as the C# server's CalcMaxExp).
##
## Combat stats (stat getter 0x430580, ids 41..45): with L = level + 100 * reborn (0x49f0e4),
##   base  = attr * c0 + L * c1 + L * element_bonus * c3
##   value = R(base + equip * c2 [+ a server bonus, flag 0x20a5]) + R(base * job_bonus)
## c0..c3 are the four doubles at `offset` (attr, level, equip, element); element_bonus is 1 when the
## character has the stat's element; job_bonus is 0.1 for the listed jobs (byte 0x1f9c), else 0.
## R (0x1297d8) rounds half up: Ceil when Frac >= 0.5, else Floor.
## Max HP / SP (ids 205 / 206) are only stored by the client: the server computes them. max_hp / max_sp use the
## C# server's Equip.MaxHp / MaxSp (C# Math.Round = half to even); their 0.35 / 3.2 / 0.3 factors are also in Formula.dat.

const FORMULA_PATH: String = "res://assets/data/Formula.dat"
const OFFSET_EXP_EXPONENT: int = 0xF1
const OFFSET_EXP_ADDEND: int = 0x169
const DEFAULT_EXP_EXPONENT: float = 3.1
const DEFAULT_EXP_ADDEND: int = 5
const REBORN_EXP_EXPONENT: float = 3.3
const REBORN_EXP_ADDEND: float = 50.0
const REBORN_HIGH_LEVEL: int = 150
const REBORN_HIGH_EXPONENT: float = 4.9
const MAX_LEVEL: int = 199
const MAX_LEVEL_REBORN: int = 190

const COMBAT_STATS: Dictionary = {
	"atk": {"offset": 0x01, "element": 3, "jobs": [1]},
	"def": {"offset": 0x21, "element": 1, "jobs": [2]},
	"matk": {"offset": 0x41, "element": 3, "jobs": [4]},
	"mdef": {"offset": 0x61, "element": 1, "jobs": [5]},
	"spd": {"offset": 0x81, "element": 4, "jobs": [3, 6]},
}
## Values of the shipped Formula.dat, used when the file is missing.
const DEFAULT_COMBAT_COEFFICIENTS: Dictionary = {
	"atk": [2.0, 1.4, 1.0, 0.6],
	"def": [1.75, 2.0, 1.0, 0.6],
	"matk": [2.0, 1.4, 1.0, 0.2],
	"mdef": [2.2, 2.0, 1.0, 0.2],
	"spd": [1.8, 1.6, 1.0, 0.5],
}
const JOB_BONUS: float = 0.1

static var _bytes: PackedByteArray = PackedByteArray()
static var _loaded: bool = false


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if FileAccess.file_exists(FORMULA_PATH):
		_bytes = FileAccess.get_file_as_bytes(FORMULA_PATH)
	else:
		push_warning("[FormulaData] %s not found, using the values decoded from the original file" % FORMULA_PATH)


## Raw double of Formula.dat at `offset` (the file is a run of doubles from offset 1), or `fallback`.
static func get_double(offset: int, fallback: float = 0.0) -> float:
	ensure_loaded()
	if offset < 0 or offset + 8 > _bytes.size():
		return fallback
	return _bytes.decode_double(offset)


static func get_int32(offset: int, fallback: int = 0) -> int:
	ensure_loaded()
	if offset < 0 or offset + 4 > _bytes.size():
		return fallback
	return _bytes.decode_s32(offset)


static func max_level(reborn: bool = false) -> int:
	return MAX_LEVEL_REBORN if reborn else MAX_LEVEL


## EXP of one level, f(level) in the client.
static func exp_of_level(level: int, reborn: bool = false) -> int:
	var exponent: float = REBORN_EXP_EXPONENT
	var addend: float = REBORN_EXP_ADDEND
	if not reborn:
		exponent = get_double(OFFSET_EXP_EXPONENT, DEFAULT_EXP_EXPONENT)
		addend = float(get_int32(OFFSET_EXP_ADDEND, DEFAULT_EXP_ADDEND))
	elif level > REBORN_HIGH_LEVEL:
		addend = pow(float(level - REBORN_HIGH_LEVEL), REBORN_HIGH_EXPONENT)
	return _round_half_even(pow(float(level), exponent) + addend)


## EXP needed to go from `level` to `level + 1` (the denominator of the EXP bar).
static func exp_to_next_level(level: int, reborn: bool = false) -> int:
	return exp_of_level(maxi(1, level) + 1, reborn)


## Total EXP at which `level` is reached, g(level) in the client.
static func total_exp_for_level(level: int, reborn: bool = false) -> int:
	var total: int = 0
	for i in range(1, maxi(1, level) + 1):
		total += exp_of_level(i, reborn)
	return total


## Level for a total EXP value, as the client derives it from the server's total.
static func level_from_total_exp(total_exp: int, reborn: bool = false) -> int:
	var level: int = 1
	while level < max_level(reborn) and total_exp_for_level(level + 1, reborn) <= total_exp:
		level += 1
	return level


static func _round_half_even(value: float) -> int:
	var lower: float = floorf(value)
	var diff: float = value - lower
	if is_equal_approx(diff, 0.5):
		return int(lower) + (int(lower) & 1)
	return int(roundf(value))


## [attr, level, equip, element] coefficients of a combat stat ("atk", "def", "matk", "mdef", "spd").
static func combat_coefficients(stat: String) -> Array[float]:
	var layout: Dictionary = COMBAT_STATS[stat]
	var defaults: Array = DEFAULT_COMBAT_COEFFICIENTS[stat]
	var result: Array[float] = []
	for i in 4:
		result.append(get_double(int(layout["offset"]) + i * 8, float(defaults[i])))
	return result


## Combat stat as the client shows it. `element_id`: 1 Earth, 2 Water, 3 Fire, 4 Wind.
static func combat_stat(stat: String, attr: int, level: int, equip: int = 0, element_id: int = 0, job: int = 0, reborn: bool = false) -> int:
	var c: Array[float] = combat_coefficients(stat)
	var layout: Dictionary = COMBAT_STATS[stat]
	var eff_level: float = float(level + (100 if reborn else 0))
	var element_bonus: float = 1.0 if element_id == int(layout["element"]) else 0.0
	var base: float = float(attr) * c[0] + eff_level * c[1] + eff_level * element_bonus * c[3]
	var job_bonus: float = JOB_BONUS if (layout["jobs"] as Array).has(job) else 0.0
	return _round_half_up(base + float(equip) * c[2]) + _round_half_up(base * job_bonus)


static func _round_half_up(value: float) -> int:
	var lower: float = floorf(value)
	return int(lower) + 1 if value - lower >= 0.5 else int(lower)


## Base max HP before equipment (server formula).
static func max_hp(level: int, con: int) -> int:
	return _round_half_even(pow(float(level), 0.35) * float(con) * 2.0 + float(level) + float(con) * 2.0 + 180.0)


## Base max SP before equipment (server formula).
static func max_sp(level: int, wis: int) -> int:
	return _round_half_even(pow(float(level), 0.3) * float(wis) * 3.2 + float(level) + float(wis) * 2.0 + 94.0)
