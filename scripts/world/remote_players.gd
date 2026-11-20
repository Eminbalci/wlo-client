class_name RemotePlayers
extends Node2D

## Other players on the same map, shown as simple markers (a dot and the name) from the packets the
## server sends: AC4 when a player appears and AC6:1 when one walks. Markers glide to the position the
## server reports at WALK_SPEED pixels per second. Players on another map than `current_map` are hidden.

const WALK_SPEED := 160.0
const DOT_RADIUS := 7.0

var own_id: int = 0
var current_map: int = 0
var players: Dictionary = {} # char id -> {node: Node2D, map: int, target: Vector2}


## Routes a server packet. Returns true when it concerned a remote player.
func handle_packet(action: int, payload: PackedByteArray) -> bool:
	match action:
		4:
			var info := WorldEntry.parse_other_player(payload)
			if info.is_empty() or int(info.char_id) == own_id:
				return false
			_show(info)
			return true
		6:
			var walk := WorldEntry.parse_remote_walk(payload)
			if walk.is_empty() or not players.has(int(walk.char_id)):
				return false
			players[int(walk.char_id)].target = Vector2(float(walk.x), float(walk.y))
			return true
	return false


func set_map(map_id: int) -> void:
	current_map = map_id
	for id in players:
		_apply_visibility(players[id])


func _show(info: Dictionary) -> void:
	var id := int(info.char_id)
	var pos := Vector2(float(info.x), float(info.y))
	if not players.has(id):
		players[id] = {"node": _make_marker(str(info.name)), "map": int(info.map), "target": pos}
		add_child(players[id].node)
	players[id].map = int(info.map)
	players[id].target = pos
	players[id].node.position = pos
	_apply_visibility(players[id])


func _apply_visibility(entry: Dictionary) -> void:
	(entry.node as Node2D).visible = current_map == 0 or int(entry.map) == current_map


func _make_marker(player_name: String) -> Node2D:
	var marker := _Marker.new()
	marker.label_text = player_name
	return marker


func _process(delta: float) -> void:
	for id in players:
		var node: Node2D = players[id].node
		node.position = node.position.move_toward(players[id].target, WALK_SPEED * delta)


class _Marker extends Node2D:
	var label_text: String = ""

	func _draw() -> void:
		draw_circle(Vector2.ZERO, 7.0, Color(0.95, 0.7, 0.2, 0.95))
		draw_string(ThemeDB.fallback_font, Vector2(-30, -12), label_text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, 12, Color.WHITE)

	func _ready() -> void:
		queue_redraw()
