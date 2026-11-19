extends SceneTree

## The dialogue record appended to Talk.dat must load through TalkDatabase.

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
	print("--- Added Talk Suite ---")
	await process_frame
	await process_frame
	var db = root.get_node("GameDatabase")
	var talks = db.talks
	var rec = talks.get_talk(63018) if talks.has_method("get_talk") else null
	_record(rec != null, "talk record 63018 is loaded")
	if rec != null:
		_record(str(rec.text).find("added as new dialogue") >= 0, "its text is the added line")
	_record(talks.get_talk(63017) != null, "the previous talk 63017 still loads")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
