class_name RadarChart
extends Control

## Dynamic 6-axis Hexagonal Radar Chart for Wonderland Online Role Attributes.
## Axes: AGI (top), INT (top-right), WIS (bottom-right), Bottom-anchor, CON (bottom-left), STR (top-left).

var stats: Dictionary = {
	"str": 10,
	"con": 10,
	"int": 10,
	"wis": 10,
	"agi": 10
}

const MAX_STAT_VALUE: float = 18.0
const RADAR_RADIUS: float = 44.0

func set_stats(new_stats: Dictionary) -> void:
	stats = new_stats.duplicate()
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	# Draw concentric guide hexagons (0.33, 0.66, 1.0)
	for s: float in [0.33, 0.66, 1.0]:
		var r: float = RADAR_RADIUS * s
		var ring_pts: PackedVector2Array = []
		for i in range(6):
			var angle: float = -PI / 2.0 + i * (PI / 3.0)
			ring_pts.append(center + Vector2(cos(angle), sin(angle)) * r)
		ring_pts.append(ring_pts[0])
		draw_polyline(ring_pts, Color(0.72, 0.65, 0.52, 0.45), 1.0)

	# Draw 6 radial spokes from center
	for i in range(6):
		var angle: float = -PI / 2.0 + i * (PI / 3.0)
		var pt := center + Vector2(cos(angle), sin(angle)) * RADAR_RADIUS
		draw_line(center, pt, Color(0.72, 0.65, 0.52, 0.35), 1.0)

	# Calculate stat polygon vertices
	var s_agi: float = clampf(float(stats.get("agi", 8)) / MAX_STAT_VALUE, 0.25, 1.0) * RADAR_RADIUS
	var s_int: float = clampf(float(stats.get("int", 8)) / MAX_STAT_VALUE, 0.25, 1.0) * RADAR_RADIUS
	var s_wis: float = clampf(float(stats.get("wis", 8)) / MAX_STAT_VALUE, 0.25, 1.0) * RADAR_RADIUS
	var s_bottom: float = RADAR_RADIUS * 0.30
	var s_con: float = clampf(float(stats.get("con", 8)) / MAX_STAT_VALUE, 0.25, 1.0) * RADAR_RADIUS
	var s_str: float = clampf(float(stats.get("str", 8)) / MAX_STAT_VALUE, 0.25, 1.0) * RADAR_RADIUS

	var poly_pts: PackedVector2Array = [
		center + Vector2(cos(-PI / 2.0), sin(-PI / 2.0)) * s_agi,
		center + Vector2(cos(-PI / 6.0), sin(-PI / 6.0)) * s_int,
		center + Vector2(cos(PI / 6.0), sin(PI / 6.0)) * s_wis,
		center + Vector2(cos(PI / 2.0), sin(PI / 2.0)) * s_bottom,
		center + Vector2(cos(5.0 * PI / 6.0), sin(5.0 * PI / 6.0)) * s_con,
		center + Vector2(cos(-5.0 * PI / 6.0), sin(-5.0 * PI / 6.0)) * s_str
	]

	draw_colored_polygon(poly_pts, Color(0.96, 0.65, 0.20, 0.55))
	poly_pts.append(poly_pts[0])
	draw_polyline(poly_pts, Color(0.90, 0.50, 0.10, 0.95), 1.5)
