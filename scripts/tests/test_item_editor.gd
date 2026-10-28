extends SceneTree

func _init() -> void:
	# Ensure core Autoloads exist if run via script
	if not root.has_node("ArchiveLoader"):
		var arch_loader = load("res://scripts/core/archive_loader.gd").new()
		arch_loader.name = "ArchiveLoader"
		root.add_child(arch_loader)

	if not root.has_node("GameDatabase"):
		var gdb = load("res://scripts/database/game_database.gd").new()
		gdb.name = "GameDatabase"
		root.add_child(gdb)

	var test_script = load("res://tests/test_item_editor.gd")
	var node = test_script.new()
	root.add_child(node)
