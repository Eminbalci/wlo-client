extends SceneTree

func _init() -> void:
	print("--- Running Test Simulator NPC Click Diagnose ---")
	_run.call_deferred()

func _run() -> void:
	var scene_res = ResourceLoader.load("res://scenes/tools/world_editor.tscn")
	var editor = scene_res.instantiate()
	root.add_child(editor)
	await process_frame
	await process_frame

	print("1. Checking SimViewport properties:")
	var vp = editor.sim_viewport
	print("  vp.physics_object_picking = ", vp.physics_object_picking)
	print("  vp.handle_input_locally = ", vp.handle_input_locally)

	print("2. Starting playtest in editor...")
	editor.start_playtest()
	await process_frame
	await process_frame

	var sim_mv = editor._simulator_instance
	print("  sim_mv valid? ", is_instance_valid(sim_mv))
	print("  sim_mv.hud valid? ", is_instance_valid(sim_mv.hud))
	print("  sim_mv.hud.dialogue_ctrl valid? ", sim_mv.hud.dialogue_ctrl != null if sim_mv.hud else false)
	if sim_mv.hud and sim_mv.hud.dialogue_ctrl:
		var dctrl = sim_mv.hud.dialogue_ctrl
		print("  dialogue_dock = ", dctrl.dialogue_dock)
		print("  dialogue_dock visible initially? ", dctrl.dialogue_dock.visible if dctrl.dialogue_dock else false)

	# Check active NPCs on Ship Deck (10001)
	var npcs = sim_mv.get_active_npcs()
	print("3. Active NPCs in sim_mv: ", npcs.size())
	for n in npcs:
		print("  NPC: ", n.npc_name, " (id: ", n.npc_id, ") pos: ", n.world_position, " click_area: ", n.get_node_or_null("ClickArea"))

	# Test calling _on_npc_interacted on first NPC
	if not npcs.is_empty():
		var test_npc = npcs[0]
		print("4. Testing direct _on_npc_interacted for: ", test_npc.npc_name)
		sim_mv._on_npc_interacted(test_npc)
		await process_frame
		if sim_mv.hud and sim_mv.hud.dialogue_ctrl:
			var dctrl = sim_mv.hud.dialogue_ctrl
			print("  After _on_npc_interacted, dialogue_dock visible? ", dctrl.dialogue_dock.visible if dctrl.dialogue_dock else false)
			print("  Speaker text: ", dctrl.speaker_label.text if dctrl.speaker_label else "")
			print("  Dialogue text: ", dctrl.dialogue_text.text if dctrl.dialogue_text else "")

	# Test clicking Cat at (1014, 954) from (1042, 1075)
	var cat_npc = null
	for n in npcs:
		if "cat" in n.npc_name.to_lower():
			cat_npc = n
			break
	if cat_npc:
		# Close dialogue first
		sim_mv.hud.hide_dialogue()
		await process_frame
		print("6. Testing _on_tile_clicked on Cat NPC at: ", cat_npc.world_position)
		sim_mv._on_tile_clicked(cat_npc.world_position)
		print("  Immediately after click, pending: ", sim_mv._pending_npc_interaction != null)
		print("  Player moving? ", sim_mv.player.is_moving)
		# Step frames to let player walk toward Cat
		for step in range(30):
			sim_mv._process(0.05)
			sim_mv.player._update_movement(0.05)
			if sim_mv.hud.is_dialogue_active():
				print("  Dialogue opened after step ", step, "!")
				break
		var dctrl = sim_mv.hud.dialogue_ctrl
		print("  Cat dialogue_dock visible? ", dctrl.dialogue_dock.visible if dctrl.dialogue_dock else false)
		print("  Speaker text: ", dctrl.speaker_label.text if dctrl.speaker_label else "")
		print("  Dialogue text: ", dctrl.dialogue_text.text if dctrl.dialogue_text else "")

	editor.stop_playtest()
	editor.queue_free()
	print("--- Diagnostic Completed ---")
	quit(0)
