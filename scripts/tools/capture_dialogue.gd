extends SceneTree

## Captures the NPC dialogue dock over the world view (CAPTURE_DIR sets the output folder).

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	var inst := (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 40:
		await process_frame
	var hud = inst.find_child("HUD", true, false)
	hud.show_dialogue("Guard", "This is the house of our Village Leader.")
	for i in 30:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("dialogue.png"))
	quit()
