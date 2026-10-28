extends SceneTree

var _frames: int = 0
var _scene: Node = null

func _init() -> void:
	_scene = load("res://scenes/world/map_view.tscn").instantiate()
	root.add_child(_scene)

func _process(delta: float) -> bool:
	_frames += 1
	var player = _scene.get_node("Entities/Player")
	var map_renderer = _scene.get_node("MapRenderer")
	var camera = _scene.get_node("Camera2D")
	
	if _frames == 3:
		print("--- Frame 3 ---")
		print("Player pos: ", player.position)
		print("Camera pos: ", camera.position)
		print("Viewport canvas transform: ", root.get_canvas_transform())
		print("MapRenderer canvas transform: ", map_renderer.get_canvas_transform())
		print("MapRenderer global mouse: ", map_renderer.get_global_mouse_position())
		quit(0)
		return true
	return false
