extends SceneTree

## Element skill tree (Intro tab): table transcribed from the Go client, node geometry, learned
## nodes, hit testing and requirement text.

const SkillExpressWindow = preload("res://scripts/ui/hud/skill_express_window.gd")
const SkillExpressTable = preload("res://scripts/data/skill_express_table.gd")

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
	print("--- Skill Express Window Suite ---")
	await process_frame
	_record(SkillExpressTable.ROWS.size() == 92, "the requirement table has all 92 Go rows")
	var element3: Array = SkillExpressTable.rows_for_element(3)
	_record(element3.size() > 0 and element3[0][1] == 11016, "element 3 starts with skill 11016 (Go order)")
	_record(SkillExpressWindow.format_requirements(0, 0, 0, 0, 0) == "None", "no requirement reads None")
	_record(SkillExpressWindow.format_requirements(16, 0, 0, 0, 0) == "STR 16", "a single requirement is listed")
	_record(SkillExpressWindow.format_requirements(16, 3, 0, 0, 0) == "STR 16, CON 3", "several requirements keep the Go order")

	var w = SkillExpressWindow.new()
	root.add_child(w)
	await process_frame
	w.set_element(3)
	_record(w._background.texture != null, "the element 3 background picture loads")
	_record(w.node_count() == 18, "the tree shows 18 nodes")
	_record(SkillExpressWindow.tree_point(0) == Vector2(69, 129), "node 0 sits at the first column top")
	_record(SkillExpressWindow.tree_point(6) == Vector2(128, 129), "node 6 starts the second column")
	_record(SkillExpressWindow.tree_point(17) == Vector2(186, 129 + 5 * 34), "node 17 is the bottom of the third column")

	w.set_grades({11016: 1, 15101: 0})
	var learned := w.learned_nodes()
	_record(learned.size() == 1 and learned[0].skill_id == 11016 and learned[0].index == 0, "only grade != 0 nodes count as learned")
	_record(w.is_learned(11016) and not w.is_learned(15101), "is_learned follows the grade map")

	var hit := w.node_at(SkillExpressWindow.tree_point(0) + SkillExpressWindow.BACKGROUND_POS + Vector2(5, 5))
	_record(hit == 0, "a point inside node 0 hits index 0")
	_record(w.node_at(Vector2(0, 0)) == -1, "a point outside the tree hits nothing")
	_record(w.requirement_text(0) == "None" and w.requirement_text(1) == "STR 16", "requirement text is read per node")

	w.set_element(9)
	_record(w.element == 4, "an out-of-range element clamps to 4")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
