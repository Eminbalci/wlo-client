class_name RepairWindow
extends Control

## Equipment repair, rebuilt from Form_Repair (aLogin.exe constructor 0x1ac9f0, skin
## white/Form_Repair.bmp 171x183, title "REPAIR" baked in). Controls: one item cell "SelectUitem"
## (70,71) 32x32, Btn_OK_2 (37,142) 39x20, Btn_Cancel_3 (93,142) 39x20; no close sphere.
## OK handler 0x1b14cc: nothing selected -> nothing; in battle -> "Can't fix in battle"; the 15
## "Broken <weapon/armour>" items are silently refused; otherwise sends action 0x17 sub 0x54,
## shows "<item name> Repaired" and plays sound\wav0152.wav. Durability: item dict keys
## "durability"/"max_durability", falling back to the ItemDatabase record.
## Cost: not in the client (server side) -> `cost_per_point` (default 0) is a placeholder.

signal item_repaired(bag_index: int, item: Dictionary, cost: int)
signal message(text: String)
signal window_closed

const WINDOW_SIZE: Vector2 = Vector2(171, 183)
const SLOT_RECT: Rect2 = Rect2(70, 71, 32, 32)
const OK_RECT: Rect2 = Rect2(37, 142, 39, 20)
const CANCEL_RECT: Rect2 = Rect2(93, 142, 39, 20)
## Item ids compared in the OK handler (0x1b1568..0x1b1613): Broken Knife ... Broken Adornment.
const UNREPAIRABLE_IDS: Array[int] = [10062, 11098, 12069, 13064, 14063, 15051, 17066, 18062, 19055, 20039, 21120, 22125, 23105, 24090, 25044]
const REPAIR_SOUND: String = "res://assets/sound/wav0152.wav"

var inventory: Object = null
var in_battle: bool = false
var cost_per_point: int = 0
var selected_bag_index: int = -1
var is_open: bool = false

var background: TextureRect = null
var item_slot: SkinItemSlot = null
var btn_ok: TextureButton = null
var btn_cancel: TextureButton = null
var _built: bool = false


func _init() -> void:
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_build()


## Scene instances build right after their children (the Background node) are added, so the
## controls exist before the node enters the tree.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_build()


func setup(p_inventory: Object) -> void:
	inventory = p_inventory
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	background = SkinWindowKit.background(self, "form_repair", WINDOW_SIZE)
	item_slot = SkinWindowKit.slot(self, "SelectUitem", SLOT_RECT, 0)
	item_slot.slot_pressed.connect(func(_s: SkinItemSlot) -> void: clear_selection())
	btn_ok = SkinWindowKit.button(self, "BtnOK", "btn_ok_2", OK_RECT)
	btn_cancel = SkinWindowKit.button(self, "BtnCancel", "btn_cancel_3", CANCEL_RECT)
	btn_cancel.tooltip_text = "[ESC]"
	btn_ok.pressed.connect(repair_selected)
	btn_cancel.pressed.connect(close_window)


# --- public API ---------------------------------------------------------------------------

func open_repair(p_inventory: Object = null) -> void:
	_build()
	if p_inventory:
		inventory = p_inventory
	clear_selection()
	is_open = true
	visible = true


func close_window() -> void:
	clear_selection()
	is_open = false
	visible = false
	window_closed.emit()


## Copies bag slot `bag_index` into the repair cell (0x1b1814 copies the bag cell's fields).
func select_inventory_slot(bag_index: int) -> bool:
	var item: Dictionary = SkinWindowKit.inv_item(inventory, bag_index)
	if item.is_empty():
		return false
	selected_bag_index = bag_index
	item_slot.set_item(_with_durability(item))
	return true


func clear_selection() -> void:
	selected_bag_index = -1
	if item_slot:
		item_slot.clear_item()


func get_durability(item: Dictionary) -> Vector2i:
	var d: Dictionary = _with_durability(item)
	return Vector2i(int(d.get("durability", 0)), int(d.get("max_durability", 0)))


func get_repair_cost(item: Dictionary) -> int:
	var dur: Vector2i = get_durability(item)
	return maxi(0, dur.y - dur.x) * cost_per_point


func is_repairable(item: Dictionary) -> bool:
	if item.is_empty() or UNREPAIRABLE_IDS.has(int(item.get("id", 0))):
		return false
	return _is_equipment(item)


## Btn_OK_2. Returns true when the item was repaired.
func repair_selected() -> bool:
	if selected_bag_index < 0:
		return false
	if in_battle:
		message.emit("Can't fix in battle")
		return false
	var item: Dictionary = SkinWindowKit.inv_item(inventory, selected_bag_index)
	if item.is_empty():
		clear_selection()
		return false
	if not is_repairable(item):
		return false # the client returns silently
	var dur: Vector2i = get_durability(item)
	if dur.y <= 0 or dur.x >= dur.y:
		message.emit("Doesn't need repairs")
		return false
	var cost: int = get_repair_cost(item)
	var gold: int = SkinWindowKit.inv_gold(inventory)
	if cost > gold:
		message.emit("Not enough Gold")
		return false
	var repaired: Dictionary = item.duplicate(true)
	repaired["durability"] = dur.y
	repaired["max_durability"] = dur.y
	SkinWindowKit.inv_set(inventory, selected_bag_index, repaired)
	if cost > 0:
		SkinWindowKit.inv_set_gold(inventory, gold - cost)
	item_slot.set_item(repaired)
	message.emit("%s Repaired" % str(repaired.get("name", "")))
	_play_sound()
	item_repaired.emit(selected_bag_index, repaired, cost)
	return true


# --- internals ----------------------------------------------------------------------------

func _is_equipment(item: Dictionary) -> bool:
	if not str(item.get("equip_slot", "")).is_empty():
		return true
	var rec: Variant = SkinWindowKit.item_record(int(item.get("id", 0)))
	return rec != null and int(rec.equip_pos) >= 1 and int(rec.equip_pos) <= 6


func _with_durability(item: Dictionary) -> Dictionary:
	var d: Dictionary = item.duplicate(true)
	if d.has("durability") and d.has("max_durability"):
		return d
	var rec: Variant = SkinWindowKit.item_record(int(d.get("id", 0)))
	var max_d: int = int(rec.max_durability) if rec != null else 0
	if not d.has("max_durability"):
		d["max_durability"] = max_d
	if not d.has("durability"):
		d["durability"] = int(rec.durability) if rec != null else max_d
	return d


func _play_sound() -> void:
	if not is_inside_tree() or not ResourceLoader.exists(REPAIR_SOUND):
		return
	var p := AudioStreamPlayer.new()
	p.stream = load(REPAIR_SOUND)
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_open and visible and event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		close_window()
		get_viewport().set_input_as_handled()
