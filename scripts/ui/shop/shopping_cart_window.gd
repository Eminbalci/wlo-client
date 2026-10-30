class_name ShoppingCartWindow
extends RefCounted

## Shopping cart (real client: Form_ShoppingCar_1). Seven rows (name, effect, price, amount), a total,
## and Continue / Checkout / Leave. Row layout is measured from the skin.

const SKIN_PATH := "res://assets/ui/shop/form_shoppingcar_1.png"
const ROW_COUNT := 7


## Builds the cart panel into parent and returns its parts.
static func build(parent: Control) -> Dictionary:
	var root := TextureRect.new()
	root.name = "CartPanel"
	if ResourceLoader.exists(SKIN_PATH):
		root.texture = load(SKIN_PATH)
	root.stretch_mode = TextureRect.STRETCH_KEEP
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(root)

	var rows := build_cart_rows(root)

	var total := Label.new()
	total.name = "Total"
	total.text = "0"
	total.position = Vector2(430.0, 468.0)
	total.size = Vector2(70.0, 20.0)
	root.add_child(total)

	var btn_size := Vector2(70.0, 22.0)
	var continue_btn := _make_button(root, "Continue", Vector2(80.0, 495.0), btn_size)
	var checkout_btn := _make_button(root, "Checkout", Vector2(240.0, 495.0), btn_size)
	var leave_btn := _make_button(root, "Leave", Vector2(400.0, 495.0), btn_size)

	return {
		"root": root,
		"rows": rows,
		"total": total,
		"continue": continue_btn,
		"checkout": checkout_btn,
		"leave": leave_btn
	}


static func _make_button(parent: Control, text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.name = text
	b.text = text
	b.position = pos
	b.size = size
	b.custom_minimum_size = size
	parent.add_child(b)
	return b


## Seven cart rows at 40 + 59*i, 548x58 (measured from Form_ShoppingCar_1).
static func build_cart_rows(parent: Control) -> Array:
	if not parent:
		return []

	var rows: Array = []
	const ROW_Y_START: float = 40.0
	const ROW_Y_STEP: float = 59.0
	const ROW_WIDTH: float = 548.0
	const ROW_HEIGHT: float = 58.0

	for i in range(ROW_COUNT):
		var row := Control.new()
		row.name = "CartRow_%d" % i
		row.position = Vector2(0.0, ROW_Y_START + ROW_Y_STEP * float(i))
		row.size = Vector2(ROW_WIDTH, ROW_HEIGHT)
		row.custom_minimum_size = Vector2(ROW_WIDTH, ROW_HEIGHT)
		parent.add_child(row)

		var lbl_ad := Label.new()
		lbl_ad.name = "Ad"
		lbl_ad.position = Vector2(56.0, 0.0)
		lbl_ad.size = Vector2(70.0, ROW_HEIGHT)
		lbl_ad.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_ad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(lbl_ad)

		var lbl_etki := Label.new()
		lbl_etki.name = "Etki"
		lbl_etki.position = Vector2(132.0, 0.0)
		lbl_etki.size = Vector2(174.0, ROW_HEIGHT)
		lbl_etki.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_etki.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(lbl_etki)

		var lbl_fiyat := Label.new()
		lbl_fiyat.name = "Fiyat"
		lbl_fiyat.position = Vector2(314.0, 0.0)
		lbl_fiyat.size = Vector2(56.0, ROW_HEIGHT)
		lbl_fiyat.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_fiyat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(lbl_fiyat)

		var sb_miktar := SpinBox.new()
		sb_miktar.name = "Miktar"
		sb_miktar.min_value = 0.0
		sb_miktar.max_value = 999.0
		sb_miktar.step = 1.0
		sb_miktar.value = 1.0
		sb_miktar.position = Vector2(376.0, (ROW_HEIGHT - 31.0) / 2.0)
		sb_miktar.size = Vector2(60.0, 31.0)
		sb_miktar.custom_minimum_size = Vector2(60.0, 0.0)
		row.add_child(sb_miktar)

		rows.append(row)

	return rows
