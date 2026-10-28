extends SceneTree

## Captures the Notebook menu, the collection book (one monster registered) and the star sky.

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
	hud.register_monster_seen(17001, "Jellyfish")
	hud.register_monster_seen(17002, "Green Slime")
	hud.open_notebook()
	for i in 6:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("nb_menu.png"))
	hud.notebook_window.open_monster_book()
	hud.notebook_window.book_rows[0].pressed.emit()
	for i in 6:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("nb_book.png"))
	hud.notebook_window.open_star_book()
	for i in 6:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("nb_sky.png"))
	quit()
