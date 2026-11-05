extends SceneTree

## Life skills: the Skill window's Life tab lists the Skill.dat category 9 records (16 of them),
## and the default learned set uses their real ids (Collection 15983, Cutting 15984, Mining 15985).

const SkillDatabaseScript = preload("res://scripts/database/skill_database.gd")
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
	print("--- Life Skills Suite ---")
	var db := SkillDatabaseScript.new()
	_record(db.load_from_file("res://assets/data/Skill.dat"), "Skill.dat loads")

	var life_ids: Array[int] = []
	for id in db.get_all_skills().keys():
		var rec = db.get_skill(int(id))
		if int(rec.category) == 9:
			life_ids.append(int(rec.id))
	_record(life_ids.size() == 16, "Skill.dat has 16 life skills (got %d)" % life_ids.size())

	var win = SkillWindowScript.new()
	win.init_default_learned_skills(1, 3)
	_record(win.is_skill_learned(15983), "Collection (15983) is learned by default")
	_record(win.is_skill_learned(15984), "Cutting (15984) is learned by default")
	_record(win.is_skill_learned(15985), "Mining (15985) is learned by default")
	_record(not win.is_skill_learned(10021), "Banana Skin (10021) is not treated as a life skill")

	var shown := 0
	for id in life_ids:
		var rec = db.get_skill(id)
		if win._skill_in_tab(rec, 3, 0):
			shown += 1
	_record(shown == 16, "the Life tab shows all 16 life skills (got %d)" % shown)

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	win.free()
	quit(1 if _failed > 0 else 0)
