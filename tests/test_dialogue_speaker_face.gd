extends SceneTree

## A speaker known only by name still gets its own Npc.dat face instead of a default one.

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
	print("--- Dialogue Speaker Face Suite ---")
	var hud: Control = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame
	var dlg = hud.dialogue_ctrl if "dialogue_ctrl" in hud else null
	_check(dlg != null, "The HUD exposes its dialogue controller")
	var db = root.get_node_or_null("GameDatabase")
	var tid: int = dlg._talk_image_for_speaker("Doll") if dlg else 0
	_check(tid >= 8000, "'Doll' resolves to a real talk image (got %d)" % tid)
	_check(dlg._talk_image_for_speaker("") == 0, "An empty speaker has no face")
	hud.show_dialogue("Doll", "Oh! It's ok when the flavour tastes similar.")
	await process_frame
	var tex = dlg.portrait_rect.texture if dlg and dlg.portrait_rect else null
	_check(tex != null, "The portrait shows a texture for a name-only speaker")
	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
