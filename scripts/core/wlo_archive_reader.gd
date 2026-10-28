class_name WloArchiveReader
extends RefCounted

## Reader for Wonderland Online package archives (.JMG and .BMg).
## Direct in-memory parsing without extracting any loose files to disk.

class ArchiveEntry:
	var name: String
	var offset: int
	var size: int

	func _init(p_name: String, p_offset: int, p_size: int) -> void:
		name = p_name
		offset = p_offset
		size = p_size

var _file_path: String = ""
var _entries: Dictionary = {} # String -> ArchiveEntry
var _texture_cache: Dictionary = {} # String -> ImageTexture

static func open_archive(file_path: String) -> WloArchiveReader:
	if not FileAccess.file_exists(file_path):
		push_error("Archive file not found: %s" % file_path)
		return null
	var reader := WloArchiveReader.new()
	reader._file_path = file_path
	if not reader._read_index():
		return null
	return reader

func _read_index() -> bool:
	var file := FileAccess.open(_file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open archive: %s" % _file_path)
		return false
	
	if file.get_length() < 2:
		push_error("Archive file too small: %s" % _file_path)
		return false
	
	var count: int = file.get_16()
	for i in range(count):
		if file.get_position() + 32 > file.get_length():
			break
		
		var name_len: int = file.get_8()
		var name_bytes: PackedByteArray = file.get_buffer(23)
		var actual_len: int = mini(name_len, 23)
		var slice := name_bytes.slice(0, actual_len)
		var nul_idx := slice.find(0)
		if nul_idx != -1:
			slice = slice.slice(0, nul_idx)
		var name_str: String = slice.get_string_from_ascii().strip_edges()
		
		var offset: int = file.get_32()
		var size: int = file.get_32()
		
		if not name_str.is_empty():
			_entries[name_str.to_lower()] = ArchiveEntry.new(name_str, offset, size)
	
	return true

func has_file(file_name: String) -> bool:
	return _entries.has(file_name.to_lower())

func get_entry(file_name: String) -> ArchiveEntry:
	return _entries.get(file_name.to_lower())

func get_file_list() -> Array[String]:
	var list: Array[String] = []
	for key in _entries:
		var entry: ArchiveEntry = _entries[key]
		list.append(entry.name)
	return list

func extract_bytes(file_name: String) -> PackedByteArray:
	var entry: ArchiveEntry = get_entry(file_name)
	if not entry:
		return PackedByteArray()
	
	var file := FileAccess.open(_file_path, FileAccess.READ)
	if not file:
		push_error("Failed to read file %s from %s" % [file_name, _file_path])
		return PackedByteArray()
	
	file.seek(entry.offset)
	return file.get_buffer(entry.size)

## Extracts asset directly into a Godot Image in memory without disk access.
func extract_image(file_name: String, use_chroma_key: bool = true) -> Image:
	var bytes := extract_bytes(file_name)
	if bytes.is_empty():
		return null
	
	var lower_name := file_name.to_lower()
	if lower_name.ends_with(".jpg") or lower_name.ends_with(".jpeg"):
		var img := Image.new()
		var err := img.load_jpg_from_buffer(bytes)
		if err == OK:
			return img
		push_error("Failed to decode JPG buffer for %s (Error: %d)" % [file_name, err])
		return null
	elif lower_name.ends_with(".png"):
		var img := Image.new()
		var err := img.load_png_from_buffer(bytes)
		if err == OK:
			return img
		push_error("Failed to decode PNG buffer for %s (Error: %d)" % [file_name, err])
		return null
	elif lower_name.ends_with(".bmp"):
		return decode_bmp_buffer(bytes, use_chroma_key)
	else:
		# Detect magic header
		if bytes.size() >= 2 and bytes[0] == 0x42 and bytes[1] == 0x4d: # "BM"
			return decode_bmp_buffer(bytes, use_chroma_key)
		elif bytes.size() >= 3 and bytes[0] == 0xff and bytes[1] == 0xd8 and bytes[2] == 0xff: # JPEG
			var img := Image.new()
			if img.load_jpg_from_buffer(bytes) == OK:
				return img
	
	push_error("Unknown image format for entry: %s" % file_name)
	return null

## Loads the asset directly into a GPU ImageTexture in memory. Never touches disk.
func extract_texture(file_name: String, use_chroma_key: bool = true) -> ImageTexture:
	var cache_key := file_name.to_lower()
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	var img := extract_image(file_name, use_chroma_key)
	if not img:
		return null
	
	var tex := ImageTexture.create_from_image(img)
	if tex:
		_texture_cache[cache_key] = tex
	return tex

## Pure in-memory BMP parser supporting 8-bit paletted, 24-bit BGR, and 32-bit BGRA.
## Applies DirectDraw green chroma-key transparency (R=0, G=255, B=0) when requested.
static func decode_bmp_buffer(bytes: PackedByteArray, use_chroma_key: bool = true) -> Image:
	if bytes.size() < 54:
		push_error("BMP buffer too short (%d bytes)" % bytes.size())
		return null
	
	# Verify "BM" magic
	if bytes[0] != 0x42 or bytes[1] != 0x4d:
		push_error("Invalid BMP magic: %02x %02x" % [bytes[0], bytes[1]])
		return null
	
	var data_offset := bytes.decode_u32(10)
	var dib_size := bytes.decode_u32(14)
	var width := bytes.decode_s32(18)
	var height_raw := bytes.decode_s32(22)
	var planes := bytes.decode_u16(26)
	var bpp := bytes.decode_u16(28)
	var compression := bytes.decode_u32(30)
	
	if planes != 1:
		push_warning("Unexpected BMP planes count: %d" % planes)
	
	if compression != 0:
		push_error("Unsupported BMP compression mode: %d (only BI_RGB uncompressed supported)" % compression)
		return null
	
	if width <= 0:
		push_error("Invalid BMP width: %d" % width)
		return null
	
	var top_down := false
	var height := height_raw
	if height < 0:
		top_down = true
		height = -height
	elif height == 0:
		push_error("Invalid BMP height: 0")
		return null
	
	var rgba_bytes := PackedByteArray()
	rgba_bytes.resize(width * height * 4)
	
	if bpp == 8:
		# 8-bit indexed palette
		var pal_start := 14 + dib_size
		var pal_bytes_available := data_offset - pal_start
		var pal_entries := mini(256, pal_bytes_available / 4)
		
		# Pre-build 256-color RGBA lookup table
		var pal_rgba := PackedByteArray()
		pal_rgba.resize(256 * 4)
		for c in range(pal_entries):
			var p_idx := pal_start + c * 4
			if p_idx + 3 < bytes.size():
				var b: int = bytes[p_idx + 0]
				var g: int = bytes[p_idx + 1]
				var r: int = bytes[p_idx + 2]
				var a: int = 255
				if use_chroma_key and (c == 0 or (r == 0 and g == 255 and b == 0)):
					a = 0
				
				var out_idx := c * 4
				pal_rgba[out_idx + 0] = r
				pal_rgba[out_idx + 1] = g
				pal_rgba[out_idx + 2] = b
				pal_rgba[out_idx + 3] = a
		
		var stride: int = (width + 3) & ~3
		for y in range(height):
			var src_y := y if top_down else (height - 1 - y)
			var src_row := data_offset + src_y * stride
			var dst_row := y * width * 4
			
			if src_row + width > bytes.size():
				break
			
			for x in range(width):
				var pal_idx: int = bytes[src_row + x]
				var pal_offset := pal_idx * 4
				var dst_idx := dst_row + x * 4
				
				rgba_bytes[dst_idx + 0] = pal_rgba[pal_offset + 0]
				rgba_bytes[dst_idx + 1] = pal_rgba[pal_offset + 1]
				rgba_bytes[dst_idx + 2] = pal_rgba[pal_offset + 2]
				rgba_bytes[dst_idx + 3] = pal_rgba[pal_offset + 3]
				
	elif bpp == 24:
		# 24-bit BGR
		var stride: int = (width * 3 + 3) & ~3
		for y in range(height):
			var src_y := y if top_down else (height - 1 - y)
			var src_row := data_offset + src_y * stride
			var dst_row := y * width * 4
			
			if src_row + width * 3 > bytes.size():
				break
			
			for x in range(width):
				var src_px := src_row + x * 3
				var b: int = bytes[src_px + 0]
				var g: int = bytes[src_px + 1]
				var r: int = bytes[src_px + 2]
				var a: int = 255
				if use_chroma_key and (r == 0 and g == 255 and b == 0):
					a = 0
				
				var dst_idx := dst_row + x * 4
				rgba_bytes[dst_idx + 0] = r
				rgba_bytes[dst_idx + 1] = g
				rgba_bytes[dst_idx + 2] = b
				rgba_bytes[dst_idx + 3] = a
				
	elif bpp == 32:
		# 32-bit BGRA
		var stride: int = width * 4
		for y in range(height):
			var src_y := y if top_down else (height - 1 - y)
			var src_row := data_offset + src_y * stride
			var dst_row := y * width * 4
			
			if src_row + stride > bytes.size():
				break
			
			for x in range(width):
				var src_px := src_row + x * 4
				var b: int = bytes[src_px + 0]
				var g: int = bytes[src_px + 1]
				var r: int = bytes[src_px + 2]
				var a: int = bytes[src_px + 3]
				if use_chroma_key and (r == 0 and g == 255 and b == 0):
					a = 0
				
				var dst_idx := dst_row + x * 4
				rgba_bytes[dst_idx + 0] = r
				rgba_bytes[dst_idx + 1] = g
				rgba_bytes[dst_idx + 2] = b
				rgba_bytes[dst_idx + 3] = a
	else:
		push_error("Unsupported BMP bit depth: %d bpp" % bpp)
		return null
	
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, rgba_bytes)
