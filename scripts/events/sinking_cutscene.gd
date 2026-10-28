class_name SinkingCutsceneController
extends Node

## Controller for the authentic Wonderland Online Ship Sinking Event Sequence.
## Coordinates decaying trauma camera shake, dynamic ship tilt, emergency sirens,
## red hazard flashing overlay, structural stress audio cues, and seamless fade transition to Deserted Island Beach.

signal cutscene_started(trigger_source: String)
signal stage_changed(stage_name: String)
signal cutscene_finished
signal transition_to_beach(beach_scene_path: String)

enum CutsceneStage {
	NORMAL,
	WARNING,
	SINKING,
	FADED,
	AWAKENED
}

@export var camera_path: NodePath = NodePath("Camera2D")
@export var red_overlay_path: NodePath = NodePath("CanvasLayer/RedOverlay")
@export var audio_player_path: NodePath = NodePath("AlarmAudio")
@export var sfx_player_path: NodePath = NodePath("SinkingSFX")
@export var fade_overlay_path: NodePath = NodePath("CanvasLayer/FadeOverlay")
@export var beach_scene_path: String = "res://scenes/maps/map_10011_beach.tscn"

# Cutscene pacing parameters (punchy 6.0s total sequence)
@export var warning_duration: float = 2.0
@export var sinking_duration: float = 2.5
@export var fade_duration: float = 1.5
@export var time_scale: float = 1.0

var current_stage: CutsceneStage = CutsceneStage.NORMAL
var is_cutscene_active: bool:
	get: return current_stage != CutsceneStage.NORMAL and current_stage != CutsceneStage.AWAKENED
var elapsed_time: float = 0.0
var trauma: float = 0.0
var max_offset: Vector2 = Vector2(20.0, 20.0)
var max_roll: float = 0.06 # Camera tilt roll
var ship_tilt_angle: float = 0.0 # Progressive ship tilt as hull floods
var noise: FastNoiseLite = FastNoiseLite.new()
var noise_y: float = 0.0
var trigger_reason: String = ""

var _camera: Camera2D = null
var camera: Camera2D:
	get:
		if not _camera and not camera_path.is_empty() and has_node(camera_path):
			_camera = get_node(camera_path) as Camera2D
		elif not _camera and is_inside_tree():
			if get_viewport():
				_camera = get_viewport().get_camera_2d()
			if not _camera and get_parent():
				_camera = get_parent().get_node_or_null("Camera2D") as Camera2D
				if not _camera and "camera" in get_parent():
					_camera = get_parent().camera as Camera2D
		return _camera
	set(val):
		_camera = val

## The ship lists up to ~9 degrees as the hull floods; the camera pushes in slightly.
const MAX_SHIP_TILT: float = 0.16
const MAX_SINKING_ZOOM: float = 0.12
const MAX_FLOOD_FRACTION: float = 0.62

var _flood_overlay: ColorRect = null
var _base_zoom: Vector2 = Vector2.ONE

var _red_overlay: ColorRect = null
var red_overlay: ColorRect:
	get:
		if not _red_overlay and not red_overlay_path.is_empty() and has_node(red_overlay_path):
			_red_overlay = get_node(red_overlay_path) as ColorRect
		elif not _red_overlay and is_inside_tree():
			_ensure_ui_overlays()
		return _red_overlay
	set(val):
		_red_overlay = val

var _audio_player: AudioStreamPlayer = null
var audio_player: AudioStreamPlayer:
	get:
		if not _audio_player and not audio_player_path.is_empty() and has_node(audio_player_path):
			_audio_player = get_node(audio_player_path) as AudioStreamPlayer
		elif not _audio_player and is_inside_tree():
			_ensure_audio_players()
		return _audio_player
	set(val):
		_audio_player = val

var _sfx_player: AudioStreamPlayer = null
var sfx_player: AudioStreamPlayer:
	get:
		if not _sfx_player and not sfx_player_path.is_empty() and has_node(sfx_player_path):
			_sfx_player = get_node(sfx_player_path) as AudioStreamPlayer
		elif not _sfx_player and is_inside_tree():
			_ensure_audio_players()
		return _sfx_player
	set(val):
		_sfx_player = val

var _fade_overlay: ColorRect = null
var fade_overlay: ColorRect:
	get:
		if not _fade_overlay and not fade_overlay_path.is_empty() and has_node(fade_overlay_path):
			_fade_overlay = get_node(fade_overlay_path) as ColorRect
		elif not _fade_overlay and is_inside_tree():
			_ensure_ui_overlays()
		return _fade_overlay
	set(val):
		_fade_overlay = val

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 3.0
	
	_ensure_ui_overlays()
	_ensure_audio_players()
	
	if red_overlay:
		red_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
		red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fade_overlay:
		fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ensure_ui_overlays() -> void:
	if not is_inside_tree():
		return
	if _red_overlay and _fade_overlay:
		return
		
	var canvas: CanvasLayer = null
	if not red_overlay_path.is_empty() and has_node(red_overlay_path):
		_red_overlay = get_node(red_overlay_path) as ColorRect
	if not fade_overlay_path.is_empty() and has_node(fade_overlay_path):
		_fade_overlay = get_node(fade_overlay_path) as ColorRect
		
	if _red_overlay and _fade_overlay:
		return

	if has_node("CanvasLayer"):
		canvas = get_node("CanvasLayer") as CanvasLayer
	elif get_parent() and get_parent().has_node("CanvasLayer"):
		canvas = get_parent().get_node("CanvasLayer") as CanvasLayer
	
	if not canvas:
		canvas = CanvasLayer.new()
		canvas.name = "SinkingCanvasLayer"
		canvas.layer = 55
		add_child(canvas)

	if not _red_overlay:
		if canvas.has_node("RedOverlay"):
			_red_overlay = canvas.get_node("RedOverlay") as ColorRect
		else:
			_red_overlay = ColorRect.new()
			_red_overlay.name = "RedOverlay"
			_red_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			_red_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_red_overlay.color = Color(1.0, 0.0, 0.0, 0.0)
			canvas.add_child(_red_overlay)

	if not _fade_overlay:
		if canvas.has_node("FadeOverlay"):
			_fade_overlay = canvas.get_node("FadeOverlay") as ColorRect
		else:
			_fade_overlay = ColorRect.new()
			_fade_overlay.name = "FadeOverlay"
			_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
			canvas.add_child(_fade_overlay)

## Blue water layer that rises from the bottom of the screen while the ship sinks.
func _ensure_flood_overlay() -> void:
	if _flood_overlay or not is_inside_tree():
		return
	var canvas: Node = _red_overlay.get_parent() if _red_overlay else null
	if canvas == null:
		return
	_flood_overlay = ColorRect.new()
	_flood_overlay.name = "FloodOverlay"
	_flood_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flood_overlay.color = Color(0.06, 0.26, 0.52, 0.55)
	_flood_overlay.anchor_left = 0.0
	_flood_overlay.anchor_right = 1.0
	_flood_overlay.anchor_bottom = 1.0
	_flood_overlay.anchor_top = 1.0
	_flood_overlay.offset_left = 0.0
	_flood_overlay.offset_right = 0.0
	_flood_overlay.offset_top = 0.0
	_flood_overlay.offset_bottom = 0.0
	canvas.add_child(_flood_overlay)
	canvas.move_child(_flood_overlay, 0) # under the red hazard pulse and the fade

## 0..1 progress of the SINKING stage (1 once it has finished)
func _sinking_progress() -> float:
	if current_stage == CutsceneStage.NORMAL or current_stage == CutsceneStage.WARNING:
		return 0.0
	return clampf((elapsed_time - warning_duration) / maxf(sinking_duration, 0.01), 0.0, 1.0)

func _ensure_audio_players() -> void:
	if not _audio_player:
		if not audio_player_path.is_empty() and has_node(audio_player_path):
			_audio_player = get_node(audio_player_path) as AudioStreamPlayer
		elif is_inside_tree():
			_audio_player = AudioStreamPlayer.new()
			_audio_player.name = "AlarmAudio"
			_audio_player.bus = &"Master"
			add_child(_audio_player)

	if not _sfx_player:
		if not sfx_player_path.is_empty() and has_node(sfx_player_path):
			_sfx_player = get_node(sfx_player_path) as AudioStreamPlayer
		elif is_inside_tree():
			_sfx_player = AudioStreamPlayer.new()
			_sfx_player.name = "SinkingSFX"
			_sfx_player.bus = &"Master"
			add_child(_sfx_player)

	_setup_authentic_audio()

func _setup_authentic_audio() -> void:
	# Alarm / emergency shock siren cue (authentic SEB0011)
	if _audio_player and not _audio_player.stream:
		var siren_paths := [
			"res://assets/sound/SEB0011.WAV",
			"res://assets/sound/SEB0011.wav",
			"res://assets/sound/SEB0015.WAV",
			"res://assets/sound/SEB0015.wav"
		]
		for p in siren_paths:
			if ResourceLoader.exists(p):
				_audio_player.stream = load(p)
				break
				
	# Ship structural groaning / crash rumble / wave impact audio cue (authentic SEB0015)
	if _sfx_player and not _sfx_player.stream:
		var sinking_paths := [
			"res://assets/sound/SEB0015.WAV",
			"res://assets/sound/SEB0015.wav",
			"res://assets/sound/SEB0011.WAV",
			"res://assets/sound/SEB0011.wav"
		]
		for p in sinking_paths:
			if ResourceLoader.exists(p):
				_sfx_player.stream = load(p)
				break

## Triggers the sinking cutscene when the player concludes interaction with Captain Robinson
func trigger_after_captain_dialogue() -> void:
	trigger_cutscene("captain_dialogue")

## Triggers the sinking cutscene when the player inspects the cabin hatch or lower deck
func trigger_after_cabin_inspection() -> void:
	trigger_cutscene("cabin_inspection")

## Master trigger for the ship sinking cutscene
func trigger_cutscene(p_trigger_source: String = "manual") -> void:
	if current_stage != CutsceneStage.NORMAL:
		return
	_ensure_ui_overlays()
	_ensure_audio_players()
	
	trigger_reason = p_trigger_source
	current_stage = CutsceneStage.WARNING
	elapsed_time = 0.0
	trauma = 0.6
	_ensure_flood_overlay()
	if camera:
		_base_zoom = camera.zoom
	
	cutscene_started.emit(trigger_reason)
	stage_changed.emit("WARNING")
	play_siren()
	_broadcast_crew_shouts("WARNING")

func start_cutscene() -> void:
	trigger_cutscene("start_cutscene")

func fast_forward() -> void:
	if current_stage == CutsceneStage.NORMAL:
		trigger_cutscene("fast_forward")
	elapsed_time = warning_duration + sinking_duration + fade_duration
	_process_stages(0.0)

func accelerate(multiplier: float = 10.0) -> void:
	time_scale = multiplier

func _process(delta: float) -> void:
	if current_stage == CutsceneStage.NORMAL:
		return
		
	var scaled_delta: float = delta * time_scale
	elapsed_time += scaled_delta
	
	_process_stages(scaled_delta)
	_process_visuals(scaled_delta)

func _process_stages(scaled_delta: float) -> void:
	var sinking_threshold: float = warning_duration
	var fade_threshold: float = warning_duration + sinking_duration
	var awaken_threshold: float = warning_duration + sinking_duration + fade_duration
	
	# Stage transitions
	if elapsed_time >= awaken_threshold and current_stage != CutsceneStage.AWAKENED:
		current_stage = CutsceneStage.AWAKENED
		stage_changed.emit("AWAKENED")
		fade_to_beach()
		stop_all_audio()
		reset_visuals()
		cutscene_finished.emit()
		transition_to_beach.emit(beach_scene_path)
	elif elapsed_time >= fade_threshold and current_stage != CutsceneStage.FADED and current_stage != CutsceneStage.AWAKENED:
		current_stage = CutsceneStage.FADED
		stage_changed.emit("FADED")
		start_fade_to_black(fade_duration)
	elif elapsed_time >= sinking_threshold and current_stage == CutsceneStage.WARNING:
		current_stage = CutsceneStage.SINKING
		stage_changed.emit("SINKING")
		trauma = 1.0 # Climax shock tremor
		play_sinking_audio()
		_broadcast_crew_shouts("SINKING")

func _process_visuals(scaled_delta: float) -> void:
	# Update decaying trauma camera shake and ship tilt
	if trauma > 0.0 or ship_tilt_angle > 0.0 or current_stage == CutsceneStage.SINKING:
		if trauma > 0.0:
			trauma = maxf(0.0, trauma - scaled_delta * 0.4)
		apply_shake(scaled_delta)
	elif current_stage == CutsceneStage.FADED or current_stage == CutsceneStage.AWAKENED:
		if camera:
			camera.offset = Vector2.ZERO
			camera.rotation = 0.0
		
	# Update red emergency hazard lighting pulse
	if current_stage == CutsceneStage.WARNING or current_stage == CutsceneStage.SINKING:
		if red_overlay:
			var speed: float = 6.0 if current_stage == CutsceneStage.WARNING else 9.0
			var max_alpha: float = 0.45 if current_stage == CutsceneStage.WARNING else 0.65
			var pulse: float = (sin(elapsed_time * speed) + 1.0) * 0.5 * max_alpha
			red_overlay.color = Color(1.0, 0.05, 0.05, pulse)
	elif red_overlay and red_overlay.color.a > 0.0:
		red_overlay.color = Color(1.0, 0.0, 0.0, 0.0)

func apply_shake(_delta: float) -> void:
	# Progressive ship tilt: lists to starboard as the hull floods, easing in
	if current_stage == CutsceneStage.SINKING:
		var progress: float = _sinking_progress()
		var eased: float = progress * progress * (3.0 - 2.0 * progress)
		ship_tilt_angle = maxf(ship_tilt_angle, MAX_SHIP_TILT * eased)
		if _flood_overlay:
			_flood_overlay.anchor_top = 1.0 - MAX_FLOOD_FRACTION * pow(progress, 1.4)
		if camera:
			camera.zoom = _base_zoom * (1.0 + MAX_SINKING_ZOOM * eased)
	else:
		ship_tilt_angle = maxf(0.0, ship_tilt_angle - _delta * 0.02)

	if not camera:
		return
	var shake: float = trauma * trauma
	noise_y += 1.0
	
	# 2D translational shake offset
	camera.offset = Vector2(
		max_offset.x * shake * noise.get_noise_2d(noise_y, 0.0),
		max_offset.y * shake * noise.get_noise_2d(0.0, noise_y)
	)
	camera.rotation = (max_roll * shake * noise.get_noise_2d(noise_y, 50.0)) + ship_tilt_angle

func reset_visuals() -> void:
	trauma = 0.0
	ship_tilt_angle = 0.0
	if _flood_overlay:
		_flood_overlay.anchor_top = 1.0
	if camera:
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0
		camera.zoom = _base_zoom
	if red_overlay:
		red_overlay.color = Color(1.0, 0.0, 0.0, 0.0)

func play_siren() -> void:
	if audio_player and audio_player.stream and audio_player.is_inside_tree():
		if not audio_player.playing:
			audio_player.play()

func play_sinking_audio() -> void:
	if sfx_player and sfx_player.stream and sfx_player.is_inside_tree():
		if not sfx_player.playing:
			sfx_player.play()

func stop_all_audio() -> void:
	if _audio_player and _audio_player.playing:
		_audio_player.stop()
	if _sfx_player and _sfx_player.playing:
		_sfx_player.stop()

func start_fade_to_black(duration: float = 2.0) -> void:
	if fade_overlay:
		var tween: Tween = create_tween()
		if tween:
			tween.tween_property(fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), duration)
		else:
			fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)

func fade_to_beach(duration: float = 1.5) -> void:
	if fade_overlay:
		var tween: Tween = create_tween()
		if tween:
			tween.tween_property(fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), duration)
		else:
			fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

## Triggers authentic overhead speech bubbles and shock emotions on Captain Robinson and crew members
func _broadcast_crew_shouts(stage_name: String) -> void:
	var hud: Control = null
	if get_parent():
		hud = get_parent().get_node_or_null("HUD") as Control
		if not hud and "hud" in get_parent():
			hud = get_parent().hud as Control

	if hud and hud.has_method("add_chat_message"):
		if stage_name == "WARNING":
			hud.add_chat_message("Captain Robinson", "All passengers, brace yourselves! We have struck an iceberg!", "Local")
			hud.add_chat_message("Crew", "The hull is breached! Water is rushing into the hold!", "Local")
		elif stage_name == "SINKING":
			hud.add_chat_message("Captain Robinson", "Abandon ship! Head for the lifeboats immediately!", "Local")
			hud.add_chat_message("Crew", "The ship is going down! Jump into the sea!", "Local")

	var ents: Node = null
	if get_parent():
		ents = get_parent().get_node_or_null("Entities")
		if not ents and "entities" in get_parent():
			ents = get_parent().entities
	if not ents:
		return
	
	for child in ents.get_children():
		if not is_instance_valid(child):
			continue
		var n_id: int = child.npc_id if "npc_id" in child else 0
		var n_name: String = str(child.npc_name if "npc_name" in child else "").to_lower()
		var is_captain: bool = (n_id == 14003 or "captain" in n_name or "robinson" in n_name)
		var is_crew: bool = (n_id in [14001, 14002] or "crew" in n_name or "sailor" in n_name)
		
		if is_captain:
			if child.has_method("show_emotion"):
				child.show_emotion("shock", 2.0)
			if child.has_method("show_speech_bubble"):
				if stage_name == "WARNING":
					child.show_speech_bubble("All passengers, brace yourselves! We have struck an iceberg!", 3.5)
				elif stage_name == "SINKING":
					child.show_speech_bubble("Abandon ship! Head for the lifeboats immediately!", 3.5)
		elif is_crew:
			if child.has_method("show_emotion"):
				child.show_emotion("sweat", 2.0)
			if child.has_method("show_speech_bubble"):
				if stage_name == "WARNING":
					child.show_speech_bubble("The hull is breached! Water is rushing into the hold!", 3.5)
				elif stage_name == "SINKING":
					child.show_speech_bubble("The ship is going down! Jump into the sea!", 3.5)
