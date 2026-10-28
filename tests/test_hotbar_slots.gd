extends SceneTree

func _init() -> void:
	print("Starting Hotbar & Quick Slot Verification Test...")
	var hud_scene = load("res://scenes/ui/hud.tscn")
	if not hud_scene:
		print("ERROR: Failed to load res://scenes/ui/hud.tscn")
		quit(1)
		return
	
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	
	if not hud.has_method("_setup_hotbar"):
		print("ERROR: HUD missing _setup_hotbar")
		quit(1)
		return
		
	var buttons = hud._hotkey_buttons
	var icons = hud._hotkey_icons
	
	print("Hotbar buttons count: ", buttons.size())
	print("Hotbar icons count: ", icons.size())
	
	if buttons.size() != 8 or icons.size() != 8:
		print("ERROR: Expected exactly 8 hotbar buttons and icons")
		quit(1)
		return
		
	for i in range(8):
		var btn = buttons[i]
		if not btn:
			print("ERROR: Hotbar button %d is null" % (i + 1))
			quit(1)
			return
		var lbl = btn.get_node_or_null("KeyLabel")
		var expected_f := "F%d" % (i + 1)
		if not lbl or lbl.text != expected_f:
			print("ERROR: Hotbar slot %d missing correct KeyLabel F%d" % [i + 1, i + 1])
			quit(1)
			return
		print("Slot %d (F%d) verified successfully." % [i + 1, i + 1])
		
	for i in range(8):
		var key_event = InputEventKey.new()
		key_event.keycode = KEY_F1 + i
		key_event.pressed = true
		hud._unhandled_input(key_event)

	print("All Hotbar & Quick Slot Buttons (F1-F8) verified successfully!")
	quit(0)
