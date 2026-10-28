class_name MapEditor
extends Control

## Wonderland Online Map Creation & Collision / Portal Editor Tool.
## Provides visual background loading, 20px axonometric/isometric tile collision painting,
## warp portal & trigger placement, ground item spawn configuration, NPC placement/dragging,
## and multi-format exports (.MapData binary, .json, and Godot 4 .tscn scenes).

const MapData = preload("res://scripts/map/map_data.gd")
const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const EveParser = preload("res://scripts/map/eve_parser.gd")
const GroundParser = preload("res://scripts/map/ground_parser.gd")

enum ToolMode {
	SELECT = 0,
	PAINT = 1,
	ERASER = 2,
	RECT_FILL = 3,
	FLOOD_FILL = 4,
	PLACE_PORTAL = 5,
	PLACE_ITEM = 6,
	PLACE_NPC = 7,
	PAN = 8
}

const FLAG_COLORS: Dictionary = {
	MapData.TileCollisionFlags.WALKABLE: Color(0.1, 0.85, 0.25, 0.25),
	MapData.TileCollisionFlags.SOLID_WALL: Color(0.95, 0.15, 0.15, 0.45),
	MapData.TileCollisionFlags.SEA: Color(0.15, 0.45, 0.95, 0.45),
	MapData.TileCollisionFlags.DEEP_OCEAN: Color(0.05, 0.15, 0.55, 0.55),
	MapData.TileCollisionFlags.WATER: Color(0.15, 0.85, 0.95, 0.45),
	MapData.TileCollisionFlags.MOUNTAIN: Color(0.65, 0.4, 0.15, 0.55),
	MapData.TileCollisionFlags.SHALLOW_WATER: Color(0.25, 0.9, 0.75, 0.4),
	MapData.TileCollisionFlags.HOT_SPRING: Color(0.75, 0.2, 0.85, 0.5)
}

const FLAG_NAMES: Dictionary = {
	MapData.TileCollisionFlags.WALKABLE: "Walkable (0x00)",
	MapData.TileCollisionFlags.SOLID_WALL: "Solid Wall (0x01)",
	MapData.TileCollisionFlags.SEA: "Sea (0x02)",
	MapData.TileCollisionFlags.DEEP_OCEAN: "Deep Ocean (0x04)",
	MapData.TileCollisionFlags.WATER: "Water (0x08)",
	MapData.TileCollisionFlags.MOUNTAIN: "Mountain (0x10)",
	MapData.TileCollisionFlags.SHALLOW_WATER: "Shallow Water (0x40)",
	MapData.TileCollisionFlags.HOT_SPRING: "Hot Spring (0x80)"
}

class PortalEntry:
	var portal_id: int = 1
	var portal_name: String = "Portal"
	var world_position: Vector2 = Vector2.ZERO
	var target_map_id: int = 10002
	var target_coords: Vector2 = Vector2(500, 500)
	var trigger_radius: float = 56.0
	var portal_color: Color = Color(0.2, 0.75, 1.0, 0.85)

	func to_dict() -> Dictionary:
		return {
			"portal_id": portal_id,
			"portal_name": portal_name,
			"world_x": world_position.x,
			"world_y": world_position.y,
			"target_map_id": target_map_id,
			"target_coords": {"x": target_coords.x, "y": target_coords.y},
			"trigger_radius": trigger_radius,
			"portal_color": portal_color.to_html()
		}

	func from_dict(d: Dictionary) -> void:
		portal_id = int(d.get("portal_id", 1))
		portal_name = str(d.get("portal_name", "Portal"))
		world_position = Vector2(float(d.get("world_x", 0.0)), float(d.get("world_y", 0.0)))
		target_map_id = int(d.get("target_map_id", 10002))
		var tc: Variant = d.get("target_coords", {})
		if tc is Dictionary:
			target_coords = Vector2(float(tc.get("x", 500.0)), float(tc.get("y", 500.0)))
		elif tc is Vector2:
			target_coords = tc
		trigger_radius = float(d.get("trigger_radius", 56.0))
		if d.has("portal_color"):
			portal_color = Color.from_string(str(d.get("portal_color")), Color(0.2, 0.75, 1.0, 0.85))

class GroundItemEntry:
	var item_id: int = 46113
	var item_name: String = "Shell"
	var world_position: Vector2 = Vector2.ZERO
	var slot: int = 1
	var respawn_seconds: float = 120.0

	func to_dict() -> Dictionary:
		return {
			"item_id": item_id,
			"item_name": item_name,
			"world_x": world_position.x,
			"world_y": world_position.y,
			"slot": slot,
			"respawn_seconds": respawn_seconds
		}

	func from_dict(d: Dictionary) -> void:
		item_id = int(d.get("item_id", 0))
		item_name = str(d.get("item_name", ""))
		world_position = Vector2(float(d.get("world_x", 0.0)), float(d.get("world_y", 0.0)))
		slot = int(d.get("slot", 1))
		respawn_seconds = float(d.get("respawn_seconds", 120.0))

class NpcEntry:
	var click_id: int = 0
	var template_id: int = 14001
	var npc_id: int = 14001
	var npc_name: String = "NPC"
	var world_position: Vector2 = Vector2.ZERO
	var model_jmp: String = "1037.jmp"
	var model_jma: String = "001.jma"
	var heading: int = IsometricMath.Heading.SOUTH
	var rotation: int = 5
	var dialogue_text: String = "Hello traveler!"
	var dialogue_choices: Array[String] = ["Greetings"]

	func to_dict() -> Dictionary:
		return {
			"click_id": click_id,
			"template_id": template_id,
			"npc_id": npc_id,
			"npc_name": npc_name,
			"world_x": world_position.x,
			"world_y": world_position.y,
			"model_jmp": model_jmp,
			"model_jma": model_jma,
			"heading": heading,
			"rotation": rotation,
			"dialogue_text": dialogue_text,
			"dialogue_choices": dialogue_choices
		}

	func from_dict(d: Dictionary) -> void:
		click_id = int(d.get("click_id", 0))
		npc_id = int(d.get("npc_id", 0))
		template_id = int(d.get("template_id", npc_id))
		npc_name = str(d.get("npc_name", "NPC"))
		world_position = Vector2(float(d.get("world_x", 0.0)), float(d.get("world_y", 0.0)))
		model_jmp = str(d.get("model_jmp", ""))
		model_jma = str(d.get("model_jma", "001.jma"))
		heading = int(d.get("heading", IsometricMath.Heading.SOUTH))
		rotation = int(d.get("rotation", 5))
		dialogue_text = str(d.get("dialogue_text", ""))
		var raw_choices: Variant = d.get("dialogue_choices", [])
		dialogue_choices.clear()
		if raw_choices is Array:
			for c in raw_choices:
				dialogue_choices.append(str(c))

# --- Project State ---
var map_id: int = 10001
var map_name: String = "Ship Deck"
var background_path: String = ""
var background_texture: Texture2D = null
var width_px: int = 2084
var height_px: int = 2400
var cols: int = 105
var rows: int = 120
var tile_scale: int = MapData.TILE_SCALE
var collision_grid: PackedByteArray = PackedByteArray()
var portals: Array[PortalEntry] = []
var ground_items: Array[GroundItemEntry] = []
var npcs: Array[NpcEntry] = []
var player_spawn_pos: Vector2 = Vector2(1040, 1070)

# --- Viewport & Interaction State ---
var zoom_level: float = 0.5
var pan_offset: Vector2 = Vector2(100, 50)
var is_panning: bool = false
var is_painting: bool = false
var is_rect_filling: bool = false
var rect_fill_start_grid: Vector2i = Vector2i(-1, -1)
var hover_screen_pos: Vector2 = Vector2.ZERO
var hover_world_pos: Vector2 = Vector2.ZERO
var hover_grid_pos: Vector2i = Vector2i.ZERO
var is_mouse_over_canvas: bool = false

# --- Selection & Dragging State ---
var selected_entity_type: String = "" # "portal", "item", "npc", or ""
var selected_entity_index: int = -1
var is_dragging_entity: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# --- Undo / Redo History State ---
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const MAX_UNDO_LEVELS: int = 50
var _paint_stroke_before: PackedByteArray = PackedByteArray()
var _drag_start_pos: Vector2 = Vector2.ZERO

# --- View Toggles ---
var show_grid: bool = true
var show_collision: bool = true
var show_portals: bool = true
var show_items: bool = true
var show_npcs: bool = true
var show_walkable_tiles: bool = false

# --- Active Tools ---
var active_tool: ToolMode = ToolMode.PAINT
var active_collision_flag: int = MapData.TileCollisionFlags.SOLID_WALL
var brush_size: int = 1 # 1, 3, 5, 7

# --- UI Node References ---
@onready var canvas_control: Control = $MainVBox/BodyArea/CanvasPanel/CanvasControl
@onready var tab_container: TabContainer = $MainVBox/BodyArea/Sidebar/TabContainer

# Top Bar
@onready var btn_new: Button = $MainVBox/TopBar/TopHBox/BtnNew
@onready var btn_load: Button = $MainVBox/TopBar/TopHBox/BtnLoad
@onready var btn_save_binary: Button = $MainVBox/TopBar/TopHBox/BtnSaveBinary
@onready var btn_export_json: Button = $MainVBox/TopBar/TopHBox/BtnExportJson
@onready var btn_import_json: Button = $MainVBox/TopBar/TopHBox/BtnImportJson
@onready var btn_export_scene: Button = $MainVBox/TopBar/TopHBox/BtnExportScene

@onready var check_grid: CheckBox = $MainVBox/TopBar/TopHBox/CheckGrid
@onready var check_collision: CheckBox = $MainVBox/TopBar/TopHBox/CheckCollision
@onready var check_portals: CheckBox = $MainVBox/TopBar/TopHBox/CheckPortals
@onready var check_items: CheckBox = $MainVBox/TopBar/TopHBox/CheckItems
@onready var check_npcs: CheckBox = $MainVBox/TopBar/TopHBox/CheckNPCs
@onready var check_walkable: CheckBox = $MainVBox/TopBar/TopHBox/CheckWalkable

@onready var btn_zoom_out: Button = $MainVBox/TopBar/TopHBox/BtnZoomOut
@onready var zoom_label: Label = $MainVBox/TopBar/TopHBox/ZoomLabel
@onready var btn_zoom_in: Button = $MainVBox/TopBar/TopHBox/BtnZoomIn
@onready var btn_zoom_reset: Button = $MainVBox/TopBar/TopHBox/BtnZoomReset
@onready var btn_recenter: Button = $MainVBox/TopBar/TopHBox/BtnRecenter

# Map Setup Tab
@onready var map_id_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/MapIdHBox/MapIdSpin
@onready var map_name_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/MapNameHBox/MapNameEdit
@onready var map_search_edit: LineEdit = find_child("MapSearchEdit", true, false)
@onready var preset_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/PresetHBox/PresetSelect
@onready var btn_load_preset: Button = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/PresetHBox/BtnLoadPreset
@onready var sec_map_npc_dock: Label = find_child("SecMapNpcDock", true, false)
@onready var map_npc_dock_list: ItemList = find_child("MapNpcDockList", true, false)
var _all_preset_maps: Dictionary = {}
@onready var bg_source_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/BgSourceHBox/BgSourceSelect
@onready var bg_path_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/BgPathHBox/BgPathEdit
@onready var btn_browse_bg: Button = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/BgPathHBox/BtnBrowseBg
@onready var btn_load_bg: Button = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/BtnLoadBg
@onready var dimensions_label: Label = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/DimensionsLabel
@onready var width_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/DimsHBox/WidthSpin
@onready var height_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/DimsHBox/HeightSpin
@onready var btn_resize_grid: Button = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/BtnResizeGrid
@onready var spawn_x_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/SpawnHBox/SpawnXSpin
@onready var spawn_y_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/SpawnHBox/SpawnYSpin
@onready var btn_spawn_center: Button = $MainVBox/BodyArea/Sidebar/TabContainer/MapSetup/Scroll/VBox/BtnSpawnCenter

# Collision Tab
@onready var tool_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/Collision/Scroll/VBox/ToolSelect
@onready var collision_flag_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/Collision/Scroll/VBox/CollisionFlagSelect
@onready var brush_size_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/Collision/Scroll/VBox/BrushSizeSelect
@onready var btn_fill_all: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Collision/Scroll/VBox/BtnFillAll
@onready var btn_clear_collision: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Collision/Scroll/VBox/BtnClearCollision
@onready var btn_invert_collision: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Collision/Scroll/VBox/BtnInvertCollision
@onready var collision_stats_label: Label = $MainVBox/BodyArea/Sidebar/TabContainer/Collision/Scroll/VBox/CollisionStatsLabel

# Portals Tab
@onready var btn_place_portal_mode: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/BtnPlacePortalMode
@onready var portal_id_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/IdHBox/PortalIdSpin
@onready var portal_name_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/NameHBox/PortalNameEdit
@onready var portal_target_map_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/TargetMapHBox/PortalTargetMapSpin
@onready var portal_dest_x_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/DestHBox/PortalDestXSpin
@onready var portal_dest_y_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/DestHBox/PortalDestYSpin
@onready var portal_radius_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/RadiusHBox/PortalRadiusSpin
@onready var portal_color_picker: ColorPickerButton = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/ColorHBox/PortalColorPicker
@onready var btn_add_portal: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/ActionsHBox/BtnAddPortal
@onready var btn_delete_portal: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/ActionsHBox/BtnDeletePortal
@onready var portal_item_list: ItemList = $MainVBox/BodyArea/Sidebar/TabContainer/Portals/Scroll/VBox/PortalItemList

# Ground Items Tab
@onready var btn_place_item_mode: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/BtnPlaceItemMode
@onready var item_id_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/IdHBox/ItemIdSpin
@onready var item_name_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/NameHBox/ItemNameEdit
@onready var item_slot_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/SlotHBox/ItemSlotSpin
@onready var item_respawn_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/RespawnHBox/ItemRespawnSpin
@onready var quick_item_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/QuickItemSelect
@onready var btn_add_item: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/ActionsHBox/BtnAddItem
@onready var btn_delete_item: Button = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/ActionsHBox/BtnDeleteItem
@onready var item_item_list: ItemList = $MainVBox/BodyArea/Sidebar/TabContainer/Items/Scroll/VBox/ItemItemList

# NPCs Tab
@onready var btn_place_npc_mode: Button = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/BtnPlaceNpcMode
@onready var npc_id_spin: SpinBox = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/IdHBox/NpcIdSpin
@onready var npc_name_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/NameHBox/NpcNameEdit
@onready var npc_jmp_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/JmpHBox/NpcJmpEdit
@onready var npc_jma_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/JmaHBox/NpcJmaEdit
@onready var npc_heading_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/HeadingHBox/NpcHeadingSelect
@onready var npc_dialogue_edit: TextEdit = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/NpcDialogueEdit
@onready var npc_choices_edit: LineEdit = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/NpcChoicesEdit
@onready var quick_npc_select: OptionButton = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/QuickNpcSelect
@onready var btn_add_npc: Button = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/ActionsHBox/BtnAddNpc
@onready var btn_delete_npc: Button = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/ActionsHBox/BtnDeleteNpc
@onready var npc_item_list: ItemList = $MainVBox/BodyArea/Sidebar/TabContainer/NPCs/Scroll/VBox/NpcItemList

# Status Bar
@onready var status_coords: Label = $MainVBox/StatusBar/StatusHBox/StatusCoords
@onready var status_flag: Label = $MainVBox/StatusBar/StatusHBox/StatusFlag
@onready var status_entities: Label = $MainVBox/StatusBar/StatusHBox/StatusEntities
@onready var status_dimensions: Label = $MainVBox/StatusBar/StatusHBox/StatusDimensions
@onready var status_help: Label = $MainVBox/StatusBar/StatusHBox/StatusHelp

# File Dialogs
@onready var file_dialog_save_binary: FileDialog = $FileDialogSaveBinary
@onready var file_dialog_save_json: FileDialog = $FileDialogSaveJson
@onready var file_dialog_load_json: FileDialog = $FileDialogLoadJson
@onready var file_dialog_save_scene: FileDialog = $FileDialogSaveScene
@onready var file_dialog_browse_bg: FileDialog = $FileDialogBrowseBg

func _ready() -> void:
	_setup_canvas()
	_setup_presets()
	_setup_options()
	_connect_ui_signals()
	
	# Initial default map load
	load_map_from_id(10001)
	recenter_canvas()
	_update_status_bar()

# --- Canvas & Coordinate Methods ---

func _setup_canvas() -> void:
	if canvas_control:
		if not canvas_control.draw.is_connected(_on_canvas_draw):
			canvas_control.draw.connect(_on_canvas_draw)
		if not canvas_control.gui_input.is_connected(_on_canvas_gui_input):
			canvas_control.gui_input.connect(_on_canvas_gui_input)
		if not canvas_control.mouse_entered.is_connected(_on_canvas_mouse_entered):
			canvas_control.mouse_entered.connect(_on_canvas_mouse_entered)
		if not canvas_control.mouse_exited.is_connected(_on_canvas_mouse_exited):
			canvas_control.mouse_exited.connect(_on_canvas_mouse_exited)

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - pan_offset) / zoom_level

func world_to_screen(world_pos: Vector2) -> Vector2:
	return world_pos * zoom_level + pan_offset

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / float(tile_scale))), int(floor(world_pos.y / float(tile_scale))))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(float(grid_pos.x * tile_scale), float(grid_pos.y * tile_scale))

func grid_to_center_world(grid_pos: Vector2i) -> Vector2:
	return Vector2((float(grid_pos.x) + 0.5) * float(tile_scale), (float(grid_pos.y) + 0.5) * float(tile_scale))

func set_zoom(new_zoom: float, pivot_screen: Vector2 = Vector2.ZERO) -> void:
	var clamped := clampf(new_zoom, 0.1, 5.0)
	if is_equal_approx(clamped, zoom_level):
		return
	var pivot_world := screen_to_world(pivot_screen)
	zoom_level = clamped
	pan_offset = pivot_screen - pivot_world * zoom_level
	if zoom_label:
		zoom_label.text = "%d%%" % int(round(zoom_level * 100.0))
	if canvas_control:
		canvas_control.queue_redraw()

func recenter_canvas() -> void:
	if not canvas_control:
		return
	var canvas_sz := canvas_control.size
	if canvas_sz == Vector2.ZERO:
		canvas_sz = Vector2(800, 500)
	var map_sz := Vector2(width_px, height_px)
	if map_sz == Vector2.ZERO:
		map_sz = Vector2(2000, 2000)
	
	# Fit zoom so entire map is visible comfortably
	var fit_zoom_x := (canvas_sz.x * 0.85) / map_sz.x
	var fit_zoom_y := (canvas_sz.y * 0.85) / map_sz.y
	zoom_level = clampf(minf(fit_zoom_x, fit_zoom_y), 0.15, 1.5)
	
	# Center in viewport
	var center_world := map_sz * 0.5
	pan_offset = canvas_sz * 0.5 - center_world * zoom_level
	if zoom_label:
		zoom_label.text = "%d%%" % int(round(zoom_level * 100.0))
	canvas_control.queue_redraw()

# --- Grid & Collision Operations ---

func init_empty_map(p_width: int, p_height: int, p_map_id: int, p_map_name: String) -> void:
	map_id = p_map_id
	map_name = p_map_name
	width_px = maxi(p_width, 100)
	height_px = maxi(p_height, 100)
	cols = int(ceil(float(width_px) / float(tile_scale)))
	rows = int(ceil(float(height_px) / float(tile_scale)))
	collision_grid.resize(cols * rows)
	collision_grid.fill(MapData.TileCollisionFlags.WALKABLE)
	portals.clear()
	ground_items.clear()
	npcs.clear()
	undo_stack.clear()
	redo_stack.clear()
	player_spawn_pos = Vector2(float(width_px) * 0.5, float(height_px) * 0.5)
	
	_update_ui_forms()
	_update_stats()
	recenter_canvas()

func resize_map_grid(new_width: int, new_height: int) -> void:
	var old_cols := cols
	var old_rows := rows
	var old_grid := collision_grid.duplicate()
	
	width_px = maxi(new_width, 100)
	height_px = maxi(new_height, 100)
	cols = int(ceil(float(width_px) / float(tile_scale)))
	rows = int(ceil(float(height_px) / float(tile_scale)))
	
	collision_grid.resize(cols * rows)
	collision_grid.fill(MapData.TileCollisionFlags.WALKABLE)
	
	# Copy existing overlapping tiles
	var min_c := mini(old_cols, cols)
	var min_r := mini(old_rows, rows)
	for r in range(min_r):
		for c in range(min_c):
			var old_idx := r * old_cols + c
			var new_idx := r * cols + c
			if old_idx < old_grid.size() and new_idx < collision_grid.size():
				collision_grid[new_idx] = old_grid[old_idx]
	
	_update_ui_forms()
	_update_stats()
	if canvas_control:
		canvas_control.queue_redraw()

func get_collision_at(col: int, row: int) -> int:
	if col < 0 or col >= cols or row < 0 or row >= rows:
		return MapData.TileCollisionFlags.SOLID_WALL
	var idx := row * cols + col
	if idx < 0 or idx >= collision_grid.size():
		return MapData.TileCollisionFlags.SOLID_WALL
	return int(collision_grid[idx])

func set_collision_at(col: int, row: int, flag: int) -> void:
	if col < 0 or col >= cols or row < 0 or row >= rows:
		return
	var idx := row * cols + col
	if idx >= 0 and idx < collision_grid.size():
		collision_grid[idx] = flag

func paint_brush(center_c: int, center_r: int, flag: int, size: int) -> void:
	var half := size / 2
	for dy in range(-half, half + 1):
		for dx in range(-half, half + 1):
			set_collision_at(center_c + dx, center_r + dy, flag)

func flood_fill(start_c: int, start_r: int, fill_flag: int) -> void:
	if start_c < 0 or start_c >= cols or start_r < 0 or start_r >= rows:
		return
	var target_flag := get_collision_at(start_c, start_r)
	if target_flag == fill_flag:
		return
	
	var queue: Array[Vector2i] = [Vector2i(start_c, start_r)]
	var visited: Dictionary = {}
	visited[Vector2i(start_c, start_r)] = true
	
	while not queue.is_empty():
		var pt: Vector2i = queue.pop_front()
		var c := pt.x
		var r := pt.y
		set_collision_at(c, r, fill_flag)
		
		var neighbors: Array[Vector2i] = [
			Vector2i(c + 1, r),
			Vector2i(c - 1, r),
			Vector2i(c, r + 1),
			Vector2i(c, r - 1)
		]
		for n in neighbors:
			if n.x >= 0 and n.x < cols and n.y >= 0 and n.y < rows:
				if not visited.has(n):
					visited[n] = true
					if get_collision_at(n.x, n.y) == target_flag:
						queue.append(n)

func rect_fill(start_grid: Vector2i, end_grid: Vector2i, flag: int) -> void:
	var min_c := mini(start_grid.x, end_grid.x)
	var max_c := maxi(start_grid.x, end_grid.x)
	var min_r := mini(start_grid.y, end_grid.y)
	var max_r := maxi(start_grid.y, end_grid.y)
	for r in range(min_r, max_r + 1):
		for c in range(min_c, max_c + 1):
			set_collision_at(c, r, flag)

func fill_all(flag: int) -> void:
	var before := collision_grid.duplicate()
	collision_grid.fill(flag)
	record_action({"type": "collision", "before": before, "after": collision_grid.duplicate()})
	_update_stats()
	if canvas_control:
		canvas_control.queue_redraw()

func clear_collision() -> void:
	fill_all(MapData.TileCollisionFlags.WALKABLE)

func invert_collision() -> void:
	var before := collision_grid.duplicate()
	for i in range(collision_grid.size()):
		var val := int(collision_grid[i])
		if val == MapData.TileCollisionFlags.WALKABLE:
			collision_grid[i] = MapData.TileCollisionFlags.SOLID_WALL
		else:
			collision_grid[i] = MapData.TileCollisionFlags.WALKABLE
	record_action({"type": "collision", "before": before, "after": collision_grid.duplicate()})
	_update_stats()
	if canvas_control:
		canvas_control.queue_redraw()

func get_collision_stats() -> Dictionary:
	var stats: Dictionary = {
		"walkable": 0,
		"solid": 0,
		"water": 0,
		"sea": 0,
		"deep_ocean": 0,
		"mountain": 0,
		"other": 0,
		"total": collision_grid.size()
	}
	for i in range(collision_grid.size()):
		match int(collision_grid[i]):
			MapData.TileCollisionFlags.WALKABLE:
				stats["walkable"] += 1
			MapData.TileCollisionFlags.SOLID_WALL:
				stats["solid"] += 1
			MapData.TileCollisionFlags.WATER, MapData.TileCollisionFlags.SHALLOW_WATER:
				stats["water"] += 1
			MapData.TileCollisionFlags.SEA:
				stats["sea"] += 1
			MapData.TileCollisionFlags.DEEP_OCEAN:
				stats["deep_ocean"] += 1
			MapData.TileCollisionFlags.MOUNTAIN, MapData.TileCollisionFlags.HOT_SPRING:
				stats["mountain"] += 1
			_:
				stats["other"] += 1
	return stats

# --- Map Loading & Background ---

func load_map_from_id(p_map_id: int, custom_bg_path: String = "") -> bool:
	map_id = p_map_id
	
	# 1. Resolve map name
	map_name = "Map %d" % map_id
	var gdb = get_node_or_null("/root/GameDatabase") if is_inside_tree() else null
	if gdb and gdb.scenes:
		var scene_rec = gdb.scenes.get_scene(map_id)
		if scene_rec and not scene_rec.name.is_empty():
			map_name = scene_rec.name
	else:
		match map_id:
			10001: map_name = "Ship Deck"
			10002: map_name = "Ship Cabin"
			10003: map_name = "Ship Kitchen"
			10011: map_name = "Beach Awakening"
			20001: map_name = "Kelan Village"
			12001: map_name = "Holy Village"
	
	# 2. Load background texture
	background_texture = null
	if not custom_bg_path.is_empty() and FileAccess.file_exists(custom_bg_path):
		var full_p := ProjectSettings.globalize_path(custom_bg_path)
		var img := Image.load_from_file(full_p)
		if img:
			background_texture = ImageTexture.create_from_image(img)
			background_path = custom_bg_path
	
	if not background_texture:
		var loader = get_node_or_null("/root/ArchiveLoader") if is_inside_tree() else null
		if loader and loader.has_method("get_map_background"):
			background_texture = loader.get_map_background(map_id)
			background_path = "ArchiveLoader(map_%d)" % map_id
	
	if not background_texture:
		# Check fallback picture paths
		var fallbacks: Array[String] = [
			"res://assets/pic/%d.jpg" % map_id,
			"res://assets/pic/%05d.jpg" % map_id,
			"res://assets/pic/%04d.jpg" % map_id,
			"D:/GitHub/WLRI/pic/%d.jpg" % map_id,
			"D:/GitHub/WLRI/pic/%05d.jpg" % map_id
		]
		for fb in fallbacks:
			if FileAccess.file_exists(fb):
				var img := Image.load_from_file(ProjectSettings.globalize_path(fb))
				if img:
					background_texture = ImageTexture.create_from_image(img)
					background_path = fb
					break

	if background_texture:
		width_px = background_texture.get_width()
		height_px = background_texture.get_height()
	else:
		width_px = 2084
		height_px = 2400
	
	cols = int(ceil(float(width_px) / float(tile_scale)))
	rows = int(ceil(float(height_px) / float(tile_scale)))
	collision_grid.resize(cols * rows)
	collision_grid.fill(MapData.TileCollisionFlags.WALKABLE)
	
	# 3. Load authentic collision if available
	var disk_id := MapData.get_disk_map_id(map_id)
	var disk_path := "res://assets/user/Map/%d.MapData" % disk_id
	if not FileAccess.file_exists(disk_path) and FileAccess.file_exists("D:/GitHub/WLRI/user/Map/%d.MapData" % disk_id):
		disk_path = "D:/GitHub/WLRI/user/Map/%d.MapData" % disk_id
	
	var authentic_map: MapData = MapData.load_map(map_id, disk_path)
	if authentic_map:
		for r in range(rows):
			for c in range(cols):
				var byte_val := authentic_map.get_collision_byte(c, r)
				set_collision_at(c, r, byte_val)
	
	# 4. Load authentic portals and items from EveParser
	portals.clear()
	ground_items.clear()
	npcs.clear()
	
	var eve := EveParser.new()
	if eve:
		var warps = eve.get_warps_for_map(map_id)
		var p_id: int = 1
		for w in warps:
			var pe := PortalEntry.new()
			pe.portal_id = p_id
			pe.portal_name = w.name if not w.name.is_empty() else ("Portal %d" % p_id)
			pe.world_position = Vector2(float(w.world_x), float(w.world_y))
			pe.target_map_id = w.target_map_id
			pe.target_coords = Vector2(float(w.dest_x), float(w.dest_y))
			pe.trigger_radius = 56.0
			portals.append(pe)
			p_id += 1
		
		var items_data: Array = eve.get_ground_items_for_map(map_id) if eve.has_method("get_ground_items_for_map") else []
		for it in items_data:
			var gi := GroundItemEntry.new()
			gi.item_id = it.item_id
			gi.item_name = it.name
			gi.world_position = Vector2(float(it.world_x), float(it.world_y))
			gi.slot = it.slot
			gi.respawn_seconds = float(it.respawn_seconds)
			ground_items.append(gi)
		
		var npcs_data: Array = eve.get_npcs_for_map(map_id)
		for n in npcs_data:
			var ne := NpcEntry.new()
			ne.click_id = n.click_id
			ne.template_id = n.npc_id
			ne.npc_id = n.npc_id
			ne.npc_name = n.name
			if (ne.npc_name == "Npc" or ne.npc_name.begins_with("NPC_")) and gdb and gdb.npcs:
				var nrec = gdb.npcs.get_npc(ne.npc_id)
				if nrec and not nrec.name.is_empty():
					ne.npc_name = nrec.name
			ne.world_position = Vector2(float(n.world_x), float(n.world_y))
			ne.heading = n.heading
			ne.rotation = n.rotation
			ne.model_jmp = "%d.jmp" % n.npc_id
			npcs.append(ne)

	player_spawn_pos = Vector2(float(width_px) * 0.5, float(height_px) * 0.5)
	
	if preset_select:
		for i in range(preset_select.item_count):
			if preset_select.get_item_id(i) == map_id:
				preset_select.selected = i
				break

	_update_ui_forms()
	_update_stats()
	refresh_portal_list()
	refresh_ground_item_list()
	refresh_npc_list()
	undo_stack.clear()
	redo_stack.clear()
	
	if canvas_control:
		canvas_control.queue_redraw()
	return true

# --- Portal Management ---

func add_portal(pos: Vector2, target_id: int, dest: Vector2, arg4 = "Portal", arg5 = 56.0, col: Color = Color(0.2, 0.75, 1.0, 0.85)) -> PortalEntry:
	var p_name: String = "Portal"
	var radius: float = 56.0
	if arg4 is String:
		p_name = arg4
		if arg5 is float or arg5 is int:
			radius = float(arg5)
	elif arg4 is float or arg4 is int:
		radius = float(arg4)
		if arg5 is String:
			p_name = arg5
	var p := PortalEntry.new()
	p.portal_id = portals.size() + 1
	p.portal_name = p_name
	p.world_position = pos
	p.target_map_id = target_id
	p.target_coords = dest
	p.trigger_radius = radius
	p.portal_color = col
	portals.append(p)
	refresh_portal_list()
	if canvas_control:
		canvas_control.queue_redraw()
	record_action({"type": "add_portal", "portal": p.to_dict(), "index": portals.size() - 1})
	return p

func remove_portal(idx: int) -> void:
	if idx >= 0 and idx < portals.size():
		var p_dict: Dictionary = portals[idx].to_dict()
		portals.remove_at(idx)
		if selected_entity_type == "portal" and selected_entity_index == idx:
			selected_entity_type = ""
			selected_entity_index = -1
		refresh_portal_list()
		if canvas_control:
			canvas_control.queue_redraw()
		record_action({"type": "remove_portal", "portal": p_dict, "index": idx})

func refresh_portal_list() -> void:
	if not portal_item_list:
		return
	portal_item_list.clear()
	for i in range(portals.size()):
		var p := portals[i]
		var item_txt := "#%d %s (%d, %d) -> Map %d (%d, %d)" % [
			p.portal_id, p.portal_name,
			int(p.world_position.x), int(p.world_position.y),
			p.target_map_id,
			int(p.target_coords.x), int(p.target_coords.y)
		]
		portal_item_list.add_item(item_txt)
	_update_status_bar()

# --- Ground Item Management ---

func add_ground_item(pos: Vector2, p_item_id: int, arg3 = "", arg4 = 1, arg5 = 120.0) -> GroundItemEntry:
	var item_name: String = ""
	var slot: int = 1
	var respawn: float = 120.0
	
	if arg3 is String:
		item_name = arg3
		if arg4 is int:
			slot = arg4
		if arg5 is float or arg5 is int:
			respawn = float(arg5)
	elif arg3 is int:
		slot = arg3
		if arg4 is float or arg4 is int:
			respawn = float(arg4)
		if arg5 is String:
			item_name = arg5

	var it := GroundItemEntry.new()
	it.item_id = p_item_id
	it.item_name = item_name
	if it.item_name.is_empty():
		var gdb = get_node_or_null("/root/GameDatabase")
		if gdb and gdb.items:
			var rec = gdb.items.get_item(p_item_id)
			if rec:
				it.item_name = rec.name
		if it.item_name.is_empty():
			it.item_name = "Item %d" % p_item_id
	it.world_position = pos
	it.slot = slot
	it.respawn_seconds = respawn
	ground_items.append(it)
	refresh_ground_item_list()
	if canvas_control:
		canvas_control.queue_redraw()
	record_action({"type": "add_item", "item": it.to_dict(), "index": ground_items.size() - 1})
	return it

func remove_ground_item(idx: int) -> void:
	if idx >= 0 and idx < ground_items.size():
		var it_dict: Dictionary = ground_items[idx].to_dict()
		ground_items.remove_at(idx)
		if selected_entity_type == "item" and selected_entity_index == idx:
			selected_entity_type = ""
			selected_entity_index = -1
		refresh_ground_item_list()
		if canvas_control:
			canvas_control.queue_redraw()
		record_action({"type": "remove_item", "item": it_dict, "index": idx})

func refresh_ground_item_list() -> void:
	if not item_item_list:
		return
	item_item_list.clear()
	for i in range(ground_items.size()):
		var it := ground_items[i]
		var item_txt := "#%d %s (%d, %d) Slot:%d Respawn:%.0fs" % [
			it.item_id, it.item_name,
			int(it.world_position.x), int(it.world_position.y),
			it.slot, it.respawn_seconds
		]
		item_item_list.add_item(item_txt)
	_update_status_bar()

# --- NPC Management ---

func add_npc(pos: Vector2, p_npc_id: int, p_name: String = "NPC", p_jmp: String = "1037.jmp", p_jma: String = "001.jma", p_heading: int = IsometricMath.Heading.SOUTH, p_dialogue: String = "", p_choices: Array = []) -> NpcEntry:
	var n := NpcEntry.new()
	n.npc_id = p_npc_id
	n.npc_name = p_name
	n.model_jmp = p_jmp
	n.model_jma = p_jma
	n.heading = p_heading
	n.world_position = pos
	n.dialogue_text = p_dialogue
	n.dialogue_choices.clear()
	for c in p_choices:
		n.dialogue_choices.append(str(c))
	npcs.append(n)
	refresh_npc_list()
	if canvas_control:
		canvas_control.queue_redraw()
	record_action({"type": "add_npc", "npc": n.to_dict(), "index": npcs.size() - 1})
	return n

func remove_npc(idx: int) -> void:
	if idx >= 0 and idx < npcs.size():
		var n_dict: Dictionary = npcs[idx].to_dict()
		npcs.remove_at(idx)
		if selected_entity_type == "npc" and selected_entity_index == idx:
			selected_entity_type = ""
			selected_entity_index = -1
		refresh_npc_list()
		if canvas_control:
			canvas_control.queue_redraw()
		record_action({"type": "remove_npc", "npc": n_dict, "index": idx})

static func heading_to_name(h: int) -> String:
	match h % 8:
		IsometricMath.Heading.NORTH: return "NORTH"
		IsometricMath.Heading.NORTH_WEST: return "NORTH_WEST"
		IsometricMath.Heading.WEST: return "WEST"
		IsometricMath.Heading.SOUTH_WEST: return "SOUTH_WEST"
		IsometricMath.Heading.SOUTH: return "SOUTH"
		IsometricMath.Heading.SOUTH_EAST: return "SOUTH_EAST"
		IsometricMath.Heading.EAST: return "EAST"
		IsometricMath.Heading.NORTH_EAST: return "NORTH_EAST"
	return "SOUTH"

func refresh_npc_list() -> void:
	if npc_item_list:
		npc_item_list.clear()
		for i in range(npcs.size()):
			var n := npcs[i]
			var h_str: String = heading_to_name(n.heading)
			var item_txt := "[Click #%d] %s (Tpl #%d) | Pos: (%d, %d) | Facing: %s (H:%d)" % [
				n.click_id if n.click_id > 0 else (i + 1),
				n.npc_name,
				n.template_id if n.template_id > 0 else n.npc_id,
				int(n.world_position.x), int(n.world_position.y),
				h_str, n.heading
			]
			npc_item_list.add_item(item_txt)
	
	if map_npc_dock_list:
		map_npc_dock_list.clear()
		for i in range(npcs.size()):
			var n := npcs[i]
			var h_str: String = heading_to_name(n.heading)
			var item_txt := "[#%d] %s (Tpl:%d) | Pos: (%d, %d) | Facing: %s" % [
				n.click_id if n.click_id > 0 else (i + 1),
				n.npc_name,
				n.template_id if n.template_id > 0 else n.npc_id,
				int(n.world_position.x), int(n.world_position.y),
				h_str
			]
			map_npc_dock_list.add_item(item_txt)
	
	if sec_map_npc_dock:
		sec_map_npc_dock.text = "Map NPCs (%d total)" % npcs.size()

	_update_status_bar()

# --- Export & Packaging Functions ---

## Exports binary .MapData format compatible with MapData.load_from_mapdata_file.
## File structure: 36-byte block header (dimensions, coordinates, flags) + cols*rows collision matrix.
func export_mapdata_binary(file_path: String = "") -> bool:
	var target_path: String = file_path
	if target_path.is_empty():
		var disk_id: int = MapData.get_disk_map_id(map_id)
		target_path = "res://assets/user/Map/%d.MapData" % disk_id
	
	var dir_path: String = target_path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: " + target_path)
		return false
	
	# 36-byte block header matching MapBlock format in MapData
	var header := PackedByteArray()
	header.resize(36)
	header.encode_u32(0, 1) # block_id
	header.encode_u32(4, 0) # tile_sprite_id
	header.encode_s32(8, 0) # grid_x
	header.encode_s32(12, 0) # grid_y
	header.encode_s16(16, cols) # dim_x
	header.encode_s16(18, rows) # dim_y
	header[20] = 0 # is_uniform
	header[21] = 0 # elevation
	# bytes 22..35 are reserved zeros
	
	file.store_buffer(header)
	file.store_buffer(collision_grid)
	file.close()
	
	# Verify output by reading back with MapData
	var verify_map := MapData.load_from_mapdata_file(target_path, map_id)
	if not verify_map or verify_map.blocks.is_empty():
		push_error("Verification failed for exported binary MapData: " + target_path)
		return false
	
	print("[MapEditor] Successfully exported binary MapData: %s (blocks: %d, size: %d bytes)" % [
		target_path, verify_map.blocks.size(), 36 + collision_grid.size()
	])
	return true

## Exports human-readable JSON containing grid dimensions, collision, portals, ground items, and NPCs.
func export_map_json(file_path: String = "") -> bool:
	var target_path: String = file_path
	if target_path.is_empty():
		target_path = "res://assets/maps/map_%d.json" % map_id
	
	var dir_path: String = target_path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	
	var portals_arr: Array[Dictionary] = []
	for p in portals:
		portals_arr.append(p.to_dict())
	
	var items_arr: Array[Dictionary] = []
	for it in ground_items:
		items_arr.append(it.to_dict())
	
	var npcs_arr: Array[Dictionary] = []
	for n in npcs:
		npcs_arr.append(n.to_dict())
	
	var data: Dictionary = {
		"version": 1,
		"map_id": map_id,
		"map_name": map_name,
		"width_px": width_px,
		"height_px": height_px,
		"cols": cols,
		"rows": rows,
		"tile_scale": tile_scale,
		"player_spawn": {"x": player_spawn_pos.x, "y": player_spawn_pos.y},
		"background_source": background_path,
		"collision_base64": Marshalls.raw_to_base64(collision_grid),
		"portals": portals_arr,
		"ground_items": items_arr,
		"npcs": npcs_arr
	}
	
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open JSON file for writing: " + target_path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[MapEditor] Successfully exported map JSON: %s" % target_path)
	return true

## Imports map structure, entities, and collision from a JSON file.
func import_map_json(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("JSON file does not exist: " + file_path)
		return false
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	var text := file.get_as_text()
	file.close()
	
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_error("Invalid JSON map data in: " + file_path)
		return false
	var dict: Dictionary = parsed
	
	map_id = int(dict.get("map_id", 10001))
	map_name = str(dict.get("map_name", "Custom Map"))
	width_px = int(dict.get("width_px", 2000))
	height_px = int(dict.get("height_px", 2000))
	cols = int(dict.get("cols", int(ceil(float(width_px) / float(tile_scale)))))
	rows = int(dict.get("rows", int(ceil(float(height_px) / float(tile_scale)))))
	
	var spawn_dict = dict.get("player_spawn", {})
	if spawn_dict is Dictionary:
		player_spawn_pos = Vector2(float(spawn_dict.get("x", width_px * 0.5)), float(spawn_dict.get("y", height_px * 0.5)))
	
	# Collision grid
	var b64 := str(dict.get("collision_base64", ""))
	if not b64.is_empty():
		collision_grid = Marshalls.base64_to_raw(b64)
	else:
		collision_grid.resize(cols * rows)
		collision_grid.fill(0)
	
	# Portals
	portals.clear()
	var raw_portals = dict.get("portals", [])
	if raw_portals is Array:
		for pd in raw_portals:
			if pd is Dictionary:
				var p := PortalEntry.new()
				p.from_dict(pd)
				portals.append(p)
	
	# Ground Items
	ground_items.clear()
	var raw_items = dict.get("ground_items", [])
	if raw_items is Array:
		for itd in raw_items:
			if itd is Dictionary:
				var it := GroundItemEntry.new()
				it.from_dict(itd)
				ground_items.append(it)
	
	# NPCs
	npcs.clear()
	var raw_npcs = dict.get("npcs", [])
	if raw_npcs is Array:
		for nd in raw_npcs:
			if nd is Dictionary:
				var n := NpcEntry.new()
				n.from_dict(nd)
				npcs.append(n)
	
	# Load background artwork
	var bg_src := str(dict.get("background_source", ""))
	if not bg_src.is_empty() and FileAccess.file_exists(bg_src):
		var img := Image.load_from_file(ProjectSettings.globalize_path(bg_src))
		if img:
			background_texture = ImageTexture.create_from_image(img)
	if not background_texture:
		var loader = get_node_or_null("/root/ArchiveLoader") if is_inside_tree() else null
		if loader and loader.has_method("get_map_background"):
			background_texture = loader.get_map_background(map_id)
	
	_update_ui_forms()
	_update_stats()
	refresh_portal_list()
	refresh_ground_item_list()
	refresh_npc_list()
	undo_stack.clear()
	redo_stack.clear()
	recenter_canvas()
	print("[MapEditor] Imported map JSON successfully: %s" % file_path)
	return true

## Generates a production Godot .tscn scene extending map_view.tscn configured for this map.
func export_map_scene(file_path: String = "") -> bool:
	var target_path: String = file_path
	if target_path.is_empty():
		var safe_name := map_name.to_lower().replace(" ", "_").validate_node_name()
		target_path = "res://scenes/maps/map_%d_%s.tscn" % [map_id, safe_name]
	
	var dir_path: String = target_path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	
	var out: String = ""
	out += "[gd_scene load_steps=8 format=3]\n\n"
	out += "[ext_resource type=\"Script\" path=\"res://scripts/map/map_view.gd\" id=\"1_mapview\"]\n"
	out += "[ext_resource type=\"Script\" path=\"res://scripts/map/map_renderer.gd\" id=\"2_map\"]\n"
	out += "[ext_resource type=\"PackedScene\" path=\"res://scenes/world/player.tscn\" id=\"3_player\"]\n"
	out += "[ext_resource type=\"PackedScene\" path=\"res://scenes/world/npc.tscn\" id=\"4_npc\"]\n"
	out += "[ext_resource type=\"PackedScene\" path=\"res://scenes/ui/hud.tscn\" id=\"5_hud\"]\n"
	out += "[ext_resource type=\"Script\" path=\"res://scripts/map/portal.gd\" id=\"6_portal\"]\n"
	out += "[ext_resource type=\"Script\" path=\"res://scripts/map/ground_item.gd\" id=\"7_ground_item\"]\n\n"
	
	var scene_root_name := "Map%d_%s" % [map_id, map_name.replace(" ", "_").validate_node_name()]
	out += "[node name=\"%s\" type=\"Node2D\"]\n" % scene_root_name
	out += "script = ExtResource(\"1_mapview\")\n\n"
	
	out += "[node name=\"MapRenderer\" type=\"Node2D\" parent=\".\"]\n"
	out += "script = ExtResource(\"2_map\")\n"
	out += "current_map_id = %d\n\n" % map_id
	
	out += "[node name=\"Camera2D\" type=\"Camera2D\" parent=\".\"]\n"
	out += "position = Vector2(%d, %d)\n" % [int(player_spawn_pos.x), int(player_spawn_pos.y)]
	out += "zoom = Vector2(1, 1)\n"
	out += "position_smoothing_enabled = true\n"
	out += "position_smoothing_speed = 6.0\n\n"
	
	out += "[node name=\"Entities\" type=\"Node2D\" parent=\".\"]\n"
	out += "y_sort_enabled = true\n\n"
	
	out += "[node name=\"Player\" parent=\"Entities\" instance=ExtResource(\"3_player\")]\n"
	out += "world_position = Vector2(%d, %d)\n\n" % [int(player_spawn_pos.x), int(player_spawn_pos.y)]
	
	# Portals
	for i in range(portals.size()):
		var p := portals[i]
		var p_name := "Portal_%d_%s" % [p.portal_id, p.portal_name.replace(" ", "_").validate_node_name()]
		out += "[node name=\"%s\" type=\"Node2D\" parent=\"Entities\"]\n" % p_name
		out += "position = Vector2(%d, %d)\n" % [int(p.world_position.x), int(p.world_position.y)]
		out += "script = ExtResource(\"6_portal\")\n"
		out += "portal_id = %d\n" % p.portal_id
		out += "portal_name = \"%s\"\n" % p.portal_name.c_escape()
		out += "target_map_id = %d\n" % p.target_map_id
		out += "target_coords = Vector2(%d, %d)\n" % [int(p.target_coords.x), int(p.target_coords.y)]
		out += "trigger_radius = %.1f\n" % p.trigger_radius
		out += "portal_color = Color(%.3f, %.3f, %.3f, %.3f)\n\n" % [p.portal_color.r, p.portal_color.g, p.portal_color.b, p.portal_color.a]
	
	# Ground Items
	for i in range(ground_items.size()):
		var it := ground_items[i]
		var it_name := "Item_%d_%s" % [it.item_id, it.item_name.replace(" ", "_").validate_node_name()]
		out += "[node name=\"%s\" type=\"Node2D\" parent=\"Entities\"]\n" % it_name
		out += "position = Vector2(%d, %d)\n" % [int(it.world_position.x), int(it.world_position.y)]
		out += "script = ExtResource(\"7_ground_item\")\n"
		out += "item_id = %d\n" % it.item_id
		out += "slot = %d\n" % it.slot
		out += "item_name = \"%s\"\n" % it.item_name.c_escape()
		out += "respawn_seconds = %.1f\n\n" % it.respawn_seconds
	
	# NPCs
	for i in range(npcs.size()):
		var n := npcs[i]
		var n_name := "NPC_%d_%s" % [n.npc_id, n.npc_name.replace(" ", "_").validate_node_name()]
		out += "[node name=\"%s\" parent=\"Entities\" instance=ExtResource(\"4_npc\")]\n" % n_name
		out += "npc_id = %d\n" % n.npc_id
		out += "npc_name = \"%s\"\n" % n.npc_name.c_escape()
		if not n.model_jmp.is_empty():
			out += "model_jmp = \"%s\"\n" % n.model_jmp.c_escape()
		if not n.model_jma.is_empty():
			out += "model_jma = \"%s\"\n" % n.model_jma.c_escape()
		out += "world_position = Vector2(%d, %d)\n" % [int(n.world_position.x), int(n.world_position.y)]
		out += "heading = %d\n" % n.heading
		if not n.dialogue_text.is_empty():
			out += "dialogue_text = \"%s\"\n" % n.dialogue_text.c_escape()
		if not n.dialogue_choices.is_empty():
			var choices_esc: Array[String] = []
			for c in n.dialogue_choices:
				choices_esc.append("\"%s\"" % c.c_escape())
			out += "dialogue_choices = [%s]\n" % ", ".join(choices_esc)
		out += "\n"
	
	out += "[node name=\"CanvasLayer\" type=\"CanvasLayer\" parent=\".\"]\n\n"
	out += "[node name=\"HUD\" parent=\"CanvasLayer\" instance=ExtResource(\"5_hud\")]\n"
	
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open scene file for writing: " + target_path)
		return false
	file.store_string(out)
	file.close()
	print("[MapEditor] Successfully exported Godot map scene: %s" % target_path)
	return true

# --- Canvas Drawing Logic ---

func _on_canvas_draw() -> void:
	if not canvas_control:
		return
	
	var canvas_sz := canvas_control.size
	
	# 1. Background checkerboard / neutral fill
	canvas_control.draw_rect(Rect2(Vector2.ZERO, canvas_sz), Color(0.12, 0.14, 0.18, 1.0), true)
	
	# 2. Map Background Texture
	var map_rect_screen := Rect2(pan_offset, Vector2(width_px, height_px) * zoom_level)
	if background_texture:
		canvas_control.draw_texture_rect(background_texture, map_rect_screen, false)
	else:
		canvas_control.draw_rect(map_rect_screen, Color(0.18, 0.22, 0.28, 1.0), true)
	
	# Boundary border
	canvas_control.draw_rect(map_rect_screen, Color(0.4, 0.6, 0.8, 0.8), false, 2.0)
	
	# 3. Calculate visible tile bounds for fast culling
	var top_left_world := screen_to_world(Vector2.ZERO)
	var bottom_right_world := screen_to_world(canvas_sz)
	
	var start_col: int = clampi(int(floor(top_left_world.x / float(tile_scale))), 0, cols - 1)
	var end_col: int = clampi(int(ceil(bottom_right_world.x / float(tile_scale))), 0, cols - 1)
	var start_row: int = clampi(int(floor(top_left_world.y / float(tile_scale))), 0, rows - 1)
	var end_row: int = clampi(int(ceil(bottom_right_world.y / float(tile_scale))), 0, rows - 1)
	
	var tile_size_screen := Vector2(float(tile_scale) * zoom_level, float(tile_scale) * zoom_level)
	
	# 4. Color-coded Collision Grid Overlay
	if show_collision and collision_grid.size() == cols * rows:
		for r in range(start_row, end_row + 1):
			for c in range(start_col, end_col + 1):
				var flag := get_collision_at(c, r)
				if flag == MapData.TileCollisionFlags.WALKABLE and not show_walkable_tiles:
					continue
				var col_color: Color = FLAG_COLORS.get(flag, Color(0.5, 0.5, 0.5, 0.35))
				var tile_screen := world_to_screen(Vector2(c * tile_scale, r * tile_scale))
				canvas_control.draw_rect(Rect2(tile_screen, tile_size_screen), col_color, true)
	
	# 5. Tile Grid Lines
	if show_grid and zoom_level >= 0.25:
		var grid_col := Color(1.0, 1.0, 1.0, 0.12)
		for c in range(start_col, end_col + 2):
			var x_screen := float(c * tile_scale) * zoom_level + pan_offset.x
			var y_start := float(start_row * tile_scale) * zoom_level + pan_offset.y
			var y_end := float((end_row + 1) * tile_scale) * zoom_level + pan_offset.y
			canvas_control.draw_line(Vector2(x_screen, y_start), Vector2(x_screen, y_end), grid_col, 1.0)
		for r in range(start_row, end_row + 2):
			var y_screen := float(r * tile_scale) * zoom_level + pan_offset.y
			var x_start := float(start_col * tile_scale) * zoom_level + pan_offset.x
			var x_end := float((end_col + 1) * tile_scale) * zoom_level + pan_offset.x
			canvas_control.draw_line(Vector2(x_start, y_screen), Vector2(x_end, y_screen), grid_col, 1.0)

	var default_font := get_theme_default_font()
	
	# 6. Portals Overlay
	if show_portals:
		for i in range(portals.size()):
			var p := portals[i]
			var p_scr := world_to_screen(p.world_position)
			var r_scr := p.trigger_radius * zoom_level
			
			# Pulse / transparent circle
			var fill_color := p.portal_color
			fill_color.a = 0.2
			canvas_control.draw_circle(p_scr, r_scr, fill_color)
			canvas_control.draw_arc(p_scr, r_scr, 0.0, TAU, 32, p.portal_color, 2.0)
			
			# Center icon
			canvas_control.draw_rect(Rect2(p_scr - Vector2(6, 6), Vector2(12, 12)), p.portal_color, true)
			
			# Selected highlight
			if selected_entity_type == "portal" and selected_entity_index == i:
				canvas_control.draw_arc(p_scr, r_scr + 4.0, 0.0, TAU, 32, Color.YELLOW, 3.0)
			
			if zoom_level >= 0.35 and default_font:
				var lbl := "#%d: %s -> Map %d" % [p.portal_id, p.portal_name, p.target_map_id]
				canvas_control.draw_string(default_font, p_scr + Vector2(10, -8), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

	# 7. Ground Items Overlay
	if show_items:
		for i in range(ground_items.size()):
			var it := ground_items[i]
			var it_scr := world_to_screen(it.world_position)
			var item_col := Color(1.0, 0.85, 0.2, 0.9)
			canvas_control.draw_rect(Rect2(it_scr - Vector2(8, 8), Vector2(16, 16)), item_col, true)
			canvas_control.draw_rect(Rect2(it_scr - Vector2(8, 8), Vector2(16, 16)), Color.WHITE, false, 1.5)
			
			if selected_entity_type == "item" and selected_entity_index == i:
				canvas_control.draw_arc(it_scr, 14.0, 0.0, TAU, 24, Color.YELLOW, 3.0)
			
			if zoom_level >= 0.35 and default_font:
				var lbl := "%s (#%d)" % [it.item_name, it.item_id]
				canvas_control.draw_string(default_font, it_scr + Vector2(12, 5), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.95, 0.6))

	# 8. NPCs Overlay
	if show_npcs:
		for i in range(npcs.size()):
			var n := npcs[i]
			var n_scr := world_to_screen(n.world_position)
			var npc_col := Color(0.2, 0.7, 1.0, 0.75)
			var n_radius := 14.0 * clampf(zoom_level, 0.6, 1.8)
			canvas_control.draw_circle(n_scr, n_radius, npc_col)
			canvas_control.draw_arc(n_scr, n_radius, 0.0, TAU, 24, Color(0.85, 0.95, 1.0), 2.0)
			
			# Heading direction indicator
			var heading_dir := heading_to_dir_vector(n.heading)
			var arrow_end := n_scr + heading_dir * (n_radius + 10.0)
			canvas_control.draw_line(n_scr, arrow_end, Color.YELLOW, 2.5)
			
			if selected_entity_type == "npc" and selected_entity_index == i:
				canvas_control.draw_arc(n_scr, n_radius + 4.0, 0.0, TAU, 24, Color.YELLOW, 3.0)
			
			if zoom_level >= 0.35 and default_font:
				var lbl := "%s (#%d)" % [n.npc_name, n.npc_id]
				canvas_control.draw_string(default_font, n_scr + Vector2(16, 5), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.9, 1.0))

	# 9. Player Spawn Marker
	var spawn_scr := world_to_screen(player_spawn_pos)
	canvas_control.draw_circle(spawn_scr, 8.0, Color.MAGENTA)
	canvas_control.draw_arc(spawn_scr, 12.0, 0.0, TAU, 16, Color.WHITE, 1.5)
	if default_font:
		canvas_control.draw_string(default_font, spawn_scr + Vector2(12, -4), "Player Spawn", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.MAGENTA)

	# 10. Hover & Tool Previews
	if is_mouse_over_canvas:
		match active_tool:
			ToolMode.PAINT, ToolMode.ERASER:
				var flag_to_paint := active_collision_flag if active_tool == ToolMode.PAINT else MapData.TileCollisionFlags.WALKABLE
				var half := brush_size / 2
				var preview_top_left := world_to_screen(Vector2((hover_grid_pos.x - half) * tile_scale, (hover_grid_pos.y - half) * tile_scale))
				var preview_sz := Vector2(brush_size * tile_scale * zoom_level, brush_size * tile_scale * zoom_level)
				var prev_col: Color = FLAG_COLORS.get(flag_to_paint, Color.WHITE)
				prev_col.a = 0.4
				canvas_control.draw_rect(Rect2(preview_top_left, preview_sz), prev_col, true)
				canvas_control.draw_rect(Rect2(preview_top_left, preview_sz), Color.WHITE, false, 1.5)
			
			ToolMode.RECT_FILL:
				if is_rect_filling:
					var min_c := mini(rect_fill_start_grid.x, hover_grid_pos.x)
					var max_c := maxi(rect_fill_start_grid.x, hover_grid_pos.x)
					var min_r := mini(rect_fill_start_grid.y, hover_grid_pos.y)
					var max_r := maxi(rect_fill_start_grid.y, hover_grid_pos.y)
					var r_top_left := world_to_screen(Vector2(min_c * tile_scale, min_r * tile_scale))
					var r_sz := Vector2((max_c - min_c + 1) * tile_scale * zoom_level, (max_r - min_r + 1) * tile_scale * zoom_level)
					var fill_prev_col: Color = FLAG_COLORS.get(active_collision_flag, Color.WHITE)
					fill_prev_col.a = 0.45
					canvas_control.draw_rect(Rect2(r_top_left, r_sz), fill_prev_col, true)
					canvas_control.draw_rect(Rect2(r_top_left, r_sz), Color.YELLOW, false, 2.0)
				else:
					var hover_tl := world_to_screen(Vector2(hover_grid_pos.x * tile_scale, hover_grid_pos.y * tile_scale))
					canvas_control.draw_rect(Rect2(hover_tl, tile_size_screen), Color(1, 1, 1, 0.5), false, 2.0)
			
			ToolMode.FLOOD_FILL:
				var hover_tl := world_to_screen(Vector2(hover_grid_pos.x * tile_scale, hover_grid_pos.y * tile_scale))
				canvas_control.draw_rect(Rect2(hover_tl, tile_size_screen), Color(0.2, 1.0, 0.4, 0.6), false, 2.0)
			
			ToolMode.PLACE_PORTAL:
				var p_rad := (portal_radius_spin.value if portal_radius_spin else 56.0) * zoom_level
				canvas_control.draw_arc(hover_screen_pos, p_rad, 0.0, TAU, 32, Color(0.2, 0.8, 1.0, 0.8), 2.0)
				canvas_control.draw_circle(hover_screen_pos, 5.0, Color.CYAN)
			
			ToolMode.PLACE_ITEM:
				canvas_control.draw_rect(Rect2(hover_screen_pos - Vector2(8, 8), Vector2(16, 16)), Color(1.0, 0.8, 0.2, 0.6), true)
			
			ToolMode.PLACE_NPC:
				canvas_control.draw_circle(hover_screen_pos, 14.0 * zoom_level, Color(0.2, 0.7, 1.0, 0.6))

# --- Canvas Input & Interaction ---

func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		
		# Zooming via mouse wheel
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			set_zoom(zoom_level * 1.15, mb.position)
			return
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			set_zoom(zoom_level / 1.15, mb.position)
			return
		
		# Right-click or middle-click panning
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = mb.pressed
			return
		
		# Left-click tool actions
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var world_click := screen_to_world(mb.position)
			var grid_click := world_to_grid(world_click)
			
			if mb.pressed:
				match active_tool:
					ToolMode.SELECT:
						_handle_select_click(world_click)
					ToolMode.PAINT:
						is_painting = true
						_paint_stroke_before = collision_grid.duplicate()
						paint_brush(grid_click.x, grid_click.y, active_collision_flag, brush_size)
						_update_stats()
						canvas_control.queue_redraw()
					ToolMode.ERASER:
						is_painting = true
						_paint_stroke_before = collision_grid.duplicate()
						paint_brush(grid_click.x, grid_click.y, MapData.TileCollisionFlags.WALKABLE, brush_size)
						_update_stats()
						canvas_control.queue_redraw()
					ToolMode.RECT_FILL:
						is_rect_filling = true
						_paint_stroke_before = collision_grid.duplicate()
						rect_fill_start_grid = grid_click
						canvas_control.queue_redraw()
					ToolMode.FLOOD_FILL:
						var before := collision_grid.duplicate()
						flood_fill(grid_click.x, grid_click.y, active_collision_flag)
						if before != collision_grid:
							record_action({"type": "collision", "before": before, "after": collision_grid.duplicate()})
						_update_stats()
						canvas_control.queue_redraw()
					ToolMode.PLACE_PORTAL:
						var target_id := int(portal_target_map_spin.value) if portal_target_map_spin else 10002
						var dest := Vector2(portal_dest_x_spin.value, portal_dest_y_spin.value) if portal_dest_x_spin else Vector2(500, 500)
						var r_val := float(portal_radius_spin.value) if portal_radius_spin else 56.0
						var col_val := portal_color_picker.color if portal_color_picker else Color(0.2, 0.75, 1.0, 0.85)
						var p_name := portal_name_edit.text if portal_name_edit else "Portal"
						add_portal(world_click, target_id, dest, p_name, r_val, col_val)
					ToolMode.PLACE_ITEM:
						var item_id := int(item_id_spin.value) if item_id_spin else 46113
						var it_name := item_name_edit.text if item_name_edit else "Shell"
						var slot := int(item_slot_spin.value) if item_slot_spin else 1
						var respawn := float(item_respawn_spin.value) if item_respawn_spin else 120.0
						add_ground_item(world_click, item_id, it_name, slot, respawn)
					ToolMode.PLACE_NPC:
						var npc_id := int(npc_id_spin.value) if npc_id_spin else 14001
						var npc_name := npc_name_edit.text if npc_name_edit else "NPC"
						var jmp := npc_jmp_edit.text if npc_jmp_edit else "1037.jmp"
						var jma := npc_jma_edit.text if npc_jma_edit else "001.jma"
						var heading := npc_heading_select.selected if npc_heading_select else IsometricMath.Heading.SOUTH
						var dialogue := npc_dialogue_edit.text if npc_dialogue_edit else ""
						var choices: Array[String] = []
						if npc_choices_edit and not npc_choices_edit.text.is_empty():
							for c in npc_choices_edit.text.split(","):
								choices.append(c.strip_edges())
						add_npc(world_click, npc_id, npc_name, jmp, jma, heading, dialogue, choices)
					ToolMode.PAN:
						is_panning = true
			else:
				# Left-click released
				if is_painting:
					is_painting = false
					if _paint_stroke_before != collision_grid:
						record_action({"type": "collision", "before": _paint_stroke_before, "after": collision_grid.duplicate()})
				if is_rect_filling:
					is_rect_filling = false
					rect_fill(rect_fill_start_grid, grid_click, active_collision_flag)
					if _paint_stroke_before != collision_grid:
						record_action({"type": "collision", "before": _paint_stroke_before, "after": collision_grid.duplicate()})
					_update_stats()
					canvas_control.queue_redraw()
				if is_dragging_entity:
					is_dragging_entity = false
					var new_pos := _get_selected_entity_position()
					if new_pos != _drag_start_pos and selected_entity_index >= 0:
						record_action({
							"type": "move_entity",
							"entity_type": selected_entity_type,
							"index": selected_entity_index,
							"old_pos": _drag_start_pos,
							"new_pos": new_pos
						})
	
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		hover_screen_pos = mm.position
		hover_world_pos = screen_to_world(hover_screen_pos)
		hover_grid_pos = world_to_grid(hover_world_pos)
		
		if is_panning:
			pan_offset += mm.relative
			canvas_control.queue_redraw()
		elif is_painting:
			var flag := active_collision_flag if active_tool == ToolMode.PAINT else MapData.TileCollisionFlags.WALKABLE
			paint_brush(hover_grid_pos.x, hover_grid_pos.y, flag, brush_size)
			_update_stats()
			canvas_control.queue_redraw()
		elif is_dragging_entity:
			_apply_entity_drag(hover_world_pos)
			canvas_control.queue_redraw()
		else:
			canvas_control.queue_redraw()
		
		_update_status_bar()

func _handle_select_click(click_world: Vector2) -> void:
	# 1. Check Portals
	for i in range(portals.size() - 1, -1, -1):
		var p := portals[i]
		if p.world_position.distance_to(click_world) <= p.trigger_radius:
			selected_entity_type = "portal"
			selected_entity_index = i
			_drag_start_pos = p.world_position
			is_dragging_entity = true
			drag_offset = p.world_position - click_world
			_populate_portal_form(p)
			if tab_container:
				tab_container.current_tab = 2 # Portals Tab
			if portal_item_list:
				portal_item_list.select(i)
			canvas_control.queue_redraw()
			return
	
	# 2. Check Ground Items
	for i in range(ground_items.size() - 1, -1, -1):
		var it := ground_items[i]
		if it.world_position.distance_to(click_world) <= 24.0:
			selected_entity_type = "item"
			selected_entity_index = i
			_drag_start_pos = it.world_position
			is_dragging_entity = true
			drag_offset = it.world_position - click_world
			_populate_item_form(it)
			if tab_container:
				tab_container.current_tab = 3 # Items Tab
			if item_item_list:
				item_item_list.select(i)
			canvas_control.queue_redraw()
			return
	
	# 3. Check NPCs
	for i in range(npcs.size() - 1, -1, -1):
		var n := npcs[i]
		if n.world_position.distance_to(click_world) <= 28.0:
			selected_entity_type = "npc"
			selected_entity_index = i
			_drag_start_pos = n.world_position
			is_dragging_entity = true
			drag_offset = n.world_position - click_world
			_populate_npc_form(n)
			if tab_container:
				tab_container.current_tab = 4 # NPCs Tab
			if npc_item_list:
				npc_item_list.select(i)
			canvas_control.queue_redraw()
			return
	
	# Deselect if clicked empty ground
	selected_entity_type = ""
	selected_entity_index = -1
	canvas_control.queue_redraw()

func _apply_entity_drag(new_world_pos: Vector2) -> void:
	var target_pos := new_world_pos + drag_offset
	match selected_entity_type:
		"portal":
			if selected_entity_index >= 0 and selected_entity_index < portals.size():
				portals[selected_entity_index].world_position = target_pos
				refresh_portal_list()
		"item":
			if selected_entity_index >= 0 and selected_entity_index < ground_items.size():
				ground_items[selected_entity_index].world_position = target_pos
				refresh_ground_item_list()
		"npc":
			if selected_entity_index >= 0 and selected_entity_index < npcs.size():
				npcs[selected_entity_index].world_position = target_pos
				refresh_npc_list()

func _on_canvas_mouse_entered() -> void:
	is_mouse_over_canvas = true
	if canvas_control:
		canvas_control.queue_redraw()

func _on_canvas_mouse_exited() -> void:
	is_mouse_over_canvas = false
	is_panning = false
	is_painting = false
	is_dragging_entity = false
	if canvas_control:
		canvas_control.queue_redraw()

func _get_selected_entity_position() -> Vector2:
	if selected_entity_index < 0:
		return Vector2.ZERO
	match selected_entity_type:
		"portal":
			if selected_entity_index < portals.size():
				return portals[selected_entity_index].world_position
		"item":
			if selected_entity_index < ground_items.size():
				return ground_items[selected_entity_index].world_position
		"npc":
			if selected_entity_index < npcs.size():
				return npcs[selected_entity_index].world_position
	return Vector2.ZERO

# --- Undo / Redo History Operations ---

func record_action(action: Dictionary) -> void:
	undo_stack.append(action)
	if undo_stack.size() > MAX_UNDO_LEVELS:
		undo_stack.pop_front()
	redo_stack.clear()

func undo() -> bool:
	if undo_stack.is_empty():
		return false
	var action: Dictionary = undo_stack.pop_back()
	_apply_undo_action(action)
	redo_stack.append(action)
	_update_stats()
	if canvas_control:
		canvas_control.queue_redraw()
	return true

func redo() -> bool:
	if redo_stack.is_empty():
		return false
	var action: Dictionary = redo_stack.pop_back()
	_apply_redo_action(action)
	undo_stack.append(action)
	_update_stats()
	if canvas_control:
		canvas_control.queue_redraw()
	return true

func _apply_undo_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"collision":
			var before: PackedByteArray = action.get("before", PackedByteArray())
			if before.size() == collision_grid.size():
				collision_grid = before.duplicate()
		"add_portal":
			var idx: int = action.get("index", portals.size() - 1)
			if idx >= 0 and idx < portals.size():
				portals.remove_at(idx)
				refresh_portal_list()
		"remove_portal":
			var idx: int = action.get("index", 0)
			var p := PortalEntry.new()
			p.from_dict(action.get("portal", {}))
			idx = clampi(idx, 0, portals.size())
			portals.insert(idx, p)
			refresh_portal_list()
		"add_item":
			var idx: int = action.get("index", ground_items.size() - 1)
			if idx >= 0 and idx < ground_items.size():
				ground_items.remove_at(idx)
				refresh_ground_item_list()
		"remove_item":
			var idx: int = action.get("index", 0)
			var it := GroundItemEntry.new()
			it.from_dict(action.get("item", {}))
			idx = clampi(idx, 0, ground_items.size())
			ground_items.insert(idx, it)
			refresh_ground_item_list()
		"add_npc":
			var idx: int = action.get("index", npcs.size() - 1)
			if idx >= 0 and idx < npcs.size():
				npcs.remove_at(idx)
				refresh_npc_list()
		"remove_npc":
			var idx: int = action.get("index", 0)
			var n := NpcEntry.new()
			n.from_dict(action.get("npc", {}))
			idx = clampi(idx, 0, npcs.size())
			npcs.insert(idx, n)
			refresh_npc_list()
		"move_entity":
			var etype: String = action.get("entity_type", "")
			var idx: int = action.get("index", -1)
			var old_pos: Vector2 = action.get("old_pos", Vector2.ZERO)
			_set_entity_pos(etype, idx, old_pos)

func _apply_redo_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"collision":
			var after: PackedByteArray = action.get("after", PackedByteArray())
			if after.size() == collision_grid.size():
				collision_grid = after.duplicate()
		"add_portal":
			var p := PortalEntry.new()
			p.from_dict(action.get("portal", {}))
			portals.append(p)
			refresh_portal_list()
		"remove_portal":
			var idx: int = action.get("index", 0)
			if idx >= 0 and idx < portals.size():
				portals.remove_at(idx)
				refresh_portal_list()
		"add_item":
			var it := GroundItemEntry.new()
			it.from_dict(action.get("item", {}))
			ground_items.append(it)
			refresh_ground_item_list()
		"remove_item":
			var idx: int = action.get("index", 0)
			if idx >= 0 and idx < ground_items.size():
				ground_items.remove_at(idx)
				refresh_ground_item_list()
		"add_npc":
			var n := NpcEntry.new()
			n.from_dict(action.get("npc", {}))
			npcs.append(n)
			refresh_npc_list()
		"remove_npc":
			var idx: int = action.get("index", 0)
			if idx >= 0 and idx < npcs.size():
				npcs.remove_at(idx)
				refresh_npc_list()
		"move_entity":
			var etype: String = action.get("entity_type", "")
			var idx: int = action.get("index", -1)
			var new_pos: Vector2 = action.get("new_pos", Vector2.ZERO)
			_set_entity_pos(etype, idx, new_pos)

func _set_entity_pos(etype: String, idx: int, pos: Vector2) -> void:
	match etype:
		"portal":
			if idx >= 0 and idx < portals.size():
				portals[idx].world_position = pos
				refresh_portal_list()
		"item":
			if idx >= 0 and idx < ground_items.size():
				ground_items[idx].world_position = pos
				refresh_ground_item_list()
		"npc":
			if idx >= 0 and idx < npcs.size():
				npcs[idx].world_position = pos
				refresh_npc_list()

# --- Helpers ---

static func heading_to_dir_vector(heading: int) -> Vector2:
	match heading % 8:
		IsometricMath.Heading.NORTH: return Vector2(0, -1)
		IsometricMath.Heading.NORTH_WEST: return Vector2(-0.7071, -0.7071)
		IsometricMath.Heading.WEST: return Vector2(-1, 0)
		IsometricMath.Heading.SOUTH_WEST: return Vector2(-0.7071, 0.7071)
		IsometricMath.Heading.SOUTH: return Vector2(0, 1)
		IsometricMath.Heading.SOUTH_EAST: return Vector2(0.7071, 0.7071)
		IsometricMath.Heading.EAST: return Vector2(1, 0)
		IsometricMath.Heading.NORTH_EAST: return Vector2(0.7071, -0.7071)
	return Vector2(0, 1)

func _update_status_bar() -> void:
	if status_coords:
		status_coords.text = "World: (%d, %d) | Grid: [%d, %d]" % [
			int(hover_world_pos.x), int(hover_world_pos.y),
			hover_grid_pos.x, hover_grid_pos.y
		]
	if status_flag:
		var current_flag := get_collision_at(hover_grid_pos.x, hover_grid_pos.y)
		var f_name: String = FLAG_NAMES.get(current_flag, "Unknown (0x%02X)" % current_flag)
		status_flag.text = "Flag: %s" % f_name
	if status_entities:
		status_entities.text = "Portals: %d | Items: %d | NPCs: %d" % [
			portals.size(), ground_items.size(), npcs.size()
		]
	if status_dimensions:
		status_dimensions.text = "%d x %d px (%d x %d tiles)" % [
			width_px, height_px, cols, rows
		]

func _update_stats() -> void:
	var stats := get_collision_stats()
	var total: int = maxi(stats["total"], 1)
	var walk_pct: float = (float(stats["walkable"]) / float(total)) * 100.0
	var solid_pct: float = (float(stats["solid"]) / float(total)) * 100.0
	var water_pct: float = (float(stats["water"] + stats["sea"] + stats["deep_ocean"]) / float(total)) * 100.0
	if collision_stats_label:
		collision_stats_label.text = "Walkable: %d (%.1f%%)\nSolid Wall: %d (%.1f%%)\nWater/Ocean: %d (%.1f%%)\nTotal Grid: %d tiles" % [
			stats["walkable"], walk_pct,
			stats["solid"], solid_pct,
			stats["water"] + stats["sea"] + stats["deep_ocean"], water_pct,
			stats["total"]
		]

func _update_ui_forms() -> void:
	if map_id_spin:
		map_id_spin.value = map_id
	if map_name_edit:
		map_name_edit.text = map_name
	if width_spin:
		width_spin.value = width_px
	if height_spin:
		height_spin.value = height_px
	if dimensions_label:
		dimensions_label.text = "Dimensions: %d x %d px (%d x %d tiles)" % [width_px, height_px, cols, rows]
	if spawn_x_spin:
		spawn_x_spin.value = player_spawn_pos.x
	if spawn_y_spin:
		spawn_y_spin.value = player_spawn_pos.y

func _populate_portal_form(p: PortalEntry) -> void:
	if portal_id_spin:
		portal_id_spin.value = p.portal_id
	if portal_name_edit:
		portal_name_edit.text = p.portal_name
	if portal_target_map_spin:
		portal_target_map_spin.value = p.target_map_id
	if portal_dest_x_spin:
		portal_dest_x_spin.value = p.target_coords.x
	if portal_dest_y_spin:
		portal_dest_y_spin.value = p.target_coords.y
	if portal_radius_spin:
		portal_radius_spin.value = p.trigger_radius
	if portal_color_picker:
		portal_color_picker.color = p.portal_color

func _populate_item_form(it: GroundItemEntry) -> void:
	if item_id_spin:
		item_id_spin.value = it.item_id
	if item_name_edit:
		item_name_edit.text = it.item_name
	if item_slot_spin:
		item_slot_spin.value = it.slot
	if item_respawn_spin:
		item_respawn_spin.value = it.respawn_seconds

func _populate_npc_form(n: NpcEntry) -> void:
	if npc_id_spin:
		npc_id_spin.value = n.npc_id
	if npc_name_edit:
		npc_name_edit.text = n.npc_name
	if npc_jmp_edit:
		npc_jmp_edit.text = n.model_jmp
	if npc_jma_edit:
		npc_jma_edit.text = n.model_jma
	if npc_heading_select:
		npc_heading_select.selected = n.heading
	if npc_dialogue_edit:
		npc_dialogue_edit.text = n.dialogue_text
	if npc_choices_edit:
		npc_choices_edit.text = ", ".join(n.dialogue_choices)

# --- Presets & Options Setup ---

func _setup_presets() -> void:
	if not preset_select:
		return
	
	_all_preset_maps.clear()
	var gdb = get_node_or_null("/root/GameDatabase")
	if gdb and gdb.scenes:
		for mid in gdb.scenes.get_all_scenes():
			var sc = gdb.scenes.get_scene(mid)
			_all_preset_maps[mid] = sc.name if (sc and not sc.name.is_empty()) else ("Map %d" % mid)
	else:
		var sdb = SceneDatabase.new()
		var s_path := "res://assets/data/SceneData.dat"
		if not FileAccess.file_exists(s_path): s_path = "D:/GitHub/WLRI/data/SceneData.dat"
		if sdb.load_from_file(s_path):
			for mid in sdb.get_all_scenes():
				var sc = sdb.get_scene(mid)
				_all_preset_maps[mid] = sc.name if (sc and not sc.name.is_empty()) else ("Map %d" % mid)
	
	var eve := EveParser.new()
	for mid in eve.get_all_map_ids():
		if not _all_preset_maps.has(mid):
			_all_preset_maps[mid] = "Map %d" % mid
	
	var canonical_names: Dictionary = {
		10001: "Ship Deck",
		10002: "Ship Cabin",
		10003: "Deserted Island",
		10005: "Kelan Trail",
		10007: "Kelan Village",
		10011: "Beach Awakening",
		12001: "Holy Village",
		20001: "Kelan Village"
	}
	for cid in canonical_names:
		_all_preset_maps[cid] = canonical_names[cid]
	
	_populate_preset_dropdown("")

func _populate_preset_dropdown(filter_text: String = "") -> void:
	if not preset_select:
		return
	preset_select.clear()
	var query := filter_text.strip_edges().to_lower()
	var sorted_mids: Array = _all_preset_maps.keys()
	sorted_mids.sort()
	
	for mid in sorted_mids:
		var mname: String = str(_all_preset_maps[mid])
		var entry_text := "%d - %s" % [mid, mname]
		if query.is_empty() or str(mid).contains(query) or mname.to_lower().contains(query):
			preset_select.add_item(entry_text, mid)
	
	for i in range(preset_select.item_count):
		if preset_select.get_item_id(i) == map_id:
			preset_select.selected = i
			break

func _setup_options() -> void:
	# Active Tool
	if tool_select:
		tool_select.clear()
		tool_select.add_item("Paint Brush", ToolMode.PAINT)
		tool_select.add_item("Eraser (Walkable)", ToolMode.ERASER)
		tool_select.add_item("Rectangle Fill", ToolMode.RECT_FILL)
		tool_select.add_item("Flood Fill", ToolMode.FLOOD_FILL)
		tool_select.add_item("Select & Move", ToolMode.SELECT)
		tool_select.selected = 0
	
	# Collision Flags
	if collision_flag_select:
		collision_flag_select.clear()
		collision_flag_select.add_item("Solid Wall (0x01)", MapData.TileCollisionFlags.SOLID_WALL)
		collision_flag_select.add_item("Walkable (0x00)", MapData.TileCollisionFlags.WALKABLE)
		collision_flag_select.add_item("Water (0x08)", MapData.TileCollisionFlags.WATER)
		collision_flag_select.add_item("Sea (0x02)", MapData.TileCollisionFlags.SEA)
		collision_flag_select.add_item("Deep Ocean (0x04)", MapData.TileCollisionFlags.DEEP_OCEAN)
		collision_flag_select.add_item("Mountain (0x10)", MapData.TileCollisionFlags.MOUNTAIN)
		collision_flag_select.add_item("Shallow Water (0x40)", MapData.TileCollisionFlags.SHALLOW_WATER)
		collision_flag_select.add_item("Hot Spring (0x80)", MapData.TileCollisionFlags.HOT_SPRING)
		collision_flag_select.selected = 0

	# Brush Sizes
	if brush_size_select:
		brush_size_select.clear()
		brush_size_select.add_item("1x1 Tile (20px)", 1)
		brush_size_select.add_item("3x3 Tiles (60px)", 3)
		brush_size_select.add_item("5x5 Tiles (100px)", 5)
		brush_size_select.add_item("7x7 Tiles (140px)", 7)
		brush_size_select.selected = 0

	# Quick Items
	if quick_item_select:
		quick_item_select.clear()
		quick_item_select.add_item("Custom Item ID...", 0)
		quick_item_select.add_item("46113: Shell", 46113)
		quick_item_select.add_item("41066: Coconut", 41066)
		quick_item_select.add_item("10002: Plate", 10002)
		quick_item_select.add_item("46101: Common Clay", 46101)
		quick_item_select.add_item("41001: Wood", 41001)
		quick_item_select.add_item("42001: Iron Ore", 42001)
		quick_item_select.add_item("45001: Pure Water", 45001)

	# Quick NPCs
	if quick_npc_select:
		quick_npc_select.clear()
		quick_npc_select.add_item("Custom NPC...", 0)
		quick_npc_select.add_item("14001: Crew on Deck (1037.jmp)", 14001)
		quick_npc_select.add_item("14003: Captain Robinson (1038.jmp)", 14003)
		quick_npc_select.add_item("14062: Kelang (1131.jmp)", 14062)
		quick_npc_select.add_item("14065: Girl (1009.jmp)", 14065)
		quick_npc_select.add_item("11000: Persian Cat (1035.jmp)", 11000)
		quick_npc_select.add_item("14091: Jack (1010.jmp)", 14091)
		quick_npc_select.add_item("14152: Ross (1207.jmp)", 14152)

	# NPC Headings
	if npc_heading_select:
		npc_heading_select.clear()
		npc_heading_select.add_item("North (Back)", IsometricMath.Heading.NORTH)
		npc_heading_select.add_item("North-West", IsometricMath.Heading.NORTH_WEST)
		npc_heading_select.add_item("West (Left)", IsometricMath.Heading.WEST)
		npc_heading_select.add_item("South-West", IsometricMath.Heading.SOUTH_WEST)
		npc_heading_select.add_item("South (Front)", IsometricMath.Heading.SOUTH)
		npc_heading_select.add_item("South-East", IsometricMath.Heading.SOUTH_EAST)
		npc_heading_select.add_item("East (Right)", IsometricMath.Heading.EAST)
		npc_heading_select.add_item("North-East", IsometricMath.Heading.NORTH_EAST)
		npc_heading_select.selected = IsometricMath.Heading.SOUTH

	# Background Sources
	if bg_source_select:
		bg_source_select.clear()
		bg_source_select.add_item("Archive (map.JMG)", 0)
		bg_source_select.add_item("File on Disk (res:// or absolute)", 1)
		bg_source_select.selected = 0

# --- UI Signals Wiring ---

func _connect_ui_signals() -> void:
	# Top bar actions
	btn_new.pressed.connect(func(): init_empty_map(2000, 2000, 99999, "New Map"))
	btn_load.pressed.connect(func(): load_map_from_id(int(map_id_spin.value)))
	btn_save_binary.pressed.connect(func(): file_dialog_save_binary.popup_centered())
	btn_export_json.pressed.connect(func(): file_dialog_save_json.popup_centered())
	btn_import_json.pressed.connect(func(): file_dialog_load_json.popup_centered())
	btn_export_scene.pressed.connect(func(): file_dialog_save_scene.popup_centered())
	
	# File Dialogs
	file_dialog_save_binary.file_selected.connect(func(p: String): export_mapdata_binary(p))
	file_dialog_save_json.file_selected.connect(func(p: String): export_map_json(p))
	file_dialog_load_json.file_selected.connect(func(p: String): import_map_json(p))
	file_dialog_save_scene.file_selected.connect(func(p: String): export_map_scene(p))
	file_dialog_browse_bg.file_selected.connect(func(p: String):
		bg_path_edit.text = p
		load_map_from_id(int(map_id_spin.value), p)
	)

	# Toggles
	check_grid.toggled.connect(func(v: bool): show_grid = v; canvas_control.queue_redraw())
	check_collision.toggled.connect(func(v: bool): show_collision = v; canvas_control.queue_redraw())
	check_portals.toggled.connect(func(v: bool): show_portals = v; canvas_control.queue_redraw())
	check_items.toggled.connect(func(v: bool): show_items = v; canvas_control.queue_redraw())
	check_npcs.toggled.connect(func(v: bool): show_npcs = v; canvas_control.queue_redraw())
	check_walkable.toggled.connect(func(v: bool): show_walkable_tiles = v; canvas_control.queue_redraw())

	# Zoom & Pan controls
	btn_zoom_in.pressed.connect(func(): set_zoom(zoom_level * 1.2, canvas_control.size * 0.5))
	btn_zoom_out.pressed.connect(func(): set_zoom(zoom_level / 1.2, canvas_control.size * 0.5))
	btn_zoom_reset.pressed.connect(func(): set_zoom(1.0, canvas_control.size * 0.5))
	btn_recenter.pressed.connect(recenter_canvas)

	# Setup Tab
	preset_select.item_selected.connect(func(_idx: int):
		var sel_id: int = preset_select.get_selected_id()
		if sel_id > 0:
			map_id_spin.value = sel_id
			load_map_from_id(sel_id)
			recenter_canvas()
	)
	btn_load_preset.pressed.connect(func():
		var sel_id: int = preset_select.get_selected_id()
		if sel_id > 0:
			map_id_spin.value = sel_id
			load_map_from_id(sel_id)
			recenter_canvas()
	)
	if map_search_edit:
		map_search_edit.text_changed.connect(func(t: String):
			_populate_preset_dropdown(t)
		)
		map_search_edit.text_submitted.connect(func(t: String):
			var trimmed := t.strip_edges()
			if trimmed.is_valid_int():
				var q_id := trimmed.to_int()
				if _all_preset_maps.has(q_id):
					map_id_spin.value = q_id
					load_map_from_id(q_id)
					recenter_canvas()
			elif preset_select.item_count > 0:
				var first_id: int = preset_select.get_item_id(0)
				map_id_spin.value = first_id
				load_map_from_id(first_id)
				recenter_canvas()
		)
	if map_npc_dock_list:
		map_npc_dock_list.item_selected.connect(func(idx: int):
			if idx >= 0 and idx < npcs.size():
				selected_entity_type = "npc"
				selected_entity_index = idx
				_populate_npc_form(npcs[idx])
				if canvas_control:
					var world_p: Vector2 = npcs[idx].world_position
					pan_offset = canvas_control.size * 0.5 - world_p * zoom_level
					canvas_control.queue_redraw()
		)
	btn_browse_bg.pressed.connect(func(): file_dialog_browse_bg.popup_centered())
	btn_load_bg.pressed.connect(func():
		load_map_from_id(int(map_id_spin.value), bg_path_edit.text.strip_edges())
		recenter_canvas()
	)
	btn_resize_grid.pressed.connect(func():
		resize_map_grid(int(width_spin.value), int(height_spin.value))
	)
	btn_spawn_center.pressed.connect(func():
		player_spawn_pos = Vector2(float(width_px) * 0.5, float(height_px) * 0.5)
		spawn_x_spin.value = player_spawn_pos.x
		spawn_y_spin.value = player_spawn_pos.y
		canvas_control.queue_redraw()
	)
	spawn_x_spin.value_changed.connect(func(v: float): player_spawn_pos.x = v; canvas_control.queue_redraw())
	spawn_y_spin.value_changed.connect(func(v: float): player_spawn_pos.y = v; canvas_control.queue_redraw())
	map_name_edit.text_changed.connect(func(t: String): map_name = t)

	# Collision Tab
	tool_select.item_selected.connect(func(idx: int): active_tool = tool_select.get_item_id(idx) as ToolMode)
	collision_flag_select.item_selected.connect(func(idx: int): active_collision_flag = collision_flag_select.get_item_id(idx))
	brush_size_select.item_selected.connect(func(idx: int): brush_size = brush_size_select.get_item_id(idx))
	btn_fill_all.pressed.connect(func(): fill_all(active_collision_flag))
	btn_clear_collision.pressed.connect(clear_collision)
	btn_invert_collision.pressed.connect(invert_collision)

	# Portals Tab
	btn_place_portal_mode.pressed.connect(func():
		active_tool = ToolMode.PLACE_PORTAL
		status_help.text = "Click anywhere on map to place a Warp Portal."
	)
	btn_add_portal.pressed.connect(func():
		var target_id := int(portal_target_map_spin.value)
		var dest := Vector2(portal_dest_x_spin.value, portal_dest_y_spin.value)
		var r_val := float(portal_radius_spin.value)
		var col_val := portal_color_picker.color
		var p_name := portal_name_edit.text
		if selected_entity_type == "portal" and selected_entity_index >= 0 and selected_entity_index < portals.size():
			var p := portals[selected_entity_index]
			p.portal_id = int(portal_id_spin.value)
			p.portal_name = p_name
			p.target_map_id = target_id
			p.target_coords = dest
			p.trigger_radius = r_val
			p.portal_color = col_val
			refresh_portal_list()
			canvas_control.queue_redraw()
		else:
			add_portal(hover_world_pos, target_id, dest, p_name, r_val, col_val)
	)
	btn_delete_portal.pressed.connect(func():
		if selected_entity_type == "portal":
			remove_portal(selected_entity_index)
	)
	portal_item_list.item_selected.connect(func(idx: int):
		if idx >= 0 and idx < portals.size():
			selected_entity_type = "portal"
			selected_entity_index = idx
			_populate_portal_form(portals[idx])
			canvas_control.queue_redraw()
	)

	# Ground Items Tab
	btn_place_item_mode.pressed.connect(func():
		active_tool = ToolMode.PLACE_ITEM
		status_help.text = "Click anywhere on map to place an Item Spawner."
	)
	quick_item_select.item_selected.connect(func(idx: int):
		var i_id: int = quick_item_select.get_item_id(idx)
		if i_id > 0:
			item_id_spin.value = i_id
			var txt := quick_item_select.get_item_text(idx)
			var parts := txt.split(":")
			if parts.size() > 1:
				item_name_edit.text = parts[1].strip_edges()
	)
	item_id_spin.value_changed.connect(func(v: float):
		var gdb = get_node_or_null("/root/GameDatabase")
		if gdb and gdb.items:
			var rec = gdb.items.get_item(int(v))
			if rec and not rec.name.is_empty():
				item_name_edit.text = rec.name
	)
	btn_add_item.pressed.connect(func():
		var i_id := int(item_id_spin.value)
		var i_name := item_name_edit.text
		var slot := int(item_slot_spin.value)
		var respawn := float(item_respawn_spin.value)
		if selected_entity_type == "item" and selected_entity_index >= 0 and selected_entity_index < ground_items.size():
			var it := ground_items[selected_entity_index]
			it.item_id = i_id
			it.item_name = i_name
			it.slot = slot
			it.respawn_seconds = respawn
			refresh_ground_item_list()
			canvas_control.queue_redraw()
		else:
			add_ground_item(hover_world_pos, i_id, i_name, slot, respawn)
	)
	btn_delete_item.pressed.connect(func():
		if selected_entity_type == "item":
			remove_ground_item(selected_entity_index)
	)
	item_item_list.item_selected.connect(func(idx: int):
		if idx >= 0 and idx < ground_items.size():
			selected_entity_type = "item"
			selected_entity_index = idx
			_populate_item_form(ground_items[idx])
			canvas_control.queue_redraw()
	)

	# NPCs Tab
	btn_place_npc_mode.pressed.connect(func():
		active_tool = ToolMode.PLACE_NPC
		status_help.text = "Click anywhere on map to place an NPC Entity."
	)
	quick_npc_select.item_selected.connect(func(idx: int):
		var n_id: int = quick_npc_select.get_item_id(idx)
		if n_id > 0:
			npc_id_spin.value = n_id
			match n_id:
				14001: npc_name_edit.text = "Crew on Deck"; npc_jmp_edit.text = "1037.jmp"
				14003: npc_name_edit.text = "Captain Robinson"; npc_jmp_edit.text = "1038.jmp"
				14062: npc_name_edit.text = "Kelang"; npc_jmp_edit.text = "1131.jmp"
				14065: npc_name_edit.text = "Girl"; npc_jmp_edit.text = "1009.jmp"
				11000: npc_name_edit.text = "Persian Cat"; npc_jmp_edit.text = "1035.jmp"
				14091: npc_name_edit.text = "Jack"; npc_jmp_edit.text = "1010.jmp"
				14152: npc_name_edit.text = "Ross"; npc_jmp_edit.text = "1207.jmp"
	)
	npc_id_spin.value_changed.connect(func(v: float):
		var gdb = get_node_or_null("/root/GameDatabase")
		if gdb and gdb.npcs:
			var rec = gdb.npcs.get_npc(int(v))
			if rec and not rec.name.is_empty():
				npc_name_edit.text = rec.name
	)
	btn_add_npc.pressed.connect(func():
		var n_id := int(npc_id_spin.value)
		var n_name := npc_name_edit.text
		var jmp := npc_jmp_edit.text
		var jma := npc_jma_edit.text
		var heading := npc_heading_select.selected
		var dialogue := npc_dialogue_edit.text
		var choices: Array[String] = []
		if not npc_choices_edit.text.is_empty():
			for c in npc_choices_edit.text.split(","):
				choices.append(c.strip_edges())
		if selected_entity_type == "npc" and selected_entity_index >= 0 and selected_entity_index < npcs.size():
			var n := npcs[selected_entity_index]
			n.npc_id = n_id
			n.npc_name = n_name
			n.model_jmp = jmp
			n.model_jma = jma
			n.heading = heading
			n.dialogue_text = dialogue
			n.dialogue_choices = choices
			refresh_npc_list()
			canvas_control.queue_redraw()
		else:
			add_npc(hover_world_pos, n_id, n_name, jmp, jma, heading, dialogue, choices)
	)
	btn_delete_npc.pressed.connect(func():
		if selected_entity_type == "npc":
			remove_npc(selected_entity_index)
	)
	npc_item_list.item_selected.connect(func(idx: int):
		if idx >= 0 and idx < npcs.size():
			selected_entity_type = "npc"
			selected_entity_index = idx
			_populate_npc_form(npcs[idx])
			if canvas_control:
				var world_p: Vector2 = npcs[idx].world_position
				pan_offset = canvas_control.size * 0.5 - world_p * zoom_level
				canvas_control.queue_redraw()
	)
