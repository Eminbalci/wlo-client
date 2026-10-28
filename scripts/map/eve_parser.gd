class_name EveParser
extends RefCounted

## Pure binary parser for Wonderland Online Eve.emg data.
## Extracts authentic WarpLoc entries, ItemAreas (native ground item spawns),
## and Category 0 NPC entries with authentic coordinates, rotation, walksteps and events.
## Cross-referenced with wlo.pserver.core/Game/Maps/Map.cs.

const IsometricMath = preload("res://scripts/map/isometric_math.gd")

class NpcSpawnInfo:
	var click_id: int = 0
	var name: String = ""
	var entity_type: int = 0
	var world_x: int = 0
	var world_y: int = 0
	var wx: int:
		get: return world_x
		set(v): world_x = v
	var wy: int:
		get: return world_y
		set(v): world_y = v
	var world_pos: Vector2 = Vector2.ZERO
	var npc_id: int = 0
	var rotation: int = 5
	var heading: int = IsometricMath.Heading.SOUTH
	var walk_behavior: int = 1
	var walksteps: Array[Vector2] = []
	var walkstep_delays: Array[float] = []
	var events: Array[int] = []
	var source_map_id: int = 0

	func _init(p_cid: int, p_name: String, p_type: int, p_x: int, p_y: int, p_nid: int, p_rot: int, p_beh: int, p_steps: Array[Vector2], p_delays: Array[float], p_events: Array[int], p_smap: int = 0) -> void:
		click_id = p_cid
		name = p_name
		entity_type = p_type
		world_x = p_x
		world_y = p_y
		world_pos = Vector2(p_x, p_y)
		npc_id = p_nid
		rotation = p_rot
		heading = IsometricMath.rotation_to_heading(p_rot)
		walk_behavior = p_beh
		walksteps = p_steps
		walkstep_delays = p_delays
		events = p_events
		source_map_id = p_smap

class EntryPoint:
	var click_id: int = 0
	var name: String = ""
	var grid_x: int = 0
	var grid_y: int = 0
	var min_cell: Vector2i = Vector2i.ZERO
	var max_cell: Vector2i = Vector2i.ZERO
	var center_px: Vector2 = Vector2.ZERO
	var trigger_type: int = 0
	var event_ids: Array[int] = []
	var world_x: int = 0
	var world_y: int = 0

	func _init(p_cid: int, p_name: String, p_gx: int, p_gy: int, p_min_cell: Vector2i = Vector2i.ZERO, p_max_cell: Vector2i = Vector2i.ZERO, p_center: Vector2 = Vector2.ZERO, p_trig: int = 0, p_events: Array[int] = []) -> void:
		click_id = p_cid
		name = p_name
		grid_x = p_gx
		grid_y = p_gy
		min_cell = p_min_cell
		max_cell = p_max_cell
		center_px = p_center
		trigger_type = p_trig
		event_ids = p_events
		world_x = int(p_center.x) if p_center != Vector2.ZERO else p_gx * 20
		world_y = int(p_center.y) if p_center != Vector2.ZERO else p_gy * 20

class WarpInfo:
	var click_id: int = 0
	var name: String = ""
	var target_map_id: int = 0
	var dest_x: int = 0
	var dest_y: int = 0
	var source_map_id: int = 0
	var world_x: int = 0
	var world_y: int = 0

	func _init(p_cid: int, p_name: String, p_tmap: int, p_dx: int, p_dy: int, p_smap: int = 0) -> void:
		click_id = p_cid
		name = p_name
		target_map_id = p_tmap
		dest_x = p_dx
		dest_y = p_dy
		source_map_id = p_smap

class GroundItemSpawn:
	var click_id: int = 0
	var slot: int = 0
	var name: String = ""
	var world_x: int = 0
	var world_y: int = 0
	var item_id: int = 0
	var respawn_seconds: int = 120
	var source_map_id: int = 0

	func _init(p_cid: int, p_slot: int, p_name: String, p_x: int, p_y: int, p_item_id: int, p_respawn: int = 120, p_smap: int = 0) -> void:
		click_id = p_cid
		slot = p_slot
		name = p_name
		world_x = p_x
		world_y = p_y
		item_id = p_item_id
		respawn_seconds = p_respawn if p_respawn > 0 else 120
		source_map_id = p_smap

class MapEveHeader:
	var map_id: int = 0
	var scene_id: int = 0
	var data_ptr: int = 0
	var data_len: int = 0

class PreEventAction:
	var action_op: int = 0
	var target_click_id: int = 0
	var action_type: int = 0 # 2=Hide, 3=Show, 5=PropState, 7=Pose
	var state1: int = 0
	var state2: int = 0
	var raw_data: PackedByteArray = PackedByteArray()

class PreEventRule:
	var condition_op: int = 0
	var word1: int = 0
	var word2: int = 0
	var word3: int = 0
	var value: int = 0
	var comparison: int = 0
	var raw_condition: PackedByteArray = PackedByteArray()
	var sub_conditions: Array[PreEventRule] = []
	var actions: Array[PreEventAction] = []

class PreEventEntry:
	var click_id: int = 0
	var name: String = ""
	var rules: Array[PreEventRule] = []

var eve_file_path: String = "res://assets/data/Eve.emg"
var _map_headers: Dictionary = {} # int (map_id) -> MapEveHeader
var _warps_cache: Dictionary = {} # int (map_id) -> Array[WarpInfo]
var _entry_points_cache: Dictionary = {} # int (map_id) -> Dictionary of int -> EntryPoint
var _items_cache: Dictionary = {} # int (map_id) -> Array[GroundItemSpawn]
var _npcs_cache: Dictionary = {} # int (map_id) -> Array[NpcSpawnInfo]
var _preevents_cache: Dictionary = {} # int (map_id) -> Array[PreEventEntry]
var _all_maps_cache: Dictionary = {} # String (map_id) -> Dictionary
var _is_initialized: bool = false

func _init(p_path: String = "") -> void:
	if not FileAccess.file_exists(eve_file_path) and FileAccess.file_exists("D:/GitHub/WLRI/data/Eve.emg"):
		eve_file_path = "D:/GitHub/WLRI/data/Eve.emg"
	if not p_path.is_empty():
		eve_file_path = p_path
	initialize()

## Initializes header table and indexes all maps in Eve.emg
func initialize() -> bool:
	if _is_initialized:
		return true
	
	# Load pre-extracted authoritative map metadata if available
	var json_paths: Array[String] = [
		"res://assets/data/all_maps.json",
		"D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/all_maps.json",
		"D:/GitHub/WLRI/data/all_maps.json"
	]
	for jp in json_paths:
		if FileAccess.file_exists(jp):
			var jf := FileAccess.open(jp, FileAccess.READ)
			if jf:
				var parsed = JSON.parse_string(jf.get_as_text())
				if parsed is Dictionary and not parsed.is_empty():
					_all_maps_cache = parsed
					break

	if not FileAccess.file_exists(eve_file_path):
		# If JSON cache is loaded, we can still index headers from cache
		if not _all_maps_cache.is_empty():
			for k in _all_maps_cache.keys():
				var mdata: Dictionary = _all_maps_cache[k]
				var hdr := MapEveHeader.new()
				hdr.map_id = int(mdata.get("map_id", int(k)))
				hdr.scene_id = int(mdata.get("scene_id", hdr.map_id))
				_map_headers[hdr.map_id] = hdr
			_is_initialized = not _map_headers.is_empty()
			return _is_initialized
		push_error("Eve.emg not found at path: %s" % eve_file_path)
		return false
	
	var file := FileAccess.open(eve_file_path, FileAccess.READ)
	if not file:
		push_error("Cannot open Eve.emg: %s" % eve_file_path)
		return false
	
	var file_len := file.get_length()
	if file_len < 12:
		return false
	
	file.seek(8)
	var num_entries := file.get_32()
	_map_headers.clear()
	
	for i in range(num_entries):
		if file.get_position() + 10 > file_len:
			break
		var hdr := MapEveHeader.new()
		hdr.map_id = file.get_16()
		hdr.scene_id = file.get_16()
		hdr.data_ptr = file.get_32()
		hdr.data_len = file.get_16()
		_map_headers[hdr.map_id] = hdr
	
	_is_initialized = not _map_headers.is_empty()
	return _is_initialized

func has_map(map_id: int) -> bool:
	return _map_headers.has(map_id)

func get_scene_id(map_id: int) -> int:
	if not _is_initialized:
		initialize()
	var s_mid := str(map_id)
	if _all_maps_cache.has(s_mid):
		var m: Dictionary = _all_maps_cache[s_mid]
		return int(m.get("scene_id", map_id))
	var hdr: MapEveHeader = _map_headers.get(map_id)
	if hdr:
		return hdr.scene_id
	return map_id

func get_total_maps() -> int:
	return _map_headers.size()

func get_all_map_ids() -> Array[int]:
	if not _is_initialized:
		initialize()
	var ids: Array[int] = []
	for k in _map_headers.keys():
		ids.append(int(k))
	ids.sort()
	return ids

func get_total_npc_spawns() -> int:
	if not _is_initialized:
		initialize()
	var total: int = 0
	for mid in _map_headers.keys():
		total += get_npcs_for_map(mid).size()
	return total

func get_total_warps() -> int:
	if not _is_initialized:
		initialize()
	var total: int = 0
	for mid in _map_headers.keys():
		total += get_warps_for_map(mid).size()
	return total

## Retrieves comprehensive summary for a map (name, bgm, background graphic info, entity counts).
func get_map_summary(map_id: int) -> Dictionary:
	if not _is_initialized:
		initialize()
	
	var s_mid := str(map_id)
	if _all_maps_cache.has(s_mid):
		var m: Dictionary = _all_maps_cache[s_mid]
		return {
			"map_id": int(m.get("map_id", map_id)),
			"scene_id": int(m.get("scene_id", map_id)),
			"name": String(m.get("name", "Map_%d" % map_id)),
			"bgm_name": String(m.get("bgm_name", "")),
			"bgm_id": int(m.get("bgm_id", 0)),
			"has_bg": bool(m.get("has_bg", false)),
			"bg_file": String(m.get("bg_file", "")),
			"bg_archive": String(m.get("bg_archive", "")),
			"npc_count": int(m.get("npc_count", 0)),
			"warp_count": int(m.get("warp_count", 0)),
			"item_count": int(m.get("item_count", 0)),
			"entry_count": int(m.get("entry_count", 0))
		}
	
	var hdr: MapEveHeader = _map_headers.get(map_id)
	if not hdr:
		return {}
	
	var warps := get_warps_for_map(map_id)
	var items := get_ground_items_for_map(map_id)
	var npcs := get_npcs_for_map(map_id)
	
	return {
		"map_id": hdr.map_id,
		"scene_id": hdr.scene_id,
		"name": "Map_%d" % hdr.map_id,
		"bgm_name": "",
		"bgm_id": 0,
		"has_bg": false,
		"bg_file": "",
		"bg_archive": "",
		"npc_count": npcs.size(),
		"warp_count": warps.size(),
		"item_count": items.size(),
		"entry_count": 0
	}

## Searches maps by name (case-insensitive substring match).
func search_maps_by_name(query: String) -> Array[Dictionary]:
	if not _is_initialized:
		initialize()
	var res: Array[Dictionary] = []
	var q := query.strip_edges().to_lower()
	var all_ids := get_all_map_ids()
	for mid in all_ids:
		var summary := get_map_summary(mid)
		if q.is_empty() or String(summary.get("name", "")).to_lower().contains(q):
			res.append(summary)
	return res

## Decodes clean string from byte slice, trimming null bytes and control chars without triggering Unicode errors
static func decode_eve_string(bytes: PackedByteArray, default_fallback: String = "Entry") -> String:
	var nul := bytes.find(0)
	if nul != -1:
		bytes = bytes.slice(0, nul)
	
	# Check for printable ASCII
	var clean := PackedByteArray()
	for b in bytes:
		if b >= 32 and b <= 126:
			clean.append(b)
	
	var ascii_str := clean.get_string_from_ascii().strip_edges()
	if not ascii_str.is_empty():
		return ascii_str
	return default_fallback

## Reads map block and 11 category offsets
func _load_map_block(map_id: int) -> Dictionary:
	var hdr: MapEveHeader = _map_headers.get(map_id)
	if not hdr:
		return {}
	
	var file := FileAccess.open(eve_file_path, FileAccess.READ)
	if not file:
		return {}
	
	file.seek(hdr.data_ptr)
	var block := file.get_buffer(hdr.data_len)
	if block.size() < 44:
		return {}
	
	var off_base := block.size() - 44
	var cat_offsets: Array[int] = []
	for c in range(11):
		cat_offsets.append(block.decode_u32(off_base + c * 4))
	
	return {
		"block": block,
		"cat_offsets": cat_offsets
	}

## Loads and parses all WarpLoc entries for a given map_id
func get_warps_for_map(map_id: int) -> Array[WarpInfo]:
	if _warps_cache.has(map_id):
		return _warps_cache[map_id]
	
	var res: Array[WarpInfo] = []
	var data := _load_map_block(map_id)
	if data.is_empty():
		_warps_cache[map_id] = res
		return res
	
	var block: PackedByteArray = data["block"]
	var cat_offsets: Array = data["cat_offsets"]
	var w_off: int = cat_offsets[6] # Category 6 = WarpLoc
	
	if w_off <= 0 or w_off + 2 > block.size():
		_warps_cache[map_id] = res
		return res
	
	var ptr := w_off
	var count := block.decode_u16(ptr)
	ptr += 2
	
	for i in range(count):
		if ptr + 35 > block.size():
			break
		var cid := block.decode_u16(ptr); ptr += 2
		var name_slice := block.slice(ptr, ptr + 20); ptr += 20
		var w_name := decode_eve_string(name_slice, "Warp_%d" % cid)
		var tmap := block.decode_u16(ptr); ptr += 2
		var dx := block.decode_u32(ptr); ptr += 4
		var dy := block.decode_u32(ptr); ptr += 4
		# skip 3 unknown bytes
		ptr += 3
		
		var warp := WarpInfo.new(cid, w_name, tmap, dx, dy, map_id)
		res.append(warp)
	
	var entries := get_entry_points_for_map(map_id)
	for warp in res:
		if entries.has(warp.click_id):
			var ep: EntryPoint = entries[warp.click_id]
			warp.world_x = ep.world_x
			warp.world_y = ep.world_y
	
	_warps_cache[map_id] = res
	return res

## Loads and parses all Entry Points (Category 1) for a given map_id
func get_entry_points_for_map(map_id: int) -> Dictionary:
	if _entry_points_cache.has(map_id):
		return _entry_points_cache[map_id]
	
	var res: Dictionary = {}
	var data := _load_map_block(map_id)
	if data.is_empty():
		_entry_points_cache[map_id] = res
		return res
	
	var block: PackedByteArray = data["block"]
	var cat_offsets: Array = data["cat_offsets"]
	var e_off: int = cat_offsets[1] # Category 1 = Entry Points
	
	if e_off <= 0 or e_off + 2 > block.size():
		_entry_points_cache[map_id] = res
		return res
	
	var ptr := e_off
	var count := block.decode_u16(ptr)
	ptr += 2
	
	for i in range(count):
		if ptr >= block.size():
			break
		var click_id := block.decode_u16(ptr); ptr += 2
		if ptr + 20 > block.size():
			break
		var name_slice := block.slice(ptr, ptr + 20); ptr += 20
		var name := decode_eve_string(name_slice, "Entry_%d" % click_id)
		
		if ptr >= block.size():
			break
		var ub1 := block[ptr]; ptr += 1
		if ptr + 4 > block.size():
			break
		var min_cx := block.decode_u32(ptr); ptr += 4
		if ptr + 4 > block.size():
			break
		var min_cy := block.decode_u32(ptr); ptr += 4
		
		if ptr >= block.size():
			break
		var b1 := block[ptr]; ptr += 1
		var event_ids: Array[int] = []
		for e in range(b1):
			if ptr >= block.size():
				break
			event_ids.append(block[ptr])
			ptr += 1
		
		if ptr >= block.size():
			break
		var b2 := block[ptr]; ptr += 1
		ptr += b2
		
		if ptr >= block.size():
			break
		var ub2 := block[ptr]; ptr += 1
		
		if ptr + 8 > block.size():
			break
		var max_cx := block.decode_u32(ptr); ptr += 4
		var max_cy := block.decode_u32(ptr); ptr += 4
		
		if ptr >= block.size():
			break
		var trigger_type := block[ptr]; ptr += 1
		
		# skip unknowndword3, unknowndword4 (8 bytes)
		ptr += 8
		
		var center_px := Vector2((min_cx + max_cx) * 10.0, (min_cy + max_cy) * 10.0)
		var world_x := int(center_px.x)
		var world_y := int(center_px.y)
		var grid_x := int(min_cx)
		var grid_y := int(min_cy)
		
		var ep := EntryPoint.new(
			click_id, name, grid_x, grid_y,
			Vector2i(min_cx, min_cy), Vector2i(max_cx, max_cy),
			center_px, trigger_type, event_ids
		)
		ep.world_x = world_x
		ep.world_y = world_y
		res[click_id] = ep
	
	_entry_points_cache[map_id] = res
	return res

## Loads and parses all ItemAreas (native ground items) for a given map_id
## Cross-referenced with Map.cs lines 286-325
func get_ground_items_for_map(map_id: int) -> Array[GroundItemSpawn]:
	if _items_cache.has(map_id):
		return _items_cache[map_id]
	
	var res: Array[GroundItemSpawn] = []
	var data := _load_map_block(map_id)
	if data.is_empty():
		_items_cache[map_id] = res
		return res
	
	var block: PackedByteArray = data["block"]
	var cat_offsets: Array = data["cat_offsets"]
	var item_off: int = cat_offsets[3] # Category 3 = ItemAreas
	
	if item_off <= 0 or item_off + 2 > block.size():
		_items_cache[map_id] = res
		return res
	
	var ptr := item_off
	var count := block.decode_u16(ptr)
	ptr += 2
	var slot_idx: int = 1
	
	for i in range(count):
		if ptr + 35 > block.size():
			break
		var cid := block.decode_u16(ptr); ptr += 2
		var nlen := block[ptr]; ptr += 1
		var name_slice := block.slice(ptr, ptr + 19); ptr += 19
		var iname := decode_eve_string(name_slice, "Resource")
		var _ub1 := block[ptr]; ptr += 1
		var wx := block.decode_u32(ptr); ptr += 4
		var wy := block.decode_u32(ptr); ptr += 4
		
		var blen1 := block[ptr]; ptr += 1 + blen1
		var blen2 := block[ptr]; ptr += 1 + blen2
		var _ub2 := block[ptr]; ptr += 1
		var iid := block.decode_u32(ptr); ptr += 4
		# skip 3 unknown bytes
		ptr += 3
		var respawn_word := block.decode_u16(ptr); ptr += 2
		var _uw2 := block.decode_u16(ptr); ptr += 2
		
		# Validation from Map.cs line 298
		if iid == 0 or (wx == 0 and wy == 0):
			continue
		
		var respawn_sec: int = respawn_word if respawn_word > 0 else 120
		var slot: int = cid if (cid > 0 and cid < 256) else slot_idx
		slot_idx += 1
		
		var spawn := GroundItemSpawn.new(cid, slot, iname, wx, wy, iid, respawn_sec, map_id)
		res.append(spawn)
	
	_items_cache[map_id] = res
	return res

## Returns a specific warp by click_id on map_id
func get_warp_by_id(map_id: int, click_id: int) -> WarpInfo:
	var warps := get_warps_for_map(map_id)
	for w in warps:
		if w.click_id == click_id:
			return w
	return null

## Loads and parses all authentic NPC entries (Category 0) for a given map_id
func get_npcs_for_map(map_id: int) -> Array[NpcSpawnInfo]:
	if _npcs_cache.has(map_id):
		return _npcs_cache[map_id]
	
	var res: Array[NpcSpawnInfo] = []
	var data := _load_map_block(map_id)
	if data.is_empty():
		_npcs_cache[map_id] = res
		return res
	
	var block: PackedByteArray = data["block"]
	var cat_offsets: Array = data["cat_offsets"]
	var npc_off: int = cat_offsets[0] # Category 0 = NPCs
	
	if npc_off <= 0 or npc_off + 2 > block.size():
		_npcs_cache[map_id] = res
		return res
	
	var ptr := npc_off
	var count := block.decode_u16(ptr)
	ptr += 2
	
	for i in range(count):
		if ptr + 30 > block.size():
			break
		var cid := block.decode_u16(ptr); ptr += 2
		var name_slice := block.slice(ptr, ptr + 20); ptr += 20
		var nname := decode_eve_string(name_slice, "NPC_%d" % cid)
		var ent_type := block[ptr]; ptr += 1
		var wx := block.decode_u32(ptr); ptr += 4
		var wy := block.decode_u32(ptr); ptr += 4
		
		var events_len := block[ptr]; ptr += 1
		var events: Array[int] = []
		for e in range(events_len):
			events.append(block[ptr]); ptr += 1
		
		var unk2_len := block[ptr]; ptr += 1
		ptr += unk2_len
		var _ub2 := block[ptr]; ptr += 1
		var nid := block.decode_u32(ptr); ptr += 4
		var rot := block[ptr]; ptr += 1
		var behavior := block[ptr]; ptr += 1
		var _ub5 := block[ptr]; ptr += 1
		
		var steps_len := block[ptr]; ptr += 1
		var walksteps: Array[Vector2] = []
		var walkstep_delays: Array[float] = []
		for s in range(steps_len):
			var sx := block.decode_u32(ptr); ptr += 4
			var sy := block.decode_u32(ptr); ptr += 4
			var sdelay := block.decode_u32(ptr); ptr += 4
			walksteps.append(Vector2(sx, sy))
			walkstep_delays.append(float(sdelay) / 1000.0 if sdelay > 0 else 0.0)
		
		ptr += 2 # unk_b6, unk_b7
		ptr += 8 # unk_dw1, unk_dw2
		ptr += 3 # unk_b8, unk_b9, unk_b10
		var patterns_len := block[ptr]; ptr += 1
		ptr += patterns_len * 92
		ptr += 8 # w1, w2, w3, w4
		
		var spawn := NpcSpawnInfo.new(cid, nname, ent_type, wx, wy, nid, rot, behavior, walksteps, walkstep_delays, events, map_id)
		res.append(spawn)
	
	_npcs_cache[map_id] = res
	return res

## Event scripts of a map (category 4, layout from the C# server's EveLoader): [{click_id, name, subs: [{index, cond_byte,
## words[6], dwords[2], ops: [{index, opcode, d1, d2, d3, d4, dw[3]}]}]}]. A sub without ops is a condition that belongs to the
## branch before it.
var _events_cache: Dictionary = {}

func get_events_for_map(map_id: int) -> Array[Dictionary]:
	if _events_cache.has(map_id):
		return _events_cache[map_id]
	var res: Array[Dictionary] = []
	var data := _load_map_block(map_id)
	if data.is_empty():
		_events_cache[map_id] = res
		return res
	var block: PackedByteArray = data["block"]
	var off: int = data["cat_offsets"][4]
	if off <= 0 or off + 2 > block.size():
		_events_cache[map_id] = res
		return res
	var ptr := off
	var count := block.decode_u16(ptr)
	ptr += 2
	for a in range(count):
		if ptr + 25 > block.size():
			break
		var ev := {"click_id": block.decode_u16(ptr), "name": "", "subs": []}
		ptr += 2
		ptr += 1
		ev["name"] = decode_eve_string(block.slice(ptr, ptr + 20), "Event_%d" % ev["click_id"])
		ptr += 20
		var sub_count := block[ptr]
		ptr += 1
		for c in range(sub_count):
			if ptr + 25 > block.size():
				break
			var sub := {"index": block[ptr], "cond_byte": block[ptr + 1], "words": [], "dwords": [], "ops": []}
			ptr += 2
			for w in range(6):
				sub["words"].append(block.decode_u16(ptr))
				ptr += 2
			sub["dwords"] = [block.decode_u32(ptr), block.decode_u32(ptr + 4)]
			ptr += 8
			var op_count := block[ptr]
			ptr += 1
			for cs in range(op_count):
				if ptr + 22 > block.size():
					break
				var op := {"index": block[ptr], "opcode": block[ptr + 1], "d1": block.decode_u16(ptr + 2), "d2": block.decode_u16(ptr + 4), "d3": block.decode_u16(ptr + 6), "d4": block.decode_u16(ptr + 8), "dw": [block.decode_u32(ptr + 10), block.decode_u32(ptr + 14), block.decode_u32(ptr + 18)]}
				ptr += 22
				sub["ops"].append(op)
			ev["subs"].append(sub)
		res.append(ev)
	_events_cache[map_id] = res
	return res


## Returns a specific NPC by click_id on map_id
func get_npc_by_id(map_id: int, click_id: int) -> NpcSpawnInfo:
	var npcs := get_npcs_for_map(map_id)
	for n in npcs:
		if n.click_id == click_id:
			return n
	return null

## Loads and parses all PreEvent entries (Category 9) for a given map_id
## Cross-referenced with EveLoader.cs:836-903 and PreEventInterpreter.cs
func get_preevents_for_map(map_id: int) -> Array[PreEventEntry]:
	if _preevents_cache.has(map_id):
		return _preevents_cache[map_id]
	
	var res: Array[PreEventEntry] = []
	var data := _load_map_block(map_id)
	if data.is_empty():
		_preevents_cache[map_id] = res
		return res
	
	var block: PackedByteArray = data["block"]
	var cat_offsets: Array = data["cat_offsets"]
	if cat_offsets.size() < 10:
		_preevents_cache[map_id] = res
		return res
	
	var pre_off: int = cat_offsets[9] # Category 9 = PreEvents
	if pre_off <= 0 or pre_off + 2 > block.size():
		_preevents_cache[map_id] = res
		return res
	
	var ptr := pre_off
	var count := block.decode_u16(ptr)
	ptr += 2
	
	for a in range(count):
		if ptr + 23 > block.size():
			break
		var cid := block.decode_u16(ptr); ptr += 2
		var _ub1 := block[ptr]; ptr += 1
		var name_slice := block.slice(ptr, ptr + 20); ptr += 20
		var pe_name := decode_eve_string(name_slice, "PreEvent_%d" % cid)
		var blen := block[ptr]; ptr += 1
		
		var entry := PreEventEntry.new()
		entry.click_id = cid
		entry.name = pe_name
		
		var current_rule: PreEventRule = null
		
		for c in range(blen):
			if ptr + 22 > block.size():
				break
			var _sub_idx := block[ptr]; ptr += 1
			var cond_bytes := block.slice(ptr, ptr + 21); ptr += 21
			var blen2 := block[ptr]; ptr += 1
			
			var parsed_cond := PreEventRule.new()
			parsed_cond.raw_condition = cond_bytes
			parsed_cond.condition_op = cond_bytes[0]
			parsed_cond.word1 = cond_bytes.decode_u16(1)
			parsed_cond.word2 = cond_bytes.decode_u16(3)
			parsed_cond.word3 = cond_bytes.decode_u16(5)
			var w4 := cond_bytes.decode_u16(7)
			var w5 := cond_bytes.decode_u16(9)
			var w6 := cond_bytes.decode_u16(11)
			parsed_cond.value = (w4 >> 8) | (w5 << 8) | ((w6 & 0xFF) << 24)
			parsed_cond.comparison = w4 & 0xFF
			
			var has_actions := (blen2 > 0)
			if has_actions or current_rule == null:
				current_rule = parsed_cond
				entry.rules.append(current_rule)
			else:
				current_rule.sub_conditions.append(parsed_cond)
			
			for cl in range(blen2):
				if ptr + 22 > block.size():
					break
				var _act_sub_idx := block[ptr]; ptr += 1
				var act_bytes := block.slice(ptr, ptr + 21); ptr += 21
				var act := PreEventAction.new()
				act.raw_data = act_bytes
				act.action_op = act_bytes[0]
				act.target_click_id = act_bytes.decode_u16(1)
				act.action_type = act_bytes.decode_u16(3)
				act.state1 = act_bytes[8]
				act.state2 = act_bytes[9]
				current_rule.actions.append(act)
		
		res.append(entry)
	
	_preevents_cache[map_id] = res
	return res
