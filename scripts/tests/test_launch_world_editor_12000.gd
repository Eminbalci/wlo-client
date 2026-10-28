extends SceneTree

const WorldEditorScene = preload("res://scenes/tools/world_editor.tscn")

func _init() -> void:
	print("[Test] Instantiating WorldEditor...")
	var editor = WorldEditorScene.instantiate()
	root.add_child(editor)
	
	await process_frame
	await process_frame
	
	print("[Test] Setting simulator map to 12000...")
	var opt_sim_map = editor.find_child("OptSimMap", true, false)
	if opt_sim_map:
		for i in range(opt_sim_map.item_count):
			if opt_sim_map.get_item_id(i) == 12000:
				opt_sim_map.selected = i
				editor._on_sim_map_selected(i)
				break
	
	print("[Test] SpinSimX: ", editor.spin_sim_x.value, " SpinSimY: ", editor.spin_sim_y.value)
	print("[Test] Calling start_playtest()...")
	editor.start_playtest()
	
	await process_frame
	await process_frame
	
	var sim = editor._simulator_instance
	if sim:
		print("[Test] Simulator instance found!")
		print("  Current MapRenderer map_id: ", sim.map_renderer.current_map_id)
		print("  Player position: ", sim.player.world_position if "world_position" in sim.player else sim.player.position)
		if sim.hud:
			print("  HUD map label: ", sim.hud.lbl_map_name.text if "lbl_map_name" in sim.hud else "no label")
	
	# Simulate 10 frames
	for f in range(10):
		await process_frame
		if sim:
			print("[Test] Frame %d: map_id=%d player_pos=%s" % [f, sim.map_renderer.current_map_id, sim.player.world_position if "world_position" in sim.player else sim.player.position])
	
	quit(0)
