extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/world/map_view.tscn").instantiate()
	root.add_child(scene)
	
	var map_renderer = scene.get_node("MapRenderer")
	var camera = scene.get_node("Camera2D")
	var player = scene.get_node("Entities/Player")
	
	print("--- Transformation Test ---")
	print("Camera position: ", camera.position)
	print("Canvas transform: ", map_renderer.get_canvas_transform())
	print("Inverse: ", map_renderer.get_canvas_transform().affine_inverse())
	
	var ev_pos := Vector2(500, 350)
	var calc: Vector2 = map_renderer.get_canvas_transform().affine_inverse() * ev_pos
	print("Calc result: ", calc)
	
	root.warp_mouse(ev_pos)
	print("Global mouse position: ", map_renderer.get_global_mouse_position())
	print("Expected world position: Vector2(1142, 1125)")
	
	quit(0)
