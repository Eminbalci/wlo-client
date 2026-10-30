class_name SkinWindowKit
extends RefCounted

## Shared helpers for the skin-built windows decoded from aLogin.exe (trade, pet trade, item bank,
## repair). Every control is placed at the immediates the real client passes to its control
## constructor: x in ECX, then y, width, height pushed first (vmt+8 call, see docs/re/trade_window.md).
##
## Inventory access goes through the small duck-typed API HUDInventory already has
## (inventory_data, current_gold, set_inventory_data_item, clear_inventory_slot, update_gold), so
## the windows work with the live HUD model and with a plain test double.

const HUD_DIR: String = "res://assets/hud/"
const TEXT_COLOR: Color = Color(0.28, 0.33, 0.52, 1.0) # blue-grey of the baked captions
const BAG_SLOTS: int = 50 # the real bag grid is 10 rows x 5 columns


static func tex(stem_or_path: String) -> Texture2D:
	var path: String = stem_or_path
	if not path.begins_with("res://"):
		path = HUD_DIR + stem_or_path + ".png"
	if ResourceLoader.exists(path):
		var res := load(path) as Texture2D
		if res:
			return res
	# Not imported yet (fresh checkout / headless): read the PNG straight from disk.
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


static func background(parent: Control, stem: String, window_size: Vector2) -> TextureRect:
	var bg := parent.get_node_or_null("Background") as TextureRect
	if bg == null:
		bg = TextureRect.new()
		bg.name = "Background"
		parent.add_child(bg)
		parent.move_child(bg, 0)
	bg.position = Vector2.ZERO
	bg.size = window_size
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	if bg.texture == null:
		bg.texture = tex(stem)
	return bg


## Skin button from a sliced 3-frame sheet: <stem>_normal/_hover/_pressed.png.
static func button(parent: Control, node_name: String, stem: String, rect: Rect2) -> TextureButton:
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
	btn.texture_pressed = tex(stem + "_pressed")
	parent.add_child(btn)
	return btn


## Single-frame picture (icon_trade_1 / icon_Confirm_1 are the greyed stand-ins under a button).
static func picture(parent: Control, node_name: String, stem: String, rect: Rect2) -> TextureRect:
	var pic := TextureRect.new()
	pic.name = node_name
	pic.position = rect.position
	pic.size = rect.size
	pic.texture = tex(stem)
	pic.stretch_mode = TextureRect.STRETCH_KEEP
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pic)
	return pic


## Transparent hit area over the "x" sphere baked into the skin (Btn_Close_s_1 is drawn by the skin).
static func close_sphere(parent: Control, rect: Rect2) -> Button:
	var btn := Button.new()
	btn.name = "CloseButton"
	parent.add_child(btn)
	WindowCloseButton.apply(btn, parent.size.x)
	btn.position = rect.position
	btn.size = rect.size
	btn.custom_minimum_size = rect.size
	btn.tooltip_text = "[ESC]"
	return btn


static func label(parent: Control, node_name: String, rect: Rect2, text: String = "", align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.text = text
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", TEXT_COLOR)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl


## Gold entry: the client uses an editable label (max length 9 at 0x37fc96) with the text "0".
static func gold_edit(parent: Control, node_name: String, rect: Rect2) -> LineEdit:
	var edit := LineEdit.new()
	edit.name = node_name
	edit.position = rect.position
	edit.size = rect.size
	edit.custom_minimum_size = Vector2(0, 0)
	edit.max_length = 9
	edit.text = "0"
	edit.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	edit.add_theme_font_size_override("font_size", 12)
	edit.add_theme_color_override("font_color", TEXT_COLOR)
	edit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	edit.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	edit.add_theme_stylebox_override("read_only", StyleBoxEmpty.new())
	parent.add_child(edit)
	return edit


static func slot(parent: Control, node_name: String, rect: Rect2, index: int) -> SkinItemSlot:
	var s := SkinItemSlot.new()
	s.name = node_name
	s.slot_index = index
	parent.add_child(s)
	s.position = rect.position
	s.size = rect.size
	s.custom_minimum_size = rect.size
	return s


## Builds a cols x rows grid of slots; origin = first cell, pitch = cell + 2 px gap (34 in the client).
static func grid(parent: Control, prefix: String, origin: Vector2, cols: int, rows: int, pitch: int = 34, cell: int = 32) -> Array[SkinItemSlot]:
	var out: Array[SkinItemSlot] = []
	for r in range(rows):
		for c in range(cols):
			var idx: int = r * cols + c
			var rect := Rect2(origin + Vector2(c * pitch, r * pitch), Vector2(cell, cell))
			out.append(slot(parent, "%s%d" % [prefix, idx], rect, idx))
	return out


# --- inventory adapter --------------------------------------------------------------------

static func inv_items(inv: Object) -> Array:
	if inv == null:
		return []
	var data: Variant = inv.get("inventory_data")
	return data if data is Array else []


static func inv_item(inv: Object, idx: int) -> Dictionary:
	var items: Array = inv_items(inv)
	if idx < 0 or idx >= items.size() or not (items[idx] is Dictionary):
		return {}
	var d: Dictionary = items[idx]
	return d if int(d.get("id", 0)) > 0 else {}


static func inv_set(inv: Object, idx: int, item: Dictionary) -> void:
	if inv == null:
		return
	if item.is_empty():
		if inv.has_method("clear_inventory_slot"):
			inv.clear_inventory_slot(idx)
		else:
			inv_items(inv)[idx] = {}
		return
	if inv.has_method("set_inventory_data_item"):
		inv.set_inventory_data_item(idx, item)
	else:
		inv_items(inv)[idx] = item.duplicate(true)


static func inv_gold(inv: Object) -> int:
	if inv == null:
		return 0
	return int(inv.get("current_gold")) if inv.get("current_gold") != null else 0


static func inv_set_gold(inv: Object, amount: int) -> void:
	if inv == null:
		return
	if inv.has_method("update_gold"):
		inv.update_gold(amount)
	else:
		inv.set("current_gold", amount)


static func inv_free_slots(inv: Object) -> int:
	var n: int = 0
	for it in inv_items(inv):
		if not (it is Dictionary) or int((it as Dictionary).get("id", 0)) <= 0:
			n += 1
	return n


## Stackable = same id and no per-instance state (durability) on either side.
static func can_stack(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return false
	if int(a.get("id", 0)) != int(b.get("id", 0)):
		return false
	if a.has("durability") or b.has("durability"):
		return false
	return str(a.get("equip_slot", "")).is_empty()


## Puts a full item dictionary into the inventory (stacks consumables, keeps per-item state).
static func inv_add(inv: Object, item: Dictionary) -> bool:
	var items: Array = inv_items(inv)
	for i in range(items.size()):
		var cur: Dictionary = inv_item(inv, i)
		if can_stack(cur, item):
			var merged: Dictionary = cur.duplicate(true)
			merged["count"] = int(cur.get("count", 1)) + int(item.get("count", 1))
			inv_set(inv, i, merged)
			return true
	for i in range(items.size()):
		if inv_item(inv, i).is_empty():
			inv_set(inv, i, item)
			return true
	return false


static func item_icon(item: Dictionary) -> Texture2D:
	var icon_id: int = int(item.get("icon_id", 0))
	if icon_id <= 0:
		return null
	var st := Engine.get_main_loop() as SceneTree
	var loader: Node = st.root.get_node_or_null("ArchiveLoader") if st and st.root else null
	if loader and loader.has_method("get_item_icon"):
		return loader.get_item_icon(icon_id)
	return null


static func item_record(item_id: int) -> Variant:
	var st := Engine.get_main_loop() as SceneTree
	var gdb: Node = st.root.get_node_or_null("GameDatabase") if st and st.root else null
	if gdb and "items" in gdb and gdb.items:
		return gdb.items.get_item(item_id)
	return null


static func parse_gold(text: String) -> int:
	var digits: String = ""
	for ch in text.strip_edges():
		if ch >= "0" and ch <= "9":
			digits += ch
	return int(digits) if not digits.is_empty() else 0
