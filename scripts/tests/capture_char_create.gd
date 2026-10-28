extends Node

var frames_rendered := 0
var cc: Control = null

func _ready() -> void:
	print("--- Running Character Create Screen Capture ---")
	var scene = load("res://scenes/ui/auth/character_create.tscn")
	cc = scene.instantiate()
	add_child(cc)
	if cc.has_method("start_wizard"):
		cc.start_wizard(0)

func _process(_delta: float) -> void:
	frames_rendered += 1
	
	if frames_rendered == 6:
		var img: Image = get_viewport().get_texture().get_image()
		var out1 := "D:/Godot/WonderlandOnline/wonderland-online-client/test_screenshots/char_create_step1.png"
		img.save_png(out1)
		print("[PASS] Saved Step 1 capture to: ", out1)
		
		# Move to Step 2
		if cc and cc.has_method("goto_step"):
			cc.first_name_input.text = "Hero"
			cc.family_name_input.text = "Legend"
			cc.goto_step(2)
	
	if frames_rendered == 12:
		var img: Image = get_viewport().get_texture().get_image()
		var out2 := "D:/Godot/WonderlandOnline/wonderland-online-client/test_screenshots/char_create_step2.png"
		img.save_png(out2)
		print("[PASS] Saved Step 2 capture to: ", out2)
		
		# Move to Step 3
		if cc and cc.has_method("goto_step"):
			cc.goto_step(3)
	
	if frames_rendered == 18:
		var img: Image = get_viewport().get_texture().get_image()
		var out3 := "D:/Godot/WonderlandOnline/wonderland-online-client/test_screenshots/char_create_step3.png"
		img.save_png(out3)
		print("[PASS] Saved Step 3 capture to: ", out3)
		get_tree().quit(0)
