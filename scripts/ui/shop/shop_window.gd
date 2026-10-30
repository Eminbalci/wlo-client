class_name ShopWindow
extends Control

## Authentic Wonderland Online NPC Merchant Shop Window (Buy & Sell).
## High-fidelity implementation based on authentic Form_ThingStore_1 / Form_WeaponStore_1 (409x525).
## Strictly conforms to original 2000s classic MMORPG visual assets and typography:
## - Background: Authentic sliced store form texture (form_store_1.png)
## - Close Button: Authentic 18x18 3-state texture button at (379, 8)
## - Tabs: Authentic sliced ShopTab 3-state texture buttons for "Buy" and "Sell"
## - 5 Pre-drawn authentic store slot rows with item icons, names, descriptions, and gold prices
## - Scroll / page navigation (5 items per page / smooth scroll)
## - Selected item preview card with authentic typography (11/12px, 2px black outline)
## - Quantity SpinBox (1..99 for buy, 1..stack for sell) and dynamic total cost calculation
## - "Buy" button (btn_buy_1) and "Sell" button (btn_trade_1) with authentic audio
## - Dynamic player gold display synced with HUDInventory and CharacterManager
## - Window title bar dragging with screen bounds clamping

signal item_bought(item_id: int, count: int, total_price: int)
signal item_sold(item_id: int, count: int, total_price: int)
signal mode_changed(new_mode: String)
signal window_closed
signal shop_opened(merchant_id: int, merchant_name: String)

const FORM_WIDTH: float = 409.0
const FORM_HEIGHT: float = 525.0
const SLOTS_PER_PAGE: int = 5

const TEX_BG_DEFAULT: String = "res://assets/hud/form_store_1.png"
const TEX_BG_WEAPON: String = "res://assets/hud/form_weapon_store_1.png"
const TEX_BG_PHARMACY: String = "res://assets/hud/form_pharmacy_store.png"

## Store kinds of the real client's store form (aLogin.exe 0x383a48, docs/re/equip_store_window.md):
## the same form swaps its skin by a mode byte: 1 = Form_EquipStore_1, 2 = Form_ThingStore_1,
## 3 = Form_ActivityExchange (Btn_Exchange_1 replaces Btn_Buy_1 at (136,489)). Layout is shared.
enum StoreKind { DEFAULT = 0, EQUIP = 1, THING = 2, ACTIVITY_EXCHANGE = 3 }
const STORE_KIND_SKINS: Dictionary = {
	StoreKind.DEFAULT: "res://assets/hud/form_store_1.png",
	StoreKind.EQUIP: "res://assets/hud/form_equip_store_1.png",
	StoreKind.THING: "res://assets/hud/form_thing_store_1.png",
	StoreKind.ACTIVITY_EXCHANGE: "res://assets/hud/form_activity_exchange.png",
}
var store_kind: int = StoreKind.DEFAULT


## Switches the window skin to one of the real store variants (EquipStore / ThingStore / ...).
## Returns false when the skin is not available (the current skin is kept).
func set_store_kind(kind: int) -> bool:
	var path: String = str(STORE_KIND_SKINS.get(kind, ""))
	if path.is_empty():
		return false
	var tex: Texture2D = SkinWindowKit.tex(path)
	if tex == null:
		return false
	store_kind = kind
	if background_rect == null:
		background_rect = get_node_or_null("Background") as TextureRect
	if background_rect:
		background_rect.texture = tex
	return true

const TEX_CLOSE_NORMAL: String = "res://assets/hud/btn_close_normal.png"
const TEX_CLOSE_HOVER: String = "res://assets/hud/btn_close_hover.png"
const TEX_CLOSE_PRESSED: String = "res://assets/hud/btn_close_pressed.png"

const TEX_TAB_BUY_NORMAL: String = "res://assets/hud/btn_buy_1_normal.png"
const TEX_TAB_BUY_HOVER: String = "res://assets/hud/btn_buy_1_hover.png"
const TEX_TAB_BUY_PRESSED: String = "res://assets/hud/btn_buy_1_pressed.png"

const TEX_TAB_SELL_NORMAL: String = "res://assets/hud/btn_trade_1_normal.png"
const TEX_TAB_SELL_HOVER: String = "res://assets/hud/btn_trade_1_hover.png"
const TEX_TAB_SELL_PRESSED: String = "res://assets/hud/btn_trade_1_pressed.png"

const TEX_BUY_NORMAL: String = "res://assets/hud/btn_buy_1_normal.png"
const TEX_BUY_HOVER: String = "res://assets/hud/btn_buy_1_hover.png"
const TEX_BUY_PRESSED: String = "res://assets/hud/btn_buy_1_pressed.png"

const TEX_TRADE_NORMAL: String = "res://assets/hud/btn_trade_1_normal.png"
const TEX_TRADE_HOVER: String = "res://assets/hud/btn_trade_1_hover.png"
const TEX_TRADE_PRESSED: String = "res://assets/hud/btn_trade_1_pressed.png"

const TEX_ARROW_UP_NORMAL: String = "res://assets/hud/btn_arrow_up_normal.png"
const TEX_ARROW_UP_HOVER: String = "res://assets/hud/btn_arrow_up_hover.png"
const TEX_ARROW_UP_PRESSED: String = "res://assets/hud/btn_arrow_up_pressed.png"

const TEX_ARROW_DN_NORMAL: String = "res://assets/hud/btn_arrow_dn_normal.png"
const TEX_ARROW_DN_HOVER: String = "res://assets/hud/btn_arrow_dn_hover.png"
const TEX_ARROW_DN_PRESSED: String = "res://assets/hud/btn_arrow_dn_pressed.png"

const SFX_COIN_PATH: String = "res://assets/sound/wav9911.wav"
const SFX_ERROR_PATH: String = "res://assets/sound/SEB0024.WAV"
const SFX_CLICK_PATH: String = "res://assets/sound/wav0151.wav"

# State
var current_mode: String = "buy" # "buy" or "sell"
var merchant_id: int = 0
var merchant_name: String = "Grocery Store"
var merchant_catalog: Array[Dictionary] = []
var selected_item: Dictionary = {}
var selected_index: int = -1
var _quantity: int = 1
var quantity: int:
	get:
		return _quantity
	set(val):
		_quantity = maxi(1, val)
		if qty_spinbox and int(qty_spinbox.value) != _quantity:
			qty_spinbox.value = _quantity
		if total_cost_label:
			_refresh_preview()
var player_gold: int = 500
var current_page: int = 0

# UI Node References
var background_rect: TextureRect = null
var title_label: Label = null
var btn_close: TextureButton = null
var btn_tab_buy: TextureButton = null
var btn_tab_buy_label: Label = null
var btn_tab_sell: TextureButton = null
var btn_tab_sell_label: Label = null

# Page navigation buttons
var btn_page_up: TextureButton = null
var btn_page_dn: TextureButton = null
var page_indicator_label: Label = null

# 5 Slot Row Containers
var slot_rows: Array[Control] = []
var empty_label: Label = null

# Preview Nodes
var preview_icon: TextureRect = null
var preview_name: Label = null
var preview_desc: Label = null
var preview_unit_price: Label = null
var qty_spinbox: SpinBox = null
var total_cost_label: Label = null
var btn_action: TextureButton = null
var btn_action_label: Label = null

# Bottom Gold
var gold_display_label: Label = null

# Dragging support
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

# HUD Reference
var _hud: Control = null
var _sfx_player: AudioStreamPlayer = null

func _init() -> void:
	custom_minimum_size = Vector2(FORM_WIDTH, FORM_HEIGHT)
	size = Vector2(FORM_WIDTH, FORM_HEIGHT)
	_setup_ui_layout()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if slot_rows.size() < SLOTS_PER_PAGE:
		_setup_ui_layout()
	_setup_audio()
	if merchant_catalog.is_empty():
		merchant_catalog = get_default_catalog(merchant_id, merchant_name)
	refresh_gold()
	set_mode("buy")

func setup(hud: Control) -> void:
	_hud = hud
	if slot_rows.size() < SLOTS_PER_PAGE or not btn_action:
		_setup_ui_layout()
	_setup_audio()
	refresh_gold()

func _setup_audio() -> void:
	if not _sfx_player:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.name = "ShopAudioPlayer"
		var sfx_bus: StringName = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"
		_sfx_player.bus = sfx_bus
		add_child(_sfx_player)

func _setup_ui_layout() -> void:
	# 1. Authentic Window Background
	if not background_rect:
		background_rect = get_node_or_null("Background") as TextureRect
	if not background_rect:
		background_rect = TextureRect.new()
		background_rect.name = "Background"
		add_child(background_rect)
	
	background_rect.position = Vector2.ZERO
	background_rect.size = Vector2(FORM_WIDTH, FORM_HEIGHT)
	background_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	if ResourceLoader.exists(TEX_BG_DEFAULT):
		background_rect.texture = load(TEX_BG_DEFAULT)

	# 2. Authentic Title Bar Label
	if not title_label:
		title_label = get_node_or_null("TitleLabel") as Label
	if not title_label:
		title_label = Label.new()
		title_label.name = "TitleLabel"
		add_child(title_label)
	title_label.position = Vector2(24.0, 8.0)
	title_label.size = Vector2(280.0, 20.0)
	title_label.text = merchant_name
	_apply_wlo_typography(title_label, 12, Color(1.0, 0.88, 0.4, 1.0), 2)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.visible = false # the skin bakes its own heading; merchant_name stays available as data
	background_rect.tooltip_text = merchant_name

	# 3. 18x18 Authentic Close Button
	if not btn_close:
		btn_close = get_node_or_null("CloseButton") as TextureButton
	if not btn_close:
		btn_close = TextureButton.new()
		btn_close.name = "CloseButton"
		add_child(btn_close)
	WindowCloseButton.apply(btn_close, FORM_WIDTH) # sits on the baked x sphere
	if not btn_close.pressed.is_connected(close_shop):
		btn_close.pressed.connect(close_shop)

	# 4. Mode Tabs: Buy & Sell with Authentic ShopTab Textures
	btn_tab_buy = get_node_or_null("BtnTabBuy") as TextureButton
	if not btn_tab_buy:
		btn_tab_buy = TextureButton.new()
		btn_tab_buy.name = "BtnTabBuy"
		btn_tab_buy.position = Vector2(24.0, 36.0)
		btn_tab_buy.size = Vector2(56.0, 20.0)
		btn_tab_buy.custom_minimum_size = Vector2(56.0, 20.0)
		btn_tab_buy.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(btn_tab_buy)
	if ResourceLoader.exists(TEX_TAB_BUY_NORMAL):
		btn_tab_buy.texture_normal = load(TEX_TAB_BUY_NORMAL)
	if ResourceLoader.exists(TEX_TAB_BUY_HOVER):
		btn_tab_buy.texture_hover = load(TEX_TAB_BUY_HOVER)
	if ResourceLoader.exists(TEX_TAB_BUY_PRESSED):
		btn_tab_buy.texture_pressed = load(TEX_TAB_BUY_PRESSED)

	btn_tab_buy_label = btn_tab_buy.get_node_or_null("Label") as Label
	if not btn_tab_buy_label:
		btn_tab_buy_label = Label.new()
		btn_tab_buy_label.name = "Label"
		btn_tab_buy_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_tab_buy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_tab_buy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_tab_buy_label.text = "Buy"
		_apply_wlo_typography(btn_tab_buy_label, 11, Color(1.0, 1.0, 1.0, 1.0), 2)
		btn_tab_buy.add_child(btn_tab_buy_label)

	if not btn_tab_buy.pressed.is_connected(set_mode.bind("buy")):
		btn_tab_buy.pressed.connect(set_mode.bind("buy"))

	btn_tab_sell = get_node_or_null("BtnTabSell") as TextureButton
	if not btn_tab_sell:
		btn_tab_sell = TextureButton.new()
		btn_tab_sell.name = "BtnTabSell"
		btn_tab_sell.position = Vector2(82.0, 36.0)
		btn_tab_sell.size = Vector2(56.0, 20.0)
		btn_tab_sell.custom_minimum_size = Vector2(56.0, 20.0)
		btn_tab_sell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(btn_tab_sell)
	if ResourceLoader.exists(TEX_TAB_SELL_NORMAL):
		btn_tab_sell.texture_normal = load(TEX_TAB_SELL_NORMAL)
	if ResourceLoader.exists(TEX_TAB_SELL_HOVER):
		btn_tab_sell.texture_hover = load(TEX_TAB_SELL_HOVER)
	if ResourceLoader.exists(TEX_TAB_SELL_PRESSED):
		btn_tab_sell.texture_pressed = load(TEX_TAB_SELL_PRESSED)

	btn_tab_sell_label = btn_tab_sell.get_node_or_null("Label") as Label
	if not btn_tab_sell_label:
		btn_tab_sell_label = Label.new()
		btn_tab_sell_label.name = "Label"
		btn_tab_sell_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_tab_sell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_tab_sell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_tab_sell_label.text = "Sell"
		_apply_wlo_typography(btn_tab_sell_label, 11, Color(1.0, 1.0, 1.0, 1.0), 2)
		btn_tab_sell.add_child(btn_tab_sell_label)

	if not btn_tab_sell.pressed.is_connected(set_mode.bind("sell")):
		btn_tab_sell.pressed.connect(set_mode.bind("sell"))

	# 5. Page Up / Down Buttons (X = 388)
	btn_page_up = get_node_or_null("BtnPageUp") as TextureButton
	if not btn_page_up:
		btn_page_up = TextureButton.new()
		btn_page_up.name = "BtnPageUp"
		btn_page_up.position = Vector2(300.0, 380.0)
		btn_page_up.size = Vector2(16.0, 16.0)
		btn_page_up.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(btn_page_up)
	if ResourceLoader.exists(TEX_ARROW_UP_NORMAL):
		btn_page_up.texture_normal = load(TEX_ARROW_UP_NORMAL)
	if ResourceLoader.exists(TEX_ARROW_UP_HOVER):
		btn_page_up.texture_hover = load(TEX_ARROW_UP_HOVER)
	if ResourceLoader.exists(TEX_ARROW_UP_PRESSED):
		btn_page_up.texture_pressed = load(TEX_ARROW_UP_PRESSED)
	if not btn_page_up.pressed.is_connected(_on_page_prev):
		btn_page_up.pressed.connect(_on_page_prev)

	btn_page_dn = get_node_or_null("BtnPageDn") as TextureButton
	if not btn_page_dn:
		btn_page_dn = TextureButton.new()
		btn_page_dn.name = "BtnPageDn"
		btn_page_dn.position = Vector2(358.0, 380.0)
		btn_page_dn.size = Vector2(16.0, 16.0)
		btn_page_dn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(btn_page_dn)
	if ResourceLoader.exists(TEX_ARROW_DN_NORMAL):
		btn_page_dn.texture_normal = load(TEX_ARROW_DN_NORMAL)
	if ResourceLoader.exists(TEX_ARROW_DN_HOVER):
		btn_page_dn.texture_hover = load(TEX_ARROW_DN_HOVER)
	if ResourceLoader.exists(TEX_ARROW_DN_PRESSED):
		btn_page_dn.texture_pressed = load(TEX_ARROW_DN_PRESSED)
	if not btn_page_dn.pressed.is_connected(_on_page_next):
		btn_page_dn.pressed.connect(_on_page_next)

	page_indicator_label = get_node_or_null("PageIndicator") as Label
	if not page_indicator_label:
		page_indicator_label = Label.new()
		page_indicator_label.name = "PageIndicator"
		page_indicator_label.position = Vector2(318.0, 380.0)
		page_indicator_label.size = Vector2(38.0, 16.0)
		page_indicator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page_indicator_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_wlo_typography(page_indicator_label, 10, Color(0.16, 0.22, 0.40, 1.0), 0)
		add_child(page_indicator_label)

	# 6. Five rows aligned with the baked grid (cell x: icon 25, name 60, effects 135, price 318; pitch 59)
	slot_rows.clear()
	var row_y_coords := [79.0, 138.0, 197.0, 256.0, 315.0]
	for i in range(SLOTS_PER_PAGE):
		var row_name := "SlotRow_%d" % i
		var row := get_node_or_null(row_name) as Control
		if not row:
			row = Control.new()
			row.name = row_name
			add_child(row)
		row.position = Vector2(25.0, row_y_coords[i])
		row.size = Vector2(356.0, 57.0)
		row.mouse_filter = Control.MOUSE_FILTER_PASS

		# Selection Highlight Bezel (subtle gold outline, visible only when selected)
		var sel_bezel := row.get_node_or_null("SelBezel") as Panel
		if not sel_bezel:
			sel_bezel = Panel.new()
			sel_bezel.name = "SelBezel"
			sel_bezel.set_anchors_preset(Control.PRESET_FULL_RECT)
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(1.0, 0.85, 0.3, 0.18)
			sb.border_color = Color(1.0, 0.85, 0.3, 0.95)
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(2)
			sel_bezel.add_theme_stylebox_override("panel", sb)
			sel_bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sel_bezel.visible = false
			row.add_child(sel_bezel)

		# Icon
		var icon_rect := row.get_node_or_null("IconRect") as TextureRect
		if not icon_rect:
			icon_rect = TextureRect.new()
			icon_rect.name = "IconRect"
			icon_rect.position = Vector2(1.0, 12.0)
			icon_rect.size = Vector2(32.0, 32.0)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon_rect)

		# Name Label
		var name_lbl := row.get_node_or_null("NameLabel") as Label
		if not name_lbl:
			name_lbl = Label.new()
			name_lbl.name = "NameLabel"
			name_lbl.position = Vector2(36.0, 3.0)
			name_lbl.size = Vector2(70.0, 51.0)
			name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			name_lbl.clip_text = true
			_apply_wlo_typography(name_lbl, 10, Color(0.16, 0.22, 0.40, 1.0), 0)
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(name_lbl)

		# Detail Label
		var desc_lbl := row.get_node_or_null("DescLabel") as Label
		if not desc_lbl:
			desc_lbl = Label.new()
			desc_lbl.name = "DescLabel"
			desc_lbl.position = Vector2(112.0, 3.0)
			desc_lbl.size = Vector2(176.0, 51.0)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			desc_lbl.clip_text = true
			_apply_wlo_typography(desc_lbl, 9, Color(0.16, 0.22, 0.40, 1.0), 0)
			desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(desc_lbl)

		# Price Label
		var price_lbl := row.get_node_or_null("PriceLabel") as Label
		if not price_lbl:
			price_lbl = Label.new()
			price_lbl.name = "PriceLabel"
			price_lbl.position = Vector2(293.0, 18.0)
			price_lbl.size = Vector2(62.0, 20.0)
			price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			price_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_apply_wlo_typography(price_lbl, 11, Color(0.50, 0.32, 0.04, 1.0), 0)
			price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(price_lbl)

		# Click input detector
		if not row.gui_input.is_connected(_on_slot_gui_input.bind(i)):
			row.gui_input.connect(_on_slot_gui_input.bind(i))

		slot_rows.append(row)

	empty_label = get_node_or_null("EmptyLabel") as Label
	if not empty_label:
		empty_label = Label.new()
		empty_label.name = "EmptyLabel"
		empty_label.position = Vector2(30.0, 205.0)
		empty_label.size = Vector2(350.0, 30.0)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.text = "No items available."
		_apply_wlo_typography(empty_label, 12, Color(0.42, 0.48, 0.64, 1.0), 0)
		empty_label.visible = false
		add_child(empty_label)

	# 7. Selected Item Preview Area (Y = 374 to 434)
	preview_icon = get_node_or_null("PreviewIcon") as TextureRect
	if not preview_icon:
		preview_icon = TextureRect.new()
		preview_icon.name = "PreviewIcon"
		preview_icon.position = Vector2(33.0, 402.0)
		preview_icon.size = Vector2(32.0, 32.0)
		preview_icon.custom_minimum_size = Vector2(32.0, 32.0)
		preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(preview_icon)

	preview_name = get_node_or_null("PreviewName") as Label
	if not preview_name:
		preview_name = Label.new()
		preview_name.name = "PreviewName"
		preview_name.position = Vector2(32.0, 380.0)
		preview_name.size = Vector2(124.0, 16.0)
		preview_name.clip_text = true
		preview_name.text = "Select an item"
		_apply_wlo_typography(preview_name, 11, Color(0.16, 0.22, 0.40, 1.0), 0)
		add_child(preview_name)

	preview_unit_price = get_node_or_null("PreviewUnitPrice") as Label
	if not preview_unit_price:
		preview_unit_price = Label.new()
		preview_unit_price.name = "PreviewUnitPrice"
		preview_unit_price.position = Vector2(246.0, 380.0)
		preview_unit_price.size = Vector2(52.0, 16.0)
		preview_unit_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_wlo_typography(preview_unit_price, 10, Color(0.50, 0.32, 0.04, 1.0), 0)
		add_child(preview_unit_price)

	preview_desc = get_node_or_null("PreviewDesc") as Label
	if not preview_desc:
		preview_desc = Label.new()
		preview_desc.name = "PreviewDesc"
		preview_desc.position = Vector2(70.0, 403.0)
		preview_desc.size = Vector2(300.0, 30.0)
		preview_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_desc.clip_text = true
		preview_desc.text = "Click an item in the list above to view details and trade."
		_apply_wlo_typography(preview_desc, 9, Color(0.16, 0.22, 0.40, 1.0), 0)
		add_child(preview_desc)

	# 8. Quantity & Total Cost (Y = 444)
	var qty_lbl := get_node_or_null("QtyLabel") as Label
	if not qty_lbl:
		qty_lbl = Label.new()
		qty_lbl.name = "QtyLabel"
		qty_lbl.position = Vector2(262.0, 442.0)
		qty_lbl.size = Vector2(28.0, 22.0)
		qty_lbl.text = "Qty:"
		qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_wlo_typography(qty_lbl, 10, Color(0.16, 0.22, 0.40, 1.0), 0)
		add_child(qty_lbl)

	qty_spinbox = get_node_or_null("QtySpinBox") as SpinBox
	if not qty_spinbox:
		qty_spinbox = SpinBox.new()
		qty_spinbox.name = "QtySpinBox"
		qty_spinbox.position = Vector2(292.0, 441.0)
		qty_spinbox.size = Vector2(66.0, 24.0)
		qty_spinbox.min_value = 1
		qty_spinbox.max_value = 99
		qty_spinbox.value = 1
		add_child(qty_spinbox)
	var qty_edit := qty_spinbox.get_line_edit()
	if qty_edit:
		var qty_box := StyleBoxFlat.new()
		qty_box.bg_color = Color(1.0, 1.0, 1.0, 1.0)
		qty_box.border_color = Color(0.48, 0.60, 0.82, 1.0)
		qty_box.set_border_width_all(1)
		qty_box.set_corner_radius_all(2)
		for state in ["normal", "focus", "read_only"]:
			qty_edit.add_theme_stylebox_override(state, qty_box)
		qty_edit.add_theme_color_override("font_color", Color(0.16, 0.22, 0.40, 1.0))
		qty_edit.add_theme_color_override("font_uneditable_color", Color(0.16, 0.22, 0.40, 1.0))
		qty_edit.add_theme_font_size_override("font_size", 11)
	if not qty_spinbox.value_changed.is_connected(_on_qty_changed):
		qty_spinbox.value_changed.connect(_on_qty_changed)

	total_cost_label = get_node_or_null("TotalCostLabel") as Label
	if not total_cost_label:
		total_cost_label = Label.new()
		total_cost_label.name = "TotalCostLabel"
		total_cost_label.position = Vector2(190.0, 444.0)
		total_cost_label.size = Vector2(66.0, 16.0)
		total_cost_label.text = "Total: 0 G"
		total_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		total_cost_label.clip_text = true
		_apply_wlo_typography(total_cost_label, 10, Color(0.50, 0.32, 0.04, 1.0), 0)
		add_child(total_cost_label)

	# 9. Authentic Action Button (Buy / Sell)
	btn_action = get_node_or_null("BtnAction") as TextureButton
	if not btn_action:
		btn_action = TextureButton.new()
		btn_action.name = "BtnAction"
		btn_action.position = Vector2(292.0, 468.0)
		btn_action.size = Vector2(66.0, 22.0)
		btn_action.custom_minimum_size = Vector2(66.0, 22.0)
		btn_action.ignore_texture_size = true
		btn_action.stretch_mode = TextureButton.STRETCH_SCALE
		btn_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(btn_action)

	btn_action_label = btn_action.get_node_or_null("ActionLabel") as Label
	if not btn_action_label:
		btn_action_label = Label.new()
		btn_action_label.name = "ActionLabel"
		btn_action_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn_action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_action_label.text = "Buy"
		_apply_wlo_typography(btn_action_label, 11, Color(1.0, 1.0, 1.0, 1.0), 2)
		btn_action.add_child(btn_action_label)

	if not btn_action.pressed.is_connected(_on_action_pressed):
		btn_action.pressed.connect(_on_action_pressed)

	# 10. Bottom Gold Display (Y = 502)
	gold_display_label = get_node_or_null("GoldDisplayLabel") as Label
	if not gold_display_label:
		gold_display_label = Label.new()
		gold_display_label.name = "GoldDisplayLabel"
		gold_display_label.position = Vector2(190.0, 468.0)
		gold_display_label.size = Vector2(90.0, 16.0)
		gold_display_label.text = "Gold: 500 G"
		gold_display_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_wlo_typography(gold_display_label, 10, Color(0.50, 0.32, 0.04, 1.0), 0)
		add_child(gold_display_label)

## Applies authentic Wonderland Online typography (clean font with 1-2px black outline)
func _apply_wlo_typography(lbl: Label, size_pt: int, text_color: Color, outline_px: int = 2) -> void:
	lbl.add_theme_font_size_override("font_size", size_pt)
	lbl.add_theme_color_override("font_color", text_color)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	lbl.add_theme_constant_override("outline_size", outline_px)

func _style_tabs() -> void:
	# The Buy / Trade button textures carry their own caption, so the text labels stay hidden and
	# the active mode is shown at full brightness. (ShopTab_1..7 are store-type tabs: Hot, Armory,
	# Weaponry, Grocery, Furniture, Slot Machine, Forging Room.)
	for tab_label in [btn_tab_buy_label, btn_tab_sell_label]:
		if tab_label:
			tab_label.visible = false
	if btn_tab_buy:
		btn_tab_buy.modulate = Color(1, 1, 1, 1) if current_mode == "buy" else Color(0.72, 0.72, 0.78, 1)
	if btn_tab_sell:
		btn_tab_sell.modulate = Color(1, 1, 1, 1) if current_mode == "sell" else Color(0.72, 0.72, 0.78, 1)
	if current_mode == "buy":
		if btn_tab_buy_label:
			btn_tab_buy_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
		if btn_tab_sell_label:
			btn_tab_sell_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.9))
	else:
		if btn_tab_sell_label:
			btn_tab_sell_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
		if btn_tab_buy_label:
			btn_tab_buy_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.9))

## Opens shop window with merchant details and optional custom catalog
func open_shop(p_merchant_id: int = 0, p_merchant_name: String = "", catalog: Array = []) -> void:
	merchant_id = p_merchant_id
	if not p_merchant_name.is_empty():
		merchant_name = p_merchant_name
	if title_label:
		title_label.text = merchant_name

	if not catalog.is_empty():
		merchant_catalog = []
		for item in catalog:
			if item is Dictionary:
				merchant_catalog.append(item)
	else:
		merchant_catalog = get_default_catalog(merchant_id, merchant_name)

	current_page = 0
	refresh_gold()
	set_mode("buy")
	visible = true
	shop_opened.emit(merchant_id, merchant_name)

## Closes shop window
func close_shop() -> void:
	visible = false
	selected_item = {}
	selected_index = -1
	play_click_sfx()
	window_closed.emit()

## Switches mode between "buy" and "sell"
func set_mode(new_mode: String) -> void:
	if new_mode != "buy" and new_mode != "sell":
		new_mode = "buy"
	current_mode = new_mode
	if current_mode == "sell" and sell_panel_refs.is_empty():
		sell_panel_refs = build_sell_panel(self)
		sell_grid_buttons = build_sell_grid(sell_panel_refs["panel"])
		var sell_grid: GridContainer = sell_panel_refs["panel"].get_node("SellGrid") as GridContainer
		sell_grid.position = Vector2(33, 63)
	_style_tabs()
	selected_item = {}
	selected_index = -1
	current_page = 0
	quantity = 1
	if qty_spinbox:
		qty_spinbox.value = 1

	if current_mode == "buy":
		if btn_action:
			if ResourceLoader.exists(TEX_BUY_NORMAL):
				btn_action.texture_normal = load(TEX_BUY_NORMAL)
			if ResourceLoader.exists(TEX_BUY_HOVER):
				btn_action.texture_hover = load(TEX_BUY_HOVER)
			if ResourceLoader.exists(TEX_BUY_PRESSED):
				btn_action.texture_pressed = load(TEX_BUY_PRESSED)
		if btn_action_label:
			btn_action_label.text = "Buy"
	else:
		if btn_action:
			if ResourceLoader.exists(TEX_TRADE_NORMAL):
				btn_action.texture_normal = load(TEX_TRADE_NORMAL)
			if ResourceLoader.exists(TEX_TRADE_HOVER):
				btn_action.texture_hover = load(TEX_TRADE_HOVER)
			if ResourceLoader.exists(TEX_TRADE_PRESSED):
				btn_action.texture_pressed = load(TEX_TRADE_PRESSED)
		if btn_action_label:
			btn_action_label.text = "Sell"

	_refresh_sell_grid()
	_render_current_page()
	_refresh_preview()
	mode_changed.emit(current_mode)

func _get_current_items() -> Array[Dictionary]:
	if current_mode == "buy":
		if merchant_catalog.is_empty():
			merchant_catalog = get_default_catalog(merchant_id, merchant_name)
		return merchant_catalog
	else:
		return get_player_inventory_items()

func _render_current_page() -> void:
	if slot_rows.size() < SLOTS_PER_PAGE:
		_setup_ui_layout()
	if current_mode == "sell":
		# Sell mode shows the bag grid in the sell panel instead of the list rows.
		for row in slot_rows:
			row.visible = false
		return
	var items := _get_current_items()
	var total_items := items.size()
	var max_pages := maxi(1, int(ceil(float(total_items) / float(SLOTS_PER_PAGE))))
	current_page = clampi(current_page, 0, max_pages - 1)

	if page_indicator_label:
		page_indicator_label.text = "%d/%d" % [current_page + 1, max_pages]

	if btn_page_up:
		btn_page_up.visible = (max_pages > 1)
		btn_page_up.disabled = (current_page == 0)
	if btn_page_dn:
		btn_page_dn.visible = (max_pages > 1)
		btn_page_dn.disabled = (current_page >= max_pages - 1)

	if total_items == 0:
		if empty_label:
			empty_label.text = "The merchant has no goods for sale." if current_mode == "buy" else "Your inventory is empty."
			empty_label.visible = true
		for row in slot_rows:
			row.visible = false
		return

	if empty_label:
		empty_label.visible = false

	var start_idx := current_page * SLOTS_PER_PAGE
	for i in range(SLOTS_PER_PAGE):
		var item_idx := start_idx + i
		var row: Control = slot_rows[i]
		if item_idx < total_items:
			var item: Dictionary = items[item_idx]
			_bind_slot_row(row, item, item_idx)
			row.visible = true
		else:
			row.visible = false

	# If no item is selected or selected item is on a different page, auto-select first on page
	if selected_index < start_idx or selected_index >= start_idx + SLOTS_PER_PAGE:
		if start_idx < total_items:
			select_item(items[start_idx], start_idx)

## The original lists an item's effects as plain stat changes ("ATK: +7, SPD: -3, Req LV: 4"), not prose.
static func effect_text(item: Dictionary) -> String:
	var explicit_text: String = str(item.get("effects", ""))
	if explicit_text != "":
		return explicit_text
	var desc: String = str(item.get("description", ""))
	var stat_re := RegEx.new()
	stat_re.compile(r"^([A-Z]{2,5}) ([+-]\d+)\.")
	var m := stat_re.search(desc)
	if m:
		return "%s: %s" % [m.get_string(1), m.get_string(2)]
	var restore_re := RegEx.new()
	restore_re.compile(r"Restores (\d+) (HP|SP)(?: and (\d+) (HP|SP))?")
	var r := restore_re.search(desc)
	if r:
		var parts: Array[String] = ["%s: +%s" % [r.get_string(2), r.get_string(1)]]
		if r.get_string(3) != "":
			parts.append("%s: +%s" % [r.get_string(4), r.get_string(3)])
		return ", ".join(parts)
	var first := desc.split(". ", false, 1)
	return first[0] if first.size() > 0 else desc


func _bind_slot_row(row: Control, item: Dictionary, index: int) -> void:
	var sel_bezel := row.get_node_or_null("SelBezel") as Panel
	if sel_bezel:
		sel_bezel.visible = (index == selected_index)

	var icon_rect := row.get_node_or_null("IconRect") as TextureRect
	if icon_rect:
		var icon_id: int = int(item.get("icon_id", 0))
		icon_rect.texture = _resolve_item_icon(icon_id)

	var name_lbl := row.get_node_or_null("NameLabel") as Label
	if name_lbl:
		var iname: String = str(item.get("name", "Item"))
		var icount: int = int(item.get("count", 1))
		name_lbl.text = iname if (current_mode == "buy" or icount <= 1) else "%s (x%d)" % [iname, icount]

	var desc_lbl := row.get_node_or_null("DescLabel") as Label
	if desc_lbl:
		desc_lbl.text = effect_text(item)

	var price_lbl := row.get_node_or_null("PriceLabel") as Label
	if price_lbl:
		var unit_p: int = int(item.get("price", 0)) if current_mode == "buy" else get_item_sell_price(item)
		price_lbl.text = "%d G" % unit_p

func _on_slot_gui_input(event: InputEvent, slot_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var items := _get_current_items()
			var item_idx := current_page * SLOTS_PER_PAGE + slot_idx
			if item_idx >= 0 and item_idx < items.size():
				select_item(items[item_idx], item_idx)

func _on_page_prev() -> void:
	if current_page > 0:
		current_page -= 1
		play_click_sfx()
		_render_current_page()

func _on_page_next() -> void:
	var items := _get_current_items()
	var max_pages := maxi(1, int(ceil(float(items.size()) / float(SLOTS_PER_PAGE))))
	if current_page < max_pages - 1:
		current_page += 1
		play_click_sfx()
		_render_current_page()

## Selects an item for preview and quantity trade
func select_item(item_data: Dictionary, index: int) -> void:
	selected_item = item_data
	selected_index = index
	_quantity = 1
	if qty_spinbox:
		if current_mode == "sell":
			var max_c: int = int(item_data.get("count", 1))
			qty_spinbox.max_value = maxi(1, max_c)
		else:
			qty_spinbox.max_value = 99
		qty_spinbox.value = 1

	# Update slot row highlights
	var start_idx := current_page * SLOTS_PER_PAGE
	for i in range(SLOTS_PER_PAGE):
		var item_idx := start_idx + i
		if i < slot_rows.size():
			var sel_bezel := slot_rows[i].get_node_or_null("SelBezel") as Panel
			if sel_bezel:
				sel_bezel.visible = (item_idx == selected_index)

	_refresh_preview()
	play_click_sfx()

## Refreshes the selected item preview panel
func _refresh_preview() -> void:
	if selected_item.is_empty():
		if preview_name: preview_name.text = "Select an item"
		if preview_desc: preview_desc.text = "Click an item in the list above to view details and trade."
		if preview_unit_price: preview_unit_price.text = ""
		if total_cost_label: total_cost_label.text = "Total: 0 G"
		if preview_icon: preview_icon.texture = null
		if btn_action: btn_action.disabled = true
		return

	if btn_action:
		btn_action.disabled = false

	var iname: String = str(selected_item.get("name", "Item"))
	var idesc: String = str(selected_item.get("description", ""))
	var icon_id: int = int(selected_item.get("icon_id", 0))
	var unit_p: int = int(selected_item.get("price", 0)) if current_mode == "buy" else get_item_sell_price(selected_item)

	if preview_name:
		preview_name.text = iname
	if preview_desc:
		preview_desc.text = idesc if not idesc.is_empty() else "A useful item for adventurers."
	if preview_unit_price:
		preview_unit_price.text = "%d G / ea" % unit_p
	if preview_icon:
		preview_icon.texture = _resolve_item_icon(icon_id)

	var total_p: int = unit_p * quantity
	if total_cost_label:
		if current_mode == "buy":
			total_cost_label.text = "Total: %d Gold" % total_p
			if player_gold < total_p:
				total_cost_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
			else:
				total_cost_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
		else:
			total_cost_label.text = "Gain: %d Gold" % total_p
			total_cost_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))

func _on_qty_changed(new_val: float) -> void:
	quantity = int(new_val)
	_refresh_preview()

## Action button pressed: Execute Buy or Sell
func _on_action_pressed() -> void:
	if current_mode == "buy":
		execute_buy()
	else:
		execute_sell()

## Executes buy transaction: checks gold, deducts gold, adds item to inventory, plays audio
func execute_buy() -> bool:
	if selected_item.is_empty():
		return false

	var iid: int = int(selected_item.get("id", 0))
	var iname: String = str(selected_item.get("name", "Item"))
	var icon_id: int = int(selected_item.get("icon_id", 0))
	var idesc: String = str(selected_item.get("description", ""))
	var unit_p: int = int(selected_item.get("price", 0))
	var total_cost: int = unit_p * quantity

	refresh_gold()
	if player_gold < total_cost:
		play_error_sfx()
		_show_feedback("Not enough Gold! Need %d G (have %d G)." % [total_cost, player_gold], true)
		return false

	# Deduct gold
	player_gold -= total_cost
	_apply_gold_change(player_gold)

	# Add item to inventory
	var added: bool = false
	if _hud and _hud.has_method("add_inventory_item"):
		added = _hud.add_inventory_item(iid, quantity, iname, icon_id, idesc)
	else:
		added = true # headless fallback

	play_coin_sfx()
	refresh_gold()
	_refresh_preview()

	var msg := "Purchased %s x%d for %d Gold." % [iname, quantity, total_cost]
	_show_feedback(msg, false)
	item_bought.emit(iid, quantity, total_cost)
	return true

## Executes sell transaction: removes item from inventory, awards gold, plays audio
func execute_sell() -> bool:
	if selected_item.is_empty():
		return false

	var iid: int = int(selected_item.get("id", 0))
	var iname: String = str(selected_item.get("name", "Item"))
	var available_count: int = int(selected_item.get("count", 1))
	var sell_qty: int = mini(quantity, available_count)
	if sell_qty <= 0:
		play_error_sfx()
		return false

	var unit_sell_p: int = get_item_sell_price(selected_item)
	var total_gain: int = unit_sell_p * sell_qty

	# Remove item from player inventory
	var removed: bool = false
	if _hud and _hud.has_method("remove_inventory_item"):
		removed = _hud.remove_inventory_item(iid, sell_qty)
	else:
		removed = true

	if not removed:
		play_error_sfx()
		_show_feedback("Failed to sell %s: not enough in inventory." % iname, true)
		return false

	# Award gold
	refresh_gold()
	player_gold += total_gain
	_apply_gold_change(player_gold)

	play_coin_sfx()
	refresh_gold()

	var msg := "Sold %s x%d for %d Gold." % [iname, sell_qty, total_gain]
	_show_feedback(msg, false)
	item_sold.emit(iid, sell_qty, total_gain)

	# Refresh sell tab list
	_render_current_page()
	_refresh_preview()
	return true

## Synchronizes gold display from HUD inventory or character data
func refresh_gold() -> int:
	var g: int = player_gold
	if _hud:
		if "inventory_ctrl" in _hud and _hud.inventory_ctrl:
			var inv_ctrl = _hud.inventory_ctrl
			if "gold_label" in inv_ctrl and inv_ctrl.gold_label and inv_ctrl.gold_label.text.is_valid_int():
				g = inv_ctrl.gold_label.text.to_int()
		elif "gold_label" in _hud and _hud.gold_label and _hud.gold_label.text.is_valid_int():
			g = _hud.gold_label.text.to_int()

	player_gold = g
	if gold_display_label:
		gold_display_label.text = "Gold: %d G" % player_gold
	return player_gold

func _apply_gold_change(new_gold: int) -> void:
	player_gold = maxi(0, new_gold)
	if _hud:
		if _hud.has_method("update_gold"):
			_hud.update_gold(player_gold)
		elif "inventory_ctrl" in _hud and _hud.inventory_ctrl and _hud.inventory_ctrl.has_method("update_gold"):
			_hud.inventory_ctrl.update_gold(player_gold)
	if gold_display_label:
		gold_display_label.text = "Gold: %d G" % player_gold

## Calculates 50% sell valuation for player items
func get_item_sell_price(item_data: Dictionary) -> int:
	if item_data.has("sell_price") and int(item_data["sell_price"]) > 0:
		return int(item_data["sell_price"])
	if item_data.has("price") and int(item_data["price"]) > 0:
		return maxi(1, int(int(item_data["price"]) * 0.5))

	var iid: int = int(item_data.get("id", 0))
	var db = _get_game_database()
	if db and "items" in db and db.items:
		var rec = db.items.get_item(iid)
		if rec:
			if rec.sell_price > 0:
				return rec.sell_price
			if rec.buy_price > 0:
				return maxi(1, int(rec.buy_price * 0.5))
			var r: int = rec.get_rank()
			if r > 0:
				return maxi(2, int(r * 15))

	return 10

## Returns all non-empty player inventory items
func get_player_inventory_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not _hud:
		return result

	var inv_data: Array = []
	if "inventory_ctrl" in _hud and _hud.inventory_ctrl and "inventory_data" in _hud.inventory_ctrl:
		inv_data = _hud.inventory_ctrl.inventory_data
	elif "_inventory_data" in _hud:
		inv_data = _hud._inventory_data

	for item in inv_data:
		if item is Dictionary and int(item.get("id", 0)) > 0:
			result.append(item.duplicate(true))

	return result

## Provides authentic Wonderland Online merchant catalogs by merchant type
static func get_default_catalog(m_id: int, m_name: String) -> Array[Dictionary]:
	var name_low := m_name.to_lower()
	
	# 1. Pharmacy / Drug Store / Potions (ID 15107, 13004, or pharmacy/drug in name)
	if m_id in [15107, 13004] or "pharmacy" in name_low or "drug" in name_low or "potion" in name_low:
		return [
			{
				"id": 34281,
				"name": "Healing Potion",
				"icon_id": 3438,
				"price": 50,
				"description": "Restores 150 HP immediately. Essential survival medicine."
			},
			{
				"id": 34282,
				"name": "SP Potion",
				"icon_id": 3439,
				"price": 60,
				"description": "Restores 100 SP immediately. Brewed from distilled mana herbs."
			},
			{
				"id": 34283,
				"name": "Super HP Potion",
				"icon_id": 3438,
				"price": 140,
				"description": "Restores 350 HP immediately. Potent restorative elixir."
			},
			{
				"id": 34284,
				"name": "Super SP Potion",
				"icon_id": 3439,
				"price": 160,
				"description": "Restores 250 SP immediately. Pure concentrated spiritual essence."
			},
			{
				"id": 32316,
				"name": "Herb Milk",
				"icon_id": 1032,
				"price": 35,
				"description": "Restores 70 HP and 70 SP. Nutritious beverage."
			}
		]

	# 2. Weapon Smith / Armorer (ID 13000, 19177, 13009, or weapon/smith/arm in name)
	if m_id in [13000, 19177, 13009] or "weapon" in name_low or "smith" in name_low or "armor" in name_low:
		return [
			{
				"id": 11031,
				"name": "Copper Sword",
				"icon_id": 2468,
				"price": 120,
				"description": "ATK +4. A lightweight starter forged copper blade."
			},
			{
				"id": 11032,
				"name": "Bronze Sword",
				"icon_id": 2469,
				"price": 200,
				"description": "ATK +7. Tempered bronze blade with solid balance."
			},
			{
				"id": 11033,
				"name": "Iron Sword",
				"icon_id": 2466,
				"price": 350,
				"description": "ATK +12. Sturdy iron sword crafted by village smiths."
			},
			{
				"id": 30035,
				"name": "Psychic's Dagger",
				"icon_id": 1137,
				"price": 220,
				"description": "MATK +8. Enchanted ritual dagger favored by mages."
			},
			{
				"id": 11041,
				"name": "Copper Big Sword",
				"icon_id": 1152,
				"price": 260,
				"description": "ATK +10, SPD -2. Heavy broad two-handed cleaver."
			}
		]

	# 3. Grocery Store / Props Shopkeeper (Kelan Village Props Shop, real client capture 2026-10-30).
	# Name, icon, description and price come from Item.dat (GameDatabase.items), not from this file.
	return _catalog_from_item_dat(PROPS_SHOP_ITEM_IDS)

func _resolve_item_icon(icon_id: int) -> Texture2D:
	if icon_id <= 0:
		return null
	var loader = _get_archive_loader()
	if loader and loader.has_method("get_item_icon"):
		var tex = loader.get_item_icon(icon_id)
		if tex:
			return tex
	return null

func _get_archive_loader() -> Node:
	if _hud and _hud.is_inside_tree():
		var l = _hud.get_node_or_null("/root/ArchiveLoader")
		if l: return l
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("ArchiveLoader")
	return null

func _get_game_database() -> Node:
	if _hud and _hud.is_inside_tree():
		var db = _hud.get_node_or_null("/root/GameDatabase")
		if db: return db
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		return loop.root.get_node_or_null("GameDatabase")
	return null

func _show_feedback(msg: String, is_error: bool) -> void:
	if _hud and _hud.has_method("add_chat_message"):
		_hud.add_chat_message("Merchant", msg, "System" if not is_error else "Local")
	print("[ShopWindow] ", msg)

## Sets purchase or sell quantity and refreshes preview and calculations
func set_quantity(new_qty: int) -> void:
	quantity = maxi(1, new_qty)
	if qty_spinbox:
		qty_spinbox.value = quantity
	_refresh_preview()

func play_coin_sfx() -> void:
	if _hud and _hud.has_method("play_sfx"):
		_hud.play_sfx("wav9911")
	elif ResourceLoader.exists(SFX_COIN_PATH):
		if _sfx_player and _sfx_player.is_inside_tree():
			_sfx_player.stream = load(SFX_COIN_PATH)
			_sfx_player.play()

func play_error_sfx() -> void:
	if ResourceLoader.exists(SFX_ERROR_PATH):
		if _sfx_player and _sfx_player.is_inside_tree():
			_sfx_player.stream = load(SFX_ERROR_PATH)
			_sfx_player.play()

func play_click_sfx() -> void:
	if ResourceLoader.exists(SFX_CLICK_PATH):
		if _sfx_player and _sfx_player.is_inside_tree():
			_sfx_player.stream = load(SFX_CLICK_PATH)
			_sfx_player.play()

# Floating Draggable Window Implementation
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if mb.position.y <= 36.0:
					_is_dragging = true
					_drag_offset = get_global_mouse_position() - global_position
			else:
				_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		var new_pos := get_global_mouse_position() - _drag_offset
		if get_viewport():
			var vp_size := get_viewport_rect().size
			new_pos.x = clampf(new_pos.x, 0.0, vp_size.x - FORM_WIDTH)
			new_pos.y = clampf(new_pos.y, 0.0, vp_size.y - FORM_HEIGHT)
		global_position = new_pos


## Item ids sold by the Kelan Village Props Shop (real client: Miscellaneous). Data is read from Item.dat.
const PROPS_SHOP_ITEM_IDS: Array[int] = [32011, 32002, 45001, 45003, 42008]


## Builds shop entries from the item database (Item.dat). Items missing from the database are skipped.
static func _catalog_from_item_dat(item_ids: Array[int]) -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	var loop := Engine.get_main_loop()
	var db: Node = loop.root.get_node_or_null("GameDatabase") if loop is SceneTree else null
	if db == null or not ("items" in db) or db.items == null:
		return catalog
	for item_id in item_ids:
		var rec = db.items.get_item(item_id)
		if rec == null:
			continue
		catalog.append({
			"id": item_id,
			"name": str(rec.name).strip_edges(),
			"icon_id": int(rec.icon_id),
			"price": int(rec.buy_price),
			"description": str(rec.description)
		})
	return catalog


## Sell grid (real client: "Select props to sell", the bag as a 5 x 10 icon grid). Built lazily; hidden for now.
var sell_grid_buttons: Array = []
var sell_panel_refs: Dictionary = {}
var _sell_hidden_nodes: Array[Node] = []


func build_sell_grid(parent: Control) -> Array:
	var grid := GridContainer.new()
	grid.name = "SellGrid"
	grid.columns = 5
	grid.visible = true
	parent.add_child(grid)

	var buttons: Array = []
	for i in range(50):
		var button := Button.new()
		grid.add_child(button)
		buttons.append(button)

	return buttons


func set_grid_cell(btn: Button, item: Dictionary) -> void:
	if item.is_empty() or item.get("id", 0) == 0:
		btn.text = ""
		btn.tooltip_text = ""
		btn.disabled = true
	else:
		btn.text = str(item.get("count", 0))
		btn.tooltip_text = str(item.get("name", ""))
		btn.disabled = false


## Fills the sell grid from the bag (50 cells) and wires each cell to pick its item.
func refresh_sell_grid(buttons: Array, bag: Array, on_pick: Callable) -> void:
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		var item: Dictionary = bag[i] if i < bag.size() else {}
		set_grid_cell(btn, item)
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		if on_pick.is_valid():
			btn.pressed.connect(func() -> void: on_pick.call(i, item))


func _refresh_sell_grid() -> void:
	if sell_panel_refs.is_empty():
		return
	sell_panel_refs["panel"].visible = current_mode == "sell"
	_update_buy_parts_visibility()
	var bag: Array = []
	if _hud and "inventory_ctrl" in _hud and _hud.inventory_ctrl:
		bag = _hud.inventory_ctrl.inventory_data
	refresh_sell_grid(sell_grid_buttons, bag, Callable(self, "_on_sell_grid_pick"))


func _on_sell_grid_pick(index: int, item: Dictionary) -> void:
	if item.is_empty() or int(item.get("id", 0)) == 0:
		return
	select_item(item, index)


## Sell panel (real client: "Select props to sell"); positions measured from the real capture.
func build_sell_panel(parent: Control) -> Dictionary:
	var panel := Control.new()
	panel.name = "SellPanel"
	panel.visible = false
	parent.add_child(panel)

	var title := Label.new()
	title.name = "Title"
	title.text = "Select props to sell"
	title.position = Vector2(30, 18)
	panel.add_child(title)

	var lbl_selling_caption := Label.new()
	lbl_selling_caption.name = "SellingAmountCaption"
	lbl_selling_caption.text = "selling amount"
	lbl_selling_caption.position = Vector2(17, 403)
	panel.add_child(lbl_selling_caption)

	var selling_amount := Label.new()
	selling_amount.name = "SellingAmount"
	selling_amount.text = "0"
	selling_amount.position = Vector2(187, 412)
	panel.add_child(selling_amount)

	var lbl_money_caption := Label.new()
	lbl_money_caption.name = "MoneyHeldCaption"
	lbl_money_caption.text = "money held"
	lbl_money_caption.position = Vector2(31, 433)
	panel.add_child(lbl_money_caption)

	var money_held := Label.new()
	money_held.name = "MoneyHeld"
	money_held.text = "0"
	money_held.position = Vector2(188, 438)
	panel.add_child(money_held)

	var btn_size := Vector2(55, 17)

	var confirm := Button.new()
	confirm.name = "Confirm"
	confirm.text = "Confirm"
	confirm.position = Vector2(54, 458)
	confirm.size = btn_size
	confirm.custom_minimum_size = btn_size
	panel.add_child(confirm)

	var close := Button.new()
	close.name = "Close"
	close.text = "Close"
	close.position = Vector2(129, 458)
	close.size = btn_size
	close.custom_minimum_size = btn_size
	panel.add_child(close)

	return {
		"panel": panel,
		"title": title,
		"selling_amount": selling_amount,
		"money_held": money_held,
		"confirm": confirm,
		"close": close
	}


## Sell mode shows only the sell panel over the window frame: buy-only parts are hidden and restored when buying again.
const _SELL_KEEP_NODES: Array[String] = ["Background", "CloseButton", "SellPanel", "ShopAudioPlayer"]


func _update_buy_parts_visibility() -> void:
	if current_mode == "sell":
		for child in get_children():
			if child is CanvasItem and child.visible and not (child.name in _SELL_KEEP_NODES):
				child.visible = false
				_sell_hidden_nodes.append(child)
	else:
		for node in _sell_hidden_nodes:
			if is_instance_valid(node):
				node.visible = true
		_sell_hidden_nodes.clear()
		_render_current_page()
