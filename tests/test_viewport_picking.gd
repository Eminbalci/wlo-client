extends SceneTree

func _init() -> void:
	print("--- Running Test Viewport Picking ---")
	_run.call_deferred()

func _run() -> void:
	var scene_res = ResourceLoader.load("res://scenes/tools/world_editor.tscn")
	var editor = scene_res.instantiate()
	root.add_child(editor)
	await process_frame
	await process_frame

	var vp = editor.sim_viewport
	vp.physics_object_picking = true
	vp.handle_input_locally = true
	
	editor.start_playtest()
	await process_frame
	await process_frame

	var sim_mv = editor._simulator_instance
	var npcs = sim_mv.get_active_npcs()
	print("Active NPCs: ", npcs.size())
	
	var cat = null
	for n in npcs:
		if "cat" in n.npc_name.to_lower():
			cat = n
			break
	if not cat and not npcs.is_empty():
		cat = npcs[0]
	
	print("Target NPC: ", cat.npc_name, " at ", cat.world_position)
	
	var interacted: bool = false
	cat.npc_interacted.connect(func(_n):
		interacted = true
		print("  -> CAT NPC_INTERACTED SIGNAL FIRED!")
	)

	# Send mouse click event to sim_viewport at NPC screen position
	var canvas_xform = sim_mv.get_canvas_transform()
	var screen_pos = canvas_xform * cat.world_position
	print("Canvas transform: ", canvas_xform, " Screen pos: ", screen_pos)
	
	var mb = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = screen_pos
	mb.global_position = screen_pos
	
	vp.push_input(mb)
	await process_frame
	await process_frame
	
	mb.pressed = false
	vp.push_input(mb)
	await process_frame
	await process_frame

	print("Did cat interact fire via vp.push_input? ", interacted)

	editor.stop_playtest()
	editor.queue_free()
	quit(0)
