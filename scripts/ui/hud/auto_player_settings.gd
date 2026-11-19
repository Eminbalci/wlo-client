class_name AutoPlayerSettings
extends RefCounted

## Auto-combat controller settings (Go client: inventory/remote.go, TTH_AutoPlayForm). This is the
## form's state only: eleven option checks, five numeric fields, four threshold sliders (0..100) and
## five discard slots. The automation loop that acts on these settings is a separate subsystem
## (the Go Agent controller) and is not part of this model.

const CHECK_COUNT := 11
const FIELD_COUNT := 5
const THRESHOLD_COUNT := 4
const DISCARD_COUNT := 5
const DEFAULT_THRESHOLD := 50
const MAX_FIELD_DIGITS := 4
## Check indices in the Go order: fight, move, supply, no supplies, player deaths, pet deaths,
## elapsed time, unequip, discard, option 10 (hidden), remote information.
const CHECK_REMOTE_INFO := 10

var checks: Array[bool] = []
var fields: Array[String] = []
var thresholds: Array[int] = []
var discard: Array[int] = []


func _init() -> void:
	reset()


func reset() -> void:
	checks = []
	for i in CHECK_COUNT:
		checks.append(false)
	checks[CHECK_REMOTE_INFO] = true
	fields = ["1", "50", "3", "3", "0"]
	thresholds = []
	for i in THRESHOLD_COUNT:
		thresholds.append(DEFAULT_THRESHOLD)
	discard = []
	for i in DISCARD_COUNT:
		discard.append(0)


func toggle_check(index: int) -> void:
	if index >= 0 and index < CHECK_COUNT:
		checks[index] = not checks[index]


## Field text is digits only, at most four characters, as the Go editor (Filter 1, MaxLen 4).
func set_field(index: int, text: String) -> bool:
	if index < 0 or index >= FIELD_COUNT:
		return false
	var digits := ""
	for c in text:
		if c >= "0" and c <= "9":
			digits += c
	if digits.length() > MAX_FIELD_DIGITS:
		digits = digits.substr(0, MAX_FIELD_DIGITS)
	fields[index] = digits
	return true


func set_threshold(index: int, value: int) -> void:
	if index >= 0 and index < THRESHOLD_COUNT:
		thresholds[index] = clampi(value, 0, 100)


## Sets or clears a discard slot (item id 0 clears it).
func set_discard(index: int, item_id: int) -> void:
	if index >= 0 and index < DISCARD_COUNT:
		discard[index] = maxi(item_id, 0)


func field_int(index: int) -> int:
	return int(fields[index]) if index >= 0 and index < FIELD_COUNT and fields[index] != "" else 0
