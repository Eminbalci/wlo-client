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
