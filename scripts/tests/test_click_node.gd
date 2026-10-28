extends Node

func _ready() -> void:
	var scene = load("res://scenes/world/map_view.tscn").instantiate()
	add_child(scene)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var player = scene.get_node("Entities/Player")
	var map_renderer = scene.get_node("MapRenderer")
	var camera = scene.get_node("Camera2D")
	
	print("Player ready pos: ", player.position, " world_pos: ", player.world_position)
	print("Camera ready pos: ", camera.position)
	
	# In a 800x600 window, the player is at center (screen center).
	# If player is at (867, 1108.5), and camera is at (867, 1108.5).
	# When mouse clicks at screen position (500, 350) [100px right, 50px down from center]:
	# What should canvas/map coordinate be?
	# Center of screen is (400, 300).
	# Mouse is at (500, 350), which is (+100, +50) from screen center.
	# So in world 2D map pixels, the click is at:
	# camera.position + Vector2(100, 50) = (967, 1158.5)!
	
	# Now let's see what get_global_mouse_position() and event.position give!
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(500, 350)
	ev.global_position = Vector2(500, 350)
	
	# What does map_renderer do with this event?
	# In map_renderer.gd:
	# var screen_click: Vector2 = get_local_mouse_position()
	# var world_coord: Vector2 = IsometricMath.screen_to_world(screen_click)
	print("Viewport size: ", get_viewport().size)
	print("MapRenderer get_local_mouse_position(): ", map_renderer.get_local_mouse_position())
	print("MapRenderer get_global_mouse_position(): ", map_renderer.get_global_mouse_position())
	
	# If screen_click = map_renderer.get_global_mouse_position() when mouse is at (500, 350):
	var mouse_in_canvas = camera.position + (ev.position - Vector2(get_viewport().size) * 0.5)
	print("Calculated mouse in canvas: ", mouse_in_canvas)
	var world_calc = IsometricMath.screen_to_world(mouse_in_canvas)
	print("World calc: ", world_calc)
	var back_to_canvas = IsometricMath.world_to_screen(world_calc)
	print("Back to canvas: ", back_to_canvas)
	
	get_tree().quit(0)
