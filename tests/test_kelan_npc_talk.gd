extends SceneTree

## Kelan Village NPCs seen in the real client resolve to their real Talk.dat lines.

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
	print("--- Kelan NPC Talk Suite ---")
	await process_frame
	await process_frame
	var t = root.get_node("GameDatabase").talks
	var doll: Dictionary = t.resolve_talk_for_npc(14141, 12000)
	_check(str(doll.get("text", "")).contains("flavour tastes similar"), "Doll starts with her real first line")
	var chain: Array = t.get_dialogue_chain(int(doll.get("id", 0)))
	_check(chain.size() == 4, "Doll's chain has four pages (got %d)" % chain.size())
	_check(chain.size() == 4 and str(chain[3].get("text", "")).contains("Hill"), "The last page asks for Hill Pepper")
	_check(chain.size() == 4 and chain[3].get("choices", []).size() == 2, "The last page offers Yes. / No.")
	_check(str(t.resolve_talk_for_npc(14140, 12000).get("text", "")).contains("grape plantations"), "Emilie has her real line")
	_check(str(t.resolve_talk_for_npc(14118, 12000).get("text", "")).contains("Village Leader"), "The Guard has his real line")
	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
