class_name GroundParser
extends RefCounted

## Pure binary parser for Wonderland Online Ground.MMG and Wem.MMG archives.
## Parses isometric tilemap geometry, cell walkability grids, triggers, and warp points directly in memory.
## Cross-referenced with Eve.emg for authoritative warp destinations and native ground resources.

const EveParser = preload("res://scripts/map/eve_parser.gd")

## Portal style constants matching Portal.STYLE_DOOR / Portal.STYLE_SMALL_DOOR
const PORTAL_STYLE_DOOR: int       = 0
const PORTAL_STYLE_SMALL_DOOR: int = 1

class MMGEntry:
	var name: String
	var offset: int
	var size: int

	func _init(p_name: String, p_offset: int, p_size: int) -> void:
		name = p_name
		offset = p_offset
		size = p_size

class GroundTrigger:
	var event_id: int
	var world_x: int
	var world_y: int

	func _init(p_event_id: int, p_x: int, p_y: int) -> void:
		event_id = p_event_id
		world_x = p_x
		world_y = p_y

class WemEvent:
	var event_id: int
	var warp_id: int = 0
	var sub_id: int = 0
	var trigger_type: int = 1
	var param: int = 0
	var dest_x: int = 0
	var dest_y: int = 0
	var flag1: int = 0
	var flag2: int = 0
	var flag3: int = 0
	var target_map_id: int = 0

	func _init(p_id: int, p_type: int, p_param: int, p_x: int, p_y: int, p_f1: int, p_f2: int, p_f3: int, p_warp_id: int = 0, p_sub_id: int = 0) -> void:
		event_id = p_id
		trigger_type = p_type
		param = p_param
		dest_x = p_x
		dest_y = p_y
		flag1 = p_f1
		flag2 = p_f2
		flag3 = p_f3
		warp_id = p_warp_id
		sub_id = p_sub_id

class GroundMap:
	var map_id: int
	var sub_id: int
	var width_px: int
	var height_px: int
	var cols: int
	var rows: int
	var grid: PackedByteArray = PackedByteArray()
	var waypoints: Array[Vector3i] = [] # (x, y, flags)
	var triggers: Array[GroundTrigger] = []
	var map_name: String = ""
	var default_spawn: Vector2i = Vector2i.ZERO

	const TILE_SCALE: int = 20

	func is_walkable(grid_x: int, grid_y: int) -> bool:
		if grid_x < 0 or grid_x >= cols or grid_y < 0 or grid_y >= rows:
			return false
		var idx: int = grid_x * rows + grid_y
		if idx < 0 or idx >= grid.size():
			return false
		# 0 = Walkable, 1 = Solid Obstacle/Wall, 2 = Sea, 8 = Water, 16 = Mountain/Sky
		return grid[idx] == 0

	func get_tile_type(grid_x: int, grid_y: int) -> int:
		if grid_x < 0 or grid_x >= cols or grid_y < 0 or grid_y >= rows:
			return 1 # Treat out of bounds as solid wall
		var idx: int = grid_x * rows + grid_y
		if idx < 0 or idx >= grid.size():
			return 1
		return int(grid[idx])

	func world_to_grid(world_pos: Vector2) -> Vector2i:
		var gx: int = int(floor(world_pos.x / float(TILE_SCALE)))
		var gy: int = int(floor(world_pos.y / float(TILE_SCALE)))
		return Vector2i(gx, gy)

	func grid_to_world(grid_pos: Vector2i) -> Vector2:
		var wx: float = (float(grid_pos.x) + 0.5) * float(TILE_SCALE)
		var wy: float = (float(grid_pos.y) + 0.5) * float(TILE_SCALE)
		return Vector2(wx, wy)

var ground_file_path: String = "res://assets/data/Ground.MMG"
var wem_file_path: String = "res://assets/data/Wem.MMG"

var _ground_entries: Dictionary = {} # String (e.g. "10001.map") -> MMGEntry
var _wem_entries: Dictionary = {}    # String (e.g. "10001001.wem") -> MMGEntry
var _map_cache: Dictionary = {}      # int (map_id) -> GroundMap

var eve_parser: EveParser = null

func _init(p_ground_path: String = "", p_wem_path: String = "", p_eve_path: String = "") -> void:
	if not FileAccess.file_exists(ground_file_path) and FileAccess.file_exists("D:/GitHub/WLRI/data/Ground.MMG"):
		ground_file_path = "D:/GitHub/WLRI/data/Ground.MMG"
		wem_file_path = "D:/GitHub/WLRI/data/Wem.MMG"
	if not p_ground_path.is_empty():
		ground_file_path = p_ground_path
	if not p_wem_path.is_empty():
		wem_file_path = p_wem_path
	
	eve_parser = EveParser.new(p_eve_path)
	initialize_indices()

## Reads the directory table from the tail of both Ground.MMG and Wem.MMG.
func initialize_indices() -> bool:
	var ground_ok: bool = _index_mmg_archive(ground_file_path, _ground_entries)
	var wem_ok: bool = _index_mmg_archive(wem_file_path, _wem_entries)
	return ground_ok

func _index_mmg_archive(file_path: String, target_dict: Dictionary) -> bool:
	target_dict.clear()
	if not FileAccess.file_exists(file_path):
		push_error("MMG archive not found: %s" % file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Cannot open MMG file: %s" % file_path)
		return false
	
	var file_len: int = file.get_length()
	if file_len < 31: # At least 1 entry (29 bytes) + count (2 bytes)
		return false
	
	file.seek(file_len - 2)
	var entry_count: int = file.get_16()
	var table_size: int = entry_count * 29
	var table_offset: int = (file_len - 2) - table_size
	
	if table_offset < 0 or table_offset >= file_len:
		push_error("Corrupted MMG header/table in %s" % file_path)
		return false
	
	file.seek(table_offset)
	for i in range(entry_count):
		var name_len: int = file.get_8()
		var name_raw: PackedByteArray = file.get_buffer(12)
		var actual_len: int = mini(name_len, 12)
		var slice := name_raw.slice(0, actual_len)
		var nul_idx := slice.find(0)
		if nul_idx != -1:
			slice = slice.slice(0, nul_idx)
		var name_str: String = slice.get_string_from_ascii().strip_edges()
		
		# Skip 8 bytes timestamp/attributes
		file.seek(file.get_position() + 8)
		
		var offset: int = file.get_32()
		var size: int = file.get_32()
		
		if not name_str.is_empty():
			target_dict[name_str.to_lower()] = MMGEntry.new(name_str, offset, size)
	
	return true

## Checks if a map ID exists in Ground.MMG
func has_map(map_id: int) -> bool:
	var key: String = "%d.map" % map_id
	return _ground_entries.has(key)

## Loads and parses a map by map_id from Ground.MMG.
func load_map(map_id: int) -> GroundMap:
	if _map_cache.has(map_id):
		return _map_cache[map_id]
	
	var key: String = "%d.map" % map_id
	var entry: MMGEntry = _ground_entries.get(key)
	if not entry:
		push_error("Map not found in Ground.MMG: %s" % key)
		return null
	
	var file := FileAccess.open(ground_file_path, FileAccess.READ)
	if not file:
		return null
	
	file.seek(entry.offset)
	var data: PackedByteArray = file.get_buffer(entry.size)
	if data.size() < 19:
		push_error("Invalid map data length for map %d: %d" % [map_id, data.size()])
		return null
	
	var gmap := GroundMap.new()
	gmap.width_px = data.decode_u32(0)
	gmap.height_px = data.decode_u32(4)
	gmap.sub_id = data[8]
	gmap.map_id = data.decode_u16(9)
	gmap.cols = data.decode_u16(15)
	gmap.rows = data.decode_u16(17)
	
	var grid_size: int = gmap.cols * gmap.rows
	var grid_start: int = 19
	if grid_start + grid_size <= data.size():
		gmap.grid = data.slice(grid_start, grid_start + grid_size)
	else:
		push_error("Incomplete grid buffer for map %d (cols=%d, rows=%d)" % [map_id, gmap.cols, gmap.rows])
		gmap.grid = data.slice(grid_start)
	
	var cur_pos: int = grid_start + grid_size
	
	# Parse waypoints
	if cur_pos + 2 <= data.size():
		var wp_count: int = data.decode_u16(cur_pos)
		cur_pos += 2
		for w in range(wp_count):
			if cur_pos + 6 > data.size():
				break
			var wx: int = data.decode_u16(cur_pos)
			var wy: int = data.decode_u16(cur_pos + 2)
			var wf: int = data.decode_u16(cur_pos + 4)
			gmap.waypoints.append(Vector3i(wx, wy, wf))
			cur_pos += 6
	
	# Parse triggers / warps
	if cur_pos + 2 <= data.size():
		var trig_count: int = data.decode_u16(cur_pos)
		cur_pos += 2
		for t in range(trig_count):
			if cur_pos + 8 > data.size():
				break
			var eid: int = data.decode_u32(cur_pos)
			var tx: int = data.decode_u16(cur_pos + 4)
			var ty: int = data.decode_u16(cur_pos + 6)
			gmap.triggers.append(GroundTrigger.new(eid, tx, ty))
			cur_pos += 8
	
	# Parse map name and spawn position (remaining bytes)
	if cur_pos < data.size():
		var str_len: int = data[cur_pos]
		cur_pos += 1
		if cur_pos + str_len <= data.size():
			var name_bytes: PackedByteArray = data.slice(cur_pos, cur_pos + str_len)
			var nul_idx := name_bytes.find(0)
			if nul_idx != -1:
				name_bytes = name_bytes.slice(0, nul_idx)
			gmap.map_name = name_bytes.get_string_from_ascii()
			cur_pos += str_len
		
		# Skip padding bytes and read spawn coordinates
		while cur_pos + 4 < data.size() and data[cur_pos] == 0:
			cur_pos += 1
		
		if cur_pos + 4 <= data.size():
			var spawn_x: int = data.decode_u16(cur_pos)
			var spawn_y: int = data.decode_u16(cur_pos + 2)
			gmap.default_spawn = Vector2i(spawn_x, spawn_y)
	
	_map_cache[map_id] = gmap
	return gmap

## Loads and parses a single event record from Wem.MMG by event_id.
func load_wem_event(event_id: int) -> WemEvent:
	var key: String = "%d.wem" % event_id
	var entry: MMGEntry = _wem_entries.get(key)
	if not entry:
		return null
	
	var file := FileAccess.open(wem_file_path, FileAccess.READ)
	if not file:
		return null
	
	file.seek(entry.offset)
	var data: PackedByteArray = file.get_buffer(entry.size)
	if data.size() < 22:
		return null
	
	var eid: int = data.decode_u32(0)
	var warp_id: int = data.decode_u32(4)
	var sub_id: int = data.decode_u32(8)
	var t_type: int = data[12]
	var param: int = data.decode_u16(13)
	var dx: int = data.decode_u16(15)
	var dy: int = data.decode_u16(17)
	var f1: int = data[19]
	var f2: int = data[20]
	var f3: int = data[21]
	
	var event := WemEvent.new(eid, t_type, param, dx, dy, f1, f2, f3, warp_id, sub_id)
	
	# Automatically resolve target map id if warp_id matches Eve.emg
	if eve_parser:
		var source_map: int = int(floor(float(eid) / 1000.0))
		if warp_id > 0:
			var w_info = eve_parser.get_warp_by_id(source_map, warp_id)
			if w_info:
				event.target_map_id = w_info.target_map_id
	
	return event

## Resolves a single GroundTrigger into an authoritative Warp Event
func resolve_warp_for_trigger(trig: GroundTrigger, map_id: int) -> Dictionary:
	var event := load_wem_event(trig.event_id)
	var target_map: int = 0
	var dest_coords := Vector2.ZERO
	var p_name := "Portal"
	
	if event:
		if event.trigger_type == 4:
			# Intra-map teleport
			target_map = map_id
			dest_coords = Vector2(event.dest_x, event.dest_y)
			p_name = "Teleport"
		elif event.trigger_type == 1:
			if eve_parser and event.warp_id > 0:
				var w_info = eve_parser.get_warp_by_id(map_id, event.warp_id)
				if w_info:
					target_map = w_info.target_map_id
					dest_coords = Vector2(w_info.dest_x, w_info.dest_y)
					p_name = w_info.name
			
			# Fallback: find closest Eve warp
			if target_map == 0 and eve_parser:
				var eve_warps := eve_parser.get_warps_for_map(map_id)
				var best_dist := 180.0
				for ew in eve_warps:
					# Check against trigger location or known portal positions
					var test_pos := Vector2(trig.world_x, trig.world_y)
					var d := test_pos.distance_to(Vector2(ew.dest_x, ew.dest_y))
					if d < best_dist:
						best_dist = d
						target_map = ew.target_map_id
						dest_coords = Vector2(ew.dest_x, ew.dest_y)
						p_name = ew.name
	
	return {
		"event_id": trig.event_id,
		"world_pos": Vector2(trig.world_x, trig.world_y),
		"target_map_id": target_map,
		"dest_coords": dest_coords,
		"portal_name": p_name,
		"wem_event": event
	}

## Returns all authoritative warp portals for a map, ready for dynamic spawning
func get_map_warp_portals(map_id: int) -> Array[Dictionary]:
	var portals: Array[Dictionary] = []
	
	if not eve_parser:
		return portals
	
	var eve_warps := eve_parser.get_warps_for_map(map_id)
	var entry_points := eve_parser.get_entry_points_for_map(map_id)
	
	# Helper lambda or inner logic for bounds clamping on interior rooms
	var clamp_target = func(t_map: int, t_coords: Vector2) -> Vector2:
		if t_map in [12001, 12002, 12003, 12004, 12005]:
			if t_coords.x > 800 or t_coords.y > 600 or t_coords.x < 50 or t_coords.y < 50:
				return Vector2(400, 380)
		return t_coords

	# A) For ship maps (10001, 10002, 10003), use handcrafted verified bijective portals
	match map_id:
		10001:
			portals.append({
				"portal_id": 10001001,
				"portal_name": "Ship Cabin Entrance",
				"world_pos": Vector2(1814, 904),
				"target_map_id": 10002,
				"target_coords": Vector2(674, 1067),
				"trigger_radius": 56.0,
				"color": Color(0.3, 0.9, 0.4, 0.85),
				"portal_style": PORTAL_STYLE_DOOR
			})
			portals.append({
				"portal_id": 10001002,
				"portal_name": "Gangway to Island",
				"world_pos": Vector2(1038, 2235),
				"target_map_id": 10003,
				"target_coords": Vector2(134, 1126),
				"trigger_radius": 56.0,
				"color": Color(0.3, 0.9, 0.4, 0.85),
				"portal_style": PORTAL_STYLE_DOOR
			})
			return portals
		10002:
			portals.append({
				"portal_id": 10002001,
				"portal_name": "Exit to Ship Deck",
				"world_pos": Vector2(674, 1067),
				"target_map_id": 10001,
				"target_coords": Vector2(1814, 904),
				"trigger_radius": 56.0,
				"color": Color(0.3, 0.9, 0.4, 0.85),
				"portal_style": PORTAL_STYLE_SMALL_DOOR
			})
			portals.append({
				"portal_id": 10002002,
				"portal_name": "Stairs to Ship Kitchen / Bunk",
				"world_pos": Vector2(483, 631),
				"target_map_id": 10003,
				"target_coords": Vector2(483, 631),
				"trigger_radius": 56.0,
				"color": Color(0.3, 0.85, 0.5, 0.85),
				"portal_style": PORTAL_STYLE_SMALL_DOOR
			})
			return portals
		10003:
			portals.append({
				"portal_id": 10003001,
				"portal_name": "Stairs to Passenger Cabin",
				"world_pos": Vector2(420, 360),
				"target_map_id": 10002,
				"target_coords": Vector2(530, 670),
				"trigger_radius": 56.0,
				"color": Color(0.3, 0.9, 0.4, 0.85),
				"portal_style": PORTAL_STYLE_SMALL_DOOR
			})
			portals.append({
				"portal_id": 10003002,
				"portal_name": "Gangway to Main Deck",
				"world_pos": Vector2(134, 1126),
				"target_map_id": 10001,
				"target_coords": Vector2(1038, 2235),
				"trigger_radius": 56.0,
				"color": Color(0.3, 0.9, 0.4, 0.85),
				"portal_style": PORTAL_STYLE_DOOR
			})
			return portals

	# B) Warp-Centric resolution based on C# server Map.cs Priority A and B
	var claimed_eps: Dictionary = {}

	for w: EveParser.WarpInfo in eve_warps:
		if w.target_map_id == 0 or w.target_map_id == map_id:
			continue
		
		var rev_pos := Vector2.ZERO
		var dst_warps := eve_parser.get_warps_for_map(w.target_map_id)
		for rev_w in dst_warps:
			if rev_w.target_map_id == map_id:
				rev_pos = Vector2(rev_w.dest_x, rev_w.dest_y)
				break
		
		var best_ep: EveParser.EntryPoint = null
		
		# Priority 1: Check if an unclaimed Door (trigger_type == 2) within 600px matches event_ids
		if rev_pos != Vector2.ZERO:
			for cid in entry_points.keys():
				if claimed_eps.has(cid):
					continue
				var ep: EveParser.EntryPoint = entry_points[cid]
				if ep.trigger_type == 2 and (w.click_id in ep.event_ids or w.click_id == ep.click_id):
					if ep.center_px.distance_to(rev_pos) < 600.0:
						best_ep = ep
						break
		
		# Priority 2 (C# Priority A): Geometric reverse matching (closest unclaimed EP to rev_pos)
		if best_ep == null and rev_pos != Vector2.ZERO:
			var best_dist := 600.0
			for cid in entry_points.keys():
				if claimed_eps.has(cid):
					continue
				var ep: EveParser.EntryPoint = entry_points[cid]
				if ep.trigger_type in [1, 2, 3]:
					var d := ep.center_px.distance_to(rev_pos)
					if d < best_dist:
						best_dist = d
						best_ep = ep
		
		# Priority 3 (C# Priority B): Check if an unclaimed EP explicitly links via click_id or event_ids
		if best_ep == null:
			for cid in entry_points.keys():
				if claimed_eps.has(cid):
					continue
				var ep: EveParser.EntryPoint = entry_points[cid]
				if ep.trigger_type in [1, 2, 3]:
					if w.click_id == ep.click_id or w.click_id in ep.event_ids:
						best_ep = ep
						break

		# Priority 4: Fallback to any remaining unclaimed Door/Trigger EntryPoint on this map
		if best_ep == null:
			for cid in entry_points.keys():
				if claimed_eps.has(cid):
					continue
				var ep: EveParser.EntryPoint = entry_points[cid]
				if ep.trigger_type in [1, 2, 3]:
					best_ep = ep
					break

		var portal_pos := rev_pos
		var p_name: String = w.name if not w.name.is_empty() else "Portal_%d" % w.click_id
		var p_id: int = w.click_id
		if best_ep != null:
			claimed_eps[best_ep.click_id] = true
			portal_pos = best_ep.center_px
			p_name = best_ep.name if not best_ep.name.is_empty() else p_name
			p_id = best_ep.click_id
		elif portal_pos == Vector2.ZERO:
			var gmap: GroundMap = load_map(map_id)
			if gmap and not gmap.triggers.is_empty():
				portal_pos = Vector2(gmap.triggers[0].world_x, gmap.triggers[0].world_y)
			else:
				portal_pos = Vector2(w.dest_x, w.dest_y)

		var is_small_door: bool = false
		if map_id in [10002, 10003, 12001, 12002, 12003, 12004, 12005] or w.target_map_id in [12001, 12002, 12003, 12004, 12005]:
			is_small_door = true
		elif best_ep != null and best_ep.trigger_type == 2:
			is_small_door = true

		var t_coords: Vector2 = clamp_target.call(w.target_map_id, Vector2(w.dest_x, w.dest_y))
		portals.append({
			"portal_id": p_id,
			"portal_name": p_name,
			"world_pos": portal_pos,
			"target_map_id": w.target_map_id,
			"target_coords": t_coords,
			"trigger_radius": 56.0,
			"color": Color(0.2, 0.75, 1.0, 0.85),
			"portal_style": PORTAL_STYLE_SMALL_DOOR if is_small_door else PORTAL_STYLE_DOOR
		})

	return portals

## Returns all triggers for a specific map along with their Wem event definitions.
func get_map_triggers_with_events(map_id: int) -> Array[Dictionary]:
	var gmap: GroundMap = load_map(map_id)
	if not gmap:
		return []
	
	var result: Array[Dictionary] = []
	for trig in gmap.triggers:
		var event: WemEvent = load_wem_event(trig.event_id)
		result.append({
			"event_id": trig.event_id,
			"world_pos": Vector2(trig.world_x, trig.world_y),
			"grid_pos": gmap.world_to_grid(Vector2(trig.world_x, trig.world_y)),
			"event": event
		})
	return result

## Returns total number of indexed maps in Ground.MMG
func get_map_count() -> int:
	return _ground_entries.size()

## Returns total number of indexed events in Wem.MMG
func get_event_count() -> int:
	return _wem_entries.size()
