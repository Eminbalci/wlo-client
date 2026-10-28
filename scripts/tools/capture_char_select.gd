extends SceneTree

## Captures the real login flow at the character select state (CAPTURE_DIR env var sets the output folder).

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	var packed := load("res://scenes/ui/login_screen.tscn") as PackedScene
	var inst := packed.instantiate()
	root.add_child(inst)
	for i in 5:
		await process_frame
	inst._transition_to_character_select()
	for i in 20:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join("char_select_flow.png"))
	print("saved ", out_dir, " size=", img.get_size())
	quit()
