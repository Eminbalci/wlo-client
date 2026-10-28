extends SceneTree

## Captures the ship sinking cutscene at several moments (CAPTURE_DIR sets the output folder).

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
	inst.trigger_ship_sinking_cutscene()
	var cut = inst.sinking_cutscene
	print("CUT trigger ok, cutscene=", cut, " active=", cut.is_cutscene_active if cut else null)
	var targets := [0.4, 1.5, 2.6, 3.2, 3.8, 4.3, 4.8]
	var idx := 0
	var guard := 0
	while idx < targets.size() and guard < 2000:
		await process_frame
		guard += 1
		if cut.elapsed_time >= targets[idx]:
			root.get_texture().get_image().save_png(out_dir.path_join("cut_%d.png" % idx))
			print("CUT frame ", idx, " t=", cut.elapsed_time, " stage=", cut.current_stage)
			idx += 1
	quit()
