class_name MinimapWaypoint
extends Control

## Waypoint marker indicating click-to-move pathfinding destination on Radar Minimap
@export var marker_radius: float = 4.0
@export var marker_color: Color = Color(0.2, 0.85, 1.0, 0.95) # Cyan
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.8)
@export var pulse_color: Color = Color(1.0, 1.0, 1.0, 0.7)

var _pulse_scale: float = 1.0
var _pulse_timer: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(16, 16)

func _process(delta: float) -> void:
	if visible:
		_pulse_timer += delta * 4.0
		_pulse_scale = 1.0 + 0.35 * sin(_pulse_timer)
		queue_redraw()

func _draw() -> void:
	# 1. Pulsing outer radar ring
	draw_arc(Vector2.ZERO, marker_radius * _pulse_scale + 2.0, 0.0, TAU, 16, pulse_color, 1.2)
	# 2. Dark contrast shadow
	draw_circle(Vector2.ZERO, marker_radius + 1.2, shadow_color)
	# 3. Vibrant waypoint core
	draw_circle(Vector2.ZERO, marker_radius, marker_color)
	# 4. White center target pip
	draw_circle(Vector2.ZERO, 1.5, Color(1.0, 1.0, 1.0, 1.0) )
