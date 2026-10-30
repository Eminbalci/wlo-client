class_name TradeWindow
extends Control

## Player-to-player item trade, rebuilt from the real client's Form_TradeItem_1 constructor
## (aLogin.exe 0x37f744, skin menu/Skins/white/Form_TradeItem_1.bmp 401x481) and its button
## handlers (Cancel 0x381c98, Trade ~0x381e9c, Confirm 0x381f90). Addresses and evidence:
## docs/re/trade_window.md.
##
## Layout (all decoded immediates):
##   other player's offer   4x5 slots at (24 + 34c, 69 + 34r)        "money earned" label (92,213)
##   my offer               4x5 slots at (24 + 34c, 250 + 34r)       "money paid" entry (92,390) max 9 digits
##   my bag                10x5 slots at (206 + 34c, 68 + 34r)       partner name label (92,43)
##   Btn_confirm_1 (100,445)  Btn_Trade_2 (174,445, hidden until both confirmed)  Btn_Cancel_1 (250,445)
##   icon_Confirm_1 / icon_trade_1 sit under the Confirm / Trade buttons (greyed stand-ins).
##
## Network: every button sends action 0x19 (trade). Confirm = sub 2, Cancel and Trade = sub 3 with
## a state byte (2 = cancel, 1 = accept; inferred from [esi+0x48c]). Offline, a TradePartnerStub
## plays the other side (see trade_partner_stub.gd).

signal trade_opened(partner_name: String)
signal offer_changed(items: Array, gold: int)
signal offer_confirmed(items: Array, gold: int)
signal trade_accepted
signal trade_completed(received_items: Array, received_gold: int, given_items: Array, given_gold: int)
signal trade_canceled
signal message(text: String)
signal window_closed

const WINDOW_SIZE: Vector2 = Vector2(401, 481)
const OFFER_SLOTS: int = 20
const CLOSE_RECT: Rect2 = Rect2(352, 25, 18, 18)
const CONFIRM_RECT: Rect2 = Rect2(100, 445, 56, 20)
const TRADE_RECT: Rect2 = Rect2(174, 445, 56, 20)
const CANCEL_RECT: Rect2 = Rect2(250, 445, 56, 20)
const ARROW_L_RECT: Rect2 = Rect2(200, 335, 17, 17)
const ARROW_R_RECT: Rect2 = Rect2(201, 288, 17, 17)
const PARTNER_NAME_RECT: Rect2 = Rect2(92, 43, 160, 20)
const PARTNER_GOLD_RECT: Rect2 = Rect2(92, 213, 100, 24)
const MY_GOLD_RECT: Rect2 = Rect2(92, 390, 100, 24)
const OTHER_GRID_ORIGIN: Vector2 = Vector2(24, 69)
const MY_GRID_ORIGIN: Vector2 = Vector2(24, 250)
const BAG_GRID_ORIGIN: Vector2 = Vector2(206, 68)

var inventory: Object = null ## HUDInventory (or any object with the same small API)
var partner_name: String = ""
var my_confirmed: bool = false
var partner_confirmed: bool = false
var is_open: bool = false

## my offer: Array of {"bag_index": int, "item": Dictionary}
var _my_offer: Array[Dictionary] = []
var _partner_items: Array[Dictionary] = []
var _partner_gold: int = 0

var background: TextureRect = null
var close_button: Button = null
var btn_confirm: TextureButton = null
var btn_trade: TextureButton = null
var btn_cancel: TextureButton = null
var icon_confirm: TextureRect = null
var icon_trade: TextureRect = null
var btn_arrow_l: TextureButton = null
var btn_arrow_r: TextureButton = null
var partner_name_label: Label = null
var partner_gold_label: Label = null
var my_gold_edit: LineEdit = null
var other_slots: Array[SkinItemSlot] = []
var my_slots: Array[SkinItemSlot] = []
var bag_slots: Array[SkinItemSlot] = []

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
	refresh_bag()


func _build() -> void:
	if _built:
		return
	_built = true
	size = WINDOW_SIZE
	background = SkinWindowKit.background(self, "form_trade_item_1", WINDOW_SIZE)
	other_slots = SkinWindowKit.grid(self, "OtherSlot", OTHER_GRID_ORIGIN, 5, 4)
	my_slots = SkinWindowKit.grid(self, "MySlot", MY_GRID_ORIGIN, 5, 4)
	bag_slots = SkinWindowKit.grid(self, "BagSlot", BAG_GRID_ORIGIN, 5, 10)
	for s in other_slots:
		s.mouse_default_cursor_shape = Control.CURSOR_ARROW
	for s in my_slots:
		s.slot_pressed.connect(_on_my_slot_pressed)
	for s in bag_slots:
		s.slot_pressed.connect(_on_bag_slot_pressed)
	partner_name_label = SkinWindowKit.label(self, "PartnerNameLabel", PARTNER_NAME_RECT)
	partner_gold_label = SkinWindowKit.label(self, "PartnerGoldLabel", PARTNER_GOLD_RECT, "0", HORIZONTAL_ALIGNMENT_RIGHT)
	my_gold_edit = SkinWindowKit.gold_edit(self, "MyGoldEdit", MY_GOLD_RECT)
	my_gold_edit.text_changed.connect(_on_my_gold_changed)
	# Arrow buttons exist in the constructor but are hidden (0x480670 with dl=0).
	btn_arrow_l = SkinWindowKit.button(self, "ArrowL", "btn_arrow_l_5", ARROW_L_RECT)
	btn_arrow_r = SkinWindowKit.button(self, "ArrowR", "btn_arrow_r_5", ARROW_R_RECT)
	btn_arrow_l.visible = false
	btn_arrow_r.visible = false
	icon_confirm = SkinWindowKit.picture(self, "IconConfirm", "icon_confirm_1", CONFIRM_RECT)
	icon_trade = SkinWindowKit.picture(self, "IconTrade", "icon_trade_1", TRADE_RECT)
	btn_confirm = SkinWindowKit.button(self, "BtnConfirm", "btn_confirm_1", CONFIRM_RECT)
	btn_trade = SkinWindowKit.button(self, "BtnTrade", "btn_trade_2", TRADE_RECT)
	btn_cancel = SkinWindowKit.button(self, "BtnCancel", "btn_cancel_1", CANCEL_RECT)
	btn_confirm.pressed.connect(confirm_offer)
	btn_trade.pressed.connect(accept_trade)
	btn_cancel.pressed.connect(cancel_trade)
	close_button = SkinWindowKit.close_sphere(self, CLOSE_RECT)
	close_button.pressed.connect(cancel_trade)
	_reset_state()


# --- public API ---------------------------------------------------------------------------

## Opens the window for a trade with `p_partner_name` (server: trade request accepted).
func open_trade(p_partner_name: String, p_inventory: Object = null) -> void:
	_build()
	if p_inventory:
		inventory = p_inventory
	_reset_state()
	partner_name = p_partner_name
	partner_name_label.text = p_partner_name
	is_open = true
	visible = true
	refresh_bag()
	trade_opened.emit(p_partner_name)


func close_window() -> void:
	is_open = false
	visible = false
	window_closed.emit()


func get_my_offer_items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in _my_offer:
		out.append((o["item"] as Dictionary).duplicate(true))
	return out


func get_my_offer_gold() -> int:
	return SkinWindowKit.parse_gold(my_gold_edit.text) if my_gold_edit else 0


func set_my_offer_gold(amount: int) -> void:
	if my_confirmed:
		return
	my_gold_edit.text = str(maxi(0, amount))
	_on_my_gold_changed(my_gold_edit.text)


func get_partner_items() -> Array[Dictionary]:
	return _partner_items.duplicate(true)


func get_partner_gold() -> int:
	return _partner_gold


## Puts the item in bag slot `bag_index` into my offer. Returns false when refused.
func offer_bag_item(bag_index: int) -> bool:
	if my_confirmed:
		_say("Trade is locked")
		return false
	var item: Dictionary = SkinWindowKit.inv_item(inventory, bag_index)
	if item.is_empty():
		return false
	if _offer_index_of_bag(bag_index) >= 0:
		return false
	if item.has("tradeable") and not bool(item["tradeable"]):
		_say("Non-tradeable")
		return false
	if _my_offer.size() >= OFFER_SLOTS:
		return false
	_my_offer.append({"bag_index": bag_index, "item": item.duplicate(true)})
	_refresh_my_offer()
	refresh_bag()
	offer_changed.emit(get_my_offer_items(), get_my_offer_gold())
	return true


## Takes offer slot `offer_index` back out of my offer.
func withdraw_offer(offer_index: int) -> bool:
	if my_confirmed or offer_index < 0 or offer_index >= _my_offer.size():
		return false
	_my_offer.remove_at(offer_index)
	_refresh_my_offer()
	refresh_bag()
	offer_changed.emit(get_my_offer_items(), get_my_offer_gold())
	return true


## Fills the other player's side (server packet, or the offline stub).
func set_partner_offer(items: Array, gold: int) -> void:
	_partner_items.clear()
	for it in items:
		if it is Dictionary and int((it as Dictionary).get("id", 0)) > 0 and _partner_items.size() < OFFER_SLOTS:
			_partner_items.append((it as Dictionary).duplicate(true))
	_partner_gold = maxi(0, gold)
	for i in range(other_slots.size()):
		other_slots[i].set_item(_partner_items[i] if i < _partner_items.size() else {})
	partner_gold_label.text = str(_partner_gold)


func set_partner_confirmed(value: bool) -> void:
	partner_confirmed = value
	_update_buttons()


## Btn_confirm_1 (handler 0x381f90): checks the gold, locks the offer, sends 0x19/2.
func confirm_offer() -> bool:
	if my_confirmed:
		return false
	var gold: int = get_my_offer_gold()
	if gold > SkinWindowKit.inv_gold(inventory):
		_say("Not enough Gold")
		return false
	my_confirmed = true
	my_gold_edit.editable = false
	for s in my_slots:
		s.locked = true
	_update_buttons()
	offer_confirmed.emit(get_my_offer_items(), gold)
	return true


## Btn_Trade_2: needs room for the partner's items ("Inventory full, can't trade").
func accept_trade() -> bool:
	if not (my_confirmed and partner_confirmed):
		return false
	if not _has_room_for_partner_items():
		_say("Inventory full, can't trade")
		return false
	btn_trade.visible = false
	trade_accepted.emit()
	return true


## Applies the exchange to the inventory and gold (server "Trade complete", or the stub).
func complete_trade() -> bool:
	if not (my_confirmed and partner_confirmed):
		return false
	if not _has_room_for_partner_items():
		_say("Inventory full, can't trade")
		return false
	var given: Array[Dictionary] = get_my_offer_items()
	var given_gold: int = get_my_offer_gold()
	if given_gold > SkinWindowKit.inv_gold(inventory):
		_say("Not enough Gold")
		return false
	for o in _my_offer:
		SkinWindowKit.inv_set(inventory, int(o["bag_index"]), {})
	var received: Array[Dictionary] = get_partner_items()
	for it in received:
		SkinWindowKit.inv_add(inventory, it)
	SkinWindowKit.inv_set_gold(inventory, SkinWindowKit.inv_gold(inventory) - given_gold + _partner_gold)
	var received_gold: int = _partner_gold
	_say("Trade complete")
	trade_completed.emit(received, received_gold, given, given_gold)
	_reset_state()
	close_window()
	return true


## Btn_Cancel_1 / close sphere (handler 0x381c98): sends 0x19/3 (state 2), clears both sides.
func cancel_trade() -> void:
	var was_open: bool = is_open
	_reset_state()
	if was_open:
		_say("Trade canceled")
		trade_canceled.emit()
	close_window()


func refresh_bag() -> void:
	for i in range(bag_slots.size()):
		var s: SkinItemSlot = bag_slots[i]
		s.set_item(SkinWindowKit.inv_item(inventory, i))
		s.locked = _offer_index_of_bag(i) >= 0
		s.disabled = i >= SkinWindowKit.inv_items(inventory).size()


# --- internals ----------------------------------------------------------------------------

func _reset_state() -> void:
	_my_offer.clear()
	_partner_items.clear()
	_partner_gold = 0
	my_confirmed = false
	partner_confirmed = false
	if my_gold_edit:
		my_gold_edit.text = "0"
		my_gold_edit.editable = true
	if partner_gold_label:
		partner_gold_label.text = "0"
	if partner_name_label:
		partner_name_label.text = ""
	for s in other_slots + my_slots:
		s.clear_item()
	_update_buttons()
	if not bag_slots.is_empty():
		refresh_bag()


func _update_buttons() -> void:
	if btn_confirm == null:
		return
	btn_confirm.visible = not my_confirmed
	btn_trade.visible = my_confirmed and partner_confirmed
	icon_confirm.visible = true
	icon_trade.visible = true


func _refresh_my_offer() -> void:
	for i in range(my_slots.size()):
		my_slots[i].set_item(_my_offer[i]["item"] if i < _my_offer.size() else {})


func _offer_index_of_bag(bag_index: int) -> int:
	for i in range(_my_offer.size()):
		if int(_my_offer[i]["bag_index"]) == bag_index:
			return i
	return -1


func _has_room_for_partner_items() -> bool:
	var free: int = SkinWindowKit.inv_free_slots(inventory) + _my_offer.size()
	return _partner_items.size() <= free


func _on_bag_slot_pressed(s: SkinItemSlot) -> void:
	var idx: int = _offer_index_of_bag(s.slot_index)
	if idx >= 0:
		withdraw_offer(idx)
	else:
		offer_bag_item(s.slot_index)


func _on_my_slot_pressed(s: SkinItemSlot) -> void:
	withdraw_offer(s.slot_index)


func _on_my_gold_changed(_text: String) -> void:
	if not my_confirmed:
		offer_changed.emit(get_my_offer_items(), get_my_offer_gold())


func _say(text: String) -> void:
	message.emit(text)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_open and visible and event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		cancel_trade()
		get_viewport().set_input_as_handled()
