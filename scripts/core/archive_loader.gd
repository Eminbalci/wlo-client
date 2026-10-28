extends Node

## Central singleton for Wonderland Online game assets.
## Manages in-memory streaming of textures, sprites, animations and audio without extracting files to disk.

const WloArchiveReader = preload("res://scripts/core/wlo_archive_reader.gd")
const JmaParser = preload("res://scripts/core/jma_parser.gd")

signal assets_initialized

var base_path: String = "res://assets"
var data_path: String = "res://assets/data"
var pic_path: String = "res://assets/pic"
var sound_path: String = "res://assets/sound"
var jma_path: String = "res://assets/jma"
var menu_path: String = "res://assets/menu"
var cursor_path: String = "res://assets/cursor"

var _map_archive: RefCounted
var _map_archives: Array[RefCounted] = []
var _map_object_archives: Array[RefCounted] = []
var _item_archive: RefCounted
var _item_archives: Array = []
var _role_archive: RefCounted
var _jma_archives: Dictionary = {} # String -> JmaParser

var _texture_cache: Dictionary = {} # String -> ImageTexture
var _anim_cache: Dictionary = {} # String -> JmpAnimation
var _composite_cache: Dictionary = {} # Variant (String/int) -> Array[ImageTexture]
var _cursor_frames: Array[ImageTexture] = []
var _cursor_cache: Dictionary = {}
var _jma_frame_128_cache: Dictionary = {} # String -> ImageTexture
var _avatar_cache: Dictionary = {} # int -> Array[ImageTexture]
var _skill_vfx_cache: Dictionary = {} # int -> Array[ImageTexture]

func _init() -> void:
	if not DirAccess.dir_exists_absolute(base_path) and DirAccess.dir_exists_absolute("D:/GitHub/WLRI"):
		base_path = "D:/GitHub/WLRI"
		data_path = "D:/GitHub/WLRI/data"
		pic_path = "D:/GitHub/WLRI/pic"
		sound_path = "D:/GitHub/WLRI/sound"
		jma_path = "D:/GitHub/WLRI/jma"
		menu_path = "D:/GitHub/WLRI/menu"
		cursor_path = "D:/GitHub/WLRI/cursor"

func _ready() -> void:
	var min_sz: Variant = ProjectSettings.get_setting("display/window/size/min_size", Vector2i(800, 600))
	if min_sz is Vector2i:
		var root_win: Window = get_tree().root if get_tree() else null
		if root_win:
			root_win.min_size = min_sz
		DisplayServer.window_set_min_size(min_sz)
	initialize_archives()
	setup_custom_cursor()

func initialize_archives() -> void:
	# 1. Load JMG and BMg archives
	_map_archives.clear()
	var map_files: Array[String] = [
		"map.JMG", "map_d01.JMg", "map_c01.JMg",
		"map.jmg", "map_d01.jmg", "map_c01.jmg"
	]
	var loaded_map_paths: Dictionary = {}
	for mfile: String in map_files:
		var mpath: String = str(pic_path) + "/" + mfile
		if FileAccess.file_exists(mpath):
			var norm_path: String = mpath.to_lower()
			if not loaded_map_paths.has(norm_path):
				loaded_map_paths[norm_path] = true
				var reader = WloArchiveReader.open_archive(mpath)
				if reader:
					_map_archives.append(reader)
	if not _map_archives.is_empty():
		_map_archive = _map_archives[0]

	_item_archives.clear()
	var item_files: Array[String] = ["item.BMg", "item1.BMg", "item2.BMg", "item3.BMg", "item_c01.BMg", "item_c02.BMg"]
	for ifile: String in item_files:
		var ipath: String = str(pic_path) + "/" + ifile
		if FileAccess.file_exists(ipath):
			var reader = WloArchiveReader.open_archive(ipath)
			if reader:
				_item_archives.append(reader)
	if not _item_archives.is_empty():
		_item_archive = _item_archives[0]

	_map_object_archives.clear()
	var map_obj_files: Array[String] = [
		"images1.BMg", "images1_d01.BMg",
		"images4.BMg", "images4_c01.BMg", "images4_d01.BMg"
	]
	for ofile: String in map_obj_files:
		var opath: String = str(pic_path) + "/" + ofile
		if FileAccess.file_exists(opath):
			var reader = WloArchiveReader.open_archive(opath)
			if reader:
				_map_object_archives.append(reader)

	for role_cand in ["/jRole.JMg", "/JRole.JMg"]:
		if FileAccess.file_exists(pic_path + role_cand):
			_role_archive = WloArchiveReader.open_archive(pic_path + role_cand)
			break
	
	# 2. Pre-index primary JMA sprite packages
	var dir := DirAccess.open(jma_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.to_lower().ends_with(".jma"):
				var parser = JmaParser.open_jma(jma_path + "/" + file_name)
				if parser:
					_jma_archives[file_name.to_lower()] = parser
			file_name = dir.get_next()
	
	assets_initialized.emit()

## Loads any UI skin asset directly into memory as ImageTexture. Zero disk writes.
func get_ui_texture(relative_path: String) -> ImageTexture:
	var cache_key := "ui_" + relative_path.to_lower()
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	var full_path := base_path + "/" + relative_path
	if not FileAccess.file_exists(full_path):
		# Try case-insensitive fallback if needed
		full_path = full_path.replace("\\", "/")
		if not FileAccess.file_exists(full_path):
			return null
	
	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		return null
	
	var bytes := file.get_buffer(file.get_length())
	var img := Image.new()
	var err: Error = FAILED
	var lower := relative_path.to_lower()
	
	if lower.ends_with(".jpg") or lower.ends_with(".jpeg"):
		err = img.load_jpg_from_buffer(bytes)
	elif lower.ends_with(".bmp"):
		err = img.load_bmp_from_buffer(bytes)
	elif lower.ends_with(".png"):
		err = img.load_png_from_buffer(bytes)
	
	if err != OK:
		return null
	
	# In Wonderland Online white skin, Form_Talk_2.bmp contains the authentic parchment background for Form_Talk_1
	if lower.ends_with("form_talk_1.bmp"):
		var f2_path := full_path.replace("Form_Talk_1.bmp", "Form_Talk_2.bmp").replace("form_talk_1.bmp", "form_talk_2.bmp")
		if FileAccess.file_exists(f2_path):
			var f2_file := FileAccess.open(f2_path, FileAccess.READ)
			if f2_file:
				var f2_bytes := f2_file.get_buffer(f2_file.get_length())
				var f2_img := Image.new()
				if f2_img.load_bmp_from_buffer(f2_bytes) == OK:
					img = f2_img

	# If BMP has green (0, 255, 0) or magenta (255, 0, 255) chroma key, make it transparent
	if lower.ends_with(".bmp"):
		img.convert(Image.FORMAT_RGBA8)
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var pixel := img.get_pixel(x, y)
				var is_green: bool = (pixel.r < 0.05 and pixel.g > 0.95 and pixel.b < 0.05)
				var is_magenta: bool = (pixel.r > 0.95 and pixel.g < 0.05 and pixel.b > 0.95)
				if is_green or is_magenta:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
				elif lower.ends_with("minimapform.bmp") and x >= 6 and x <= 218 and y >= 6 and y <= 137:
					if pixel.r < 0.02 and pixel.g < 0.02 and pixel.b < 0.02:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
				elif lower.ends_with("main_status_1.bmp"):
					# Key out the circular avatar hole (center: 49.5, 74.5, radius: 35.5)
					var dx: float = float(x) - 49.5
					var dy: float = float(y) - 74.5
					if (dx * dx + dy * dy) <= 35.5 * 35.5:
						if pixel.r < 0.15 and pixel.g < 0.15 and pixel.b < 0.15:
							img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[cache_key] = tex
	return tex

## Loads map background image directly from map.JMG, map_d01.JMg, or map_c01.JMg
func get_map_background(scene_id: int) -> ImageTexture:
	var cache_key := "map_%d" % scene_id
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	if _map_archives.is_empty():
		initialize_archives()
	if _map_archives.is_empty():
		return null
	
	var candidates: Array[String] = [
		"%d.jpg" % scene_id,
		"%05d.jpg" % scene_id,
		"%04d.jpg" % scene_id
	]
	if scene_id == 10011:
		candidates.append("10003.jpg")
	
	var tex: ImageTexture = null
	for arch in _map_archives:
		for name in candidates:
			if arch.has_file(name):
				tex = arch.extract_texture(name)
				if tex:
					break
		if tex:
			break
	
	if tex:
		_texture_cache[cache_key] = tex
	else:
		push_warning("ArchiveLoader: Background image for scene %d not found across %d map archives" % [scene_id, _map_archives.size()])
	return tex

## Checks if map background image exists in cache or across map archives without necessarily decoding it into an ImageTexture
func has_map_background(scene_id: int) -> bool:
	var cache_key := "map_%d" % scene_id
	if _texture_cache.has(cache_key):
		return true
	if _map_archives.is_empty():
		initialize_archives()
	var candidates: Array[String] = [
		"%d.jpg" % scene_id,
		"%05d.jpg" % scene_id,
		"%04d.jpg" % scene_id
	]
	if scene_id == 10011:
		candidates.append("10003.jpg")
	for arch in _map_archives:
		for name in candidates:
			if arch.has_file(name):
				return true
	return false

## Loads minimap texture for a scene directly into memory as an authentic downscaled thumbnail
func get_minimap_texture(scene_id: int) -> ImageTexture:
	var cache_key := "minimap_%d" % scene_id
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	# 1. Fetch real map background and downscale to 212x131 minimap view
	var bg_tex := get_map_background(scene_id)
	if bg_tex:
		var img := bg_tex.get_image()
		if img and not img.is_empty():
			var thumb_img := img.duplicate()
			thumb_img.resize(212, 131, Image.INTERPOLATE_BILINEAR)
			var tex := ImageTexture.create_from_image(thumb_img)
			if tex:
				_texture_cache[cache_key] = tex
				return tex
	
	# 2. Fallback candidate minimap filenames if map background not available
	var minimap_candidates := [
		pic_path + "/MiniMap_1.bmp",
		pic_path + "/minimap_1.bmp",
		"res://assets/pic/MiniMap_1.bmp",
		"D:/GitHub/WLRI/pic/MiniMap_1.bmp"
	]
	
	for path in minimap_candidates:
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file:
				var bytes := file.get_buffer(file.get_length())
				var img := Image.new()
				if img.load_bmp_from_buffer(bytes) == OK:
					var tex := ImageTexture.create_from_image(img)
					_texture_cache[cache_key] = tex
					return tex
	return null

## Loads item icon from item*.BMg archives (e.g. 1000.bmp, 8000.bmp)
func get_item_icon(icon_id: int) -> ImageTexture:
	var cache_key := "item_%d" % icon_id
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	var name := "%d.bmp" % icon_id
	var tex: ImageTexture = null
	for arch in _item_archives:
		if arch.has_file(name):
			tex = arch.extract_texture(name)
			if tex:
				break
	
	if not tex and _item_archive and _item_archive.has_file(name):
		tex = _item_archive.extract_texture(name)
	
	if tex:
		_texture_cache[cache_key] = tex
	return tex

## Loads map foreground/background object sprite (e.g. 10001029.bmp, 10002009.bmp) from images1*.BMg / images4*.BMg with green/magenta chroma key transparency
func get_map_object_texture(event_id: int) -> ImageTexture:
	var cache_key := "map_obj_%d" % event_id
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	if _map_object_archives.is_empty():
		initialize_archives()

	var name := "%d.bmp" % event_id
	var tex: ImageTexture = null
	for arch in _map_object_archives:
		if arch.has_file(name):
			tex = arch.extract_texture(name, true)
			if tex:
				break

	if tex:
		_texture_cache[cache_key] = tex
	return tex

## Loads role sprite sheet from JRole.JMg
func get_role_sprite_sheet(role_id: int, motion: int = 0) -> ImageTexture:
	var cache_key := "role_%d_%d" % [role_id, motion]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	if not _role_archive:
		return null
	
	var candidates := [
		"JRole_5_%d.jpg" % role_id,
		"JRole_%d_%d.jpg" % [role_id, motion]
	]
	
	var tex: ImageTexture = null
	for name in candidates:
		if _role_archive.has_file(name):
			tex = _role_archive.extract_texture(name)
			if tex:
				break
	
	if tex:
		_texture_cache[cache_key] = tex
	return tex

## Loads animated sprite from .jma
func get_jma_animation(jma_file: String, jmp_file: String):
	var key := (jma_file + ":" + jmp_file).to_lower()
	if _anim_cache.has(key):
		return _anim_cache[key]
	
	var parser = _jma_archives.get(jma_file.to_lower())
	if not parser:
		parser = JmaParser.open_jma(jma_path + "/" + jma_file)
		if parser:
			_jma_archives[jma_file.to_lower()] = parser
		else:
			return null
	var anim = parser.parse_jmp(jmp_file)
	if anim:
		_anim_cache[key] = anim
	return anim

## Decodes or retrieves a single JMA frame composited onto a 128x128 canvas using (pivot_x, pivot_y).
## Prevents frame jitter during idle animations. Caches result in RAM dictionary. Zero disk writes.
func get_jma_frame_128(jma_file: String, jmp_file: String, frame_idx: int) -> ImageTexture:
	var cache_key := "%s:%s:%d" % [jma_file.to_lower(), jmp_file.to_lower(), frame_idx]
	if _jma_frame_128_cache.has(cache_key):
		return _jma_frame_128_cache[cache_key]
	
	var anim = get_jma_animation(jma_file, jmp_file)
	if not anim:
		return null
	
	var j_frame = anim.get_frame(frame_idx)
	if not j_frame or j_frame.width <= 0 or j_frame.height <= 0:
		return null
	
	var layer_img: Image = anim.decode_frame_image(frame_idx)
	if not layer_img:
		return null
	
	var cw: int = maxi(128, j_frame.bound_w)
	var ch: int = maxi(128, j_frame.bound_h)
	var canvas := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blend_rect(
		layer_img,
		Rect2i(0, 0, j_frame.width, j_frame.height),
		Vector2i(j_frame.pivot_x, j_frame.pivot_y)
	)
	var tex := ImageTexture.create_from_image(canvas)
	_jma_frame_128_cache[cache_key] = tex
	return tex

## Retrieves and decodes authentic combat skill VFX animation frames from 006.jma, 006_c01.jma, or 006_c02.jma.
## Matches anim_id (e.g. 60009, 6009, 6001, 60001, 6022, 60022).
## Formats candidate JMP names, searches across archives, decodes frames with transparent chroma key,
## composites them onto uniform bounding canvases, and caches in _skill_vfx_cache.
func get_skill_vfx_frames(anim_id: int) -> Array[ImageTexture]:
	if _skill_vfx_cache.has(anim_id):
		return _skill_vfx_cache[anim_id]
	
	var candidates: Array[String] = []
	candidates.append("%d.jmp" % anim_id)
	
	if anim_id >= 60000 and anim_id < 70000:
		var sub_id: int = anim_id - 60000
		candidates.append("6%03d.jmp" % sub_id)
		candidates.append("%d.jmp" % (6000 + sub_id))
		candidates.append("%05d.jmp" % anim_id)
	elif anim_id >= 6000 and anim_id < 7000:
		var sub_id: int = anim_id - 6000
		candidates.append("60%03d.jmp" % sub_id)
		candidates.append("%d.jmp" % (60000 + sub_id))
	elif anim_id < 1000:
		candidates.append("6%03d.jmp" % anim_id)
		candidates.append("60%03d.jmp" % anim_id)
		candidates.append("%d.jmp" % (6000 + anim_id))
		candidates.append("%d.jmp" % (60000 + anim_id))

	var jma_archives: Array[String] = ["006.jma", "006_c01.jma", "006_c02.jma"]
	var anim = null
	
	for jma_name in jma_archives:
		for cand in candidates:
			anim = get_jma_animation(jma_name, cand)
			if anim and anim.frames.size() > 0:
				break
		if anim and anim.frames.size() > 0:
			break
			
	if not anim or anim.frames.is_empty():
		return []

	var max_bw: int = 0
	var max_bh: int = 0
	for jf in anim.frames:
		if jf:
			max_bw = maxi(max_bw, maxi(jf.bound_w, jf.width))
			max_bh = maxi(max_bh, maxi(jf.bound_h, jf.height))
	if max_bw <= 0: max_bw = 128
	if max_bh <= 0: max_bh = 128

	var frames: Array[ImageTexture] = []
	for i in range(anim.frames.size()):
		var j_frame = anim.get_frame(i)
		if not j_frame or j_frame.width <= 0 or j_frame.height <= 0:
			continue
		# Filter out 1x1 dummy padding frames if animation has real frames
		if j_frame.width <= 1 and j_frame.height <= 1 and anim.frames.size() > 1:
			continue
		var layer_img: Image = anim.decode_frame_image(i)
		if not layer_img:
			continue
		var canvas := Image.create(max_bw, max_bh, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))
		canvas.blend_rect(
			layer_img,
			Rect2i(0, 0, j_frame.width, j_frame.height),
			Vector2i(maxi(0, j_frame.pivot_x), maxi(0, j_frame.pivot_y))
		)
		frames.append(ImageTexture.create_from_image(canvas))

	if not frames.is_empty():
		_skill_vfx_cache[anim_id] = frames
	return frames

## Retrieves the authentic icon texture for a combat or overland skill by skill_id
func get_skill_icon(skill_id: int) -> Texture2D:
	var cache_key := "skill_%d" % skill_id
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]
	
	var elem: int = 0
	var gdb: Node = get_node_or_null("/root/GameDatabase") if is_inside_tree() else null
	if not gdb and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st and st.root:
			gdb = st.root.get_node_or_null("GameDatabase")
	
	if gdb and "skills" in gdb and gdb.skills and gdb.skills.has_skill(skill_id):
		var rec = gdb.skills.get_skill(skill_id)
		elem = int(rec.element) if ("element" in rec) else 0
	
	var tex_path := ""
	match elem:
		1: tex_path = "res://assets/hud/icon_element_1.png"
		2: tex_path = "res://assets/hud/icon_element_2.png"
		3: tex_path = "res://assets/hud/icon_element_3.png"
		4: tex_path = "res://assets/hud/icon_element_4.png"
		_:
			if ResourceLoader.exists("res://assets/hud/icon_use_compound_skill.png"):
				tex_path = "res://assets/hud/icon_use_compound_skill.png"
			else:
				tex_path = "res://assets/hud/test_Btn_SkillIcon_1.png"
	
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex:
			_texture_cache[cache_key] = tex
			return tex
	return null

## Retrieves the animated avatar frames for a character role (1..14) or NPC portrait (>= 8000).
## For playable roles (1..14), decodes authentic cutout heads (00-1.bmp idle, 00-2.bmp blink) from 002f.jma..005f.jma.
## For NPC portraits (>= 8000), decodes from 008.jma.
## Caches result in RAM dictionary.
func get_avatar_frames(role_id: int) -> Array[ImageTexture]:
	if _avatar_cache.has(role_id):
		return _avatar_cache[role_id]

	var frames: Array[ImageTexture] = []

	# 1. Playable character roles (1..14): decode cutout head frames 0 and 1 from 002f.jma..005f.jma
	const ROLE_FACE_ARCHIVES: Dictionary = {
		1: ["003f.jma", "3600.jmp"], # Nina
		2: ["003f.jma", "3601.jmp"], # Betty
		3: ["002f.jma", "2600.jmp"], # Rocco
		4: ["005f.jma", "5602.jmp"], # Vanessa
		5: ["005f.jma", "5601.jmp"], # Lique
		6: ["004f.jma", "4601.jmp"], # Daniel
		7: ["004f.jma", "4600.jmp"], # Sid
		8: ["005f.jma", "5604.jmp"], # Jessica
		9: ["005f.jma", "5605.jmp"], # Konnotsuroko
		10: ["005f.jma", "5600.jmp"], # Iris
		11: ["005f.jma", "5606.jmp"], # Maria
		12: ["004f.jma", "4602.jmp"], # More
		13: ["004f.jma", "4603.jmp"], # Kurogane
		14: ["005f.jma", "5607.jmp"]  # Karin
	}
	if ROLE_FACE_ARCHIVES.has(role_id):
		var face_pair: Array = ROLE_FACE_ARCHIVES[role_id]
		var face_anim = get_jma_animation(str(face_pair[0]), str(face_pair[1]))
		if face_anim and face_anim.frames.size() >= 2:
			var jf0 = face_anim.get_frame(0)
			if jf0 and jf0.width > 0 and jf0.height > 0:
				for i in [0, 1]:
					var jf = face_anim.get_frame(i)
					var layer_img: Image = face_anim.decode_frame_image(i)
					if jf and layer_img:
						var canvas := Image.create(72, 72, false, Image.FORMAT_RGBA8)
						canvas.fill(Color(0, 0, 0, 0))
						var base_dx: int = int((72 - jf0.width) / 2) + (jf.pivot_x - jf0.pivot_x)
						var base_dy: int = (72 - jf0.height) + (jf.pivot_y - jf0.pivot_y)
						var src_x: int = maxi(0, -base_dx)
						var src_y: int = maxi(0, -base_dy)
						var dst_x: int = maxi(0, base_dx)
						var dst_y: int = maxi(0, base_dy)
						var copy_w: int = mini(jf.width - src_x, 72 - dst_x)
						var copy_h: int = mini(jf.height - src_y, 72 - dst_y)
						if copy_w > 0 and copy_h > 0:
							canvas.blend_rect(
								layer_img,
								Rect2i(src_x, src_y, copy_w, copy_h),
								Vector2i(dst_x, dst_y)
							)
						frames.append(ImageTexture.create_from_image(canvas))

	# 2. NPC dialogue portraits (>= 8000): decode from 008.jma
	if frames.is_empty() and role_id >= 8000:
		var jmp_name: String = "%d.jmp" % role_id
		var anim = get_jma_animation("008.jma", jmp_name)
		if anim and anim.frames.size() > 0:
			for i in range(anim.frames.size()):
				var j_frame = anim.get_frame(i)
				if not j_frame or j_frame.width <= 0 or j_frame.height <= 0:
					continue
				var layer_img: Image = anim.decode_frame_image(i)
				if not layer_img:
					continue
				var bw: int = maxi(j_frame.bound_w, 72)
				var bh: int = maxi(j_frame.bound_h, 72)
				var canvas := Image.create(bw, bh, false, Image.FORMAT_RGBA8)
				canvas.fill(Color(0, 0, 0, 0))
				canvas.blend_rect(
					layer_img,
					Rect2i(0, 0, j_frame.width, j_frame.height),
					Vector2i(j_frame.pivot_x, j_frame.pivot_y)
				)
				frames.append(ImageTexture.create_from_image(canvas))
	
	# Disk fallback if JMA was not found
	if frames.is_empty():
		for f_idx in [0, 1]:
			var png_path := "res://assets/hud/avatar_role_%d_%d.png" % [role_id, f_idx]
			if FileAccess.file_exists(png_path):
				var img := Image.new()
				if img.load(png_path) == OK:
					frames.append(ImageTexture.create_from_image(img))
			elif role_id == 2 and f_idx == 0:
				var betty_path := "res://assets/hud/betty_avatar.png"
				if FileAccess.file_exists(betty_path):
					var img := Image.new()
					if img.load(betty_path) == OK:
						frames.append(ImageTexture.create_from_image(img))
	
	if not frames.is_empty():
		_avatar_cache[role_id] = frames
	return frames

## Retrieves authentic animated portrait frames for an NPC by talk_image TID (e.g. 8025 for Captain).
## Decodes directly from 008.jma in memory.
func get_npc_portrait_frames(talk_image_id: int) -> Array[ImageTexture]:
	return get_avatar_frames(talk_image_id)

## Retrieves the primary static portrait texture for an NPC by talk_image TID.
func get_npc_portrait(talk_image_id: int) -> ImageTexture:
	var frames := get_npc_portrait_frames(talk_image_id)
	return frames[0] if not frames.is_empty() else null

## Loads an NPC or Monster or Role texture by sprite_id (and optional heading 0..7).
## Resolves from:
## - Role archives 002.jma..005.jma if sprite_id corresponds to a playable role (1..14)
## - 007.jma / 007_c01.jma for NPC models (e.g. 7000..7286 or 0..286)
## - 001.jma / 001_c01.jma..001_c04.jma for Monsters and NPCs (e.g. 1000..1982 or 0..999)
## Falls back cleanly with error logging.
func get_npc_texture(sprite_id: int, heading: int = 0) -> ImageTexture:
	var cache_key: String = "npc_tex_%d_%d" % [sprite_id, heading]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key]

	# 1. Playable roles (1..14): resolve from role archives 002.jma..005.jma
	if sprite_id >= 1 and sprite_id <= 14:
		var comp_frames: Array[ImageTexture] = get_player_composite_frames(sprite_id)
		if not comp_frames.is_empty():
			var frame_idx: int = 32 + (heading % 8) * 4
			if frame_idx >= comp_frames.size():
				frame_idx = (heading % 8) % comp_frames.size()
			var role_tex: ImageTexture = comp_frames[frame_idx]
			if role_tex:
				_texture_cache[cache_key] = role_tex
				return role_tex
		var sheet: ImageTexture = get_role_sprite_sheet(sprite_id, 0)
		if sheet:
			_texture_cache[cache_key] = sheet
			return sheet

	# Helper lambda to extract heading frame from an animation
	var extract_heading_frame: Callable = func(jma_file: String, jmp_file: String, anim) -> ImageTexture:
		if not anim or anim.frames.is_empty():
			return null
		var total_frames: int = anim.frames.size()
		var f_idx: int = 0
		if total_frames >= 64:
			f_idx = (32 + (heading % 8) * 4) % total_frames
		elif total_frames == 32:
			if anim.frames[0].name.begins_with("08"):
				f_idx = ((heading % 8) * 4) % total_frames
			else:
				var diag_idx: int = 0
				match heading % 8:
					IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
						diag_idx = 0
					IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
						diag_idx = 1
					IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
						diag_idx = 2
					IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
						diag_idx = 3
				f_idx = (16 + diag_idx * 4) % total_frames
		elif total_frames == 16:
			var diag_block: int = 0
			match heading % 8:
				IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
					diag_block = 0
				IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
					diag_block = 1
				IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
					diag_block = 2
				IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
					diag_block = 3
			f_idx = (diag_block * 4) % total_frames
		elif total_frames == 8:
			if anim.frames[0].name.begins_with("01"):
				var diag_idx: int = 0
				match heading % 8:
					IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
						diag_idx = 0
					IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
						diag_idx = 1
					IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
						diag_idx = 2
					IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
						diag_idx = 3
				f_idx = (4 + diag_idx) % total_frames
			else:
				f_idx = (heading % 8) % total_frames
		elif total_frames == 4:
			var diag_4: int = 0
			match heading % 8:
				IsometricMath.Heading.NORTH_WEST, IsometricMath.Heading.NORTH:
					diag_4 = 0
				IsometricMath.Heading.SOUTH_WEST, IsometricMath.Heading.WEST:
					diag_4 = 1
				IsometricMath.Heading.SOUTH_EAST, IsometricMath.Heading.SOUTH:
					diag_4 = 2
				IsometricMath.Heading.NORTH_EAST, IsometricMath.Heading.EAST:
					diag_4 = 3
			f_idx = diag_4 % total_frames
		else:
			f_idx = 0
		
		var frame_tex: ImageTexture = get_jma_frame_128(jma_file, jmp_file, f_idx)
		if not frame_tex and anim.has_method("decode_frame"):
			frame_tex = anim.decode_frame(f_idx)
		return frame_tex

	# 2. Check 007.jma (and 007_c01.jma) for NPC models
	var npc_jma_list: Array[String] = ["007.jma", "007_c01.jma"]
	var npc_cands: Array[String] = []
	if sprite_id >= 7000 and sprite_id < 8000:
		npc_cands.append("%d.jmp" % sprite_id)
		npc_cands.append("%05d.jmp" % sprite_id)
	elif sprite_id < 1000:
		npc_cands.append("%d.jmp" % (7000 + sprite_id))
		npc_cands.append("7%03d.jmp" % sprite_id)
		npc_cands.append("%d.jmp" % sprite_id)
	else:
		npc_cands.append("%d.jmp" % sprite_id)

	for jma_name in npc_jma_list:
		for cand in npc_cands:
			var anim = get_jma_animation(jma_name, cand)
			if anim and anim.frames.size() > 0:
				var tex: ImageTexture = extract_heading_frame.call(jma_name, cand, anim)
				if tex:
					_texture_cache[cache_key] = tex
					return tex

	# 3. Check 001.jma (and 001_c01.jma..001_c04.jma) for Monsters and standard NPC models
	var monster_jma_list: Array[String] = [
		"001.jma", "001_c01.jma", "001_c02.jma", "001_c03.jma", "001_c04.jma"
	]
	var monster_cands: Array[String] = []
	if sprite_id >= 1000 and sprite_id < 7000:
		monster_cands.append("%d.jmp" % sprite_id)
		monster_cands.append("%05d.jmp" % sprite_id)
	elif sprite_id < 1000:
		monster_cands.append("%d.jmp" % (1000 + sprite_id))
		monster_cands.append("1%03d.jmp" % sprite_id)
		monster_cands.append("%d.jmp" % sprite_id)
	else:
		monster_cands.append("%d.jmp" % sprite_id)

	for jma_name in monster_jma_list:
		for cand in monster_cands:
			var anim = get_jma_animation(jma_name, cand)
			if anim and anim.frames.size() > 0:
				var tex: ImageTexture = extract_heading_frame.call(jma_name, cand, anim)
				if tex:
					_texture_cache[cache_key] = tex
					return tex

	# 4. If sprite_id was an NPC ID (e.g. 14003) rather than a sprite ID, resolve via GameDatabase
	var gdb = get_node_or_null("/root/GameDatabase") if is_inside_tree() else null
	if not gdb and Engine.get_main_loop() is SceneTree:
		var st = Engine.get_main_loop() as SceneTree
		if st and st.root:
			gdb = st.root.get_node_or_null("GameDatabase")
	if gdb and "npcs" in gdb and gdb.npcs:
		var rec = gdb.npcs.get_npc(sprite_id)
		if rec and rec.sprite_id > 0 and rec.sprite_id != sprite_id:
			var resolved_tex: ImageTexture = get_npc_texture(rec.sprite_id, heading)
			if resolved_tex:
				_texture_cache[cache_key] = resolved_tex
				return resolved_tex

	# 5. Clean error logging and fallback
	push_error("ArchiveLoader: Failed to load NPC texture for sprite_id %d (heading %d)" % [sprite_id, heading])
	return null

## Resolves layer specification (String, Dictionary, Array, int, etc.) into [jma_file, jmp_file].
func _resolve_equip_layer(val, default_jma: String, default_jmp: String) -> Array[String]:
	if val == null:
		return ["", ""]
	if val is bool:
		return [default_jma, default_jmp] if val else ["", ""]
	if val is int:
		if val <= 0:
			return ["", ""]
		return [default_jma, "%d.jmp" % val]
	if val is String:
		var s: String = (val as String).strip_edges()
		if s.is_empty() or s.to_lower() == "none" or s.to_lower() == "null" or s == "0":
			return ["", ""]
		if s.contains(":"):
			var parts: PackedStringArray = s.split(":")
			var p_jma: String = parts[0].strip_edges()
			var p_jmp: String = parts[1].strip_edges()
			if not p_jmp.to_lower().ends_with(".jmp"):
				p_jmp += ".jmp"
			if not p_jma.to_lower().ends_with(".jma") and not p_jma.is_empty():
				p_jma += ".jma"
			return [p_jma, p_jmp]
		elif s.to_lower().ends_with(".jmp"):
			return [default_jma, s]
		elif s.to_lower().ends_with(".jma"):
			return [s, default_jmp]
		elif s.is_valid_int():
			return [default_jma, s + ".jmp"]
		else:
			return [default_jma, default_jmp]
	if val is Array:
		if val.size() >= 2:
			return [str(val[0]), str(val[1])]
		elif val.size() == 1:
			return _resolve_equip_layer(val[0], default_jma, default_jmp)
		return ["", ""]
	if val is Dictionary:
		var jma: String = str(val.get("jma", default_jma))
		var jmp: String = str(val.get("jmp", default_jmp))
		return [jma, jmp]
	return [default_jma, default_jmp]

func clear_composite_cache() -> void:
	_composite_cache.clear()

## Composes full player character normal animation frames (up to 216 frames: 32 walk, 32 stand/idle,
## 32 sit, 48 attack/combat strike, 32 defend/hurt, 24 prone/knockout, 16 victory emote)
## onto 128x128 RGBA ImageTextures from paper-doll layers (body, face, clothes, shoes, hair, cap, weapon)
## using each frame's (px, py) pivot. Supports dynamic equipment overrides and caches composites in RAM.
func get_player_composite_frames(role_id: int, equip_layers: Dictionary = {}) -> Array[ImageTexture]:
	var role_info: Dictionary = {}
	var game_db = null
	if is_inside_tree():
		game_db = get_node_or_null("/root/GameDatabase")
	elif Engine.get_main_loop() is SceneTree:
		var st = Engine.get_main_loop() as SceneTree
		if st and st.root:
			game_db = st.root.get_node_or_null("GameDatabase")
	if game_db and game_db.has_method("get_role"):
		role_info = game_db.get_role(role_id)

	# Authentic defaults from GameDatabase role registry
	var def_body_jma: String = str(role_info.get("body_archive", "003.jma" if role_id == 2 else "002.jma"))
	var def_body_jmp: String = str(role_info.get("body_jmp", "3000.jmp" if role_id == 2 else "2000.jmp"))
	var def_face_jma: String = str(role_info.get("face_archive", ""))
	var def_face_jmp: String = str(role_info.get("face_jmp", ""))
	if def_face_jma.is_empty() or def_face_jmp.is_empty():
		var b_low := def_body_jma.to_lower()
		if b_low.contains("002"):
			def_face_jma = "002f.jma"
			def_face_jmp = "2600.jmp"
		elif b_low.contains("003"):
			def_face_jma = "003f.jma"
			def_face_jmp = "3600.jmp"
		elif b_low.contains("004"):
			def_face_jma = "004f.jma"
			def_face_jmp = "4600.jmp"
		elif b_low.contains("005"):
			def_face_jma = "005f.jma"
			def_face_jmp = "5600.jmp"

	var def_hair_jma: String = str(role_info.get("hair_archive", "003h.jma" if role_id == 2 else "002h.jma"))
	var def_hair_jmp: String = str(role_info.get("hair_jmp", "3101.jmp" if role_id == 2 else "2100.jmp"))
	var def_clothes_jma: String = str(role_info.get("default_clothes_archive", "003e.jma" if role_id == 2 else "002e.jma"))
	var def_clothes_jmp: String = str(role_info.get("default_clothes_jmp", "3301.jmp" if role_id == 2 else "2300.jmp"))
	var def_shoes_jma: String = str(role_info.get("default_shoes_archive", "003s.jma" if role_id == 2 else "002s.jma"))
	var def_shoes_jmp: String = str(role_info.get("default_shoes_jmp", "3401.jmp" if role_id == 2 else "2400.jmp"))
	var def_cap_jma: String = str(role_info.get("default_head_archive", "003c.jma" if role_id == 2 else ""))
	var def_cap_jmp: String = str(role_info.get("default_head_jmp", "3201.jmp" if role_id == 2 else ""))

	# 1. Base body skin layer is ALWAYS the role's native skin model (e.g. 003.jma:3000.jmp for Betty)
	# The base body NEVER disappears when clothes are unequipped or equipped.
	var body_jma: String = def_body_jma
	var body_jmp: String = def_body_jmp
	if equip_layers.has("skin") and not str(equip_layers["skin"]).is_empty():
		var s_pair := _resolve_equip_layer(equip_layers["skin"], def_body_jma, def_body_jmp)
		if not s_pair[0].is_empty() and not s_pair[1].is_empty():
			body_jma = s_pair[0]
			body_jmp = s_pair[1]
			var s_low := body_jma.to_lower()
			if s_low.contains("002"):
				def_face_jma = "002f.jma"
				def_face_jmp = "2600.jmp"
			elif s_low.contains("003"):
				def_face_jma = "003f.jma"
				def_face_jmp = "3600.jmp"
			elif s_low.contains("004"):
				def_face_jma = "004f.jma"
				def_face_jmp = "4600.jmp"
			elif s_low.contains("005"):
				def_face_jma = "005f.jma"
				def_face_jmp = "5600.jmp"

	# 2. Resolve face layer (between body and clothes)
	var face_jma: String = def_face_jma
	var face_jmp: String = def_face_jmp
	if equip_layers.has("face"):
		var f_val = equip_layers["face"]
		if f_val == null or (f_val is String and (f_val.is_empty() or f_val.to_lower() == "none" or f_val == "0")):
			face_jma = ""
			face_jmp = ""
		else:
			var face_pair := _resolve_equip_layer(f_val, def_face_jma, def_face_jmp)
			face_jma = face_pair[0]
			face_jmp = face_pair[1]

	# 3. Resolve clothes / armor layer (mapped from "clothes" or HUD "body" equipment slot)
	var clothes_jma: String = ""
	var clothes_jmp: String = ""
	var has_clothes_spec: bool = equip_layers.has("clothes") or equip_layers.has("body") or equip_layers.has("armor")
	if has_clothes_spec:
		var c_val = null
		if equip_layers.has("clothes"):
			c_val = equip_layers["clothes"]
		elif equip_layers.has("body"):
			c_val = equip_layers["body"]
		elif equip_layers.has("armor"):
			c_val = equip_layers["armor"]
		
		if c_val != null and not (c_val is String and (c_val.is_empty() or c_val.to_lower() == "none" or c_val == "0")):
			var clothes_pair := _resolve_equip_layer(c_val, def_clothes_jma, def_clothes_jmp)
			clothes_jma = clothes_pair[0]
			clothes_jmp = clothes_pair[1]
	elif equip_layers.is_empty():
		clothes_jma = def_clothes_jma
		clothes_jmp = def_clothes_jmp

	# 4. Resolve shoes layer (mapped from "shoes" or HUD "foot" equipment slot)
	var shoes_jma: String = ""
	var shoes_jmp: String = ""
	var has_shoes_spec: bool = equip_layers.has("shoes") or equip_layers.has("foot")
	if has_shoes_spec:
		var s_val = equip_layers["shoes"] if equip_layers.has("shoes") else equip_layers["foot"]
		if s_val != null and not (s_val is String and (s_val.is_empty() or s_val.to_lower() == "none" or s_val == "0")):
			var shoes_pair := _resolve_equip_layer(s_val, def_shoes_jma, def_shoes_jmp)
			shoes_jma = shoes_pair[0]
			shoes_jmp = shoes_pair[1]
	elif equip_layers.is_empty():
		shoes_jma = def_shoes_jma
		shoes_jmp = def_shoes_jmp

	# 5. Resolve hair layer
	var hair_jma: String = def_hair_jma
	var hair_jmp: String = def_hair_jmp
	if equip_layers.has("hair"):
		var h_val = equip_layers["hair"]
		if h_val == null or (h_val is String and (h_val.is_empty() or h_val.to_lower() == "none" or h_val == "0")):
			hair_jma = ""
			hair_jmp = ""
		else:
			var hair_pair := _resolve_equip_layer(h_val, def_hair_jma, def_hair_jmp)
			hair_jma = hair_pair[0]
			hair_jmp = hair_pair[1]

	# 6. Resolve cap/head layer (optional)
	var cap_jma: String = ""
	var cap_jmp: String = ""
	if equip_layers.has("cap") or equip_layers.has("head"):
		var cap_raw = equip_layers["cap"] if equip_layers.has("cap") else equip_layers["head"]
		if cap_raw != null and not (cap_raw is String and (cap_raw.is_empty() or cap_raw.to_lower() == "none" or cap_raw == "0")):
			var cap_pair := _resolve_equip_layer(cap_raw, def_cap_jma, def_cap_jmp)
			cap_jma = cap_pair[0]
			cap_jmp = cap_pair[1]
	elif equip_layers.is_empty() and not def_cap_jmp.is_empty() and not def_cap_jma.is_empty():
		cap_jma = def_cap_jma
		cap_jmp = def_cap_jmp

	# 7. Resolve weapon layer (optional)
	var weapon_jma: String = ""
	var weapon_jmp: String = ""
	if equip_layers.has("weapon") or equip_layers.has("hand"):
		var w_val = equip_layers["weapon"] if equip_layers.has("weapon") else equip_layers["hand"]
		if w_val != null and not (w_val is String and (w_val.is_empty() or w_val.to_lower() == "none" or w_val == "0")):
			var base_prefix := "002"
			var b_low := body_jma.to_lower()
			if b_low.contains("003"):
				base_prefix = "003"
			elif b_low.contains("004"):
				base_prefix = "004"
			elif b_low.contains("005"):
				base_prefix = "005"
			var def_weapon_jma := base_prefix + "w.jma"
			var def_weapon_jmp := base_prefix.substr(2, 1) + "040.jmp"
			var weapon_pair := _resolve_equip_layer(w_val, def_weapon_jma, def_weapon_jmp)
			weapon_jma = weapon_pair[0]
			weapon_jmp = weapon_pair[1]
			if weapon_jma.to_lower().ends_with("w.jma") and not weapon_jma.to_lower().begins_with(base_prefix):
				weapon_jma = base_prefix + "w.jma"
			if weapon_jmp.to_lower().ends_with("040.jmp") and not weapon_jmp.begins_with(base_prefix.substr(2, 1)):
				weapon_jmp = base_prefix.substr(2, 1) + "040.jmp"

	# Form explicit cache key: unequipped slots marked "none" to prevent hash collisions
	var body_key: String = "%s:%s" % [body_jma, body_jmp]
	var face_key: String = ("%s:%s" % [face_jma, face_jmp]) if not face_jma.is_empty() and not face_jmp.is_empty() else "none"
	var clothes_key: String = ("%s:%s" % [clothes_jma, clothes_jmp]) if not clothes_jma.is_empty() and not clothes_jmp.is_empty() else "none"
	var shoes_key: String = ("%s:%s" % [shoes_jma, shoes_jmp]) if not shoes_jma.is_empty() and not shoes_jmp.is_empty() else "none"
	var hair_key: String = ("%s:%s" % [hair_jma, hair_jmp]) if not hair_jma.is_empty() and not hair_jmp.is_empty() else "none"
	var cap_key: String = ("%s:%s" % [cap_jma, cap_jmp]) if not cap_jma.is_empty() and not cap_jmp.is_empty() else "none"
	var weapon_key: String = ("%s:%s" % [weapon_jma, weapon_jmp]) if not weapon_jma.is_empty() and not weapon_jmp.is_empty() else "none"

	var cache_key: String = "%d:%s:%s:%s:%s:%s:%s:%s" % [role_id, body_key, face_key, clothes_key, shoes_key, hair_key, cap_key, weapon_key]

	if _composite_cache.has(cache_key):
		return _composite_cache[cache_key]
	elif equip_layers.is_empty() and _composite_cache.has(role_id):
		return _composite_cache[role_id]

	var body_anim = get_jma_animation(body_jma, body_jmp) if not body_jma.is_empty() and not body_jmp.is_empty() else null
	var face_anim = get_jma_animation(face_jma, face_jmp) if not face_jma.is_empty() and not face_jmp.is_empty() else null
	var clothes_anim = get_jma_animation(clothes_jma, clothes_jmp) if not clothes_jma.is_empty() and not clothes_jmp.is_empty() else null
	var shoes_anim = get_jma_animation(shoes_jma, shoes_jmp) if not shoes_jma.is_empty() and not shoes_jmp.is_empty() else null
	var hair_anim = get_jma_animation(hair_jma, hair_jmp) if not hair_jma.is_empty() and not hair_jmp.is_empty() else null
	var cap_anim = get_jma_animation(cap_jma, cap_jmp) if not cap_jma.is_empty() and not cap_jmp.is_empty() else null
	var weapon_anim = get_jma_animation(weapon_jma, weapon_jmp) if not weapon_jma.is_empty() and not weapon_jmp.is_empty() else null

	if not body_anim:
		body_anim = get_jma_animation("001.jma", "1000.jmp")
	if not body_anim:
		push_error("Failed to load body animation for composite role %d (%s:%s)" % [role_id, body_jma, body_jmp])
		return []

	# Authentic layer composite order:
	# Base order: body, face, clothes, shoes, hair, cap.
	# In WLO, weapon is worn on the character's back:
	# When facing generally South/East/West (headings 2, 3, 4, 5, 6), weapon sits BEHIND the torso/body.
	# When facing North (headings 0, 1, 7), character back faces camera, so weapon sits IN FRONT of clothes/body.
	var composite_frames: Array[ImageTexture] = []
	var total_frames: int = mini(body_anim.frames.size(), 216) if (body_anim and body_anim.frames.size() > 0) else 216

	for frame_idx in range(total_frames):
		var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))

		var heading: int = (frame_idx % 32) / 4
		var weapon_behind := (heading >= 2 and heading <= 6)

		var cur_layers: Array = []
		if weapon_anim and weapon_behind:
			cur_layers.append(weapon_anim)

		if body_anim: cur_layers.append(body_anim)
		if face_anim and face_anim.frames.size() >= total_frames: cur_layers.append(face_anim)
		if clothes_anim: cur_layers.append(clothes_anim)
		if shoes_anim: cur_layers.append(shoes_anim)

		if weapon_anim and not weapon_behind:
			cur_layers.append(weapon_anim)

		if hair_anim: cur_layers.append(hair_anim)
		if cap_anim: cur_layers.append(cap_anim)

		for anim in cur_layers:
			if not anim or frame_idx >= anim.frames.size():
				continue
			var j_frame = anim.get_frame(frame_idx)
			if not j_frame or j_frame.width <= 0 or j_frame.height <= 0:
				continue
			var layer_img: Image = anim.decode_frame_image(frame_idx)
			if layer_img:
				var ox: int = int((j_frame.bound_w - 128) / 2) if j_frame.bound_w > 128 else 0
				var oy: int = int((j_frame.bound_h - 128) / 2) if j_frame.bound_h > 128 else 0
				canvas.blend_rect(
					layer_img,
					Rect2i(0, 0, j_frame.width, j_frame.height),
					Vector2i(j_frame.pivot_x - ox, j_frame.pivot_y - oy)
				)

		var tex := ImageTexture.create_from_image(canvas)
		composite_frames.append(tex)

	_composite_cache[cache_key] = composite_frames
	if equip_layers.is_empty():
		_composite_cache[role_id] = composite_frames
	return composite_frames

## Composes authentic awakening sequence frames (0: prone 26-2.bmp, 1: rising 26-1.bmp, 2: stand 08-1.bmp)
## onto 128x128 RGBA ImageTextures from active paper-doll layers.
func get_player_awakening_composite_frames(role_id: int, equip_layers: Dictionary = {}) -> Array[ImageTexture]:
	var cache_key: String = "awakening_%d" % role_id
	if _composite_cache.has(cache_key):
		return _composite_cache[cache_key]

	var role_info: Dictionary = {}
	var game_db = null
	if is_inside_tree():
		game_db = get_node_or_null("/root/GameDatabase")
	elif Engine.get_main_loop() is SceneTree:
		var st = Engine.get_main_loop() as SceneTree
		if st and st.root:
			game_db = st.root.get_node_or_null("GameDatabase")
	if game_db and game_db.has_method("get_role"):
		role_info = game_db.get_role(role_id)

	var def_body_jma: String = str(role_info.get("body_archive", "003.jma" if role_id == 2 else "002.jma"))
	var def_body_jmp: String = str(role_info.get("body_jmp", "3000.jmp" if role_id == 2 else "2000.jmp"))
	var def_face_jma: String = str(role_info.get("face_archive", ""))
	var def_face_jmp: String = str(role_info.get("face_jmp", ""))
	if def_face_jma.is_empty() or def_face_jmp.is_empty():
		var b_low := def_body_jma.to_lower()
		if b_low.contains("002"):
			def_face_jma = "002f.jma"
			def_face_jmp = "2600.jmp"
		elif b_low.contains("003"):
			def_face_jma = "003f.jma"
			def_face_jmp = "3600.jmp"
		elif b_low.contains("004"):
			def_face_jma = "004f.jma"
			def_face_jmp = "4600.jmp"
		elif b_low.contains("005"):
			def_face_jma = "005f.jma"
			def_face_jmp = "5600.jmp"

	var def_hair_jma: String = str(role_info.get("hair_archive", "003h.jma" if role_id == 2 else "002h.jma"))
	var def_hair_jmp: String = str(role_info.get("hair_jmp", "3101.jmp" if role_id == 2 else "2100.jmp"))
	var def_clothes_jma: String = str(role_info.get("default_clothes_archive", "003e.jma" if role_id == 2 else "002e.jma"))
	var def_clothes_jmp: String = str(role_info.get("default_clothes_jmp", "3301.jmp" if role_id == 2 else "2300.jmp"))
	var def_shoes_jma: String = str(role_info.get("default_shoes_archive", "003s.jma" if role_id == 2 else "002s.jma"))
	var def_shoes_jmp: String = str(role_info.get("default_shoes_jmp", "3401.jmp" if role_id == 2 else "2400.jmp"))
	var def_cap_jma: String = str(role_info.get("default_head_archive", "003c.jma" if role_id == 2 else ""))
	var def_cap_jmp: String = str(role_info.get("default_head_jmp", "3201.jmp" if role_id == 2 else ""))

	var body_anim = get_jma_animation(def_body_jma, def_body_jmp)
	var face_anim = get_jma_animation(def_face_jma, def_face_jmp) if not def_face_jma.is_empty() and not def_face_jmp.is_empty() else null
	var clothes_anim = get_jma_animation(def_clothes_jma, def_clothes_jmp)
	var shoes_anim = get_jma_animation(def_shoes_jma, def_shoes_jmp)
	var hair_anim = get_jma_animation(def_hair_jma, def_hair_jmp)
	var cap_anim = get_jma_animation(def_cap_jma, def_cap_jmp) if not def_cap_jma.is_empty() and not def_cap_jmp.is_empty() else null

	var layer_anims: Array = []
	if body_anim: layer_anims.append(body_anim)
	if face_anim and face_anim.frames.size() >= 64: layer_anims.append(face_anim)
	if clothes_anim: layer_anims.append(clothes_anim)
	if shoes_anim: layer_anims.append(shoes_anim)
	if hair_anim: layer_anims.append(hair_anim)
	if cap_anim: layer_anims.append(cap_anim)

	var frame_names: Array[String] = ["26-2.bmp", "26-1.bmp", "08-1.bmp"]
	var result_frames: Array[ImageTexture] = []

	for fname in frame_names:
		var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))

		for anim in layer_anims:
			if not anim:
				continue
			var j_frame = anim.get_frame_by_name(fname)
			if not j_frame or j_frame.width <= 0 or j_frame.height <= 0:
				continue
			var layer_img: Image = anim.decode_frame_image_by_name(fname)
			if layer_img:
				canvas.blend_rect(
					layer_img,
					Rect2i(0, 0, j_frame.width, j_frame.height),
					Vector2i(j_frame.pivot_x, j_frame.pivot_y)
				)

		var tex := ImageTexture.create_from_image(canvas)
		result_frames.append(tex)

	_composite_cache[cache_key] = result_frames
	return result_frames

## Resolves BGM file path on disk (WAV/OGG)
func get_bgm_path(bgm_id: int) -> String:
	var candidates := [
		sound_path + "/BGM%04d.wav" % bgm_id,
		sound_path + "/BGM%d.wav" % bgm_id,
		sound_path + "/BGM0013.wav" # Fallback village theme
	]
	for path in candidates:
		if FileAccess.file_exists(path):
			return path
	return ""

## Loads custom cursor from cursor/cursor1.ani in memory and applies the initial frame
func setup_custom_cursor() -> void:
	var frames := get_cursor_frames()
	if not frames.is_empty():
		Input.set_custom_mouse_cursor(frames[0], Input.CURSOR_ARROW, Vector2(0, 0))

## Parses assets/cursor/<cursor_name>.ani (RIFF/ACON format).
## Extracts each icon chunk in the fram list, converts to Godot Image, creates ImageTexture, and caches in RAM.
func get_cursor_frames(cursor_name: String = "cursor1") -> Array[ImageTexture]:
	var clean_name: String = cursor_name.replace(".ani", "").strip_edges()
	if clean_name.is_empty():
		clean_name = "cursor1"
	
	if _cursor_cache.has(clean_name):
		return _cursor_cache[clean_name]

	var ani_candidates := [
		cursor_path + "/" + clean_name + ".ani",
		base_path + "/cursor/" + clean_name + ".ani",
		"res://assets/cursor/" + clean_name + ".ani",
		"D:/GitHub/WLRI/cursor/" + clean_name + ".ani"
	]

	var file_path := ""
	for cand in ani_candidates:
		if FileAccess.file_exists(cand):
			file_path = cand
			break

	if file_path.is_empty():
		return []

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return []

	var data := file.get_buffer(file.get_length())
	if data.size() < 12:
		return []

	# Validate RIFF container header and ACON format
	if data.slice(0, 4).get_string_from_ascii() != "RIFF":
		return []
	if data.slice(8, 12).get_string_from_ascii() != "ACON":
		return []

	var frames: Array[ImageTexture] = []
	var pos: int = 12
	var total_len: int = data.size()
	while pos + 8 <= total_len:
		var chunk_id := data.slice(pos, pos + 4).get_string_from_ascii()
		var chunk_size: int = data.decode_u32(pos + 4)
		if chunk_size == 0 and chunk_id != "LIST":
			break

		if chunk_id == "LIST" and pos + 12 <= total_len:
			var list_type := data.slice(pos + 8, pos + 12).get_string_from_ascii()
			if list_type == "fram":
				var sub_pos: int = pos + 12
				var sub_end: int = mini(pos + 8 + chunk_size, total_len)
				while sub_pos + 8 <= sub_end:
					var sub_id := data.slice(sub_pos, sub_pos + 4).get_string_from_ascii()
					var sub_size: int = data.decode_u32(sub_pos + 4)
					if sub_id == "icon" and sub_pos + 8 + sub_size <= total_len:
						var icon_data := data.slice(sub_pos + 8, sub_pos + 8 + sub_size)
						var tex := _decode_icon_to_texture(icon_data)
						if tex:
							frames.append(tex)
					if sub_size == 0:
						break
					sub_pos += 8 + sub_size + (sub_size & 1)

		pos += 8 + chunk_size + (chunk_size & 1)

	_cursor_cache[clean_name] = frames
	if clean_name == "cursor1":
		_cursor_frames = frames
	return frames

## Decodes Windows .cur/.ico chunk data into Godot ImageTexture with accurate transparency.
func _decode_icon_to_texture(icon_data: PackedByteArray) -> ImageTexture:
	if icon_data.size() < 22:
		return null

	var dib_offset: int = icon_data.decode_u32(18)
	if dib_offset + 40 > icon_data.size():
		return null

	var bi_size: int = icon_data.decode_u32(dib_offset)
	var bi_width: int = icon_data.decode_s32(dib_offset + 4)
	var bi_height: int = icon_data.decode_s32(dib_offset + 8)
	var bi_bit_count: int = icon_data.decode_u16(dib_offset + 14)
	var bi_clr_used: int = icon_data.decode_u32(dib_offset + 32)

	var real_width: int = bi_width
	var real_height: int = bi_height / 2
	if real_width <= 0 or real_height <= 0:
		return null

	if bi_bit_count == 8:
		var num_colors: int = bi_clr_used if bi_clr_used > 0 else 256
		var pal_offset: int = dib_offset + bi_size
		if pal_offset + num_colors * 4 > icon_data.size():
			return null

		var xor_stride: int = ((real_width * 8 + 31) / 32) * 4
		var xor_offset: int = pal_offset + num_colors * 4
		if xor_offset + xor_stride * real_height > icon_data.size():
			return null

		var and_stride: int = ((real_width + 31) / 32) * 4
		var and_offset: int = xor_offset + xor_stride * real_height
		var has_and_mask: bool = (and_offset + and_stride * real_height <= icon_data.size())

		var rgba := PackedByteArray()
		rgba.resize(real_width * real_height * 4)

		for y in range(real_height):
			var src_y: int = real_height - 1 - y # DIB scanlines are bottom-up
			for x in range(real_width):
				var is_transparent: bool = false
				if has_and_mask:
					var and_byte: int = icon_data[and_offset + src_y * and_stride + (x >> 3)]
					is_transparent = ((and_byte >> (7 - (x & 7))) & 1) == 1

				var out_idx: int = (y * real_width + x) * 4
				if is_transparent:
					rgba[out_idx] = 0
					rgba[out_idx + 1] = 0
					rgba[out_idx + 2] = 0
					rgba[out_idx + 3] = 0
				else:
					var pal_idx: int = icon_data[xor_offset + src_y * xor_stride + x]
					var pal_entry: int = pal_offset + pal_idx * 4
					var b: int = icon_data[pal_entry]
					var g: int = icon_data[pal_entry + 1]
					var r: int = icon_data[pal_entry + 2]
					if r == 0 and g == 255 and b == 0:
						rgba[out_idx] = 0
						rgba[out_idx + 1] = 0
						rgba[out_idx + 2] = 0
						rgba[out_idx + 3] = 0
					else:
						rgba[out_idx] = r
						rgba[out_idx + 1] = g
						rgba[out_idx + 2] = b
						rgba[out_idx + 3] = 255

		var img := Image.create_from_data(real_width, real_height, false, Image.FORMAT_RGBA8, rgba)
		return ImageTexture.create_from_image(img)

	elif bi_bit_count == 32:
		var xor_stride: int = real_width * 4
		var xor_offset: int = dib_offset + bi_size
		if xor_offset + xor_stride * real_height <= icon_data.size():
			var rgba := PackedByteArray()
			rgba.resize(real_width * real_height * 4)
			for y in range(real_height):
				var src_y: int = real_height - 1 - y
				for x in range(real_width):
					var pixel_offset: int = xor_offset + src_y * xor_stride + x * 4
					var b: int = icon_data[pixel_offset]
					var g: int = icon_data[pixel_offset + 1]
					var r: int = icon_data[pixel_offset + 2]
					var a: int = icon_data[pixel_offset + 3]
					var out_idx: int = (y * real_width + x) * 4
					rgba[out_idx] = r
					rgba[out_idx + 1] = g
					rgba[out_idx + 2] = b
					rgba[out_idx + 3] = a
			var img := Image.create_from_data(real_width, real_height, false, Image.FORMAT_RGBA8, rgba)
			return ImageTexture.create_from_image(img)

	return null
