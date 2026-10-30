extends SceneTree

## Opens the Props Shop window in sell mode and saves a screenshot (CAPTURE_DIR sets the folder).
## Written with agy (gemini-3.8-flash-medium).


func _init() -> void:
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	if hud_scene == null:
		push_error("Failed to load res://scenes/ui/hud.tscn")
		quit(1)
		return

	var hud: Node = hud_scene.instantiate()
	root.add_child(hud)

	for _i in range(3):
		await process_frame

	var shop = hud.get_or_create_shop_window()
	if shop == null:
		push_error("Failed to get_or_create_shop_window()")
		quit(1)
		return

	shop.open_shop(0, "Props Shop")
	shop.set_mode("sell")

	for _i in range(10):
		await process_frame

	var tex: ViewportTexture = root.get_texture()
	if tex == null:
		push_error("Failed to acquire root viewport texture")
		quit(1)
		return

	var img: Image = tex.get_image()
	if img == null:
		push_error("Failed to get image from root viewport texture")
		quit(1)
		return

	var capture_dir: String = OS.get_environment("CAPTURE_DIR")
	var save_path: String = "shop_sell_grid.png"
	if not capture_dir.is_empty():
		save_path = capture_dir.path_join("shop_sell_grid.png")

	var err: Error = img.save_png(save_path)
	if err != OK:
		push_error("Failed to save screenshot to %s (Error code: %d)" % [save_path, err])
		quit(1)
		return

	quit(0)
