class_name MinimapMarker
extends Control

## Authentic Radar Minimap Player Position Indicator
## Renders a blinking green/yellow radar dot with high-contrast outline

@export var marker_radius: float = 3.5
@export var marker_color: Color = Color(0.15, 0.98, 0.2, 1.0)
@export var border_color: Color = Color(0.0, 0.0, 0.0, 0.9)
@export var highlight_color: Color = Color(1.0, 1.0, 1.0, 0.9)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(marker_radius * 2.0 + 4.0, marker_radius * 2.0 + 4.0)

func set_marker_color(p_color: Color) -> void:
	if marker_color != p_color:
		marker_color = p_color
		queue_redraw()

func _draw() -> void:
	# 1. Dark outline / drop shadow for universal contrast on light & dark maps
	draw_circle(Vector2.ZERO, marker_radius + 1.2, border_color)
	# 2. Main vibrant radar core (green / yellow)
	draw_circle(Vector2.ZERO, marker_radius, marker_color)
	# 3. Bright specular highlight at center-top-left
	draw_circle(Vector2(-0.6, -0.6), 1.2, highlight_color)
