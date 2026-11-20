class_name BusinessWindow
extends Control

## Toolbar Trade menu (Go client: hud/business.go, Form_Business_1). Shows the player's gold and the
## trade and stall buttons. Only Trade Items is wired; the pet, furniture and stall buttons stay
## disabled, as the Go port leaves them, because the forms they open are not ported yet.
## Form-local layout (Go constants): size 260x217, gold text at (70,70), Trade Items (21,96),
## Trade Pets (94,96), Trade Furniture (167,96), Stall Items (21,124), Stall Pets (94,124),
## Stall Furniture (167,124), Abandon (174,68), Close (102,182), corner close (209,24).

signal trade_items_requested
signal closed

const FORM_SIZE := Vector2(260, 217)
const GOLD_POS := Vector2(70, 70)
const DEFAULT_POS := Vector2(0, 180)
const SkinWindowKitScript := preload("res://scripts/ui/common/skin_window_kit.gd")
const INK := Color("#2b2b2b")

var gold_provider: Callable = Callable()
var _gold_label: Label
var _trade_items: TextureButton
var _close: TextureButton


func _ready() -> void:
	size = FORM_SIZE
	custom_minimum_size = FORM_SIZE
	position = DEFAULT_POS
	visible = false
	_build()
	refresh()


func _build() -> void:
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = SkinWindowKitScript.tex("res://assets/menu/Skins/white/Form_Business_1.bmp")
	bg.stretch_mode = TextureRect.STRETCH_KEEP
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_gold_label = Label.new()
	_gold_label.name = "Gold"
	_gold_label.position = GOLD_POS
	_gold_label.size = Vector2(120, 12)
	_gold_label.add_theme_color_override("font_color", INK)
	add_child(_gold_label)

	_trade_items = _button("TradeItems", "res://assets/menu/Skins/default/Btn_TradeThing_1.bmp", Rect2(21, 96, 71, 20))
	_trade_items.pressed.connect(func() -> void: trade_items_requested.emit())

	for entry in [["TradePets", "res://assets/menu/Skins/default/Btn_TradePet_1.bmp", Rect2(94, 96, 71, 20)],
			["TradeFurniture", "res://assets/menu/Skins/default/Btn_TradeUtensil_1.bmp", Rect2(167, 96, 71, 20)],
			["StallItems", "res://assets/menu/Skins/default/Btn_StallThing_1.bmp", Rect2(21, 124, 71, 20)],
			["StallPets", "res://assets/menu/Skins/default/Btn_StallPet_1.bmp", Rect2(94, 124, 71, 20)],
			["StallFurniture", "res://assets/menu/Skins/default/Btn_StallUtensil_1.bmp", Rect2(167, 124, 71, 20)],
			["Abandon", "res://assets/menu/Skins/default/Btn_Abandon_1.bmp", Rect2(174, 68, 56, 20)]]:
		var b := _button(entry[0], entry[1], entry[2])
		b.disabled = true

	_close = _button("Close", "res://assets/menu/Skins/default/btn_close_1.bmp", Rect2(102, 182, 56, 20))
	_close.pressed.connect(close)
	var corner := _button("CornerClose", "res://assets/menu/Skins/default/btn_close_s_1.bmp", Rect2(209, 24, 18, 18))
	corner.pressed.connect(close)


## Single-picture button from a bmp path (the Go menu buttons are one bitmap each).
func _button(node_name: String, path: String, rect: Rect2) -> TextureButton:
	var b := TextureButton.new()
	b.name = node_name
	b.position = rect.position
	b.size = rect.size
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.texture_normal = SkinWindowKitScript.tex(path)
	add_child(b)
	return b


func configure(gold: Callable) -> void:
	gold_provider = gold
	refresh()


func refresh() -> void:
	if _gold_label == null:
		return
	var gold := int(gold_provider.call()) if gold_provider.is_valid() else 0
	_gold_label.text = str(maxi(gold, 0))


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	refresh()
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	closed.emit()
