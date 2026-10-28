class_name WloClickRipple
extends Node2D

## Authentic Wonderland Online Ground Click Destination Marker.
## Plays the authentic 4-frame animated arrow sequence (Arrow1.bmp - Arrow4.bmp)
## at the target world coordinate when the player clicks on the map terrain.

const FRAME_INTERVAL: float = 0.12 # ~8.3 FPS authentic frame rate
const TOTAL_LOOPS: int = 1

var _frames: Array[Texture2D] = []
var _elapsed: float = 0.0
var _current_frame: int = 0
var _total_duration: float = 0.0

func _ready() -> void:
	z_index = 30 # Render above map terrain, shadows, and click grid
	_load_textures()
	_total_duration = FRAME_INTERVAL * 4.0 * float(TOTAL_LOOPS)

func _load_textures() -> void:
	_frames.clear()
	for i in range(1, 5):
		var res_path := "res://assets/fx/click_arrow_%d.png" % i
		var global_path := ProjectSettings.globalize_path(res_path)
		var tex: Texture2D = null
		if ResourceLoader.exists(res_path):
			tex = load(res_path)
		if not tex and FileAccess.file_exists(res_path):
			var img := Image.load_from_file(global_path)
			if img:
				tex = ImageTexture.create_from_image(img)
		if tex:
			_frames.append(tex)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _total_duration or _frames.is_empty():
		queue_free()
		return
	
	var frame_idx: int = int(floor(_elapsed / FRAME_INTERVAL)) % _frames.size()
	if frame_idx != _current_frame:
		_current_frame = frame_idx
		queue_redraw()

func _draw() -> void:
	if _frames.is_empty() or _current_frame < 0 or _current_frame >= _frames.size():
		return
	
	var tex := _frames[_current_frame]
	if not tex:
		return
	
	# Calculate fade out during final loop
	var alpha: float = 1.0
	var fade_start: float = _total_duration * 0.75
	if _elapsed > fade_start:
		alpha = clampf(1.0 - (_elapsed - fade_start) / (_total_duration - fade_start), 0.0, 1.0)
	
	var tex_size := tex.get_size()
	# Center anchor at destination point
	var draw_pos := -tex_size * 0.5
	draw_texture(tex, draw_pos, Color(1.0, 1.0, 1.0, alpha))
