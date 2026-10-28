extends SceneTree

var _frames: int = 0
var _scene: Node = null

func _init() -> void:
	_scene = load("res://scenes/world/map_view.tscn").instantiate()
	root.add_child(_scene)

func _process(delta: float) -> bool:
	_frames += 1
	if _frames == 3:
		var player = _scene.get_node("Entities/Player")
		var map_renderer = _scene.get_node("MapRenderer")
		var camera = _scene.get_node("Camera2D")
		
		print("Player ready pos: ", player.position, " world_pos: ", player.world_position)
		print("Camera ready pos: ", camera.position)
		
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = Vector2(500, 350)
		ev.global_position = Vector2(500, 350)
		
		# Test what map_renderer._unhandled_input does:
		map_renderer._unhandled_input(ev)
		
		print("After click:")
		print("Player target_world_position: ", player.target_world_position)
		var expected_canvas = camera.position + (Vector2(500, 350) - Vector2(800, 600) * 0.5)
		print("Expected click canvas: ", expected_canvas)
		print("Player target in canvas: ", IsometricMath.world_to_screen(player.target_world_position))
		return true
	return false
