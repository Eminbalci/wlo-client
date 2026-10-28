class_name LoadingScreen
extends Control

## Authentic Wonderland Online loading screen shown between scene transitions.
## Decoded from aLogin.exe: full-window artwork (Anim_load0/1), a 4-frame
## "NOW LOADING" strip (LoadingPic, 291x104), a 275x10 progress bar
## (LoadingBarB back plate + LoadingBarF fill) and the 3-frame "Busy" bubble
## (Waiteven, 32px frames) that advances every 500 ms.
##
## Usage: LoadingScreen.go_to(get_tree(), "res://scenes/world/map_view.tscn")

const SCENE_PATH: String = "res://scenes/ui/loading_screen.tscn"
const BACKGROUNDS: Array[String] = [
	"res://assets/loading/anim_load0.png",
	"res://assets/loading/anim_load1.png",
]
const LOADING_PIC_PATH: String = "res://assets/loading/loading_pic.png"
const BAR_BACK_PATH: String = "res://assets/loading/loading_bar_back.png"
const BAR_FILL_PATH: String = "res://assets/loading/loading_bar_fill.png"
const WAIT_PATH: String = "res://assets/loading/waiteven.png"

const LOADING_FRAME_SIZE: Vector2 = Vector2(291, 26)
const LOADING_FRAME_COUNT: int = 4
const LOADING_FRAME_TIME: float = 0.2
const BAR_SIZE: Vector2 = Vector2(275, 10)
const WAIT_FRAME_SIZE: Vector2 = Vector2(32, 32)
const WAIT_FRAME_COUNT: int = 3
const WAIT_FRAME_TIME: float = 0.5
const MIN_DISPLAY_TIME: float = 0.9
const BOTTOM_MARGIN: float = 70.0

signal finished(scene_path: String)

static var target_scene: String = ""
static var background_index: int = 0

var progress: float = 0.0
var displayed_progress: float = 0.0
var elapsed: float = 0.0
var is_done: bool = false
var auto_change_scene: bool = true

var _background: TextureRect
var _loading_sprite: TextureRect
var _loading_atlas: AtlasTexture
var _bar_back: TextureRect
var _bar_clip: Control
var _bar_fill: TextureRect
var _wait_sprite: TextureRect
var _wait_atlas: AtlasTexture
var _percent_label: Label
var _loading_frame: int = 0
var _loading_timer: float = 0.0
var _wait_frame: int = 0
var _wait_timer: float = 0.0
var _requested: bool = false


static func go_to(tree: SceneTree, scene_path: String) -> void:
	target_scene = scene_path
	background_index = (background_index + 1) % BACKGROUNDS.size()
	tree.change_scene_to_file.call_deferred(SCENE_PATH)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_layout()
	resized.connect(_layout)
	_set_cursor("busy")
	_start_request()


func _build_ui() -> void:
	_background = TextureRect.new()
	_background.name = "Background"
	_background.texture = load(BACKGROUNDS[background_index % BACKGROUNDS.size()])
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	_loading_atlas = AtlasTexture.new()
	_loading_atlas.atlas = load(LOADING_PIC_PATH)
	_loading_atlas.region = Rect2(Vector2.ZERO, LOADING_FRAME_SIZE)
	_loading_sprite = TextureRect.new()
	_loading_sprite.name = "NowLoading"
	_loading_sprite.texture = _loading_atlas
	_loading_sprite.custom_minimum_size = LOADING_FRAME_SIZE
	_loading_sprite.size = LOADING_FRAME_SIZE
	_loading_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loading_sprite)

	_bar_back = TextureRect.new()
	_bar_back.name = "BarBack"
	_bar_back.texture = load(BAR_BACK_PATH)
	_bar_back.size = BAR_SIZE
	_bar_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar_back)

	_bar_clip = Control.new()
	_bar_clip.name = "BarClip"
	_bar_clip.clip_contents = true
	_bar_clip.size = Vector2(0, BAR_SIZE.y)
	_bar_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_back.add_child(_bar_clip)

	_bar_fill = TextureRect.new()
	_bar_fill.name = "BarFill"
	_bar_fill.texture = load(BAR_FILL_PATH)
	_bar_fill.size = BAR_SIZE
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar_clip.add_child(_bar_fill)

	_percent_label = Label.new()
	_percent_label.name = "Percent"
	_percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_percent_label.add_theme_color_override("font_color", Color.WHITE)
	_percent_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.3))
	_percent_label.add_theme_constant_override("outline_size", 4)
	_percent_label.size = Vector2(BAR_SIZE.x, 20)
	_percent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_percent_label)

	_wait_atlas = AtlasTexture.new()
	_wait_atlas.atlas = load(WAIT_PATH)
	_wait_atlas.region = Rect2(Vector2.ZERO, WAIT_FRAME_SIZE)
	_wait_sprite = TextureRect.new()
	_wait_sprite.name = "Busy"
	_wait_sprite.texture = _wait_atlas
	_wait_sprite.size = WAIT_FRAME_SIZE
	_wait_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wait_sprite)


func _layout() -> void:
	var win: Vector2 = size
	_background.position = Vector2.ZERO
	_background.size = win
	var center_x: float = win.x * 0.5
	var bar_y: float = win.y - BOTTOM_MARGIN
	_bar_back.position = Vector2(center_x - BAR_SIZE.x * 0.5, bar_y)
	_loading_sprite.position = Vector2(center_x - LOADING_FRAME_SIZE.x * 0.5, bar_y - LOADING_FRAME_SIZE.y - 10.0)
	_percent_label.position = Vector2(center_x - BAR_SIZE.x * 0.5, bar_y + BAR_SIZE.y + 4.0)
	_wait_sprite.position = Vector2(_bar_back.position.x + BAR_SIZE.x + 12.0, bar_y - 10.0)


func _start_request() -> void:
	if target_scene == "" or not ResourceLoader.exists(target_scene):
		push_warning("[LoadingScreen] Target scene missing: '%s'" % target_scene)
		return
	_requested = ResourceLoader.load_threaded_request(target_scene) == OK


func _process(delta: float) -> void:
	elapsed += delta
	_animate(delta)
	if is_done:
		return
	_poll_load()
	displayed_progress = move_toward(displayed_progress, progress, delta * 1.5)
	_apply_progress()
	if displayed_progress >= 1.0 and elapsed >= MIN_DISPLAY_TIME:
		_finish()


func _animate(delta: float) -> void:
	_loading_timer += delta
	if _loading_timer >= LOADING_FRAME_TIME:
		_loading_timer = 0.0
		_loading_frame = (_loading_frame + 1) % LOADING_FRAME_COUNT
		_loading_atlas.region = Rect2(Vector2(0, _loading_frame * LOADING_FRAME_SIZE.y), LOADING_FRAME_SIZE)
	_wait_timer += delta
	if _wait_timer >= WAIT_FRAME_TIME:
		_wait_timer = 0.0
		_wait_frame = (_wait_frame + 1) % WAIT_FRAME_COUNT
		_wait_atlas.region = Rect2(Vector2(0, _wait_frame * WAIT_FRAME_SIZE.y), WAIT_FRAME_SIZE)


func _poll_load() -> void:
	if not _requested:
		progress = 1.0
		return
	var info: Array = []
	var status := ResourceLoader.load_threaded_get_status(target_scene, info)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not info.is_empty():
				progress = clampf(float(info[0]), 0.0, 0.99)
		ResourceLoader.THREAD_LOAD_LOADED:
			progress = 1.0
		_:
			push_warning("[LoadingScreen] Failed to load '%s'" % target_scene)
			progress = 1.0
			_requested = false


func _apply_progress() -> void:
	_bar_clip.size = Vector2(roundf(BAR_SIZE.x * displayed_progress), BAR_SIZE.y)
	_percent_label.text = "%d%%" % int(displayed_progress * 100.0)


func _set_cursor(cursor_name: String) -> void:
	var cursor_manager := get_node_or_null("/root/CursorManager")
	if cursor_manager and cursor_manager.has_method("set_cursor_by_name"):
		cursor_manager.set_cursor_by_name(cursor_name)

func _finish() -> void:
	_set_cursor("normal")
	is_done = true
	finished.emit(target_scene)
	if not auto_change_scene:
		return
	var packed: PackedScene = null
	if _requested:
		packed = ResourceLoader.load_threaded_get(target_scene) as PackedScene
	if packed == null and target_scene != "" and ResourceLoader.exists(target_scene):
		packed = load(target_scene) as PackedScene
	if packed != null and is_inside_tree():
		get_tree().change_scene_to_packed.call_deferred(packed)
