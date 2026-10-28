extends SceneTree

## Opens each HUD floating window in the world view and captures it (CAPTURE_DIR sets the output folder).

const WINDOWS: Array[String] = [
	"toggle_character_status", "toggle_inventory", "toggle_skill_window", "toggle_team_window",
	"toggle_quest_window", "toggle_friends_window", "toggle_system_window", "toggle_fight_menu", "toggle_shop_window",
]


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
	for i in 60:
		await process_frame
	var hud = inst.get_node_or_null("HUD")
	if hud == null:
		hud = inst.find_child("HUD", true, false)
	print("hud=", hud)
	var mgr = hud.window_manager
	for fn in WINDOWS:
		mgr.call(fn)
		for i in 8:
			await process_frame
		root.get_texture().get_image().save_png(out_dir.path_join("win_%s.png" % fn.replace("toggle_", "")))
		mgr.call(fn)
		for i in 3:
			await process_frame
	print("saved windows")
	quit()
