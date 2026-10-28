extends SceneTree

## Captures the server select (main + sub list) and login dialog states of the real login flow.

func _init() -> void:
	_run()


func _snap(name: String) -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	for i in 12:
		await process_frame
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))


func _run() -> void:
	var inst := (load("res://scenes/ui/login_screen.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 6:
		await process_frame
	await _snap("flow_server_main")
	var ss = inst.server_select_node
	var entries: Array = []
	if ss.has_method("show_sub_servers"):
		print("has show_sub_servers")
	var group_buttons: Array = ss.find_children("*", "BaseButton", true, false)
	print("server select buttons: ", group_buttons.size())
	inst.current_server = null
	inst.goto_state(inst.FlowState.LOGIN_DIALOG)
	await _snap("flow_login")
	print("saved")
	quit()
