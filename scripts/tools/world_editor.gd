class_name WorldEditor
extends Control

## Unified World Editor Suite & Database Inspector for Wonderland Online Godot 4 Client.
## Coordinates Map Studio, NPC Studio, Quest Studio, Skill Studio, Item Studio, Battle Studio,
## Searchable Database Inspector, and In-Engine Live Playtest & Simulator.

const MapViewScene = preload("res://scenes/world/map_view.tscn")
const MapEditorScript = preload("res://scripts/tools/map_editor.gd")
const NpcEditorScript = preload("res://scripts/tools/npc_editor.gd")
const QuestEditorScript = preload("res://scripts/tools/quest_editor.gd")
const SkillEditorScript = preload("res://scripts/tools/skill_editor.gd")
const ItemEditorScript = preload("res://scripts/tools/item_editor.gd")
const BattleEditorScript = preload("res://scripts/tools/battle_editor.gd")
const CutsceneEditorScript = preload("res://scripts/tools/cutscene_editor.gd")
const TentEditorScript = preload("res://scripts/tools/tent_editor.gd")
const AudioEditorScript = preload("res://scripts/tools/audio_editor.gd")

# --- Core Singletons & Data Sources ---
var _archive_loader: Node = null
var _game_database: Node = null

# --- Active Editor State ---
var active_map_id: int = 10001
var active_map_name: String = "Ship Deck"

# --- Database Inspector State ---
var db_category: String = "items" # "items", "npcs", "dialogues", "scenes", "skills"
var db_filtered_ids: Array = []
var db_current_page: int = 0
const DB_PAGE_SIZE: int = 50
var db_search_query: String = ""
var _current_inspected_npc_record = null
var _current_inspected_skill_id: int = 0
var _next_talk_chain_target: int = 0

# --- Simulator State ---
var _simulator_instance: Node = null
var is_simulator_running: bool = false

# --- Node References ---
@onready var main_tab_container: TabContainer = find_child("MainTabContainer", true, false)
@onready var status_label: Label = find_child("StatusReadoutLabel", true, false)
@onready var map_status_label: Label = find_child("MapStatusLabel", true, false)

# Toolbar Controls
@onready var btn_new_map: Button = find_child("BtnNewMap", true, false)
@onready var btn_new_npc: Button = find_child("BtnNewNPC", true, false)
@onready var btn_new_quest: Button = find_child("BtnNewQuest", true, false)
@onready var btn_new_skill: Button = find_child("BtnNewSkill", true, false)
@onready var btn_new_item: Button = find_child("BtnNewItem", true, false)
@onready var btn_new_battle: Button = find_child("BtnNewBattle", true, false)
@onready var btn_new_cutscene: Button = find_child("BtnNewCutscene", true, false)
@onready var btn_new_tent: Button = find_child("BtnNewTent", true, false)
@onready var btn_audio_studio: Button = find_child("BtnAudioStudio", true, false)
@onready var btn_open_mapdata: Button = find_child("BtnOpenMapData", true, false)
@onready var btn_save_all: Button = find_child("BtnSaveAll", true, false)
@onready var btn_refresh_db: Button = find_child("BtnRefreshDB", true, false)
@onready var btn_undo: Button = find_child("BtnUndo", true, false)
@onready var btn_redo: Button = find_child("BtnRedo", true, false)
@onready var edit_quick_map_search: LineEdit = find_child("EditQuickMapSearch", true, false)
@onready var opt_quick_map: OptionButton = find_child("OptQuickMap", true, false)
@onready var btn_return_to_game: Button = find_child("BtnReturnToGame", true, false)
var _all_world_maps: Dictionary = {}

# Embedded Sub-Editors (Tabs 0 to 8)
@onready var map_studio = find_child("MapEditor", true, false)
@onready var npc_studio = find_child("NpcEditor", true, false)
@onready var quest_studio = find_child("QuestEditor", true, false)
@onready var skill_studio = find_child("SkillEditor", true, false)
@onready var item_studio = find_child("ItemEditor", true, false)
@onready var battle_studio = find_child("BattleEditor", true, false)
@onready var cutscene_studio = find_child("CutsceneEditor", true, false)
@onready var tent_studio = find_child("TentEditor", true, false)
@onready var audio_studio = find_child("AudioEditor", true, false)

# Tab 9: Database Inspector Controls
@onready var opt_db_category: OptionButton = find_child("OptDBCategory", true, false)
@onready var edit_db_search: LineEdit = find_child("EditDBSearch", true, false)
@onready var lbl_db_count: Label = find_child("LblDBCount", true, false)
@onready var list_db_results: ItemList = find_child("ListDBResults", true, false)
@onready var btn_page_prev: Button = find_child("BtnPagePrev", true, false)
@onready var btn_page_next: Button = find_child("BtnPageNext", true, false)
@onready var lbl_page_info: Label = find_child("LblPageInfo", true, false)

@onready var panel_item_details: Control = find_child("PanelItemDetails", true, false)
@onready var rect_item_icon: TextureRect = find_child("RectItemIcon", true, false)
@onready var lbl_item_name: Label = find_child("LblItemName", true, false)
@onready var lbl_item_meta: Label = find_child("LblItemMeta", true, false)
@onready var lbl_item_stats: Label = find_child("LblItemStats", true, false)
@onready var rich_item_desc: RichTextLabel = find_child("RichItemDesc", true, false)

@onready var panel_npc_details: Control = find_child("PanelNPCDetails", true, false)
@onready var rect_npc_db_portrait: TextureRect = find_child("RectNPCPortrait", true, false)
@onready var lbl_npc_db_name: Label = find_child("LblNPCName", true, false)
@onready var lbl_npc_db_meta: Label = find_child("LblNPCMeta", true, false)
@onready var lbl_npc_db_stats: Label = find_child("LblNPCStats", true, false)
@onready var btn_send_npc_to_studio: Button = find_child("BtnSendToStudio", true, false)

@onready var panel_talk_details: Control = find_child("PanelTalkDetails", true, false)
@onready var lbl_talk_meta: Label = find_child("LblTalkMeta", true, false)
@onready var rich_talk_formatted: RichTextLabel = find_child("RichTalkFormatted", true, false)
@onready var edit_talk_raw: TextEdit = find_child("EditTalkRaw", true, false)
@onready var lbl_talk_choices: Label = find_child("LblTalkChoices", true, false)
@onready var btn_follow_talk_chain: Button = find_child("BtnFollowTalkChain", true, false)

@onready var panel_scene_details: Control = find_child("PanelSceneDetails", true, false)
@onready var lbl_scene_meta: Label = find_child("LblSceneMeta", true, false)
@onready var rect_scene_bg_thumb: TextureRect = find_child("RectSceneBGThumb", true, false)
@onready var rect_scene_mm_thumb: TextureRect = find_child("RectSceneMMThumb", true, false)
@onready var btn_scene_open_studio: Button = find_child("BtnSceneOpenStudio", true, false)
@onready var btn_scene_playtest: Button = find_child("BtnScenePlaytest", true, false)

# Tab 10: Live Playtest & Simulator Controls
@onready var btn_launch_playtest: Button = find_child("BtnLaunchPlaytest", true, false)
@onready var btn_stop_playtest: Button = find_child("BtnStopPlaytest", true, false)
@onready var opt_sim_map: OptionButton = find_child("OptSimMap", true, false)
@onready var opt_sim_role: OptionButton = find_child("OptSimRole", true, false)
@onready var spin_sim_x: SpinBox = find_child("SpinSimX", true, false)
@onready var spin_sim_y: SpinBox = find_child("SpinSimY", true, false)
@onready var chk_sim_inject_npcs: CheckBox = find_child("ChkSimInjectNPCs", true, false)
@onready var sim_viewport_container: SubViewportContainer = find_child("SimViewportContainer", true, false)
@onready var sim_viewport: SubViewport = find_child("SimViewport", true, false)
@onready var lbl_sim_status: Label = find_child("LblSimStatus", true, false)
@onready var btn_sim_teleport: Button = find_child("BtnSimTeleport", true, false)
@onready var spin_sim_item_id: SpinBox = find_child("SpinSimItemId", true, false)
@onready var spin_sim_item_count: SpinBox = find_child("SpinSimItemCount", true, false)
@onready var btn_sim_give_item: Button = find_child("BtnSimGiveItem", true, false)
@onready var btn_sim_give_gold: Button = find_child("BtnSimGiveGold", true, false)
@onready var btn_sim_clear_inventory: Button = find_child("BtnSimClearInventory", true, false)

func _ready() -> void:
	_setup_responsive_editor_window()
	_init_singletons()
	_init_toolbar()
	_init_database_inspector()
	_init_simulator()
	_update_database_stats()
	_sync_active_map(active_map_id)

func _setup_responsive_editor_window() -> void:
	if is_inside_tree() and get_tree().root:
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
		if not get_tree().root.size_changed.is_connected(_on_window_resized):
			get_tree().root.size_changed.connect(_on_window_resized)
	
	var screen_idx: int = DisplayServer.window_get_current_screen()
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_idx)
	var win_size: Vector2i = DisplayServer.window_get_size()
	
	if win_size.x < 1280 or win_size.y < 720:
		var target_w: int = mini(1400, int(screen_size.x * 0.92))
		var target_h: int = mini(850, int(screen_size.y * 0.88))
		target_w = maxi(target_w, 1024)
		target_h = maxi(target_h, 680)
		DisplayServer.window_set_size(Vector2i(target_w, target_h))
		
		var pos_x: int = maxi(0, (screen_size.x - target_w) / 2)
		var pos_y: int = maxi(0, (screen_size.y - target_h) / 2)
		DisplayServer.window_set_position(Vector2i(pos_x, pos_y))
	
	_adapt_to_window_size()

func _on_window_resized() -> void:
	_adapt_to_window_size()

func _adapt_to_window_size() -> void:
	if not is_inside_tree():
		return
	var vp_size: Vector2 = get_viewport_rect().size
	set_anchors_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	set_deferred("size", vp_size)

func _init_singletons() -> void:
	if is_inside_tree():
		_archive_loader = get_node_or_null("/root/ArchiveLoader")
	if not _archive_loader:
		var al_script = load("res://scripts/core/archive_loader.gd")
		if al_script:
			_archive_loader = al_script.new()
			_archive_loader.name = "ArchiveLoader"
			if is_inside_tree() and get_tree() and get_tree().root:
				get_tree().root.add_child(_archive_loader)
	
	if is_inside_tree():
		_game_database = get_node_or_null("/root/GameDatabase")
	if not _game_database:
		var gdb_script = load("res://scripts/database/game_database.gd")
		if gdb_script:
			_game_database = gdb_script.new()
			_game_database.name = "GameDatabase"
			if is_inside_tree() and get_tree() and get_tree().root:
				get_tree().root.add_child(_game_database)
			if _game_database.has_method("load_all") and not _game_database.is_loaded:
				_game_database.load_all()
	
	if skill_studio and _game_database and skill_studio.has_method("set_game_database"):
		skill_studio.set_game_database(_game_database)

func _update_database_stats() -> void:
	var item_cnt: int = _game_database.items.get_all_items().size() if _game_database and _game_database.items else 0
	var npc_cnt: int = _game_database.npcs.get_all_npcs().size() if _game_database and _game_database.npcs else 0
	var talk_cnt: int = _game_database.talks.get_count() if _game_database and _game_database.talks else 0
	var scene_cnt: int = _game_database.scenes.get_all_scenes().size() if _game_database and _game_database.scenes else 0
	var skill_cnt: int = _game_database.skills.get_all_skills().size() if _game_database and _game_database.skills else 0
	
	if status_label:
		status_label.text = "Database Loaded: %s items | %s NPCs | %s dialogues | %s scenes | %s skills" % [
			_format_int_with_commas(item_cnt),
			_format_int_with_commas(npc_cnt),
			_format_int_with_commas(talk_cnt),
			_format_int_with_commas(scene_cnt),
			_format_int_with_commas(skill_cnt)
		]
	
	if map_status_label:
		map_status_label.text = "Active Map: %d (%s)" % [active_map_id, active_map_name]

func _format_int_with_commas(val: int) -> String:
	var s := str(val)
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

# ==============================================================================
# TOOLBAR INITIALIZATION & ACTIONS
# ==============================================================================
func _init_toolbar() -> void:
	if btn_new_map:
		btn_new_map.pressed.connect(_on_btn_new_map_pressed)
	if btn_new_npc:
		btn_new_npc.pressed.connect(_on_btn_new_npc_pressed)
	if btn_new_quest:
		btn_new_quest.pressed.connect(_on_btn_new_quest_pressed)
	if btn_new_skill:
		btn_new_skill.pressed.connect(_on_btn_new_skill_pressed)
	if btn_new_item:
		btn_new_item.pressed.connect(_on_btn_new_item_pressed)
	if btn_new_battle:
		btn_new_battle.pressed.connect(_on_btn_new_battle_pressed)
	if btn_new_cutscene:
		btn_new_cutscene.pressed.connect(_on_btn_new_cutscene_pressed)
	if btn_new_tent:
		btn_new_tent.pressed.connect(_on_btn_new_tent_pressed)
	if btn_audio_studio:
		btn_audio_studio.pressed.connect(_on_btn_audio_studio_pressed)
	if btn_open_mapdata:
		btn_open_mapdata.pressed.connect(_on_btn_open_mapdata_pressed)
	if btn_save_all:
		btn_save_all.pressed.connect(_on_btn_save_all_pressed)
	if btn_refresh_db:
		btn_refresh_db.pressed.connect(_on_btn_refresh_db_pressed)
	if btn_undo:
		btn_undo.pressed.connect(perform_undo)
	if btn_redo:
		btn_redo.pressed.connect(perform_redo)
	if btn_return_to_game:
		btn_return_to_game.pressed.connect(_on_btn_return_to_game_pressed)
	
	_populate_map_option_buttons()

func _populate_map_option_buttons() -> void:
	_all_world_maps.clear()
	if _game_database and _game_database.scenes:
		for mid in _game_database.scenes.get_all_scenes():
			var sc = _game_database.scenes.get_scene(mid)
			_all_world_maps[mid] = sc.name if (sc and not sc.name.is_empty()) else ("Map %d" % mid)
	else:
		var sdb = load("res://scripts/database/scene_database.gd").new()
		var s_path := "res://assets/data/SceneData.dat"
		if not FileAccess.file_exists(s_path): s_path = "D:/GitHub/WLRI/data/SceneData.dat"
		if sdb.load_from_file(s_path):
			for mid in sdb.get_all_scenes():
				var sc = sdb.get_scene(mid)
				_all_world_maps[mid] = sc.name if (sc and not sc.name.is_empty()) else ("Map %d" % mid)
	
	var eve = load("res://scripts/map/eve_parser.gd").new()
	for mid in eve.get_all_map_ids():
		if not _all_world_maps.has(mid):
			_all_world_maps[mid] = "Map %d" % mid
	
	var canonical_names: Dictionary = {
		10001: "Ship Deck",
		10002: "Ship Cabin",
		10003: "Deserted Island",
		10005: "Kelan Trail",
		10007: "Kelan Village",
		10011: "Beach Awakening",
		12001: "Holy Village",
		20001: "Kelan Village"
	}
	for cid in canonical_names:
		_all_world_maps[cid] = canonical_names[cid]
	
	_filter_quick_map_options("")
	
	if opt_quick_map and not opt_quick_map.item_selected.is_connected(_on_quick_map_selected):
		opt_quick_map.item_selected.connect(_on_quick_map_selected)
	
	if edit_quick_map_search:
		if not edit_quick_map_search.text_changed.is_connected(_on_quick_map_search_changed):
			edit_quick_map_search.text_changed.connect(_on_quick_map_search_changed)
		if not edit_quick_map_search.text_submitted.is_connected(_on_quick_map_search_submitted):
			edit_quick_map_search.text_submitted.connect(_on_quick_map_search_submitted)
	
	_populate_sim_maps()

func _populate_sim_maps() -> void:
	if not opt_sim_map:
		return
	opt_sim_map.clear()
	var sorted_ids := _all_world_maps.keys()
	sorted_ids.sort()
	for mid in sorted_ids:
		opt_sim_map.add_item("%d - %s" % [mid, _all_world_maps[mid]], mid)
	if not opt_sim_map.item_selected.is_connected(_on_sim_map_selected):
		opt_sim_map.item_selected.connect(_on_sim_map_selected)
	for i in range(opt_sim_map.item_count):
		if opt_sim_map.get_item_id(i) == active_map_id:
			opt_sim_map.selected = i
			break

func _filter_quick_map_options(filter_text: String = "") -> void:
	if not opt_quick_map:
		return
	opt_quick_map.clear()
	var q := filter_text.strip_edges().to_lower()
	var sorted_ids := _all_world_maps.keys()
	sorted_ids.sort()
	
	for mid in sorted_ids:
		var mname: String = str(_all_world_maps[mid])
		if q.is_empty() or str(mid).contains(q) or mname.to_lower().contains(q):
			opt_quick_map.add_item("%d - %s" % [mid, mname], mid)
	
	for i in range(opt_quick_map.item_count):
		if opt_quick_map.get_item_id(i) == active_map_id:
			opt_quick_map.selected = i
			break

func _on_quick_map_search_changed(new_text: String) -> void:
	_filter_quick_map_options(new_text)

func _on_quick_map_search_submitted(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_valid_int():
		var q_id := trimmed.to_int()
		if _all_world_maps.has(q_id):
			_sync_active_map(q_id)
	elif opt_quick_map and opt_quick_map.item_count > 0:
		var first_id: int = opt_quick_map.get_item_id(0)
		_sync_active_map(first_id)

func _on_sim_map_selected(idx: int) -> void:
	if not opt_sim_map:
		return
	var mid: int = opt_sim_map.get_item_id(idx)
	_sync_active_map(mid)
	var spawn_pos: Vector2 = _get_default_spawn_for_map(mid)
	if spin_sim_x:
		spin_sim_x.value = spawn_pos.x
	if spin_sim_y:
		spin_sim_y.value = spawn_pos.y
	if is_simulator_running and _simulator_instance and is_instance_valid(_simulator_instance):
		teleport_simulator_to(mid, spawn_pos)

func _sync_active_map(map_id: int) -> void:
	active_map_id = map_id
	active_map_name = "Map %d" % map_id
	if _all_world_maps.has(map_id):
		active_map_name = _all_world_maps[map_id]
	elif _game_database and _game_database.scenes:
		var sc = _game_database.scenes.get_scene(map_id)
		if sc and not sc.name.is_empty():
			active_map_name = sc.name
	
	# Update quick map selection
	if opt_quick_map:
		for i in range(opt_quick_map.item_count):
			if opt_quick_map.get_item_id(i) == map_id:
				opt_quick_map.selected = i
				break
	
	# Update simulator map selection
	if opt_sim_map:
		for i in range(opt_sim_map.item_count):
			if opt_sim_map.get_item_id(i) == map_id:
				opt_sim_map.selected = i
				break
	
	# Update default simulator spawn spinboxes
	var spawn_pos: Vector2 = _get_default_spawn_for_map(map_id)
	if spin_sim_x:
		spin_sim_x.value = spawn_pos.x
	if spin_sim_y:
		spin_sim_y.value = spawn_pos.y
	
	# Sync Map Studio if embedded
	if map_studio and map_studio.has_method("load_map_from_id"):
		map_studio.load_map_from_id(map_id)
	
	_update_database_stats()

func _get_default_spawn_for_map(map_id: int) -> Vector2:
	const CANONICAL_SPAWNS: Dictionary = {
		10001: Vector2(1042, 1075), # Ship Deck
		10002: Vector2(674, 1067),  # Ship Cabin
		10003: Vector2(420, 360),   # Ship Kitchen / Bunk
		10004: Vector2(300, 240),   # Ship Storage
		10005: Vector2(400, 300),   # Kelan Trail
		10011: Vector2(1390, 2460), # Beach Awakening
		11003: Vector2(500, 400),   # Holy Village
		12000: Vector2(892, 734),   # Kelan Village (North Island entrance)
		12001: Vector2(400, 380),   # Civillian's House 1
		12002: Vector2(400, 380),   # Civillian's House 2
		12003: Vector2(400, 380),   # Civillian's House 3
		12004: Vector2(400, 380),   # Civillian's House 4
		12005: Vector2(400, 380),   # 1F Cave
		20001: Vector2(500, 400),   # Kelan Village interior
		60000: Vector2(2882, 3009), # North Island
		60001: Vector2(2344, 269),  # North Island
	}
	if CANONICAL_SPAWNS.has(map_id):
		return CANONICAL_SPAWNS[map_id]
	
	var eve = load("res://scripts/map/eve_parser.gd").new()
	if eve:
		var npcs = eve.get_npcs_for_map(map_id)
		if not npcs.is_empty() and npcs[0].world_pos != Vector2.ZERO:
			return npcs[0].world_pos
		var warps = eve.get_warps_for_map(map_id)
		for w in warps:
			var warp_pos := Vector2(w.world_x, w.world_y)
			if warp_pos != Vector2.ZERO:
				return warp_pos
			if w.dest_x > 0 and w.dest_y > 0:
				return Vector2(w.dest_x, w.dest_y)
	
	if _archive_loader and _archive_loader.has_method("get_map_background"):
		var bg_tex: Texture2D = _archive_loader.get_map_background(map_id)
		if bg_tex:
			var sz: Vector2 = bg_tex.get_size()
			if sz.x > 0 and sz.y > 0:
				return Vector2(sz.x * 0.5, sz.y * 0.5)
	
	return Vector2(500, 400)

func _on_quick_map_selected(index: int) -> void:
	var mid: int = opt_quick_map.get_item_id(index)
	_sync_active_map(mid)

func _on_btn_new_map_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 0
	if map_studio and map_studio.has_method("init_empty_map"):
		map_studio.init_empty_map(1600, 1200, 99999, "New Custom Map")
	active_map_id = 99999
	active_map_name = "New Custom Map"
	_update_database_stats()

func _on_btn_new_npc_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 1
	if npc_studio and npc_studio.has_method("_on_new_npc_pressed"):
		npc_studio._on_new_npc_pressed()

func _on_btn_new_quest_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 2
	if quest_studio and quest_studio.has_method("_on_btn_new_quest_pressed"):
		quest_studio._on_btn_new_quest_pressed()

func _on_btn_new_skill_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 3
	if skill_studio and skill_studio.has_method("_on_new_skill_pressed"):
		skill_studio._on_new_skill_pressed()

func _on_btn_new_item_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 4
	if item_studio and item_studio.has_method("reset_to_blank"):
		item_studio.reset_to_blank()

func _on_btn_new_battle_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 5
	if battle_studio and battle_studio.has_method("clear_all_slots"):
		battle_studio.clear_all_slots()

func _on_btn_new_cutscene_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 6
	if cutscene_studio and cutscene_studio.has_method("clear_all_tracks"):
		cutscene_studio.clear_all_tracks()

func _on_btn_new_tent_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 7
	if tent_studio and tent_studio.has_method("clear_furniture"):
		tent_studio.clear_furniture()

func _on_btn_audio_studio_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 8

func _on_btn_open_mapdata_pressed() -> void:
	if main_tab_container:
		main_tab_container.current_tab = 0
	if map_studio and map_studio.has_method("load_map_from_id"):
		map_studio.load_map_from_id(active_map_id)

func _on_btn_save_all_pressed() -> void:
	var saved_count := 0
	if map_studio and map_studio.has_method("export_mapdata_binary"):
		if map_studio.export_mapdata_binary():
			saved_count += 1
	if npc_studio and npc_studio.has_method("save_custom_preset"):
		npc_studio.save_custom_preset("Current_Editor_NPC")
		saved_count += 1
	if quest_studio and quest_studio.has_method("save_quest"):
		if quest_studio.save_quest():
			saved_count += 1
	if skill_studio and skill_studio.has_method("save_skill_json"):
		if skill_studio.save_skill_json("user://custom_skills.json"):
			saved_count += 1
	if item_studio and item_studio.has_method("save_item_json"):
		if item_studio.save_item_json("user://custom_items.json"):
			saved_count += 1
	if battle_studio and battle_studio.has_method("save_encounter_table"):
		if battle_studio.save_encounter_table("user://custom_encounters.json"):
			saved_count += 1
	if cutscene_studio and cutscene_studio.has_method("save_cutscene_json"):
		if cutscene_studio.save_cutscene_json("user://custom_cutscenes.json"):
			saved_count += 1
	if tent_studio and tent_studio.has_method("save_tent_layout"):
		if tent_studio.save_tent_layout("user://custom_tent_layout.json"):
			saved_count += 1
	if audio_studio and audio_studio.has_method("export_audio_manifest"):
		if audio_studio.export_audio_manifest("user://custom_audio_manifest.json"):
			saved_count += 1
	if status_label:
		status_label.text = "Saved all active Content Studios data successfully (%d operations)." % saved_count

func _on_btn_refresh_db_pressed() -> void:
	if _game_database and _game_database.has_method("load_all"):
		_game_database.load_all()
	_populate_map_option_buttons()
	_refresh_db_inspector_results()
	_update_database_stats()

func _on_btn_return_to_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/login_screen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed:
			if event.keycode == KEY_Z:
				if event.shift_pressed:
					perform_redo()
				else:
					perform_undo()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_Y:
				perform_redo()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F12:
			_on_btn_return_to_game_pressed()
			get_viewport().set_input_as_handled()

func _ensure_studio_node_refs() -> void:
	if not main_tab_container:
		main_tab_container = find_child("MainTabContainer", true, false)
	if not map_studio:
		map_studio = find_child("MapEditor", true, false)
	if not npc_studio:
		npc_studio = find_child("NpcEditor", true, false)
	if not tent_studio:
		tent_studio = find_child("TentEditor", true, false)
	if not status_label:
		status_label = find_child("StatusReadoutLabel", true, false)

func perform_undo() -> void:
	_ensure_studio_node_refs()
	var current_tab: int = main_tab_container.current_tab if main_tab_container else 0
	var handled: bool = false
	var studio_name: String = ""
	
	match current_tab:
		0: # Map Studio
			if map_studio and map_studio.has_method("undo"):
				handled = map_studio.undo()
				studio_name = "Map Studio"
		1: # NPC Studio
			if npc_studio and npc_studio.has_method("undo"):
				handled = npc_studio.undo()
				studio_name = "NPC Studio"
		7: # Tent Studio
			if tent_studio and tent_studio.has_method("undo"):
				handled = tent_studio.undo()
				studio_name = "Tent Studio"
		_:
			var active_child = main_tab_container.get_current_tab_control() if main_tab_container else null
			if active_child and active_child.has_method("undo"):
				handled = active_child.undo()
				studio_name = active_child.name

	if status_label:
		if handled:
			status_label.text = "[UNDO] Action reversed in %s." % studio_name
		else:
			status_label.text = "[UNDO] Nothing to undo in current tab."

func perform_redo() -> void:
	_ensure_studio_node_refs()
	var current_tab: int = main_tab_container.current_tab if main_tab_container else 0
	var handled: bool = false
	var studio_name: String = ""
	
	match current_tab:
		0: # Map Studio
			if map_studio and map_studio.has_method("redo"):
				handled = map_studio.redo()
				studio_name = "Map Studio"
		1: # NPC Studio
			if npc_studio and npc_studio.has_method("redo"):
				handled = npc_studio.redo()
				studio_name = "NPC Studio"
		7: # Tent Studio
			if tent_studio and tent_studio.has_method("redo"):
				handled = tent_studio.redo()
				studio_name = "Tent Studio"
		_:
			var active_child = main_tab_container.get_current_tab_control() if main_tab_container else null
			if active_child and active_child.has_method("redo"):
				handled = active_child.redo()
				studio_name = active_child.name

	if status_label:
		if handled:
			status_label.text = "[REDO] Action reapplied in %s." % studio_name
		else:
			status_label.text = "[REDO] Nothing to redo in current tab."

# ==============================================================================
# TAB 9: DATABASE INSPECTOR LOGIC
# ==============================================================================
func _init_database_inspector() -> void:
	if opt_db_category:
		opt_db_category.clear()
		opt_db_category.add_item("Items (7,569)", 0)
		opt_db_category.add_item("NPCs (4,929)", 1)
		opt_db_category.add_item("Dialogues (17,493)", 2)
		opt_db_category.add_item("Scenes (86)", 3)
		opt_db_category.add_item("Skills (953)", 4)
		opt_db_category.item_selected.connect(_on_db_category_selected)
	
	if edit_db_search:
		edit_db_search.text_changed.connect(_on_db_search_text_changed)
	
	if list_db_results:
		list_db_results.item_selected.connect(_on_db_item_selected)
		list_db_results.item_activated.connect(_on_db_item_activated)
	
	if btn_page_prev:
		btn_page_prev.pressed.connect(_on_btn_page_prev_pressed)
	if btn_page_next:
		btn_page_next.pressed.connect(_on_btn_page_next_pressed)
	
	if btn_send_npc_to_studio:
		btn_send_npc_to_studio.pressed.connect(_on_btn_send_npc_to_studio_pressed)
	if btn_follow_talk_chain:
		btn_follow_talk_chain.pressed.connect(_on_btn_follow_talk_chain_pressed)
	if btn_scene_open_studio:
		btn_scene_open_studio.pressed.connect(_on_btn_scene_open_studio_pressed)
	if btn_scene_playtest:
		btn_scene_playtest.pressed.connect(_on_btn_scene_playtest_pressed)
	
	_refresh_db_inspector_results()

func _on_db_category_selected(index: int) -> void:
	match index:
		0: db_category = "items"
		1: db_category = "npcs"
		2: db_category = "dialogues"
		3: db_category = "scenes"
		4: db_category = "skills"
	db_current_page = 0
	_refresh_db_inspector_results()

## Programmatic search facade for the Database Inspector
func search_database(category: String, query: String) -> Array:
	var results: Array = []
	if not _game_database:
		_init_singletons()
	if not _game_database:
		return results
	
	var q: String = query.to_lower().strip_edges()
	match category.to_lower():
		"items", "item":
			if _game_database.items:
				var all_items: Dictionary = _game_database.items.get_all_items()
				for id in all_items.keys():
					var rec = all_items[id]
					if q.is_empty() or str(rec.id).find(q) != -1 or rec.name.to_lower().find(q) != -1 or rec.description.to_lower().find(q) != -1:
						results.append({
							"id": rec.id,
							"name": rec.name,
							"icon_id": rec.icon_id,
							"desc": rec.description
						})
						if results.size() >= 100:
							break
		"npcs", "npc":
			if _game_database.npcs:
				var all_npcs: Dictionary = _game_database.npcs.get_all_npcs()
				for id in all_npcs.keys():
					var rec = all_npcs[id]
					if q.is_empty() or str(rec.id).find(q) != -1 or rec.name.to_lower().find(q) != -1:
						results.append({
							"id": rec.id,
							"name": rec.name,
							"sprite_id": rec.sprite_id,
							"talk_image": rec.talk_image
						})
						if results.size() >= 100:
							break
		"talks", "dialogues", "talk":
			if _game_database.talks:
				var talk_ids: Array = _game_database.talks.get_all_talk_ids() if _game_database.talks.has_method("get_all_talk_ids") else []
				for tid in talk_ids:
					var t: Dictionary = _game_database.talks.get_talk(int(tid))
					var text: String = str(t.get("text", t.get("dialogue", t.get("plain_text", ""))))
					var speaker: String = str(t.get("speaker", ""))
					if q.is_empty() or str(tid).find(q) != -1 or text.to_lower().find(q) != -1 or speaker.to_lower().find(q) != -1:
						results.append({
							"talk_id": tid,
							"speaker": speaker,
							"text": text,
							"talk_image": t.get("talk_image", 0)
						})
						if results.size() >= 100:
							break
		"scenes", "scene", "maps", "map":
			if _game_database.scenes:
				var all_scenes: Dictionary = _game_database.scenes.get_all_scenes()
				for sid in all_scenes.keys():
					var s = all_scenes[sid]
					if q.is_empty() or str(s.id).find(q) != -1 or s.name.to_lower().find(q) != -1:
						results.append({
							"id": s.id,
							"name": s.name,
							"bgm_id": s.bgm_id
						})
						if results.size() >= 100:
							break
		"skills", "skill":
			if _game_database.skills:
				var all_skills: Dictionary = _game_database.skills.get_all_skills()
				for sid in all_skills.keys():
					var sk = all_skills[sid]
					if q.is_empty() or str(sk.id).find(q) != -1 or sk.name.to_lower().find(q) != -1 or sk.description.to_lower().find(q) != -1:
						results.append({
							"id": sk.id,
							"name": sk.name,
							"element": sk.element_name,
							"desc": sk.description
						})
						if results.size() >= 100:
							break
	return results

func _on_db_search_text_changed(new_text: String) -> void:
	db_search_query = new_text.strip_edges().to_lower()
	db_current_page = 0
	_refresh_db_inspector_results()

func _refresh_db_inspector_results() -> void:
	db_filtered_ids.clear()
	var query := db_search_query
	
	if db_category == "items":
		var all_items: Dictionary = _game_database.items.get_all_items() if _game_database and _game_database.items else {}
		for i_id in all_items:
			var item = all_items[i_id]
			if query.is_empty():
				db_filtered_ids.append(i_id)
			else:
				var match_str := "%d %s" % [i_id, item.name.to_lower()]
				if match_str.contains(query):
					db_filtered_ids.append(i_id)
	
	elif db_category == "npcs":
		var all_npcs: Dictionary = _game_database.npcs.get_all_npcs() if _game_database and _game_database.npcs else {}
		for n_id in all_npcs:
			var npc = all_npcs[n_id]
			if query.is_empty():
				db_filtered_ids.append(n_id)
			else:
				var match_str := "%d %s" % [n_id, npc.name.to_lower()]
				if match_str.contains(query):
					db_filtered_ids.append(n_id)
	
	elif db_category == "dialogues":
		var talk_db = _game_database.talks if _game_database else null
		if talk_db:
			var all_tids: Array = talk_db.get_all_talk_ids()
			for t_id in all_tids:
				if query.is_empty():
					db_filtered_ids.append(t_id)
				else:
					var tk: Dictionary = talk_db.get_talk(t_id)
					var match_str := "%d %s %s" % [t_id, str(tk.get("speaker", "")).to_lower(), str(tk.get("plain_text", "")).to_lower()]
					if match_str.contains(query):
						db_filtered_ids.append(t_id)
	
	elif db_category == "scenes":
		var all_scenes: Dictionary = _game_database.scenes.get_all_scenes() if _game_database and _game_database.scenes else {}
		for s_id in all_scenes:
			var sc = all_scenes[s_id]
			if query.is_empty():
				db_filtered_ids.append(s_id)
			else:
				var match_str := "%d %s %s" % [s_id, sc.name.to_lower(), sc.bgm_name.to_lower()]
				if match_str.contains(query):
					db_filtered_ids.append(s_id)
	
	elif db_category == "skills":
		var all_skills: Dictionary = _game_database.skills.get_all_skills() if _game_database and _game_database.skills else {}
		for sk_id in all_skills:
			var sk = all_skills[sk_id]
			if query.is_empty():
				db_filtered_ids.append(sk_id)
			else:
				var match_str := "%d %s %s" % [sk_id, sk.name.to_lower(), sk.description.to_lower()]
				if match_str.contains(query):
					db_filtered_ids.append(sk_id)
	
	db_filtered_ids.sort()
	
	if lbl_db_count:
		lbl_db_count.text = "Results: %s found" % _format_int_with_commas(db_filtered_ids.size())
	
	_render_db_page()

func _render_db_page() -> void:
	if not list_db_results:
		return
	list_db_results.clear()
	
	var total_items: int = db_filtered_ids.size()
	var total_pages: int = maxi(1, int(ceil(float(total_items) / float(DB_PAGE_SIZE))))
	db_current_page = clampi(db_current_page, 0, total_pages - 1)
	
	var start_idx: int = db_current_page * DB_PAGE_SIZE
	var end_idx: int = mini(start_idx + DB_PAGE_SIZE, total_items)
	
	for i in range(start_idx, end_idx):
		var entity_id = db_filtered_ids[i]
		var title: String = ""
		
		match db_category:
			"items":
				var it = _game_database.items.get_item(entity_id)
				title = "[%d] %s" % [entity_id, it.name if it else "Item"]
			"npcs":
				var npc = _game_database.npcs.get_npc(entity_id)
				title = "[%d] %s (Lv.%d)" % [entity_id, npc.name if npc else "NPC", npc.level if npc else 1]
			"dialogues":
				var tk: Dictionary = _game_database.talks.get_talk(entity_id)
				var spk: String = tk.get("speaker", "")
				var excerpt: String = tk.get("plain_text", "")
				if excerpt.length() > 40:
					excerpt = excerpt.substr(0, 37) + "..."
				title = "[%d] %s: %s" % [entity_id, spk if not spk.is_empty() else "Talk", excerpt]
			"scenes":
				var sc = _game_database.scenes.get_scene(entity_id)
				title = "[%d] %s (BGM: %s)" % [entity_id, sc.name if sc else "Scene", sc.bgm_name if sc else ""]
			"skills":
				var sk = _game_database.skills.get_skill(entity_id) if _game_database and _game_database.skills else null
				title = "[%d] %s (%s, SP:%d)" % [entity_id, sk.name if sk else "Skill", sk.element_name if sk else "None", sk.sp_cost if sk else 0]
		
		list_db_results.add_item(title)
	
	if lbl_page_info:
		lbl_page_info.text = "Page %d of %d" % [db_current_page + 1, total_pages]
	if btn_page_prev:
		btn_page_prev.disabled = (db_current_page <= 0)
	if btn_page_next:
		btn_page_next.disabled = (db_current_page >= total_pages - 1)
	
	if list_db_results.item_count > 0:
		list_db_results.select(0)
		_on_db_item_selected(0)
	else:
		_hide_all_db_detail_panels()

func _on_btn_page_prev_pressed() -> void:
	if db_current_page > 0:
		db_current_page -= 1
		_render_db_page()

func _on_btn_page_next_pressed() -> void:
	var total_items: int = db_filtered_ids.size()
	var total_pages: int = maxi(1, int(ceil(float(total_items) / float(DB_PAGE_SIZE))))
	if db_current_page < total_pages - 1:
		db_current_page += 1
		_render_db_page()

func _hide_all_db_detail_panels() -> void:
	if panel_item_details: panel_item_details.visible = false
	if panel_npc_details: panel_npc_details.visible = false
	if panel_talk_details: panel_talk_details.visible = false
	if panel_scene_details: panel_scene_details.visible = false

func _on_db_item_selected(index: int) -> void:
	var global_idx: int = db_current_page * DB_PAGE_SIZE + index
	if global_idx < 0 or global_idx >= db_filtered_ids.size():
		return
	
	var entity_id = db_filtered_ids[global_idx]
	_hide_all_db_detail_panels()
	
	match db_category:
		"items":
			_show_item_details(entity_id)
		"npcs":
			_show_npc_details(entity_id)
		"dialogues":
			_show_talk_details(entity_id)
		"scenes":
			_show_scene_details(entity_id)
		"skills":
			_show_skill_details(entity_id)

func _show_item_details(item_id: int) -> void:
	if not panel_item_details:
		return
	panel_item_details.visible = true
	var item = _game_database.items.get_item(item_id) if _game_database and _game_database.items else null
	if not item:
		return
	
	if rect_item_icon and _archive_loader:
		rect_item_icon.texture = _archive_loader.get_item_icon(item.icon_id)
	if lbl_item_name:
		lbl_item_name.text = item.name
	if lbl_item_meta:
		lbl_item_meta.text = "Item ID: %d | Type: %d | Slot: %s\nLevel: %d | Rank: %d | Material: %s | Durability: %d/%d\nBuy Price: %d G | Sell Price: %d G" % [
			item.id, item.item_type, item.get_equip_slot_name(),
			item.level, item.get_rank(), item.get_material_name(),
			item.durability, item.max_durability,
			item.buy_price, item.sell_price
		]
	if lbl_item_stats:
		var stats: Array[Dictionary] = item.get_formatted_stats()
		if stats.is_empty():
			lbl_item_stats.text = "Stat Modifiers: None"
		else:
			var s_lines := []
			for st in stats:
				s_lines.append(st["text"])
			lbl_item_stats.text = "Stat Modifiers:\n" + "\n".join(s_lines)
	if rich_item_desc:
		rich_item_desc.text = "Description:\n" + (item.description if not item.description.is_empty() else "(No description)")

func _show_skill_details(skill_id: int) -> void:
	if not panel_item_details:
		return
	panel_item_details.visible = true
	var sk = _game_database.skills.get_skill(skill_id) if _game_database and _game_database.skills else null
	if not sk:
		return
	
	_current_inspected_skill_id = skill_id
	if rect_item_icon:
		rect_item_icon.texture = null
	if lbl_item_name:
		lbl_item_name.text = sk.name
	if lbl_item_meta:
		lbl_item_meta.text = "Skill ID: %d | Element: %s | Type: %s | Scope: %s\nSP Cost: %d | Base Damage: %d" % [
			sk.id, sk.element_name, sk.skill_type_name, sk.target_scope_name,
			sk.sp_cost, sk.base_damage
		]
	if lbl_item_stats:
		var mult1: float = sk.damage_rate_1 if "damage_rate_1" in sk else 1.0
		var mult2: float = sk.damage_rate_2 if "damage_rate_2" in sk else 0.0
		lbl_item_stats.text = "Combat Scaling:\nMultipliers: x%.2f / x%.2f" % [mult1, mult2]
	if rich_item_desc:
		rich_item_desc.text = "Description:\n" + (sk.description if not sk.description.is_empty() else "(No description)")

func open_skill_in_studio(skill_id: int) -> void:
	if main_tab_container:
		main_tab_container.current_tab = 3
	if skill_studio and skill_studio.has_method("lookup_from_game_database"):
		skill_studio.lookup_from_game_database(skill_id)

func _on_db_item_activated(index: int) -> void:
	var global_idx: int = db_current_page * DB_PAGE_SIZE + index
	if global_idx < 0 or global_idx >= db_filtered_ids.size():
		return
	var entity_id = db_filtered_ids[global_idx]
	if db_category == "skills":
		open_skill_in_studio(int(entity_id))
	elif db_category == "npcs":
		_on_btn_send_npc_to_studio_pressed()
	elif db_category == "scenes":
		_on_btn_scene_open_studio_pressed()

func _show_npc_details(npc_id: int) -> void:
	if not panel_npc_details:
		return
	panel_npc_details.visible = true
	var npc = _game_database.npcs.get_npc(npc_id) if _game_database and _game_database.npcs else null
	if not npc:
		return
	_current_inspected_npc_record = npc
	
	if rect_npc_db_portrait and _archive_loader:
		rect_npc_db_portrait.texture = _archive_loader.get_npc_portrait(npc.talk_image)
	if lbl_npc_db_name:
		lbl_npc_db_name.text = npc.name
	if lbl_npc_db_meta:
		lbl_npc_db_meta.text = "NPC ID: %d | Sprite ID: %d | Model ID: %d\nTalk Portrait TID: %d" % [
			npc.id, npc.sprite_id, npc.model_id, npc.talk_image
		]
	if lbl_npc_db_stats:
		lbl_npc_db_stats.text = "Level: %d\nMax HP: %s\nMax SP: %s" % [
			npc.level, _format_int_with_commas(npc.max_hp), _format_int_with_commas(npc.max_sp)
		]

func _on_btn_send_npc_to_studio_pressed() -> void:
	if not _current_inspected_npc_record:
		return
	var npc = _current_inspected_npc_record
	main_tab_container.current_tab = 1
	if npc_studio:
		if "edit_name" in npc_studio and npc_studio.edit_name:
			npc_studio.edit_name.text = npc.name
		if "spin_npc_id" in npc_studio and npc_studio.spin_npc_id:
			npc_studio.spin_npc_id.value = float(npc.id)
		if "spin_talk_image" in npc_studio and npc_studio.spin_talk_image:
			npc_studio.spin_talk_image.value = float(npc.talk_image)
		if "spin_max_hp" in npc_studio and npc_studio.spin_max_hp:
			npc_studio.spin_max_hp.value = float(npc.max_hp)
		if "spin_max_sp" in npc_studio and npc_studio.spin_max_sp:
			npc_studio.spin_max_sp.value = float(npc.max_sp)
		if "spin_level" in npc_studio and npc_studio.spin_level:
			npc_studio.spin_level.value = float(npc.level)
		if npc_studio.has_method("_reload_model_art"):
			npc_studio._reload_model_art()

func _show_talk_details(talk_id: int) -> void:
	if not panel_talk_details:
		return
	panel_talk_details.visible = true
	var tk: Dictionary = _game_database.talks.get_talk(talk_id) if _game_database and _game_database.talks else {}
	if tk.is_empty():
		return
	
	_next_talk_chain_target = int(tk.get("next_talk_id", 0))
	if btn_follow_talk_chain:
		btn_follow_talk_chain.visible = (_next_talk_chain_target > 0)
		btn_follow_talk_chain.text = "Follow Next Talk (#%d)" % _next_talk_chain_target
	
	if lbl_talk_meta:
		lbl_talk_meta.text = "Talk ID: %d | Speaker: %s (ID: %d)\nFace Index: %d | Sound Effect: %s | Next Talk: %d" % [
			int(tk.get("id", 0)),
			str(tk.get("speaker", "None")),
			int(tk.get("speaker_id", 0)),
			int(tk.get("face_index", -1)),
			str(tk.get("sound_effect", "None")),
			_next_talk_chain_target
		]
	
	if rich_talk_formatted:
		var bb_text: String = str(tk.get("text", ""))
		rich_talk_formatted.text = "[b]Formatted Presentation (with Tokens & Highlights):[/b]\n" + bb_text
	
	if edit_talk_raw:
		edit_talk_raw.text = str(tk.get("raw_text", ""))
	
	if lbl_talk_choices:
		var choices: Array = tk.get("choices", [])
		if choices.is_empty():
			lbl_talk_choices.text = "Branching Choices: None"
		else:
			var c_lines := ["Branching Choices:"]
			for c in choices:
				c_lines.append("  • %s -> Next Talk #%d (Branch %d)" % [
					str(c.get("text", "")),
					int(c.get("next_talk_id", 0)),
					int(c.get("branch", 0))
				])
			lbl_talk_choices.text = "\n".join(c_lines)

func _on_btn_follow_talk_chain_pressed() -> void:
	if _next_talk_chain_target > 0:
		db_search_query = str(_next_talk_chain_target)
		if edit_db_search:
			edit_db_search.text = db_search_query
		_refresh_db_inspector_results()

func _show_scene_details(map_id: int) -> void:
	if not panel_scene_details:
		return
	panel_scene_details.visible = true
	var sc = _game_database.scenes.get_scene(map_id) if _game_database and _game_database.scenes else null
	if not sc:
		return
	
	if lbl_scene_meta:
		lbl_scene_meta.text = "Scene Map ID: %d\nScene Name: %s\nBGM ID: %d (%s)" % [
			sc.map_id, sc.name, sc.bgm_id, sc.bgm_name
		]
	
	if rect_scene_bg_thumb and _archive_loader:
		rect_scene_bg_thumb.texture = _archive_loader.get_map_background(sc.map_id)
	if rect_scene_mm_thumb and _archive_loader:
		rect_scene_mm_thumb.texture = _archive_loader.get_minimap_texture(sc.map_id)

func _on_btn_scene_open_studio_pressed() -> void:
	var global_idx: int = db_current_page * DB_PAGE_SIZE + list_db_results.get_selected_items()[0]
	var map_id: int = db_filtered_ids[global_idx]
	_sync_active_map(map_id)
	main_tab_container.current_tab = 0

func _on_btn_scene_playtest_pressed() -> void:
	var global_idx: int = db_current_page * DB_PAGE_SIZE + list_db_results.get_selected_items()[0]
	var map_id: int = db_filtered_ids[global_idx]
	_sync_active_map(map_id)
	main_tab_container.current_tab = 10
	start_playtest()

# ==============================================================================
# TAB 10: LIVE PLAYTEST & SIMULATOR LOGIC
# ==============================================================================
func _init_simulator() -> void:
	if sim_viewport:
		sim_viewport.physics_object_picking = true
		sim_viewport.handle_input_locally = true

	if btn_launch_playtest and not btn_launch_playtest.pressed.is_connected(start_playtest):
		btn_launch_playtest.pressed.connect(start_playtest)
	if btn_stop_playtest and not btn_stop_playtest.pressed.is_connected(stop_playtest):
		btn_stop_playtest.pressed.connect(stop_playtest)
	if btn_sim_teleport and not btn_sim_teleport.pressed.is_connected(_on_btn_sim_teleport_pressed):
		btn_sim_teleport.pressed.connect(_on_btn_sim_teleport_pressed)
	if btn_sim_give_item and not btn_sim_give_item.pressed.is_connected(_on_btn_sim_give_item_pressed):
		btn_sim_give_item.pressed.connect(_on_btn_sim_give_item_pressed)
	if btn_sim_give_gold and not btn_sim_give_gold.pressed.is_connected(_on_btn_sim_give_gold_pressed):
		btn_sim_give_gold.pressed.connect(_on_btn_sim_give_gold_pressed)
	if btn_sim_clear_inventory and not btn_sim_clear_inventory.pressed.is_connected(_on_btn_sim_clear_inventory_pressed):
		btn_sim_clear_inventory.pressed.connect(_on_btn_sim_clear_inventory_pressed)
	
	_populate_sim_maps()
	
	if opt_sim_role:
		opt_sim_role.clear()
		for role_id in range(1, 15):
			var r_name: String = _game_database.get_role_name(role_id) if _game_database else ("Role %d" % role_id)
			opt_sim_role.add_item("Role %d: %s" % [role_id, r_name], role_id)
		opt_sim_role.selected = 1 # Role 2 Betty by default

func _on_btn_sim_teleport_pressed() -> void:
	var target_map: int = active_map_id
	if opt_sim_map and opt_sim_map.selected >= 0:
		var selected_mid: int = opt_sim_map.get_selected_id()
		if selected_mid > 0:
			target_map = selected_mid
	
	var target_pos := Vector2(spin_sim_x.value, spin_sim_y.value) if (spin_sim_x and spin_sim_y) else Vector2.ZERO
	if target_pos == Vector2.ZERO:
		target_pos = _get_default_spawn_for_map(target_map)
	
	if is_simulator_running and _simulator_instance and is_instance_valid(_simulator_instance):
		teleport_simulator_to(target_map, target_pos)
	else:
		_sync_active_map(target_map)
		if spin_sim_x: spin_sim_x.value = target_pos.x
		if spin_sim_y: spin_sim_y.value = target_pos.y
		start_playtest()

func teleport_simulator_to(map_id: int, spawn_pos: Vector2 = Vector2.ZERO) -> bool:
	if not _simulator_instance or not is_instance_valid(_simulator_instance):
		return false
	
	active_map_id = map_id
	if _all_world_maps.has(map_id):
		active_map_name = _all_world_maps[map_id]
	
	if spawn_pos == Vector2.ZERO:
		spawn_pos = _get_default_spawn_for_map(map_id)
	
	if spin_sim_x: spin_sim_x.value = spawn_pos.x
	if spin_sim_y: spin_sim_y.value = spawn_pos.y
	
	var success: bool = false
	if _simulator_instance.has_method("load_map"):
		success = _simulator_instance.load_map(map_id, spawn_pos)
	elif _simulator_instance.has_method("_on_portal_triggered"):
		_simulator_instance._on_portal_triggered(null, map_id, spawn_pos)
		success = true
	else:
		var map_renderer = _simulator_instance.get_node_or_null("MapRenderer")
		if map_renderer and map_renderer.has_method("load_map"):
			map_renderer.load_map(map_id)
		var player = _simulator_instance.get_node_or_null("Entities/Player")
		if player:
			if player.has_method("teleport_to"):
				player.teleport_to(spawn_pos)
			else:
				player.position = spawn_pos
		success = true
	
	if chk_sim_inject_npcs and chk_sim_inject_npcs.button_pressed and npc_studio and npc_studio.has_method("create_npc_entity"):
		var npc_map_id: int = int(npc_studio.map_id_spin.value) if ("map_id_spin" in npc_studio and npc_studio.map_id_spin) else map_id
		if npc_map_id == map_id:
			var custom_npc = npc_studio.create_npc_entity()
			if custom_npc:
				# Only inject if this npc_id is NOT already spawned from EVE data for this map
				var already_in_eve: bool = false
				var entities_node = _simulator_instance.get_node_or_null("Entities")
				if entities_node:
					for child in entities_node.get_children():
						if child is NpcEntity and child.npc_id == custom_npc.npc_id:
							already_in_eve = true
							break
				if not already_in_eve and entities_node:
					entities_node.add_child(custom_npc)
					if "_dynamic_npcs" in _simulator_instance:
						_simulator_instance._dynamic_npcs.append(custom_npc)
					if custom_npc.has_signal("npc_interacted"):
						if _simulator_instance.has_method("interact_with_npc"):
							custom_npc.npc_interacted.connect(_simulator_instance.interact_with_npc)
						elif _simulator_instance.has_method("_on_npc_interacted"):
							custom_npc.npc_interacted.connect(_simulator_instance._on_npc_interacted)
				elif already_in_eve:
					custom_npc.free()

	if lbl_sim_status:
		lbl_sim_status.text = "SIMULATOR ACTIVE: Teleported to Map %d (%s) at (%.0f, %.0f)!" % [
			map_id, active_map_name, spawn_pos.x, spawn_pos.y
		]
	return success

func start_playtest() -> void:
	stop_playtest()
	
	if not sim_viewport:
		return
	
	sim_viewport.physics_object_picking = true
	sim_viewport.handle_input_locally = true
	
	var target_map_id: int = active_map_id
	if opt_sim_map and opt_sim_map.selected >= 0:
		var selected_mid: int = opt_sim_map.get_selected_id()
		if selected_mid > 0:
			target_map_id = selected_mid
			active_map_id = selected_mid
			if _all_world_maps.has(selected_mid):
				active_map_name = _all_world_maps[selected_mid]
	
	var spawn_pos := Vector2(spin_sim_x.value, spin_sim_y.value) if (spin_sim_x and spin_sim_y) else Vector2.ZERO
	if spawn_pos == Vector2.ZERO or (spawn_pos == Vector2(1042, 1075) and target_map_id != 10001):
		spawn_pos = _get_default_spawn_for_map(target_map_id)
		if spin_sim_x: spin_sim_x.value = spawn_pos.x
		if spin_sim_y: spin_sim_y.value = spawn_pos.y
	
	if lbl_sim_status:
		lbl_sim_status.text = "Launching MapView for Map %d (%s)..." % [target_map_id, active_map_name]
	
	# Configure active character in GameDatabase so MapView initializes player accordingly
	if _game_database:
		var role_id: int = opt_sim_role.get_selected_id() if opt_sim_role else 2
		_game_database.active_character = {
			"role_id": role_id,
			"name": "Playtester",
			"level": 25,
			"hp": 850,
			"max_hp": 850,
			"sp": 400,
			"max_sp": 400,
			"element": "Water"
		}
	
	# Instantiate MapView scene
	_simulator_instance = MapViewScene.instantiate()
	_simulator_instance.name = "SimulatedMapView"
	if _simulator_instance.has_signal("map_changed"):
		_simulator_instance.map_changed.connect(_on_sim_map_changed)
	sim_viewport.add_child(_simulator_instance)
	
	# Load target map in MapView with full entity, portal and NPC synchronization
	if _simulator_instance.has_method("load_map"):
		_simulator_instance.load_map(target_map_id, spawn_pos)
	else:
		var map_renderer = _simulator_instance.get_node_or_null("MapRenderer")
		if map_renderer and map_renderer.has_method("load_map"):
			map_renderer.load_map(target_map_id)
		var player = _simulator_instance.get_node_or_null("Entities/Player")
		if player:
			if player.has_method("teleport_to"):
				player.teleport_to(spawn_pos)
			else:
				player.position = spawn_pos
	
	# Inject studio NPC if checkbox is checked — only if npc_id not already present from EVE data
	if chk_sim_inject_npcs and chk_sim_inject_npcs.button_pressed and npc_studio and npc_studio.has_method("create_npc_entity"):
		var npc_map_id: int = int(npc_studio.map_id_spin.value) if ("map_id_spin" in npc_studio and npc_studio.map_id_spin) else target_map_id
		if npc_map_id == target_map_id:
			var custom_npc = npc_studio.create_npc_entity()
			if custom_npc:
				var already_in_eve: bool = false
				var entities_node = _simulator_instance.get_node_or_null("Entities")
				if entities_node:
					for child in entities_node.get_children():
						if child is NpcEntity and child.npc_id == custom_npc.npc_id:
							already_in_eve = true
							break
				if not already_in_eve and entities_node:
					entities_node.add_child(custom_npc)
					if "_dynamic_npcs" in _simulator_instance:
						_simulator_instance._dynamic_npcs.append(custom_npc)
					if custom_npc.has_signal("npc_interacted"):
						if _simulator_instance.has_method("interact_with_npc"):
							custom_npc.npc_interacted.connect(_simulator_instance.interact_with_npc)
						elif _simulator_instance.has_method("_on_npc_interacted"):
							custom_npc.npc_interacted.connect(_simulator_instance._on_npc_interacted)
				elif already_in_eve:
					custom_npc.free()

	is_simulator_running = true
	if btn_launch_playtest: btn_launch_playtest.disabled = true
	if btn_stop_playtest: btn_stop_playtest.disabled = false
	if lbl_sim_status:
		lbl_sim_status.text = "SIMULATOR ACTIVE: Map %d (%s) running live at (%.0f, %.0f)!" % [
			target_map_id, active_map_name, spawn_pos.x, spawn_pos.y
		]

func stop_playtest() -> void:
	if _simulator_instance and is_instance_valid(_simulator_instance):
		_simulator_instance.queue_free()
		_simulator_instance = null
	
	is_simulator_running = false
	if btn_launch_playtest: btn_launch_playtest.disabled = false
	if btn_stop_playtest: btn_stop_playtest.disabled = true
	if lbl_sim_status:
		lbl_sim_status.text = "Simulator stopped. Ready to launch."

func _on_sim_map_changed(map_id: int, map_name: String) -> void:
	active_map_id = map_id
	if lbl_sim_status:
		lbl_sim_status.text = "SIMULATOR: Map %d (%s)" % [map_id, map_name]
	if opt_sim_map:
		for i in range(opt_sim_map.item_count):
			if opt_sim_map.get_item_id(i) == map_id:
				opt_sim_map.selected = i
				break

func _get_simulator_hud() -> Control:
	if not _simulator_instance or not is_instance_valid(_simulator_instance):
		return null
	var hud_node: Control = _simulator_instance.get_node_or_null("CanvasLayer/HUD") as Control
	if not hud_node:
		hud_node = _simulator_instance.get_node_or_null("HUD") as Control
	if not hud_node and "hud" in _simulator_instance and _simulator_instance.hud:
		hud_node = _simulator_instance.hud as Control
	if hud_node and not hud_node.inventory_ctrl:
		hud_node._ready()
	return hud_node

func _on_btn_sim_give_item_pressed() -> void:
	if not _simulator_instance or not is_instance_valid(_simulator_instance):
		if lbl_sim_status: lbl_sim_status.text = "Launch Playtest first to grant items!"
		return
	var item_id: int = int(spin_sim_item_id.value) if spin_sim_item_id else 34014
	var count: int = int(spin_sim_item_count.value) if spin_sim_item_count else 1
	var hud := _get_simulator_hud()
	if not hud:
		if lbl_sim_status: lbl_sim_status.text = "HUD not found in playtest simulator!"
		return
	var item_name := "Item %d" % item_id
	var icon_id: int = 1000
	var gdb = _game_database if _game_database else (get_node_or_null("/root/GameDatabase") if is_inside_tree() else null)
	if gdb and gdb.items:
		var rec = gdb.items.get_item(item_id)
		if rec:
			if not rec.name.is_empty(): item_name = rec.name
			if rec.icon_id > 0: icon_id = rec.icon_id
	if hud.has_method("add_inventory_item"):
		var added: bool = hud.add_inventory_item(item_id, count, item_name, icon_id)
		if lbl_sim_status:
			lbl_sim_status.text = ("Granted %s x%d (ID: %d)!" % [item_name, count, item_id]) if added else "Inventory is full!"
		if hud.has_method("add_chat_message"):
			hud.add_chat_message("System", "Playtest Simulator: Granted %s x%d" % [item_name, count], "System")

func _on_btn_sim_give_gold_pressed() -> void:
	if not _simulator_instance or not is_instance_valid(_simulator_instance):
		if lbl_sim_status: lbl_sim_status.text = "Launch Playtest first to grant gold!"
		return
	var hud := _get_simulator_hud()
	if hud and hud.has_method("add_gold"):
		hud.add_gold(10000)
		if lbl_sim_status: lbl_sim_status.text = "Granted +10,000 Gold!"
		if hud.has_method("add_chat_message"):
			hud.add_chat_message("System", "Playtest Simulator: Added 10,000 Gold", "System")

func _on_btn_sim_clear_inventory_pressed() -> void:
	if not _simulator_instance or not is_instance_valid(_simulator_instance):
		return
	var hud := _get_simulator_hud()
	if not hud:
		return
	if hud.has_method("clear_inventory"):
		hud.clear_inventory()
	elif "inventory_ctrl" in hud and hud.inventory_ctrl and hud.inventory_ctrl.has_method("clear_inventory"):
		hud.inventory_ctrl.clear_inventory()
	elif "inventory" in hud and hud.inventory != null:
		if hud.inventory.has_method("clear_all_items"):
			hud.inventory.clear_all_items()
	if lbl_sim_status: lbl_sim_status.text = "Inventory bag cleared."
