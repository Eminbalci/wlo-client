extends SceneTree

var _frames: int = 0
var _scene: Node = null

func _init() -> void:
	_scene = load("res://scenes/world/map_view.tscn").instantiate()
	root.add_child(_scene)

func _process(delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		var map_renderer = _scene.get_node("MapRenderer")
		var camera = _scene.get_node("Camera2D")
		
		print("map_renderer get_local_mouse_position(): ", map_renderer.get_local_mouse_position())
		print("map_renderer get_global_mouse_position(): ", map_renderer.get_global_mouse_position())
		print("camera get_local_mouse_position(): ", camera.get_local_mouse_position())
		print("camera get_global_mouse_position(): ", camera.get_global_mouse_position())
		print("root get_mouse_position(): ", root.get_mouse_position())
		return true
	return false
