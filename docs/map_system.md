# Technical Documentation: Isometric Map & Coordinate System

## Projection Mathematics
Wonderland Online uses classic 2:1 axonometric isometric projection matching the original `rodraw2.dll` DirectDraw pipeline:

### Coordinate Conversions
- **World Grid to Screen Pixels**:
  ```
  screen_x = world_x - world_y
  screen_y = (world_x + world_y) / 2
  ```
- **Screen Pixels to World Grid**:
  ```
  world_x = (2 * screen_y + screen_x) / 2
  world_y = (2 * screen_y - screen_x) / 2
  ```

### Kinematics & 8-Directional Headings
- Sectors of 45 degrees:
  - 0: South
  - 1: South-West
  - 2: West
  - 3: North-West
  - 4: North
  - 5: North-East
  - 6: East
  - 7: South-East
- Diagonal velocity scaling factor: `1.0 / sqrt(2) ≈ 0.7071`

## Map Collision Matrix (`.MapData` & `Ground.MMG`)
- File path convention: `user/Map/<ID ^ 0x190C>.MapData` (fallback: `data/Ground.MMG`).
- XOR key: `0x190C` (6412 decimal).
- Tile Scale: 20 pixels per tile grid unit (`TILE_SCALE = 20`).
- Block Header (36 bytes):
  - `block_id`: uint32
  - `tile_sprite_id`: uint32
  - `grid_x`, `grid_y`: int32
  - `block_dim_x`, `block_dim_y`: int16
  - `is_uniform`: uint8 (1 = uniform solid obstacle)
  - `elevation`: uint8
  - Followed by matrix: `block_dim_x * block_dim_y` bytes
- Collision Flags:
  - `0x00`: Walkable (Normal land ground)
  - `0x01`: Solid Wall / Impassable obstacle
  - `0x02`: Water / Ocean / Sea (requires Boat, Raft, or Canoe)
  - `0x04`: Deep Ocean (requires Ship / Steamship)
  - `0x08`: Mountain / Cliff (requires Flying vehicle like Plane, Hot Air Balloon, UFO)
  - `0x40`: Shallow Water (requires Boat, Raft, Canoe)
  - `0x80`: Hot Spring / Mountain elevation

## Vehicle Traversal Gates
- **On Foot (`VehicleType.NONE`)**: Can only traverse `0x00` (Walkable Land). Attempting to step on water triggers feedback: `"You need a vehicle to traverse water!"`.
- **Raft (`VehicleType.RAFT`)**: Can traverse `0x00` (Land/Shore) and `0x02` / `0x40` (Water). Blocked on deep ocean: `"A fragile raft cannot cross deep ocean! You need a ship or advanced vehicle."`.
- **Boat (`VehicleType.BOAT`)**: Can traverse Land, Water, and Deep Ocean.
- **Ship (`VehicleType.SHIP`)**: Can traverse Land, Water, and Deep Ocean.
- **Plane (`VehicleType.PLANE`)**: Can traverse Land, Water, Deep Ocean, and fly over Mountains (`0x08`). Solid boundary walls block all entities.
