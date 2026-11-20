class_name InstanceProtocol
extends RefCounted

## Instance (dungeon) browser packets, AC 85 (Go client: team/instances.go, internal/protocol).
## Native layouts only: browse (1), create (3), status (2), membership (5), definitions (14) and the
## room snapshot (203). Room controls 200-202 are Gonline extensions whose native layouts are
## unverified, so they are not encoded here. Integers are little endian, strings are a 1-byte
## length followed by the bytes, as in the Go Builder and Reader.

const ACTION := 85
const BROWSE := 1
const STATUS := 2
const CREATE := 3
const MEMBERSHIP := 5
const DEFINITIONS := 14
const ROOM_SNAPSHOT := 203
const PAGE_SIZE := 5
const NAME_LIMIT := 28

const STATUS_UNAVAILABLE := 11
const STATUS_LEVEL_TOO_LOW := 2
const STATUS_ROOMS_FULL := 1
const STATUS_REJECTED := 255


## Browse request for a listing page: AC85 sub 1, page.
static func encode_browse(page: int) -> PackedByteArray:
	var p := page if page > 0 else 1
	return PackedByteArray([ACTION, BROWSE, p & 0xFF])


## Create-room request: AC85 sub 3, definition id (u16), room name (length-prefixed).
## Returns an empty array when the name cannot be encoded.
static func encode_create(definition_id: int, room_name: String) -> PackedByteArray:
	var raw := room_name.to_utf8_buffer()
	if raw.size() > 255:
		return PackedByteArray()
	var p := PackedByteArray([ACTION, CREATE, definition_id & 0xFF, (definition_id >> 8) & 0xFF, raw.size()])
	p.append_array(raw)
	return p


## Browse reply: AC85 sub 1 [pages u8, page u8, count u8, rows...]. Each row is id u16, creator
## string, name string, members u8, guild-bytes length u8 followed by that many bytes.
## Returns {pages, page, rows: [{id, creator, name, members}]} or {} when the packet is malformed.
static func parse_browse(p: PackedByteArray) -> Dictionary:
	var r := _Reader.new(p, 2)
	var pages := r.u8()
	var page := r.u8()
	var count := r.u8()
	if count > PAGE_SIZE:
		return {}
	var rows: Array = []
	for _i in count:
		var row := {"id": r.u16(), "creator": r.string(), "name": r.string(), "members": r.u8()}
		r.skip(r.u8())
		rows.append(row)
	if not r.ok() or r.remaining() != 0:
		return {}
	return {"pages": pages, "page": page, "rows": rows}


## Room snapshot: AC85 sub 203 [room u16, definition u16, count u8, members...]. A member is
## id u32, level u8, name string. A room id of 0 must carry no members.
## Returns {room, definition, members: [{id, level, name}]} or {} when malformed.
static func parse_room_snapshot(p: PackedByteArray) -> Dictionary:
	var r := _Reader.new(p, 2)
	var room := r.u16()
	var definition := r.u16()
	var count := r.u8()
	var members: Array = []
	for _i in count:
		members.append({"id": r.u32(), "level": r.u8(), "name": r.string()})
	if not r.ok() or r.remaining() != 0 or (room == 0 and count != 0):
		return {}
	return {"room": room, "definition": definition, "members": members}


## Status reply: AC85 sub 2 [code u8]. Returns the code, or -1 when malformed.
static func parse_status(p: PackedByteArray) -> int:
	var r := _Reader.new(p, 2)
	var code := r.u8()
	if not r.ok() or r.remaining() != 0:
		return -1
	return code


## Message shown for a status code (the Go wording, English here). Unknown codes name the number.
static func status_message(code: int) -> String:
	match code:
		STATUS_UNAVAILABLE:
			return "This instance is not available yet."
		STATUS_LEVEL_TOO_LOW:
			return "Your level is too low for this instance."
		STATUS_ROOMS_FULL:
			return "The instance room is full."
		STATUS_REJECTED:
			return "The instance request was rejected."
	return "Instance status %d." % code


## Definitions reply: AC85 sub 14 [count u8, (id u16, flag u8) * count]. Returns [{id, flag}] or [].
static func parse_definitions(p: PackedByteArray) -> Array:
	var r := _Reader.new(p, 2)
	var count := r.u8()
	var out: Array = []
	for _i in count:
		out.append({"id": r.u16(), "flag": r.u8()})
	if not r.ok() or r.remaining() != 0:
		return []
	return out


# --- C# server flavour (the original client's AC85, verified against a live capture) -----------------
# The Go layouts above are not what the C# server speaks: there AC85:1 creates or enters a room.
# These cover the C# server's own packets. Names in the roster have no length prefix on the wire, so
# the roster parser only resolves a single-member roster (the name is what precedes the last 4 bytes).

## Enter or create a room: AC85:1 [map u16, max members u8].
static func encode_enter(map_id: int, max_members: int = 4) -> PackedByteArray:
	return PackedByteArray([ACTION, BROWSE, map_id & 0xFF, (map_id >> 8) & 0xFF, clampi(max_members, 1, 255)])


## Room joined: AC85:4 [room u32, map u16, ...]. Returns {room, map} or {}.
static func parse_room_joined(p: PackedByteArray) -> Dictionary:
	var r := _Reader.new(p, 2)
	var room := r.u32()
	var map_id := r.u16()
	if not r.ok():
		return {}
	return {"room": room, "map": map_id}


## Instance started: AC85:5 [wave u8, pad u8, room u32, map u16]. Returns {wave, room, map} or {}.
static func parse_started(p: PackedByteArray) -> Dictionary:
	var r := _Reader.new(p, 2)
	var wave := r.u8()
	r.u8()
	var room := r.u32()
	var map_id := r.u16()
	if not r.ok():
		return {}
	return {"wave": wave, "room": room, "map": map_id}


## Roster: AC85:0 [map u16, count u8, (name bytes, char id u32)...]. Only count 0 or 1 is resolved,
## because the name carries no length. Returns {map, members: [{name, id}]} or {} when unresolved.
static func parse_roster(p: PackedByteArray) -> Dictionary:
	var r := _Reader.new(p, 2)
	var map_id := r.u16()
	var count := r.u8()
	if not r.ok() or count > 1:
		return {}
	if count == 0:
		return {"map": map_id, "members": []} if r.remaining() == 0 else {}
	var rest := r.remaining()
	if rest < 5:
		return {}
	var name_len := rest - 4
	var name := p.slice(5, 5 + name_len).get_string_from_utf8()
	var id := p[5 + name_len] | (p[6 + name_len] << 8) | (p[7 + name_len] << 16) | (p[8 + name_len] << 24)
	return {"map": map_id, "members": [{"name": name, "id": id}]}


## Minimal bounded reader mirroring the Go Reader: any overrun flags an error instead of crashing.
class _Reader:
	var _data: PackedByteArray
	var _pos: int
	var _error := false

	func _init(data: PackedByteArray, start: int) -> void:
		_data = data
		_pos = start

	func ok() -> bool:
		return not _error

	func remaining() -> int:
		return _data.size() - _pos

	func _take(n: int) -> PackedByteArray:
		if _error or n < 0 or _pos + n > _data.size():
			_error = true
			return PackedByteArray()
		var out := _data.slice(_pos, _pos + n)
		_pos += n
		return out

	func u8() -> int:
		var b := _take(1)
		return b[0] if b.size() == 1 else 0

	func u16() -> int:
		var b := _take(2)
		return b[0] | (b[1] << 8) if b.size() == 2 else 0

	func u32() -> int:
		var b := _take(4)
		return b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24) if b.size() == 4 else 0

	func skip(n: int) -> void:
		_take(n)

	func string() -> String:
		var n := u8()
		var b := _take(n)
		return b.get_string_from_utf8() if b.size() == n else ""
