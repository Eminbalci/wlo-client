class_name CutsceneRunner
extends Node2D

## Standalone In-Game Cutscene & Event Sequence Playback Controller.
## Interprets multi-track timeline sequences: camera pan/zoom/shake, actor motions/facings,
## dialogue boxes with typewriter text, audio cues, and screen fx.

signal cutscene_started
signal cutscene_finished
signal dialogue_started(speaker: String, text: String)
signal dialogue_ended
signal sfx_played(sfx_id: String)
signal bgm_changed(bgm_id: String)
signal time_advanced(current_time: float)

@export var autoplay: bool = true
@export var loop: bool = false
@export var total_duration: float = 15.0
@export var time_scale: float = 1.0

var current_time: float = 0.0
var is_playing: bool = false
var cutscene_data: Dictionary = {}
var _triggered_sfx: Dictionary = {}
var _last_dialogue_key: String = ""

@onready var camera: Camera2D = find_child("Camera2D", true, false)
@onready var actors_container: Node2D = find_child("Actors", true, false)
@onready var fade_rect: ColorRect = find_child("FadeRect", true, false)
@onready var flash_rect: ColorRect = find_child("FlashRect", true, false)
@onready var dialogue_box: Control = find_child("DialogueBox", true, false)
@onready var speaker_label: Label = find_child("SpeakerLabel", true, false)
@onready var text_label: Label = find_child("TextLabel", true, false)
@onready var audio_bgm: AudioStreamPlayer = find_child("AudioBGM", true, false)
@onready var audio_sfx: AudioStreamPlayer = find_child("AudioSFX", true, false)

func _ready() -> void:
	if has_meta("cutscene_data"):
		set_cutscene_data(get_meta("cutscene_data"))
	
	if autoplay:
		play()

func play() -> void:
	is_playing = true
	cutscene_started.emit()

func pause() -> void:
	is_playing = false

func stop() -> void:
	is_playing = false
	current_time = 0.0
	_triggered_sfx.clear()
	_last_dialogue_key = ""
	seek(0.0)
	cutscene_finished.emit()

func is_playback_active() -> bool:
	return is_playing

func seek(t: float) -> void:
	current_time = clampf(t, 0.0, total_duration)
	var state: Dictionary = evaluate_at_time(current_time)
	_apply_state(state)
	time_advanced.emit(current_time)

func set_cutscene_data(data: Dictionary) -> void:
	cutscene_data = data
	if data.has("total_duration"):
		total_duration = float(data["total_duration"])
	seek(current_time)

func _process(delta: float) -> void:
	if not is_playing:
		return
	
	current_time += delta * time_scale
	if current_time >= total_duration:
		if loop:
			current_time = 0.0
			_triggered_sfx.clear()
			_last_dialogue_key = ""
		else:
			current_time = total_duration
			is_playing = false
			seek(current_time)
			cutscene_finished.emit()
			return
	
	seek(current_time)

func _apply_state(state: Dictionary) -> void:
	# 1. Camera
	if camera and state.has("camera"):
		var cam_state: Dictionary = state["camera"]
		camera.position = cam_state.get("position", Vector2.ZERO) + cam_state.get("shake_offset", Vector2.ZERO)
		var zoom_val: float = float(cam_state.get("zoom", 1.0))
		camera.zoom = Vector2(zoom_val, zoom_val)
		if state.has("screen_fx"):
			var tilt_deg: float = float(state["screen_fx"].get("tilt_angle", 0.0))
			camera.rotation_degrees = tilt_deg
	
	# 2. Actors
	if actors_container and state.has("actors"):
		var actors_state: Dictionary = state["actors"]
		for actor_id in actors_state.keys():
			var actor_node: Node2D = actors_container.find_child(actor_id, true, false) as Node2D
			if actor_node:
				var a_data: Dictionary = actors_state[actor_id]
				actor_node.position = a_data.get("position", Vector2.ZERO)
				actor_node.visible = bool(a_data.get("visible", true))
				if actor_node.has_method("set_facing"):
					actor_node.call("set_facing", int(a_data.get("facing", 0)))
				if actor_node.has_method("set_action"):
					actor_node.call("set_action", str(a_data.get("action", "Idle")))
	
	# 3. Dialogue
	if state.has("dialogue"):
		var dlg: Dictionary = state["dialogue"]
		var is_active: bool = bool(dlg.get("is_active", false))
		if dialogue_box:
			dialogue_box.visible = is_active
		if is_active:
			var spk: String = str(dlg.get("speaker", ""))
			var txt: String = str(dlg.get("text", ""))
			if speaker_label:
				speaker_label.text = spk
			if text_label:
				text_label.text = txt
			var cur_key: String = "%s:%s" % [spk, dlg.get("full_text", "")]
			if cur_key != _last_dialogue_key:
				_last_dialogue_key = cur_key
				dialogue_started.emit(spk, txt)
		else:
			if not _last_dialogue_key.is_empty():
				_last_dialogue_key = ""
				dialogue_ended.emit()
	
	# 4. Audio
	if state.has("audio"):
		var aud: Dictionary = state["audio"]
		var bgm_id: String = str(aud.get("bgm", ""))
		if not bgm_id.is_empty():
			bgm_changed.emit(bgm_id)
		var sfx_list: Array = aud.get("sfx_triggers", [])
		for sfx in sfx_list:
			var sfx_id: String = str(sfx)
			if not _triggered_sfx.has(sfx_id):
				_triggered_sfx[sfx_id] = true
				sfx_played.emit(sfx_id)
	
	# 5. Screen FX
	if state.has("screen_fx"):
		var fx: Dictionary = state["screen_fx"]
		if fade_rect:
			var fade_c: Color = fx.get("fade_color", Color(0, 0, 0, 0))
			fade_rect.color = fade_c
			fade_rect.visible = fade_c.a > 0.001
		if flash_rect:
			var flash_c: Color = fx.get("flash_color", Color(1, 0, 0, 0))
			flash_rect.color = flash_c
			flash_rect.visible = flash_c.a > 0.001

func evaluate_at_time(t: float) -> Dictionary:
	var result: Dictionary = {
		"time": t,
		"camera": _eval_camera(t),
		"actors": _eval_actors(t),
		"dialogue": _eval_dialogue(t),
		"audio": _eval_audio(t),
		"screen_fx": _eval_screen_fx(t)
	}
	return result

func _eval_camera(t: float) -> Dictionary:
	var cam_keys: Array = cutscene_data.get("tracks", {}).get("camera", [])
	if cam_keys.is_empty():
		return {
			"position": Vector2(400.0, 300.0),
			"zoom": 1.0,
			"shake_intensity": 0.0,
			"shake_offset": Vector2.ZERO
		}
	
	var pos: Vector2 = Vector2(400.0, 300.0)
	var zoom: float = 1.0
	
	if t <= float(cam_keys[0].get("time", 0.0)):
		pos = _parse_vector2(cam_keys[0].get("pan_target", Vector2(400, 300)))
		zoom = float(cam_keys[0].get("zoom", 1.0))
	elif t >= float(cam_keys[cam_keys.size() - 1].get("time", 0.0)):
		var last_k: Dictionary = cam_keys[cam_keys.size() - 1]
		pos = _parse_vector2(last_k.get("pan_target", Vector2(400, 300)))
		zoom = float(last_k.get("zoom", 1.0))
	else:
		for i in range(cam_keys.size() - 1):
			var k1: Dictionary = cam_keys[i]
			var k2: Dictionary = cam_keys[i + 1]
			var t1: float = float(k1.get("time", 0.0))
			var t2: float = float(k2.get("time", 0.0))
			if t >= t1 and t <= t2:
				var factor: float = (t - t1) / maxf(t2 - t1, 0.0001)
				var interp: String = str(k1.get("interpolation", "Linear"))
				factor = _apply_interp(factor, interp)
				var p1: Vector2 = _parse_vector2(k1.get("pan_target", Vector2(400, 300)))
				var p2: Vector2 = _parse_vector2(k2.get("pan_target", Vector2(400, 300)))
				pos = p1.lerp(p2, factor)
				var z1: float = float(k1.get("zoom", 1.0))
				var z2: float = float(k2.get("zoom", 1.0))
				zoom = lerpf(z1, z2, factor)
				break
	
	# Shake evaluation
	var total_shake: float = 0.0
	for k in cam_keys:
		var k_time: float = float(k.get("time", 0.0))
		var k_dur: float = float(k.get("shake_duration", 0.0))
		var k_int: float = float(k.get("shake_intensity", 0.0))
		if k_int > 0.0 and t >= k_time and t <= k_time + k_dur:
			var r: float = 1.0 - (t - k_time) / maxf(k_dur, 0.0001)
			total_shake = maxf(total_shake, k_int * r)
	
	var shake_offset: Vector2 = Vector2.ZERO
	if total_shake > 0.001:
		shake_offset = Vector2(
			sin(t * 43.7) * total_shake * 18.0,
			cos(t * 37.3) * total_shake * 14.0
		)
	
	return {
		"position": pos,
		"zoom": zoom,
		"shake_intensity": total_shake,
		"shake_offset": shake_offset
	}

func _eval_actors(t: float) -> Dictionary:
	var result: Dictionary = {}
	var actors_meta: Dictionary = cutscene_data.get("actors", {})
	var actor_keys: Array = cutscene_data.get("tracks", {}).get("actor", [])
	
	# Initial states from roster
	for aid in actors_meta.keys():
		var am: Dictionary = actors_meta[aid]
		result[aid] = {
			"actor_id": aid,
			"actor_name": am.get("name", aid),
			"position": _parse_vector2(am.get("initial_pos", Vector2(400, 300))),
			"facing": int(am.get("initial_facing", 0)),
			"action": str(am.get("initial_action", "Idle")),
			"visible": true
		}
	
	# Group keyframes by actor
	var keys_by_actor: Dictionary = {}
	for k in actor_keys:
		var aid: String = str(k.get("actor_id", "player"))
		if not keys_by_actor.has(aid):
			keys_by_actor[aid] = []
		keys_by_actor[aid].append(k)
	
	for aid in keys_by_actor.keys():
		var a_keys: Array = keys_by_actor[aid]
		if a_keys.is_empty():
			continue
		
		if not result.has(aid):
			result[aid] = {
				"actor_id": aid,
				"actor_name": aid,
				"position": Vector2(400, 300),
				"facing": 0,
				"action": "Idle",
				"visible": true
			}
		
		if t <= float(a_keys[0].get("time", 0.0)):
			var k0: Dictionary = a_keys[0]
			result[aid]["position"] = _parse_vector2(k0.get("position", Vector2(400, 300)))
			result[aid]["facing"] = int(k0.get("facing", 0))
			result[aid]["action"] = str(k0.get("action", "Idle"))
			result[aid]["visible"] = bool(k0.get("visible", true))
		elif t >= float(a_keys[a_keys.size() - 1].get("time", 0.0)):
			var kn: Dictionary = a_keys[a_keys.size() - 1]
			result[aid]["position"] = _parse_vector2(kn.get("position", Vector2(400, 300)))
			result[aid]["facing"] = int(kn.get("facing", 0))
			result[aid]["action"] = str(kn.get("action", "Idle"))
			result[aid]["visible"] = bool(kn.get("visible", true))
		else:
			for i in range(a_keys.size() - 1):
				var k1: Dictionary = a_keys[i]
				var k2: Dictionary = a_keys[i + 1]
				var t1: float = float(k1.get("time", 0.0))
				var t2: float = float(k2.get("time", 0.0))
				if (t >= t1 and t < t2) or (i == a_keys.size() - 2 and t <= t2):
					var factor: float = (t - t1) / maxf(t2 - t1, 0.0001)
					var p1: Vector2 = _parse_vector2(k1.get("position", Vector2(400, 300)))
					var p2: Vector2 = _parse_vector2(k2.get("position", Vector2(400, 300)))
					result[aid]["position"] = p1.lerp(p2, factor)
					result[aid]["facing"] = int(k1.get("facing", 0))
					result[aid]["action"] = str(k1.get("action", "Idle"))
					result[aid]["visible"] = bool(k1.get("visible", true))
					break
					
	return result

func _eval_dialogue(t: float) -> Dictionary:
	var dlg_keys: Array = cutscene_data.get("tracks", {}).get("dialogue", [])
	for k in dlg_keys:
		var k_time: float = float(k.get("time", 0.0))
		var k_dur: float = float(k.get("duration", 3.0))
		if t >= k_time and t < k_time + k_dur:
			var full_txt: String = str(k.get("text", ""))
			var type_delay: float = float(k.get("typewriter_delay", 0.03))
			var visible_txt: String = full_txt
			if type_delay > 0.001:
				var chars_count: int = int((t - k_time) / type_delay)
				visible_txt = full_txt.substr(0, mini(chars_count, full_txt.length()))
			
			return {
				"is_active": true,
				"speaker": str(k.get("speaker", "")),
				"text": visible_txt,
				"full_text": full_txt,
				"talk_id": int(k.get("talk_id", 0)),
				"time": k_time,
				"duration": k_dur
			}
	
	return {
		"is_active": false,
		"speaker": "",
		"text": "",
		"full_text": "",
		"talk_id": 0,
		"time": 0.0,
		"duration": 0.0
	}

func _eval_audio(t: float) -> Dictionary:
	var aud_keys: Array = cutscene_data.get("tracks", {}).get("audio", [])
	var active_bgm: String = ""
	var volume_db: float = 0.0
	var pitch_scale: float = 1.0
	var triggers: Array[String] = []
	
	for k in aud_keys:
		var k_time: float = float(k.get("time", 0.0))
		var a_type: String = str(k.get("audio_type", "BGM"))
		var r_id: String = str(k.get("resource_id", ""))
		
		if a_type == "BGM" or a_type == "Ambient":
			if t >= k_time:
				active_bgm = r_id
				volume_db = float(k.get("volume_db", 0.0))
				pitch_scale = float(k.get("pitch_scale", 1.0))
		elif a_type == "SFX":
			if absf(t - k_time) <= 0.2:
				triggers.append(r_id)
				
	return {
		"bgm": active_bgm,
		"volume_db": volume_db,
		"pitch_scale": pitch_scale,
		"sfx_triggers": triggers
	}

func _eval_screen_fx(t: float) -> Dictionary:
	var fx_keys: Array = cutscene_data.get("tracks", {}).get("screen_fx", [])
	var fade_col: Color = Color(0, 0, 0, 0)
	var flash_col: Color = Color(1, 0, 0, 0)
	var tilt_ang: float = 0.0
	
	for k in fx_keys:
		var k_time: float = float(k.get("time", 0.0))
		var k_dur: float = float(k.get("duration", 2.0))
		if t >= k_time and t <= k_time + k_dur:
			var fx_type: String = str(k.get("fx_type", "None"))
			var intensity: float = float(k.get("intensity", 1.0))
			var progress: float = (t - k_time) / maxf(k_dur, 0.0001)
			
			if fx_type == "FadeColor":
				var c: Color = _parse_color(k.get("color", Color.BLACK))
				# Fade out or sustain
				fade_col = Color(c.r, c.g, c.b, intensity * (1.0 - progress if progress > 0.8 else 1.0))
			elif fx_type == "Flash":
				var c: Color = _parse_color(k.get("color", Color.RED))
				var freq: float = float(k.get("pulse_frequency", 2.0))
				var pulse: float = maxf(0.0, sin((t - k_time) * freq * TAU))
				flash_col = Color(c.r, c.g, c.b, c.a * pulse * intensity)
			elif fx_type == "CameraTilt":
				var target_tilt: float = float(k.get("tilt_angle", 0.0))
				tilt_ang = lerpf(0.0, target_tilt, clampf(progress * 2.0, 0.0, 1.0))
			elif fx_type == "TintPulse":
				var c: Color = _parse_color(k.get("color", Color(0.2, 0.2, 0.4, 0.3)))
				var freq: float = float(k.get("pulse_frequency", 1.0))
				var pulse: float = 0.5 + 0.5 * sin((t - k_time) * freq * TAU)
				fade_col = Color(c.r, c.g, c.b, c.a * pulse * intensity)
				
	return {
		"fade_color": fade_col,
		"flash_color": flash_col,
		"tilt_angle": tilt_ang
	}

func _apply_interp(factor: float, interp: String) -> float:
	match interp:
		"EaseIn":
			return factor * factor
		"EaseOut":
			return 1.0 - (1.0 - factor) * (1.0 - factor)
		"EaseInOut":
			return smoothstep(0.0, 1.0, factor)
		"Step":
			return 0.0 if factor < 1.0 else 1.0
		_:
			return factor

func _parse_vector2(val: Variant) -> Vector2:
	if val is Vector2:
		return val
	if val is Dictionary:
		return Vector2(float(val.get("x", 0.0)), float(val.get("y", 0.0)))
	if val is Array and val.size() >= 2:
		return Vector2(float(val[0]), float(val[1]))
	return Vector2.ZERO

func _parse_color(val: Variant) -> Color:
	if val is Color:
		return val
	if val is String:
		return Color.from_string(val, Color.BLACK)
	if val is Dictionary:
		return Color(
			float(val.get("r", 0.0)),
			float(val.get("g", 0.0)),
			float(val.get("b", 0.0)),
			float(val.get("a", 1.0))
		)
	if val is Array and val.size() >= 4:
		return Color(float(val[0]), float(val[1]), float(val[2]), float(val[3]))
	return Color.BLACK
