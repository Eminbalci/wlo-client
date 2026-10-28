extends SceneTree

## Captures the full world view with the chat unfocused and focused (CAPTURE_DIR sets the output folder).

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
	hud.add_chat_message("JUPITER", "B>SHADOW PESTLE", "World", 7)
	hud.add_chat_message("Athiesha", "S> Priest Book = 50m B> Venus Lantern 300k with a long tail so that it wraps", "World", 3)
	hud.add_chat_message("Daniel", "Hello everyone", "Local")
	for i in 20:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("chat_unfocused.png"))
	hud.chat_ctrl.chat_input.grab_focus()
	for i in 10:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("chat_focused.png"))
	quit()
