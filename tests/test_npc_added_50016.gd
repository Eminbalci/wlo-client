extends SceneTree

## The NPC template appended to all_npcs.json (id 50016, a copy of template 18044) must load.

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
	print("--- Added NPC 50016 Suite ---")
	await process_frame
	await process_frame
	var db = root.get_node("GameDatabase")
	var npc = db.npcs.get_npc(50016) if db.npcs.has_method("get_npc") else null
	_record(npc != null, "NPC template 50016 is loaded")
	var src = db.npcs.get_npc(18044) if db.npcs.has_method("get_npc") else null
	_record(src != null, "the source template 18044 still loads")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
