class_name IsometricMath
extends RefCounted

## 2:1 axonometric isometric projection mathematics and 8-directional kinematics resolver.
## Matches the original Wonderland Online DirectDraw engine (rodraw2.dll).

const TILE_SCALE: int = 20
const DIAGONAL_VELOCITY_FACTOR: float = 0.7071067811865475 # 1 / sqrt(2)

## 8-directional heading constants matching authentic JMP sprite orientations (0..7)
## 0 = North (Back), 1 = North-West, 2 = West (Left), 3 = South-West,
## 4 = South (Front/Camera), 5 = South-East, 6 = East (Right), 7 = North-East.
enum Heading {
	NORTH = 0,
	NORTH_WEST = 1,
	WEST = 2,
	SOUTH_WEST = 3,
	SOUTH = 4,
	SOUTH_EAST = 5,
	EAST = 6,
	NORTH_EAST = 7
}

## Converts authentic Eve.emg 1-based clockwise rotation (1..8) to 0-based counter-clockwise heading (0..7) matching JMP sprite frame rows:
## 1 (North) -> 0 (NORTH)
## 2 (North-East) -> 7 (NORTH_EAST)
## 3 (East) -> 6 (EAST)
## 4 (South-East) -> 5 (SOUTH_EAST)
## 5 (South) -> 4 (SOUTH)
## 6 (South-West) -> 3 (SOUTH_WEST)
## 7 (West) -> 2 (WEST)
## 8 (North-West) -> 1 (NORTH_WEST)
static func rotation_to_heading(rotation: int) -> int:
	if rotation <= 0:
		return Heading.SOUTH
	return (8 - ((rotation - 1) % 8)) % 8

## Explicit alias for Eve.emg 1-based clockwise rotation conversion
static func eve_rotation_to_heading(rotation: int) -> int:
	return rotation_to_heading(rotation)

## Converts 0-based counter-clockwise heading (0..7) to authentic Eve.emg 1-based clockwise rotation (1..8):
static func heading_to_rotation(heading: int) -> int:
	return ((8 - (heading % 8)) % 8) + 1

## Converts 2D isometric world coordinates to screen pixel coordinates.
## Xs = Xw - Yw, Ys = (Xw + Yw) / 2
static func world_to_screen(world_pos: Vector2) -> Vector2:
	var screen_x: float = world_pos.x - world_pos.y
	var screen_y: float = (world_pos.x + world_pos.y) * 0.5
	return Vector2(screen_x, screen_y)

## Converts screen pixel coordinates to 2D isometric world coordinates.
## Xw = (2 * Ys + Xs) / 2, Yw = (2 * Ys - Xs) / 2
static func screen_to_world(screen_pos: Vector2) -> Vector2:
	var world_x: float = (2.0 * screen_pos.y + screen_pos.x) * 0.5
	var world_y: float = (2.0 * screen_pos.y - screen_pos.x) * 0.5
	return Vector2(world_x, world_y)

## Converts world coordinates to integer tile grid indices (20 px per grid unit).
static func world_to_tile(world_pos: Vector2) -> Vector2i:
	var gx: int = int(floor(world_pos.x / float(TILE_SCALE)))
	var gy: int = int(floor(world_pos.y / float(TILE_SCALE)))
	return Vector2i(gx, gy)

## Converts integer tile grid coordinates to world coordinates.
## If center is true, returns the center of the tile; otherwise returns top-left world corner.
static func tile_to_world(grid_pos: Vector2i, center: bool = true) -> Vector2:
	var offset: float = 0.5 if center else 0.0
	var wx: float = (float(grid_pos.x) + offset) * float(TILE_SCALE)
	var wy: float = (float(grid_pos.y) + offset) * float(TILE_SCALE)
	return Vector2(wx, wy)

## Converts integer tile grid coordinates directly to screen coordinates.
static func tile_to_screen(grid_pos: Vector2i, center: bool = true) -> Vector2:
	return world_to_screen(tile_to_world(grid_pos, center))

## Converts screen pixel coordinates directly to integer tile grid coordinates.
static func screen_to_tile(screen_pos: Vector2) -> Vector2i:
	return world_to_tile(screen_to_world(screen_pos))

## Returns the 4 screen vertices of the 2:1 isometric diamond representing a grid tile.
## Ordered: Top, Right, Bottom, Left.
static func get_tile_diamond_polygon(grid_pos: Vector2i) -> PackedVector2Array:
	var gx: float = float(grid_pos.x) * float(TILE_SCALE)
	var gy: float = float(grid_pos.y) * float(TILE_SCALE)
	var s: float = float(TILE_SCALE)
	
	var top: Vector2 = world_to_screen(Vector2(gx, gy))
	var right: Vector2 = world_to_screen(Vector2(gx + s, gy))
	var bottom: Vector2 = world_to_screen(Vector2(gx + s, gy + s))
	var left: Vector2 = world_to_screen(Vector2(gx, gy + s))
	
	return PackedVector2Array([top, right, bottom, left])

## Calculates the 8-directional heading (0..7) from source world pos to target world pos.
static func get_heading(from: Vector2, to: Vector2) -> int:
	var diff: Vector2 = to - from
	if diff.is_zero_approx():
		return Heading.SOUTH
	
	var angle_deg: float = rad_to_deg(diff.angle())
	if angle_deg < 0.0:
		angle_deg += 360.0
	
	if angle_deg >= 337.5 or angle_deg < 22.5:
		return Heading.EAST
	elif angle_deg >= 22.5 and angle_deg < 67.5:
		return Heading.SOUTH_EAST
	elif angle_deg >= 67.5 and angle_deg < 112.5:
		return Heading.SOUTH
	elif angle_deg >= 112.5 and angle_deg < 157.5:
		return Heading.SOUTH_WEST
	elif angle_deg >= 157.5 and angle_deg < 202.5:
		return Heading.WEST
	elif angle_deg >= 202.5 and angle_deg < 247.5:
		return Heading.NORTH_WEST
	elif angle_deg >= 247.5 and angle_deg < 292.5:
		return Heading.NORTH
	elif angle_deg >= 292.5 and angle_deg < 337.5:
		return Heading.NORTH_EAST
	return Heading.SOUTH

## Calculates the 8-directional heading from source tile to target tile.
static func get_tile_heading(from_tile: Vector2i, to_tile: Vector2i) -> int:
	if from_tile == to_tile:
		return Heading.SOUTH
	return get_heading(tile_to_world(from_tile), tile_to_world(to_tile))

## Returns the normalized 2D direction vector in screen coordinates corresponding to an 8-way heading.
static func get_heading_vector(heading: int) -> Vector2:
	match heading:
		Heading.NORTH:
			return Vector2(0.0, -1.0)
		Heading.NORTH_WEST:
			return Vector2(-DIAGONAL_VELOCITY_FACTOR, -DIAGONAL_VELOCITY_FACTOR)
		Heading.WEST:
			return Vector2(-1.0, 0.0)
		Heading.SOUTH_WEST:
			return Vector2(-DIAGONAL_VELOCITY_FACTOR, DIAGONAL_VELOCITY_FACTOR)
		Heading.SOUTH:
			return Vector2(0.0, 1.0)
		Heading.SOUTH_EAST:
			return Vector2(DIAGONAL_VELOCITY_FACTOR, DIAGONAL_VELOCITY_FACTOR)
		Heading.EAST:
			return Vector2(1.0, 0.0)
		Heading.NORTH_EAST:
			return Vector2(DIAGONAL_VELOCITY_FACTOR, -DIAGONAL_VELOCITY_FACTOR)
	return Vector2.ZERO

## Returns adjacent neighbor coordinates for a given tile.
## Includes 4 orthogonal and optionally 4 diagonal neighbors.
static func get_tile_neighbors(tile: Vector2i, include_diagonals: bool = true) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = [
		Vector2i(tile.x + 1, tile.y),
		Vector2i(tile.x - 1, tile.y),
		Vector2i(tile.x, tile.y + 1),
		Vector2i(tile.x, tile.y - 1)
	]
	if include_diagonals:
		neighbors.append(Vector2i(tile.x + 1, tile.y + 1))
		neighbors.append(Vector2i(tile.x - 1, tile.y + 1))
		neighbors.append(Vector2i(tile.x + 1, tile.y - 1))
		neighbors.append(Vector2i(tile.x - 1, tile.y - 1))
	return neighbors

## Calculates Euclidean distance in tile units.
static func distance_tiles(a: Vector2i, b: Vector2i) -> float:
	var dx: float = float(a.x - b.x)
	var dy: float = float(a.y - b.y)
	return sqrt(dx * dx + dy * dy)
