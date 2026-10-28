extends SceneTree

## Captures the 4 character create wizard steps (CAPTURE_DIR env var sets the output folder).

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	var inst := (load("res://scenes/ui/auth/character_create.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 8:
		await process_frame
	for step in [1, 2, 3, 4]:
		inst.goto_step(step)
		for i in 12:
			await process_frame
		root.get_texture().get_image().save_png(out_dir.path_join("create_step%d.png" % step))
	print("saved ", out_dir)
	quit()
