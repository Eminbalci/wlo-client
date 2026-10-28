extends SceneTree

## Fills the in-world chat with every channel and captures it (CAPTURE_DIR sets the output folder).

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
	print("CHATDBG methods: add_chat_message=", hud.has_method("add_chat_message"), " add_message=", hud.has_method("add_message"))
	hud.add_chat_message("Daniel", "Hello everyone, this is a normal local message.", "Local")
	hud.add_chat_message("Betty", "Whisper to you from Betty with a fairly long sentence that should wrap nicely inside the chat window.", "Whisper")
	hud.add_chat_message("Roca", "Team message: let's fight the boss at the beach!", "Team")
	hud.add_chat_message("Satoru", "Guild message with some words.", "Guild")
	hud.add_chat_message("Kelang", "World shout! Selling Coconut x99.", "World")
	hud.add_chat_message("System", "You obtained Fresh Coconut x3.", "System")
	for i in 20:
		await process_frame
	root.get_texture().get_image().get_region(Rect2i(0, 520, 700, 200)).save_png(out_dir.path_join("chat_all.png"))
	print("saved chat")
	quit()
