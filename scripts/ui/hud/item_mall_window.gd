class_name ItemMallWindow
extends Control

## Item Mall (top bar icon 711). Layout and text measured from the live client (docs/reference/real_client/item_mall_real.png):
## the Form_Shopping_1 frame (778x554), Points Mall / Bonus Mall tabs, the current and bonus IM points, a character card,
## seven category tabs, ten product rows (name, description, POINTS price, On Sale price, Add to Cart) and a bottom bar
## (Previous, page, Next, Security Lock, Shop Cart, Check Out, Exit). The product catalog and point balances come from
## the server; this client has no data for them yet, so the rows stay empty and the balances read 0.

signal closed

const SKIN_PATH: String = "res://assets/ui/shop/form_shopping_1.png"
const CATEGORIES: Array[String] = ["Hot", "Armory", "Weaponry", "Grocery", "Furniture", "Slot Machine", "Fishing"]
const ROW_COUNT: int = 10

## Measured in window coordinates (screenshot minus the window's top-left corner).
const CATEGORY_X: Array[float] = [235.0, 335.0, 395.0, 475.0, 550.0, 625.0, 690.0]
const ROW_Y_START: float = 46.0
const ROW_Y_STEP: float = 40.0
const BOTTOM_Y: float = 530.0

var current_points: int = 0
var bonus_points: int = 0
var current_label: Label = null
var bonus_label: Label = null
var page_label: Label = null
var product_rows: Array[Dictionary] = [] # {"name": Label, "desc": Label, "price": Label, "sale": Label, "cart": Button}
var close_button: Button = null


func _ready() -> void:
	name = "ItemMallWindow"
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(778, 554)
	size = custom_minimum_size
	# The real client draws the mall below the top icon row (window top at y 50 in item_mall_real.png).
	position = Vector2(15, 50)
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

	_add_text("PointsMallTab", Vector2(24, 36), "Points Mall")
	_add_text("BonusMallTab", Vector2(118, 36), "Bonus Mall")
	_add_text("PointsMallTitle", Vector2(52, 86), "POINTS MALL")
	current_label = _add_text("CurrentPoints", Vector2(24, 128), "")
	bonus_label = _add_text("BonusPoints", Vector2(56, 146), "")

	for i in range(CATEGORIES.size()):
		var tab := Button.new()
		tab.name = "Category_%d" % i
		tab.text = CATEGORIES[i]
		tab.flat = true
		tab.position = Vector2(CATEGORY_X[i], 12)
		tab.size = Vector2(90, 20)
		add_child(tab)

	for i in range(ROW_COUNT):
		product_rows.append(_build_product_row(i))

	var bottom := [
		["Previous", 225.0, 60.0],
		["Next", 357.0, 60.0],
		["SecurityLock", 422.0, 75.0],
		["ShopCart", 502.0, 70.0],
		["CheckOut", 590.0, 70.0],
	]
	for entry in bottom:
		var b := Button.new()
		b.name = entry[0]
		b.text = entry[0]
		b.position = Vector2(entry[1], BOTTOM_Y)
		b.size = Vector2(entry[2], 22)
		add_child(b)

	page_label = _add_text("Page", Vector2(305, BOTTOM_Y + 4), "1 / 1")

	close_button = Button.new()
	close_button.name = "Exit"
	close_button.text = "Exit"
	close_button.position = Vector2(680, BOTTOM_Y)
	close_button.size = Vector2(70, 22)
	close_button.pressed.connect(close)
	add_child(close_button)


func _build_product_row(index: int) -> Dictionary:
	var y: float = ROW_Y_START + ROW_Y_STEP * float(index)
	var name_label := _add_text("RowName_%d" % index, Vector2(277, y), "")
	var desc_label := _add_text("RowDesc_%d" % index, Vector2(380, y), "")
	var price_label := _add_text("RowPrice_%d" % index, Vector2(610, y), "")
	var sale_label := _add_text("RowSale_%d" % index, Vector2(705, y), "")
	var cart := Button.new()
	cart.name = "RowCart_%d" % index
	cart.text = "Add to Cart"
	cart.disabled = true
	cart.position = Vector2(688, y - 2)
	cart.size = Vector2(75, 24)
	add_child(cart)
	return {"name": name_label, "desc": desc_label, "price": price_label, "sale": sale_label, "cart": cart}


func _add_text(node_name: String, pos: Vector2, text: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.position = pos
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


## Sets the two point balances shown under the Points Mall title.
func set_points(current: int, bonus: int) -> void:
	current_points = maxi(current, 0)
	bonus_points = maxi(bonus, 0)
	_refresh_points()


func _refresh_points() -> void:
	if current_label:
		current_label.text = "Current IM Points %d" % current_points
	if bonus_label:
		bonus_label.text = "Bonus Points %d" % bonus_points


func open() -> void:
	visible = true
	move_to_front()


func close() -> void:
	visible = false
	closed.emit()
