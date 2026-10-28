extends SceneTree

## Observed in the real client: the player's own lines show the frame at the bottom with a full-body illustration and
## no portrait box; NPC lines sit at the top with their face; a quest reward shows an "Obtain N pcs X" frame.

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


func _run() -> void:
	print("--- Dialogue Player Mode Suite ---")
	var hud: Control = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame
	var dlg = hud.dialogue_ctrl
	var dock: Control = dlg.dialogue_dock

	hud.show_dialogue("Doll", "Oh! It's ok when the flavour tastes similar.")
	await process_frame
	_check(dock.visible and dock.offset_top == 48.0, "An NPC line sits at the top of the view")
	_check(dlg.portrait_frame.visible and dlg.speaker_label.visible, "The NPC's face and name are shown")

	hud.show_dialogue("Player", "Doll, I have the Hill Pepper now.")
	await process_frame
	_check(dock.offset_top > 300.0 or dock.anchor_top == 1.0, "The player's line sits at the bottom of the view")
	_check(not dlg.portrait_frame.visible, "No portrait box while the player speaks")
	_check(dlg._player_body != null and dlg._player_body.visible and dlg._player_body.texture != null, "The player's full-body illustration is shown")

	hud.show_dialogue("Doll", "Thanks.")
	await process_frame
	_check(dock.offset_top == 48.0 and not dlg._player_body.visible, "Back to the top layout and the illustration hides")

	hud.show_dialogue("Doll", "Can you get some Hill Pepper?", null, ["Yes.", "No."])
	await process_frame
	_check(dock.offset_bottom > 250.0, "With choices the frame grows downwards")
	_check(dlg.branching_dock.visible and dlg.choices_container.get_child_count() == 2, "Two choice rows are listed")
	dlg.hide_dialogue()

	dlg.show_quest_reward("Radio Set", 1)
	await process_frame
	var banner := hud.get_node_or_null("RewardBanner")
	_check(banner != null, "A quest reward shows a framed banner")
	_check(banner != null and banner.get_child(0) is Label and (banner.get_child(0) as Label).text == "Obtain 1 pcs Radio Set", "The banner reads 'Obtain 1 pcs Radio Set'")

	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
