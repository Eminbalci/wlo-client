extends SceneTree

## Opens the inventory with items and an item tooltip (CAPTURE_DIR sets the output folder).

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
	hud.window_manager.toggle_inventory()
	for i in 10:
		await process_frame
	var inv = hud.inventory_ctrl
	var slot: Button = inv.get_inventory_slot(0)
	print("ITM slot0=", slot, " data0=", inv.inventory_data[0] if inv.inventory_data.size() > 0 else null)
	inv.show_inventory_item_tooltip(0, slot.global_position, slot.size)
	for i in 10:
		await process_frame
	root.get_texture().get_image().get_region(Rect2i(60, 20, 520, 460)).save_png(out_dir.path_join("items_inv.png"))
	print("ITM saved")
	quit()
