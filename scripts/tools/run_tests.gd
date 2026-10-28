extends SceneTree

func _initialize() -> void:
	print("--- Running Map 10001 Parity Verification ---")
	var test_script = load("res://scripts/tests/verify_map_10001.gd")
	var test_node = test_script.new()
	root.add_child(test_node)
