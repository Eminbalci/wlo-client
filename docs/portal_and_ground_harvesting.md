# Map Warp Portals & Ground Resource Harvesting System

Technical documentation for the reverse-engineered Map Warp Portal and Ground Resource Harvesting architectures in the Wonderland Online Godot 4 Client (`wonderland-online-client`).

---

## 1. Binary Data Formats & Layouts

### 1.1 Ground.MMG & Wem.MMG (Map Triggers & Warp Events)

`Ground.MMG` and `Wem.MMG` define the interactive event triggers and warp locations for all 1,147 maps in Wonderland Online.

#### Ground.MMG (Map Index Table)
- **Header:** 8 bytes
  - `uint32 magic`: Magic identifier (`0x00000000` or file tag)
  - `uint32 map_count`: Total indexed maps (1,147 maps)
- **Entries (12 bytes per map):**
  - `uint32 map_id`: Numeric Map ID (e.g., `10001`, `10002`, `10003`)
  - `uint32 offset`: Byte offset into event table / Wem linkage
  - `uint32 length`: Number of entries / trigger records

#### Wem.MMG (Event Record Table)
- **Header:** 8 bytes
  - `uint32 total_events`: 5,761 events
  - `uint32 data_offset`: Start of 22-byte event payload
- **Event Record (22 bytes per entry):**
  | Offset | Type | Field Name | Description |
  | :--- | :--- | :--- | :--- |
  | `0x00..0x03` | `uint32` | `event_id` | Unique Event identifier (e.g. `10001005`, `10001040`) |
  | `0x04..0x07` | `uint32` | `warp_id` | Warp ID cross-referenced with `Eve.emg` `click_id` |
  | `0x08..0x0B` | `uint32` | `sub_id` | Secondary event / dialog branch identifier |
  | `0x0C` | `uint8` | `trigger_type` | `1` = Inter-map warp via `Eve.emg`, `4` = Intra-map teleport / slide |
  | `0x0D..0x0E` | `uint16` | `param` | Parameter value (e.g., slide velocity, duration, flag) |
  | `0x0F..0x10` | `uint16` | `dest_x` | Intra-map target X coordinate (for type 4) |
  | `0x11..0x12` | `uint16` | `dest_y` | Intra-map target Y coordinate (for type 4) |
  | `0x13..0x15` | `uint8[3]` | `flags` | Behavior flags (facing, sound, animation) |

---

### 1.2 Eve.emg (Authoritative Map Scripts, Warps & Ground Resources)

`Eve.emg` is the authoritative client-side database indexed for 1,119 maps.

#### Map Header & Category Offsets
Each map block contains 4 category offsets:
1. `Offset 0`: Map Info & Header block
2. `Offset 1`: `WarpLoc` Table (Authoritative Inter-Map Portals)
3. `Offset 2`: NPC & Script Trigger Definitions
4. `Offset 3`: `ItemAreas` Table (Ground Resource Harvesting)

#### Category 1: WarpLoc Table
Each entry defines an authoritative warp portal:
- `uint16 click_id`: Identifier matching `Wem.MMG` `warp_id`
- `PascalString name`: Warp destination label (1-byte length + characters)
- `uint16 unknown1`: Internal state flag
- `uint32 target_map_id`: Destination Map ID (e.g., `10002`, `10003`)
- `uint16 dest_x`: Target player spawn X coordinate
- `uint16 dest_y`: Target player spawn Y coordinate

#### Category 3: ItemAreas Table (Ground Resources)
- `uint16 count`: Number of ground resource nodes on map
- **Item Node Record:**
  - `uint16 click_id`: Click event identifier
  - `PascalString name`: Item display name (e.g., "Shell", "Coconut")
  - `uint8 ub1`: Reserved byte
  - `uint32 world_x`: Ground coordinate X in pixels
  - `uint32 world_y`: Ground coordinate Y in pixels
  - `LengthPrefixed array1`: Area polygon bounds
  - `LengthPrefixed array2`: Area collision bounds
  - `uint8 ub2`: Reserved byte
  - `uint32 item_id`: Game item ID (matches `Item.dat`, e.g., `46113` = Shell, `41066` = Coconut)
  - `uint8[3] ub3..ub5`: Attribute padding
  - `uint16 respawn_seconds`: Node regeneration duration (default 120s / 180s)
  - `uint16 unknownword2`: Node metadata flag

---

## 2. Rendering & Mathematical Models

### 2.1 DoorLight Additive Blending (`CanvasItemMaterial.BLEND_MODE_ADD`)
Original Wonderland Online portal VFX utilize `res://assets/map/Atlas_DoorLight.png` (512x512 atlas containing 13 animation frames of 81x157 dimensions).
- In classic 2D sprites without pre-baked alpha channels, black pixels (`#000000`) represent complete transparency when rendered under additive blending:
  $$\text{FinalColor} = \text{SourceColor} \times \text{SourceAlpha} + \text{DestColor}$$
- Blending mode configuration:
  ```gdscript
  var mat := CanvasItemMaterial.new()
  mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
  _doorlight_sprite.material = mat
  ```

### 2.2 2:1 Axonometric Proximity Check
Wonderland Online uses a 2:1 isometric projection where the vertical axis is compressed by half:
$$\text{IsoDistance}^2 = (\Delta x)^2 + (2 \cdot \Delta y)^2$$
A portal trigger evaluates true when:
$$\sqrt{(\text{player.x} - \text{portal.x})^2 + 4 \cdot (\text{player.y} - \text{portal.y})^2} \le R_{\text{trigger}}$$

### 2.3 Proximity Gating for Resource Harvesting
To prevent non-local item harvesting through map boundaries:
- Proximity threshold: `180.0` pixels.
- When an item is clicked beyond 180px:
  1. MapView initiates player pathfinding to destination `item.position`.
  2. MapView stores reference in `_pending_pickup_item`.
  3. Upon reaching distance $\le 180\text{px}$, pickup executes automatically.
- Ground shadow rendering uses a 2:1 isometric ellipse:
  ```gdscript
  _draw_iso_ellipse(Vector2(0, 2), 12.0, 6.0, Color(0, 0, 0, 0.35))
  ```

---

## 3. Core Class APIs & Interfaces

### 3.1 `EveParser` (`scripts/map/eve_parser.gd`)
Pure binary parser for `Eve.emg`.
- `load_eve(path: String) -> bool`: Indexes all 1,119 maps into memory.
- `get_warps_for_map(map_id: int) -> Array[WarpInfo]`: Returns authoritative portal definitions for given map.
- `get_ground_items_for_map(map_id: int) -> Array[GroundItemSpawn]`: Returns all resource nodes for given map.

### 3.2 `GroundParser` (`scripts/map/ground_parser.gd`)
Integrates `Ground.MMG`, `Wem.MMG`, and `EveParser`.
- `resolve_warp_for_trigger(trigger: WemEvent) -> WarpInfo`: Resolves inter-map destination using `trigger.warp_id` and `Eve.emg`.
- `get_map_warp_portals(map_id: int) -> Array[Dictionary]`: Returns compiled portal specifications ready for instantiation.

### 3.3 `Portal` (`scripts/map/portal.gd`)
Node2D entity representing warp gateways.
- **Signals:**
  - `portal_triggered(portal: Portal, target_map_id: int, target_coords: Vector2)`
- **Properties:**
  - `portal_id: int`, `portal_name: String`, `target_map_id: int`, `target_coords: Vector2`, `trigger_radius: float`
- **Methods:**
  - `check_trigger(player_pos: Vector2, player_cell: Vector2i) -> bool`

### 3.4 `GroundItem` (`scripts/map/ground_item.gd`)
Node2D entity representing interactive harvestable resources.
- **Signals:**
  - `item_picked_up(item: GroundItem, player: Node2D)`
  - `item_respawned(item: GroundItem)`
- **Properties:**
  - `item_id: int`, `slot: int`, `click_id: int`, `item_name: String`, `respawn_seconds: float`, `icon_id: int`
- **Methods:**
  - `set_item_data(p_id: int, p_slot: int, p_cid: int, p_name: String, p_respawn: float, p_icon: int = 0) -> void`
  - `can_pickup(player: Node2D) -> bool`
  - `try_pickup(player: Node2D) -> bool`
  - `respawn() -> void`

### 3.5 `MapView` (`scripts/map/map_view.gd`)
World coordinator orchestrating entity lifecycle and transitions.
- `_spawn_map_portals(map_id: int) -> void`: Spawns dynamic portals from `GroundParser`.
- `_spawn_ground_items(map_id: int) -> void`: Spawns harvestable resources from `EveParser`.
- `_on_portal_triggered(portal: Portal, target_map_id: int, dest_coords: Vector2) -> void`: Executes map transition.
- `_on_ground_item_clicked(item: GroundItem) -> void`: Evaluates proximity and triggers harvesting or pathfinding.
- `_on_ground_item_harvested(item: GroundItem, player: Node2D) -> void`: Inserts item into HUD inventory and displays animated banner.
