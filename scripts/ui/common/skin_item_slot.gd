class_name SkinItemSlot
extends Button

## One 32x32 item cell of a skin window (the client's item-slot class at VMT 0x368af4, created
## through 0x371074). The empty cell art is baked into the window skin, so the slot itself only
## draws the item icon, the stack count and a selection frame.

signal slot_pressed(slot: SkinItemSlot)

var slot_index: int = 0
var item: Dictionary = {}
var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
var locked: bool = false:
	set(value):
		locked = value
		queue_redraw()

var _icon: TextureRect = null
var _count: Label = null


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "focus", "disabled", "pressed"]:
		add_theme_stylebox_override(state, empty)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1, 1, 1, 0.14)
	hover.border_color = Color(1.0, 0.86, 0.35, 0.8)
	hover.set_border_width_all(1)
	add_theme_stylebox_override("hover", hover)
	_icon = TextureRect.new()
	_icon.name = "Icon"
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_icon)
	_count = Label.new()
	_count.name = "Count"
	_count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_count.set_anchors_preset(Control.PRESET_FULL_RECT)
	_count.add_theme_font_size_override("font_size", 10)
	_count.add_theme_color_override("font_color", Color.WHITE)
	_count.add_theme_color_override("font_outline_color", Color.BLACK)
	_count.add_theme_constant_override("outline_size", 3)
	add_child(_count)
	pressed.connect(func() -> void: slot_pressed.emit(self))


func set_item(data: Dictionary) -> void:
	item = data.duplicate(true) if not data.is_empty() and int(data.get("id", 0)) > 0 else {}
	_refresh()


func clear_item() -> void:
	item = {}
	selected = false
	locked = false
	_refresh()


func is_empty() -> bool:
	return item.is_empty()


func get_icon_texture() -> Texture2D:
	return _icon.texture if _icon else null


func get_count_text() -> String:
	return _count.text if _count else ""


func _refresh() -> void:
	if item.is_empty():
		_icon.texture = null
		_count.text = ""
		tooltip_text = ""
	else:
		_icon.texture = SkinWindowKit.item_icon(item)
		var n: int = int(item.get("count", 1))
		_count.text = str(n) if n > 1 else ""
		var tip: String = str(item.get("name", ""))
		if item.has("durability"):
			tip += "\nDurability %d/%d" % [int(item.get("durability", 0)), int(item.get("max_durability", 0))]
		tooltip_text = tip
	queue_redraw()


func _draw() -> void:
	if locked and not item.is_empty():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.35), true)
	if selected:
		draw_rect(Rect2(Vector2(0.5, 0.5), size - Vector2.ONE), Color(1.0, 0.2, 0.2, 0.95), false, 2.0)
