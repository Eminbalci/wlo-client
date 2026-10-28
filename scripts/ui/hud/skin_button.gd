class_name HUDSkinButton
extends RefCounted

## Builds a TextureButton from a classic-skin button sheet: the bitmap stacks three frames
## (normal, highlighted, pressed) and uses pure green (0,255,0) as the transparent key.

const SKIN_PATH_FORMAT: String = "res://assets/menu/Skins/default/Btn_%s.bmp"


static func make(stem: String, pos: Vector2, node_name: String) -> TextureButton:
	var btn := TextureButton.new()
	btn.name = node_name
	btn.position = pos
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var path: String = SKIN_PATH_FORMAT % stem
	if not ResourceLoader.exists(path):
		return btn
	var source := load(path) as Texture2D
	if source == null:
		return btn
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.r < 0.02 and c.g > 0.98 and c.b < 0.02:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	var sheet := ImageTexture.create_from_image(image)
	var frame_size := Vector2(sheet.get_width(), floorf(sheet.get_height() / 3.0))
	btn.size = frame_size
	btn.custom_minimum_size = frame_size
	btn.texture_normal = _frame(sheet, 0, frame_size)
	btn.texture_hover = _frame(sheet, 1, frame_size)
	btn.texture_pressed = _frame(sheet, 2, frame_size)
	return btn


static func _frame(sheet: Texture2D, index: int, frame_size: Vector2) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, frame_size.y * index, frame_size.x, frame_size.y)
	return atlas


## Loads any skin bitmap with its pure green (0, 255, 0) chroma key made transparent.
static func keyed_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var source := load(path) as Texture2D
	if source == null:
		return null
	var image := source.get_image()
	if image == null:
		return source
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.r < 0.02 and c.g > 0.98 and c.b < 0.02:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(image)
