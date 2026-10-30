class_name ItemMallWindow
extends Control

## Item Mall (top bar icon 711). Real client skin Form_Shopping_1 (778x554): a points box at the top left,
## the "目前點數" (current points) and "紅利點數" (bonus points) labels, a list box under them and a large
## product panel on the right. The mall catalog and point balances live on the server; this client has no
## data for them yet, so the lists stay empty and the balances read 0.

signal closed

const SKIN_PATH: String = "res://assets/ui/shop/form_shopping_1.png"
const TITLE_CURRENT: String = "目前點數"
const TITLE_BONUS: String = "紅利點數"

## Measured from the skin bitmap.
const POINTS_BOX: Rect2 = Rect2(16, 58, 191, 58)
const LIST_BOX: Rect2 = Rect2(20, 158, 183, 352)
const PRODUCT_PANEL: Rect2 = Rect2(224, 34, 537, 477)

var current_points: int = 0
var bonus_points: int = 0
var current_label: Label = null
var bonus_label: Label = null
var product_panel: Control = null
var list_panel: Control = null
var close_button: Button = null


func _ready() -> void:
	name = "ItemMallWindow"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(778, 554)
	size = custom_minimum_size
	visible = false
	_build()
	_refresh_points()


func _build() -> void:
	var skin := TextureRect.new()
	skin.name = "Skin"
	skin.texture = load(SKIN_PATH)
	skin.stretch_mode = TextureRect.STRETCH_KEEP
	skin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skin)

	var box := Control.new()
	box.name = "PointsBox"
	box.position = POINTS_BOX.position
	box.size = POINTS_BOX.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	current_label = _make_value_label(box, "CurrentPoints", Vector2(8, 8))
	bonus_label = _make_value_label(box, "BonusPoints", Vector2(8, 32))

	var titles := Label.new()
	titles.name = "Titles"
	titles.position = Vector2(16, 120)
	titles.text = "%s\n    %s" % [TITLE_CURRENT, TITLE_BONUS]
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(titles)

	list_panel = Control.new()
	list_panel.name = "ListBox"
	list_panel.position = LIST_BOX.position
	list_panel.size = LIST_BOX.size
	add_child(list_panel)

	product_panel = Control.new()
	product_panel.name = "ProductPanel"
	product_panel.position = PRODUCT_PANEL.position
	product_panel.size = PRODUCT_PANEL.size
	add_child(product_panel)

	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "Close"
	close_button.position = Vector2(680, 514)
	close_button.size = Vector2(70, 22)
	close_button.pressed.connect(close)
	add_child(close_button)


func _make_value_label(parent: Control, label_name: String, pos: Vector2) -> Label:
	var label := Label.new()
	label.name = label_name
	label.position = pos
	label.size = Vector2(175, 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


## Sets the two point balances shown in the points box.
func set_points(current: int, bonus: int) -> void:
	current_points = maxi(current, 0)
	bonus_points = maxi(bonus, 0)
	_refresh_points()


func _refresh_points() -> void:
	if current_label:
		current_label.text = "%s: %d" % [TITLE_CURRENT, current_points]
	if bonus_label:
		bonus_label.text = "%s: %d" % [TITLE_BONUS, bonus_points]


func open() -> void:
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	closed.emit()
