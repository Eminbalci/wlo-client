class_name TradePetWindow
extends Control

## Player-to-player pet trade, rebuilt from Form_TradePet_1 (aLogin.exe constructor 0x3351a8,
## skin menu/Skins/white/Form_TradePet_1.bmp 463x455). Left panel = the other player's pet
## ("money earned"), right panel = mine ("money paid", arrows to pick which pet). See
## docs/re/trade_window.md for the decoded immediates; label meanings are marked as guesses there.

signal trade_opened(partner_name: String)
signal pet_selected(pet: Dictionary)
signal offer_confirmed(pet: Dictionary, gold: int)
signal trade_accepted
signal trade_completed(received_pet: Dictionary, received_gold: int, given_pet: Dictionary, given_gold: int)
signal trade_canceled
signal message(text: String)
signal window_closed

const WINDOW_SIZE: Vector2 = Vector2(463, 455)
const CLOSE_RECT: Rect2 = Rect2(413, 25, 18, 18)
const CONFIRM_RECT: Rect2 = Rect2(130, 418, 56, 20)
const TRADE_RECT: Rect2 = Rect2(205, 418, 56, 20)
const CANCEL_RECT: Rect2 = Rect2(280, 418, 56, 20)
const ARROW_L_RECT: Rect2 = Rect2(255, 184, 17, 17)
const ARROW_R_RECT: Rect2 = Rect2(399, 184, 17, 17)
const OTHER_HEADER_RECT: Rect2 = Rect2(31, 63, 160, 20)   # label [0x134]
const MY_HEADER_RECT: Rect2 = Rect2(242, 63, 160, 20)     # label [0x130]
const OTHER_NAME_RECT: Rect2 = Rect2(33, 230, 160, 20)    # label [0x198]
const MY_NAME_RECT: Rect2 = Rect2(243, 230, 128, 24)      # label [0x194]
const OTHER_GOLD_RECT: Rect2 = Rect2(95, 380, 128, 14)    # label [0x1e0]
const MY_GOLD_RECT: Rect2 = Rect2(306, 380, 127, 14)      # editable label, text "0"
const OTHER_SKILL_ORIGIN: Vector2 = Vector2(37, 308)      # [0x1b8+i], pitch 35, 33x33
const MY_SKILL_ORIGIN: Vector2 = Vector2(247, 308)        # [0x19c+i]
const OTHER_BOX_RECT: Rect2 = Rect2(178, 266, 33, 33)     # [0x1d0]
const MY_BOX_RECT: Rect2 = Rect2(388, 266, 33, 33)        # [0x1b4]
# LV / HP / loyalty values: the words are baked into the skin; value positions are a GUESS (right of the words).
const OTHER_STATS_ORIGIN: Vector2 = Vector2(62, 252)
const MY_STATS_ORIGIN: Vector2 = Vector2(272, 252)

var inventory: Object = null
var partner_name: String = ""
var my_pets: Array[Dictionary] = []
var my_pet_index: int = -1
var my_confirmed: bool = false
var partner_confirmed: bool = false
var is_open: bool = false
var _partner_pet: Dictionary = {}
var _partner_gold: int = 0

var background: TextureRect = null
var close_button: Button = null
var btn_confirm: TextureButton = null
var btn_trade: TextureButton = null
var btn_cancel: TextureButton = null
var btn_arrow_l: TextureButton = null
var btn_arrow_r: TextureButton = null
var icon_confirm: TextureRect = null
var icon_trade: TextureRect = null
var other_header: Label = null
var my_header: Label = null
var other_pet_name: Label = null
var my_pet_name: Label = null
var other_gold_label: Label = null
var my_gold_edit: LineEdit = null
var other_stats: Array[Label] = []
var my_stats: Array[Label] = []
var other_skill_slots: Array[SkinItemSlot] = []
var my_skill_slots: Array[SkinItemSlot] = []
var other_box: SkinItemSlot = null
var my_box: SkinItemSlot = null
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


func setup(p_inventory: Object, pets: Array = []) -> void:
	inventory = p_inventory
	_build()
	set_my_pets(pets)


func _build() -> void:
	if _built:
		return
	_built = true
	background = SkinWindowKit.background(self, "form_trade_pet_1", WINDOW_SIZE)
	other_header = SkinWindowKit.label(self, "OtherHeader", OTHER_HEADER_RECT)
	my_header = SkinWindowKit.label(self, "MyHeader", MY_HEADER_RECT)
	other_pet_name = SkinWindowKit.label(self, "OtherPetName", OTHER_NAME_RECT)
	my_pet_name = SkinWindowKit.label(self, "MyPetName", MY_NAME_RECT)
	other_gold_label = SkinWindowKit.label(self, "OtherGoldLabel", OTHER_GOLD_RECT, "0", HORIZONTAL_ALIGNMENT_RIGHT)
	my_gold_edit = SkinWindowKit.gold_edit(self, "MyGoldEdit", MY_GOLD_RECT)
	for i in range(3):
		other_stats.append(SkinWindowKit.label(self, "OtherStat%d" % i, Rect2(OTHER_STATS_ORIGIN + Vector2(0, 17 * i), Vector2(100, 16))))
		my_stats.append(SkinWindowKit.label(self, "MyStat%d" % i, Rect2(MY_STATS_ORIGIN + Vector2(0, 17 * i), Vector2(100, 16))))
	for i in range(5):
		other_skill_slots.append(SkinWindowKit.slot(self, "OtherSkill%d" % i, Rect2(OTHER_SKILL_ORIGIN + Vector2(35 * i, 0), Vector2(33, 33)), i))
		my_skill_slots.append(SkinWindowKit.slot(self, "MySkill%d" % i, Rect2(MY_SKILL_ORIGIN + Vector2(35 * i, 0), Vector2(33, 33)), i))
	other_box = SkinWindowKit.slot(self, "OtherBox", OTHER_BOX_RECT, 0)
	my_box = SkinWindowKit.slot(self, "MyBox", MY_BOX_RECT, 0)
	btn_arrow_l = SkinWindowKit.button(self, "ArrowL", "btn_arrow_l_5", ARROW_L_RECT)
	btn_arrow_r = SkinWindowKit.button(self, "ArrowR", "btn_arrow_r_5", ARROW_R_RECT)
	btn_arrow_l.pressed.connect(func() -> void: select_my_pet(my_pet_index - 1))
	btn_arrow_r.pressed.connect(func() -> void: select_my_pet(my_pet_index + 1))
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

func open_trade(p_partner_name: String, p_inventory: Object = null, pets: Array = []) -> void:
	_build()
	if p_inventory:
		inventory = p_inventory
	_reset_state()
	partner_name = p_partner_name
	other_header.text = p_partner_name
	if not pets.is_empty():
		set_my_pets(pets)
	else:
		select_my_pet(my_pet_index if my_pet_index >= 0 else 0)
	is_open = true
	visible = true
	trade_opened.emit(p_partner_name)


func close_window() -> void:
	is_open = false
	visible = false
	window_closed.emit()


## pets: Array of {name, level, hp, max_hp, loyalty, skills: [item-like dicts with icon_id], item: {}}
func set_my_pets(pets: Array) -> void:
	my_pets.clear()
	for p in pets:
		if p is Dictionary:
			my_pets.append((p as Dictionary).duplicate(true))
	my_pet_index = -1
	select_my_pet(0)


func select_my_pet(index: int) -> void:
	if my_confirmed:
		return
	if my_pets.is_empty():
		my_pet_index = -1
		_show_pet({}, my_pet_name, my_stats, my_skill_slots, my_box)
		return
	my_pet_index = wrapi(index, 0, my_pets.size())
	var pet: Dictionary = my_pets[my_pet_index]
	_show_pet(pet, my_pet_name, my_stats, my_skill_slots, my_box)
	pet_selected.emit(pet)


func get_my_offer_pet() -> Dictionary:
	return my_pets[my_pet_index].duplicate(true) if my_pet_index >= 0 and my_pet_index < my_pets.size() else {}


func get_my_offer_gold() -> int:
	return SkinWindowKit.parse_gold(my_gold_edit.text)


func set_my_offer_gold(amount: int) -> void:
	if not my_confirmed:
		my_gold_edit.text = str(maxi(0, amount))


func set_partner_pet(pet: Dictionary, gold: int) -> void:
	_partner_pet = pet.duplicate(true)
	_partner_gold = maxi(0, gold)
	_show_pet(_partner_pet, other_pet_name, other_stats, other_skill_slots, other_box)
	other_gold_label.text = str(_partner_gold)


func get_partner_pet() -> Dictionary:
	return _partner_pet.duplicate(true)


func set_partner_confirmed(value: bool) -> void:
	partner_confirmed = value
	_update_buttons()


func confirm_offer() -> bool:
	if my_confirmed:
		return false
	var gold: int = get_my_offer_gold()
	if gold > SkinWindowKit.inv_gold(inventory):
		message.emit("Not enough Gold")
		return false
	var pet: Dictionary = get_my_offer_pet()
	if not pet.is_empty() and pet.has("tradeable") and not bool(pet["tradeable"]):
		message.emit("Non-tradeable")
		return false
	my_confirmed = true
	my_gold_edit.editable = false
	_update_buttons()
	offer_confirmed.emit(pet, gold)
	return true


func accept_trade() -> bool:
	if not (my_confirmed and partner_confirmed):
		return false
	btn_trade.visible = false
	trade_accepted.emit()
	return true


## Applies the exchange: my pet leaves my_pets, the partner's pet joins, gold is settled.
func complete_trade() -> bool:
	if not (my_confirmed and partner_confirmed):
		return false
	var given_gold: int = get_my_offer_gold()
	if given_gold > SkinWindowKit.inv_gold(inventory):
		message.emit("Not enough Gold")
		return false
	var given: Dictionary = get_my_offer_pet()
	if my_pet_index >= 0 and my_pet_index < my_pets.size():
		my_pets.remove_at(my_pet_index)
	var received: Dictionary = _partner_pet.duplicate(true)
	if not received.is_empty():
		my_pets.append(received)
	SkinWindowKit.inv_set_gold(inventory, SkinWindowKit.inv_gold(inventory) - given_gold + _partner_gold)
	var received_gold: int = _partner_gold
	message.emit("Trade complete")
	trade_completed.emit(received, received_gold, given, given_gold)
	_reset_state()
	close_window()
	return true


func cancel_trade() -> void:
	var was_open: bool = is_open
	_reset_state()
	if was_open:
		message.emit("Trade canceled")
		trade_canceled.emit()
	close_window()


# --- internals ----------------------------------------------------------------------------

func _reset_state() -> void:
	my_confirmed = false
	partner_confirmed = false
	_partner_pet = {}
	_partner_gold = 0
	if my_gold_edit:
		my_gold_edit.text = "0"
		my_gold_edit.editable = true
	if other_gold_label:
		other_gold_label.text = "0"
	if other_pet_name:
		_show_pet({}, other_pet_name, other_stats, other_skill_slots, other_box)
	_update_buttons()


func _update_buttons() -> void:
	if btn_confirm == null:
		return
	btn_confirm.visible = not my_confirmed
	btn_trade.visible = my_confirmed and partner_confirmed


func _show_pet(pet: Dictionary, name_label: Label, stats: Array[Label], skills: Array[SkinItemSlot], box: SkinItemSlot) -> void:
	name_label.text = str(pet.get("name", ""))
	if pet.is_empty():
		for l in stats:
			l.text = ""
	else:
		stats[0].text = str(int(pet.get("level", 1)))
		stats[1].text = "%d/%d" % [int(pet.get("hp", 0)), int(pet.get("max_hp", pet.get("hp", 0)))]
		stats[2].text = str(int(pet.get("loyalty", 0)))
	var skill_list: Array = pet.get("skills", [])
	for i in range(skills.size()):
		skills[i].set_item(skill_list[i] if i < skill_list.size() and skill_list[i] is Dictionary else {})
	box.set_item(pet.get("item", {}) if pet.get("item", {}) is Dictionary else {})
