class_name GiftCardWindow
extends Control

## Gift Exchange Card selector (Go client: wlo/inventory/item_cards.go, TGiftExchangeCardForm, Form_GiftExchange_1).
## Layout (form-local): form at (176,153) 447x293; reward rows at x 25 (checkboxes) and y 90+34*i for 4 rows;
## item icon at (51, 81+34*i) and name at (92, 90+34*i); page label at (204,224); arrows (175,224)/(256,224);
## Close (240,250), Confirm (152,250), corner close (393,22).
## The server protocol (server internal/server/item_cards.go): the card is requested with AC23:133 mode 1; the
## reward list comes back as AC23:108 type 2; the client confirms with AC23:133 mode 2 (slot, 1, index, rewardId).

signal closed

const FORM_POS := Vector2(176, 153)
const FORM_SIZE := Vector2(447, 293)
const ROWS := 4
const ACTION := 23
const SUB_CARD := 108
const TYPE_INDEX := 1
const TYPE_DETAILS := 2
const TYPE_REDEEMED := 3
const TYPE_OPEN := 4
const CMD_GIFT := 133

var _slot: int = 0
var _item_id: int = 0
var _item_name: String = ""
var _rewards: Array = [] # each {item_id, quantity}
var _page := 0
var _selected := -1
var _waiting := false
var _send: Callable = Callable()
var _name_of: Callable = Callable()

var _rows: Array[Button] = []
var _confirm: Button
var _page_label: Label
var _title: Label


func _ready() -> void:
	position = FORM_POS
	size = FORM_SIZE
	custom_minimum_size = FORM_SIZE
	visible = false
	_build()


func _build() -> void:
	_title = Label.new()
	_title.position = Vector2(51, 54)
	_title.size = Vector2(350, 18)
	add_child(_title)
	for i in ROWS:
		var row := i
		var b := Button.new()
		b.name = "Check%d" % i
		b.position = Vector2(25, 90 + i * 34)
		b.size = Vector2(16, 16)
		b.pressed.connect(func() -> void: _select(_page * ROWS + row))
		add_child(b)
		_rows.append(b)
	_confirm = Button.new()
	_confirm.name = "Confirm"
	_confirm.text = "Confirm"
	_confirm.position = Vector2(152, 250)
	_confirm.size = Vector2(56, 20)
	_confirm.pressed.connect(_exchange)
	add_child(_confirm)
	var close_btn := Button.new()
	close_btn.name = "Close"
	close_btn.text = "Close"
	close_btn.position = Vector2(240, 250)
	close_btn.size = Vector2(56, 20)
	close_btn.pressed.connect(close)
	add_child(close_btn)
	var corner := Button.new()
	corner.name = "CornerClose"
	corner.position = Vector2(393, 22)
	corner.size = Vector2(18, 18)
	corner.pressed.connect(close)
	add_child(corner)
	var left := Button.new()
	left.name = "PrevPage"
	left.text = "<"
	left.position = Vector2(175, 224)
	left.size = Vector2(17, 17)
	left.pressed.connect(func() -> void: _change_page(-1))
	add_child(left)
	var right := Button.new()
	right.name = "NextPage"
	right.text = ">"
	right.position = Vector2(256, 224)
	right.size = Vector2(17, 17)
	right.pressed.connect(func() -> void: _change_page(1))
	add_child(right)
	_page_label = Label.new()
	_page_label.position = Vector2(204, 224)
	_page_label.size = Vector2(50, 17)
	add_child(_page_label)


## The sender is any Callable taking a PackedByteArray; the name lookup maps an item id to its name.
func configure(send: Callable, name_of: Callable) -> void:
	_send = send
	_name_of = name_of


## Asks the server for the card in `slot` (AC23:133 mode 1: slot, item id, zero).
func request_card(slot: int, item_id: int) -> void:
	_slot = slot
	_item_id = item_id
	_rewards = []
	_selected = -1
	_page = 0
	_waiting = false
	visible = false
	var p := PackedByteArray([ACTION, CMD_GIFT, 1, slot, item_id & 0xFF, (item_id >> 8) & 0xFF, 0])
	if _send.is_valid():
		_send.call(p)


## Handles a server packet (action, sub, payload). Returns true when the packet belonged to this window.
func handle_packet(action: int, sub: int, payload: PackedByteArray) -> bool:
	if action != ACTION or sub != SUB_CARD or payload.size() < 3:
		return false
	match payload[2]:
		TYPE_DETAILS:
			return _on_details(payload)
		TYPE_OPEN:
			if payload.size() == 4 and payload[3] == _slot and _rewards.size() > 0:
				open()
			return true
		TYPE_REDEEMED:
			close()
			return true
		TYPE_INDEX:
			return true
	return false


func _on_details(payload: PackedByteArray) -> bool:
	if payload.size() < 5:
		return false
	var count := payload[3] | (payload[4] << 8)
	var offset := 5
	var rewards: Array = []
	for _i in count:
		if offset + 4 > payload.size():
			return false
		var card_id := payload[offset] | (payload[offset + 1] << 8)
		var n := payload[offset + 3]
		offset += 4
		var parsed: Array = []
		for _j in n:
			if offset + 3 > payload.size():
				return false
			parsed.append({"item_id": payload[offset] | (payload[offset + 1] << 8), "quantity": payload[offset + 2]})
			offset += 3
		if card_id == _item_id:
			rewards = parsed
	if rewards.is_empty() or _slot == 0:
		return true
	_rewards = rewards
	_page = 0
	_selected = -1
	_refresh()
	open()
	return true


func _select(index: int) -> void:
	if _waiting or index < 0 or index >= _rewards.size():
		return
	_selected = index
	_refresh()


func _change_page(delta: int) -> void:
	var pages := maxi(1, int(ceil(float(_rewards.size()) / ROWS)))
	var next := clampi(_page + delta, 0, pages - 1)
	if next != _page:
		_page = next
		_refresh()


func _exchange() -> void:
	if _waiting or _selected < 0 or _selected >= _rewards.size():
		return
	var reward: Dictionary = _rewards[_selected]
	var rid: int = int(reward.item_id)
	_waiting = true
	var p := PackedByteArray([ACTION, CMD_GIFT, 2, _slot, 1, _selected + 1, rid & 0xFF, (rid >> 8) & 0xFF])
	if _send.is_valid():
		_send.call(p)
	_refresh()


func _refresh() -> void:
	_title.text = _name_of.call(_item_id) if _name_of.is_valid() else str(_item_id)
	for i in ROWS:
		var index := _page * ROWS + i
		_rows[i].visible = index < _rewards.size()
		_rows[i].disabled = _waiting
		_rows[i].text = "*" if index == _selected else ""
	_confirm.disabled = _selected < 0 or _waiting
	var pages := maxi(1, int(ceil(float(_rewards.size()) / ROWS)))
	_page_label.text = "%d/%d" % [_page + 1, pages]


func open() -> void:
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	_waiting = false
	closed.emit()
