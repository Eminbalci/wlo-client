extends SceneTree

## The skill window's Intro tab shows the element skill tree for the player's element.

const SkillWindowScript = preload("res://scripts/ui/hud/skill_window.gd")

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _run() -> void:
	print("--- Skill Window Express Tree Suite ---")
	await process_frame
	var w = SkillWindowScript.new()
	root.add_child(w)
	await process_frame
	var tree = w._express
	_record(tree != null and not tree.visible, "the element tree exists and starts hidden")
	w.select_tab(4)
	_record(tree.visible, "the Intro tab shows the element tree")
	w.select_tab(0)
	_record(not tree.visible, "leaving Intro hides the element tree")
	w.select_tab(4)
	w._learned_skill_ids = {11016: true}
	w._refresh_express_tree()
	_record(tree.is_learned(11016) and tree.learned_nodes().size() == 1, "learned skills reach the element tree")
	_record(tree.element == w._player_element, "the tree uses the player's element")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
