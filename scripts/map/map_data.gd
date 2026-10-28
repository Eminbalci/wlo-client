class_name MapData
extends RefCounted

## Terrain collision grid and block matrix parser for Wonderland Online maps.
## Supports both user/Map/<ID ^ 0x190C>.MapData and data/Ground.MMG.

const FILENAME_XOR_KEY: int = 0x190C # 6412 decimal
const TILE_SCALE: int = 20 # 20 pixels per tile grid unit

enum TileCollisionFlags {
	WALKABLE = 0x00,
	SOLID_WALL = 0x01,
	SEA = 0x02,
	DEEP_OCEAN = 0x04,
	WATER = 0x08,
	MOUNTAIN = 0x10,
	SHALLOW_WATER = 0x40,
	HOT_SPRING = 0x80
}

class MapBlock:
	var block_id: int
	var tile_sprite_id: int
	var grid_x: int
	var grid_y: int
	var block_dim_x: int
	var block_dim_y: int
	var is_uniform: bool
	var elevation: int
	var collision_matrix: PackedByteArray = PackedByteArray()

	func is_walkable(local_x: int, local_y: int) -> bool:
		if local_x < 0 or local_x >= block_dim_x or local_y < 0 or local_y >= block_dim_y:
			return false
		if is_uniform:
			return false
		var idx: int = local_y * block_dim_x + local_x
		if idx < 0 or idx >= collision_matrix.size():
			return false
		return (collision_matrix[idx] & TileCollisionFlags.SOLID_WALL) == 0

	func get_tile_flag(local_x: int, local_y: int) -> int:
		if local_x < 0 or local_x >= block_dim_x or local_y < 0 or local_y >= block_dim_y:
			return TileCollisionFlags.SOLID_WALL
		if is_uniform:
			return TileCollisionFlags.SOLID_WALL
		var idx: int = local_y * block_dim_x + local_x
		if idx < 0 or idx >= collision_matrix.size():
			return TileCollisionFlags.SOLID_WALL
		return collision_matrix[idx]

var map_id: int = 0
var width_px: int = 0
var height_px: int = 0
var blocks: Array[MapBlock] = []
var ground_map = null # GroundParser.GroundMap instance if loaded from Ground.MMG

var cols: int:
	get:
		if ground_map:
			return ground_map.cols
		var max_c: int = 0
		for b in blocks:
			max_c = maxi(max_c, b.grid_x + b.block_dim_x)
		return max_c

var rows: int:
	get:
		if ground_map:
			return ground_map.rows
		var max_r: int = 0
		for b in blocks:
			max_r = maxi(max_r, b.grid_y + b.block_dim_y)
		return max_r

static func get_disk_map_id(p_map_id: int) -> int:
	return p_map_id ^ FILENAME_XOR_KEY

static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / float(TILE_SCALE))), int(floor(world_pos.y / float(TILE_SCALE))))

static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2((float(grid_pos.x) + 0.5) * float(TILE_SCALE), (float(grid_pos.y) + 0.5) * float(TILE_SCALE))

static func load_from_mapdata_file(file_path: String, p_map_id: int) -> MapData:
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return null
	
	var data := file.get_buffer(file.get_length())
	var map := MapData.new()
	map.map_id = p_map_id
	
	var offset: int = 0
	while offset + 36 <= data.size():
		var b_id := data.decode_u32(offset)
		var sprite_id := data.decode_u32(offset + 4)
		var gx := data.decode_s32(offset + 8)
		var gy := data.decode_s32(offset + 12)
		var dim_x := data.decode_s16(offset + 16)
		var dim_y := data.decode_s16(offset + 18)
		var uniform := data[offset + 20] != 0
		var elev := data[offset + 21]
		
		var matrix_size := dim_x * dim_y
		var block := MapBlock.new()
		block.block_id = b_id
		block.tile_sprite_id = sprite_id
		block.grid_x = gx
		block.grid_y = gy
		block.block_dim_x = dim_x
		block.block_dim_y = dim_y
		block.is_uniform = uniform
		block.elevation = elev
		
		offset += 36
		if offset + matrix_size <= data.size():
			block.collision_matrix = data.slice(offset, offset + matrix_size)
			offset += matrix_size
		
		map.blocks.append(block)
	
	return map

## Master loader: loads authentic collision from Ground.MMG via GroundParser
static func load_map(p_map_id: int, file_path: String = "") -> MapData:
	# 1. Primary: authentic Ground.MMG
	var gp_script = load("res://scripts/map/ground_parser.gd")
	if gp_script:
		var gp = gp_script.new()
		if gp.has_map(p_map_id):
			var gmap = gp.load_map(p_map_id)
			if gmap:
				var map := MapData.new()
				map.map_id = p_map_id
				map.width_px = gmap.width_px
				map.height_px = gmap.height_px
				map.ground_map = gmap
				return map
	
	# 2. Fallback: custom MapData file if present
	if not file_path.is_empty() and FileAccess.file_exists(file_path):
		var map := load_from_mapdata_file(file_path, p_map_id)
		if map:
			return map
	
	return null

func get_collision_byte(grid_x: int, grid_y: int) -> int:
	if ground_map:
		return ground_map.get_tile_type(grid_x, grid_y)
	for block in blocks:
		if grid_x >= block.grid_x and grid_x < block.grid_x + block.block_dim_x and \
		   grid_y >= block.grid_y and grid_y < block.grid_y + block.block_dim_y:
			var local_x: int = grid_x - block.grid_x
			var local_y: int = grid_y - block.grid_y
			return block.get_tile_flag(local_x, local_y)
	return TileCollisionFlags.WALKABLE

func is_walkable(grid_x: int, grid_y: int, vehicle: int = 0) -> bool:
	var flag: int = get_collision_byte(grid_x, grid_y)
	return check_traversal(flag, vehicle)["allowed"]

static func is_solid_obstacle(flag: int) -> bool:
	return flag == 1 or (flag & TileCollisionFlags.SOLID_WALL) != 0

static func is_water_tile(flag: int) -> bool:
	return flag == 2 or flag == 8 or flag == 0x02 or flag == 0x08 or flag == 0x40 or \
		(flag & TileCollisionFlags.WATER) != 0 or \
		(flag & TileCollisionFlags.SHALLOW_WATER) != 0 or \
		(flag & TileCollisionFlags.SEA) != 0

static func is_deep_ocean_tile(flag: int) -> bool:
	return flag == 4 or flag == 0x04 or (flag & TileCollisionFlags.DEEP_OCEAN) != 0

static func is_mountain_tile(flag: int) -> bool:
	return flag == 16 or flag == 0x10 or flag == 0x80 or \
		(flag & TileCollisionFlags.MOUNTAIN) != 0 or \
		(flag & TileCollisionFlags.HOT_SPRING) != 0

## Validates if a vehicle type can traverse a tile with the given collision flag.
## vehicle: 0 = NONE (Foot), 1 = RAFT, 2 = BOAT, 3 = SHIP, 4 = PLANE
static func check_traversal(flag: int, vehicle: int) -> Dictionary:
	# 1. Solid obstacle / wall blocks everything
	if is_solid_obstacle(flag):
		return {"allowed": false, "reason": "Path is blocked by an obstacle."}
	
	# 2. Mountain / elevated peak (requires flying vehicle)
	if is_mountain_tile(flag):
		if vehicle == 4: # PLANE
			return {"allowed": true, "reason": ""}
		return {"allowed": false, "reason": "You need a flying vehicle to cross this terrain!"}
	
	# 3. Deep ocean (requires ship, steamship, or plane)
	if is_deep_ocean_tile(flag):
		if vehicle == 4 or vehicle == 3 or vehicle == 2: # PLANE, SHIP, BOAT
			return {"allowed": true, "reason": ""}
		elif vehicle == 1: # RAFT
			return {"allowed": false, "reason": "A fragile raft cannot cross deep ocean! You need a ship or advanced vehicle."}
		else:
			return {"allowed": false, "reason": "You need a ship or advanced vehicle to traverse deep ocean!"}
	
	# 4. Water / sea / shallow water (requires boat, raft, canoe, plane)
	if is_water_tile(flag):
		if vehicle != 0: # Any mounted vehicle
			return {"allowed": true, "reason": ""}
		return {"allowed": false, "reason": "You need a vehicle to traverse water!"}
	
	# 5. Normal walkable land
	return {"allowed": true, "reason": ""}
