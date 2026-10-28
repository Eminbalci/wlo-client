class_name TentEditor
extends Control

## Wonderland Online Tent (Player Portable Housing) & Furniture Interior Studio.
## Production-ready, strictly type-hinted visual authoring tool for designing 2:1 axonometric
## tent interiors, placing workbenches, furniture, storage and decor, calculating collision
## and walkability matrices, managing presets, and exporting to standalone Godot 4 scenes.

const IsometricMath = preload("res://scripts/map/isometric_math.gd")

signal layout_saved(file_path: String)
signal layout_loaded(file_path: String)
signal scene_exported(file_path: String)
signal furniture_placed(instance_id: int, furniture_id: int)
signal furniture_removed(instance_id: int)
signal furniture_selected(instance_id: int)
signal furniture_rotated(instance_id: int, new_heading: int)
signal furniture_moved(instance_id: int, new_pos: Vector2i)
signal preset_applied(preset_name: String)
signal walkability_updated(walkable_percentage: float)
signal collision_painted(tile: Vector2i, flag: int)

enum EditMode {
	PLACE = 0,
	SELECT_MOVE = 1,
	ROTATE = 2,
	REMOVE = 3,
	PAINT_COLLISION = 4
}

enum Heading {
	SOUTH = 0,
	WEST = 1,
	NORTH = 2,
	EAST = 3
}

enum CollisionFlag {
	WALKABLE = 0,
	SOLID = 1
}

class FurnitureInstance:
	extends RefCounted

	var instance_id: int = 1
	var furniture_id: int = 101
	var item_id: int = 38001
	var name: String = "Alchemy Apparatus"
	var category: String = "Crafting Workbenches"
	var grid_pos: Vector2i = Vector2i(4, 4)
	var base_grid_size: Vector2i = Vector2i(2, 2)
	var heading: int = Heading.SOUTH
	var is_workbench: bool = true
	var workbench_type: String = "Alchemy"
	var is_walkable: bool = false
	var color: Color = Color(0.3, 0.7, 0.9, 0.85)
	var height_px: float = 28.0

	func get_effective_size() -> Vector2i:
		if heading % 2 == 1:
			return Vector2i(base_grid_size.y, base_grid_size.x)
		return base_grid_size

	func get_occupied_tiles() -> Array[Vector2i]:
		var tiles: Array[Vector2i] = []
		var eff_size: Vector2i = get_effective_size()
		for x in range(eff_size.x):
			for y in range(eff_size.y):
				tiles.append(Vector2i(grid_pos.x + x, grid_pos.y + y))
		return tiles

	func to_dict() -> Dictionary:
		return {
			"instance_id": instance_id,
			"furniture_id": furniture_id,
			"item_id": item_id,
			"name": name,
			"category": category,
			"grid_x": grid_pos.x,
			"grid_y": grid_pos.y,
			"base_width": base_grid_size.x,
			"base_height": base_grid_size.y,
			"heading": heading,
			"is_workbench": is_workbench,
			"workbench_type": workbench_type,
			"is_walkable": is_walkable,
			"color": color.to_html(),
			"height_px": height_px
		}

	func from_dict(d: Dictionary) -> void:
		instance_id = int(d.get("instance_id", 1))
		furniture_id = int(d.get("furniture_id", 0))
		item_id = int(d.get("item_id", 0))
		name = str(d.get("name", "Furniture"))
		category = str(d.get("category", "Furniture"))
		var gx: int = int(d.get("grid_x", 0))
		var gy: int = int(d.get("grid_y", 0))
		grid_pos = Vector2i(gx, gy)
		var bw: int = int(d.get("base_width", 1))
		var bh: int = int(d.get("base_height", 1))
		base_grid_size = Vector2i(bw, bh)
		heading = int(d.get("heading", 0))
		is_workbench = bool(d.get("is_workbench", false))
		workbench_type = str(d.get("workbench_type", ""))
		is_walkable = bool(d.get("is_walkable", false))
		if d.has("color"):
			color = Color.from_string(str(d.get("color")), Color(0.3, 0.7, 0.9, 0.85))
		height_px = float(d.get("height_px", 24.0))

const DEFAULT_TENT_SIZE: Vector2i = Vector2i(16, 16)
const TILE_SIZE: int = IsometricMath.TILE_SCALE

const WALLPAPER_TYPES: Array[String] = [
	"Wood Plank",
	"Stone Brick",
	"Red Floral Wallpaper",
	"Blue Regal Wallpaper",
	"Simple Canvas"
]

const FLOORING_TYPES: Array[String] = [
	"Wood Plank",
	"Marble",
	"Carpet",
	"Tatami",
	"Grass"
]

const FLOORING_COLORS: Dictionary = {
	"Wood Plank": Color(0.48, 0.34, 0.20, 1.0),
	"Marble": Color(0.78, 0.82, 0.86, 1.0),
	"Carpet": Color(0.62, 0.18, 0.24, 1.0),
	"Tatami": Color(0.70, 0.68, 0.44, 1.0),
	"Grass": Color(0.24, 0.54, 0.22, 1.0)
}

const WALLPAPER_COLORS: Dictionary = {
	"Wood Plank": Color(0.36, 0.25, 0.15, 1.0),
	"Stone Brick": Color(0.42, 0.45, 0.49, 1.0),
	"Red Floral Wallpaper": Color(0.66, 0.22, 0.28, 1.0),
	"Blue Regal Wallpaper": Color(0.20, 0.34, 0.58, 1.0),
	"Simple Canvas": Color(0.74, 0.70, 0.60, 1.0)
}

const FURNITURE_CATALOG: Dictionary = {
	101: {
		"furniture_id": 101,
		"item_id": 38001,
		"name": "Alchemy Apparatus",
		"category": "Crafting Workbenches",
		"grid_size": Vector2i(2, 2),
		"is_workbench": true,
		"workbench_type": "Alchemy",
		"is_walkable": false,
		"color": Color(0.25, 0.70, 0.92, 0.9),
		"height_px": 28.0,
		"description": "High-tier alchemical alembic apparatus for synthesizing reagents and elixirs."
	},
	102: {
		"furniture_id": 102,
		"item_id": 38002,
		"name": "Furnace",
		"category": "Crafting Workbenches",
		"grid_size": Vector2i(2, 2),
		"is_workbench": true,
		"workbench_type": "Smelting",
		"is_walkable": false,
		"color": Color(0.92, 0.35, 0.18, 0.9),
		"height_px": 32.0,
		"description": "Refined blast furnace for smelting raw copper, iron, gold ores, and titanium."
	},
	103: {
		"furniture_id": 103,
		"item_id": 38003,
		"name": "Loom",
		"category": "Crafting Workbenches",
		"grid_size": Vector2i(2, 2),
		"is_workbench": true,
		"workbench_type": "Weaving",
		"is_walkable": false,
		"color": Color(0.85, 0.65, 0.25, 0.9),
		"height_px": 26.0,
		"description": "Wooden textile loom used to weave hemp, cotton thread, and silk into fabrics."
	},
	104: {
		"furniture_id": 104,
		"item_id": 38004,
		"name": "Stove",
		"category": "Crafting Workbenches",
		"grid_size": Vector2i(2, 2),
		"is_workbench": true,
		"workbench_type": "Cooking",
		"is_walkable": false,
		"color": Color(0.82, 0.45, 0.20, 0.9),
		"height_px": 24.0,
		"description": "Cast iron kitchen stove for preparing nutritious field meals, soups, and dishes."
	},
	105: {
		"furniture_id": 105,
		"item_id": 38005,
		"name": "Sawmill",
		"category": "Crafting Workbenches",
		"grid_size": Vector2i(2, 2),
		"is_workbench": true,
		"workbench_type": "Carpentry",
		"is_walkable": false,
		"color": Color(0.65, 0.45, 0.25, 0.9),
		"height_px": 26.0,
		"description": "Water-cranked sawbench for processing timber into building blocks and rods."
	},
	106: {
		"furniture_id": 106,
		"item_id": 38006,
		"name": "Potter's Wheel",
		"category": "Crafting Workbenches",
		"grid_size": Vector2i(2, 2),
		"is_workbench": true,
		"workbench_type": "Pottery",
		"is_walkable": false,
		"color": Color(0.75, 0.50, 0.35, 0.9),
		"height_px": 20.0,
		"description": "Foot-driven ceramic wheel for shaping clay pots, tea sets, and water jars."
	},
	201: {
		"furniture_id": 201,
		"item_id": 38101,
		"name": "Simple Bed",
		"category": "Furniture",
		"grid_size": Vector2i(2, 3),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.32, 0.58, 0.78, 0.9),
		"height_px": 16.0,
		"description": "Comfortable wooden single bed for resting and recovering character HP and SP."
	},
	202: {
		"furniture_id": 202,
		"item_id": 38102,
		"name": "Luxury Double Bed",
		"category": "Furniture",
		"grid_size": Vector2i(3, 3),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.76, 0.24, 0.56, 0.9),
		"height_px": 20.0,
		"description": "Spacious double bed with velvet canopy, down comforter, and plush pillows."
	},
	203: {
		"furniture_id": 203,
		"item_id": 38103,
		"name": "Wardrobe",
		"category": "Furniture",
		"grid_size": Vector2i(2, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.52, 0.36, 0.22, 0.9),
		"height_px": 36.0,
		"description": "Tall dark oak wardrobe for hanging spare gear, cloaks, and formal robes."
	},
	204: {
		"furniture_id": 204,
		"item_id": 38104,
		"name": "Dining Table",
		"category": "Furniture",
		"grid_size": Vector2i(2, 2),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.60, 0.44, 0.30, 0.9),
		"height_px": 18.0,
		"description": "Sturdy polished wooden dining table for shared meals and tea ceremonies."
	},
	205: {
		"furniture_id": 205,
		"item_id": 38105,
		"name": "Wooden Chair",
		"category": "Furniture",
		"grid_size": Vector2i(1, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.56, 0.40, 0.26, 0.9),
		"height_px": 20.0,
		"description": "Standard timber chair with straight back support."
	},
	206: {
		"furniture_id": 206,
		"item_id": 38106,
		"name": "Stool",
		"category": "Furniture",
		"grid_size": Vector2i(1, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.50, 0.34, 0.24, 0.9),
		"height_px": 12.0,
		"description": "Compact round wooden stool that can be tucked under any dining table."
	},
	207: {
		"furniture_id": 207,
		"item_id": 38107,
		"name": "Bookshelf",
		"category": "Furniture",
		"grid_size": Vector2i(2, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.44, 0.30, 0.16, 0.9),
		"height_px": 34.0,
		"description": "Tiered bookcase holding alchemy recipes, continent maps, and historic chronicles."
	},
	208: {
		"furniture_id": 208,
		"item_id": 38108,
		"name": "Bathtub",
		"category": "Furniture",
		"grid_size": Vector2i(2, 2),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.86, 0.92, 0.98, 0.9),
		"height_px": 18.0,
		"description": "White porcelain soaking tub for therapeutic bathing and hot spring comfort."
	},
	209: {
		"furniture_id": 209,
		"item_id": 38109,
		"name": "Sleeping Bag",
		"category": "Furniture",
		"grid_size": Vector2i(1, 2),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.32, 0.52, 0.36, 0.9),
		"height_px": 8.0,
		"description": "Compact insulated bedroll for lightweight wilderness camping inside the tent."
	},
	301: {
		"furniture_id": 301,
		"item_id": 38201,
		"name": "Storage Chest",
		"category": "Storage",
		"grid_size": Vector2i(2, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.72, 0.52, 0.22, 0.9),
		"height_px": 16.0,
		"description": "Reinforced wooden storage chest with iron fittings holding up to 50 items."
	},
	302: {
		"furniture_id": 302,
		"item_id": 38202,
		"name": "Cabinet",
		"category": "Storage",
		"grid_size": Vector2i(2, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.54, 0.38, 0.24, 0.9),
		"height_px": 28.0,
		"description": "Multi-compartment storage cabinet for organizing crafting parts and alchemy catalysts."
	},
	303: {
		"furniture_id": 303,
		"item_id": 38203,
		"name": "Safe",
		"category": "Storage",
		"grid_size": Vector2i(1, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.36, 0.40, 0.44, 0.9),
		"height_px": 18.0,
		"description": "Hardened alloy combination safe for locking away precious gems and gold."
	},
	401: {
		"furniture_id": 401,
		"item_id": 38301,
		"name": "Wall Clock",
		"category": "Decor",
		"grid_size": Vector2i(1, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": true,
		"color": Color(0.88, 0.76, 0.38, 0.9),
		"height_px": 14.0,
		"description": "Polished pendulum wall clock displaying server time and in-game day/night state."
	},
	402: {
		"furniture_id": 402,
		"item_id": 38302,
		"name": "Hanging Banner",
		"category": "Decor",
		"grid_size": Vector2i(1, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": true,
		"color": Color(0.82, 0.22, 0.26, 0.9),
		"height_px": 20.0,
		"description": "Tapestry banner emblazoned with heraldic guild and element crests."
	},
	403: {
		"furniture_id": 403,
		"item_id": 38303,
		"name": "Potted Plant",
		"category": "Decor",
		"grid_size": Vector2i(1, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.24, 0.72, 0.32, 0.9),
		"height_px": 22.0,
		"description": "Lush evergreen fern planted in a terracotta pot to purify the tent atmosphere."
	},
	404: {
		"furniture_id": 404,
		"item_id": 38304,
		"name": "Persian Carpet",
		"category": "Decor",
		"grid_size": Vector2i(3, 3),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": true,
		"color": Color(0.72, 0.18, 0.22, 0.7),
		"height_px": 2.0,
		"description": "Intricately woven ornamental silk carpet with floral medallion borders."
	},
	405: {
		"furniture_id": 405,
		"item_id": 38305,
		"name": "Flower Vase",
		"category": "Decor",
		"grid_size": Vector2i(1, 1),
		"is_workbench": false,
		"workbench_type": "",
		"is_walkable": false,
		"color": Color(0.42, 0.82, 0.74, 0.9),
		"height_px": 14.0,
		"description": "Glazed celadon vase with fresh wild blooms picked from coastal meadows."
	}
}

const PRESETS: Dictionary = {
	"Beginner Camping Tent": {
		"tent_name": "Beginner Camping Tent",
		"wallpaper": "Simple Canvas",
		"flooring": "Grass",
		"furniture": [
			{"furniture_id": 209, "grid_x": 3, "grid_y": 3, "heading": 0},
			{"furniture_id": 104, "grid_x": 7, "grid_y": 3, "heading": 0},
			{"furniture_id": 204, "grid_x": 4, "grid_y": 7, "heading": 0},
			{"furniture_id": 206, "grid_x": 3, "grid_y": 7, "heading": 0},
			{"furniture_id": 301, "grid_x": 2, "grid_y": 2, "heading": 0}
		]
	},
	"Alchemist Laboratory": {
		"tent_name": "Alchemist Laboratory",
		"wallpaper": "Stone Brick",
		"flooring": "Marble",
		"furniture": [
			{"furniture_id": 101, "grid_x": 4, "grid_y": 3, "heading": 0},
			{"furniture_id": 102, "grid_x": 8, "grid_y": 3, "heading": 0},
			{"furniture_id": 207, "grid_x": 2, "grid_y": 3, "heading": 1},
			{"furniture_id": 207, "grid_x": 2, "grid_y": 6, "heading": 1},
			{"furniture_id": 301, "grid_x": 2, "grid_y": 9, "heading": 1},
			{"furniture_id": 204, "grid_x": 6, "grid_y": 7, "heading": 0},
			{"furniture_id": 205, "grid_x": 6, "grid_y": 6, "heading": 0},
			{"furniture_id": 403, "grid_x": 11, "grid_y": 3, "heading": 0}
		]
	},
	"Cozy Bedroom Suite": {
		"tent_name": "Cozy Bedroom Suite",
		"wallpaper": "Red Floral Wallpaper",
		"flooring": "Wood Plank",
		"furniture": [
			{"furniture_id": 202, "grid_x": 3, "grid_y": 3, "heading": 0},
			{"furniture_id": 203, "grid_x": 8, "grid_y": 2, "heading": 0},
			{"furniture_id": 404, "grid_x": 5, "grid_y": 7, "heading": 0},
			{"furniture_id": 204, "grid_x": 10, "grid_y": 6, "heading": 0},
			{"furniture_id": 205, "grid_x": 9, "grid_y": 6, "heading": 3},
			{"furniture_id": 208, "grid_x": 3, "grid_y": 9, "heading": 0},
			{"furniture_id": 405, "grid_x": 10, "grid_y": 5, "heading": 0},
			{"furniture_id": 401, "grid_x": 2, "grid_y": 2, "heading": 0}
		]
	}
}

var tent_name: String = "Player Tent"
var tent_size: Vector2i = DEFAULT_TENT_SIZE
var current_wallpaper: String = "Wood Plank"
var current_flooring: String = "Wood Plank"
var current_mode: EditMode = EditMode.PLACE
var current_palette_def_id: int = 101
var placement_heading: int = Heading.SOUTH
var selected_instance_id: int = -1

var placed_furniture: Array[FurnitureInstance] = []
var next_instance_id: int = 1
var custom_collision: Dictionary = {}
var collision_matrix: Dictionary = {}

# --- Undo / Redo History State ---
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const MAX_UNDO_LEVELS: int = 50

var show_grid: bool = true
var show_collision: bool = true
var canvas_zoom: float = 1.0
var canvas_offset: Vector2 = Vector2.ZERO
var hover_tile: Vector2i = Vector2i(-1, -1)
var is_hovering_canvas: bool = false
var _is_panning: bool = false
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_offset: Vector2 = Vector2.ZERO

# UI Controls
var opt_preset: OptionButton = null
var btn_apply_preset: Button = null
var opt_wallpaper: OptionButton = null
var opt_flooring: OptionButton = null
var btn_clear: Button = null
var btn_save: Button = null
var btn_load: Button = null
var btn_export_scene: Button = null

var opt_category: OptionButton = null
var edit_search: LineEdit = null
var list_furniture: ItemList = null
var lbl_palette_name: Label = null
var lbl_palette_item_id: Label = null
var lbl_palette_category: Label = null
var lbl_palette_footprint: Label = null
var lbl_palette_workbench: Label = null
var lbl_palette_desc: Label = null
var btn_quick_place: Button = null

var btn_mode_place: Button = null
var btn_mode_select: Button = null
var btn_mode_rotate: Button = null
var btn_mode_delete: Button = null
var btn_mode_paint_col: Button = null
var check_grid: CheckBox = null
var check_collision: CheckBox = null
var btn_center_view: Button = null
var tent_canvas: Control = null

var edit_tent_name: LineEdit = null
var spin_width: SpinBox = null
var spin_height: SpinBox = null
var btn_resize_tent: Button = null

var lbl_sel_instance: Label = null
var lbl_sel_name: Label = null
var spin_pos_x: SpinBox = null
var spin_pos_y: SpinBox = null
var opt_heading: OptionButton = null
var btn_rotate_sel: Button = null
var btn_delete_sel: Button = null

var lbl_total_furniture: Label = null
var lbl_workbenches: Label = null
var lbl_walkable_pct: Label = null
var bar_walkable: ProgressBar = null
var lbl_status: Label = null

var export_dialog: AcceptDialog = null
var export_text_edit: TextEdit = null

func _ready() -> void:
	custom_minimum_size = Vector2(800, 600)
	_ensure_node_refs()
	_populate_ui_elements()
	_connect_ui_signals()
	recalculate_walkability()
	_update_ui_state()
	_update_palette_selection()

func _ensure_node_refs() -> void:
	opt_preset = get_node_or_null("%PresetOption") as OptionButton
	btn_apply_preset = get_node_or_null("%BtnApplyPreset") as Button
	opt_wallpaper = get_node_or_null("%WallpaperOption") as OptionButton
	opt_flooring = get_node_or_null("%FlooringOption") as OptionButton
	btn_clear = get_node_or_null("%BtnClear") as Button
	btn_save = get_node_or_null("%BtnSave") as Button
	btn_load = get_node_or_null("%BtnLoad") as Button
	btn_export_scene = get_node_or_null("%BtnExportScene") as Button

	opt_category = get_node_or_null("%CategoryOption") as OptionButton
	edit_search = get_node_or_null("%SearchEdit") as LineEdit
	list_furniture = get_node_or_null("%FurnitureList") as ItemList
	lbl_palette_name = get_node_or_null("%LblPaletteName") as Label
	lbl_palette_item_id = get_node_or_null("%LblPaletteItemId") as Label
	lbl_palette_category = get_node_or_null("%LblPaletteCategory") as Label
	lbl_palette_footprint = get_node_or_null("%LblPaletteFootprint") as Label
	lbl_palette_workbench = get_node_or_null("%LblPaletteWorkbench") as Label
	lbl_palette_desc = get_node_or_null("%LblPaletteDesc") as Label
	btn_quick_place = get_node_or_null("%BtnQuickPlace") as Button

	btn_mode_place = get_node_or_null("%BtnModePlace") as Button
	btn_mode_select = get_node_or_null("%BtnModeSelect") as Button
	btn_mode_rotate = get_node_or_null("%BtnModeRotate") as Button
	btn_mode_delete = get_node_or_null("%BtnModeDelete") as Button
	btn_mode_paint_col = get_node_or_null("%BtnModePaintCollision") as Button
	check_grid = get_node_or_null("%CheckGrid") as CheckBox
	check_collision = get_node_or_null("%CheckCollision") as CheckBox
	btn_center_view = get_node_or_null("%BtnCenterView") as Button
	tent_canvas = get_node_or_null("%TentCanvas") as Control

	edit_tent_name = get_node_or_null("%TentNameEdit") as LineEdit
	spin_width = get_node_or_null("%WidthSpin") as SpinBox
	spin_height = get_node_or_null("%HeightSpin") as SpinBox
	btn_resize_tent = get_node_or_null("%BtnResizeTent") as Button

	lbl_sel_instance = get_node_or_null("%SelectedInstanceLabel") as Label
	lbl_sel_name = get_node_or_null("%SelectedNameLabel") as Label
	spin_pos_x = get_node_or_null("%PosXSpin") as SpinBox
	spin_pos_y = get_node_or_null("%PosYSpin") as SpinBox
	opt_heading = get_node_or_null("%HeadingOption") as OptionButton
	btn_rotate_sel = get_node_or_null("%BtnRotateSelected") as Button
	btn_delete_sel = get_node_or_null("%BtnDeleteSelected") as Button

	lbl_total_furniture = get_node_or_null("%TotalFurnitureLabel") as Label
	lbl_workbenches = get_node_or_null("%WorkbenchesLabel") as Label
	lbl_walkable_pct = get_node_or_null("%WalkableTilesLabel") as Label
	bar_walkable = get_node_or_null("%WalkableProgressBar") as ProgressBar
	lbl_status = get_node_or_null("%StatusLabel") as Label

	export_dialog = get_node_or_null("%ExportDialog") as AcceptDialog
	export_text_edit = get_node_or_null("%ExportTextEdit") as TextEdit

func _populate_ui_elements() -> void:
	if opt_preset != null and opt_preset.item_count == 0:
		for p_name in PRESETS.keys():
			opt_preset.add_item(p_name)

	if opt_wallpaper != null and opt_wallpaper.item_count == 0:
		for wp in WALLPAPER_TYPES:
			opt_wallpaper.add_item(wp)
		opt_wallpaper.select(WALLPAPER_TYPES.find(current_wallpaper))

	if opt_flooring != null and opt_flooring.item_count == 0:
		for fl in FLOORING_TYPES:
			opt_flooring.add_item(fl)
		opt_flooring.select(FLOORING_TYPES.find(current_flooring))

	if opt_category != null and opt_category.item_count == 0:
		opt_category.add_item("All Categories")
		opt_category.add_item("Crafting Workbenches")
		opt_category.add_item("Furniture")
		opt_category.add_item("Storage")
		opt_category.add_item("Decor")

	if opt_heading != null and opt_heading.item_count == 0:
		opt_heading.add_item("0 - South (Front)")
		opt_heading.add_item("1 - West (Left)")
		opt_heading.add_item("2 - North (Back)")
		opt_heading.add_item("3 - East (Right)")

	if spin_width != null:
		spin_width.value = tent_size.x
	if spin_height != null:
		spin_height.value = tent_size.y
	if edit_tent_name != null:
		edit_tent_name.text = tent_name

	_refresh_furniture_palette()

func _connect_ui_signals() -> void:
	if btn_apply_preset != null and not btn_apply_preset.pressed.is_connected(_on_btn_apply_preset_pressed):
		btn_apply_preset.pressed.connect(_on_btn_apply_preset_pressed)
	if opt_wallpaper != null and not opt_wallpaper.item_selected.is_connected(_on_opt_wallpaper_selected):
		opt_wallpaper.item_selected.connect(_on_opt_wallpaper_selected)
	if opt_flooring != null and not opt_flooring.item_selected.is_connected(_on_opt_flooring_selected):
		opt_flooring.item_selected.connect(_on_opt_flooring_selected)
	if btn_clear != null and not btn_clear.pressed.is_connected(_on_btn_clear_pressed):
		btn_clear.pressed.connect(_on_btn_clear_pressed)
	if btn_save != null and not btn_save.pressed.is_connected(_on_btn_save_pressed):
		btn_save.pressed.connect(_on_btn_save_pressed)
	if btn_load != null and not btn_load.pressed.is_connected(_on_btn_load_pressed):
		btn_load.pressed.connect(_on_btn_load_pressed)
	if btn_export_scene != null and not btn_export_scene.pressed.is_connected(_on_btn_export_scene_pressed):
		btn_export_scene.pressed.connect(_on_btn_export_scene_pressed)

	if opt_category != null and not opt_category.item_selected.is_connected(_on_opt_category_selected):
		opt_category.item_selected.connect(_on_opt_category_selected)
	if edit_search != null and not edit_search.text_changed.is_connected(_on_search_text_changed):
		edit_search.text_changed.connect(_on_search_text_changed)
	if list_furniture != null and not list_furniture.item_selected.is_connected(_on_furniture_list_item_selected):
		list_furniture.item_selected.connect(_on_furniture_list_item_selected)
	if btn_quick_place != null and not btn_quick_place.pressed.is_connected(_on_btn_quick_place_pressed):
		btn_quick_place.pressed.connect(_on_btn_quick_place_pressed)

	if btn_mode_place != null and not btn_mode_place.pressed.is_connected(func() -> void: set_edit_mode(EditMode.PLACE)):
		btn_mode_place.pressed.connect(func() -> void: set_edit_mode(EditMode.PLACE))
	if btn_mode_select != null and not btn_mode_select.pressed.is_connected(func() -> void: set_edit_mode(EditMode.SELECT_MOVE)):
		btn_mode_select.pressed.connect(func() -> void: set_edit_mode(EditMode.SELECT_MOVE))
	if btn_mode_rotate != null and not btn_mode_rotate.pressed.is_connected(func() -> void: set_edit_mode(EditMode.ROTATE)):
		btn_mode_rotate.pressed.connect(func() -> void: set_edit_mode(EditMode.ROTATE))
	if btn_mode_delete != null and not btn_mode_delete.pressed.is_connected(func() -> void: set_edit_mode(EditMode.REMOVE)):
		btn_mode_delete.pressed.connect(func() -> void: set_edit_mode(EditMode.REMOVE))
	if btn_mode_paint_col != null and not btn_mode_paint_col.pressed.is_connected(func() -> void: set_edit_mode(EditMode.PAINT_COLLISION)):
		btn_mode_paint_col.pressed.connect(func() -> void: set_edit_mode(EditMode.PAINT_COLLISION))

	if check_grid != null and not check_grid.toggled.is_connected(_on_check_grid_toggled):
		check_grid.toggled.connect(_on_check_grid_toggled)
	if check_collision != null and not check_collision.toggled.is_connected(_on_check_collision_toggled):
		check_collision.toggled.connect(_on_check_collision_toggled)
	if btn_center_view != null and not btn_center_view.pressed.is_connected(_on_btn_center_view_pressed):
		btn_center_view.pressed.connect(_on_btn_center_view_pressed)

	if tent_canvas != null:
		if not tent_canvas.draw.is_connected(_on_canvas_draw):
			tent_canvas.draw.connect(_on_canvas_draw)
		if not tent_canvas.gui_input.is_connected(_on_canvas_gui_input):
			tent_canvas.gui_input.connect(_on_canvas_gui_input)
		if not tent_canvas.mouse_exited.is_connected(_on_canvas_mouse_exited):
			tent_canvas.mouse_exited.connect(_on_canvas_mouse_exited)

	if btn_resize_tent != null and not btn_resize_tent.pressed.is_connected(_on_btn_resize_tent_pressed):
		btn_resize_tent.pressed.connect(_on_btn_resize_tent_pressed)
	if btn_rotate_sel != null and not btn_rotate_sel.pressed.is_connected(_on_btn_rotate_sel_pressed):
		btn_rotate_sel.pressed.connect(_on_btn_rotate_sel_pressed)
	if btn_delete_sel != null and not btn_delete_sel.pressed.is_connected(_on_btn_delete_sel_pressed):
		btn_delete_sel.pressed.connect(_on_btn_delete_sel_pressed)
	if opt_heading != null and not opt_heading.item_selected.is_connected(_on_opt_heading_selected):
		opt_heading.item_selected.connect(_on_opt_heading_selected)
	if spin_pos_x != null and not spin_pos_x.value_changed.is_connected(_on_spin_pos_changed):
		spin_pos_x.value_changed.connect(_on_spin_pos_changed)
	if spin_pos_y != null and not spin_pos_y.value_changed.is_connected(_on_spin_pos_changed):
		spin_pos_y.value_changed.connect(_on_spin_pos_changed)

func set_tent_size(new_size: Vector2i) -> void:
	tent_size = Vector2i(maxi(4, new_size.x), maxi(4, new_size.y))
	if spin_width != null:
		spin_width.value = tent_size.x
	if spin_height != null:
		spin_height.value = tent_size.y
	_clamp_furniture_in_bounds()
	recalculate_walkability()
	_redraw_canvas()

func set_wallpaper(wallpaper_name: String) -> void:
	if WALLPAPER_TYPES.has(wallpaper_name):
		current_wallpaper = wallpaper_name
		if opt_wallpaper != null:
			opt_wallpaper.select(WALLPAPER_TYPES.find(wallpaper_name))
		_redraw_canvas()

func set_flooring(flooring_name: String) -> void:
	if FLOORING_TYPES.has(flooring_name):
		current_flooring = flooring_name
		if opt_flooring != null:
			opt_flooring.select(FLOORING_TYPES.find(flooring_name))
		_redraw_canvas()

func set_edit_mode(mode: EditMode) -> void:
	current_mode = mode
	_update_mode_buttons()
	_redraw_canvas()
	if lbl_status != null:
		match current_mode:
			EditMode.PLACE:
				lbl_status.text = "Mode: Place Furniture (Click canvas to place; Right-Click to rotate)."
			EditMode.SELECT_MOVE:
				lbl_status.text = "Mode: Select / Move (Click furniture to select, click tile to move)."
			EditMode.ROTATE:
				lbl_status.text = "Mode: Rotate (Click placed furniture to rotate 90 degrees)."
			EditMode.REMOVE:
				lbl_status.text = "Mode: Delete (Click placed furniture to remove)."
			EditMode.PAINT_COLLISION:
				lbl_status.text = "Mode: Paint Collision (Click tiles to toggle Solid/Walkable)."

func set_palette_item(furniture_def_id: int) -> void:
	if FURNITURE_CATALOG.has(furniture_def_id):
		current_palette_def_id = furniture_def_id
		_update_palette_selection()
		_redraw_canvas()

func place_furniture(furniture_def_id: int, grid_pos: Vector2i, heading: int = Heading.SOUTH) -> FurnitureInstance:
	if not FURNITURE_CATALOG.has(furniture_def_id):
		return null

	var def: Dictionary = FURNITURE_CATALOG[furniture_def_id]
	var base_size: Vector2i = def["grid_size"]
	var eff_size: Vector2i = base_size
	if heading % 2 == 1:
		eff_size = Vector2i(base_size.y, base_size.x)

	if not is_tile_in_bounds(grid_pos) or not is_tile_in_bounds(grid_pos + eff_size - Vector2i(1, 1)):
		if lbl_status != null:
			lbl_status.text = "Error: Cannot place furniture out of bounds."
		return null

	var inst = FurnitureInstance.new()
	inst.instance_id = next_instance_id
	next_instance_id += 1
	inst.furniture_id = def["furniture_id"]
	inst.item_id = def["item_id"]
	inst.name = def["name"]
	inst.category = def["category"]
	inst.grid_pos = grid_pos
	inst.base_grid_size = base_size
	inst.heading = heading
	inst.is_workbench = def["is_workbench"]
	inst.workbench_type = def["workbench_type"]
	inst.is_walkable = def["is_walkable"]
	inst.color = def["color"]
	inst.height_px = def["height_px"]

	placed_furniture.append(inst)
	select_furniture(inst.instance_id)
	recalculate_walkability()
	_update_ui_state()
	_redraw_canvas()
	record_action({"type": "place", "data": inst.to_dict()})

	furniture_placed.emit(inst.instance_id, inst.furniture_id)
	return inst

func rotate_furniture(instance_id: int, clockwise: bool = true) -> bool:
	var inst: FurnitureInstance = get_furniture(instance_id)
	if inst == null:
		return false

	var new_heading: int = (inst.heading + (1 if clockwise else 3)) % 4
	var old_heading: int = inst.heading
	inst.heading = new_heading

	var eff_size: Vector2i = inst.get_effective_size()
	if inst.grid_pos.x + eff_size.x > tent_size.x:
		inst.grid_pos.x = tent_size.x - eff_size.x
	if inst.grid_pos.y + eff_size.y > tent_size.y:
		inst.grid_pos.y = tent_size.y - eff_size.y

	if not is_tile_in_bounds(inst.grid_pos):
		inst.heading = old_heading
		return false

	recalculate_walkability()
	_update_inspector_controls()
	_redraw_canvas()
	record_action({"type": "rotate", "instance_id": instance_id, "old_heading": old_heading, "new_heading": inst.heading})

	furniture_rotated.emit(inst.instance_id, inst.heading)
	return true

func move_furniture(instance_id: int, new_grid_pos: Vector2i) -> bool:
	var inst: FurnitureInstance = get_furniture(instance_id)
	if inst == null:
		return false

	var eff_size: Vector2i = inst.get_effective_size()
	if new_grid_pos.x < 0 or new_grid_pos.y < 0:
		return false
	if new_grid_pos.x + eff_size.x > tent_size.x or new_grid_pos.y + eff_size.y > tent_size.y:
		return false

	var old_pos: Vector2i = inst.grid_pos
	inst.grid_pos = new_grid_pos
	recalculate_walkability()
	_update_inspector_controls()
	_redraw_canvas()
	record_action({"type": "move", "instance_id": instance_id, "old_pos": old_pos, "new_pos": new_grid_pos})

	furniture_moved.emit(inst.instance_id, inst.grid_pos)
	return true

func remove_furniture(instance_id: int) -> bool:
	for i in range(placed_furniture.size()):
		if placed_furniture[i].instance_id == instance_id:
			var f_dict: Dictionary = placed_furniture[i].to_dict()
			placed_furniture.remove_at(i)
			if selected_instance_id == instance_id:
				selected_instance_id = -1
				_update_inspector_controls()
			recalculate_walkability()
			_update_ui_state()
			_redraw_canvas()
			record_action({"type": "remove", "data": f_dict})
			furniture_removed.emit(instance_id)
			return true
	return false

func clear_furniture() -> void:
	placed_furniture.clear()
	selected_instance_id = -1
	_update_inspector_controls()
	recalculate_walkability()
	_update_ui_state()
	_redraw_canvas()

func get_furniture(instance_id: int) -> FurnitureInstance:
	for inst in placed_furniture:
		if inst.instance_id == instance_id:
			return inst
	return null

func get_furniture_at(tile: Vector2i) -> FurnitureInstance:
	for i in range(placed_furniture.size() - 1, -1, -1):
		var inst: FurnitureInstance = placed_furniture[i]
		if inst.get_occupied_tiles().has(tile):
			return inst
	return null

func select_furniture(instance_id: int) -> void:
	selected_instance_id = instance_id
	_update_inspector_controls()
	_redraw_canvas()
	furniture_selected.emit(instance_id)

func paint_collision(tile: Vector2i, flag: int = CollisionFlag.SOLID) -> void:
	if not is_tile_in_bounds(tile):
		return
	var old_flag: int = custom_collision.get(tile, CollisionFlag.WALKABLE)
	var new_flag: int = CollisionFlag.WALKABLE
	if old_flag == flag:
		custom_collision.erase(tile)
		new_flag = CollisionFlag.WALKABLE
	else:
		custom_collision[tile] = flag
		new_flag = flag
	recalculate_walkability()
	_redraw_canvas()
	record_action({"type": "paint_collision", "tile": tile, "old_flag": old_flag, "new_flag": new_flag})
	collision_painted.emit(tile, flag)

func clear_custom_collision() -> void:
	custom_collision.clear()
	recalculate_walkability()
	_redraw_canvas()

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
	recalculate_walkability()
	_update_ui_state()
	_redraw_canvas()
	return true

func redo() -> bool:
	if redo_stack.is_empty():
		return false
	var action: Dictionary = redo_stack.pop_back()
	_apply_redo_action(action)
	undo_stack.append(action)
	recalculate_walkability()
	_update_ui_state()
	_redraw_canvas()
	return true

func _apply_undo_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"place":
			var data: Dictionary = action.get("data", {})
			var iid: int = int(data.get("instance_id", -1))
			for i in range(placed_furniture.size()):
				if placed_furniture[i].instance_id == iid:
					placed_furniture.remove_at(i)
					break
			if selected_instance_id == iid:
				selected_instance_id = -1
		"remove":
			var data: Dictionary = action.get("data", {})
			var inst = FurnitureInstance.new()
			inst.from_dict(data)
			placed_furniture.append(inst)
		"rotate":
			var iid: int = int(action.get("instance_id", -1))
			var inst: FurnitureInstance = get_furniture(iid)
			if inst:
				inst.heading = int(action.get("old_heading", 0))
		"move":
			var iid: int = int(action.get("instance_id", -1))
			var inst: FurnitureInstance = get_furniture(iid)
			if inst:
				inst.grid_pos = action.get("old_pos", inst.grid_pos)
		"paint_collision":
			var tile: Vector2i = action.get("tile", Vector2i(-1, -1))
			var old_flag: int = int(action.get("old_flag", CollisionFlag.WALKABLE))
			if old_flag == CollisionFlag.WALKABLE:
				custom_collision.erase(tile)
			else:
				custom_collision[tile] = old_flag

func _apply_redo_action(action: Dictionary) -> void:
	match action.get("type", ""):
		"place":
			var data: Dictionary = action.get("data", {})
			var inst = FurnitureInstance.new()
			inst.from_dict(data)
			placed_furniture.append(inst)
		"remove":
			var data: Dictionary = action.get("data", {})
			var iid: int = int(data.get("instance_id", -1))
			for i in range(placed_furniture.size()):
				if placed_furniture[i].instance_id == iid:
					placed_furniture.remove_at(i)
					break
			if selected_instance_id == iid:
				selected_instance_id = -1
		"rotate":
			var iid: int = int(action.get("instance_id", -1))
			var inst: FurnitureInstance = get_furniture(iid)
			if inst:
				inst.heading = int(action.get("new_heading", 0))
		"move":
			var iid: int = int(action.get("instance_id", -1))
			var inst: FurnitureInstance = get_furniture(iid)
			if inst:
				inst.grid_pos = action.get("new_pos", inst.grid_pos)
		"paint_collision":
			var tile: Vector2i = action.get("tile", Vector2i(-1, -1))
			var new_flag: int = int(action.get("new_flag", CollisionFlag.WALKABLE))
			if new_flag == CollisionFlag.WALKABLE:
				custom_collision.erase(tile)
			else:
				custom_collision[tile] = new_flag

func is_tile_in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < tent_size.x and tile.y < tent_size.y

func is_tile_walkable(tile: Vector2i) -> bool:
	if not is_tile_in_bounds(tile):
		return false
	return collision_matrix.get(tile, CollisionFlag.WALKABLE) == CollisionFlag.WALKABLE

func recalculate_walkability() -> void:
	collision_matrix.clear()

	for y in range(tent_size.y):
		for x in range(tent_size.x):
			var t: Vector2i = Vector2i(x, y)
			if custom_collision.has(t):
				collision_matrix[t] = custom_collision[t]
			else:
				collision_matrix[t] = CollisionFlag.WALKABLE

	for inst in placed_furniture:
		if not inst.is_walkable:
			for t in inst.get_occupied_tiles():
				if is_tile_in_bounds(t):
					collision_matrix[t] = CollisionFlag.SOLID

	var stats: Dictionary = get_walkability_stats()
	var pct: float = float(stats["walkable_percentage"])
	walkability_updated.emit(pct)

	if lbl_walkable_pct != null:
		lbl_walkable_pct.text = "Walkable: %d / %d (%.1f%%)" % [stats["walkable_tiles"], stats["total_tiles"], pct]
	if bar_walkable != null:
		bar_walkable.value = pct

func get_walkability_stats() -> Dictionary:
	var total: int = tent_size.x * tent_size.y
	var solid_count: int = 0
	for y in range(tent_size.y):
		for x in range(tent_size.x):
			if collision_matrix.get(Vector2i(x, y), CollisionFlag.WALKABLE) == CollisionFlag.SOLID:
				solid_count += 1
	var walkable_count: int = maxi(0, total - solid_count)
	var pct: float = (float(walkable_count) / float(maxi(1, total))) * 100.0
	return {
		"total_tiles": total,
		"solid_tiles": solid_count,
		"walkable_tiles": walkable_count,
		"walkable_percentage": pct
	}

func apply_preset(preset_name: String) -> bool:
	if not PRESETS.has(preset_name):
		return false

	var p: Dictionary = PRESETS[preset_name]
	clear_furniture()
	custom_collision.clear()

	tent_name = str(p.get("tent_name", preset_name))
	set_wallpaper(str(p.get("wallpaper", "Wood Plank")))
	set_flooring(str(p.get("flooring", "Wood Plank")))

	var items: Array = p.get("furniture", [])
	for item in items:
		var f_id: int = int(item.get("furniture_id", 101))
		var gx: int = int(item.get("grid_x", 0))
		var gy: int = int(item.get("grid_y", 0))
		var h: int = int(item.get("heading", 0))
		place_furniture(f_id, Vector2i(gx, gy), h)

	recalculate_walkability()
	_update_ui_state()
	_redraw_canvas()

	if lbl_status != null:
		lbl_status.text = "Preset '%s' applied successfully." % preset_name

	preset_applied.emit(preset_name)
	return true

func save_tent_layout(path: String) -> bool:
	var furniture_data: Array[Dictionary] = []
	for inst in placed_furniture:
		furniture_data.append(inst.to_dict())

	var custom_col_data: Array[Dictionary] = []
	for tile in custom_collision.keys():
		custom_col_data.append({
			"x": tile.x,
			"y": tile.y,
			"flag": custom_collision[tile]
		})

	var data: Dictionary = {
		"version": "1.0.0",
		"tent_name": tent_name,
		"grid_width": tent_size.x,
		"grid_height": tent_size.y,
		"wallpaper": current_wallpaper,
		"flooring": current_flooring,
		"furniture": furniture_data,
		"custom_collision": custom_col_data
	}

	var json_str: String = JSON.stringify(data, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		if lbl_status != null:
			lbl_status.text = "Error: Failed to save tent layout to " + path
		return false

	file.store_string(json_str)
	file.close()

	if lbl_status != null:
		lbl_status.text = "Tent layout saved to " + path

	layout_saved.emit(path)
	return true

func load_tent_layout(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		if lbl_status != null:
			lbl_status.text = "Error: File does not exist: " + path
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var text: String = file.get_as_text()
	file.close()

	var test_json_conv = JSON.new()
	var error = test_json_conv.parse(text)
	if error != OK:
		if lbl_status != null:
			lbl_status.text = "Error: JSON parse failed for " + path
		return {}

	var data: Dictionary = test_json_conv.data as Dictionary
	if data == null:
		return {}

	clear_furniture()
	custom_collision.clear()

	tent_name = str(data.get("tent_name", "Player Tent"))
	var gw: int = int(data.get("grid_width", DEFAULT_TENT_SIZE.x))
	var gh: int = int(data.get("grid_height", DEFAULT_TENT_SIZE.y))
	set_tent_size(Vector2i(gw, gh))

	set_wallpaper(str(data.get("wallpaper", "Wood Plank")))
	set_flooring(str(data.get("flooring", "Wood Plank")))

	var f_list: Array = data.get("furniture", [])
	for fd in f_list:
		if fd is Dictionary:
			var inst = FurnitureInstance.new()
			inst.from_dict(fd)
			if inst.instance_id >= next_instance_id:
				next_instance_id = inst.instance_id + 1
			placed_furniture.append(inst)

	var c_list: Array = data.get("custom_collision", [])
	for cd in c_list:
		if cd is Dictionary:
			var cx: int = int(cd.get("x", 0))
			var cy: int = int(cd.get("y", 0))
			var cflag: int = int(cd.get("flag", CollisionFlag.SOLID))
			custom_collision[Vector2i(cx, cy)] = cflag

	recalculate_walkability()
	_update_ui_state()
	_redraw_canvas()

	if lbl_status != null:
		lbl_status.text = "Tent layout loaded successfully from " + path

	layout_loaded.emit(path)
	return data

func export_tent_scene(path: String) -> String:
	var lines: PackedStringArray = []
	lines.append("[gd_scene format=3]")
	lines.append("")
	lines.append("[node name=\"TentInteriorMap\" type=\"Node2D\"]")
	lines.append("metadata/tent_name = \"%s\"" % tent_name)
	lines.append("metadata/wallpaper = \"%s\"" % current_wallpaper)
	lines.append("metadata/flooring = \"%s\"" % current_flooring)
	lines.append("metadata/grid_size = Vector2i(%d, %d)" % [tent_size.x, tent_size.y])
	lines.append("")

	lines.append("[node name=\"Background\" type=\"ColorRect\" parent=\".\"]")
	lines.append("offset_right = 1024.0")
	lines.append("offset_bottom = 768.0")
	lines.append("color = Color(0.04, 0.06, 0.09, 1.0)")
	lines.append("")

	lines.append("[node name=\"RoomRoot\" type=\"Node2D\" parent=\".\"]")
	lines.append("position = Vector2(512.0, 200.0)")
	lines.append("")

	lines.append("[node name=\"FloorDiamond\" type=\"Polygon2D\" parent=\"RoomRoot\"]")
	var s: float = float(TILE_SIZE)
	var top: Vector2 = IsometricMath.world_to_screen(Vector2(0, 0))
	var right: Vector2 = IsometricMath.world_to_screen(Vector2(float(tent_size.x) * s, 0))
	var bottom: Vector2 = IsometricMath.world_to_screen(Vector2(float(tent_size.x) * s, float(tent_size.y) * s))
	var left: Vector2 = IsometricMath.world_to_screen(Vector2(0, float(tent_size.y) * s))
	lines.append("polygon = PackedVector2Array(%.1f, %.1f, %.1f, %.1f, %.1f, %.1f, %.1f, %.1f)" % [
		top.x, top.y, right.x, right.y, bottom.x, bottom.y, left.x, left.y
	])
	var fl_col: Color = FLOORING_COLORS.get(current_flooring, Color(0.48, 0.34, 0.20, 1.0))
	lines.append("color = Color(%.2f, %.2f, %.2f, 1.0)" % [fl_col.r, fl_col.g, fl_col.b])
	lines.append("")

	lines.append("[node name=\"FurnitureContainer\" type=\"Node2D\" parent=\"RoomRoot\"]")
	lines.append("")

	for inst in placed_furniture:
		var safe_name: String = "Furniture_%d_%s" % [inst.instance_id, inst.name.replace(" ", "").replace("'", "")]
		lines.append("[node name=\"%s\" type=\"StaticBody2D\" parent=\"RoomRoot/FurnitureContainer\"]" % safe_name)
		var center_world: Vector2 = Vector2(
			(float(inst.grid_pos.x) + float(inst.get_effective_size().x) * 0.5) * s,
			(float(inst.grid_pos.y) + float(inst.get_effective_size().y) * 0.5) * s
		)
		var center_screen: Vector2 = IsometricMath.world_to_screen(center_world)
		lines.append("position = Vector2(%.1f, %.1f)" % [center_screen.x, center_screen.y])
		lines.append("metadata/instance_id = %d" % inst.instance_id)
		lines.append("metadata/furniture_id = %d" % inst.furniture_id)
		lines.append("metadata/item_id = %d" % inst.item_id)
		lines.append("metadata/heading = %d" % inst.heading)
		lines.append("metadata/is_workbench = %s" % ("true" if inst.is_workbench else "false"))
		lines.append("metadata/workbench_type = \"%s\"" % inst.workbench_type)
		lines.append("metadata/is_walkable = %s" % ("true" if inst.is_walkable else "false"))
		lines.append("")

		lines.append("[node name=\"CollisionPolygon2D\" type=\"CollisionPolygon2D\" parent=\"RoomRoot/FurnitureContainer/%s\"]" % safe_name)
		var eff: Vector2i = inst.get_effective_size()
		var half_w: float = float(eff.x) * s * 0.5
		var half_h: float = float(eff.y) * s * 0.5
		var c_top: Vector2 = IsometricMath.world_to_screen(Vector2(-half_w, -half_h))
		var c_right: Vector2 = IsometricMath.world_to_screen(Vector2(half_w, -half_h))
		var c_bottom: Vector2 = IsometricMath.world_to_screen(Vector2(half_w, half_h))
		var c_left: Vector2 = IsometricMath.world_to_screen(Vector2(-half_w, half_h))
		lines.append("polygon = PackedVector2Array(%.1f, %.1f, %.1f, %.1f, %.1f, %.1f, %.1f, %.1f)" % [
			c_top.x, c_top.y, c_right.x, c_right.y, c_bottom.x, c_bottom.y, c_left.x, c_left.y
		])
		lines.append("")

	lines.append("[node name=\"ExitPortal\" type=\"Area2D\" parent=\"RoomRoot\"]")
	lines.append("position = Vector2(%.1f, %.1f)" % [bottom.x, bottom.y - 10.0])
	lines.append("metadata/target_map = \"outdoors\"")
	lines.append("")
	lines.append("[node name=\"PortalCollision\" type=\"CollisionPolygon2D\" parent=\"RoomRoot/ExitPortal\"]")
	lines.append("polygon = PackedVector2Array(-20, -10, 20, -10, 20, 10, -20, 10)")
	lines.append("")

	var scene_text: String = "\n".join(lines)
	if not path.is_empty():
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(scene_text)
			file.close()
			scene_exported.emit(path)

	return scene_text

func get_canvas_origin() -> Vector2:
	if tent_canvas == null:
		return Vector2(300.0, 120.0)
	var size: Vector2 = tent_canvas.size
	return Vector2(size.x * 0.5, 120.0) + canvas_offset

func canvas_screen_to_tile(screen_pos: Vector2) -> Vector2i:
	var origin: Vector2 = get_canvas_origin()
	var local_scr: Vector2 = (screen_pos - origin) / canvas_zoom
	var world_pos: Vector2 = IsometricMath.screen_to_world(local_scr)
	return IsometricMath.world_to_tile(world_pos)

func tile_to_canvas_screen(grid_pos: Vector2i, center: bool = true) -> Vector2:
	var origin: Vector2 = get_canvas_origin()
	var world_pos: Vector2 = IsometricMath.tile_to_world(grid_pos, center)
	var scr: Vector2 = IsometricMath.world_to_screen(world_pos)
	return origin + scr * canvas_zoom

func _on_canvas_draw() -> void:
	if tent_canvas == null:
		return

	var origin: Vector2 = get_canvas_origin()
	var s: float = float(TILE_SIZE) * canvas_zoom
	var tw: int = tent_size.x
	var th: int = tent_size.y

	var top_apex: Vector2 = origin + IsometricMath.world_to_screen(Vector2(0, 0)) * canvas_zoom
	var right_apex: Vector2 = origin + IsometricMath.world_to_screen(Vector2(float(tw) * float(TILE_SIZE), 0)) * canvas_zoom
	var bottom_apex: Vector2 = origin + IsometricMath.world_to_screen(Vector2(float(tw) * float(TILE_SIZE), float(th) * float(TILE_SIZE))) * canvas_zoom
	var left_apex: Vector2 = origin + IsometricMath.world_to_screen(Vector2(0, float(th) * float(TILE_SIZE))) * canvas_zoom

	var wall_height: float = 90.0 * canvas_zoom
	var wp_col: Color = WALLPAPER_COLORS.get(current_wallpaper, Color(0.36, 0.25, 0.15, 1.0))
	var wp_col_shaded: Color = wp_col.darkened(0.18)

	var left_wall: PackedVector2Array = PackedVector2Array([
		left_apex,
		top_apex,
		top_apex - Vector2(0, wall_height),
		left_apex - Vector2(0, wall_height)
	])
	tent_canvas.draw_polygon(left_wall, PackedColorArray([wp_col, wp_col, wp_col, wp_col]))
	tent_canvas.draw_polyline(left_wall, wp_col.lightened(0.2), 1.5)

	var right_wall: PackedVector2Array = PackedVector2Array([
		top_apex,
		right_apex,
		right_apex - Vector2(0, wall_height),
		top_apex - Vector2(0, wall_height)
	])
	tent_canvas.draw_polygon(right_wall, PackedColorArray([wp_col_shaded, wp_col_shaded, wp_col_shaded, wp_col_shaded]))
	tent_canvas.draw_polyline(right_wall, wp_col.lightened(0.1), 1.5)

	var floor_poly: PackedVector2Array = PackedVector2Array([
		top_apex, right_apex, bottom_apex, left_apex
	])
	var fl_col: Color = FLOORING_COLORS.get(current_flooring, Color(0.48, 0.34, 0.20, 1.0))
	tent_canvas.draw_polygon(floor_poly, PackedColorArray([fl_col, fl_col, fl_col, fl_col]))

	if show_grid:
		var grid_line_col: Color = Color(0.15, 0.22, 0.32, 0.45)
		for x in range(tw + 1):
			var start_p: Vector2 = origin + IsometricMath.world_to_screen(Vector2(float(x) * float(TILE_SIZE), 0)) * canvas_zoom
			var end_p: Vector2 = origin + IsometricMath.world_to_screen(Vector2(float(x) * float(TILE_SIZE), float(th) * float(TILE_SIZE))) * canvas_zoom
			tent_canvas.draw_line(start_p, end_p, grid_line_col, 1.0)
		for y in range(th + 1):
			var start_p: Vector2 = origin + IsometricMath.world_to_screen(Vector2(0, float(y) * float(TILE_SIZE))) * canvas_zoom
			var end_p: Vector2 = origin + IsometricMath.world_to_screen(Vector2(float(tw) * float(TILE_SIZE), float(y) * float(TILE_SIZE))) * canvas_zoom
			tent_canvas.draw_line(start_p, end_p, grid_line_col, 1.0)

	if show_collision:
		for y in range(th):
			for x in range(tw):
				var tile: Vector2i = Vector2i(x, y)
				if collision_matrix.get(tile, CollisionFlag.WALKABLE) == CollisionFlag.SOLID:
					var diamond: PackedVector2Array = _get_screen_diamond(tile)
					tent_canvas.draw_polygon(diamond, PackedColorArray([Color(0.9, 0.15, 0.15, 0.35), Color(0.9, 0.15, 0.15, 0.35), Color(0.9, 0.15, 0.15, 0.35), Color(0.9, 0.15, 0.15, 0.35)]))
					var center_p: Vector2 = tile_to_canvas_screen(tile, true)
					tent_canvas.draw_line(center_p - Vector2(4, 3), center_p + Vector2(4, 3), Color(0.95, 0.3, 0.3, 0.8), 1.5)
					tent_canvas.draw_line(center_p - Vector2(4, -3), center_p + Vector2(4, -3), Color(0.95, 0.3, 0.3, 0.8), 1.5)

	var sorted_furniture: Array[FurnitureInstance] = placed_furniture.duplicate()
	sorted_furniture.sort_custom(func(a: FurnitureInstance, b: FurnitureInstance) -> bool:
		var depth_a: int = a.grid_pos.x + a.grid_pos.y
		var depth_b: int = b.grid_pos.x + b.grid_pos.y
		if depth_a != depth_b:
			return depth_a < depth_b
		return a.instance_id < b.instance_id
	)

	for inst in sorted_furniture:
		_draw_furniture_piece(inst)

	var door_center: Vector2 = bottom_apex
	var exit_marker: PackedVector2Array = PackedVector2Array([
		door_center + Vector2(-16, -8),
		door_center + Vector2(16, -8),
		door_center + Vector2(20, 0),
		door_center + Vector2(-20, 0)
	])
	tent_canvas.draw_colored_polygon(exit_marker, Color(0.85, 0.70, 0.25, 0.7))
	tent_canvas.draw_polyline(exit_marker, Color(1.0, 0.9, 0.4, 0.95), 1.5)

	if is_hovering_canvas and is_tile_in_bounds(hover_tile):
		if current_mode == EditMode.PLACE and FURNITURE_CATALOG.has(current_palette_def_id):
			_draw_placement_preview(hover_tile)
		else:
			var h_diamond: PackedVector2Array = _get_screen_diamond(hover_tile)
			tent_canvas.draw_polyline(h_diamond, Color(0.3, 0.85, 1.0, 0.85), 2.0)

func _get_screen_diamond(tile: Vector2i) -> PackedVector2Array:
	var origin: Vector2 = get_canvas_origin()
	var s: float = float(TILE_SIZE)
	var gx: float = float(tile.x) * s
	var gy: float = float(tile.y) * s

	var top: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx, gy)) * canvas_zoom
	var right: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx + s, gy)) * canvas_zoom
	var bottom: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx + s, gy + s)) * canvas_zoom
	var left: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx, gy + s)) * canvas_zoom

	return PackedVector2Array([top, right, bottom, left])

func _draw_furniture_piece(inst: FurnitureInstance) -> void:
	var origin: Vector2 = get_canvas_origin()
	var s: float = float(TILE_SIZE)
	var eff: Vector2i = inst.get_effective_size()
	var gx: float = float(inst.grid_pos.x) * s
	var gy: float = float(inst.grid_pos.y) * s
	var gw: float = float(eff.x) * s
	var gh: float = float(eff.y) * s

	var b_top: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx, gy)) * canvas_zoom
	var b_right: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx + gw, gy)) * canvas_zoom
	var b_bottom: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx + gw, gy + gh)) * canvas_zoom
	var b_left: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx, gy + gh)) * canvas_zoom

	var shadow_poly: PackedVector2Array = PackedVector2Array([b_top, b_right, b_bottom, b_left])
	tent_canvas.draw_polygon(shadow_poly, PackedColorArray([Color(0, 0, 0, 0.28), Color(0, 0, 0, 0.28), Color(0, 0, 0, 0.28), Color(0, 0, 0, 0.28)]))

	var h_px: float = inst.height_px * canvas_zoom
	var t_top: Vector2 = b_top - Vector2(0, h_px)
	var t_right: Vector2 = b_right - Vector2(0, h_px)
	var t_bottom: Vector2 = b_bottom - Vector2(0, h_px)
	var t_left: Vector2 = b_left - Vector2(0, h_px)

	if h_px > 3.0:
		var left_side: PackedVector2Array = PackedVector2Array([b_left, b_bottom, t_bottom, t_left])
		var side_l_col: Color = inst.color.darkened(0.35)
		tent_canvas.draw_polygon(left_side, PackedColorArray([side_l_col, side_l_col, side_l_col, side_l_col]))
		tent_canvas.draw_polyline(left_side, side_l_col.lightened(0.15), 1.0)

		var right_side: PackedVector2Array = PackedVector2Array([b_bottom, b_right, t_right, t_bottom])
		var side_r_col: Color = inst.color.darkened(0.20)
		tent_canvas.draw_polygon(right_side, PackedColorArray([side_r_col, side_r_col, side_r_col, side_r_col]))
		tent_canvas.draw_polyline(right_side, side_r_col.lightened(0.15), 1.0)

	var top_poly: PackedVector2Array = PackedVector2Array([t_top, t_right, t_bottom, t_left])
	tent_canvas.draw_polygon(top_poly, PackedColorArray([inst.color, inst.color, inst.color, inst.color]))

	var is_selected: bool = (inst.instance_id == selected_instance_id)
	var border_col: Color = Color(1.0, 0.85, 0.2, 0.95) if is_selected else inst.color.lightened(0.3)
	var border_width: float = 2.5 if is_selected else 1.2
	tent_canvas.draw_polyline(top_poly, border_col, border_width)

	var center_p: Vector2 = (t_top + t_bottom) * 0.5
	var heading_dir: Vector2 = Vector2.ZERO
	match inst.heading:
		Heading.SOUTH: heading_dir = (t_bottom - center_p).normalized() * 8.0 * canvas_zoom
		Heading.WEST: heading_dir = (t_left - center_p).normalized() * 8.0 * canvas_zoom
		Heading.NORTH: heading_dir = (t_top - center_p).normalized() * 8.0 * canvas_zoom
		Heading.EAST: heading_dir = (t_right - center_p).normalized() * 8.0 * canvas_zoom
	tent_canvas.draw_line(center_p, center_p + heading_dir, Color.WHITE, 2.0)

	if inst.is_workbench:
		tent_canvas.draw_circle(center_p, 4.0 * canvas_zoom, Color(1.0, 0.85, 0.1, 0.95))

func _draw_placement_preview(tile: Vector2i) -> void:
	var def: Dictionary = FURNITURE_CATALOG[current_palette_def_id]
	var base_size: Vector2i = def["grid_size"]
	var eff: Vector2i = base_size
	if placement_heading % 2 == 1:
		eff = Vector2i(base_size.y, base_size.x)

	var valid: bool = is_tile_in_bounds(tile) and is_tile_in_bounds(tile + eff - Vector2i(1, 1))

	var origin: Vector2 = get_canvas_origin()
	var s: float = float(TILE_SIZE)
	var gx: float = float(tile.x) * s
	var gy: float = float(tile.y) * s
	var gw: float = float(eff.x) * s
	var gh: float = float(eff.y) * s

	var b_top: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx, gy)) * canvas_zoom
	var b_right: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx + gw, gy)) * canvas_zoom
	var b_bottom: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx + gw, gy + gh)) * canvas_zoom
	var b_left: Vector2 = origin + IsometricMath.world_to_screen(Vector2(gx, gy + gh)) * canvas_zoom

	var preview_poly: PackedVector2Array = PackedVector2Array([b_top, b_right, b_bottom, b_left])
	var tint: Color = Color(0.2, 0.9, 0.35, 0.45) if valid else Color(0.95, 0.2, 0.2, 0.45)
	tent_canvas.draw_polygon(preview_poly, PackedColorArray([tint, tint, tint, tint]))
	tent_canvas.draw_polyline(preview_poly, Color.WHITE if valid else Color.RED, 2.0)

func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		is_hovering_canvas = true
		hover_tile = canvas_screen_to_tile(event.position)
		if _is_panning:
			canvas_offset = _pan_start_offset + (event.position - _pan_start_mouse)
		_redraw_canvas()

	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or (mb.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SPACE)):
			if mb.pressed:
				_is_panning = true
				_pan_start_mouse = mb.position
				_pan_start_offset = canvas_offset
			else:
				_is_panning = false

		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			canvas_zoom = clampf(canvas_zoom + 0.1, 0.5, 2.5)
			_redraw_canvas()

		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			canvas_zoom = clampf(canvas_zoom - 0.1, 0.5, 2.5)
			_redraw_canvas()

		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if current_mode == EditMode.PLACE:
				placement_heading = (placement_heading + 1) % 4
				_redraw_canvas()
			elif selected_instance_id > 0:
				rotate_furniture(selected_instance_id, true)

		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var clicked_tile: Vector2i = canvas_screen_to_tile(mb.position)
			if not is_tile_in_bounds(clicked_tile):
				return

			match current_mode:
				EditMode.PLACE:
					place_furniture(current_palette_def_id, clicked_tile, placement_heading)

				EditMode.SELECT_MOVE:
					var hit: FurnitureInstance = get_furniture_at(clicked_tile)
					if hit != null:
						select_furniture(hit.instance_id)
					elif selected_instance_id > 0:
						move_furniture(selected_instance_id, clicked_tile)

				EditMode.ROTATE:
					var hit_rot: FurnitureInstance = get_furniture_at(clicked_tile)
					if hit_rot != null:
						rotate_furniture(hit_rot.instance_id, true)

				EditMode.REMOVE:
					var hit_rem: FurnitureInstance = get_furniture_at(clicked_tile)
					if hit_rem != null:
						remove_furniture(hit_rem.instance_id)

				EditMode.PAINT_COLLISION:
					paint_collision(clicked_tile, CollisionFlag.SOLID)

func _on_canvas_mouse_exited() -> void:
	is_hovering_canvas = false
	_redraw_canvas()

func _redraw_canvas() -> void:
	if tent_canvas != null:
		tent_canvas.queue_redraw()

func _update_mode_buttons() -> void:
	if btn_mode_place != null:
		btn_mode_place.button_pressed = (current_mode == EditMode.PLACE)
	if btn_mode_select != null:
		btn_mode_select.button_pressed = (current_mode == EditMode.SELECT_MOVE)
	if btn_mode_rotate != null:
		btn_mode_rotate.button_pressed = (current_mode == EditMode.ROTATE)
	if btn_mode_delete != null:
		btn_mode_delete.button_pressed = (current_mode == EditMode.REMOVE)
	if btn_mode_paint_col != null:
		btn_mode_paint_col.button_pressed = (current_mode == EditMode.PAINT_COLLISION)

func _update_ui_state() -> void:
	if lbl_total_furniture != null:
		lbl_total_furniture.text = "Placed Furniture: %d" % placed_furniture.size()

	var wb_count: int = 0
	for inst in placed_furniture:
		if inst.is_workbench:
			wb_count += 1
	if lbl_workbenches != null:
		lbl_workbenches.text = "Workbenches: %d" % wb_count

	_update_inspector_controls()

func _update_inspector_controls() -> void:
	var inst: FurnitureInstance = get_furniture(selected_instance_id)
	if inst == null:
		if lbl_sel_instance != null:
			lbl_sel_instance.text = "No furniture selected"
		if lbl_sel_name != null:
			lbl_sel_name.text = "-"
		if spin_pos_x != null:
			spin_pos_x.editable = false
		if spin_pos_y != null:
			spin_pos_y.editable = false
		if opt_heading != null:
			opt_heading.disabled = true
		if btn_rotate_sel != null:
			btn_rotate_sel.disabled = true
		if btn_delete_sel != null:
			btn_delete_sel.disabled = true
	else:
		if lbl_sel_instance != null:
			lbl_sel_instance.text = "Instance #%d (Item #%d)" % [inst.instance_id, inst.item_id]
		if lbl_sel_name != null:
			lbl_sel_name.text = inst.name + (" [" + inst.workbench_type + "]" if inst.is_workbench else "")
		if spin_pos_x != null:
			spin_pos_x.editable = true
			spin_pos_x.value = inst.grid_pos.x
		if spin_pos_y != null:
			spin_pos_y.editable = true
			spin_pos_y.value = inst.grid_pos.y
		if opt_heading != null:
			opt_heading.disabled = false
			opt_heading.select(inst.heading)
		if btn_rotate_sel != null:
			btn_rotate_sel.disabled = false
		if btn_delete_sel != null:
			btn_delete_sel.disabled = false

func _refresh_furniture_palette() -> void:
	if list_furniture == null:
		return
	list_furniture.clear()

	var filter_cat: String = ""
	if opt_category != null and opt_category.selected > 0:
		filter_cat = opt_category.get_item_text(opt_category.selected)

	var search_text: String = edit_search.text.strip_edges().to_lower() if edit_search != null else ""

	for f_id in FURNITURE_CATALOG.keys():
		var def: Dictionary = FURNITURE_CATALOG[f_id]
		if not filter_cat.is_empty() and def["category"] != filter_cat:
			continue
		if not search_text.is_empty() and not str(def["name"]).to_lower().contains(search_text):
			continue
		var label: String = "%s (%dx%d)" % [def["name"], def["grid_size"].x, def["grid_size"].y]
		var idx: int = list_furniture.add_item(label)
		list_furniture.set_item_metadata(idx, f_id)
		if f_id == current_palette_def_id:
			list_furniture.select(idx)

func _update_palette_selection() -> void:
	if not FURNITURE_CATALOG.has(current_palette_def_id):
		return
	var def: Dictionary = FURNITURE_CATALOG[current_palette_def_id]
	if lbl_palette_name != null:
		lbl_palette_name.text = def["name"]
	if lbl_palette_item_id != null:
		lbl_palette_item_id.text = "Item ID: %d" % def["item_id"]
	if lbl_palette_category != null:
		lbl_palette_category.text = "Category: %s" % def["category"]
	if lbl_palette_footprint != null:
		lbl_palette_footprint.text = "Size: %dx%d" % [def["grid_size"].x, def["grid_size"].y]
	if lbl_palette_workbench != null:
		lbl_palette_workbench.text = "Workbench: %s" % (def["workbench_type"] if def["is_workbench"] else "No")
	if lbl_palette_desc != null:
		lbl_palette_desc.text = def["description"]

func _clamp_furniture_in_bounds() -> void:
	for inst in placed_furniture:
		var eff: Vector2i = inst.get_effective_size()
		if inst.grid_pos.x + eff.x > tent_size.x:
			inst.grid_pos.x = maxi(0, tent_size.x - eff.x)
		if inst.grid_pos.y + eff.y > tent_size.y:
			inst.grid_pos.y = maxi(0, tent_size.y - eff.y)

func _on_btn_apply_preset_pressed() -> void:
	if opt_preset != null:
		var p_name: String = opt_preset.get_item_text(opt_preset.selected)
		apply_preset(p_name)

func _on_opt_wallpaper_selected(index: int) -> void:
	if opt_wallpaper != null:
		set_wallpaper(opt_wallpaper.get_item_text(index))

func _on_opt_flooring_selected(index: int) -> void:
	if opt_flooring != null:
		set_flooring(opt_flooring.get_item_text(index))

func _on_btn_clear_pressed() -> void:
	clear_furniture()
	clear_custom_collision()
	if lbl_status != null:
		lbl_status.text = "Tent interior cleared."

func _on_btn_save_pressed() -> void:
	var path: String = "user://tent_layout.json"
	save_tent_layout(path)

func _on_btn_load_pressed() -> void:
	var path: String = "user://tent_layout.json"
	load_tent_layout(path)

func _on_btn_export_scene_pressed() -> void:
	var path: String = "user://tent_interior_map.tscn"
	var scene_str: String = export_tent_scene(path)
	if export_text_edit != null:
		export_text_edit.text = scene_str
	if export_dialog != null:
		export_dialog.popup_centered()
	if lbl_status != null:
		lbl_status.text = "Exported standalone tent scene to " + path

func _on_opt_category_selected(_index: int) -> void:
	_refresh_furniture_palette()

func _on_search_text_changed(_new_text: String) -> void:
	_refresh_furniture_palette()

func _on_furniture_list_item_selected(index: int) -> void:
	if list_furniture != null:
		var f_id: Variant = list_furniture.get_item_metadata(index)
		if f_id != null and f_id is int:
			set_palette_item(f_id)

func _on_btn_quick_place_pressed() -> void:
	var center_tile: Vector2i = tent_size / 2
	place_furniture(current_palette_def_id, center_tile, placement_heading)

func _on_check_grid_toggled(pressed: bool) -> void:
	show_grid = pressed
	_redraw_canvas()

func _on_check_collision_toggled(pressed: bool) -> void:
	show_collision = pressed
	_redraw_canvas()

func _on_btn_center_view_pressed() -> void:
	canvas_offset = Vector2.ZERO
	canvas_zoom = 1.0
	_redraw_canvas()

func _on_btn_resize_tent_pressed() -> void:
	var w: int = int(spin_width.value) if spin_width != null else DEFAULT_TENT_SIZE.x
	var h: int = int(spin_height.value) if spin_height != null else DEFAULT_TENT_SIZE.y
	if edit_tent_name != null:
		tent_name = edit_tent_name.text.strip_edges()
	set_tent_size(Vector2i(w, h))

func _on_btn_rotate_sel_pressed() -> void:
	if selected_instance_id > 0:
		rotate_furniture(selected_instance_id, true)

func _on_btn_delete_sel_pressed() -> void:
	if selected_instance_id > 0:
		remove_furniture(selected_instance_id)

func _on_opt_heading_selected(index: int) -> void:
	var inst: FurnitureInstance = get_furniture(selected_instance_id)
	if inst != null:
		inst.heading = index
		recalculate_walkability()
		_redraw_canvas()
		furniture_rotated.emit(inst.instance_id, inst.heading)

func _on_spin_pos_changed(_val: float) -> void:
	if selected_instance_id > 0 and spin_pos_x != null and spin_pos_y != null:
		var target_pos: Vector2i = Vector2i(int(spin_pos_x.value), int(spin_pos_y.value))
		move_furniture(selected_instance_id, target_pos)
