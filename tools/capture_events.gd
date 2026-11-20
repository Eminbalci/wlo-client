extends SceneTree


func _init() -> void:
	for _i in range(3):
		await process_frame

	var window_res = load("res://scripts/ui/hud/events_window.gd")
	var window: Node = null
	if window_res is PackedScene:
		window = window_res.instantiate()
	elif window_res != null:
		window = window_res.new()

	if window != null:
		if window.has_method("set_day"):
			window.set_day("Thursday")
		if window.has_method("set_events"):
			window.set_events([
				{
					"name": "Quiz",
					"start": "14:00",
					"end": "14:30",
					"status": "Soon"
				}
			])
		get_root().add_child(window)
		if window.has_method("open"):
			window.open()
		elif window.has_method("show"):
			window.show()
		else:
			window.visible = true

	for _i in range(5):
		await process_frame

	get_root().get_texture().get_image().save_png("D:/Godot/WonderlandOnline/wonderland-online-client/docs/reference/real_client/godot_events.png")
	quit(0)
