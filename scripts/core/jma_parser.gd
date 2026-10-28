class_name JmaParser
extends RefCounted

## Pure binary parser for Wonderland Online JMA package archives and JMP sprite animations.
## Decodes 8-bit indexed palette sprites directly in-memory to Godot ImageTexture. Zero disk writes.

class JmaFileEntry:
	var name: String
	var size: int
	var offset: int

	func _init(p_name: String, p_size: int, p_offset: int) -> void:
		name = p_name
		size = p_size
		offset = p_offset

class JmpFrame:
	var name: String
	var bound_w: int
	var bound_h: int
	var pivot_x: int
	var pivot_y: int
	var frame_size: int
	var frame_offset: int
	var width: int
	var height: int
	var bpp: int
	var texture: ImageTexture
	var image: Image

class JmpAnimation:
	var name: String
	var version: int
	var data_offset: int
	var frame_count: int
	var frames: Array[JmpFrame] = []
	var palette_raw: PackedByteArray = PackedByteArray()
	var palette_rgba: PackedByteArray = PackedByteArray()
	var raw_jmp_bytes: PackedByteArray = PackedByteArray()

	func get_frame(index: int) -> JmpFrame:
		if index >= 0 and index < frames.size():
			return frames[index]
		return null

	func get_frame_by_name(frame_name: String) -> JmpFrame:
		var target := frame_name.to_lower()
		for frame in frames:
			if frame.name.to_lower() == target:
				return frame
		return null

	## Lazily decodes a single frame by name to ImageTexture
	func decode_frame_by_name(frame_name: String, bottom_up: bool = false) -> ImageTexture:
		var target := frame_name.to_lower()
		for i in range(frames.size()):
			if frames[i].name.to_lower() == target:
				return decode_frame(i, bottom_up)
		return null

	## Lazily decodes a single frame by name to Godot Image
	func decode_frame_image_by_name(frame_name: String, bottom_up: bool = false) -> Image:
		var target := frame_name.to_lower()
		for i in range(frames.size()):
			if frames[i].name.to_lower() == target:
				return decode_frame_image(i, bottom_up)
		return null

	## Lazily decodes a single frame to Godot Image on-demand
	func decode_frame_image(index: int, bottom_up: bool = false) -> Image:
		var frame := get_frame(index)
		if not frame:
			return null
		if frame.image != null:
			return frame.image
		
		frame.image = JmaParser.decode_frame_to_image(raw_jmp_bytes, frame, palette_rgba, bottom_up)
		return frame.image

	## Lazily decodes a single frame to ImageTexture on-demand
	func decode_frame(index: int, bottom_up: bool = false) -> ImageTexture:
		var frame := get_frame(index)
		if not frame:
			return null
		if frame.texture != null:
			return frame.texture
		
		frame.texture = JmaParser.decode_frame_to_texture(raw_jmp_bytes, frame, palette_rgba, bottom_up)
		return frame.texture

	## Decodes all frames in the animation eagerly
	func decode_all_frames(bottom_up: bool = false) -> void:
		for i in range(frames.size()):
			if frames[i].texture == null:
				frames[i].texture = JmaParser.decode_frame_to_texture(raw_jmp_bytes, frames[i], palette_rgba, bottom_up)

var _file_path: String = ""
var _entries: Dictionary = {} # String -> JmaFileEntry

static func open_jma(path: String) -> JmaParser:
	if not FileAccess.file_exists(path):
		push_error("JMA file not found: %s" % path)
		return null
	var parser := JmaParser.new()
	parser._file_path = path
	if not parser._read_index():
		return null
	return parser

func _read_index() -> bool:
	var file := FileAccess.open(_file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open JMA: %s" % _file_path)
		return false
	
	if file.get_length() < 14:
		push_error("JMA file too short: %s" % _file_path)
		return false
	
	var magic := file.get_buffer(2).get_string_from_ascii()
	if magic != "ja":
		push_error("Invalid JMA magic: %s (expected 'ja') in %s" % [magic, _file_path])
		return false
	
	var _total_size := file.get_32()
	var _header_size := file.get_32()
	var file_count := file.get_32()
	
	for i in range(file_count):
		if file.get_position() + 28 > file.get_length():
			break
		
		var name_len := file.get_8()
		var name_bytes := file.get_buffer(19)
		var actual_len := mini(name_len, 19)
		var slice := name_bytes.slice(0, actual_len)
		var nul_idx := slice.find(0)
		if nul_idx != -1:
			slice = slice.slice(0, nul_idx)
		var name_str := slice.get_string_from_ascii().strip_edges()
		
		var size := file.get_32()
		var offset := file.get_32()
		
		if not name_str.is_empty():
			_entries[name_str.to_lower()] = JmaFileEntry.new(name_str, size, offset)
	
	return true

func has_file(entry_name: String) -> bool:
	return _entries.has(entry_name.to_lower())

func get_file_list() -> Array[String]:
	var list: Array[String] = []
	for key in _entries:
		var entry: JmaFileEntry = _entries[key]
		list.append(entry.name)
	return list

func get_file_entry(entry_name: String) -> JmaFileEntry:
	return _entries.get(entry_name.to_lower())

func get_file_bytes(entry_name: String) -> PackedByteArray:
	var entry: JmaFileEntry = _entries.get(entry_name.to_lower())
	if not entry:
		return PackedByteArray()
	
	var file := FileAccess.open(_file_path, FileAccess.READ)
	if not file:
		push_error("Failed to read entry %s from %s" % [entry_name, _file_path])
		return PackedByteArray()
	
	file.seek(entry.offset)
	return file.get_buffer(entry.size)

## Parses a .jmp sprite archive directly from memory buffer
func parse_jmp(entry_name: String, eager_decode: bool = false, bottom_up: bool = false) -> JmpAnimation:
	var jmp_bytes := get_file_bytes(entry_name)
	if jmp_bytes.is_empty():
		return null
	
	return parse_jmp_buffer(jmp_bytes, entry_name, eager_decode, bottom_up)

## Static parser to parse any JMP byte buffer in memory
static func parse_jmp_buffer(jmp_bytes: PackedByteArray, entry_name: String = "", eager_decode: bool = false, bottom_up: bool = false) -> JmpAnimation:
	if jmp_bytes.size() < 14:
		push_error("JMP byte buffer too short (%d bytes)" % jmp_bytes.size())
		return null
	
	# Verify magic starts with "jm" (0x6a 0x6d)
	if jmp_bytes[0] != 0x6a or jmp_bytes[1] != 0x6d:
		push_error("Invalid JMP magic bytes: 0x%02x 0x%02x (expected 'jm')" % [jmp_bytes[0], jmp_bytes[1]])
		return null
	
	var ver := jmp_bytes.decode_u16(4)
	var data_offset := jmp_bytes.decode_u32(6)
	var frame_count := jmp_bytes.decode_u32(10)
	
	var anim := JmpAnimation.new()
	anim.name = entry_name
	anim.version = ver
	anim.data_offset = data_offset
	anim.frame_count = frame_count
	anim.raw_jmp_bytes = jmp_bytes
	
	# Frame entries start at offset 14. Each entry is 40 bytes.
	var entries_end := 14 + frame_count * 40
	if entries_end + 1024 > jmp_bytes.size():
		push_warning("JMP buffer truncated before palette (%d < %d)" % [jmp_bytes.size(), entries_end + 1024])
		return anim
	
	# 256-color palette (1024 bytes) starts right after frame entries
	var pal_start := entries_end
	anim.palette_raw = jmp_bytes.slice(pal_start, pal_start + 1024)
	
	# Pre-build 1024-byte RGBA lookup table for fast pixel decoding
	# DirectDraw 2D Chroma Key: Pure Green (R=0, G=255, B=0) or palette index 0 is transparent (alpha = 0)
	var pal_rgba := PackedByteArray()
	pal_rgba.resize(1024)
	
	for c in range(256):
		var p_idx := pal_start + c * 4
		var b: int = jmp_bytes[p_idx + 0]
		var g: int = jmp_bytes[p_idx + 1]
		var r: int = jmp_bytes[p_idx + 2]
		
		var a: int = 255
		if c == 0 or (r == 0 and g == 255 and b == 0):
			a = 0
		
		var out_idx := c * 4
		pal_rgba[out_idx + 0] = r
		pal_rgba[out_idx + 1] = g
		pal_rgba[out_idx + 2] = b
		pal_rgba[out_idx + 3] = a
	
	anim.palette_rgba = pal_rgba
	
	# Parse frame metadata
	for f in range(frame_count):
		var entry_off := 14 + f * 40
		var name_len: int = jmp_bytes[entry_off]
		var actual_len: int = mini(name_len, 11)
		var slice := jmp_bytes.slice(entry_off + 1, entry_off + 1 + actual_len)
		var nul_idx := slice.find(0)
		if nul_idx != -1:
			slice = slice.slice(0, nul_idx)
		var f_name := slice.get_string_from_ascii()
		
		var bound_w := jmp_bytes.decode_s16(entry_off + 12)
		var bound_h := jmp_bytes.decode_s16(entry_off + 14)
		var piv_x := jmp_bytes.decode_s16(entry_off + 16)
		var piv_y := jmp_bytes.decode_s16(entry_off + 18)
		var f_size := jmp_bytes.decode_u32(entry_off + 20)
		var f_offset := jmp_bytes.decode_u32(entry_off + 24)
		var width := jmp_bytes.decode_u32(entry_off + 28)
		var height := jmp_bytes.decode_u32(entry_off + 32)
		var bpp := jmp_bytes.decode_u32(entry_off + 36)
		
		var frame := JmpFrame.new()
		frame.name = f_name
		frame.bound_w = bound_w
		frame.bound_h = bound_h
		frame.pivot_x = piv_x
		frame.pivot_y = piv_y
		frame.frame_size = f_size
		frame.frame_offset = f_offset
		frame.width = width
		frame.height = height
		frame.bpp = bpp
		
		if eager_decode and width > 0 and height > 0 and f_offset + f_size <= jmp_bytes.size():
			frame.texture = decode_frame_to_texture(jmp_bytes, frame, pal_rgba, bottom_up)
		
		anim.frames.append(frame)
	
	return anim

## Decodes a raw JMP frame into a Godot Image directly in RAM
static func decode_frame_to_image(jmp_bytes: PackedByteArray, frame: JmpFrame, pal_rgba: PackedByteArray, bottom_up: bool = false) -> Image:
	if frame.width == 0 or frame.height == 0:
		return null
	if frame.frame_offset + frame.frame_size > jmp_bytes.size():
		push_error("Frame %s offset out of bounds: %d + %d > %d" % [frame.name, frame.frame_offset, frame.frame_size, jmp_bytes.size()])
		return null
	
	var width := frame.width
	var height := frame.height
	var stride := (width + 3) & ~3
	var f_offset := frame.frame_offset
	
	var rgba_bytes := PackedByteArray()
	rgba_bytes.resize(width * height * 4)
	
	for y in range(height):
		var src_y := (height - 1 - y) if bottom_up else y
		var src_row := f_offset + src_y * stride
		var dst_row := y * width * 4
		
		for x in range(width):
			var pal_index: int = jmp_bytes[src_row + x]
			var pal_byte_idx := pal_index * 4
			var dst_idx := dst_row + x * 4
			
			rgba_bytes[dst_idx + 0] = pal_rgba[pal_byte_idx + 0]
			rgba_bytes[dst_idx + 1] = pal_rgba[pal_byte_idx + 1]
			rgba_bytes[dst_idx + 2] = pal_rgba[pal_byte_idx + 2]
			rgba_bytes[dst_idx + 3] = pal_rgba[pal_byte_idx + 3]
	
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, rgba_bytes)

## Decodes a raw JMP frame into an ImageTexture directly in RAM
static func decode_frame_to_texture(jmp_bytes: PackedByteArray, frame: JmpFrame, pal_rgba: PackedByteArray, bottom_up: bool = false) -> ImageTexture:
	var img := decode_frame_to_image(jmp_bytes, frame, pal_rgba, bottom_up)
	if not img:
		return null
	frame.image = img
	return ImageTexture.create_from_image(img)
