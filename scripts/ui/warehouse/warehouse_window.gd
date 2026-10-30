class_name WarehouseWindow
extends Control

## Item storage ("bank"). The binary has two forms:
##  - Form_Warehouse (constructor 0x24d880, 441x299, gold arrows btn_Bank_Gold_R/L): NO skin bitmap
##    for it ships in either install, so the live client cannot show it (legacy form).
##  - Form_itemBank_1 (constructor 0x1f8850, skin white/Form_itemBank_1.bmp 416x481): the bank the
##    live client uses. This window rebuilds that one.
## Decoded layout: bank grid 10x5 at (20 + 34c, 83 + 34r) ("store items"), bag grid 10x5 at
## (224 + 34c, 83 + 34r) ("items held"), Btn_ArrowR_5 (200,200) = withdraw (bank -> bag,
## "Select item on left side"), Btn_ArrowL_5 (199,247) = deposit (bag -> bank, "Select item on
## right side"), Btn_Close_s_1 (365,25), Btn_Close_1 (179,437), panel_restrainBank_1 at (20,254)
## hidden. Slots are multi-select (one flag per slot in the client). Both arrows send action 0x1E
## (sub 1 = withdraw, sub 2 = deposit) with the selected slot list. Storage persists to user://.

signal items_deposited(items: Array)
signal items_withdrawn(items: Array)
signal storage_changed
signal message(text: String)
signal window_closed

const WINDOW_SIZE: Vector2 = Vector2(416, 481)
const CAPACITY: int = 50
const DEFAULT_SAVE_PATH: String = "user://warehouse.json"
const CLOSE_S_RECT: Rect2 = Rect2(365, 25, 18, 18)
const CLOSE_RECT: Rect2 = Rect2(179, 437, 56, 20)
const ARROW_R_RECT: Rect2 = Rect2(200, 200, 17, 17)
const ARROW_L_RECT: Rect2 = Rect2(199, 247, 17, 17)
const RESTRAIN_RECT: Rect2 = Rect2(20, 254, 168, 168)
const BANK_ORIGIN: Vector2 = Vector2(20, 83)
const BAG_ORIGIN: Vector2 = Vector2(224, 83)

var inventory: Object = null
var save_path: String = DEFAULT_SAVE_PATH
var is_open: bool = false
var stored: Array[Dictionary] = [] ## CAPACITY entries, {} = empty

var background: TextureRect = null
var close_button: Button = null
var btn_close: TextureButton = null
var btn_withdraw: TextureButton = null ## Btn_ArrowR_5
var btn_deposit: TextureButton = null  ## Btn_ArrowL_5
var restrain_panel: TextureRect = null
var bank_slots: Array[SkinItemSlot] = []
var bag_slots: Array[SkinItemSlot] = []
var _built: bool = false


func _init() -> void:
	size = WINDOW_SIZE
	custom_minimum_size = WINDOW_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	stored.resize(CAPACITY)
	for i in range(CAPACITY):
		stored[i] = {}


func _ready() -> void:
	_build()


## Scene instances build right after their children (the Background node) are added, so the
## controls exist before the node enters the tree.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_build()


func setup(p_inventory: Object, p_save_path: String = DEFAULT_SAVE_PATH) -> void:
	inventory = p_inventory
	save_path = p_save_path
	_build()
	load_storage()
	refresh()


func _build() -> void:
	if _built:
		return
	_built = true
	background = SkinWindowKit.background(self, "form_item_bank_1", WINDOW_SIZE)
	bank_slots = SkinWindowKit.grid(self, "BankSlot", BANK_ORIGIN, 5, 10)
	bag_slots = SkinWindowKit.grid(self, "BagSlot", BAG_ORIGIN, 5, 10)
	for s in bank_slots + bag_slots:
		s.slot_pressed.connect(_on_slot_pressed)
	restrain_panel = SkinWindowKit.picture(self, "RestrainPanel", "panel_restrain_bank_1", RESTRAIN_RECT)
	restrain_panel.visible = false
	btn_deposit = SkinWindowKit.button(self, "BtnDeposit", "btn_arrow_l_5", ARROW_L_RECT)
	btn_withdraw = SkinWindowKit.button(self, "BtnWithdraw", "btn_arrow_r_5", ARROW_R_RECT)
	btn_deposit.tooltip_text = "Store"
	btn_withdraw.tooltip_text = "Take out"
	btn_deposit.pressed.connect(deposit_selected)
	btn_withdraw.pressed.connect(withdraw_selected)
	btn_close = SkinWindowKit.button(self, "BtnClose", "btn_close_1", CLOSE_RECT)
	btn_close.tooltip_text = "[ESC]"
	btn_close.pressed.connect(close_window)
	close_button = SkinWindowKit.close_sphere(self, CLOSE_S_RECT)
	close_button.pressed.connect(close_window)


# --- public API ---------------------------------------------------------------------------

func open_warehouse(p_inventory: Object = null) -> void:
	_build()
	if p_inventory:
		inventory = p_inventory
	load_storage()
	is_open = true
	visible = true
	refresh()


func close_window() -> void:
	_clear_selection()
	is_open = false
	visible = false
	window_closed.emit()


func refresh() -> void:
	for i in range(CAPACITY):
		bank_slots[i].set_item(stored[i])
	var bag_size: int = SkinWindowKit.inv_items(inventory).size()
	for i in range(bag_slots.size()):
		bag_slots[i].set_item(SkinWindowKit.inv_item(inventory, i))
		bag_slots[i].disabled = i >= bag_size


func toggle_bank_selection(index: int) -> void:
	if index >= 0 and index < CAPACITY and not stored[index].is_empty():
		bank_slots[index].selected = not bank_slots[index].selected


func toggle_bag_selection(index: int) -> void:
	if index >= 0 and index < bag_slots.size() and not SkinWindowKit.inv_item(inventory, index).is_empty():
		bag_slots[index].selected = not bag_slots[index].selected


## Btn_ArrowL_5 (0x1f9758): selected bag items -> bank.
func deposit_selected() -> Array[Dictionary]:
	var moved: Array[Dictionary] = []
	var picked: Array[int] = []
	for s in bag_slots:
		if s.selected:
			picked.append(s.slot_index)
	if picked.is_empty():
		message.emit("Select item on right side")
		return moved
	for idx in picked:
		var item: Dictionary = SkinWindowKit.inv_item(inventory, idx)
		if item.is_empty():
			continue
		if not _store(item):
			message.emit("Full, can't store more")
			break
		SkinWindowKit.inv_set(inventory, idx, {})
		moved.append(item)
	_after_move()
	if not moved.is_empty():
		items_deposited.emit(moved)
	return moved


## Btn_ArrowR_5 (0x1f987c): selected bank items -> bag.
func withdraw_selected() -> Array[Dictionary]:
	var moved: Array[Dictionary] = []
	var picked: Array[int] = []
	for s in bank_slots:
		if s.selected:
			picked.append(s.slot_index)
	if picked.is_empty():
		message.emit("Select item on left side")
		return moved
	for idx in picked:
		var item: Dictionary = stored[idx]
		if item.is_empty():
			continue
		if not SkinWindowKit.inv_add(inventory, item):
			message.emit("Inventory is full!")
			break
		stored[idx] = {}
		moved.append(item)
	_after_move()
	if not moved.is_empty():
		items_withdrawn.emit(moved)
	return moved


func deposit_bag_slot(index: int) -> bool:
	_clear_selection()
	toggle_bag_selection(index)
	return not deposit_selected().is_empty()


func withdraw_bank_slot(index: int) -> bool:
	_clear_selection()
	toggle_bank_selection(index)
	return not withdraw_selected().is_empty()


func get_stored_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for it in stored:
		if not it.is_empty():
			out.append(it.duplicate(true))
	return out


func save_storage() -> bool:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"version": 1, "slots": stored}, "\t"))
	f.close()
	return true


func load_storage() -> void:
	for i in range(CAPACITY):
		stored[i] = {}
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not (parsed is Dictionary) or not ((parsed as Dictionary).get("slots") is Array):
		return
	var slots: Array = parsed["slots"]
	for i in range(mini(slots.size(), CAPACITY)):
		if slots[i] is Dictionary and int((slots[i] as Dictionary).get("id", 0)) > 0:
			stored[i] = _normalize(slots[i])


# --- internals ----------------------------------------------------------------------------

## JSON turns ints into floats; put the integer fields back.
func _normalize(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	for k in ["id", "icon_id", "count", "durability", "max_durability", "hp_restore", "sp_restore", "amity_restore"]:
		if out.has(k):
			out[k] = int(out[k])
	return out


func _store(item: Dictionary) -> bool:
	for i in range(CAPACITY):
		if SkinWindowKit.can_stack(stored[i], item):
			stored[i]["count"] = int(stored[i].get("count", 1)) + int(item.get("count", 1))
			return true
	for i in range(CAPACITY):
		if stored[i].is_empty():
			stored[i] = item.duplicate(true)
			return true
	return false


func _after_move() -> void:
	_clear_selection()
	refresh()
	save_storage()
	storage_changed.emit()


func _clear_selection() -> void:
	for s in bank_slots + bag_slots:
		s.selected = false


func _on_slot_pressed(s: SkinItemSlot) -> void:
	if bank_slots.has(s):
		toggle_bank_selection(s.slot_index)
	else:
		toggle_bag_selection(s.slot_index)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_open and visible and event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		close_window()
		get_viewport().set_input_as_handled()
