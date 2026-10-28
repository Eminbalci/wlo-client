extends SceneTree

## Headless test runner for TestTentEditor.
## Can be executed directly via:
##   godot_console.exe --headless -s res://tests/test_tent_editor_runner.gd

func _init() -> void:
	var test_script = load("res://tests/test_tent_editor.gd")
	var test_node = test_script.new()
	root.add_child(test_node)
