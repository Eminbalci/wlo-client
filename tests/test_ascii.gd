@tool
extends SceneTree

static func decode_reversed_string(bytes: PackedByteArray, start: int, length: int) -> String:
	if start < 0 or start + length > bytes.size() or length <= 0:
		return ""
	var rev := PackedByteArray()
	rev.resize(length)
	for i in range(length):
		rev[i] = bytes[start + length - 1 - i]
	# Find first null in reversed
	var null_pos := rev.find(0)
	if null_pos >= 0:
		rev = rev.slice(0, null_pos)
	if rev.is_empty():
		return ""
	var s := rev.get_string_from_utf8()
	if s.is_empty() and rev.size() > 0:
		s = rev.get_string_from_ascii()
	return s

func _init() -> void:
	# "kceD pihS\0\0\0" reversed with nulls
	var raw := PackedByteArray([0x00, 0x00, 0x6b, 0x63, 0x65, 0x44, 0x20, 0x70, 0x69, 0x68, 0x53])
	var s := decode_reversed_string(raw, 0, raw.size())
	print("Decoded string: '", s, "' (length=", s.length(), ")")
	quit(0)
