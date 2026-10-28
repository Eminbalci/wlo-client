extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/world/map_view.tscn").instantiate()
	root.add_child(scene)
	
	var player = scene.get_node("Entities/Player")
	var map_renderer = scene.get_node("MapRenderer")
	var camera = scene.get_node("Camera2D")
	
	print("Player initial pos: ", player.position, " world_pos: ", player.world_position)
	print("Camera initial pos: ", camera.position)
	
	# Simulate mouse click
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(400, 300)
	ev.global_position = Vector2(400, 300)
	
	map_renderer._unhandled_input(ev)
	
	print("Local mouse pos on map_renderer: ", map_renderer.get_local_mouse_position())
	print("Global mouse pos on map_renderer: ", map_renderer.get_global_mouse_position())
	print("Player target_world_pos: ", player.target_world_position)
	print("Target screen pos: ", IsometricMath.world_to_screen(player.target_world_position))
	quit(0)
