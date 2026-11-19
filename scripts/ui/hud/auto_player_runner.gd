class_name AutoPlayerRunner
extends RefCounted

## Applies AutoPlayerController decisions to the game. Fight uses the battle manager's existing
## auto-battle (set_auto_battle), and a stop turns it off. Walking and supply use are passed to the
## optional callables `on_move` and `on_use_supply`; those are not connected yet, so a move or a
## supply decision is reported to the caller and not performed here.

const AutoPlayerController = preload("res://scripts/ui/hud/auto_player_controller.gd")

var on_move: Callable = Callable()
var on_use_supply: Callable = Callable()
var last_stop_reason: String = ""


## Returns the decision that was applied. `battle` needs set_auto_battle(bool) when it is used.
func apply(decision: Dictionary, battle: Object) -> Dictionary:
	match decision.get("action", AutoPlayerController.ACTION_NONE):
		AutoPlayerController.ACTION_FIGHT:
			if battle and battle.has_method("set_auto_battle"):
				battle.set_auto_battle(true)
		AutoPlayerController.ACTION_STOP:
			last_stop_reason = str(decision.get("reason", ""))
			if battle and battle.has_method("set_auto_battle"):
				battle.set_auto_battle(false)
		AutoPlayerController.ACTION_MOVE:
			if on_move.is_valid():
				on_move.call()
		AutoPlayerController.ACTION_USE_SUPPLY:
			if on_use_supply.is_valid():
				on_use_supply.call()
	return decision
