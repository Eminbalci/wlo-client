extends SceneTree

## Captures the compound (alchemy) window over the world view (CAPTURE_DIR sets the output folder).

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	var inst := (load("res://scenes/world/map_view.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 30:
		await process_frame
	var win = load("res://scripts/ui/hud/compound_window.gd").new()
	var hud = inst.find_child("HUD", true, false)
	hud.add_child(win)
	win.position = Vector2(200, 40)
	for i in 10:
		await process_frame
	root.get_texture().get_image().get_region(Rect2i(150, 0, 420, 560)).save_png(out_dir.path_join("compound.png"))
	print("saved compound size=", win.size)
	quit()
