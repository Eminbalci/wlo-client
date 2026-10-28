# Wonderland Online - Tent & Furniture Interior Studio Tool Specification

## 1. Overview
The **Tent & Furniture Interior Studio** (`TentEditor`) is an authentic, production-grade visual developer and authoring tool integrated into the Wonderland Online Godot 4 client.
It empowers designers and developers to create, customize, visualize, and export player portable housing tent interiors with an authentic 2:1 axonometric isometric grid, furniture and crafting workbench placement, dynamic collision and walkability matrix evaluation, custom collision painting, wallpaper and flooring configuration, and standalone Godot 4 `.tscn` scene generation.

- **Script Path:** [`res://scripts/tools/tent_editor.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/tools/tent_editor.gd)
- **Scene Path:** [`res://scenes/tools/tent_editor.tscn`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/tools/tent_editor.tscn)
- **Test Scene Path:** [`res://scenes/tests/test_tent_editor.tscn`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/tests/test_tent_editor.tscn)
- **Test Suite Script:** [`res://tests/test_tent_editor.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_tent_editor.gd)
- **Test Runner Script:** [`res://tests/test_tent_editor_runner.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_tent_editor_runner.gd)
- **Base Class:** `Control`
- **Minimum Resolution:** 800x600 (dark-themed slate/navy UI)

---

## 2. Architecture & Scene Hierarchy

```
TentEditor (Control, min 800x600)
├── Background (Panel with Dark Navy StyleBoxFlat)
└── MainVBox (VBoxContainer)
    ├── TopBar (PanelContainer)
    │   └── HBoxTop: Title, PresetOption, BtnApplyPreset, WallpaperOption, FlooringOption, BtnClear, BtnSave, BtnLoad, BtnExportScene
    ├── ContentHBox (HBoxContainer)
    │   ├── LeftPanel (PanelContainer, min 210px)
    │   │   └── LeftVBox:
    │   │       ├── LblPaletteHeader ("FURNITURE PALETTE")
    │   │       ├── CategoryOption (Category filter)
    │   │       ├── SearchEdit (Text search)
    │   │       ├── FurnitureList (ItemList of catalog items)
    │   │       ├── PaletteItemDetails (Name, Item ID, Footprint, Workbench type, Description)
    │   │       └── BtnQuickPlace ("Place in Center")
    │   ├── CenterPanel (PanelContainer, expanding)
    │   │   └── CenterVBox:
    │   │       ├── CanvasToolbar:
    │   │       │   ├── Mode Buttons: Place [P], Select/Move [S], Rotate [R], Delete [Del], Paint Col [C]
    │   │       │   ├── CheckGrid (Toggle 2:1 axonometric grid)
    │   │       │   ├── CheckCollision (Toggle collision overlay)
    │   │       │   └── BtnCenterView (Reset pan & zoom)
    │   │       └── CanvasWrapper (PanelContainer, clip_contents=true)
    │   │           └── TentCanvas (Control, custom _draw & _gui_input)
    │   └── RightPanel (PanelContainer, min 210px)
    │       └── RightVBox:
    │           ├── LblTentHeader ("TENT CONFIGURATION")
    │           ├── TentNameEdit, WidthSpin, HeightSpin, BtnResizeTent
    │           ├── LblInspectorHeader ("SELECTED FURNITURE")
    │           ├── SelectedInstanceLabel, SelectedNameLabel
    │           ├── PosXSpin, PosYSpin, HeadingOption, BtnRotateSelected, BtnDeleteSelected
    │           ├── LblMetricsHeader ("TENT METRICS")
    │           └── TotalFurnitureLabel, WorkbenchesLabel, WalkableTilesLabel, WalkableProgressBar
    ├── BottomBar (PanelContainer)
    │   └── HBoxBottom: StatusLabel
    └── ExportDialog (AcceptDialog)
        └── ExportTextEdit (TextEdit, read-only .tscn scene preview)
```

---

## 3. 2:1 Axonometric Isometric Projection & Grid System

### 3.1 Mathematical Formulation
The tent room uses the authentic 2:1 axonometric isometric projection matching the original Wonderland Online client engine:
- **World Tile Scale ($s$):** `20.0 px`
- **Projection Formula:**
  - $X_s = X_w - Y_w$
  - $Y_s = \frac{X_w + Y_w}{2}$
- **Inverse Screen-to-World Projection:**
  - $X_w = \frac{2 \cdot Y_s + X_s}{2}$
  - $Y_w = \frac{2 \cdot Y_s - X_s}{2}$
- **Screen Tile Diamond:**
  - Width: $40.0\text{ px}$ (from $-20$ to $+20$)
  - Height: $20.0\text{ px}$ (from $-10$ to $+10$)
  - Aspect Ratio: $2:1$

### 3.2 Canvas Drawing Pipeline
1. **Back Walls:** Extrudes the room back walls upward from the North-West and North-East floor perimeter lines by $90\text{ px}$ with wall-shading according to the active wallpaper.
2. **Floor Diamond Surface:** Fills the tent perimeter with the active flooring color.
3. **Grid Overlay:** Draws isometric diamond lines for all grid cells when `show_grid` is active.
4. **Collision Overlay:** Highlights unwalkable/solid tiles with a translucent red overlay and crosshair indicator when `show_collision` is active.
5. **Isometric Furniture Sorting:** Placed furniture instances are sorted along the depth axis ($(X + Y)$ ascending) and drawn with 3D isometric block extrusion, directional heading indicators, and selection borders.
6. **Exit Portal:** Renders the bottom doorway portal marker for map transitions.

### 3.3 Wallpapers & Floorings

| Type | Options | Default Color |
|---|---|---|
| **Wallpaper** | Wood Plank, Stone Brick, Red Floral Wallpaper, Blue Regal Wallpaper, Simple Canvas | Shaded wall polygons |
| **Flooring** | Wood Plank, Marble, Carpet, Tatami, Grass | Shaded floor diamond |

---

## 4. Furniture & Apparatus Palette Catalog

The catalog incorporates the four core Wonderland Online housing item categories:

### 4.1 Crafting Workbenches

| ID | Item ID | Name | Size | Workbench Type | Walkable | Description |
|---|---|---|---|---|---|---|
| 101 | 38001 | Alchemy Apparatus | 2x2 | Alchemy | No | High-tier alchemical alembic apparatus for synthesizing reagents and elixirs. |
| 102 | 38002 | Furnace | 2x2 | Smelting | No | Refined blast furnace for smelting raw copper, iron, gold ores, and titanium. |
| 103 | 38003 | Loom | 2x2 | Weaving | No | Wooden textile loom used to weave hemp, cotton thread, and silk into fabrics. |
| 104 | 38004 | Stove | 2x2 | Cooking | No | Cast iron kitchen stove for preparing nutritious field meals, soups, and dishes. |
| 105 | 38005 | Sawmill | 2x2 | Carpentry | No | Water-cranked sawbench for processing timber into building blocks and rods. |
| 106 | 38006 | Potter's Wheel | 2x2 | Pottery | No | Foot-driven ceramic wheel for shaping clay pots, tea sets, and water jars. |

### 4.2 Furniture

| ID | Item ID | Name | Size | Walkable | Height | Description |
|---|---|---|---|---|---|---|
| 201 | 38101 | Simple Bed | 2x3 | No | 16 px | Comfortable wooden single bed for resting and recovering character HP and SP. |
| 202 | 38102 | Luxury Double Bed | 3x3 | No | 20 px | Spacious double bed with velvet canopy, down comforter, and plush pillows. |
| 203 | 38103 | Wardrobe | 2x1 | No | 36 px | Tall dark oak wardrobe for hanging spare gear, cloaks, and formal robes. |
| 204 | 38104 | Dining Table | 2x2 | No | 18 px | Sturdy polished wooden dining table for shared meals and tea ceremonies. |
| 205 | 38105 | Wooden Chair | 1x1 | No | 20 px | Standard timber chair with straight back support. |
| 206 | 38106 | Stool | 1x1 | No | 12 px | Compact round wooden stool that can be tucked under any dining table. |
| 207 | 38107 | Bookshelf | 2x1 | No | 34 px | Tiered bookcase holding alchemy recipes, continent maps, and historic chronicles. |
| 208 | 38108 | Bathtub | 2x2 | No | 18 px | White porcelain soaking tub for therapeutic bathing and hot spring comfort. |
| 209 | 38109 | Sleeping Bag | 1x2 | No | 8 px | Compact insulated bedroll for lightweight wilderness camping inside the tent. |

### 4.3 Storage

| ID | Item ID | Name | Size | Walkable | Height | Description |
|---|---|---|---|---|---|---|
| 301 | 38201 | Storage Chest | 2x1 | No | 16 px | Reinforced wooden storage chest with iron fittings holding up to 50 items. |
| 302 | 38202 | Cabinet | 2x1 | No | 28 px | Multi-compartment storage cabinet for organizing crafting parts and alchemy catalysts. |
| 303 | 38203 | Safe | 1x1 | No | 18 px | Hardened alloy combination safe for locking away precious gems and gold. |

### 4.4 Decor

| ID | Item ID | Name | Size | Walkable | Height | Description |
|---|---|---|---|---|---|---|
| 401 | 38301 | Wall Clock | 1x1 | Yes | 14 px | Polished pendulum wall clock displaying server time and day/night state. |
| 402 | 38302 | Hanging Banner | 1x1 | Yes | 20 px | Tapestry banner emblazoned with heraldic guild and element crests. |
| 403 | 38303 | Potted Plant | 1x1 | No | 22 px | Lush evergreen fern planted in a terracotta pot to purify the tent atmosphere. |
| 404 | 38304 | Persian Carpet | 3x3 | Yes | 2 px | Intricately woven ornamental silk carpet with floral medallion borders. |
| 405 | 38305 | Flower Vase | 1x1 | No | 14 px | Glazed celadon vase with fresh wild blooms picked from coastal meadows. |

---

## 5. Interactive Editing Operations

### 5.1 Tool Modes
1. **Place [P]:** Selects an item from the palette and places it at the snapped isometric cursor position. Right-clicking rotates the placement preview by 90 degrees before placing.
2. **Select/Move [S]:** Left-clicking on placed furniture selects it. Left-clicking an empty tile moves the selected furniture to that position (with boundary validation).
3. **Rotate [R]:** Left-clicking placed furniture rotates it 90 degrees clockwise.
4. **Delete [Del]:** Left-clicking placed furniture removes it from the tent room.
5. **Paint Collision [C]:** Left-clicking on grid tiles toggles manual collision flags (Solid vs. Walkable).

### 5.2 90-Degree Isometric Rotation Mechanics
Orientation is represented by an integer heading $h \in \{0, 1, 2, 3\}$:
- `Heading 0 (SOUTH)`: Front / camera orientation. Effective footprint = `(base_w, base_h)`.
- `Heading 1 (WEST)`: Rotated 90 degrees clockwise. Effective footprint = `(base_h, base_w)`.
- `Heading 2 (NORTH)`: Rotated 180 degrees. Effective footprint = `(base_w, base_h)`.
- `Heading 3 (EAST)`: Rotated 270 degrees. Effective footprint = `(base_h, base_w)`.

When rotating, if the new footprint exceeds the tent boundary, `TentEditor` automatically clamps the coordinates into valid interior bounds:
```gdscript
var eff_size: Vector2i = inst.get_effective_size()
if inst.grid_pos.x + eff_size.x > tent_size.x:
	inst.grid_pos.x = tent_size.x - eff_size.x
if inst.grid_pos.y + eff_size.y > tent_size.y:
	inst.grid_pos.y = tent_size.y - eff_size.y
```

---

## 6. Dynamic Collision & Walkability Matrix

The walkability matrix maps every tile $(x, y) \in [0, W-1] \times [0, H-1]$ to an integer flag:
- `0 (WALKABLE)`: Character can traverse this tile freely.
- `1 (SOLID)`: Traversal blocked by walls, furniture, or painted obstacles.

### Calculation Rules
1. Initialize all tiles as `WALKABLE`.
2. Apply `custom_collision` painted tile overrides.
3. For each placed `FurnitureInstance`:
   - If `is_walkable == false`:
     - Iterate through `get_occupied_tiles()` and set `collision_matrix[tile] = SOLID`.
   - If `is_walkable == true` (e.g. Persian Carpet, Wall Clock, Banner):
     - The underlying tiles remain walkable.
4. Compute metrics:
   $$\text{Total Tiles} = W \times H$$
   $$\text{Solid Tiles} = \sum_{\text{tiles}} [\text{flag} = \text{SOLID}]$$
   $$\text{Walkable Percentage} = \frac{\text{Total Tiles} - \text{Solid Tiles}}{\text{Total Tiles}} \times 100\%$$

---

## 7. Built-in Authentic Presets

### 7.1 "Beginner Camping Tent"
- **Wallpaper:** Simple Canvas
- **Flooring:** Grass
- **Dimensions:** 16x16
- **Furniture Inventory:**
  - Sleeping Bag (ID 209) at $(3, 3)$
  - Campfire Stove (ID 104) at $(7, 3)$ [Cooking Workbench]
  - Simple Wooden Table (ID 204) at $(4, 7)$
  - Stool (ID 206) at $(3, 7)$
  - Storage Chest (ID 301) at $(2, 2)$

### 7.2 "Alchemist Laboratory"
- **Wallpaper:** Stone Brick
- **Flooring:** Marble
- **Dimensions:** 16x16
- **Furniture Inventory:**
  - High-grade Alchemy Table (ID 101) at $(4, 3)$ [Alchemy Workbench]
  - Furnace (ID 102) at $(8, 3)$ [Smelting Workbench]
  - Bookshelf (ID 207, rotated West) at $(2, 3)$
  - Bookshelf (ID 207, rotated West) at $(2, 6)$
  - Storage Chest (ID 301, rotated West) at $(2, 9)$
  - Dining Table (ID 204) at $(6, 7)$
  - Chair (ID 205) at $(6, 6)$
  - Potted Plant (ID 403) at $(11, 3)$

### 7.3 "Cozy Bedroom Suite"
- **Wallpaper:** Red Floral Wallpaper
- **Flooring:** Wood Plank
- **Dimensions:** 16x16
- **Furniture Inventory:**
  - Luxury Double Bed (ID 202) at $(3, 3)$
  - Wardrobe (ID 203) at $(8, 2)$
  - Persian Carpet (ID 404, Walkable Decor) at $(5, 7)$
  - Dining Table (ID 204) at $(10, 6)$
  - Chair (ID 205, rotated East) at $(9, 6)$
  - Bathtub (ID 208) at $(3, 9)$
  - Flower Vase (ID 405) at $(10, 5)$
  - Wall Clock (ID 401) at $(2, 2)$

---

## 8. Export & Serialization Pipelines

### 8.1 JSON Tent Layout Format
Invoked via `save_tent_layout(path)` and `load_tent_layout(path)`:
```json
{
	"version": "1.0.0",
	"tent_name": "Beginner Camping Tent",
	"grid_width": 16,
	"grid_height": 16,
	"wallpaper": "Simple Canvas",
	"flooring": "Grass",
	"furniture": [
		{
			"instance_id": 1,
			"furniture_id": 209,
			"item_id": 38109,
			"name": "Sleeping Bag",
			"category": "Furniture",
			"grid_x": 3,
			"grid_y": 3,
			"base_width": 1,
			"base_height": 2,
			"heading": 0,
			"is_workbench": false,
			"workbench_type": "",
			"is_walkable": false,
			"color": "52855ce6",
			"height_px": 8.0
		}
	],
	"custom_collision": []
}
```

### 8.2 Standalone Godot 4 `.tscn` Scene Generator
Invoked via `export_tent_scene(path)`. Produces fully valid Godot 4 text scenes with:
- Root node `TentInteriorMap` (`Node2D`)
- Isometric floor diamond geometry (`Polygon2D`)
- Wall boundaries and doorway portal (`Area2D` with `CollisionPolygon2D`)
- Each furniture item instantiated as `StaticBody2D` with its exact 2:1 axonometric diamond `CollisionPolygon2D` and metadata tags (`metadata/furniture_id`, `metadata/item_id`, `metadata/is_workbench`, `metadata/workbench_type`).

---

## 9. Automated Verification Suite

The tool is thoroughly verified headless via `C:\Godot\godot_console.exe`:
```powershell
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" "scenes/tests/test_tent_editor.tscn"
```

### Test Results

| Test # | Suite Name | Verified Assertions | Status |
|---|---|---|---|
| **TEST 1** | Tent Identity & Dimensions | Default 16x16 dimensions, dynamic resizing (20x20), boundary checking | **PASS** |
| **TEST 2** | Wallpapers & Floorings | 5 wallpaper types, 5 flooring types, reactive updating | **PASS** |
| **TEST 3** | Furniture Catalog | 18+ items across Workbenches, Furniture, Storage, and Decor | **PASS** |
| **TEST 4** | Interactive Placement | Valid placement, out-of-bounds rejection, negative coordinate rejection | **PASS** |
| **TEST 5** | 90-Degree Isometric Rotation | 4 heading states (0..3), non-square footprint swapping ($2\times 1 \leftrightarrow 1\times 2$) | **PASS** |
| **TEST 6** | Collision & Walkability Matrix | 100% walkable empty room, solid tile masking, walkable decor preservation, removal restoration | **PASS** |
| **TEST 7** | Built-in Presets | Beginner Camping Tent, Alchemist Laboratory, Cozy Bedroom Suite bit-exact items | **PASS** |
| **TEST 8** | JSON Serialization Roundtrip | Save to JSON, clear, reload, verify identical counts and walkability | **PASS** |
| **TEST 9** | Standalone Scene Export | `.tscn` generation, format=3 validation, live Godot resource loading and instantiation | **PASS** |
| **TEST 10** | Scene Instantiation | `scenes/tools/tent_editor.tscn` 800x600 dark theme responsive layout verification | **PASS** |

**Summary:** 10 / 10 Tests Passed (100% Pass Rate, 0 Errors, 0 Warnings).
