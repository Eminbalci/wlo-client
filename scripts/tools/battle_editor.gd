class_name BattleEditor
extends Control

## Wonderland Online - Battle Formation & Random Encounter Studio Tool.
## Provides an authentic WLO 2:1 axonometric battle field grid authoring interface,
## 8-slot player and 8-slot enemy troop placement, encounter table management,
## turn-order SPD sorting, loot drop table configuration, and Godot 4 scene exporter.

# --- Signals ---
signal slot_selected(is_enemy: bool, slot: int)
signal slot_changed(is_enemy: bool, slot: int, data: Dictionary)
signal preset_applied(preset_name: String)
signal encounter_rolled(result: Dictionary)
signal loot_rolled(drops: Array[Dictionary])
signal table_saved(path: String)
signal table_loaded(path: String)
signal scene_exported(path: String)

# --- Grid & Geometry Constants ---
const TOTAL_SLOTS: int = 8
const FRONT_ROW_COUNT: int = 4
const BACK_ROW_COUNT: int = 4

const CANVAS_BASE_SIZE: Vector2 = Vector2(580.0, 380.0)
const DIAMOND_HALF_WIDTH: float = 24.0
const DIAMOND_HALF_HEIGHT: float = 12.0 # Exact 2:1 axonometric ratio (48x24)

# Grid Layout Offsets (2:1 Axonometric projection)
# Player Slots (Facing North-East):
# Front row (0..3): starts at (110, 210), step = (44, 22)
# Back row (4..7): starts at (66, 240), step = (44, 22)
const PLAYER_FRONT_START: Vector2 = Vector2(110.0, 210.0)
const PLAYER_BACK_START: Vector2 = Vector2(66.0, 240.0)
const PLAYER_STEP: Vector2 = Vector2(44.0, 22.0)

# Enemy Slots (Facing South-West):
# Front row (0..3): starts at (350, 170), step = (44, 22)
# Back row (4..7): starts at (394, 140), step = (44, 22)
const ENEMY_FRONT_START: Vector2 = Vector2(350.0, 170.0)
const ENEMY_BACK_START: Vector2 = Vector2(394.0, 140.0)
const ENEMY_STEP: Vector2 = Vector2(44.0, 22.0)

# --- Element System ---
enum Element {
	NONE = 0,
	EARTH = 1,
	WATER = 2,
	FIRE = 3,
	WIND = 4
}

const ELEMENT_NAMES: Array[String] = [
	"None",
	"Earth",
	"Water",
	"Fire",
	"Wind"
]

const ELEMENT_COLORS: Array[Color] = [
	Color(0.7, 0.7, 0.7, 1.0),       # None: Grey
	Color(0.85, 0.65, 0.25, 1.0),    # Earth: Ochre / Yellow
	Color(0.25, 0.65, 0.95, 1.0),    # Water: Cyan / Blue
	Color(0.95, 0.35, 0.25, 1.0),    # Fire: Crimson / Red
	Color(0.35, 0.95, 0.45, 1.0)     # Wind: Emerald / Green
]

# --- Authentic WLO Party Formation Presets ---
const FORMATION_PRESETS: Dictionary = {
	"Kelan Slimes Troop": {
		"description": "2x Blue Jelly Level 1 in front, 1x Green Jelly Level 2 in back",
		"enemies": {
			0: {
				"monster_id": 101,
				"monster_name": "Blue Jelly",
				"level": 1,
				"hp": 45,
				"max_hp": 45,
				"sp": 15,
				"max_sp": 15,
				"element": Element.WATER,
				"jmp_name": "slime_blue.jmp",
				"is_boss": false,
				"spd": 8
			},
			1: {
				"monster_id": 101,
				"monster_name": "Blue Jelly",
				"level": 1,
				"hp": 45,
				"max_hp": 45,
				"sp": 15,
				"max_sp": 15,
				"element": Element.WATER,
				"jmp_name": "slime_blue.jmp",
				"is_boss": false,
				"spd": 8
			},
			4: {
				"monster_id": 102,
				"monster_name": "Green Jelly",
				"level": 2,
				"hp": 70,
				"max_hp": 70,
				"sp": 25,
				"max_sp": 25,
				"element": Element.EARTH,
				"jmp_name": "slime_green.jmp",
				"is_boss": false,
				"spd": 6
			}
		}
	},
	"Kelan Cave Bats": {
		"description": "3x Cave Bats Level 3 in front, 1x Leader Bat Level 5 in back",
		"enemies": {
			0: {
				"monster_id": 201,
				"monster_name": "Cave Bat",
				"level": 3,
				"hp": 95,
				"max_hp": 95,
				"sp": 30,
				"max_sp": 30,
				"element": Element.WIND,
				"jmp_name": "cave_bat.jmp",
				"is_boss": false,
				"spd": 14
			},
			1: {
				"monster_id": 201,
				"monster_name": "Cave Bat",
				"level": 3,
				"hp": 95,
				"max_hp": 95,
				"sp": 30,
				"max_sp": 30,
				"element": Element.WIND,
				"jmp_name": "cave_bat.jmp",
				"is_boss": false,
				"spd": 14
			},
			2: {
				"monster_id": 201,
				"monster_name": "Cave Bat",
				"level": 3,
				"hp": 95,
				"max_hp": 95,
				"sp": 30,
				"max_sp": 30,
				"element": Element.WIND,
				"jmp_name": "cave_bat.jmp",
				"is_boss": false,
				"spd": 14
			},
			4: {
				"monster_id": 205,
				"monster_name": "Leader Bat",
				"level": 5,
				"hp": 190,
				"max_hp": 190,
				"sp": 60,
				"max_sp": 60,
				"element": Element.FIRE,
				"jmp_name": "leader_bat.jmp",
				"is_boss": true,
				"spd": 18
			}
		}
	},
	"Shipwreck Pirates": {
		"description": "4x Sailor Pirates Level 8 in front, 1x Pirate Captain Boss Level 12 in back",
		"enemies": {
			0: {
				"monster_id": 301,
				"monster_name": "Sailor Pirate",
				"level": 8,
				"hp": 240,
				"max_hp": 240,
				"sp": 80,
				"max_sp": 80,
				"element": Element.WATER,
				"jmp_name": "pirate_sailor.jmp",
				"is_boss": false,
				"spd": 12
			},
			1: {
				"monster_id": 301,
				"monster_name": "Sailor Pirate",
				"level": 8,
				"hp": 240,
				"max_hp": 240,
				"sp": 80,
				"max_sp": 80,
				"element": Element.WATER,
				"jmp_name": "pirate_sailor.jmp",
				"is_boss": false,
				"spd": 12
			},
			2: {
				"monster_id": 301,
				"monster_name": "Sailor Pirate",
				"level": 8,
				"hp": 240,
				"max_hp": 240,
				"sp": 80,
				"max_sp": 80,
				"element": Element.WATER,
				"jmp_name": "pirate_sailor.jmp",
				"is_boss": false,
				"spd": 12
			},
			3: {
				"monster_id": 301,
				"monster_name": "Sailor Pirate",
				"level": 8,
				"hp": 240,
				"max_hp": 240,
				"sp": 80,
				"max_sp": 80,
				"element": Element.WATER,
				"jmp_name": "pirate_sailor.jmp",
				"is_boss": false,
				"spd": 12
			},
			5: {
				"monster_id": 310,
				"monster_name": "Pirate Captain",
				"level": 12,
				"hp": 850,
				"max_hp": 850,
				"sp": 250,
				"max_sp": 250,
				"element": Element.FIRE,
				"jmp_name": "pirate_captain.jmp",
				"is_boss": true,
				"spd": 22
			}
		}
	}
}

const KNOWN_MAPS: Dictionary = {
	10003: "Newbie Beach",
	11016: "Kelan Trail",
	10001: "Ship Deck",
	10002: "Ship Cabin",
	10011: "Kelan Beach"
}

# --- Editor State Variables ---
var map_id: int = 10003
var map_name: String = "Newbie Beach"
var encounter_rate_pct: float = 15.0

var player_slots: Array[Dictionary] = []
var enemy_slots: Array[Dictionary] = []
var encounter_groups: Array[Dictionary] = []
var loot_drops: Array[Dictionary] = []

var selected_is_enemy: bool = true
var selected_slot: int = 0
var hovered_is_enemy: bool = false
var hovered_slot: int = -1

var _custom_presets: Dictionary = {}

# --- Node References (UI) ---
@onready var battle_canvas: Control = get_node_or_null("%BattleCanvas")
@onready var opt_map: OptionButton = get_node_or_null("%OptMap")
@onready var spin_map_id: SpinBox = get_node_or_null("%SpinMapId")
@onready var edit_map_name: LineEdit = get_node_or_null("%EditMapName")
@onready var spin_enc_rate: SpinBox = get_node_or_null("%SpinEncRate")
@onready var slider_enc_rate: HSlider = get_node_or_null("%SliderEncRate")
@onready var opt_preset: OptionButton = get_node_or_null("%OptPreset")
@onready var btn_apply_preset: Button = get_node_or_null("%BtnApplyPreset")
@onready var btn_clear_arena: Button = get_node_or_null("%BtnClearArena")

# Slot Inspector Nodes
@onready var chk_inspector_is_enemy: CheckBox = get_node_or_null("%ChkInspectorIsEnemy")
@onready var spin_slot_idx: SpinBox = get_node_or_null("%SpinSlotIdx")
@onready var spin_monster_id: SpinBox = get_node_or_null("%SpinMonsterId")
@onready var edit_monster_name: LineEdit = get_node_or_null("%EditMonsterName")
@onready var spin_level: SpinBox = get_node_or_null("%SpinLevel")
@onready var spin_hp: SpinBox = get_node_or_null("%SpinHp")
@onready var spin_sp: SpinBox = get_node_or_null("%SpinSp")
@onready var spin_spd: SpinBox = get_node_or_null("%SpinSpd")
@onready var opt_element: OptionButton = get_node_or_null("%OptElement")
@onready var edit_jmp: LineEdit = get_node_or_null("%EditJmp")
@onready var chk_is_boss: CheckBox = get_node_or_null("%ChkIsBoss")
@onready var btn_save_slot: Button = get_node_or_null("%BtnSaveSlot")
@onready var btn_delete_slot: Button = get_node_or_null("%BtnDeleteSlot")

# Tab Containers & Sub-lists
@onready var list_turn_order: ItemList = get_node_or_null("%ListTurnOrder")
@onready var list_groups: ItemList = get_node_or_null("%ListGroups")
@onready var edit_group_name: LineEdit = get_node_or_null("%EditGroupName")
@onready var spin_group_weight: SpinBox = get_node_or_null("%SpinGroupWeight")
@onready var btn_add_group: Button = get_node_or_null("%BtnAddGroup")
@onready var btn_remove_group: Button = get_node_or_null("%BtnRemoveGroup")
@onready var btn_roll_encounter: Button = get_node_or_null("%BtnRollEncounter")
@onready var lbl_encounter_result: Label = get_node_or_null("%LblEncounterResult")

# Loot Drops Tab
@onready var list_loot: ItemList = get_node_or_null("%ListLoot")
@onready var spin_drop_item_id: SpinBox = get_node_or_null("%SpinDropItemId")
@onready var edit_drop_item_name: LineEdit = get_node_or_null("%EditDropItemName")
@onready var spin_drop_rate: SpinBox = get_node_or_null("%SpinDropRate")
@onready var spin_drop_min_qty: SpinBox = get_node_or_null("%SpinDropMinQty")
@onready var spin_drop_max_qty: SpinBox = get_node_or_null("%SpinDropMaxQty")
@onready var btn_add_drop: Button = get_node_or_null("%BtnAddDrop")
@onready var btn_remove_drop: Button = get_node_or_null("%BtnRemoveDrop")
@onready var btn_roll_loot: Button = get_node_or_null("%BtnRollLoot")
@onready var lbl_loot_result: Label = get_node_or_null("%LblLootResult")

# Top & Bottom Toolbars
@onready var btn_new_table: Button = get_node_or_null("%BtnNewTable")
@onready var btn_load_table: Button = get_node_or_null("%BtnLoadTable")
@onready var btn_save_table: Button = get_node_or_null("%BtnSaveTable")
@onready var btn_export_scene: Button = get_node_or_null("%BtnExportScene")
@onready var status_readout: Label = get_node_or_null("%StatusReadout")
@onready var map_readout: Label = get_node_or_null("%MapReadout")
@onready var participant_readout: Label = get_node_or_null("%ParticipantReadout")

func _init() -> void:
	_init_slots()

func _ready() -> void:
	_setup_ui_elements()
	_populate_default_sample_data()
	_sync_all_views()

func _init_slots() -> void:
	player_slots.clear()
	enemy_slots.clear()
	for i in range(TOTAL_SLOTS):
		player_slots.append({})
		enemy_slots.append({})

func _setup_ui_elements() -> void:
	if battle_canvas:
		if not battle_canvas.draw.is_connected(_on_canvas_draw):
			battle_canvas.draw.connect(_on_canvas_draw)
		if not battle_canvas.gui_input.is_connected(_on_canvas_gui_input):
			battle_canvas.gui_input.connect(_on_canvas_gui_input)
		battle_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if opt_map:
		opt_map.clear()
		for mid in KNOWN_MAPS.keys():
			opt_map.add_item("%d: %s" % [mid, KNOWN_MAPS[mid]], mid)
		opt_map.item_selected.connect(_on_map_preset_selected)
	
	if opt_preset:
		opt_preset.clear()
		for p_name in FORMATION_PRESETS.keys():
			opt_preset.add_item(p_name)
		if btn_apply_preset:
			btn_apply_preset.pressed.connect(_on_apply_preset_pressed)
	
	if opt_element:
		opt_element.clear()
		for idx in range(ELEMENT_NAMES.size()):
			opt_element.add_item(ELEMENT_NAMES[idx], idx)
	
	if spin_enc_rate and slider_enc_rate:
		spin_enc_rate.value = encounter_rate_pct
		slider_enc_rate.value = encounter_rate_pct
		spin_enc_rate.value_changed.connect(func(val: float) -> void:
			encounter_rate_pct = val
			if slider_enc_rate and slider_enc_rate.value != val:
				slider_enc_rate.value = val
			_update_status_bar()
		)
		slider_enc_rate.value_changed.connect(func(val: float) -> void:
			encounter_rate_pct = val
			if spin_enc_rate and spin_enc_rate.value != val:
				spin_enc_rate.value = val
			_update_status_bar()
		)
	
	if spin_map_id:
		spin_map_id.value = map_id
		spin_map_id.value_changed.connect(func(val: float) -> void:
			map_id = int(val)
			if KNOWN_MAPS.has(map_id):
				map_name = KNOWN_MAPS[map_id]
				if edit_map_name:
					edit_map_name.text = map_name
			_update_status_bar()
		)
	
	if edit_map_name:
		edit_map_name.text = map_name
		edit_map_name.text_changed.connect(func(txt: String) -> void:
			map_name = txt
			_update_status_bar()
		)
	
	if btn_save_slot:
		btn_save_slot.pressed.connect(_on_save_slot_clicked)
	if btn_delete_slot:
		btn_delete_slot.pressed.connect(_on_delete_slot_clicked)
	if btn_clear_arena:
		btn_clear_arena.pressed.connect(func() -> void:
			clear_all_slots()
			_sync_all_views()
		)
	
	if btn_add_group:
		btn_add_group.pressed.connect(_on_add_group_clicked)
	if btn_remove_group:
		btn_remove_group.pressed.connect(_on_remove_group_clicked)
	if btn_roll_encounter:
		btn_roll_encounter.pressed.connect(_on_roll_encounter_clicked)
	
	if btn_add_drop:
		btn_add_drop.pressed.connect(_on_add_drop_clicked)
	if btn_remove_drop:
		btn_remove_drop.pressed.connect(_on_remove_drop_clicked)
	if btn_roll_loot:
		btn_roll_loot.pressed.connect(_on_roll_loot_clicked)
	
	if btn_new_table:
		btn_new_table.pressed.connect(func() -> void:
			_init_slots()
			encounter_groups.clear()
			loot_drops.clear()
			_populate_default_sample_data()
			_sync_all_views()
		)
	if btn_save_table:
		btn_save_table.pressed.connect(func() -> void:
			var save_path: String = "user://encounter_map_%d.json" % map_id
			save_encounter_table(save_path)
		)
	if btn_load_table:
		btn_load_table.pressed.connect(func() -> void:
			var load_path: String = "user://encounter_map_%d.json" % map_id
			load_encounter_table(load_path)
		)
	if btn_export_scene:
		btn_export_scene.pressed.connect(func() -> void:
			var scene_path: String = "user://battle_scene_map_%d.tscn" % map_id
			export_battle_scene(scene_path)
		)

func _populate_default_sample_data() -> void:
	# Default player party in slots 0 and 1
	set_player_slot(0, {
		"monster_id": 1,
		"monster_name": "Daniel (Hero)",
		"level": 10,
		"hp": 320,
		"max_hp": 320,
		"sp": 140,
		"max_sp": 140,
		"element": Element.FIRE,
		"jmp_name": "hero_fire.jmp",
		"is_boss": false,
		"spd": 15
	})
	set_player_slot(1, {
		"monster_id": 2,
		"monster_name": "Betty (Mage)",
		"level": 10,
		"hp": 260,
		"max_hp": 260,
		"sp": 220,
		"max_sp": 220,
		"element": Element.WATER,
		"jmp_name": "mage_water.jmp",
		"is_boss": false,
		"spd": 11
	})
	
	# Load standard starter preset for enemies
	load_formation_preset("Kelan Slimes Troop")
	
	# Add default encounter groups for Newbie Beach
	encounter_groups = [
		{
			"group_id": 1,
			"group_name": "Kelan Slimes Troop",
			"weight": 60,
			"formation": FORMATION_PRESETS["Kelan Slimes Troop"]["enemies"]
		},
		{
			"group_id": 2,
			"group_name": "Kelan Cave Bats",
			"weight": 30,
			"formation": FORMATION_PRESETS["Kelan Cave Bats"]["enemies"]
		},
		{
			"group_id": 3,
			"group_name": "Shipwreck Pirates Patrol",
			"weight": 10,
			"formation": FORMATION_PRESETS["Shipwreck Pirates"]["enemies"]
		}
	]
	
	# Add default loot drops
	loot_drops = [
		{
			"item_id": 11001,
			"item_name": "Jelly Mucus",
			"drop_rate_pct": 75.0,
			"min_qty": 1,
			"max_qty": 2
		},
		{
			"item_id": 11005,
			"item_name": "Small HP Potion",
			"drop_rate_pct": 40.0,
			"min_qty": 1,
			"max_qty": 1
		},
		{
			"item_id": 22010,
			"item_name": "Bat Wing",
			"drop_rate_pct": 25.0,
			"min_qty": 1,
			"max_qty": 3
		},
		{
			"item_id": 31050,
			"item_name": "Pirate Dagger",
			"drop_rate_pct": 5.0,
			"min_qty": 1,
			"max_qty": 1
		}
	]

# --- 2:1 Axonometric Grid Geometry Methods ---

func get_slot_screen_position(is_enemy: bool, slot: int) -> Vector2:
	var safe_slot: int = clampi(slot, 0, TOTAL_SLOTS - 1)
	var is_front: bool = safe_slot < FRONT_ROW_COUNT
	var col: int = safe_slot % FRONT_ROW_COUNT
	
	if is_enemy:
		var start: Vector2 = ENEMY_FRONT_START if is_front else ENEMY_BACK_START
		return start + Vector2(col * ENEMY_STEP.x, col * ENEMY_STEP.y)
	else:
		var start: Vector2 = PLAYER_FRONT_START if is_front else PLAYER_BACK_START
		return start + Vector2(col * PLAYER_STEP.x, col * PLAYER_STEP.y)

func get_slot_polygon(is_enemy: bool, slot: int) -> PackedVector2Array:
	var center: Vector2 = get_slot_screen_position(is_enemy, slot)
	var hw: float = DIAMOND_HALF_WIDTH
	var hh: float = DIAMOND_HALF_HEIGHT
	
	return PackedVector2Array([
		Vector2(center.x, center.y - hh),     # Top
		Vector2(center.x + hw, center.y),      # Right
		Vector2(center.x, center.y + hh),     # Bottom
		Vector2(center.x - hw, center.y)       # Left
	])

func find_slot_at_point(point: Vector2) -> Dictionary:
	var hw: float = DIAMOND_HALF_WIDTH
	var hh: float = DIAMOND_HALF_HEIGHT
	
	# Check Enemy Slots first (render order)
	for slot in range(TOTAL_SLOTS):
		var center: Vector2 = get_slot_screen_position(true, slot)
		var dx: float = absf(point.x - center.x) / hw
		var dy: float = absf(point.y - center.y) / hh
		if (dx + dy) <= 1.05: # Slight tolerance for responsive clicking
			return {"found": true, "is_enemy": true, "slot": slot}
			
	# Check Player Slots
	for slot in range(TOTAL_SLOTS):
		var center: Vector2 = get_slot_screen_position(false, slot)
		var dx: float = absf(point.x - center.x) / hw
		var dy: float = absf(point.y - center.y) / hh
		if (dx + dy) <= 1.05:
			return {"found": true, "is_enemy": false, "slot": slot}
			
	return {"found": false, "is_enemy": false, "slot": -1}

# --- Slot Placement & Manipulation Methods ---

func set_enemy_slot(slot: int, monster_data: Dictionary) -> bool:
	if slot < 0 or slot >= TOTAL_SLOTS:
		push_warning("BattleEditor: Enemy slot out of range [0..%d]: %d" % [TOTAL_SLOTS - 1, slot])
		return false
	
	var clean: Dictionary = _normalize_participant_dict(monster_data)
	enemy_slots[slot] = clean
	slot_changed.emit(true, slot, clean)
	_sync_all_views()
	return true

func get_enemy_slot(slot: int) -> Dictionary:
	if slot < 0 or slot >= TOTAL_SLOTS:
		return {}
	return enemy_slots[slot].duplicate(true)

func set_player_slot(slot: int, player_data: Dictionary) -> bool:
	if slot < 0 or slot >= TOTAL_SLOTS:
		push_warning("BattleEditor: Player slot out of range [0..%d]: %d" % [TOTAL_SLOTS - 1, slot])
		return false
	
	var clean: Dictionary = _normalize_participant_dict(player_data)
	player_slots[slot] = clean
	slot_changed.emit(false, slot, clean)
	_sync_all_views()
	return true

func get_player_slot(slot: int) -> Dictionary:
	if slot < 0 or slot >= TOTAL_SLOTS:
		return {}
	return player_slots[slot].duplicate(true)

func clear_slot(is_enemy: bool, slot: int) -> void:
	if slot < 0 or slot >= TOTAL_SLOTS:
		return
	if is_enemy:
		enemy_slots[slot] = {}
	else:
		player_slots[slot] = {}
	slot_changed.emit(is_enemy, slot, {})
	_sync_all_views()

func clear_all_slots() -> void:
	for i in range(TOTAL_SLOTS):
		player_slots[i] = {}
		enemy_slots[i] = {}
	_sync_all_views()

func select_slot(is_enemy: bool, slot: int) -> void:
	selected_is_enemy = is_enemy
	selected_slot = clampi(slot, 0, TOTAL_SLOTS - 1)
	slot_selected.emit(selected_is_enemy, selected_slot)
	_sync_inspector_from_slot()
	if battle_canvas:
		battle_canvas.queue_redraw()

func _normalize_participant_dict(raw: Dictionary) -> Dictionary:
	var mid: int = int(raw.get("monster_id", 1))
	var mname: String = str(raw.get("monster_name", "Monster_%d" % mid))
	var lvl: int = maxi(1, int(raw.get("level", 1)))
	var hp_val: int = maxi(1, int(raw.get("hp", 100)))
	var max_hp_val: int = maxi(hp_val, int(raw.get("max_hp", hp_val)))
	var sp_val: int = maxi(0, int(raw.get("sp", 50)))
	var max_sp_val: int = maxi(sp_val, int(raw.get("max_sp", sp_val)))
	var elem: int = clampi(int(raw.get("element", Element.NONE)), 0, Element.WIND)
	var jmp: String = str(raw.get("jmp_name", "monster.jmp"))
	var boss: bool = bool(raw.get("is_boss", false))
	var spd_val: int = maxi(1, int(raw.get("spd", raw.get("agility", 10))))
	
	return {
		"monster_id": mid,
		"monster_name": mname,
		"level": lvl,
		"hp": hp_val,
		"max_hp": max_hp_val,
		"sp": sp_val,
		"max_sp": max_sp_val,
		"element": elem,
		"jmp_name": jmp,
		"is_boss": boss,
		"spd": spd_val
	}

# --- Preset Management ---

func get_preset_names() -> Array[String]:
	var names: Array[String] = []
	for k in FORMATION_PRESETS.keys():
		names.append(str(k))
	for ck in _custom_presets.keys():
		if not names.has(str(ck)):
			names.append(str(ck))
	return names

func load_formation_preset(preset_name: String) -> bool:
	var preset_data: Dictionary = {}
	if FORMATION_PRESETS.has(preset_name):
		preset_data = FORMATION_PRESETS[preset_name]
	elif _custom_presets.has(preset_name):
		preset_data = _custom_presets[preset_name]
	else:
		push_warning("BattleEditor: Preset not found: %s" % preset_name)
		return false
	
	# Clear existing enemy slots
	for i in range(TOTAL_SLOTS):
		enemy_slots[i] = {}
	
	var enemies: Dictionary = preset_data.get("enemies", {})
	for slot_key in enemies.keys():
		var slot_idx: int = int(slot_key)
		if slot_idx >= 0 and slot_idx < TOTAL_SLOTS:
			enemy_slots[slot_idx] = _normalize_participant_dict(enemies[slot_key])
	
	preset_applied.emit(preset_name)
	_sync_all_views()
	return true

func save_formation_preset(preset_name: String) -> void:
	var enemies_dict: Dictionary = {}
	for i in range(TOTAL_SLOTS):
		if not enemy_slots[i].is_empty():
			enemies_dict[i] = enemy_slots[i].duplicate(true)
	
	_custom_presets[preset_name] = {
		"description": "User created preset: %s" % preset_name,
		"enemies": enemies_dict
	}
	
	if opt_preset:
		opt_preset.clear()
		for p_name in get_preset_names():
			opt_preset.add_item(p_name)

# --- Turn Order / SPD Calculation ---

func calculate_turn_order() -> Array[Dictionary]:
	var participants: Array[Dictionary] = []
	
	for slot in range(TOTAL_SLOTS):
		if not player_slots[slot].is_empty():
			var p: Dictionary = player_slots[slot].duplicate(true)
			p["team"] = "player"
			p["slot"] = slot
			p["row"] = "Front" if slot < FRONT_ROW_COUNT else "Back"
			participants.append(p)
			
	for slot in range(TOTAL_SLOTS):
		if not enemy_slots[slot].is_empty():
			var e: Dictionary = enemy_slots[slot].duplicate(true)
			e["team"] = "enemy"
			e["slot"] = slot
			e["row"] = "Front" if slot < FRONT_ROW_COUNT else "Back"
			participants.append(e)
	
	# Sort descending by SPD; deterministic tie-breaker: player first, then slot index
	participants.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var spd_a: int = int(a.get("spd", 10))
		var spd_b: int = int(b.get("spd", 10))
		if spd_a != spd_b:
			return spd_a > spd_b
		# Tie-breaker: player precedes enemy
		var team_a: String = str(a.get("team", ""))
		var team_b: String = str(b.get("team", ""))
		if team_a != team_b:
			return team_a == "player"
		return int(a.get("slot", 0)) < int(b.get("slot", 0))
	)
	
	return participants

# --- Encounter Table Management ---

func add_encounter_group(group_data: Dictionary) -> int:
	var group_id: int = int(group_data.get("group_id", encounter_groups.size() + 1))
	var group_name: String = str(group_data.get("group_name", "Encounter Troop %d" % group_id))
	var weight: int = maxi(1, int(group_data.get("weight", 10)))
	var formation: Dictionary = group_data.get("formation", {})
	
	var clean_group: Dictionary = {
		"group_id": group_id,
		"group_name": group_name,
		"weight": weight,
		"formation": formation
	}
	encounter_groups.append(clean_group)
	_refresh_encounter_groups_ui()
	return encounter_groups.size() - 1

func remove_encounter_group(index: int) -> bool:
	if index < 0 or index >= encounter_groups.size():
		return false
	encounter_groups.remove_at(index)
	_refresh_encounter_groups_ui()
	return true

func get_encounter_groups() -> Array[Dictionary]:
	return encounter_groups.duplicate(true)

func clear_encounter_groups() -> void:
	encounter_groups.clear()
	_refresh_encounter_groups_ui()

func roll_random_encounter(step_roll: float = -1.0, group_roll: float = -1.0) -> Dictionary:
	var actual_step_roll: float = step_roll if step_roll >= 0.0 else randf() * 100.0
	
	if actual_step_roll > encounter_rate_pct:
		var miss_result: Dictionary = {
			"triggered": false,
			"reason": "Step roll (%.2f%%) exceeded encounter rate (%.2f%%)" % [actual_step_roll, encounter_rate_pct],
			"step_roll": actual_step_roll,
			"encounter_rate_pct": encounter_rate_pct
		}
		encounter_rolled.emit(miss_result)
		return miss_result
	
	if encounter_groups.is_empty():
		var empty_result: Dictionary = {
			"triggered": true,
			"reason": "Encounter triggered but group table is empty",
			"group": {},
			"step_roll": actual_step_roll,
			"encounter_rate_pct": encounter_rate_pct
		}
		encounter_rolled.emit(empty_result)
		return empty_result
	
	var total_weight: int = 0
	for g in encounter_groups:
		total_weight += int(g.get("weight", 10))
	
	if total_weight <= 0:
		total_weight = 1
	
	var actual_group_roll: float = group_roll if group_roll >= 0.0 else randf() * float(total_weight)
	var cumulative: float = 0.0
	var selected_group: Dictionary = encounter_groups[0]
	
	for g in encounter_groups:
		cumulative += float(g.get("weight", 10))
		if actual_group_roll <= cumulative:
			selected_group = g
			break
			
	var hit_result: Dictionary = {
		"triggered": true,
		"group": selected_group.duplicate(true),
		"group_name": selected_group.get("group_name", "Unknown Group"),
		"step_roll": actual_step_roll,
		"group_roll": actual_group_roll,
		"total_weight": total_weight,
		"encounter_rate_pct": encounter_rate_pct
	}
	encounter_rolled.emit(hit_result)
	return hit_result

# --- Loot Drop Table Management ---

func add_loot_drop(item_id: int, item_name: String, drop_rate_pct: float, min_qty: int = 1, max_qty: int = 1) -> void:
	var clean_drop: Dictionary = {
		"item_id": maxi(1, item_id),
		"item_name": item_name if not item_name.is_empty() else "Item_%d" % item_id,
		"drop_rate_pct": clampf(drop_rate_pct, 0.0, 100.0),
		"min_qty": maxi(1, min_qty),
		"max_qty": maxi(min_qty, max_qty)
	}
	loot_drops.append(clean_drop)
	_refresh_loot_drops_ui()

func remove_loot_drop(index: int) -> bool:
	if index < 0 or index >= loot_drops.size():
		return false
	loot_drops.remove_at(index)
	_refresh_loot_drops_ui()
	return true

func get_loot_drops() -> Array[Dictionary]:
	return loot_drops.duplicate(true)

func clear_loot_drops() -> void:
	loot_drops.clear()
	_refresh_loot_drops_ui()

func roll_loot_drops(rng_seed: int = -1) -> Array[Dictionary]:
	if rng_seed >= 0:
		seed(rng_seed)
		
	var rewarded: Array[Dictionary] = []
	for drop in loot_drops:
		var rate: float = float(drop.get("drop_rate_pct", 0.0))
		var roll: float = randf() * 100.0
		if roll <= rate:
			var min_q: int = int(drop.get("min_qty", 1))
			var max_q: int = int(drop.get("max_qty", 1))
			var qty: int = randi_range(min_q, max_q) if max_q > min_q else min_q
			rewarded.append({
				"item_id": int(drop.get("item_id", 0)),
				"item_name": str(drop.get("item_name", "Item")),
				"quantity": qty,
				"rolled_pct": roll,
				"target_rate_pct": rate
			})
			
	loot_rolled.emit(rewarded)
	return rewarded

# --- Serialization & Export Methods ---

func create_encounter_data() -> Dictionary:
	return {
		"format_version": "1.0",
		"map_id": map_id,
		"map_name": map_name,
		"encounter_rate_pct": encounter_rate_pct,
		"player_slots": player_slots.duplicate(true),
		"enemy_slots": enemy_slots.duplicate(true),
		"encounter_groups": encounter_groups.duplicate(true),
		"loot_drops": loot_drops.duplicate(true),
		"custom_presets": _custom_presets.duplicate(true),
		"metadata": {
			"editor": "BattleEditor",
			"engine": "Godot 4",
			"grid_type": "2:1 Axonometric",
			"timestamp": Time.get_datetime_string_from_system()
		}
	}

func save_encounter_table(path: String) -> bool:
	var data: Dictionary = create_encounter_data()
	var json_str: String = JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("BattleEditor: Failed to open path for writing: %s (Error: %d)" % [path, FileAccess.get_open_error()])
		return false
	
	file.store_string(json_str)
	file.close()
	table_saved.emit(path)
	if status_readout:
		status_readout.text = "Saved encounter table to: %s" % path
	return true

func load_encounter_table(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("BattleEditor: Encounter table file not found: %s" % path)
		return {}
		
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
		
	var content: String = file.get_as_text()
	file.close()
	
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		push_error("BattleEditor: Corrupt JSON format in: %s" % path)
		return {}
		
	var dict: Dictionary = parsed as Dictionary
	map_id = int(dict.get("map_id", 10003))
	map_name = str(dict.get("map_name", "Battle Map"))
	encounter_rate_pct = float(dict.get("encounter_rate_pct", 15.0))
	
	_init_slots()
	var p_slots: Array = dict.get("player_slots", [])
	for idx in range(mini(p_slots.size(), TOTAL_SLOTS)):
		if p_slots[idx] is Dictionary and not p_slots[idx].is_empty():
			player_slots[idx] = _normalize_participant_dict(p_slots[idx])
			
	var e_slots: Array = dict.get("enemy_slots", [])
	for idx in range(mini(e_slots.size(), TOTAL_SLOTS)):
		if e_slots[idx] is Dictionary and not e_slots[idx].is_empty():
			enemy_slots[idx] = _normalize_participant_dict(e_slots[idx])
			
	encounter_groups.clear()
	var groups: Array = dict.get("encounter_groups", [])
	for g in groups:
		if g is Dictionary:
			encounter_groups.append(g)
			
	loot_drops.clear()
	var drops: Array = dict.get("loot_drops", [])
	for d in drops:
		if d is Dictionary:
			loot_drops.append(d)
			
	_custom_presets = dict.get("custom_presets", {})
	
	table_loaded.emit(path)
	_sync_all_views()
	if status_readout:
		status_readout.text = "Loaded encounter table from: %s" % path
	return dict

func export_battle_scene(path: String) -> String:
	var scene_text: String = _generate_tscn_content()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("BattleEditor: Failed to export battle scene to %s (Error: %d)" % [path, FileAccess.get_open_error()])
		return ""
	
	file.store_string(scene_text)
	file.close()
	scene_exported.emit(path)
	if status_readout:
		status_readout.text = "Battle scene exported: %s" % path
	return path

func _generate_tscn_content() -> String:
	var lines: PackedStringArray = []
	lines.append("[gd_scene format=3 uid=\"uid://battle_scene_auto_%d\"]" % map_id)
	lines.append("")
	lines.append("[node name=\"BattleArena\" type=\"Node2D\"]")
	lines.append("metadata/map_id = %d" % map_id)
	lines.append("metadata/map_name = \"%s\"" % map_name)
	lines.append("metadata/encounter_rate = %f" % encounter_rate_pct)
	lines.append("")
	
	# Background
	lines.append("[node name=\"ArenaBackground\" type=\"ColorRect\" parent=\".\"]")
	lines.append("custom_minimum_size = Vector2(800, 600)")
	lines.append("offset_right = 800.0")
	lines.append("offset_bottom = 600.0")
	lines.append("color = Color(0.08, 0.11, 0.15, 1.0)")
	lines.append("")
	
	# Neutral dividing line
	lines.append("[node name=\"ArenaDividerLine\" type=\"Line2D\" parent=\".\"]")
	lines.append("points = PackedVector2Array(270, 110, 360, 330)")
	lines.append("width = 2.0")
	lines.append("default_color = Color(0.3, 0.45, 0.65, 0.4)")
	lines.append("")
	
	# Player formation
	lines.append("[node name=\"PlayerParty\" type=\"Node2D\" parent=\".\"]")
	lines.append("")
	for slot in range(TOTAL_SLOTS):
		var p_pos: Vector2 = get_slot_screen_position(false, slot)
		var p_data: Dictionary = player_slots[slot]
		var node_name: String = "Player_Slot_%d" % slot
		lines.append("[node name=\"%s\" type=\"Marker2D\" parent=\"PlayerParty\"]" % node_name)
		lines.append("position = Vector2(%.1f, %.1f)" % [p_pos.x, p_pos.y])
		lines.append("metadata/slot = %d" % slot)
		lines.append("metadata/row = \"%s\"" % ("Front" if slot < FRONT_ROW_COUNT else "Back"))
		if not p_data.is_empty():
			lines.append("metadata/occupied = true")
			lines.append("metadata/monster_id = %d" % int(p_data.get("monster_id", 0)))
			lines.append("metadata/monster_name = \"%s\"" % str(p_data.get("monster_name", "")))
			lines.append("metadata/level = %d" % int(p_data.get("level", 1)))
			lines.append("metadata/hp = %d" % int(p_data.get("hp", 100)))
			lines.append("metadata/sp = %d" % int(p_data.get("sp", 50)))
			lines.append("metadata/spd = %d" % int(p_data.get("spd", 10)))
			lines.append("metadata/element = %d" % int(p_data.get("element", 0)))
		else:
			lines.append("metadata/occupied = false")
		lines.append("")
		
	# Enemy formation
	lines.append("[node name=\"EnemyTroop\" type=\"Node2D\" parent=\".\"]")
	lines.append("")
	for slot in range(TOTAL_SLOTS):
		var e_pos: Vector2 = get_slot_screen_position(true, slot)
		var e_data: Dictionary = enemy_slots[slot]
		var node_name: String = "Enemy_Slot_%d" % slot
		lines.append("[node name=\"%s\" type=\"Marker2D\" parent=\"EnemyTroop\"]" % node_name)
		lines.append("position = Vector2(%.1f, %.1f)" % [e_pos.x, e_pos.y])
		lines.append("metadata/slot = %d" % slot)
		lines.append("metadata/row = \"%s\"" % ("Front" if slot < FRONT_ROW_COUNT else "Back"))
		if not e_data.is_empty():
			lines.append("metadata/occupied = true")
			lines.append("metadata/monster_id = %d" % int(e_data.get("monster_id", 0)))
			lines.append("metadata/monster_name = \"%s\"" % str(e_data.get("monster_name", "")))
			lines.append("metadata/level = %d" % int(e_data.get("level", 1)))
			lines.append("metadata/hp = %d" % int(e_data.get("hp", 100)))
			lines.append("metadata/sp = %d" % int(e_data.get("sp", 50)))
			lines.append("metadata/spd = %d" % int(e_data.get("spd", 10)))
			lines.append("metadata/element = %d" % int(e_data.get("element", 0)))
			lines.append("metadata/is_boss = %s" % ("true" if bool(e_data.get("is_boss", false)) else "false"))
		else:
			lines.append("metadata/occupied = false")
		lines.append("")
		
	# Battle Manager Node
	lines.append("[node name=\"TurnManager\" type=\"Node\" parent=\".\"]")
	var turn_order: Array[Dictionary] = calculate_turn_order()
	lines.append("metadata/participant_count = %d" % turn_order.size())
	lines.append("")
	
	return "\n".join(lines)

# --- Canvas Redraw & GUI Input Handling ---

func _on_canvas_draw() -> void:
	if not battle_canvas:
		return
		
	# Draw floor boundary / arena backing
	var canvas_rect: Rect2 = Rect2(Vector2.ZERO, battle_canvas.size)
	battle_canvas.draw_rect(canvas_rect, Color(0.06, 0.08, 0.12, 1.0))
	
	# Draw center diagonal neutral line
	battle_canvas.draw_line(Vector2(275.0, 110.0), Vector2(345.0, 310.0), Color(0.2, 0.35, 0.5, 0.4), 2.0)
	
	# Draw Side Headers
	battle_canvas.draw_string(ThemeDB.fallback_font, Vector2(100.0, 160.0), "PLAYER PARTY (FRONT/BACK)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 0.7, 1.0, 0.7))
	battle_canvas.draw_string(ThemeDB.fallback_font, Vector2(380.0, 100.0), "ENEMY TROOP (FRONT/BACK)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.4, 0.4, 0.7))
	
	# Draw Player Slots
	for slot in range(TOTAL_SLOTS):
		_draw_battle_slot(false, slot)
		
	# Draw Enemy Slots
	for slot in range(TOTAL_SLOTS):
		_draw_battle_slot(true, slot)

func _draw_battle_slot(is_enemy: bool, slot: int) -> void:
	var poly: PackedVector2Array = get_slot_polygon(is_enemy, slot)
	var center: Vector2 = get_slot_screen_position(is_enemy, slot)
	var is_selected: bool = (selected_is_enemy == is_enemy and selected_slot == slot)
	var is_hovered: bool = (hovered_is_enemy == is_enemy and hovered_slot == slot)
	
	var data: Dictionary = enemy_slots[slot] if is_enemy else player_slots[slot]
	var occupied: bool = not data.is_empty()
	var elem: int = int(data.get("element", Element.NONE)) if occupied else Element.NONE
	var elem_color: Color = ELEMENT_COLORS[elem]
	
	# Fill Color
	var fill_col: Color
	if occupied:
		fill_col = Color(elem_color.r, elem_color.g, elem_color.b, 0.35)
	else:
		fill_col = Color(0.12, 0.15, 0.22, 0.25)
	battle_canvas.draw_colored_polygon(poly, fill_col)
	
	# Border Color
	var border_col: Color
	var border_width: float = 1.0
	if is_selected:
		border_col = Color(1.0, 0.85, 0.2, 1.0) # Gold
		border_width = 2.5
	elif is_hovered:
		border_col = Color(0.3, 0.9, 1.0, 0.9)  # Cyan
		border_width = 1.8
	elif occupied:
		border_col = elem_color
		border_width = 1.5
	else:
		border_col = Color(0.25, 0.35, 0.45, 0.5)
		
	# Draw diamond outline
	var closed_poly: PackedVector2Array = poly.duplicate()
	closed_poly.append(poly[0])
	battle_canvas.draw_polyline(closed_poly, border_col, border_width)
	
	# Draw Occupant info or slot badge
	if occupied:
		var name_str: String = str(data.get("monster_name", "Unit"))
		var lvl: int = int(data.get("level", 1))
		var spd: int = int(data.get("spd", 10))
		var is_boss: bool = bool(data.get("is_boss", false))
		
		# Avatar Circle / Badge
		var badge_radius: float = 7.0 if not is_boss else 9.0
		battle_canvas.draw_circle(center, badge_radius, elem_color)
		battle_canvas.draw_circle(center, badge_radius - 1.5, Color(0.1, 0.1, 0.1, 0.9))
		
		# Boss Crown Indicator
		if is_boss:
			battle_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-6, -12), "★", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.85, 0.1, 1.0))
			
		# Text Label below diamond
		var label_text: String = "%s (L%d)" % [name_str, lvl]
		var text_col: Color = Color(1.0, 0.9, 0.4, 1.0) if is_boss else Color.WHITE
		battle_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-36, 22), label_text, HORIZONTAL_ALIGNMENT_LEFT, 72, 10, text_col)
		
		# Speed badge
		battle_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-20, 32), "SPD:%d" % spd, HORIZONTAL_ALIGNMENT_LEFT, 40, 9, Color(0.4, 0.85, 0.6, 0.9))
	else:
		# Empty slot badge
		var prefix: String = "E" if is_enemy else "P"
		var row_prefix: String = "F" if slot < FRONT_ROW_COUNT else "B"
		var slot_code: String = "%s-%s%d" % [prefix, row_prefix, slot % FRONT_ROW_COUNT]
		battle_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-12, 4), slot_code, HORIZONTAL_ALIGNMENT_CENTER, 24, 9, Color(0.4, 0.5, 0.6, 0.6))

func _on_canvas_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var hit: Dictionary = find_slot_at_point(mb.position)
			if hit["found"]:
				select_slot(hit["is_enemy"], hit["slot"])
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var hit_r: Dictionary = find_slot_at_point(mb.position)
			if hit_r["found"]:
				clear_slot(hit_r["is_enemy"], hit_r["slot"])
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var hit_m: Dictionary = find_slot_at_point(mm.position)
		if hit_m["found"]:
			if hovered_is_enemy != hit_m["is_enemy"] or hovered_slot != hit_m["slot"]:
				hovered_is_enemy = hit_m["is_enemy"]
				hovered_slot = hit_m["slot"]
				if battle_canvas:
					battle_canvas.queue_redraw()
		else:
			if hovered_slot != -1:
				hovered_slot = -1
				if battle_canvas:
					battle_canvas.queue_redraw()

# --- UI Synchronizers & Event Callbacks ---

func _sync_all_views() -> void:
	_sync_inspector_from_slot()
	_refresh_turn_order_ui()
	_refresh_encounter_groups_ui()
	_refresh_loot_drops_ui()
	_update_status_bar()
	if battle_canvas:
		battle_canvas.queue_redraw()

func _sync_inspector_from_slot() -> void:
	if not spin_slot_idx:
		return
		
	spin_slot_idx.value = selected_slot
	if chk_inspector_is_enemy:
		chk_inspector_is_enemy.button_pressed = selected_is_enemy
		chk_inspector_is_enemy.text = "Enemy Slot" if selected_is_enemy else "Player Slot"
		
	var data: Dictionary = enemy_slots[selected_slot] if selected_is_enemy else player_slots[selected_slot]
	var occupied: bool = not data.is_empty()
	
	if spin_monster_id:
		spin_monster_id.value = int(data.get("monster_id", 1)) if occupied else 1
	if edit_monster_name:
		edit_monster_name.text = str(data.get("monster_name", "Unit")) if occupied else ""
	if spin_level:
		spin_level.value = int(data.get("level", 1)) if occupied else 1
	if spin_hp:
		spin_hp.value = int(data.get("hp", 100)) if occupied else 100
	if spin_sp:
		spin_sp.value = int(data.get("sp", 50)) if occupied else 50
	if spin_spd:
		spin_spd.value = int(data.get("spd", 10)) if occupied else 10
	if opt_element:
		opt_element.selected = int(data.get("element", Element.NONE)) if occupied else Element.NONE
	if edit_jmp:
		edit_jmp.text = str(data.get("jmp_name", "unit.jmp")) if occupied else "unit.jmp"
	if chk_is_boss:
		chk_is_boss.button_pressed = bool(data.get("is_boss", false)) if occupied else false

func _on_save_slot_clicked() -> void:
	var slot_data: Dictionary = {
		"monster_id": int(spin_monster_id.value) if spin_monster_id else 1,
		"monster_name": edit_monster_name.text if edit_monster_name else "Monster",
		"level": int(spin_level.value) if spin_level else 1,
		"hp": int(spin_hp.value) if spin_hp else 100,
		"sp": int(spin_sp.value) if spin_sp else 50,
		"spd": int(spin_spd.value) if spin_spd else 10,
		"element": opt_element.selected if opt_element else Element.NONE,
		"jmp_name": edit_jmp.text if edit_jmp else "monster.jmp",
		"is_boss": chk_is_boss.button_pressed if chk_is_boss else false
	}
	
	if selected_is_enemy:
		set_enemy_slot(selected_slot, slot_data)
	else:
		set_player_slot(selected_slot, slot_data)

func _on_delete_slot_clicked() -> void:
	clear_slot(selected_is_enemy, selected_slot)

func _on_apply_preset_pressed() -> void:
	if not opt_preset:
		return
	var preset_name: String = opt_preset.get_item_text(opt_preset.selected)
	load_formation_preset(preset_name)

func _on_map_preset_selected(index: int) -> void:
	if not opt_map:
		return
	var selected_id: int = opt_map.get_item_id(index)
	map_id = selected_id
	map_name = KNOWN_MAPS.get(selected_id, "Map_%d" % selected_id)
	if spin_map_id:
		spin_map_id.value = map_id
	if edit_map_name:
		edit_map_name.text = map_name
	_update_status_bar()

func _refresh_turn_order_ui() -> void:
	if not list_turn_order:
		return
	list_turn_order.clear()
	var participants: Array[Dictionary] = calculate_turn_order()
	for i in range(participants.size()):
		var p: Dictionary = participants[i]
		var team_prefix: String = "[P]" if p["team"] == "player" else "[E]"
		var boss_badge: String = " ★" if p.get("is_boss", false) else ""
		var elem_name: String = ELEMENT_NAMES[clampi(int(p.get("element", 0)), 0, Element.WIND)]
		var entry_text: String = "%d. %s %s (L%d)%s | SPD:%d | %s | HP:%d" % [
			i + 1,
			team_prefix,
			p.get("monster_name", "Unit"),
			p.get("level", 1),
			boss_badge,
			p.get("spd", 10),
			elem_name,
			p.get("hp", 100)
		]
		list_turn_order.add_item(entry_text)

func _refresh_encounter_groups_ui() -> void:
	if not list_groups:
		return
	list_groups.clear()
	var total_w: int = 0
	for g in encounter_groups:
		total_w += int(g.get("weight", 10))
	if total_w <= 0:
		total_w = 1
		
	for i in range(encounter_groups.size()):
		var g: Dictionary = encounter_groups[i]
		var w: int = int(g.get("weight", 10))
		var pct: float = (float(w) / float(total_w)) * 100.0
		var g_text: String = "#%d: %s (Weight: %d, Rate: %.1f%%)" % [
			g.get("group_id", i + 1),
			g.get("group_name", "Group"),
			w,
			pct
		]
		list_groups.add_item(g_text)

func _on_add_group_clicked() -> void:
	var g_name: String = edit_group_name.text if edit_group_name and not edit_group_name.text.is_empty() else "Custom Troop"
	var weight: int = int(spin_group_weight.value) if spin_group_weight else 10
	
	# Current active enemy troop as formation
	var formation: Dictionary = {}
	for i in range(TOTAL_SLOTS):
		if not enemy_slots[i].is_empty():
			formation[i] = enemy_slots[i].duplicate(true)
			
	add_encounter_group({
		"group_id": encounter_groups.size() + 1,
		"group_name": g_name,
		"weight": weight,
		"formation": formation
	})

func _on_remove_group_clicked() -> void:
	if not list_groups:
		return
	var selected: PackedInt32Array = list_groups.get_selected_items()
	if selected.size() > 0:
		remove_encounter_group(selected[0])

func _on_roll_encounter_clicked() -> void:
	var result: Dictionary = roll_random_encounter()
	if not lbl_encounter_result:
		return
	if result["triggered"]:
		lbl_encounter_result.text = "ENCOUNTER! Rolled: %.1f%% <= %.1f%% | Spawned: %s" % [
			result["step_roll"],
			encounter_rate_pct,
			result.get("group_name", "Unknown Group")
		]
		lbl_encounter_result.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3, 1.0))
	else:
		lbl_encounter_result.text = "No Encounter (Roll: %.1f%% > %.1f%%)" % [
			result["step_roll"],
			encounter_rate_pct
		]
		lbl_encounter_result.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5, 1.0))

func _refresh_loot_drops_ui() -> void:
	if not list_loot:
		return
	list_loot.clear()
	for i in range(loot_drops.size()):
		var d: Dictionary = loot_drops[i]
		var item_id: int = int(d.get("item_id", 0))
		var item_name: String = str(d.get("item_name", "Item"))
		var rate: float = float(d.get("drop_rate_pct", 0.0))
		var min_q: int = int(d.get("min_qty", 1))
		var max_q: int = int(d.get("max_qty", 1))
		var drop_str: String = "[ID %d] %s: %.1f%% (Qty: %d..%d)" % [item_id, item_name, rate, min_q, max_q]
		list_loot.add_item(drop_str)

func _on_add_drop_clicked() -> void:
	var item_id: int = int(spin_drop_item_id.value) if spin_drop_item_id else 10001
	var item_name: String = edit_drop_item_name.text if edit_drop_item_name and not edit_drop_item_name.text.is_empty() else "Item_%d" % item_id
	var rate: float = float(spin_drop_rate.value) if spin_drop_rate else 50.0
	var min_q: int = int(spin_drop_min_qty.value) if spin_drop_min_qty else 1
	var max_q: int = int(spin_drop_max_qty.value) if spin_drop_max_qty else 1
	add_loot_drop(item_id, item_name, rate, min_q, max_q)

func _on_remove_drop_clicked() -> void:
	if not list_loot:
		return
	var selected: PackedInt32Array = list_loot.get_selected_items()
	if selected.size() > 0:
		remove_loot_drop(selected[0])

func _on_roll_loot_clicked() -> void:
	var drops: Array[Dictionary] = roll_loot_drops()
	if not lbl_loot_result:
		return
	if drops.is_empty():
		lbl_loot_result.text = "Loot Roll Result: No items dropped."
		lbl_loot_result.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	else:
		var items_summary: PackedStringArray = []
		for d in drops:
			items_summary.append("%dx %s" % [d.get("quantity", 1), d.get("item_name", "Item")])
		lbl_loot_result.text = "Loot Won: %s" % ", ".join(items_summary)
		lbl_loot_result.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4, 1.0))

func _update_status_bar() -> void:
	if map_readout:
		map_readout.text = "Map: %d (%s) | Enc Rate: %.1f%%" % [map_id, map_name, encounter_rate_pct]
	if participant_readout:
		var p_count: int = 0
		var e_count: int = 0
		for s in player_slots:
			if not s.is_empty(): p_count += 1
		for s in enemy_slots:
			if not s.is_empty(): e_count += 1
		participant_readout.text = "Party: %d/8 | Enemies: %d/8" % [p_count, e_count]
	if status_readout and status_readout.text.is_empty():
		status_readout.text = "Ready."
