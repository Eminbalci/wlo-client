class_name BeachAwakeningController
extends MapView

## Controller for the authentic Wonderland Online Beach Awakening on Map 10011 (video seconds 241 - 320).
## Handles player washed ashore prone state, get-up animation sequence,
## Kelang NPC orientation & dialogue tree, ambient ocean wave effects, and environmental audio.

signal awakening_started
signal wakeup_animation_finished
signal dialogue_with_kelang_started
signal awakening_completed

@export var shoreline_spawn_pos: Vector2 = Vector2(1040.0, 2220.0)
@export var kelang_spawn_pos: Vector2 = Vector2(1088.0, 2186.0)
@export var ambient_wave_audio_path: NodePath = NodePath("AmbientWavesAudio")
@export var beach_bgm_audio_path: NodePath = NodePath("BeachBGM")
@export var fade_overlay_path: NodePath = NodePath("CanvasLayer/FadeOverlay")
@export var wave_effects_path: NodePath = NodePath("WaveEffects")

var _ambient_waves: AudioStreamPlayer = null
var ambient_waves: AudioStreamPlayer:
	get:
		if not _ambient_waves and not ambient_wave_audio_path.is_empty() and has_node(ambient_wave_audio_path):
			_ambient_waves = get_node(ambient_wave_audio_path)
		return _ambient_waves
	set(val):
		_ambient_waves = val

var _beach_bgm: AudioStreamPlayer = null
var beach_bgm: AudioStreamPlayer:
	get:
		if not _beach_bgm and not beach_bgm_audio_path.is_empty() and has_node(beach_bgm_audio_path):
			_beach_bgm = get_node(beach_bgm_audio_path)
		return _beach_bgm
	set(val):
		_beach_bgm = val

var _fade_overlay: ColorRect = null
var fade_overlay: ColorRect:
	get:
		if not _fade_overlay and not fade_overlay_path.is_empty() and has_node(fade_overlay_path):
			_fade_overlay = get_node(fade_overlay_path)
		return _fade_overlay
	set(val):
		_fade_overlay = val

var _wave_effects: Node2D = null
var wave_effects: Node2D:
	get:
		if not _wave_effects and not wave_effects_path.is_empty() and has_node(wave_effects_path):
			_wave_effects = get_node(wave_effects_path)
		return _wave_effects
	set(val):
		_wave_effects = val

var kelang_npc: NpcEntity:
	get:
		if not _kelang_npc:
			_ensure_kelang_npc()
		return _kelang_npc
	set(val):
		_kelang_npc = val
var _kelang_npc: NpcEntity = null

var is_awakening_active: bool = false
var _wave_timer: float = 0.0

func _ready() -> void:
	# 1. Enforce Map 10011 context
	var m_ren = map_renderer
	if m_ren:
		m_ren.current_map_id = 10011
		
	super._ready()
	
	_setup_ambient_audio()
	_setup_wave_fx()
	_setup_beach_awakening()

func _setup_ambient_audio() -> void:
	if ambient_waves and not ambient_waves.stream:
		var wave_candidates := [
			"res://assets/sound/SEB0037.wav",
			"res://assets/sound/SEB0037.WAV",
			"res://assets/sound/wav0056.wav",
			"res://assets/sound/Wav1608.wav",
			"res://assets/sound/Wav1610.wav"
		]
		for p in wave_candidates:
			if ResourceLoader.exists(p):
				var res = load(p)
				if res:
					ambient_waves.stream = res
					break
	if ambient_waves and ambient_waves.stream and not ambient_waves.playing:
		ambient_waves.play()

	if beach_bgm and not beach_bgm.stream:
		var bgm_candidates := [
			"res://assets/sound/BGM0024.wav",
			"res://assets/sound/BGM0012.wav",
			"res://assets/sound/BGM0003.wav"
		]
		for p in bgm_candidates:
			if ResourceLoader.exists(p):
				var res = load(p)
				if res:
					beach_bgm.stream = res
					break
	if beach_bgm and beach_bgm.stream and not beach_bgm.playing:
		beach_bgm.play()

func _setup_wave_fx() -> void:
	if not wave_effects and has_node(wave_effects_path):
		wave_effects = get_node(wave_effects_path)
	elif not wave_effects:
		wave_effects = Node2D.new()
		wave_effects.name = "WaveEffects"
		add_child(wave_effects)

func _setup_beach_awakening() -> void:
	is_awakening_active = true
	awakening_started.emit()
	
	# Configure player washed ashore at shoreline
	if player:
		if player.has_method("teleport_to"):
			player.teleport_to(shoreline_spawn_pos)
		else:
			player.world_position = shoreline_spawn_pos
			player.position = shoreline_spawn_pos
		
		# Put player in prone state with movement locked
		if player.has_method("set_prone"):
			player.set_prone(true)
		elif "is_movement_locked" in player:
			player.is_movement_locked = true
			
		_update_camera_to_player()
	
	# Setup Kelang NPC
	_ensure_kelang_npc()
	
	# Screen fade-in from black
	if fade_overlay:
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color", Color(0.0, 0.0, 0.0, 0.0), 2.5)
		tween.tween_callback(_on_fade_in_completed)
	else:
		_on_fade_in_completed()

func _ensure_kelang_npc() -> void:
	if _kelang_npc and is_instance_valid(_kelang_npc):
		return
	var ents = entities if entities else get_node_or_null("Entities")
	if ents:
		for child in ents.get_children():
			if child is NpcEntity and (child.npc_id == 14062 or "kelang" in child.npc_name.to_lower()):
				_kelang_npc = child
				return
	
	if not _kelang_npc and ents:
		var npc_scene = load("res://scenes/world/npc.tscn")
		if npc_scene:
			_kelang_npc = npc_scene.instantiate()
			_kelang_npc.name = "KelangNPC"
			_kelang_npc.npc_id = 14062
			_kelang_npc.npc_name = "Kelang"
			_kelang_npc.model_jmp = "1131.jmp"
			_kelang_npc.world_position = kelang_spawn_pos
			_kelang_npc.heading = IsometricMath.Heading.SOUTH_WEST # Facing player on beach
			_kelang_npc.dialogue_text = "This is a deserted island. How did you end up here?"
			_kelang_npc.dialogue_choices = ["I was on a ship...", "Where is this place?"]
			_kelang_npc.npc_interacted.connect(_on_npc_interacted)
			ents.add_child(_kelang_npc)

func _on_fade_in_completed() -> void:
	# Trigger get-up animation sequence
	if player and player.has_method("play_wakeup_animation"):
		player.play_wakeup_animation(2.5, _on_wakeup_completed)
	else:
		_on_wakeup_completed()

func _on_wakeup_completed() -> void:
	wakeup_animation_finished.emit()
	
	# Automatic dialogue initiation and overhead speech bubble with Kelang once player rises
	if kelang_npc:
		if kelang_npc.has_method("show_emotion"):
			kelang_npc.show_emotion("shock", 2.0)
		if kelang_npc.has_method("show_speech_bubble"):
			kelang_npc.show_speech_bubble("Hey! Are you okay? You washed ashore from the shipwreck.", 3.5)
		dialogue_with_kelang_started.emit()
		_on_npc_interacted(kelang_npc)
	else:
		_complete_awakening()

func _complete_awakening() -> void:
	is_awakening_active = false
	if player:
		if "is_movement_locked" in player:
			player.is_movement_locked = false
		if "is_prone" in player:
			player.is_prone = false
	awakening_completed.emit()

func _process(delta: float) -> void:
	super._process(delta)
	
	# Animate ambient ocean wave rhythm
	_wave_timer += delta
	if wave_effects:
		# Modulate subtle wave tide pulsation
		var wave_alpha: float = (sin(_wave_timer * 1.5) + 1.0) * 0.2 + 0.3
		wave_effects.modulate = Color(1.0, 1.0, 1.0, wave_alpha)
