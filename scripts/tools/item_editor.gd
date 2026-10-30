class_name ItemEditor
extends Control

const ItemDatabase = preload("res://scripts/database/item_database.gd")

## Wonderland Online Item, Equipment & Alchemy Studio Authoring Tool
## Production-ready, strictly type-hinted visual editor for authoring, modifying,
## previewing, and synthesizing items, equipment stat modifiers, and alchemy recipes.

signal item_saved(item_id: int, file_path: String)
signal item_loaded(item_id: int)
signal recipe_exported(file_path: String)
signal stats_updated()
signal preset_applied(preset_name: String)

## Equip positions 1..6 as the real client names them (aLogin.exe 0x3e92a4): Head, Body, Weapon, Hands, Shoes, Special Eq.
enum EquipSlot {
	NONE = 0,
	HEADGEAR = 1,
	CLOTHES = 2,
	WEAPON = 3,
	WRIST_SHIELD = 4,
	SHOES = 5,
	ACCESSORY = 6,
	CONSUMABLE = 7,
	CRAFTING_MATERIAL = 8,
	TENT_FURNITURE = 9,
}

const PRESETS: Dictionary = {
	"Bronze Sword": {
		"item_id": 23001,
		"item_name": "Bronze Sword",
		"description": "A standard bronze sword forged by village blacksmiths.",
		"icon_id": 1000,
		"level_req": 10,
		"rank": 3,
		"durability": 50,
		"max_durability": 50,
		"equip_slot": EquipSlot.WEAPON,
		"buy_price": 150,
		"sell_price": 75,
		"atk": 12,
		"def": 0,
		"matk": 0,
		"mdef": 0,
		"spd": -2,
		"hp_bonus": 0,
		"sp_bonus": 0
	},
	"Iron Armor": {
		"item_id": 21005,
		"item_name": "Iron Armor",
		"description": "Heavy protective armor crafted from refined iron plates.",
		"icon_id": 1005,
		"level_req": 15,
		"rank": 5,
		"durability": 60,
		"max_durability": 60,
		"equip_slot": EquipSlot.CLOTHES,
		"buy_price": 300,
		"sell_price": 150,
		"atk": 0,
		"def": 18,
		"matk": 0,
		"mdef": 4,
		"spd": 0,
		"hp_bonus": 0,
		"sp_bonus": 0
	},
	"Feather Boots": {
		"item_id": 24003,
		"item_name": "Feather Boots",
		"description": "Lightweight boots sewn with enchanted avian plumage.",
		"icon_id": 1010,
		"level_req": 12,
		"rank": 4,
		"durability": 45,
		"max_durability": 45,
		"equip_slot": EquipSlot.SHOES,
		"buy_price": 200,
		"sell_price": 100,
		"atk": 0,
		"def": 3,
		"matk": 0,
		"mdef": 0,
		"spd": 15,
		"hp_bonus": 0,
		"sp_bonus": 0
	},
	"Healing Grass": {
		"item_id": 32001,
		"item_name": "Healing Grass",
		"description": "Fresh wild herbs that restore 50 vitality upon consumption.",
		"icon_id": 1020,
		"level_req": 1,
		"rank": 1,
		"durability": 1,
		"max_durability": 1,
		"equip_slot": EquipSlot.CONSUMABLE,
		"buy_price": 10,
		"sell_price": 5,
		"atk": 0,
		"def": 0,
		"matk": 0,
		"mdef": 0,
		"spd": 0,
		"hp_bonus": 50,
		"sp_bonus": 0
	},
	"Mana Potion": {
		"item_id": 32002,
		"item_name": "Mana Potion",
		"description": "A distilled mystical brew that replenishes 60 spiritual energy.",
		"icon_id": 1021,
		"level_req": 1,
		"rank": 2,
		"durability": 1,
		"max_durability": 1,
		"equip_slot": EquipSlot.CONSUMABLE,
		"buy_price": 25,
		"sell_price": 12,
		"atk": 0,
		"def": 0,
		"matk": 0,
		"mdef": 0,
		"spd": 0,
		"hp_bonus": 0,
		"sp_bonus": 60
	}
}

# --- Item Master Attributes ---
var item_id: int = 23001
var item_name: String = "Bronze Sword"
var description: String = "A standard bronze sword forged by village blacksmiths."
var icon_id: int = 1000
var level_req: int = 10
var rank: int = 3
var materials: Array[String] = []
var material_name: String = ""
var durability: int = 50
var max_durability: int = 50
var equip_slot: int = EquipSlot.WEAPON
var buy_price: int = 150
var sell_price: int = 75

# --- Stat Modifiers Builder ---
var atk: int = 12
var def: int = 0
var matk: int = 0
var mdef: int = 0
var spd: int = -2
var hp_bonus: int = 0
var sp_bonus: int = 0

# --- Alchemy & Synthesis State ---
var alchemy_recipe_name: String = "Bronze Sword Forging"
var alchemy_mat_a_id: int = 23001
var alchemy_mat_a_rank: int = 3
var alchemy_mat_b_id: int = 21005
var alchemy_mat_b_rank: int = 5
var alchemy_catalyst_tier: int = 0

# --- Internal UI State ---
var _is_updating_ui: bool = false
var _is_ui_ready: bool = false
var _signals_connected: bool = false

# --- UI Node References (Resolved in _ready or when bound) ---
var spin_item_id: SpinBox = null
var edit_item_name: LineEdit = null
var edit_description: TextEdit = null
var spin_icon_id: SpinBox = null
var rect_icon_preview: TextureRect = null
var spin_level_req: SpinBox = null
var spin_rank: SpinBox = null
var spin_durability: SpinBox = null
var spin_max_durability: SpinBox = null
var opt_equip_slot: OptionButton = null
var spin_buy_price: SpinBox = null
var spin_sell_price: SpinBox = null

var spin_atk: SpinBox = null
var spin_def: SpinBox = null
var spin_matk: SpinBox = null
var spin_mdef: SpinBox = null
var spin_spd: SpinBox = null
var spin_hp_bonus: SpinBox = null
var spin_sp_bonus: SpinBox = null
var lbl_stats_summary: Label = null

var edit_recipe_name: LineEdit = null
var spin_mat_a_id: SpinBox = null
var spin_mat_a_rank: SpinBox = null
var spin_mat_b_id: SpinBox = null
var spin_mat_b_rank: SpinBox = null
var opt_catalyst_tier: OptionButton = null
var lbl_synth_base_rank: Label = null
var lbl_synth_rank_range: Label = null
var lbl_synth_success_rate: Label = null
var bar_synth_success: ProgressBar = null
var btn_export_recipe: Button = null

var panel_tooltip: PanelContainer = null
var lbl_tt_title: Label = null
var lbl_tt_slot: Label = null
var lbl_tt_level: Label = null
var lbl_tt_stats: Label = null
var lbl_tt_durability: Label = null
var lbl_tt_desc: Label = null
var lbl_tt_prices: Label = null

var opt_presets: OptionButton = null
var btn_new_item: Button = null
var btn_save_json: Button = null
var btn_load_json: Button = null
var lbl_status: Label = null

func _ready() -> void:
	if _is_ui_ready:
		return
	custom_minimum_size = Vector2(800.0, 600.0)
	_bind_ui_elements()
	_populate_dropdowns()
	_connect_ui_signals()
	_is_ui_ready = true
	sync_to_ui()
	update_all_previews()

func _bind_ui_elements() -> void:
	spin_item_id = find_child("SpinItemID", true, false) as SpinBox
	edit_item_name = find_child("EditItemName", true, false) as LineEdit
	edit_description = find_child("EditDescription", true, false) as TextEdit
	spin_icon_id = find_child("SpinIconID", true, false) as SpinBox
	rect_icon_preview = find_child("RectIconPreview", true, false) as TextureRect
	spin_level_req = find_child("SpinLevelReq", true, false) as SpinBox
	spin_rank = find_child("SpinRank", true, false) as SpinBox
	spin_durability = find_child("SpinDurability", true, false) as SpinBox
	spin_max_durability = find_child("SpinMaxDurability", true, false) as SpinBox
	opt_equip_slot = find_child("OptEquipSlot", true, false) as OptionButton
	spin_buy_price = find_child("SpinBuyPrice", true, false) as SpinBox
	spin_sell_price = find_child("SpinSellPrice", true, false) as SpinBox

	spin_atk = find_child("SpinAtk", true, false) as SpinBox
	spin_def = find_child("SpinDef", true, false) as SpinBox
	spin_matk = find_child("SpinMatk", true, false) as SpinBox
	spin_mdef = find_child("SpinMdef", true, false) as SpinBox
	spin_spd = find_child("SpinSpd", true, false) as SpinBox
	spin_hp_bonus = find_child("SpinHpBonus", true, false) as SpinBox
	spin_sp_bonus = find_child("SpinSpBonus", true, false) as SpinBox
	lbl_stats_summary = find_child("LblStatsSummary", true, false) as Label

	edit_recipe_name = find_child("EditRecipeName", true, false) as LineEdit
	spin_mat_a_id = find_child("SpinMatAID", true, false) as SpinBox
	spin_mat_a_rank = find_child("SpinMatARank", true, false) as SpinBox
	spin_mat_b_id = find_child("SpinMatBID", true, false) as SpinBox
	spin_mat_b_rank = find_child("SpinMatBRank", true, false) as SpinBox
	opt_catalyst_tier = find_child("OptCatalystTier", true, false) as OptionButton
	lbl_synth_base_rank = find_child("LblSynthBaseRank", true, false) as Label
	lbl_synth_rank_range = find_child("LblSynthRankRange", true, false) as Label
	lbl_synth_success_rate = find_child("LblSynthSuccessRate", true, false) as Label
	bar_synth_success = find_child("BarSynthSuccess", true, false) as ProgressBar
	btn_export_recipe = find_child("BtnExportRecipe", true, false) as Button

	panel_tooltip = find_child("PanelTooltipPreview", true, false) as PanelContainer
	lbl_tt_title = find_child("LblTooltipTitle", true, false) as Label
	lbl_tt_slot = find_child("LblTooltipSlot", true, false) as Label
	lbl_tt_level = find_child("LblTooltipLevel", true, false) as Label
	lbl_tt_stats = find_child("LblTooltipStats", true, false) as Label
	lbl_tt_durability = find_child("LblTooltipDurability", true, false) as Label
	lbl_tt_desc = find_child("LblTooltipDesc", true, false) as Label
	lbl_tt_prices = find_child("LblTooltipPrices", true, false) as Label

	opt_presets = find_child("OptPresets", true, false) as OptionButton
	btn_new_item = find_child("BtnNewItem", true, false) as Button
	btn_save_json = find_child("BtnSaveJSON", true, false) as Button
	btn_load_json = find_child("BtnLoadJSON", true, false) as Button
	lbl_status = find_child("LblStatus", true, false) as Label

func _populate_dropdowns() -> void:
	if opt_equip_slot and opt_equip_slot.item_count == 0:
		opt_equip_slot.add_item("None / Inventory", EquipSlot.NONE)
		opt_equip_slot.add_item("Head", EquipSlot.HEADGEAR)
		opt_equip_slot.add_item("Body", EquipSlot.CLOTHES)
		opt_equip_slot.add_item("Weapon", EquipSlot.WEAPON)
		opt_equip_slot.add_item("Hands", EquipSlot.WRIST_SHIELD)
		opt_equip_slot.add_item("Shoes", EquipSlot.SHOES)
		opt_equip_slot.add_item("Special Eq", EquipSlot.ACCESSORY)
		opt_equip_slot.add_item("Consumable", EquipSlot.CONSUMABLE)
		opt_equip_slot.add_item("Crafting Material", EquipSlot.CRAFTING_MATERIAL)
		opt_equip_slot.add_item("Tent Furniture", EquipSlot.TENT_FURNITURE)

	if opt_catalyst_tier and opt_catalyst_tier.item_count == 0:
		opt_catalyst_tier.add_item("None (Grade 0)", 0)
		opt_catalyst_tier.add_item("Alchemy Book I (+1)", 1)
		opt_catalyst_tier.add_item("Alchemy Book II (+2)", 2)
		opt_catalyst_tier.add_item("Alchemy Book III (+3)", 3)
		opt_catalyst_tier.add_item("Alchemy Book IV (+4)", 4)

	if opt_presets and opt_presets.item_count == 0:
		opt_presets.add_item("Presets...", 0)
		var p_idx: int = 1
		for preset_name in PRESETS.keys():
			opt_presets.add_item(preset_name, p_idx)
			p_idx += 1

func _connect_ui_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	if spin_item_id: spin_item_id.value_changed.connect(_on_item_field_changed)
	if edit_item_name: edit_item_name.text_changed.connect(_on_item_field_changed)
	if edit_description: edit_description.text_changed.connect(_on_item_field_changed)
	if spin_icon_id: spin_icon_id.value_changed.connect(_on_icon_id_changed)
	if spin_level_req: spin_level_req.value_changed.connect(_on_item_field_changed)
	if spin_rank: spin_rank.value_changed.connect(_on_item_field_changed)
	if spin_durability: spin_durability.value_changed.connect(_on_item_field_changed)
	if spin_max_durability: spin_max_durability.value_changed.connect(_on_item_field_changed)
	if opt_equip_slot: opt_equip_slot.item_selected.connect(_on_equip_slot_selected)
	if spin_buy_price: spin_buy_price.value_changed.connect(_on_item_field_changed)
	if spin_sell_price: spin_sell_price.value_changed.connect(_on_item_field_changed)

	if spin_atk: spin_atk.value_changed.connect(_on_stat_field_changed)
	if spin_def: spin_def.value_changed.connect(_on_stat_field_changed)
	if spin_matk: spin_matk.value_changed.connect(_on_stat_field_changed)
	if spin_mdef: spin_mdef.value_changed.connect(_on_stat_field_changed)
	if spin_spd: spin_spd.value_changed.connect(_on_stat_field_changed)
	if spin_hp_bonus: spin_hp_bonus.value_changed.connect(_on_stat_field_changed)
	if spin_sp_bonus: spin_sp_bonus.value_changed.connect(_on_stat_field_changed)

	if edit_recipe_name: edit_recipe_name.text_changed.connect(_on_alchemy_field_changed)
	if spin_mat_a_id: spin_mat_a_id.value_changed.connect(_on_alchemy_field_changed)
	if spin_mat_a_rank: spin_mat_a_rank.value_changed.connect(_on_alchemy_field_changed)
	if spin_mat_b_id: spin_mat_b_id.value_changed.connect(_on_alchemy_field_changed)
	if spin_mat_b_rank: spin_mat_b_rank.value_changed.connect(_on_alchemy_field_changed)
	if opt_catalyst_tier: opt_catalyst_tier.item_selected.connect(_on_catalyst_selected)
	if btn_export_recipe: btn_export_recipe.pressed.connect(_on_btn_export_recipe_pressed)

	if opt_presets: opt_presets.item_selected.connect(_on_preset_selected)
	if btn_new_item: btn_new_item.pressed.connect(_on_btn_new_item_pressed)
	if btn_save_json: btn_save_json.pressed.connect(_on_btn_save_json_pressed)
	if btn_load_json: btn_load_json.pressed.connect(_on_btn_load_json_pressed)

# --- UI Sync Logic ---

func sync_to_ui() -> void:
	if not _is_ui_ready:
		return
	_is_updating_ui = true

	if spin_item_id: spin_item_id.value = item_id
	if edit_item_name: edit_item_name.text = item_name
	if edit_description: edit_description.text = description
	if spin_icon_id: spin_icon_id.value = icon_id
	if spin_level_req: spin_level_req.value = level_req
	if spin_rank: spin_rank.value = rank
	if spin_durability: spin_durability.value = durability
	if spin_max_durability: spin_max_durability.value = max_durability
	if opt_equip_slot:
		for i in range(opt_equip_slot.item_count):
			if opt_equip_slot.get_item_id(i) == equip_slot:
				opt_equip_slot.selected = i
				break
	if spin_buy_price: spin_buy_price.value = buy_price
	if spin_sell_price: spin_sell_price.value = sell_price

	if spin_atk: spin_atk.value = atk
	if spin_def: spin_def.value = def
	if spin_matk: spin_matk.value = matk
	if spin_mdef: spin_mdef.value = mdef
	if spin_spd: spin_spd.value = spd
	if spin_hp_bonus: spin_hp_bonus.value = hp_bonus
	if spin_sp_bonus: spin_sp_bonus.value = sp_bonus

	if edit_recipe_name: edit_recipe_name.text = alchemy_recipe_name
	if spin_mat_a_id: spin_mat_a_id.value = alchemy_mat_a_id
	if spin_mat_a_rank: spin_mat_a_rank.value = alchemy_mat_a_rank
	if spin_mat_b_id: spin_mat_b_id.value = alchemy_mat_b_id
	if spin_mat_b_rank: spin_mat_b_rank.value = alchemy_mat_b_rank
	if opt_catalyst_tier:
		for i in range(opt_catalyst_tier.item_count):
			if opt_catalyst_tier.get_item_id(i) == alchemy_catalyst_tier:
				opt_catalyst_tier.selected = i
				break

	_is_updating_ui = false

func sync_from_ui() -> void:
	if not _is_ui_ready or _is_updating_ui:
		return

	if spin_item_id: item_id = int(spin_item_id.value)
	if edit_item_name: item_name = edit_item_name.text
	if edit_description: description = edit_description.text
	if spin_icon_id: icon_id = int(spin_icon_id.value)
	if spin_level_req: level_req = int(spin_level_req.value)
	if spin_rank: rank = int(spin_rank.value)
	if spin_durability: durability = int(spin_durability.value)
	if spin_max_durability: max_durability = int(spin_max_durability.value)
	if opt_equip_slot and opt_equip_slot.selected >= 0:
		equip_slot = opt_equip_slot.get_selected_id()
	if spin_buy_price: buy_price = int(spin_buy_price.value)
	if spin_sell_price: sell_price = int(spin_sell_price.value)

	if spin_atk: atk = int(spin_atk.value)
	if spin_def: def = int(spin_def.value)
	if spin_matk: matk = int(spin_matk.value)
	if spin_mdef: mdef = int(spin_mdef.value)
	if spin_spd: spd = int(spin_spd.value)
	if spin_hp_bonus: hp_bonus = int(spin_hp_bonus.value)
	if spin_sp_bonus: sp_bonus = int(spin_sp_bonus.value)

	if edit_recipe_name: alchemy_recipe_name = edit_recipe_name.text
	if spin_mat_a_id: alchemy_mat_a_id = int(spin_mat_a_id.value)
	if spin_mat_a_rank: alchemy_mat_a_rank = int(spin_mat_a_rank.value)
	if spin_mat_b_id: alchemy_mat_b_id = int(spin_mat_b_id.value)
	if spin_mat_b_rank: alchemy_mat_b_rank = int(spin_mat_b_rank.value)
	if opt_catalyst_tier and opt_catalyst_tier.selected >= 0:
		alchemy_catalyst_tier = opt_catalyst_tier.get_selected_id()

# --- Signal Handlers ---

func _on_item_field_changed(_val = null) -> void:
	if _is_updating_ui:
		return
	materials.clear()
	material_name = ""
	sync_from_ui()
	update_all_previews()

func _on_icon_id_changed(_val = null) -> void:
	if _is_updating_ui:
		return
	sync_from_ui()
	update_icon_preview()
	update_tooltip_preview()

func _on_equip_slot_selected(_index: int) -> void:
	if _is_updating_ui:
		return
	materials.clear()
	material_name = ""
	sync_from_ui()
	update_all_previews()

func _on_stat_field_changed(_val = null) -> void:
	if _is_updating_ui:
		return
	sync_from_ui()
	update_stats_summary()
	update_tooltip_preview()
	stats_updated.emit()

func _on_alchemy_field_changed(_val = null) -> void:
	if _is_updating_ui:
		return
	sync_from_ui()
	update_synthesis_preview()

func _on_catalyst_selected(_index: int) -> void:
	if _is_updating_ui:
		return
	sync_from_ui()
	update_synthesis_preview()

func _on_preset_selected(index: int) -> void:
	if index <= 0 or not opt_presets:
		return
	var preset_name: String = opt_presets.get_item_text(index)
	apply_preset(preset_name)

func _on_btn_new_item_pressed() -> void:
	reset_to_blank()

func _on_btn_save_json_pressed() -> void:
	var export_path: String = "user://item_%d.json" % item_id
	if save_item_json(export_path):
		_set_status("Item saved to %s" % export_path)

func _on_btn_load_json_pressed() -> void:
	var import_path: String = "user://item_%d.json" % item_id
	if FileAccess.file_exists(import_path):
		var res := load_item_json(import_path)
		if not res.is_empty():
			_set_status("Item loaded from %s" % import_path)
	else:
		_set_status("File not found: %s" % import_path)

func _on_btn_export_recipe_pressed() -> void:
	var export_path: String = "user://recipe_%s.json" % alchemy_recipe_name.to_snake_case()
	if export_recipe_json(export_path):
		_set_status("Recipe exported to %s" % export_path)

# --- Public API & Methods ---

static func get_equip_slot_name(slot: int) -> String:
	match slot:
		EquipSlot.NONE: return "None / Inventory"
		EquipSlot.HEADGEAR: return "Head"
		EquipSlot.CLOTHES: return "Body"
		EquipSlot.WEAPON: return "Weapon"
		EquipSlot.WRIST_SHIELD: return "Hands"
		EquipSlot.SHOES: return "Shoes"
		EquipSlot.ACCESSORY: return "Special Eq"
		EquipSlot.CONSUMABLE: return "Consumable"
		EquipSlot.CRAFTING_MATERIAL: return "Crafting Material"
		EquipSlot.TENT_FURNITURE: return "Tent Furniture"
		_: return "Unknown"

func get_formatted_stats() -> Array[Dictionary]:
	var stats: Array[Dictionary] = []
	if atk != 0:
		stats.append({
			"name": "ATK",
			"delta": atk,
			"text": "ATK %s%d" % ["+" if atk > 0 else "", atk],
			"is_positive": atk >= 0
		})
	if def != 0:
		stats.append({
			"name": "DEF",
			"delta": def,
			"text": "DEF %s%d" % ["+" if def > 0 else "", def],
			"is_positive": def >= 0
		})
	if matk != 0:
		stats.append({
			"name": "MATK",
			"delta": matk,
			"text": "MATK %s%d" % ["+" if matk > 0 else "", matk],
			"is_positive": matk >= 0
		})
	if mdef != 0:
		stats.append({
			"name": "MDEF",
			"delta": mdef,
			"text": "MDEF %s%d" % ["+" if mdef > 0 else "", mdef],
			"is_positive": mdef >= 0
		})
	if spd != 0:
		stats.append({
			"name": "SPD",
			"delta": spd,
			"text": "SPD %s%d" % ["+" if spd > 0 else "", spd],
			"is_positive": spd >= 0
		})
	if hp_bonus != 0:
		stats.append({
			"name": "HP",
			"delta": hp_bonus,
			"text": "HP %s%d" % ["+" if hp_bonus > 0 else "", hp_bonus],
			"is_positive": hp_bonus >= 0
		})
	if sp_bonus != 0:
		stats.append({
			"name": "SP",
			"delta": sp_bonus,
			"text": "SP %s%d" % ["+" if sp_bonus > 0 else "", sp_bonus],
			"is_positive": sp_bonus >= 0
		})
	return stats

func get_materials() -> Array[String]:
	if not materials.is_empty():
		return materials
	materials = ItemDatabase.resolve_materials_from_info(item_name, description, equip_slot, item_id)
	return materials

func get_material_name() -> String:
	var mats := get_materials()
	if not mats.is_empty():
		return ", ".join(mats)
	if not material_name.is_empty():
		return material_name
	return "Misc"

func calculate_synthesis_result(mat_a_rank: int, mat_b_rank: int, catalyst_tier: int) -> Dictionary:
	var base_rank: int = int((mat_a_rank + mat_b_rank) / 2.0) + catalyst_tier
	var min_rank: int = maxi(1, base_rank - 1)
	var max_rank: int = base_rank + 2

	var calc_rate: float = 0.90 - (float(base_rank) * 0.03) + (float(catalyst_tier) * 0.10)
	var success_rate: float = snappedf(clampf(calc_rate, 0.15, 0.95), 0.01)
	var success_percentage: int = int(round(success_rate * 100.0))

	return {
		"mat_a_rank": mat_a_rank,
		"mat_b_rank": mat_b_rank,
		"catalyst_tier": catalyst_tier,
		"base_rank": base_rank,
		"min_rank": min_rank,
		"max_rank": max_rank,
		"success_rate": success_rate,
		"success_percentage": success_percentage,
		"rank_range_str": "Rank %d ~ %d" % [min_rank, max_rank]
	}

func apply_preset(preset_name: String) -> bool:
	if not PRESETS.has(preset_name):
		push_error("[ItemEditor] Unknown preset: " + preset_name)
		return false

	var p: Dictionary = PRESETS[preset_name]
	item_id = int(p.get("item_id", 0))
	item_name = str(p.get("item_name", ""))
	description = str(p.get("description", ""))
	icon_id = int(p.get("icon_id", 0))
	level_req = int(p.get("level_req", 1))
	rank = int(p.get("rank", 1))
	durability = int(p.get("durability", 50))
	max_durability = int(p.get("max_durability", 50))
	equip_slot = int(p.get("equip_slot", EquipSlot.NONE))
	buy_price = int(p.get("buy_price", 0))
	sell_price = int(p.get("sell_price", 0))

	atk = int(p.get("atk", 0))
	def = int(p.get("def", 0))
	matk = int(p.get("matk", 0))
	mdef = int(p.get("mdef", 0))
	spd = int(p.get("spd", 0))
	hp_bonus = int(p.get("hp_bonus", 0))
	sp_bonus = int(p.get("sp_bonus", 0))

	alchemy_recipe_name = "%s Synthesis" % item_name
	alchemy_mat_a_id = item_id
	alchemy_mat_a_rank = rank
	alchemy_mat_b_id = item_id
	alchemy_mat_b_rank = rank
	alchemy_catalyst_tier = 0

	materials.clear()
	material_name = ""

	sync_to_ui()
	update_all_previews()
	preset_applied.emit(preset_name)
	_set_status("Loaded preset: %s" % preset_name)
	return true

func reset_to_blank() -> void:
	item_id = 10000
	item_name = "New Item"
	description = "A newly authored Wonderland Online item."
	icon_id = 1000
	level_req = 1
	rank = 1
	materials.clear()
	material_name = ""
	durability = 50
	max_durability = 50
	equip_slot = EquipSlot.NONE
	buy_price = 100
	sell_price = 50

	atk = 0
	def = 0
	matk = 0
	mdef = 0
	spd = 0
	hp_bonus = 0
	sp_bonus = 0

	alchemy_recipe_name = "New Synthesis Recipe"
	alchemy_mat_a_id = 10000
	alchemy_mat_a_rank = 1
	alchemy_mat_b_id = 10000
	alchemy_mat_b_rank = 1
	alchemy_catalyst_tier = 0

	sync_to_ui()
	update_all_previews()
	_set_status("Reset editor to blank item.")

func create_item_record() -> Dictionary:
	sync_from_ui()
	return {
		"item_id": item_id,
		"item_name": item_name,
		"materials": get_materials(),
		"material_name": get_material_name(),
		"description": description,
		"icon_id": icon_id,
		"level_req": level_req,
		"rank": rank,
		"durability": durability,
		"max_durability": max_durability,
		"equip_slot": equip_slot,
		"equip_slot_name": get_equip_slot_name(equip_slot),
		"buy_price": buy_price,
		"sell_price": sell_price,
		"stats": {
			"atk": atk,
			"def": def,
			"matk": matk,
			"mdef": mdef,
			"spd": spd,
			"hp_bonus": hp_bonus,
			"sp_bonus": sp_bonus
		},
		"formatted_stats": get_formatted_stats()
	}

func load_item_data(data: Dictionary) -> void:
	item_id = int(data.get("item_id", item_id))
	item_name = str(data.get("item_name", item_name))
	description = str(data.get("description", description))
	icon_id = int(data.get("icon_id", icon_id))
	level_req = int(data.get("level_req", level_req))
	rank = int(data.get("rank", rank))
	durability = int(data.get("durability", durability))
	max_durability = int(data.get("max_durability", max_durability))
	equip_slot = int(data.get("equip_slot", equip_slot))
	buy_price = int(data.get("buy_price", buy_price))
	sell_price = int(data.get("sell_price", sell_price))

	if data.has("materials") and data["materials"] is Array:
		materials = []
		for m in data["materials"]:
			materials.append(str(m))
		material_name = ", ".join(materials)
	elif data.has("material_name"):
		material_name = str(data["material_name"])
		materials = []
		for m in material_name.split(","):
			var trimmed := m.strip_edges()
			if not trimmed.is_empty():
				materials.append(trimmed)
	else:
		materials.clear()
		material_name = ""

	var stats_dict: Dictionary = data.get("stats", {})
	if not stats_dict.is_empty():
		atk = int(stats_dict.get("atk", 0))
		def = int(stats_dict.get("def", 0))
		matk = int(stats_dict.get("matk", 0))
		mdef = int(stats_dict.get("mdef", 0))
		spd = int(stats_dict.get("spd", 0))
		hp_bonus = int(stats_dict.get("hp_bonus", 0))
		sp_bonus = int(stats_dict.get("sp_bonus", 0))

	sync_to_ui()
	update_all_previews()
	item_loaded.emit(item_id)

func save_item_json(path: String) -> bool:
	var record := create_item_record()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[ItemEditor] Failed to open file for writing: " + path)
		return false
	file.store_string(JSON.stringify(record, "\t"))
	file.close()
	item_saved.emit(item_id, path)
	return true

func load_item_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[ItemEditor] Failed to open file for reading: " + path)
		return {}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("[ItemEditor] Failed to parse JSON from: %s (err: %s)" % [path, json.get_error_message()])
		return {}
	var data: Variant = json.data
	if not (data is Dictionary):
		push_error("[ItemEditor] JSON root is not Dictionary: " + path)
		return {}

	load_item_data(data)
	return data

func export_recipe_json(path: String) -> bool:
	sync_from_ui()
	var result_data := calculate_synthesis_result(alchemy_mat_a_rank, alchemy_mat_b_rank, alchemy_catalyst_tier)
	var recipe_dict := {
		"recipe_name": alchemy_recipe_name,
		"material_a": {
			"item_id": alchemy_mat_a_id,
			"rank": alchemy_mat_a_rank
		},
		"material_b": {
			"item_id": alchemy_mat_b_id,
			"rank": alchemy_mat_b_rank
		},
		"catalyst_tier": alchemy_catalyst_tier,
		"synthesis_result": result_data,
		"target_item_id": item_id,
		"target_item_name": item_name
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[ItemEditor] Failed to open file for writing recipe: " + path)
		return false
	file.store_string(JSON.stringify(recipe_dict, "\t"))
	file.close()
	recipe_exported.emit(path)
	return true

# --- Live Previews ---

func update_all_previews() -> void:
	update_icon_preview()
	update_stats_summary()
	update_synthesis_preview()
	update_tooltip_preview()

func update_icon_preview() -> void:
	if not rect_icon_preview:
		return

	var icon_tex: Texture2D = null
	var arch_loader: Node = null
	if Engine.has_singleton("ArchiveLoader"):
		arch_loader = Engine.get_singleton("ArchiveLoader")
	elif is_inside_tree() and get_tree() and get_tree().root.has_node("ArchiveLoader"):
		arch_loader = get_tree().root.get_node("ArchiveLoader")

	if arch_loader and arch_loader.has_method("get_item_icon"):
		icon_tex = arch_loader.get_item_icon(icon_id)

	if not icon_tex:
		icon_tex = _generate_fallback_icon(icon_id, equip_slot)

	rect_icon_preview.texture = icon_tex

func _generate_fallback_icon(id: int, slot: int) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var base_col := Color(0.15, 0.2, 0.28, 1.0)
	var border_col := Color(0.35, 0.55, 0.8, 1.0)

	match slot:
		EquipSlot.WEAPON:
			base_col = Color(0.25, 0.15, 0.15, 1.0)
			border_col = Color(0.85, 0.4, 0.3, 1.0)
		EquipSlot.CLOTHES:
			base_col = Color(0.15, 0.22, 0.3, 1.0)
			border_col = Color(0.4, 0.65, 0.9, 1.0)
		EquipSlot.SHOES:
			base_col = Color(0.12, 0.25, 0.2, 1.0)
			border_col = Color(0.35, 0.8, 0.6, 1.0)
		EquipSlot.CONSUMABLE:
			base_col = Color(0.25, 0.1, 0.25, 1.0)
			border_col = Color(0.85, 0.45, 0.85, 1.0)

	img.fill(base_col)

	# 1px border
	for x in range(32):
		img.set_pixel(x, 0, border_col)
		img.set_pixel(x, 31, border_col)
	for y in range(32):
		img.set_pixel(0, y, border_col)
		img.set_pixel(31, y, border_col)

	# Cross pattern based on id
	var seed_val: int = absi(id) % 8 + 4
	for i in range(seed_val, 32 - seed_val):
		img.set_pixel(i, 16, border_col)
		img.set_pixel(16, i, border_col)

	return ImageTexture.create_from_image(img)

func update_stats_summary() -> void:
	if not lbl_stats_summary:
		return
	var formatted := get_formatted_stats()
	if formatted.is_empty():
		lbl_stats_summary.text = "No stat modifiers active"
		lbl_stats_summary.modulate = Color(0.65, 0.7, 0.75, 1.0)
	else:
		var stat_strings: Array[String] = []
		for s in formatted:
			stat_strings.append(str(s["text"]))
		lbl_stats_summary.text = " | ".join(stat_strings)
		lbl_stats_summary.modulate = Color(0.4, 0.9, 0.5, 1.0)

func update_synthesis_preview() -> void:
	var result := calculate_synthesis_result(alchemy_mat_a_rank, alchemy_mat_b_rank, alchemy_catalyst_tier)
	if lbl_synth_base_rank:
		lbl_synth_base_rank.text = "Base Rank: %d" % result["base_rank"]
	if lbl_synth_rank_range:
		lbl_synth_rank_range.text = "Expected Range: Rank %d ~ %d" % [result["min_rank"], result["max_rank"]]
	if lbl_synth_success_rate:
		lbl_synth_success_rate.text = "Success Rate: %d%%" % result["success_percentage"]
	if bar_synth_success:
		bar_synth_success.value = result["success_percentage"]

func update_tooltip_preview() -> void:
	if not panel_tooltip:
		return

	if lbl_tt_title:
		lbl_tt_title.text = item_name
	if lbl_tt_slot:
		var mat_name := get_material_name()
		lbl_tt_slot.text = "Type: %s | Material: %s | Rank: %d" % [get_equip_slot_name(equip_slot), mat_name, rank]
	if lbl_tt_level:
		lbl_tt_level.text = "Req Level: %d" % level_req
	if lbl_tt_durability:
		lbl_tt_durability.text = "Durability: %d / %d" % [durability, max_durability]
	if lbl_tt_desc:
		lbl_tt_desc.text = description
	if lbl_tt_prices:
		lbl_tt_prices.text = "Buy: %d G  |  Sell: %d G" % [buy_price, sell_price]

	if lbl_tt_stats:
		var formatted := get_formatted_stats()
		if formatted.is_empty():
			lbl_tt_stats.text = "None"
			lbl_tt_stats.modulate = Color(0.4, 0.4, 0.4, 1.0)
		else:
			var lines: Array[String] = []
			for s in formatted:
				lines.append(str(s["text"]))
			lbl_tt_stats.text = "\n".join(lines)
			lbl_tt_stats.modulate = Color(0.1, 0.45, 0.2, 1.0)

func _set_status(msg: String) -> void:
	if lbl_status:
		lbl_status.text = msg
	print("[ItemEditor] " + msg)
