class_name Packet
extends RefCounted

## Binary packet serializer, deserializer, and payload builder for Wonderland Online.
## Supports little-endian integers, IEEE floats, length-prefixed strings, and action codes.

var _buffer: PackedByteArray = PackedByteArray()
var _read_offset: int = 0

func _init(initial_data: PackedByteArray = PackedByteArray()) -> void:
	_buffer = initial_data.duplicate()
	_read_offset = 0

## Factory constructor to initialize a packet with an action code and optional sub-code.
static func create(action_code: int = 0, sub_code: int = -1) -> Packet:
	var pkt := Packet.new()
	pkt.pack_u8(action_code)
	if sub_code >= 0:
		pkt.pack_u8(sub_code)
	return pkt

# ==============================================================================
# Packing / Serialization Methods
# ==============================================================================

## Packs an unsigned 8-bit byte.
func pack_u8(val: int) -> Packet:
	_buffer.append(val & 0xFF)
	return self

## Packs a signed 8-bit byte.
func pack_i8(val: int) -> Packet:
	_buffer.encode_s8(_buffer.size(), val)
	_buffer.resize(_buffer.size() + 1)
	return self

## Packs an unsigned 16-bit integer (little-endian).
func pack_u16(val: int) -> Packet:
	var old_size := _buffer.size()
	_buffer.resize(old_size + 2)
	_buffer.encode_u16(old_size, val)
	return self

## Packs a signed 16-bit integer (little-endian).
func pack_i16(val: int) -> Packet:
	var old_size := _buffer.size()
	_buffer.resize(old_size + 2)
	_buffer.encode_s16(old_size, val)
	return self

## Packs an unsigned 32-bit integer (little-endian).
func pack_u32(val: int) -> Packet:
	var old_size := _buffer.size()
	_buffer.resize(old_size + 4)
	_buffer.encode_u32(old_size, val)
	return self

## Packs a signed 32-bit integer (little-endian).
func pack_i32(val: int) -> Packet:
	var old_size := _buffer.size()
	_buffer.resize(old_size + 4)
	_buffer.encode_s32(old_size, val)
	return self

## Packs an unsigned 64-bit integer (little-endian).
func pack_u64(val: int) -> Packet:
	var old_size := _buffer.size()
	_buffer.resize(old_size + 8)
	_buffer.encode_u64(old_size, val)
	return self

## Packs a 32-bit IEEE float (little-endian).
func pack_float(val: float) -> Packet:
	var old_size := _buffer.size()
	_buffer.resize(old_size + 4)
	_buffer.encode_float(old_size, val)
	return self

## Packs a 64-bit IEEE double (little-endian).
func pack_double(val: float) -> Packet:
	var old_size := _buffer.size()
	_buffer.resize(old_size + 8)
	_buffer.encode_double(old_size, val)
	return self

## Packs a boolean (1 byte, 1 for true, 0 for false).
func pack_bool(val: bool) -> Packet:
	return pack_u8(1 if val else 0)

## Packs a length-prefixed ASCII string (1-byte length followed by characters).
func pack_string(val: String) -> Packet:
	var ascii_bytes := val.to_ascii_buffer()
	var length := mini(ascii_bytes.size(), 255)
	pack_u8(length)
	if length > 0:
		_buffer.append_array(ascii_bytes.slice(0, length))
	return self

## Packs a raw ASCII string without length prefix.
func pack_string_n(val: String) -> Packet:
	var ascii_bytes := val.to_ascii_buffer()
	if not ascii_bytes.is_empty():
		_buffer.append_array(ascii_bytes)
	return self

## Packs raw bytes.
func pack_bytes(data: PackedByteArray) -> Packet:
	if not data.is_empty():
		_buffer.append_array(data)
	return self

# ==============================================================================
# Unpacking / Deserialization Methods
# ==============================================================================

## Unpacks an unsigned 8-bit integer.
func unpack_u8() -> int:
	if _read_offset >= _buffer.size():
		return 0
	var val: int = _buffer[_read_offset]
	_read_offset += 1
	return val

## Unpacks a signed 8-bit integer.
func unpack_i8() -> int:
	if _read_offset >= _buffer.size():
		return 0
	var val := _buffer.decode_s8(_read_offset)
	_read_offset += 1
	return val

## Unpacks an unsigned 16-bit integer (little-endian).
func unpack_u16() -> int:
	if _read_offset + 2 > _buffer.size():
		return 0
	var val := _buffer.decode_u16(_read_offset)
	_read_offset += 2
	return val

## Unpacks a signed 16-bit integer (little-endian).
func unpack_i16() -> int:
	if _read_offset + 2 > _buffer.size():
		return 0
	var val := _buffer.decode_s16(_read_offset)
	_read_offset += 2
	return val

## Unpacks an unsigned 32-bit integer (little-endian).
func unpack_u32() -> int:
	if _read_offset + 4 > _buffer.size():
		return 0
	var val := _buffer.decode_u32(_read_offset)
	_read_offset += 4
	return val

## Unpacks a signed 32-bit integer (little-endian).
func unpack_i32() -> int:
	if _read_offset + 4 > _buffer.size():
		return 0
	var val := _buffer.decode_s32(_read_offset)
	_read_offset += 4
	return val

## Unpacks an unsigned 64-bit integer (little-endian).
func unpack_u64() -> int:
	if _read_offset + 8 > _buffer.size():
		return 0
	var val := _buffer.decode_u64(_read_offset)
	_read_offset += 8
	return val

## Unpacks a 32-bit IEEE float (little-endian).
func unpack_float() -> float:
	if _read_offset + 4 > _buffer.size():
		return 0.0
	var val := _buffer.decode_float(_read_offset)
	_read_offset += 4
	return val

## Unpacks a 64-bit IEEE double (little-endian).
func unpack_double() -> float:
	if _read_offset + 8 > _buffer.size():
		return 0.0
	var val := _buffer.decode_double(_read_offset)
	_read_offset += 8
	return val

## Unpacks a boolean.
func unpack_bool() -> bool:
	return unpack_u8() != 0

## Unpacks a 1-byte length-prefixed ASCII string.
func unpack_string() -> String:
	var length := unpack_u8()
	if length <= 0 or _read_offset + length > _buffer.size():
		return ""
	var slice := _buffer.slice(_read_offset, _read_offset + length)
	_read_offset += length
	var nul_idx := slice.find(0)
	if nul_idx != -1:
		slice = slice.slice(0, nul_idx)
	return slice.get_string_from_ascii()

## Unpacks remaining bytes as an ASCII string or up to max_len bytes.
func unpack_string_n(max_len: int = -1) -> String:
	var remaining := _buffer.size() - _read_offset
	if remaining <= 0:
		return ""
	var length := remaining if max_len < 0 else mini(remaining, max_len)
	var slice := _buffer.slice(_read_offset, _read_offset + length)
	_read_offset += length
	var nul_idx := slice.find(0)
	if nul_idx != -1:
		slice = slice.slice(0, nul_idx)
	return slice.get_string_from_ascii()

## Unpacks a slice of raw bytes.
func unpack_bytes(count: int) -> PackedByteArray:
	if count <= 0 or _read_offset >= _buffer.size():
		return PackedByteArray()
	var available := _buffer.size() - _read_offset
	var actual_count := mini(count, available)
	var slice := _buffer.slice(_read_offset, _read_offset + actual_count)
	_read_offset += actual_count
	return slice

# ==============================================================================
# Utility & Inspection Methods
# ==============================================================================

func get_read_offset() -> int:
	return _read_offset

func set_read_offset(offset: int) -> void:
	_read_offset = clampi(offset, 0, _buffer.size())

func get_remaining_bytes() -> int:
	return maxi(0, _buffer.size() - _read_offset)

func has_remaining() -> bool:
	return _read_offset < _buffer.size()

func get_action_code() -> int:
	return _buffer[0] if _buffer.size() > 0 else -1

func get_sub_code() -> int:
	return _buffer[1] if _buffer.size() > 1 else -1

func get_buffer() -> PackedByteArray:
	return _buffer

func size() -> int:
	return _buffer.size()

func clear() -> void:
	_buffer.clear()
	_read_offset = 0

## Formats the packet contents as a hex dump for debugging.
func to_hex_string() -> String:
	var hex_chars := []
	for b in _buffer:
		hex_chars.append("%02X" % b)
	return " ".join(hex_chars)

func _to_string() -> String:
	return "Packet(size=%d, ac=%d, sub=%d, offset=%d)" % [
		_buffer.size(),
		get_action_code(),
		get_sub_code(),
		_read_offset
	]
