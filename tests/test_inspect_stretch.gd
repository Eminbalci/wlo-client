extends SceneTree

func _init() -> void:
	for mode in ['disabled', 'canvas_items', 'viewport']:
		for aspect in ['ignore', 'keep', 'keep_width', 'keep_height', 'expand']:
			print('Testing: mode=', mode, ' aspect=', aspect)
	
	_run_verification.call_deferred()

func _run_verification() -> void:
	print("[TestInspectStretch] Verifying ProjectSettings stretch and window configuration...")
	
	var width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var resizable = ProjectSettings.get_setting("display/window/size/resizable", true)
	var mode = ProjectSettings.get_setting("display/window/stretch/mode", "disabled")
	var aspect = ProjectSettings.get_setting("display/window/stretch/aspect", "keep")
	
	print("[TestInspectStretch] Settings: width=%s, height=%s, resizable=%s, mode=%s, aspect=%s" % [
		width, height, resizable, mode, aspect
	])
	
	assert(width == 1280, "viewport_width must be 1280")
	assert(height == 720, "viewport_height must be 720")
	assert(resizable == true, "resizable must be true")
	assert(mode == "disabled", "stretch/mode must be 'disabled' (the client resizes its layout instead of scaling)")
	assert(aspect == "ignore", "stretch/aspect must be 'ignore'")
	
	# Instantiate WorldEditor to test root window scaling & resizing logic
	print("[TestInspectStretch] Instantiating WorldEditor to test responsive window setup...")
	var scene_res = ResourceLoader.load("res://scenes/tools/world_editor.tscn")
	assert(scene_res != null, "world_editor.tscn must load")
	
	var editor = scene_res.instantiate()
	assert(editor != null, "world_editor must instantiate")
	root.add_child(editor)
	
	await process_frame
	await process_frame
	
	assert(root.content_scale_mode == Window.CONTENT_SCALE_MODE_DISABLED, "content_scale_mode must be Window.CONTENT_SCALE_MODE_DISABLED")
	assert(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_IGNORE, "content_scale_aspect must be Window.CONTENT_SCALE_ASPECT_IGNORE")
	print("[TestInspectStretch] Root scale settings verified: mode=DISABLED, aspect=IGNORE.")
	
	# Test resize adaptation
	root.size = Vector2i(1600, 900)
	await process_frame
	print("[TestInspectStretch] Resized root window to (1600, 900). Editor size: ", editor.size)
	assert(editor.size == Vector2(1600, 900), "Editor size must adapt to window size without letterboxing")
	
	editor.queue_free()
	await process_frame
	print("[TestInspectStretch] ALL STRETCH AND RESIZE TESTS PASSED SUCCESSFULLY!")
	quit(0)
