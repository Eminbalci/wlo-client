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
		
		# Test click at screen (500, 350)
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = Vector2(500, 350)
		
		var canvas_pos: Vector2 = map_renderer.get_canvas_transform().affine_inverse() * ev.position
		var world_coord: Vector2 = IsometricMath.screen_to_world(canvas_pos)
		player.set_target_world_position(world_coord)
		
		print("Player current pos: ", player.position)
		print("Click screen pos: ", ev.position)
		print("Click canvas pos: ", canvas_pos)
		print("Target world pos: ", player.target_world_position)
		print("Target canvas pos: ", IsometricMath.world_to_screen(player.target_world_position))
		print("Difference from clicked canvas pos: ", canvas_pos.distance_to(IsometricMath.world_to_screen(player.target_world_position)))
		return true
	return false
