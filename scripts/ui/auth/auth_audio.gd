extends Node

## Authentic UI Audio Helper and Player for Wonderland Online Auth and Character Creation.
## Provides safe, zero-warning playback of authentic UI sound effects:
## - res://assets/sound/wav0151.wav: standard UI button click, tab click, arrow turn, slider nudge, element selection, confirmation.
## - res://assets/sound/SEB0024.WAV: error/alert sound for empty name or invalid input.
##
## Features an AudioStreamPlayer pool (POOL_SIZE = 8) to prevent clipping and ensure graceful overlapping.

const SFX_CLICK_PATH: String = "res://assets/sound/wav0151.wav"
const SFX_ERROR_PATH: String = "res://assets/sound/SEB0024.WAV"
const POOL_SIZE: int = 8

static var _instance: Node = null

var _click_stream: AudioStream = null
var _error_stream: AudioStream = null
var _stream_cache: Dictionary = {}

var _player_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

func _init() -> void:
	_init_pool()
	_preload_streams()

func _ready() -> void:
	if _instance == null:
		_instance = self
	if _player_pool.is_empty():
		_init_pool()

func _init_pool() -> void:
	if not _player_pool.is_empty():
		return
	if AudioServer.get_bus_index("SFX") == -1:
		var sys_win = load("res://scripts/ui/hud/system_window.gd")
		if sys_win and sys_win.has_method("ensure_audio_buses"):
			sys_win.ensure_audio_buses()
	var sfx_bus: StringName = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "AuthSFXPlayer_%d" % i
		p.bus = sfx_bus
		add_child(p)
		_player_pool.append(p)

func _preload_streams() -> void:
	_click_stream = _load_audio_stream(SFX_CLICK_PATH)
	_error_stream = _load_audio_stream(SFX_ERROR_PATH)

func _load_audio_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path] as AudioStream

	if not ResourceLoader.exists(path):
		return null

	var stream = load(path) as AudioStream
	if stream:
		_stream_cache[path] = stream
	return stream

func _get_available_player() -> AudioStreamPlayer:
	if _player_pool.is_empty():
		_init_pool()

	for player in _player_pool:
		if is_instance_valid(player) and player.is_inside_tree() and not player.playing:
			return player

	# If all players are busy, round-robin to avoid dropping sound events
	if not _player_pool.is_empty():
		_pool_index = (_pool_index + 1) % _player_pool.size()
		var p = _player_pool[_pool_index]
		if is_instance_valid(p) and p.is_inside_tree():
			return p

	if is_inside_tree():
		var fallback_player := AudioStreamPlayer.new()
		add_child(fallback_player)
		_player_pool.append(fallback_player)
		return fallback_player
	return null

## Plays the authentic standard UI click sound (wav0151.wav)
func play_ui_click(volume_db: float = 0.0) -> void:
	if _click_stream == null:
		_click_stream = _load_audio_stream(SFX_CLICK_PATH)
	play_stream(_click_stream, volume_db)

## Plays the authentic UI alert / error sound (SEB0024.WAV)
func play_ui_error(volume_db: float = 0.0) -> void:
	if _error_stream == null:
		_error_stream = _load_audio_stream(SFX_ERROR_PATH)
	play_stream(_error_stream, volume_db)

## Plays a custom sound path safely from the sound library
func play_custom_sfx(path: String, volume_db: float = 0.0) -> void:
	var stream := _load_audio_stream(path)
	if stream:
		play_stream(stream, volume_db)

## Plays an AudioStream on the player pool with zero clipping and graceful overlap
func play_stream(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null or not is_inside_tree():
		return
	var player := _get_available_player()
	if player and player.is_inside_tree():
		player.stream = stream
		player.volume_db = volume_db
		player.play()

# ==================== STATIC CONVENIENCE APIS ====================

## Retrieves or lazily instantiates the active AuthAudio singleton on the SceneTree
static func get_instance() -> Node:
	if is_instance_valid(_instance) and _instance.is_inside_tree():
		return _instance

	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var root = (main_loop as SceneTree).root
		if root:
			var existing = root.get_node_or_null("AuthAudio")
			if existing:
				_instance = existing
				return _instance
			if _instance == null or not is_instance_valid(_instance):
				var script_res = load("res://scripts/ui/auth/auth_audio.gd")
				_instance = script_res.new()
				_instance.name = "AuthAudio"
			if not _instance.is_inside_tree():
				root.add_child.call_deferred(_instance)
			return _instance
	return null

## Static helper to play the standard UI button/tab/turn click sound
static func play_click(volume_db: float = 0.0) -> void:
	var inst := get_instance()
	if inst and inst.has_method("play_ui_click"):
		inst.play_ui_click(volume_db)

## Static helper to play the error/alert sound
static func play_error(volume_db: float = 0.0) -> void:
	var inst := get_instance()
	if inst and inst.has_method("play_ui_error"):
		inst.play_ui_error(volume_db)

## Static helper to play an arbitrary sound stream path
static func play_sfx(stream_path: String, volume_db: float = 0.0) -> void:
	var inst := get_instance()
	if inst and inst.has_method("play_custom_sfx"):
		inst.play_custom_sfx(stream_path, volume_db)
