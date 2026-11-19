extends SceneTree

## The test map copy appended to all_maps.json must load through SceneDatabase; its source is unchanged.

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
	print("--- Added Map Suite ---")
	await process_frame
	await process_frame
	var db = root.get_node("GameDatabase")
	var scene = db.scenes.get_scene(60016) if db.scenes.has_method("get_scene") else null
	_record(scene != null, "map 60016 (copy) is loaded")
	_record(db.scenes.get_scene(10000) != null, "the source map 10000 still loads")
	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
