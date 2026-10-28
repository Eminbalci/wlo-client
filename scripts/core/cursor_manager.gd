extends Node

## Global Animated Cursor Manager for Wonderland Online
## Manages continuous hardware/software mouse cursor animation (10 FPS)
## and dynamic contextual cursor switching (Normal, Attack, Talk, Harvest, Portal).

enum CursorType {
	NORMAL,   # cursor1.ani  (8 frames) - crystal arrow pointer
	ATTACK,   # cursor3.ani  (6 frames) - sword
	TALK,     # cursor4.ani  (1 frame)  - pointing hand over NPCs
	HARVEST,  # cursor8.ani  (2 frames) - grabbing hand over ground items / gathering spots
	EXAMINE,  # cursor17.ani (1 frame)  - magnifying glass
	PORTAL,   # cursor6.ani  (6 frames) - teleport sparkle over warps / doors
	MINING,   # cursor12.ani (1 frame)  - hammer
	SHOP,     # cursor18.ani (4 frames) - hand holding a gem over merchants
	SKILL,    # cursor15.ani (4 frames) - crosshair while aiming a skill
	QUEST,    # cursor16.ani (1 frame)  - hand over NPCs a quest is waiting on
	BUSY,     # cursor10.ani (8 frames) - hourglass while loading
	TARGET,   # cursor11.ani (6 frames) - sword with red arrow over valid battle targets
}

## The Main.exe binary does not name its cursors, so these roles come from the artwork of
## assets/cursor/cursorN.ani (cursor2 is an alternate pointer, cursor9 a mushroom creature,
## cursor13/14 hammer variants and cursor99 a blank cursor; none of those is used).

const FRAME_INTERVAL: float = 0.1 # 10 FPS (matching cursor1.ani jif_rate 10)

var _type_to_ani: Dictionary = {
	CursorType.NORMAL: "cursor1",
	CursorType.ATTACK: "cursor3",
	CursorType.TALK: "cursor4",
	CursorType.HARVEST: "cursor8",
	CursorType.EXAMINE: "cursor17",
	CursorType.PORTAL: "cursor6",
	CursorType.MINING: "cursor12",
	CursorType.SHOP: "cursor18",
	CursorType.SKILL: "cursor15",
	CursorType.QUEST: "cursor16",
	CursorType.BUSY: "cursor10",
	CursorType.TARGET: "cursor11",
}

## Click point of each cursor image (32x32): fingertips / sword tips at the top-left, centred
## for round cursors.
var _hotspot_map: Dictionary = {
	CursorType.NORMAL: Vector2(0, 0),
	CursorType.ATTACK: Vector2(2, 2),
	CursorType.TALK: Vector2(6, 3),
	CursorType.HARVEST: Vector2(12, 10),
	CursorType.EXAMINE: Vector2(12, 12),
	CursorType.PORTAL: Vector2(2, 2),
	CursorType.MINING: Vector2(4, 4),
	CursorType.SHOP: Vector2(12, 12),
	CursorType.SKILL: Vector2(16, 16),
	CursorType.QUEST: Vector2(6, 3),
	CursorType.BUSY: Vector2(16, 16),
	CursorType.TARGET: Vector2(2, 2),
}

var _cursor_cache: Dictionary = {} # CursorType -> Array[ImageTexture]
var _current_type: CursorType = CursorType.NORMAL
var _current_frames: Array[ImageTexture] = []
var _frame_index: int = 0
var _anim_timer: float = 0.0
var _is_active: bool = true

func _ready() -> void:
	# Ensure loader preloads default cursor
	_preload_cursors()
	set_cursor_state(CursorType.NORMAL)

func _preload_cursors() -> void:
	var loader = get_node_or_null("/root/ArchiveLoader")
	if not loader:
		return
	for c_type in [CursorType.NORMAL, CursorType.ATTACK, CursorType.TALK, CursorType.HARVEST, CursorType.PORTAL, CursorType.SHOP, CursorType.QUEST]:
		var ani_name: String = _type_to_ani.get(c_type, "cursor1")
		var frames: Array[ImageTexture] = loader.get_cursor_frames(ani_name)
		if not frames.is_empty():
			_cursor_cache[c_type] = frames

func _process(delta: float) -> void:
	if not _is_active or _current_frames.is_empty():
		return
	
	if _current_frames.size() <= 1:
		return
	
	_anim_timer += delta
	if _anim_timer >= FRAME_INTERVAL:
		while _anim_timer >= FRAME_INTERVAL:
			_anim_timer -= FRAME_INTERVAL
			_frame_index = (_frame_index + 1) % _current_frames.size()
		_apply_cursor_frame(_frame_index)

## Sets the active cursor state by enum type
func set_cursor_state(new_type: CursorType) -> void:
	if new_type == _current_type and not _current_frames.is_empty():
		return
	
	_current_type = new_type
	_current_frames = _get_or_load_frames(new_type)
	_frame_index = 0
	_anim_timer = 0.0
	
	if not _current_frames.is_empty():
		_apply_cursor_frame(0)

## Sets the active cursor state by string name (e.g. "normal", "talk", "portal", "harvest", "attack")
func set_cursor_by_name(cursor_name: String) -> void:
	var low := cursor_name.to_lower().strip_edges()
	match low:
		"talk", "npc", "dialogue", "cursor4":
			set_cursor_state(CursorType.TALK)
		"portal", "door", "warp", "cursor6":
			set_cursor_state(CursorType.PORTAL)
		"harvest", "pickup", "hand", "cursor8":
			set_cursor_state(CursorType.HARVEST)
		"attack", "combat", "fight", "sword", "cursor3":
			set_cursor_state(CursorType.ATTACK)
		"mining", "mine", "cursor12":
			set_cursor_state(CursorType.MINING)
		"busy", "wait", "loading", "cursor10":
			set_cursor_state(CursorType.BUSY)
		"target", "cursor11":
			set_cursor_state(CursorType.TARGET)
		"examine", "look", "inspect", "cursor17":
			set_cursor_state(CursorType.EXAMINE)
		"skill", "aim", "cursor15":
			set_cursor_state(CursorType.SKILL)
		"quest", "cursor16":
			set_cursor_state(CursorType.QUEST)
		"shop", "trade", "merchant", "cursor18":
			set_cursor_state(CursorType.SHOP)
		_:
			set_cursor_state(CursorType.NORMAL)

## Resets cursor back to standard animated pointer
func reset_to_default() -> void:
	set_cursor_state(CursorType.NORMAL)

## Returns the current active cursor type
func get_cursor_state() -> CursorType:
	return _current_type

## Returns the currently loaded animation frames
func get_active_frames() -> Array[ImageTexture]:
	return _current_frames

## Returns the current animation frame index
func get_current_frame_index() -> int:
	return _frame_index

func _get_or_load_frames(c_type: CursorType) -> Array[ImageTexture]:
	if _cursor_cache.has(c_type) and not _cursor_cache[c_type].is_empty():
		return _cursor_cache[c_type]
	
	var loader = get_node_or_null("/root/ArchiveLoader")
	if not loader:
		loader = preload("res://scripts/core/archive_loader.gd").new()
	
	var ani_name: String = _type_to_ani.get(c_type, "cursor1")
	var frames: Array[ImageTexture] = loader.get_cursor_frames(ani_name)
	if not frames.is_empty():
		_cursor_cache[c_type] = frames
		return frames
	
	# Fallback to cursor1 if specific cursor not found
	if _cursor_cache.has(CursorType.NORMAL):
		return _cursor_cache[CursorType.NORMAL]
	return []

## Control shapes that must show the game cursor. Many buttons use CURSOR_POINTING_HAND and
## drag-and-drop uses CURSOR_DRAG / CURSOR_CAN_DROP; overriding only CURSOR_ARROW made the operating
## system's hand appear over every button and while dragging items or skills.
const GAME_CURSOR_SHAPES: Array[Input.CursorShape] = [
	Input.CURSOR_ARROW,
	Input.CURSOR_POINTING_HAND,
	Input.CURSOR_DRAG,
	Input.CURSOR_CAN_DROP,
]

func _apply_cursor_frame(idx: int) -> void:
	if idx < 0 or idx >= _current_frames.size():
		return
	var tex: ImageTexture = _current_frames[idx]
	var hotspot: Vector2 = _hotspot_map.get(_current_type, Vector2(0, 0))
	for shape in GAME_CURSOR_SHAPES:
		Input.set_custom_mouse_cursor(tex, shape, hotspot)
