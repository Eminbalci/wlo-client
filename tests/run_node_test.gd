extends SceneTree

## Generic headless runner for Node-based test suites (those that start in _ready and call quit()).
## Usage: godot_console.exe --headless --path . --script res://tests/run_node_test.gd -- res://tests/test_item_editor.gd

const TIMEOUT_SECONDS: float = 80.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("run_node_test.gd needs the test script path after '--'")
		quit(2)
		return
	var script := load(args[0]) as GDScript
	if script == null:
		push_error("Cannot load test script: %s" % args[0])
		quit(2)
		return
	create_timer(TIMEOUT_SECONDS).timeout.connect(func() -> void:
		push_error("Test timed out after %d s: %s" % [int(TIMEOUT_SECONDS), args[0]])
		quit(124)
	)
	root.add_child.call_deferred(script.new())
