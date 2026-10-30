class_name WloWindowSkin
extends RefCounted

## Shared helpers for the windows rebuilt from aLogin.exe control tables (world map, GPS, mail,
## channel on/off, emote panel). All bitmaps were pre-sliced into res://assets/hud/ with the
## green (0,255,0) chroma key already removed, so nothing is keyed at runtime.
##
## Textures load through ResourceLoader when the PNG has been imported by the editor, and fall
## back to Image.load_from_file so headless tests work on a fresh checkout before import.

const HUD_DIR: String = "res://assets/hud/"

static var _cache: Dictionary = {}


static func tex(file_name: String) -> Texture2D:
	var path := file_name if file_name.begins_with("res://") else HUD_DIR + file_name
	if not path.ends_with(".png"):
		path += ".png"
	if _cache.has(path):
		return _cache[path]
	var result: Texture2D = null
	if ResourceLoader.exists(path):
		result = load(path) as Texture2D
	if result == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img != null and not img.is_empty():
				result = ImageTexture.create_from_image(img)
	_cache[path] = result
	return result


## Background TextureRect that fills `size` exactly (the skin bitmap is drawn 1:1).
static func background(parent: Control, file_name: String, size: Vector2) -> TextureRect:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = tex(file_name)
	bg.position = Vector2.ZERO
	bg.size = size
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(bg)
	return bg


## Skin button from pre-sliced frames `<stem>_normal/_hover/_pressed.png`. `rect` is the
## control rectangle the original client passes to its button Init (left, top, width, height).
static func button(parent: Control, node_name: String, stem: String, rect: Rect2, tooltip: String = "") -> TextureButton:
	var btn := TextureButton.new()
	btn.name = node_name
	btn.position = rect.position
	btn.size = rect.size
	btn.custom_minimum_size = rect.size
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.texture_normal = tex(stem + "_normal")
	btn.texture_hover = tex(stem + "_hover")
	var pressed := tex(stem + "_pressed")
	btn.texture_pressed = pressed if pressed != null else btn.texture_hover
	btn.tooltip_text = tooltip
	parent.add_child(btn)
	return btn


static func label(parent: Control, node_name: String, rect: Rect2, color: Color, font_size: int = 12,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 2)
	parent.add_child(lbl)
	return lbl


## RGB565 colour as used by the client's text-out routine (0xFFE0 yellow, 0xAD60 olive, 0xF800 red ...).
static func rgb565(value: int) -> Color:
	var r := (value >> 11) & 0x1f
	var g := (value >> 5) & 0x3f
	var b := value & 0x1f
	return Color(r / 31.0, g / 63.0, b / 31.0)


## Lets the window be dragged by any point of its background, like the original forms.
static func make_draggable(window: Control, handle: Control) -> void:
	handle.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			window.position += event.relative
	)
