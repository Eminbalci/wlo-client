extends SceneTree

## Captures the in-world view (map + HUD) for the active character.

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	var gdb := root.get_node_or_null("GameDatabase")
	if gdb:
		gdb.active_character = {
			"slot_index": 0, "name": "Daniel", "role_id": 6, "role_name": "Daniel", "element": "Fire",
			"level": 10, "exp": 0, "hp": 245, "max_hp": 245, "sp": 180, "max_sp": 180,
			"str": 15, "con": 12, "int": 8, "wis": 8, "agi": 11, "reborn": false, "gold": 1250
		}
	var inst := (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 90:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("world_view.png"))
	print("saved world_view")
	quit()
