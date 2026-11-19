class_name AutoPlayerController
extends RefCounted

## Auto-combat decision step (Go client: inventory/remote.go checks and thresholds). Given the
## settings model and a snapshot of the character, it returns the next action. It does not act:
## the caller performs the action (battle attack, walk, use supply, stop) and feeds the next snapshot.
## Check indices follow AutoPlayerSettings: 0 fight, 1 move, 2 supply, 3 no supplies, 4 player deaths,
## 5 pet deaths, 6 elapsed time, 7 unequip, 8 discard.

const AutoPlayerSettings = preload("res://scripts/ui/hud/auto_player_settings.gd")

const ACTION_NONE := "none"
const ACTION_FIGHT := "fight"
const ACTION_MOVE := "move"
const ACTION_USE_SUPPLY := "use_supply"
const ACTION_STOP := "stop"

const STOP_NO_SUPPLIES := "no_supplies"
const STOP_PLAYER_DEATH := "player_death"
const STOP_PET_DEATH := "pet_death"
const STOP_TIME := "time_limit"


## snapshot: {hp_percent: int, sp_percent: int, supplies: int, player_dead: bool, pet_dead: bool,
##            seconds_elapsed: int, in_battle: bool}
## Returns {action: String, reason: String}.
static func decide(settings: AutoPlayerSettings, snapshot: Dictionary) -> Dictionary:
	if snapshot.get("player_dead", false) and settings.checks[4]:
		return _stop(STOP_PLAYER_DEATH)
	if snapshot.get("pet_dead", false) and settings.checks[5]:
		return _stop(STOP_PET_DEATH)
	var limit := settings.field_int(1)
	if settings.checks[6] and limit > 0 and int(snapshot.get("seconds_elapsed", 0)) >= limit * 60:
		return _stop(STOP_TIME)
	var hp := int(snapshot.get("hp_percent", 100))
	var supplies := int(snapshot.get("supplies", 0))
	if settings.checks[2] and hp <= settings.thresholds[0] and supplies > 0:
		return {"action": ACTION_USE_SUPPLY, "reason": ""}
	if settings.checks[2] and hp <= settings.thresholds[0] and supplies <= 0 and settings.checks[3]:
		return _stop(STOP_NO_SUPPLIES)
	if snapshot.get("in_battle", false):
		if settings.checks[0]:
			return {"action": ACTION_FIGHT, "reason": ""}
		return {"action": ACTION_NONE, "reason": ""}
	if settings.checks[1]:
		return {"action": ACTION_MOVE, "reason": ""}
	return {"action": ACTION_NONE, "reason": ""}


static func _stop(reason: String) -> Dictionary:
	return {"action": ACTION_STOP, "reason": reason}
