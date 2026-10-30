class_name TradePartnerStub
extends RefCounted

## Offline stand-in for the other trader (no server). Attach it to a TradeWindow or
## TradePetWindow: when the player confirms, the stub puts its offer up and confirms too; when
## the player presses Trade, it completes the exchange (what the server's action 0x19 reply does).

var partner_name: String = "Merchant"
var items: Array[Dictionary] = []
var gold: int = 0
var pet: Dictionary = {}
var auto_confirm: bool = true
var auto_complete: bool = true
var received_items: Array = []
var received_gold: int = 0
var received_pet: Dictionary = {}

var _window: Control = null


func _init(p_name: String = "Merchant", p_items: Array = [], p_gold: int = 0, p_pet: Dictionary = {}) -> void:
	partner_name = p_name
	for it in p_items:
		if it is Dictionary:
			items.append((it as Dictionary).duplicate(true))
	gold = p_gold
	pet = p_pet.duplicate(true)


func attach(window: Control) -> void:
	_window = window
	if window.has_signal("offer_confirmed"):
		window.offer_confirmed.connect(_on_player_confirmed)
	if window.has_signal("trade_accepted"):
		window.trade_accepted.connect(_on_player_accepted)


func _on_player_confirmed(a: Variant = null, b: Variant = null) -> void:
	if not auto_confirm or _window == null:
		return
	if _window.has_method("set_partner_offer"):
		_window.set_partner_offer(items, gold)
	elif _window.has_method("set_partner_pet"):
		_window.set_partner_pet(pet, gold)
	_window.set_partner_confirmed(true)


func _on_player_accepted() -> void:
	if not auto_complete or _window == null:
		return
	if _window.has_method("get_my_offer_items"):
		received_items = _window.get_my_offer_items()
	if _window.has_method("get_my_offer_pet"):
		received_pet = _window.get_my_offer_pet()
	received_gold = _window.get_my_offer_gold()
	_window.complete_trade()
