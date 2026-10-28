extends SceneTree

## Captures the battle view at the start of a battle and mid-turn (CAPTURE_DIR sets the output folder).

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	var view = (load("res://scenes/battle/battle_view.tscn") as PackedScene).instantiate()
	root.add_child(view)
	for i in 10:
		await process_frame
	var manager = view.battle_manager
	manager.load_formation_preset("Kelan Slimes Troop")
	manager.set_player_slot(0, {
		"id": 6, "name": "Daniel", "level": 10, "hp": 320, "max_hp": 320, "sp": 140, "max_sp": 140,
		"atk": 45, "matk": 55, "def": 22, "mdef": 26, "spd": 18, "element": 3,
		"skills": [{"id": 10001, "name": "Normal Attack", "sp_cost": 0, "base_damage": 25, "skill_type": 0, "element": 0}]
	})
	manager.start_battle()
	view.refresh_actor_widgets()
	for i in 40:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join("battle_0.png"))
	print("BAT saved start, state=", manager.current_state)
	quit()
