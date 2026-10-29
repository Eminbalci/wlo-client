class_name MapView
extends Node2D

## World coordinator for Wonderland Online MapView.
## Connects MapRenderer, PlayerEntity, NpcEntity, Camera2D, HUD,
## dynamic Ground Warp Portals (Wem.MMG / Eve.emg), and
## dynamic Ground Resource Harvesting (Eve.emg ItemAreas).

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const GroundParser = preload("res://scripts/map/ground_parser.gd")
const GroundItem = preload("res://scripts/map/ground_item.gd")
const CharacterManager = preload("res://scripts/ui/auth/character_manager.gd")
const SinkingCutsceneController = preload("res://scripts/events/sinking_cutscene.gd")
const NpcStateEvaluator = preload("res://scripts/map/npc_state_evaluator.gd")
const EncounterSystemScript = preload("res://scripts/map/encounter_system.gd")
const NpcEventScript = preload("res://scripts/map/npc_event_script.gd")
const BattleViewScene = preload("res://scenes/battle/battle_view.tscn")

signal ground_item_harvested(item: GroundItem, player: Node2D)
signal map_changed(map_id: int, map_name: String)

@onready var map_renderer: Node2D = $MapRenderer
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $CanvasLayer/HUD
@onready var player: Node2D = $Entities/Player
@onready var entities: Node2D = $Entities
@onready var sinking_cutscene: SinkingCutsceneController = $SinkingCutscene if has_node("SinkingCutscene") else null

var quest_component: QuestDialogueComponent = null

var _interacting_npc_id: int = 0
var _active_dialogue_npc: Node2D = null
var _is_captain_dialogue_active: bool = false
var _sinking_triggered: bool = false
var _island_warped: bool = false

var _bgm_player: AudioStreamPlayer = null
var bgm_player: AudioStreamPlayer:
	get:
		if not _bgm_player:
			if has_node("BgmPlayer"):
				_bgm_player = get_node("BgmPlayer") as AudioStreamPlayer
			else:
				_bgm_player = AudioStreamPlayer.new()
				_bgm_player.name = "BgmPlayer"
				if AudioServer.get_bus_index("BGM") == -1 and ResourceLoader.exists("res://scripts/ui/hud/system_window.gd"):
					var sys_script = load("res://scripts/ui/hud/system_window.gd")
					if sys_script and sys_script.has_method("ensure_audio_buses"):
						sys_script.ensure_audio_buses()
				_bgm_player.bus = &"BGM" if AudioServer.get_bus_index("BGM") != -1 else &"Master"
				_bgm_player.finished.connect(func() -> void:
					if _bgm_player and _bgm_player.stream and not _bgm_player.playing:
						_bgm_player.play()
				)
				add_child(_bgm_player)
		return _bgm_player
	set(val):
		_bgm_player = val

const CURSOR_FRAME_INTERVAL: float = 0.1 # 10 fps (matching cursor1.ani jif_rate 10)

var cursor_frames: Array[ImageTexture] = []
var _cursor_frames: Array[ImageTexture]:
	get:
		return cursor_frames
	set(val):
		cursor_frames = val
var _cursor_frame_index: int = 0
var _cursor_timer: float = 0.0

var ground_parser: GroundParser = null
var _dynamic_portals: Array[Portal] = []
var _dynamic_ground_items: Array[GroundItem] = []
var _pending_pickup_item: GroundItem = null
var _pending_npc_interaction: Node2D = null
var _opened_containers: Dictionary = {}

func _get_autoload_node(autoload_path: String) -> Node:
	if is_inside_tree():
		return get_node_or_null(autoload_path)
	return null

func _ready() -> void:
	ground_parser = GroundParser.new()

	# Initialize QuestDialogueComponent and starter quests early
	ensure_quest_component()
	
	# Load authentic animated cursor frames
	var loader := _get_autoload_node("/root/ArchiveLoader")
	if loader and loader.has_method("get_cursor_frames"):
		cursor_frames = loader.get_cursor_frames()
	if not cursor_frames.is_empty():
		Input.set_custom_mouse_cursor(cursor_frames[0], Input.CURSOR_ARROW, Vector2(0, 0))
	
	if map_renderer:
		if not map_renderer.tile_clicked.is_connected(_on_tile_clicked):
			map_renderer.tile_clicked.connect(_on_tile_clicked)
		if not map_renderer.map_loaded.is_connected(_on_map_loaded):
			map_renderer.map_loaded.connect(_on_map_loaded)
	
	if player:
		if player.has_signal("movement_blocked") and not player.movement_blocked.is_connected(_on_player_movement_blocked):
			player.movement_blocked.connect(_on_player_movement_blocked)
		if map_renderer and "_map_data" in map_renderer:
			player.map_data = map_renderer._map_data
		if not player.position_updated.is_connected(_on_player_position_updated):
			player.position_updated.connect(_on_player_position_updated)
		if player.has_signal("stats_changed") and not player.stats_changed.is_connected(_on_player_stats_changed):
			player.stats_changed.connect(_on_player_stats_changed)
		
		# Ensure hud.player = player is set before applying character data
		if hud and "player" in hud:
			hud.player = player

		# Apply active character from Auth/Character Select flow if present, or fallback to Daniel (Role 6)
		var gdb := _get_autoload_node("/root/GameDatabase")
		var char_data: Dictionary = gdb.active_character if (gdb and not gdb.active_character.is_empty()) else {}
		if char_data.is_empty():
			var cm_char: Dictionary = CharacterManager.get_character(0, "default")
			if not cm_char.is_empty():
				char_data = cm_char
			else:
				char_data = {
					"name": "Daniel",
					"role_id": 6,
					"role_name": "Daniel",
					"element": "Fire",
					"level": 10,
					"hp": 245,
					"max_hp": 245,
					"sp": 180,
					"max_sp": 180
				}
		
		call_deferred("_restore_single_player_state")
		if "role_id" in char_data and player.has_method("set_role"):
			player.set_role(int(char_data.role_id))
		if "name" in char_data:
			player.character_name = str(char_data.name)
		if "level" in char_data:
			player.level = int(char_data.level)
		if "hp" in char_data:
			player.hp = int(char_data.hp)
			player.max_hp = int(char_data.get("max_hp", char_data.hp))
		if "sp" in char_data:
			player.sp = int(char_data.sp)
			player.max_sp = int(char_data.get("max_sp", char_data.sp))
		if hud and hud.has_method("apply_character_data"):
			hud.apply_character_data(char_data)
		else:
			if hud and hud.has_method("set_player_role"):
				hud.set_player_role(int(char_data.get("role_id", 6)))
			if hud and hud.has_method("set_player_element") and "element" in char_data:
				hud.set_player_element(str(char_data.element))
		
		_update_camera_to_player()
		if camera and camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
		if hud:
			if hud.has_signal("dialogue_closed") and not hud.dialogue_closed.is_connected(Callable(self, "_on_dialogue_closed")):
				hud.dialogue_closed.connect(Callable(self, "_on_dialogue_closed"))
			if hud.has_signal("minimap_clicked") and not hud.minimap_clicked.is_connected(_on_minimap_clicked):
				hud.minimap_clicked.connect(_on_minimap_clicked)
			if "player" in hud:
				hud.player = player
			if hud.has_signal("equipment_changed") and player.has_method("set_equipment"):
				if not hud.equipment_changed.is_connected(player.set_equipment):
					hud.equipment_changed.connect(player.set_equipment)
			if player.has_signal("equipment_changed") and hud.has_method("set_equipment"):
				if not player.equipment_changed.is_connected(hud.set_equipment):
					player.equipment_changed.connect(hud.set_equipment)
			if hud.has_method("update_coordinates"):
				hud.update_coordinates(player.world_position)
			if hud.has_method("set_player_stats"):
				hud.set_player_stats(
					player.character_name,
					player.level,
					player.hp,
					player.max_hp,
					player.sp,
					player.max_sp,
					player.exp_percent
				)
			_connect_team_window()
	
	# Connect existing static NPCs
	if entities:
		for child in entities.get_children():
			if child != player and (child is NpcEntity or child.has_signal("npc_interacted")):
				if not child.npc_interacted.is_connected(interact_with_npc):
					child.npc_interacted.connect(interact_with_npc)
				if child is NpcEntity and map_renderer and "_map_data" in map_renderer:
					child.map_data = map_renderer._map_data
			elif child is Portal:
				# Remove static scene portals in favor of dynamic parser portals
				if child.has_signal("portal_triggered") and child.portal_triggered.is_connected(_on_portal_triggered):
					child.portal_triggered.disconnect(_on_portal_triggered)
				child.set_process(false)
				child.queue_free()
		_init_map_entity_tracking()
	
	if camera:
		if is_inside_tree():
			var vp: Viewport = get_viewport()
			if vp and not vp.size_changed.is_connected(update_camera_limits):
				vp.size_changed.connect(update_camera_limits)
			if get_tree() and get_tree().root:
				if not get_tree().root.size_changed.is_connected(update_camera_limits):
					get_tree().root.size_changed.connect(update_camera_limits)
		update_camera_limits()
	
	var initial_map: int = map_renderer.current_map_id if map_renderer else 10001
	_spawn_map_portals(initial_map)
	_spawn_ground_items(initial_map)
	_spawn_map_objects(initial_map)
	_init_starter_quests()
	_refresh_all_npc_quest_markers()
	_ensure_sinking_cutscene()
	_on_map_loaded(initial_map)

var _cabin_entities_created: bool = false
var _kitchen_entities_created: bool = false
var _deck_entities: Array[Node] = []
var _cabin_entities: Array[Node] = []
var _kitchen_entities: Array[Node] = []
var _dynamic_npcs: Array[NpcEntity] = []
var _dynamic_map_objects: Array[Node] = []
var _animated_map_objects: Array[Dictionary] = []
var _quest_states: Dictionary = {}
var _quest_entries: Array[Dictionary] = []
var _party_companions: Array[int] = []
var _player_pets: Array[int] = []
var _companion_follower: NpcEntity = null
var _active_companion_data: Dictionary = {}
var _follower_trail: Array[Vector2] = []

## Lazily initializes and returns the quest component
func ensure_quest_component() -> QuestDialogueComponent:
	if not quest_component:
		if has_node("QuestDialogueComponent"):
			quest_component = get_node("QuestDialogueComponent") as QuestDialogueComponent
		else:
			quest_component = QuestDialogueComponent.new()
			quest_component.name = "QuestDialogueComponent"
			add_child(quest_component)
		if quest_component:
			quest_component.hud = hud
			if not quest_component.quest_completed.is_connected(_on_quest_completed):
				quest_component.quest_completed.connect(_on_quest_completed)
			if not quest_component.quest_reward_displayed.is_connected(_on_quest_reward_displayed):
				quest_component.quest_reward_displayed.connect(_on_quest_reward_displayed)
			if not quest_component.quest_objective_completed.is_connected(_on_quest_objective_completed):
				quest_component.quest_objective_completed.connect(_on_quest_objective_completed)
		_init_starter_quests()
	return quest_component

func _init_starter_quests() -> void:
	if not quest_component:
		if has_node("QuestDialogueComponent"):
			quest_component = get_node("QuestDialogueComponent") as QuestDialogueComponent
		else:
			quest_component = QuestDialogueComponent.new()
			quest_component.name = "QuestDialogueComponent"
			add_child(quest_component)
	if quest_component:
		quest_component.hud = hud
		if not quest_component.quest_completed.is_connected(_on_quest_completed):
			quest_component.quest_completed.connect(_on_quest_completed)
		if not quest_component.quest_reward_displayed.is_connected(_on_quest_reward_displayed):
			quest_component.quest_reward_displayed.connect(_on_quest_reward_displayed)
		if not quest_component.quest_objective_completed.is_connected(_on_quest_objective_completed):
			quest_component.quest_objective_completed.connect(_on_quest_objective_completed)

	if quest_component.active_quests.is_empty() and quest_component.completed_quests.is_empty():
		# Quest 1001: "The Awakening Voyage"
		quest_component.register_quest({
			"quest_id": 1001,
			"quest_title": "The Awakening Voyage",
			"current_step": 0,
			"objectives": [
				{
					"step_index": 0,
					"type": "TalkToNPC",
					"npc_id": 14003,
					"npc_name": "Captain Robinson",
					"map_id": 10001,
					"talk_id": 30124,
					"description": "Talk to Captain Robinson (NPC 14003) on Ship Deck (Map 10001).",
					"dialogue_preview": "Welcome aboard the Ocean Star! Enjoy the ocean voyage, passenger."
				},
				{
					"step_index": 1,
					"type": "SurviveSinking",
					"map_id": 10003,
					"description": "Survive Ship Sinking & Awaken on Deserted Island (Map 10003).",
					"dialogue_preview": "Survive the violent tempest and awaken on the deserted island."
				},
				{
					"step_index": 2,
					"type": "TalkToNPC",
					"npc_id": 12032,
					"alt_npc_ids": [14062],
					"npc_name": "Kelang",
					"map_id": 10003,
					"talk_id": 20305,
					"description": "Talk to Kelang (NPC 12032) on Monkey Beach.",
					"dialogue_preview": "Hey! Are you okay? You washed ashore from the shipwreck. Take these coconuts and gather your strength."
				}
			],
			"rewards": {
				"reward_gold": 100,
				"reward_exp": 250,
				"reward_items": [
					{
						"item_id": 41066,
						"item_name": "Fresh Coconut",
						"count": 3,
						"icon_id": 1379
					}
				]
			}
		})

		# Quest 1002: "Supplies from the Wreck"
		quest_component.register_quest({
			"quest_id": 1002,
			"quest_title": "Supplies from the Wreck",
			"current_step": 0,
			"objectives": [
				{
					"step_index": 0,
					"type": "SearchContainer",
					"target": "beach_chest",
					"map_id": 10003,
					"description": "Search washed up beach chests/containers.",
					"dialogue_preview": "Examine the wreckage and washed up supplies on the shore."
				},
				{
					"step_index": 1,
					"type": "TalkToNPC",
					"npc_id": 12032,
					"alt_npc_ids": [14062],
					"npc_name": "Kelang",
					"map_id": 10003,
					"talk_id": 20307,
					"description": "Report back to Kelang (NPC 12032).",
					"dialogue_preview": "You recovered vital supplies from the wreckage! Keep this protective pill for your journey ahead."
				}
			],
			"rewards": {
				"reward_gold": 150,
				"reward_exp": 300,
				"reward_items": [
					{
						"item_id": 34026,
						"item_name": "Protective EXP Pill",
						"count": 1,
						"icon_id": 1768
					}
				]
			}
		})

		# Quest 1003: "Hill Pepper" (Authentic Kelan Village Quest: Doll & Emilie)
		quest_component.register_quest({
			"quest_id": 1003,
			"quest_title": "Hill Pepper",
			"current_step": 0,
			"objectives": [
				{
					"step_index": 0,
					"type": "TalkToNPC",
					"npc_id": 14141,
					"npc_name": "Doll",
					"map_id": 10002,
					"talk_id": 20222,
					"description": "Talk to Doll (NPC 14141) cooking supper in Kelan Village.",
					"dialogue_preview": "The flavor is not quite right, it needs more seasoning... can you get some Hill Pepper for me?"
				},
				{
					"step_index": 1,
					"type": "TalkToNPC",
					"npc_id": 14140,
					"npc_name": "Emilie",
					"map_id": 10002,
					"talk_id": 20336,
					"description": "Find Emilie (NPC 14140) by north stairs and solve her math riddle (Answer: 29).",
					"dialogue_preview": "Answer my age riddle correctly to receive the Hill Pepper."
				},
				{
					"step_index": 2,
					"type": "TalkToNPC",
					"npc_id": 14141,
					"npc_name": "Doll",
					"map_id": 10002,
					"talk_id": 20233,
					"description": "Deliver the Hill Pepper back to Doll in Kelan Village.",
					"dialogue_preview": "Doll, I have the Hill Pepper now. The supper is saved!"
				}
			],
			"rewards": {
				"reward_gold": 200,
				"reward_exp": 500,
				"reward_items": [
					{
						"item_id": 34076,
						"item_name": "Radio Set",
						"count": 1,
						"icon_id": 6
					}
				]
			}
		})

	_sync_hud_quest_log()

func _sync_hud_quest_log() -> void:
	if quest_component:
		_quest_entries = quest_component.get_quest_log_entries()
	if hud and hud.has_method("update_quest_log"):
		hud.update_quest_log(_quest_entries)

func _refresh_all_npc_quest_markers() -> void:
	if not entities:
		return
	var q1001_done: bool = quest_component.is_quest_completed(1001) if quest_component else (_quest_states.get(1, {}).get("state", 0) >= 2)
	var q1002_done: bool = quest_component.is_quest_completed(1002) if quest_component else (_quest_states.get(2, {}).get("state", 0) >= 2)
	var q3_done: bool = _quest_states.get(3, {}).get("state", 0) >= 2
	for child in entities.get_children():
		if not (child is NpcEntity) or not is_instance_valid(child):
			continue
		var npc: NpcEntity = child as NpcEntity
		if npc.npc_id == 14003 or "captain" in npc.npc_name.to_lower():
			npc.set_quest_marker("none" if q1001_done else "available")
		elif npc.npc_id in [12032, 14062] or "kelang" in npc.npc_name.to_lower():
			npc.set_quest_marker("none" if (q1001_done and q1002_done) else "available")
		elif npc.npc_id in [10000, 14303]:
			npc.set_quest_marker("none" if q3_done else "available")

func _on_quest_completed(quest_id: int, rewards: Dictionary) -> void:
	# 1. Award rewards to player and inventory
	var gold: int = int(rewards.get("reward_gold", rewards.get("gold", 0)))
	if gold > 0:
		if hud and hud.has_method("add_gold"):
			hud.add_gold(gold)
		if player and "gold" in player:
			player.gold += gold

	var exp_pts: int = int(rewards.get("reward_exp", rewards.get("exp", 0)))
	if exp_pts > 0:
		var status = hud.character_status_ctrl if (hud and "character_status_ctrl" in hud) else null
		if status:
			status.add_experience(exp_pts)
		elif player and "exp_percent" in player:
			player.exp_percent = minf(100.0, player.exp_percent + (float(exp_pts) / 10.0))

	var items: Array = rewards.get("reward_items", rewards.get("items", []))
	for it in items:
		if it is Dictionary:
			var i_id: int = int(it.get("item_id", 0))
			var i_count: int = int(it.get("count", 1))
			var i_name: String = str(it.get("item_name", "Item"))
			var i_icon: int = int(it.get("icon_id", -1))
			if hud and hud.has_method("add_inventory_item"):
				hud.add_inventory_item(i_id, i_count, i_name, i_icon)

	# 2. Persist character progress if character manager active
	var cm_char: Dictionary = CharacterManager.get_character(0, "default")
	if not cm_char.is_empty():
		if player and "gold" in player:
			cm_char["gold"] = player.gold
		if player and "exp_percent" in player:
			cm_char["exp_percent"] = player.exp_percent
		CharacterManager.save_character(0, cm_char, "default")

	_save_to_slot()
	# 3. Synchronize quest log & NPC quest markers
	_sync_hud_quest_log()
	_refresh_all_npc_quest_markers()

	# 4. Center toast notification
	var q_title := "Quest"
	if quest_component:
		var q_data := quest_component.get_completed_quest(quest_id)
		q_title = str(q_data.get("quest_title", "Quest #%d" % quest_id))
	var toast_msg := "Quest Completed: %s!" % q_title
	if hud and hud.has_method("show_center_notification"):
		hud.show_center_notification(toast_msg, 0)
	elif hud and hud.has_method("show_banner"):
		hud.show_banner(toast_msg)

func _on_quest_reward_displayed(msg: String) -> void:
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", msg, "System")
	if hud and hud.has_method("play_sfx"):
		hud.play_sfx("wav9911")
	if hud and hud.has_method("show_center_notification"):
		hud.show_center_notification(msg, 0)
	elif hud and hud.has_method("show_banner"):
		hud.show_banner(msg)

func _on_quest_objective_completed(quest_id: int, step_index: int) -> void:
	_sync_hud_quest_log()
	_refresh_all_npc_quest_markers()
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", "Quest Objective Updated!", "System")

## Dynamically spawns authentic Ground.MMG + Wem.MMG + images1*.BMg / images4*.BMg map objects:
## - Foreground occlusion sprites (flag2 in [3, 5] and flag3 == 0): Y-sorted inside Entities so players and NPCs walk behind ship masts, counters, trees, and pillars.
## - Background animated layer sprites (flag2 == 1 or flag3 == 1): placed inside MapRenderer behind Entities.
func _spawn_map_objects(map_id: int) -> void:
	for obj in _dynamic_map_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_dynamic_map_objects.clear()
	_animated_map_objects.clear()

	if not ground_parser or not entities:
		return
	var loader := _get_autoload_node("/root/ArchiveLoader")
	if not loader or not loader.has_method("get_map_object_texture"):
		return

	var lookup_map_id: int = 10003 if map_id == 10011 else map_id
	var gm: GroundParser.GroundMap = ground_parser.load_map(lookup_map_id)
	if not gm or gm.triggers.is_empty():
		return

	for t in gm.triggers:
		var wem: GroundParser.WemEvent = ground_parser.load_wem_event(t.event_id)
		if not wem:
			continue
		var tex: ImageTexture = loader.get_map_object_texture(t.event_id)
		if not tex:
			continue

		var num_frames: int = maxi(1, wem.trigger_type)
		var frame_w: int = tex.get_width()
		var frame_h: int = int(tex.get_height() / num_frames)
		if frame_w <= 0 or frame_h <= 0:
			continue

		if wem.flag2 == 1 or wem.flag3 == 1:
			if map_renderer:
				var bg_spr := Sprite2D.new()
				bg_spr.name = "MapBgObj_%d" % t.event_id
				bg_spr.texture = tex
				bg_spr.centered = false
				bg_spr.position = Vector2(t.world_x, t.world_y)
				bg_spr.z_index = 0
				if num_frames > 1:
					bg_spr.region_enabled = true
					bg_spr.region_rect = Rect2(0, 0, frame_w, frame_h)
					_animated_map_objects.append({
						"sprite": bg_spr,
						"num_frames": num_frames,
						"frame_w": frame_w,
						"frame_h": frame_h,
						"interval": maxf(0.1, float(wem.param) / 1000.0),
						"timer": 0.0,
						"frame": 0
					})
				map_renderer.add_child(bg_spr)
				_dynamic_map_objects.append(bg_spr)
		elif wem.flag2 in [3, 5] and wem.flag3 == 0:
			var sort_y: int = maxi(t.world_y + frame_h, t.world_y + wem.sub_id * 20)
			var fg_spr := Sprite2D.new()
			fg_spr.name = "MapFgObj_%d" % t.event_id
			fg_spr.texture = tex
			fg_spr.centered = false
			fg_spr.position = Vector2(t.world_x, sort_y)
			fg_spr.offset = Vector2(0.0, -float(sort_y - t.world_y))
			fg_spr.z_index = clampi(sort_y, -4096, 4096)
			if num_frames > 1:
				fg_spr.region_enabled = true
				fg_spr.region_rect = Rect2(0, 0, frame_w, frame_h)
				_animated_map_objects.append({
					"sprite": fg_spr,
					"num_frames": num_frames,
					"frame_w": frame_w,
					"frame_h": frame_h,
					"interval": maxf(0.1, float(wem.param) / 1000.0),
					"timer": 0.0,
					"frame": 0
				})
			entities.add_child(fg_spr)
			_dynamic_map_objects.append(fg_spr)

## Updates a quest state and dynamically refreshes NPC visibility across the map
func set_quest_state(quest_id: int, state: int, step: int = 0) -> void:
	_quest_states[quest_id] = {"state": state, "step": step}
	refresh_npc_visibilities()

## Adds or removes a recruited story companion from the active party
func set_party_companion(companion_id: int, present: bool = true) -> void:
	if present:
		if not _party_companions.has(companion_id):
			_party_companions.append(companion_id)
	else:
		_party_companions.erase(companion_id)
	refresh_npc_visibilities()

## Refreshes visibility, interaction, and movement for all active dynamic NPCs on the map
func refresh_npc_visibilities() -> void:
	if not map_renderer or _dynamic_npcs.is_empty():
		return
	var mid: int = map_renderer.current_map_id
	var eve := ground_parser.eve_parser if ground_parser else null
	for npc in _dynamic_npcs:
		if is_instance_valid(npc):
			var vis: bool = NpcStateEvaluator.should_npc_be_visible(
				mid, npc.click_id, _quest_states, _party_companions, _player_pets, npc.is_broken, eve
			)
			npc.set_preevent_visibility(vis)

## Spawns an active companion follower behind the player in the overland map
func spawn_companion_follower(companion_data: Dictionary) -> NpcEntity:
	despawn_companion_follower()
	_follower_trail.clear()
	var follower_scene = load("res://scenes/world/npc.tscn")
	var follower: NpcEntity = null
	if follower_scene:
		follower = follower_scene.instantiate() as NpcEntity
	if not follower:
		follower = NpcEntity.new()

	var cid: int = int(companion_data.get("npc_id", companion_data.get("id", 8090)))
	var cname: String = str(companion_data.get("name", "Companion"))
	follower.name = "CompanionFollower"
	follower.npc_id = cid
	follower.npc_name = cname

	var jmp: String = str(companion_data.get("model_jmp", ""))
	if jmp.is_empty():
		match cid:
			8090, 14161, 14162, 15002: jmp = "1221.jmp" # Roca
			14062: jmp = "1131.jmp" # Kelan Leader
			17162, 14997, 10727: jmp = "1103.jmp" # S. Monkey
			12032, 14003: jmp = "1195.jmp" # Robinson
			14081, 15267: jmp = "1223.jmp" # Niss
			12059, 12217: jmp = "1260.jmp" # Frederico
			_: jmp = "1221.jmp"
	follower.model_jmp = jmp
	follower.model_jma = "001.jma"

	# Calculate trailing position behind player
	var p_pos: Vector2 = player.world_position if (player and "world_position" in player) else Vector2.ZERO
	var p_heading: int = player.current_heading if (player and "current_heading" in player) else IsometricMath.Heading.SOUTH
	var back_vec: Vector2 = -IsometricMath.get_heading_vector(p_heading)
	if back_vec.is_zero_approx():
		back_vec = Vector2(-32.0, 16.0)
	else:
		back_vec = back_vec.normalized() * 48.0
	follower.world_position = p_pos + back_vec
	follower.heading = p_heading
	follower.is_moving = false

	# Followers must not block ground clicks or intercept NPC interaction
	var click_area = follower.get_node_or_null("ClickArea")
	if click_area and click_area is Area2D:
		click_area.monitoring = false
		click_area.monitorable = false
		click_area.input_pickable = false

	if entities:
		entities.add_child(follower)
	elif is_inside_tree():
		add_child(follower)

	_companion_follower = follower
	_active_companion_data = companion_data.duplicate(true)

	if not _party_companions.has(cid):
		_party_companions.append(cid)
	refresh_npc_visibilities()
	return follower

## Despawns the active companion follower from the overland map
func despawn_companion_follower() -> void:
	_follower_trail.clear()
	if _companion_follower and is_instance_valid(_companion_follower):
		if entities and _companion_follower.get_parent() == entities:
			entities.remove_child(_companion_follower)
		elif _companion_follower.get_parent():
			_companion_follower.get_parent().remove_child(_companion_follower)
		_companion_follower.queue_free()
	_companion_follower = null
	if not _active_companion_data.is_empty():
		var cid: int = int(_active_companion_data.get("npc_id", _active_companion_data.get("id", 0)))
		_party_companions.erase(cid)
		_active_companion_data.clear()
	refresh_npc_visibilities()

## Smoothly updates companion follower position and heading behind the player.
## Uses authentic breadcrumb path kinematics so the follower walks along the player's footsteps
## with continuous 4-frame walk animation, stopping and facing the player without snapping.
func update_companion_follower_position(player_world_pos: Vector2, delta: float = 0.0) -> void:
	if not _companion_follower or not is_instance_valid(_companion_follower):
		return
	
	var dt: float = delta if delta > 0.0 else (get_process_delta_time() if get_process_delta_time() > 0.0 else 0.016)
	var follower_pos: Vector2 = _companion_follower.world_position
	var dist_to_player: float = follower_pos.distance_to(player_world_pos)
	
	# Emergency warp only on extreme distance transitions (e.g. portal map switch)
	if dist_to_player > 900.0:
		_follower_trail.clear()
		var p_heading: int = player.current_heading if (player and "current_heading" in player) else IsometricMath.Heading.SOUTH
		var back_vec: Vector2 = -IsometricMath.get_heading_vector(p_heading)
		if back_vec.is_zero_approx():
			back_vec = Vector2(-32.0, 16.0)
		else:
			back_vec = back_vec.normalized() * 48.0
		_companion_follower.world_position = player_world_pos + back_vec
		_companion_follower.is_moving = false
		_companion_follower.heading = IsometricMath.get_heading(_companion_follower.world_position, player_world_pos)
		if "facing_direction" in _companion_follower:
			_companion_follower.facing_direction = _companion_follower.heading
		if _companion_follower.has_method("_update_frame"):
			_companion_follower._update_frame()
		return

	# Record breadcrumb positions as the player traverses the overland map
	var is_player_walking: bool = bool(player.is_moving) if (player and "is_moving" in player) else false
	if _follower_trail.is_empty():
		if dist_to_player > 48.0:
			_follower_trail.append(player_world_pos)
	else:
		var last_trail_pt: Vector2 = _follower_trail.back()
		if last_trail_pt.distance_to(player_world_pos) >= 20.0:
			_follower_trail.append(player_world_pos)

	# If player has stopped and follower is close enough (<= 48px), halt and face player
	if not is_player_walking and dist_to_player <= 48.0:
		_follower_trail.clear()
		if _companion_follower.is_moving:
			_companion_follower.is_moving = false
			if _companion_follower.has_method("_update_frame"):
				_companion_follower._update_frame()
		_companion_follower.heading = IsometricMath.get_heading(follower_pos, player_world_pos)
		if "facing_direction" in _companion_follower:
			_companion_follower.facing_direction = _companion_follower.heading
		return

	# Traverse recorded breadcrumbs
	if not _follower_trail.is_empty():
		var target_waypoint: Vector2 = _follower_trail[0]
		var dist_to_waypoint: float = follower_pos.distance_to(target_waypoint)
		
		# Once waypoint reached, advance to next
		if dist_to_waypoint <= 12.0:
			_follower_trail.pop_front()
			if not _follower_trail.is_empty():
				target_waypoint = _follower_trail[0]
				dist_to_waypoint = follower_pos.distance_to(target_waypoint)
			else:
				target_waypoint = player_world_pos
				dist_to_waypoint = follower_pos.distance_to(player_world_pos)

		if not _companion_follower.is_moving:
			_companion_follower.is_moving = true
			if _companion_follower.has_method("_update_frame"):
				_companion_follower._update_frame()

		var base_speed: float = float(player.move_speed) if (player and "move_speed" in player) else 120.0
		var move_speed: float = base_speed
		if dist_to_player > 160.0:
			move_speed = base_speed * 1.6
		elif dist_to_player > 80.0:
			move_speed = base_speed * 1.3

		var step: float = minf(dist_to_waypoint, move_speed * dt)
		_companion_follower.world_position = follower_pos.move_toward(target_waypoint, step)
		_companion_follower.heading = IsometricMath.get_heading(follower_pos, target_waypoint)
		if "facing_direction" in _companion_follower:
			_companion_follower.facing_direction = _companion_follower.heading
	elif dist_to_player > 48.0:
		# Direct fallback toward player if no trail recorded yet
		if not _companion_follower.is_moving:
			_companion_follower.is_moving = true
			if _companion_follower.has_method("_update_frame"):
				_companion_follower._update_frame()
		var base_speed: float = float(player.move_speed) if (player and "move_speed" in player) else 120.0
		var step: float = minf(dist_to_player - 48.0, base_speed * dt)
		_companion_follower.world_position = follower_pos.move_toward(player_world_pos, step)
		_companion_follower.heading = IsometricMath.get_heading(follower_pos, player_world_pos)
		if "facing_direction" in _companion_follower:
			_companion_follower.facing_direction = _companion_follower.heading

## Callback when companion is summoned or rested in TeamWindow
func _on_team_companion_toggled(companion_id: int, summoned: bool) -> void:
	if summoned:
		# If player was riding, dismount
		if player and player.has_method("is_riding") and player.is_riding():
			player.dismount_pet()
		var comp_data: Dictionary = {}
		if hud:
			var tw: Node = hud.get_node_or_null("FloatingWindows/TeamWindow")
			if tw and "active_companion" in tw:
				comp_data = tw.active_companion
		if comp_data.is_empty():
			comp_data = {"npc_id": companion_id, "id": companion_id, "name": "Companion"}
		spawn_companion_follower(comp_data)
	else:
		despawn_companion_follower()

## Callback when companion is mounted in Ride mode
func _on_team_companion_mounted(companion_data: Dictionary) -> void:
	despawn_companion_follower()
	if player and player.has_method("mount_pet"):
		player.mount_pet(companion_data)

## Callback when companion is dismounted from Ride mode
func _on_team_companion_dismounted(_companion_data: Dictionary) -> void:
	if player and player.has_method("dismount_pet"):
		player.dismount_pet()

## Connects TeamWindow companion signals
func _connect_team_window() -> void:
	if not hud:
		return
	var tw = hud.get_node_or_null("FloatingWindows/TeamWindow")
	if tw:
		if tw.has_signal("companion_toggled") and not tw.companion_toggled.is_connected(_on_team_companion_toggled):
			tw.companion_toggled.connect(_on_team_companion_toggled)
		if tw.has_signal("companion_mounted") and not tw.companion_mounted.is_connected(_on_team_companion_mounted):
			tw.companion_mounted.connect(_on_team_companion_mounted)
		if tw.has_signal("companion_dismounted") and not tw.companion_dismounted.is_connected(_on_team_companion_dismounted):
			tw.companion_dismounted.connect(_on_team_companion_dismounted)

func _init_map_entity_tracking() -> void:
	_deck_entities.clear()
	if entities:
		for child in entities.get_children():
			if child != player and not (child is Portal) and not (child is GroundItem):
				_deck_entities.append(child)

func _switch_map_entities(target_map_id: int) -> void:
	if _deck_entities.is_empty():
		_init_map_entity_tracking()

	# 1. Clear previously spawned generic dynamic NPCs, portals and ground items
	for npc in _dynamic_npcs:
		if is_instance_valid(npc):
			npc.visible = false
			if entities and npc.get_parent() == entities:
				entities.remove_child(npc)
			npc.queue_free()
	_dynamic_npcs.clear()

	_spawn_map_portals(target_map_id)
	_spawn_ground_items(target_map_id)
	_spawn_map_objects(target_map_id)

	var set_entity_vis = func(e: Node, p_vis: bool) -> void:
		if not is_instance_valid(e):
			return
		if e is NpcEntity:
			e.set_preevent_visibility(p_vis)
		elif "visible" in e:
			e.visible = p_vis

	# 2. Check hardcoded/scenario overrides vs universal spawner
	if target_map_id == 10001 and not _sinking_triggered:
		for e in _deck_entities:
			set_entity_vis.call(e, true)
		for e in _cabin_entities:
			set_entity_vis.call(e, false)
		for e in _kitchen_entities:
			set_entity_vis.call(e, false)
		for e in _beach_entities:
			set_entity_vis.call(e, false)
	elif target_map_id == 10002:
		for e in _deck_entities:
			set_entity_vis.call(e, false)
		for e in _kitchen_entities:
			set_entity_vis.call(e, false)
		for e in _beach_entities:
			set_entity_vis.call(e, false)
		if not _cabin_entities_created:
			_spawn_cabin_entities()
		else:
			for e in _cabin_entities:
				set_entity_vis.call(e, true)
	elif target_map_id == 10003:
		for e in _deck_entities:
			set_entity_vis.call(e, false)
		for e in _cabin_entities:
			set_entity_vis.call(e, false)
		_spawn_dynamic_map_npcs(10003)
		# Map 10003 is Newbie Island: only the 8 authentic Eve.emg entities belong here.
		for e in _beach_entities:
			set_entity_vis.call(e, false)
		if not _kitchen_entities_created:
			_spawn_kitchen_entities()
		for e in _kitchen_entities:
			set_entity_vis.call(e, false)
	else:
		# Universal dynamic entity spawner for any of the 1,119 maps in Eve.emg
		for e in _deck_entities:
			set_entity_vis.call(e, false)
		for e in _cabin_entities:
			set_entity_vis.call(e, false)
		for e in _kitchen_entities:
			set_entity_vis.call(e, false)
		for e in _beach_entities:
			set_entity_vis.call(e, false)
		_spawn_dynamic_map_npcs(target_map_id)
	_refresh_all_npc_quest_markers()

## Universal dynamic NPC spawner for any map in Eve.emg.
## Queries Eve.emg Category 0 NPC entries, resolves NpcDatabase records,
## loads authentic 128x128 JMA/JMP textures, configures headings & patrol paths,
## and connects interactive dialogue triggers to TalkDatabase.
func _spawn_dynamic_map_npcs(target_map_id: int) -> void:
	if not entities:
		entities = get_node_or_null("Entities")
	if not entities:
		return
	
	if not ground_parser:
		ground_parser = GroundParser.new()
	var eve_parser := ground_parser.eve_parser if ground_parser else null
	if not eve_parser:
		return
	
	var spawns: Array[EveParser.NpcSpawnInfo] = eve_parser.get_npcs_for_map(target_map_id)
	if spawns.is_empty():
		return
	
	var npc_scene: PackedScene = load("res://scenes/world/npc.tscn")
	if not npc_scene:
		return
	
	var game_db = _get_autoload_node("/root/GameDatabase")
	var loader = _get_autoload_node("/root/ArchiveLoader")
	
	for spawn in spawns:
		var npc: NpcEntity = npc_scene.instantiate() as NpcEntity
		if not npc:
			continue
		
		var npc_rec = null
		if game_db and "npcs" in game_db and game_db.npcs:
			npc_rec = game_db.npcs.get_npc(spawn.npc_id)
		
		var sprite_id: int = 0
		var resolved_name: String = spawn.name
		var resolved_level: int = 1
		var resolved_talk_image: int = 0
		
		if npc_rec:
			sprite_id = npc_rec.sprite_id
			resolved_level = npc_rec.level
			resolved_talk_image = npc_rec.talk_image
		resolved_name = NpcStateEvaluator.resolve_npc_display_name(spawn.name, npc_rec)
		
		# Evaluate authentic visibility state from C# server rules
		var is_visible: bool = NpcStateEvaluator.should_npc_be_visible(
			target_map_id,
			spawn.click_id,
			_quest_states,
			_party_companions,
			_player_pets,
			false,
			eve_parser
		)
		
		npc.name = "%s_%d" % [resolved_name.replace(" ", "_"), spawn.click_id]
		npc.npc_name = resolved_name
		npc.npc_id = spawn.npc_id
		npc.set_meta("eve_events", spawn.events.duplicate())
		npc.set_meta("eve_map", target_map_id)
		npc.click_id = spawn.click_id
		npc.template_id = spawn.npc_id
		npc.rotation = 0.0
		npc.eve_rotation = spawn.rotation
		npc.level = resolved_level
		npc.talk_image = resolved_talk_image
		
		# Authentic C# server QuestNpc stats & states
		npc.entity_type = spawn.entity_type
		npc.walk_behavior = spawn.walk_behavior
		npc.spawn_position = Vector2(spawn.world_x, spawn.world_y)
		if npc_rec:
			npc.max_hp = npc_rec.max_hp
			npc.hp = npc_rec.max_hp
			npc.max_sp = npc_rec.max_sp
			npc.sp = npc_rec.max_sp
			npc.element = npc_rec.element
		else:
			npc.max_hp = 100
			npc.hp = 100
			npc.max_sp = 50
			npc.sp = 50
			npc.element = 0
		npc.is_wild_monster = NpcStateEvaluator.is_wild_monster(spawn.npc_id, resolved_name)
		
		npc.world_position = Vector2(spawn.world_x, spawn.world_y)
		npc.heading = IsometricMath.rotation_to_heading(spawn.rotation)
		npc.facing_direction = npc.heading
		
		# Apply PreEvent visibility & disable click area if hidden
		npc.set_preevent_visibility(is_visible)
		
		if sprite_id > 0:
			npc.model_jmp = "%d.jmp" % sprite_id
			npc.model_jma = "%03d.jma" % int(sprite_id / 1000)
		
		var tex: Texture2D = null
		if loader:
			if loader.has_method("get_npc_texture"):
				tex = loader.get_npc_texture(sprite_id, npc.heading)
			if not tex and sprite_id > 0:
				var jma_pkg := "%03d.jma" % int(sprite_id / 1000)
				tex = loader.get_jma_frame_128(jma_pkg, "%d.jmp" % sprite_id, 0)
			if not tex:
				tex = loader.get_jma_frame_128("007.jma", "%d.jmp" % sprite_id, 0)
		if tex:
			npc.set_texture(tex)
		
		var c_key: int = target_map_id * 100000 + spawn.npc_id
		if _opened_containers.get(c_key, false):
			npc.is_broken = true
			if npc.has_method("_update_frame"):
				npc._update_frame()
		
		if not spawn.walksteps.is_empty():
			npc.walksteps = spawn.walksteps.duplicate()
			var delays: Array[float] = spawn.walkstep_delays.duplicate()
			for d_i in range(delays.size()):
				if delays[d_i] <= 0.0:
					delays[d_i] = 1.5
			npc.walkstep_delays = delays
			npc.move_speed = 60.0
		
		if spawn.npc_id in [19038, 19037, 19034, 19035]:
			npc.dialogue_text = "You searched the %s and found washed-up supplies!" % resolved_name
			npc.dialogue_choices = ["Take supplies"]
		elif spawn.npc_id == 12032:
			npc.dialogue_text = "Thank goodness you're awake! Check the chests and barrels washed ashore for supplies."
			npc.dialogue_choices = ["I'll look around.", "Are you hurt?"]
		elif spawn.npc_id == 11019:
			npc.dialogue_text = "Woof! Woof! *Burke wags his tail happily*"
			npc.dialogue_choices = ["*Pat Burke*"]
		else:
			# No invented greeting: the real client only talks when the server's event script / Talk.dat has a line for this NPC.
			npc.dialogue_text = ""
			npc.dialogue_choices = []

		if game_db and "talks" in game_db and game_db.talks:
			var talk_rec: Dictionary = game_db.talks.resolve_talk_for_npc(spawn.npc_id, target_map_id)
			if not talk_rec.is_empty():
				npc.talk_id = talk_rec.get("id", 0)
				if talk_rec.get("text", "") != "":
					npc.dialogue_text = talk_rec["text"]
				if talk_rec.has("choices") and not talk_rec["choices"].is_empty():
					var choices_arr: Array[String] = []
					for c in talk_rec["choices"]:
						if c is Dictionary and c.has("text"):
							choices_arr.append(c["text"])
						else:
							choices_arr.append(str(c))
					npc.dialogue_choices = choices_arr
		
		npc.npc_interacted.connect(interact_with_npc)
		
		if map_renderer and "_map_data" in map_renderer:
			npc.map_data = map_renderer._map_data
		
		entities.add_child(npc)
		_dynamic_npcs.append(npc)

	if not _active_companion_data.is_empty():
		spawn_companion_follower(_active_companion_data)

func _spawn_cabin_entities() -> void:
	_cabin_entities_created = true
	var npc_scene = load("res://scenes/world/npc.tscn")
	if not entities:
		entities = get_node_or_null("Entities")
	if not entities:
		return
	
	# 7 Authentic Map 10002 NPCs from Eve.emg & Npc.dat (heading = IsometricMath.rotation_to_heading(rotation))
	var cabin_npc_defs: Array[Dictionary] = [
		{"name": "Drunk Man", "id": 14042, "talk_id": 30127, "pos": Vector2(851, 539), "jmp": "1050.jmp", "heading": IsometricMath.Heading.NORTH_WEST, "dialogue": "Hic... Another drink! Don't look at me like that."},
		{"name": "Peter", "id": 14146, "talk_id": 30160, "pos": Vector2(1302, 800), "jmp": "1050.jmp", "heading": IsometricMath.Heading.NORTH_EAST, "dialogue": "Traveling by ship is relaxing.", "choices": ["Is everything alright?", "Need any help?"]},
		{"name": "John", "id": 14145, "talk_id": 30163, "pos": Vector2(1309, 714), "jmp": "1050.jmp", "heading": IsometricMath.Heading.SOUTH_EAST, "dialogue": "We should reach the harbor soon.", "choices": ["What are you doing here?", "See you around."]},
		{"name": "Natasha", "id": 14303, "talk_id": 30166, "pos": Vector2(1440, 682), "jmp": "1068.jmp", "heading": IsometricMath.Heading.SOUTH_WEST, "dialogue": "Hello! What brings you into the cabin?", "choices": ["Are you feeling okay?", "Just exploring the ship."]},
		{"name": "Breillat", "id": 10000, "talk_id": 30139, "pos": Vector2(1155, 580), "jmp": "1170.jmp", "heading": IsometricMath.Heading.SOUTH_WEST, "dialogue": "Welcome to Ocean Star! Relax and enjoy your voyage."},
		{"name": "Game Machine a", "id": 18000, "pos": Vector2(226, 795), "jmp": "1088.jmp", "heading": IsometricMath.Heading.SOUTH, "dialogue": "*BEEP BEEP* Wonderland Arcade Machine."},
		{"name": "Game Machine b", "id": 18001, "pos": Vector2(141, 829), "jmp": "1089.jmp", "heading": IsometricMath.Heading.SOUTH, "dialogue": "*BEEP BEEP* Wonderland Arcade Machine."},
	]
	
	for def in cabin_npc_defs:
		var npc: NpcEntity = npc_scene.instantiate()
		npc.name = def["name"].replace(" ", "") + "NPC"
		npc.npc_name = def["name"]
		npc.npc_id = def["id"]
		npc.talk_id = def.get("talk_id", 0)
		npc.model_jmp = def["jmp"]
		npc.model_jma = "001.jma"
		npc.world_position = def["pos"]
		npc.heading = def["heading"]
		npc.dialogue_text = def["dialogue"]
		var c_choices: Array = def.get("choices", ["Hello!", "Nice to meet you."])
		npc.dialogue_choices.assign(c_choices)
		if map_renderer and "_map_data" in map_renderer:
			npc.map_data = map_renderer._map_data
		npc.npc_interacted.connect(interact_with_npc)
		entities.add_child(npc)
		_cabin_entities.append(npc)

func _spawn_kitchen_entities() -> void:
	_kitchen_entities_created = true
	var npc_scene = load("res://scenes/world/npc.tscn")
	if not entities:
		entities = get_node_or_null("Entities")
	if not entities:
		return
	
	# Map 10003 NPCs (Chef, Kitchen Crew, Bunk Crew)
	var kitchen_npc_defs: Array[Dictionary] = [
		{
			"name": "Chef",
			"id": 12006,
			"talk_id": 30170,
			"pos": Vector2(780, 520),
			"jmp": "1144.jmp",
			"heading": IsometricMath.Heading.SOUTH_EAST,
			"dialogue": "Welcome to the ship kitchen! Fresh soup is simmering.",
			"choices": ["Can I have some food?", "Smells delicious!"]
		},
		{
			"name": "Kitchen Crew",
			"id": 14002,
			"talk_id": 30173,
			"pos": Vector2(950, 480),
			"jmp": "1037.jmp",
			"heading": IsometricMath.Heading.SOUTH_WEST,
			"dialogue": "Watch your step around the kitchen stoves!",
			"choices": ["Keep up the good work!"]
		},
		{
			"name": "Bunk Crew",
			"id": 14001,
			"talk_id": 30174,
			"pos": Vector2(620, 680),
			"jmp": "1037.jmp",
			"heading": IsometricMath.Heading.NORTH_EAST,
			"dialogue": "The bunks are cozy, but it's hard to sleep through rough waves.",
			"choices": ["Rest well!"]
		}
	]
	
	for def in kitchen_npc_defs:
		var npc: NpcEntity = npc_scene.instantiate()
		npc.name = def["name"].replace(" ", "") + "NPC"
		npc.npc_name = def["name"]
		npc.npc_id = def["id"]
		npc.talk_id = def.get("talk_id", 0)
		npc.model_jmp = def["jmp"]
		npc.model_jma = "001.jma"
		npc.world_position = def["pos"]
		npc.heading = def["heading"]
		npc.dialogue_text = def["dialogue"]
		var k_choices: Array = def.get("choices", [])
		npc.dialogue_choices.assign(k_choices)
		if map_renderer and "_map_data" in map_renderer:
			npc.map_data = map_renderer._map_data
		npc.npc_interacted.connect(interact_with_npc)
		entities.add_child(npc)
		_kitchen_entities.append(npc)
	
	# Map 10003 Ground Harvestable Items (Apple, Bread, Cutlery)
	var kitchen_item_defs: Array[Dictionary] = [
		{"item_id": 41040, "slot": 1, "click_id": 101, "name": "Apple", "icon_id": 1001, "pos": Vector2(710, 560)},
		{"item_id": 32011, "slot": 2, "click_id": 102, "name": "Bread", "icon_id": 1011, "pos": Vector2(860, 540)},
		{"item_id": 10002, "slot": 3, "click_id": 103, "name": "Cutlery", "icon_id": 1120, "pos": Vector2(800, 600)}
	]
	
	for idef in kitchen_item_defs:
		var g_item: GroundItem = GroundItem.new()
		g_item.name = "KitchenItem_%d" % idef["slot"]
		g_item.position = idef["pos"]
		g_item.set_item_data(idef["item_id"], idef["slot"], idef["click_id"], idef["name"], 120.0, idef["icon_id"])
		g_item.item_clicked.connect(_on_ground_item_clicked)
		g_item.item_picked_up.connect(_on_ground_item_picked_up)
		entities.add_child(g_item)
		_kitchen_entities.append(g_item)

## Dynamically spawns authoritative warp portals for map_id
func _spawn_map_portals(map_id: int) -> void:
	# Clean up previous dynamic portals
	for p in _dynamic_portals:
		if is_instance_valid(p):
			if p.portal_triggered.is_connected(_on_portal_triggered):
				p.portal_triggered.disconnect(_on_portal_triggered)
			p.set_process(false)
			p.queue_free()
	_dynamic_portals.clear()
	
	if not ground_parser or not entities:
		return
	
	var portal_defs := ground_parser.get_map_warp_portals(map_id)
	for def in portal_defs:
		var p: Portal = Portal.new()
		p.name = "DynamicPortal_%d_%d" % [map_id, def.portal_id]
		p.portal_id = def.portal_id
		p.portal_name = def.portal_name
		p.position = def.world_pos
		p.target_map_id = def.target_map_id
		p.target_coords = def.target_coords
		p.trigger_radius = def.get("trigger_radius", 56.0)
		p.portal_color = def.get("color", Color(0.2, 0.75, 1.0, 0.85))
		p.set_portal_style(int(def.get("portal_style", Portal.STYLE_DOOR)))
		p.portal_triggered.connect(_on_portal_triggered)
		entities.add_child(p)
		_dynamic_portals.append(p)
		
		# If player spawns directly inside this portal, suppress initial retrigger
		if player:
			var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
			var dx: float = (p_pos.x - p.position.x)
			var dy: float = (p_pos.y - p.position.y) * 2.0
			var player_cell := Vector2i(int(floor(p_pos.x / 20.0)), int(floor(p_pos.y / 20.0)))
			var portal_cell := Vector2i(int(floor(p.position.x / 20.0)), int(floor(p.position.y / 20.0)))
			if sqrt(dx * dx + dy * dy) <= p.trigger_radius + 30.0 or player_cell == portal_cell:
				p.mark_player_inside()

## Dynamically spawns authentic ground items from Eve.emg (ItemAreas)
func _spawn_ground_items(map_id: int) -> void:
	# Clean up previous ground items
	for it in _dynamic_ground_items:
		if is_instance_valid(it):
			it.queue_free()
	_dynamic_ground_items.clear()
	
	if not ground_parser or not ground_parser.eve_parser or not entities:
		return
	
	var spawns := ground_parser.eve_parser.get_ground_items_for_map(map_id)
	for s in spawns:
		var g_item: GroundItem = GroundItem.new()
		g_item.name = "GroundItem_%d_%d" % [map_id, s.slot]
		g_item.position = Vector2(s.world_x, s.world_y)
		g_item.set_item_data(s.item_id, s.slot, s.click_id, s.name, float(s.respawn_seconds))
		g_item.item_clicked.connect(_on_ground_item_clicked)
		g_item.item_picked_up.connect(_on_ground_item_picked_up)
		entities.add_child(g_item)
		_dynamic_ground_items.append(g_item)

func _process(delta: float) -> void:
	_update_camera_to_player()
	_update_cursor_hover_target()
	_update_cursor_animation(delta)

	# Smoothly update companion follower position & walk animation
	if _companion_follower and is_instance_valid(_companion_follower) and player:
		var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
		update_companion_follower_position(p_pos, delta)

	for anim_obj in _animated_map_objects:
		var spr: Sprite2D = anim_obj.get("sprite") as Sprite2D
		if not is_instance_valid(spr):
			continue
		var t_val: float = float(anim_obj.get("timer", 0.0)) + delta
		var interval: float = float(anim_obj.get("interval", 0.5))
		if t_val >= interval:
			t_val = fmod(t_val, interval)
			var next_f: int = (int(anim_obj.get("frame", 0)) + 1) % int(anim_obj.get("num_frames", 1))
			anim_obj["frame"] = next_f
			var fw: int = int(anim_obj.get("frame_w", 0))
			var fh: int = int(anim_obj.get("frame_h", 0))
			spr.region_rect = Rect2(0, next_f * fh, fw, fh)
		anim_obj["timer"] = t_val
	
	# Check pending ground item pickup
	if _pending_pickup_item and is_instance_valid(_pending_pickup_item) and not _pending_pickup_item.is_picked_up:
		if player:
			var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
			if p_pos.distance_to(_pending_pickup_item.position) <= _pending_pickup_item.pickup_distance:
				_execute_pickup(_pending_pickup_item)
				_pending_pickup_item = null

	# Check pending NPC interaction
	if _pending_npc_interaction != null:
		if not is_instance_valid(_pending_npc_interaction) or not _pending_npc_interaction.visible:
			_pending_npc_interaction = null
		elif player:
			var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
			var n_pos: Vector2 = _pending_npc_interaction.world_position if ("world_position" in _pending_npc_interaction) else _pending_npc_interaction.position
			var dist: float = p_pos.distance_to(n_pos)
			if dist <= 120.0:
				var target_npc = _pending_npc_interaction
				_pending_npc_interaction = null
				_active_dialogue_npc = target_npc
				if "original_heading" in target_npc:
					if target_npc.original_heading < 0 and "heading" in target_npc:
						target_npc.original_heading = target_npc.heading
				if "is_moving" in player:
					player.is_moving = false
				if "_current_waypoints" in player:
					player._current_waypoints.clear()
				if "current_heading" in player:
					player.current_heading = IsometricMath.get_heading(p_pos, n_pos)
					if player.has_signal("heading_changed"):
						player.heading_changed.emit(player.current_heading)
				if "heading" in target_npc:
					target_npc.heading = IsometricMath.get_heading(n_pos, p_pos)
					if "facing_direction" in target_npc:
						target_npc.facing_direction = target_npc.heading
				_on_npc_interacted(target_npc)
			elif not player.is_moving:
				var target_npc = _pending_npc_interaction
				_pending_npc_interaction = null
				if dist <= 160.0:
					_active_dialogue_npc = target_npc
					if "original_heading" in target_npc:
						if target_npc.original_heading < 0 and "heading" in target_npc:
							target_npc.original_heading = target_npc.heading
					if "current_heading" in player:
						player.current_heading = IsometricMath.get_heading(p_pos, n_pos)
						if player.has_signal("heading_changed"):
							player.heading_changed.emit(player.current_heading)
					if "heading" in target_npc:
						target_npc.heading = IsometricMath.get_heading(n_pos, p_pos)
						if "facing_direction" in target_npc:
							target_npc.facing_direction = target_npc.heading
					_on_npc_interacted(target_npc)

func _on_ground_item_clicked(item: GroundItem) -> void:
	if not player or not is_instance_valid(item) or item.is_picked_up:
		return
	
	var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
	var dist := p_pos.distance_to(item.position)
	if dist <= item.pickup_distance: # <= 180.0 px
		_execute_pickup(item)
	else:
		_pending_pickup_item = item
		if player.has_method("set_target_world_position"):
			player.set_target_world_position(item.position)

func _execute_pickup(item: GroundItem) -> bool:
	if not item or item.is_picked_up:
		return false
	
	var item_icon_tex: Texture2D = item._sprite.texture if (item._sprite and item._sprite.texture) else null
	var start_pos: Vector2 = item.global_position + Vector2(0, -6)
	var it_name: String = item.item_name
	var it_id: int = item.item_id
	var it_icon: int = item.icon_id
	
	var picked: bool = item.try_pickup(player)
	if picked:
		# Add to HUD inventory
		if hud and hud.has_method("add_inventory_item"):
			hud.add_inventory_item(it_id, 1, it_name, it_icon)
		
		ground_item_harvested.emit(item, player)
		
		var banner_txt := "%s x1 elde edildi!" % it_name
		var show_notif := func():
			if hud and hud.has_method("show_center_notification"):
				hud.show_center_notification(banner_txt, it_icon)
			elif hud and hud.has_method("show_banner"):
				hud.show_banner(banner_txt)
		
		# Animate flying item towards player if inside tree and player exists
		if item_icon_tex and player and is_inside_tree():
			var fly_icon := Sprite2D.new()
			fly_icon.name = "FlyPickupIcon"
			fly_icon.texture = item_icon_tex
			fly_icon.global_position = start_pos
			fly_icon.z_index = 100
			add_child(fly_icon)
			
			var target_pos: Vector2 = player.global_position if player is CanvasItem else player.position
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(fly_icon, "global_position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(fly_icon, "scale", Vector2(0.3, 0.3), 0.28).set_ease(Tween.EASE_IN)
			tw.chain().finished.connect(func():
				if is_instance_valid(fly_icon):
					fly_icon.queue_free()
				show_notif.call()
			)
		else:
			show_notif.call()
		
		return true
	return false

func _on_ground_item_picked_up(item: GroundItem, _collector: Node2D) -> void:
	pass

func _on_portal_triggered(portal: Node, target_map_id: int, target_coords: Vector2) -> void:
	if map_renderer and map_renderer.has_method("load_map"):
		map_renderer.load_map(target_map_id)
		if "_map_data" in map_renderer:
			if player:
				player.map_data = map_renderer._map_data
			if entities:
				for child in entities.get_children():
					if child is NpcEntity:
						child.map_data = map_renderer._map_data
	
	_switch_map_entities(target_map_id)
	
	if player:
		if player.has_method("teleport_to"):
			player.teleport_to(target_coords)
		else:
			if "world_position" in player:
				player.world_position = target_coords
			if "world_pos" in player:
				player.world_pos = target_coords
			player.position = target_coords
			if player.has_method("set_target_world_position"):
				player.set_target_world_position(target_coords)
		_update_camera_to_player()
		if camera and camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
		if hud and hud.has_method("update_coordinates"):
			hud.update_coordinates(target_coords)
	
	# Mark destination portals inside so player doesn't instantly retrigger
	for p in _dynamic_portals:
		var dx: float = (target_coords.x - p.position.x)
		var dy: float = (target_coords.y - p.position.y) * 2.0
		if sqrt(dx * dx + dy * dy) <= p.trigger_radius + 20.0:
			p.mark_player_inside()
	
	var dest_name := "Map %d" % target_map_id
	var target_bgm := ""
	var db = _get_autoload_node("/root/GameDatabase")
	if db and db.scenes:
		var sc = db.scenes.get_scene(target_map_id)
		if sc and not sc.name.is_empty():
			dest_name = sc.name
		if sc and not sc.bgm_name.is_empty():
			target_bgm = sc.bgm_name
	match target_map_id:
		10001, 10011:
			dest_name = "Ship Deck"
			if target_bgm.is_empty(): target_bgm = "BGM0007"
		10002:
			dest_name = "Cabin"
			if target_bgm.is_empty(): target_bgm = "BGM0011"
		10003:
			dest_name = "Newbie Island"
			if target_bgm.is_empty(): target_bgm = "BGM0024"
		12000:
			dest_name = "Kelan Village"
			if target_bgm.is_empty(): target_bgm = "BGM0009"
	
	if not target_bgm.is_empty():
		_play_map_bgm(target_bgm)
	
	_on_map_loaded(target_map_id)
	
	if hud and hud.has_method("update_map_name"):
		hud.update_map_name(dest_name)
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", "Warping to %s..." % dest_name, "System")

func _update_cursor_hover_target() -> void:
	if not is_inside_tree():
		return
	var c_mgr = _get_autoload_node("/root/CursorManager")
	if not c_mgr:
		return
	
	if hud and hud.has_method("is_mouse_over_ui") and hud.is_mouse_over_ui():
		c_mgr.set_cursor_state(CursorManager.CursorType.NORMAL)
		return
	
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	
	# 1. Check NPC hover (within 42px of NPC position or sprite body)
	if entities:
		for child in entities.get_children():
			if child != player and is_instance_valid(child) and ("visible" not in child or child.visible) and (child is NpcEntity or child.has_signal("npc_interacted")):
				var n_pos: Vector2 = child.global_position
				if mouse_world_pos.distance_to(n_pos) <= 42.0 or mouse_world_pos.distance_to(n_pos + Vector2(0, -32)) <= 36.0:
					c_mgr.set_cursor_state(_cursor_type_for_npc(child))
					return
	
	# 2. Check Portal hover (within 42px of portal position)
	for portal in _dynamic_portals:
		if is_instance_valid(portal) and portal.visible:
			if mouse_world_pos.distance_to(portal.global_position) <= 42.0:
				c_mgr.set_cursor_state(CursorManager.CursorType.PORTAL)
				return
	
	# 3. Check Ground Item hover (within 32px of item position)
	for g_item in _dynamic_ground_items:
		if is_instance_valid(g_item) and g_item.visible and not g_item.is_picked_up:
			if mouse_world_pos.distance_to(g_item.global_position) <= 32.0:
				c_mgr.set_cursor_state(CursorManager.CursorType.HARVEST)
				return
	for k_node in _kitchen_entities:
		if is_instance_valid(k_node) and k_node is GroundItem and k_node.visible and not k_node.is_picked_up:
			if mouse_world_pos.distance_to(k_node.global_position) <= 32.0:
				c_mgr.set_cursor_state(CursorManager.CursorType.HARVEST)
				return
	
	# 4. Default: open field movement
	c_mgr.set_cursor_state(CursorManager.CursorType.NORMAL)

## Merchants show the shop cursor, NPCs a quest is waiting on the quest cursor, everyone else talk.
func _cursor_type_for_npc(npc: Node2D) -> int:
	if is_merchant_npc(npc):
		return CursorManager.CursorType.SHOP
	if quest_component and quest_component.has_method("npc_has_pending_objective"):
		var n_id: int = int(npc.get("npc_id")) if npc.get("npc_id") != null else 0
		var n_name: String = str(npc.get("npc_name")) if npc.get("npc_name") != null else ""
		if quest_component.npc_has_pending_objective(n_id, n_name):
			return CursorManager.CursorType.QUEST
	return CursorManager.CursorType.TALK

func _update_cursor_animation(delta: float) -> void:
	if not is_inside_tree():
		return
	var c_mgr = _get_autoload_node("/root/CursorManager")
	if c_mgr and c_mgr.has_method("get_active_frames"):
		# CursorManager animates the cursor itself; a second animator here restarted the frames
		# and fought over the hotspot.
		return
	if c_mgr:
		var active = c_mgr.get_active_frames()
		if not active.is_empty() and active != _cursor_frames:
			_cursor_frames = active
			_cursor_frame_index = 0

	if _cursor_frames.size() <= 1:
		return
	_cursor_timer += delta
	if _cursor_timer >= CURSOR_FRAME_INTERVAL:
		while _cursor_timer >= CURSOR_FRAME_INTERVAL:
			_cursor_timer -= CURSOR_FRAME_INTERVAL
			_cursor_frame_index = (_cursor_frame_index + 1) % _cursor_frames.size()
		var hotspot: Vector2 = Vector2(4, 2) if (c_mgr and c_mgr.get_cursor_state() == CursorManager.CursorType.HARVEST) else Vector2(0, 0)
		Input.set_custom_mouse_cursor(_cursor_frames[_cursor_frame_index], Input.CURSOR_ARROW, hotspot)

func _update_camera_to_player() -> void:
	if player and camera:
		camera.position = player.position

func update_camera_limits() -> void:
	if not camera or not map_renderer:
		return
	var map_size: Vector2 = Vector2.ZERO
	if map_renderer.has_method("get_map_pixel_size"):
		map_size = map_renderer.get_map_pixel_size()
	if map_size.x <= 0 or map_size.y <= 0:
		return
		
	var vp_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	if vp_size.x <= 0 or vp_size.y <= 0:
		vp_size = Vector2(1280, 720)
		
	if map_size.x < vp_size.x:
		var extra_x: float = (vp_size.x - map_size.x) * 0.5
		camera.limit_left = int(-extra_x)
		camera.limit_right = int(map_size.x + extra_x)
	else:
		camera.limit_left = 0
		camera.limit_right = int(map_size.x)
		
	if map_size.y < vp_size.y:
		var extra_y: float = (vp_size.y - map_size.y) * 0.5
		camera.limit_top = int(-extra_y)
		camera.limit_bottom = int(map_size.y + extra_y)
	else:
		camera.limit_top = 0
		camera.limit_bottom = int(map_size.y)

const ClickRippleScene = preload("res://scenes/fx/click_ripple.tscn")
var _last_ripple_time: float = 0.0
var _last_ripple_pos: Vector2 = Vector2(-9999, -9999)

func _spawn_click_ripple(world_coord: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_ripple_time < 0.2 and world_coord.distance_to(_last_ripple_pos) < 30.0:
		return
	_last_ripple_time = now
	_last_ripple_pos = world_coord
	if ClickRippleScene:
		var ripple = ClickRippleScene.instantiate()
		ripple.position = world_coord
		add_child(ripple)

## Searches for an active visible NPC near a world coordinate (checking origin, sprite center, head, and click area)
func find_npc_near_world_pos(world_coord: Vector2, max_radius: float = 52.0) -> Node2D:
	if not entities:
		return null
	var candidate: Node2D = null
	var min_dist: float = INF
	
	for child in entities.get_children():
		if child == player or child == _companion_follower or not is_instance_valid(child) or not child.visible:
			continue
		if not (child is NpcEntity or child.has_signal("npc_interacted")):
			continue
		
		var npc_pos: Vector2 = child.world_position if ("world_position" in child) else child.position
		var d_root: float = world_coord.distance_to(npc_pos)
		var d_body: float = world_coord.distance_to(npc_pos + Vector2(0, -35.0))
		var d_head: float = world_coord.distance_to(npc_pos + Vector2(0, -60.0))
		
		var inside_shape: bool = false
		var click_area = child.get_node_or_null("ClickArea")
		if click_area and click_area is Area2D:
			for shape_owner in click_area.get_shape_owners():
				for shape_idx in range(click_area.shape_owner_get_shape_count(shape_owner)):
					var shape = click_area.shape_owner_get_shape(shape_owner, shape_idx)
					var shape_xform: Transform2D = click_area.global_transform * click_area.shape_owner_get_transform(shape_owner)
					if shape is RectangleShape2D:
						var local_p: Vector2 = shape_xform.affine_inverse() * world_coord
						var half_ext: Vector2 = shape.size * 0.5
						if absf(local_p.x) <= half_ext.x + 10.0 and absf(local_p.y) <= half_ext.y + 10.0:
							inside_shape = true
							break
				if inside_shape:
					break
		
		var effective_dist: float = minf(d_root, minf(d_body, d_head))
		if inside_shape or effective_dist <= max_radius:
			if effective_dist < min_dist:
				min_dist = effective_dist
				candidate = child
	
	return candidate

## Handles approaching an NPC and opening dialogue once within interaction range
func interact_with_npc(npc: Node2D) -> void:
	if not is_instance_valid(npc):
		return
	
	if hud and hud.has_method("is_dialogue_active") and hud.is_dialogue_active():
		return
	
	var p_pos: Vector2 = player.world_position if (player and "world_position" in player) else (player.position if player else Vector2.ZERO)
	var n_pos: Vector2 = npc.world_position if ("world_position" in npc) else npc.position
	var dist: float = p_pos.distance_to(n_pos)
	
	const INTERACTION_DISTANCE: float = 120.0
	if dist <= INTERACTION_DISTANCE or not player:
		# Player is already within interaction range: stop and interact immediately
		if player:
			if "is_moving" in player:
				player.is_moving = false
			if "_current_waypoints" in player:
				player._current_waypoints.clear()
			if "current_heading" in player:
				player.current_heading = IsometricMath.get_heading(p_pos, n_pos)
				if player.has_signal("heading_changed"):
					player.heading_changed.emit(player.current_heading)
		
		_active_dialogue_npc = npc
		if "original_heading" in npc:
			if npc.original_heading < 0 and "heading" in npc:
				npc.original_heading = npc.heading
		
		if "heading" in npc:
			npc.heading = IsometricMath.get_heading(n_pos, p_pos)
			if "facing_direction" in npc:
				npc.facing_direction = npc.heading
		
		_pending_npc_interaction = null
		if npc.has_method("show_emotion"):
			npc.show_emotion("dots", 1.2)
		_on_npc_interacted(npc)
	else:
		# Beyond interaction range: walk toward NPC and trigger dialogue upon arrival
		_pending_npc_interaction = npc
		_active_dialogue_npc = npc
		if "original_heading" in npc:
			if npc.original_heading < 0 and "heading" in npc:
				npc.original_heading = npc.heading
		if npc.has_method("show_emotion"):
			npc.show_emotion("dots", 1.2)
		var approach_pos: Vector2 = n_pos.move_toward(p_pos, 50.0)
		var walk_started: bool = false
		if player and player.has_method("set_target_world_position"):
			walk_started = player.set_target_world_position(approach_pos)
			if not walk_started:
				walk_started = player.set_target_world_position(n_pos)
		
		if not walk_started:
			# If path cannot be navigated, trigger dialogue directly so player is never blocked
			_pending_npc_interaction = null
			_active_dialogue_npc = npc
			if "original_heading" in npc:
				if npc.original_heading < 0 and "heading" in npc:
					npc.original_heading = npc.heading
			if "heading" in npc:
				npc.heading = IsometricMath.get_heading(n_pos, p_pos)
				if "facing_direction" in npc:
					npc.facing_direction = npc.heading
			_on_npc_interacted(npc)

func _on_tile_clicked(world_coord: Vector2) -> void:
	# Ignore ground movement clicks if player is locked, waking up, or performing action animations
	if player:
		if "is_movement_locked" in player and player.is_movement_locked:
			return
		if "_is_animating_wakeup" in player and player._is_animating_wakeup:
			return
		if "is_prone" in player and player.is_prone:
			return
		if "motion_state" in player and player.motion_state in [PlayerEntity.MotionState.PRONE, PlayerEntity.MotionState.ATTACK, PlayerEntity.MotionState.DEFEND, PlayerEntity.MotionState.VICTORY]:
			return
	if sinking_cutscene and is_instance_valid(sinking_cutscene) and sinking_cutscene.is_cutscene_active:
		return
	if hud and "dialogue_dock" in hud and hud.dialogue_dock and hud.dialogue_dock.visible:
		return
	if hud and "branching_dock" in hud and hud.branching_dock and hud.branching_dock.visible:
		return

	_spawn_click_ripple(world_coord)
	
	# Check if an active NPC was clicked
	var clicked_npc: Node2D = find_npc_near_world_pos(world_coord, 52.0)
	if clicked_npc:
		interact_with_npc(clicked_npc)
		return
	
	# Normal ground movement click: cancel pending NPC interaction
	_pending_npc_interaction = null
	if player and player.has_method("set_target_world_position"):
		player.set_target_world_position(world_coord)

func _on_minimap_clicked(norm_pos: Vector2) -> void:
	if not player or not map_renderer:
		return
	var map_size: Vector2 = map_renderer.get_map_pixel_size()
	if map_size.x > 0 and map_size.y > 0:
		var target_world: Vector2 = Vector2(norm_pos.x * map_size.x, norm_pos.y * map_size.y)
		_on_tile_clicked(target_world)

func _on_player_position_updated(world_pos: Vector2) -> void:
	if hud and hud.has_method("update_coordinates"):
		hud.update_coordinates(world_pos)
	_update_encounters(world_pos)

# ==================== RANDOM ENCOUNTERS & BATTLE ====================

var encounter_system: Node = null
var _battle_layer: CanvasLayer = null
var _battle_view: Control = null
var _battle_outcome: String = ""
var _battle_enemy_templates: Array = []

func ensure_encounter_system() -> Node:
	if encounter_system == null:
		encounter_system = EncounterSystemScript.new()
		encounter_system.name = "EncounterSystem"
		add_child(encounter_system)
		encounter_system.encounter_triggered.connect(start_battle)
	return encounter_system

func is_battle_active() -> bool:
	return _battle_view != null and is_instance_valid(_battle_view)

func _update_encounters(world_pos: Vector2) -> void:
	var system := ensure_encounter_system()
	var current_map: int = map_renderer.current_map_id if (map_renderer and "current_map_id" in map_renderer) else 0
	if system.map_id != current_map:
		system.set_map(current_map)
	var blocked: bool = is_battle_active()
	if player and is_instance_valid(player) and "is_movement_locked" in player and player.is_movement_locked:
		blocked = true
	if sinking_cutscene and is_instance_valid(sinking_cutscene) and sinking_cutscene.is_cutscene_active:
		blocked = true
	if hud and "dialogue_dock" in hud and hud.dialogue_dock and hud.dialogue_dock.visible:
		blocked = true
	system.update_player_position(world_pos, blocked)

## Opens the battle over the world. `enemies` are BattleManager actor dictionaries.
var _battle_starting: bool = false

## Takes the battle backdrop: the terrain around the player WITHOUT the HUD, NPCs, companions or the player (the real
## battle field shows no village life), then restores everything. Headless runs (no renderer) skip the hiding.
func _capture_clean_backdrop() -> Image:
	if DisplayServer.get_name() == "headless":
		return get_viewport().get_texture().get_image()
	var hidden: Array[CanvasItem] = []
	var candidates: Array = [hud, player]
	for child in get_children():
		if child != player and child is CanvasItem and child.has_signal("npc_interacted"):
			candidates.append(child)
	for node in candidates:
		if node is CanvasItem and is_instance_valid(node) and node.visible:
			hidden.append(node)
			node.visible = false
	await RenderingServer.frame_post_draw
	var clean := get_viewport().get_texture().get_image()
	for node in hidden:
		if is_instance_valid(node):
			node.visible = true
	return clean


func start_battle(enemies: Array) -> void:
	if is_battle_active() or enemies.is_empty() or _battle_starting:
		return
	_battle_starting = true
	_battle_starting = false
	if is_battle_active():
		return

	# Hide world entities and map renderer so no village life or terrain bleeds into combat
	if entities and is_instance_valid(entities):
		entities.visible = false
	if map_renderer and is_instance_valid(map_renderer):
		map_renderer.visible = false

	# Set World HUD to layer 20 and Battle to layer 10 so World HUD remains visible
	var hud_layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
	if hud_layer:
		hud_layer.layer = 20

	_battle_layer = CanvasLayer.new()
	_battle_layer.name = "BattleLayer"
	_battle_layer.layer = 10
	add_child(_battle_layer)
	_battle_view = BattleViewScene.instantiate()
	_battle_layer.add_child(_battle_view)

	# Dynamic environment & battle backdrop resolution
	var cur_map_id: int = map_renderer.current_map_id if (map_renderer and "current_map_id" in map_renderer) else 10001
	var gdb = Engine.get_singleton("GameDatabase") if Engine.has_singleton("GameDatabase") else null
	if not gdb:
		gdb = get_node_or_null("/root/GameDatabase")
	var scene_rec = gdb.scenes.get_scene(cur_map_id) if gdb and "scenes" in gdb and gdb.scenes else null
	var s_name: String = scene_rec.name if scene_rec else ""
	var env_type: String = BattleView.resolve_environment_for_map(cur_map_id, s_name)
	_battle_view.set_environment(env_type)

	# Hide radar minimap during battle per authentic client behavior
	if hud:
		var minimap_node = hud.get_node_or_null("RadarMinimapDock")
		if minimap_node:
			minimap_node.visible = false

	_battle_outcome = ""
	_battle_enemy_templates = []
	for enemy in enemies:
		_battle_enemy_templates.append({"id": int(enemy.get("template_id", 0)), "name": str(enemy.get("name", ""))})
	_battle_view.victory_confirmed.connect(func() -> void: _battle_outcome = "victory")
	_battle_view.defeat_confirmed.connect(func() -> void: _battle_outcome = "defeat")
	_battle_view.escape_confirmed.connect(func() -> void: _battle_outcome = "escape")
	_battle_view.view_closed.connect(_on_battle_view_closed, CONNECT_ONE_SHOT)

	var manager = _battle_view.battle_manager
	var party: Array[Dictionary] = [_build_player_battle_actor()]
	if not _active_companion_data.is_empty():
		party.append(_build_companion_battle_actor(_active_companion_data))
	var foes: Array[Dictionary] = []
	for enemy in enemies:
		foes.append(enemy)
	manager.initialize_battle(party, foes)
	manager.start_battle()
	_battle_view.refresh_actor_widgets()
	if player and is_instance_valid(player) and "is_movement_locked" in player:
		player.is_movement_locked = true
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", "Monsters appeared!", "System")

func _build_companion_battle_actor(cdata: Dictionary) -> Dictionary:
	var cid: int = int(cdata.get("npc_id", cdata.get("id", 8090)))
	var cname: String = str(cdata.get("name", "Companion"))
	var clevel: int = int(cdata.get("level", 10))
	var chp: int = int(cdata.get("hp", 200))
	var cmax_hp: int = int(cdata.get("max_hp", 200))
	var csp: int = int(cdata.get("sp", 100))
	var cmax_sp: int = int(cdata.get("max_sp", 100))
	var celem: int = int(cdata.get("element", 3))
	return {
		"id": cid,
		"role_id": cid,
		"name": cname,
		"level": clevel,
		"hp": chp,
		"max_hp": cmax_hp,
		"sp": csp,
		"max_sp": cmax_sp,
		"atk": 12 + clevel * 2,
		"matk": 10 + clevel * 2,
		"def": 8 + clevel * 2,
		"mdef": 8 + clevel * 2,
		"spd": 10 + clevel,
		"element": celem,
		"is_pet": true
	}

func _build_player_battle_actor() -> Dictionary:
	var status = hud.character_status_ctrl if (hud and "character_status_ctrl" in hud) else null
	var element_ids := {"earth": 1, "water": 2, "fire": 3, "wind": 4}
	var actor := {"id": 1, "name": "Daniel", "level": 1, "hp": 150, "max_hp": 150, "sp": 100, "max_sp": 100, "element": 3, "role_id": 6}
	if status:
		var combat: Dictionary = status.get_combat_stats(status.get_equipment_bonus())
		actor = {
			"id": int(status.current_role_id), "role_id": int(status.current_role_id),
			"name": str(status.current_name), "level": int(status.current_level),
			"hp": int(status.current_hp), "max_hp": int(status.current_max_hp),
			"sp": int(status.current_sp), "max_sp": int(status.current_max_sp),
			"atk": combat["atk"], "matk": combat["matk"], "def": combat["def"], "mdef": combat["mdef"], "spd": combat["spd"],
			"element": int(element_ids.get(str(status.current_element).to_lower(), 0)),
			"equip_layers": status.current_equip_layers,
		}
	return actor

func _on_battle_view_closed() -> void:
	var outcome := _battle_outcome
	var manager = _battle_view.battle_manager if is_battle_active() else null
	if manager:
		var survivor: Dictionary = manager.get_participant(false, 0)
		if outcome == "victory":
			_apply_battle_rewards(manager.rewards)
		_sync_player_after_battle(survivor, outcome)
		if not _active_companion_data.is_empty():
			var pet_survivor: Dictionary = manager.get_participant(false, 1)
			if not pet_survivor.is_empty():
				_active_companion_data["hp"] = pet_survivor.get("hp", _active_companion_data.get("hp", 200))
				_active_companion_data["sp"] = pet_survivor.get("sp", _active_companion_data.get("sp", 100))
	if _battle_layer and is_instance_valid(_battle_layer):
		_battle_layer.queue_free()
	_battle_layer = null
	_battle_view = null
	if entities and is_instance_valid(entities):
		entities.visible = true
	if map_renderer and is_instance_valid(map_renderer):
		map_renderer.visible = true
	if player and is_instance_valid(player) and "is_movement_locked" in player:
		player.is_movement_locked = false
	if hud:
		var minimap_node = hud.get_node_or_null("RadarMinimapDock")
		if minimap_node:
			minimap_node.visible = true
	ensure_encounter_system().start_cooldown()

func _apply_battle_rewards(rewards: Dictionary) -> void:
	if hud == null:
		return
	var gold: int = int(rewards.get("gold", 0))
	var exp_gain: int = int(rewards.get("exp", 0))
	if gold > 0 and hud.has_method("add_gold"):
		hud.add_gold(gold)
	for item in rewards.get("items", []):
		if item is Dictionary and hud.has_method("add_inventory_item"):
			hud.add_inventory_item(int(item.get("item_id", 0)), int(item.get("quantity", 1)), str(item.get("item_name", "")))
	var status = hud.character_status_ctrl if "character_status_ctrl" in hud else null
	if status and exp_gain > 0:
		var old_level: int = int(status.current_level)
		status.add_experience(exp_gain)
		if int(status.current_level) > old_level and hud.has_method("add_chat_message"):
			hud.add_chat_message("System", "Level up! You are now level %d." % status.current_level, "System")
	for tid in _battle_enemy_templates:
		if hud.has_method("register_monster_seen"):
			hud.register_monster_seen(int(tid["id"]), str(tid["name"]))
	if hud.has_method("add_chat_message"):
		hud.add_chat_message("System", "Victory! +%d EXP, +%d Gold." % [exp_gain, gold], "System")

func _sync_player_after_battle(survivor: Dictionary, outcome: String) -> void:
	var status = hud.character_status_ctrl if (hud and "character_status_ctrl" in hud) else null
	if status == null:
		return
	if outcome == "defeat":
		status.current_hp = maxi(1, int(status.current_max_hp / 2))
	elif not survivor.is_empty():
		status.current_hp = clampi(int(survivor.get("hp", status.current_hp)), 1, int(status.current_max_hp))
		status.current_sp = clampi(int(survivor.get("sp", status.current_sp)), 0, int(status.current_max_sp))
	if hud.has_method("update_character_stats"):
		hud.update_character_stats(status.current_name, status.current_level, status.current_element, status.current_hp, status.current_max_hp, status.current_sp, status.current_max_sp, status.current_exp, status.current_max_exp, status.current_str, status.current_con, status.current_int, status.current_wis, status.current_agi, status.current_free)

func _on_player_stats_changed(stat_dict: Dictionary) -> void:
	if not hud:
		return
	if hud.has_method("set_player_stats"):
		hud.set_player_stats(
			stat_dict.get("name", player.character_name if player else "Daniel"),
			int(stat_dict.get("level", player.level if player else 10)),
			int(stat_dict.get("hp", player.hp if player else 245)),
			int(stat_dict.get("max_hp", player.max_hp if player else 245)),
			int(stat_dict.get("sp", player.sp if player else 180)),
			int(stat_dict.get("max_sp", player.max_sp if player else 180)),
			stat_dict.get("exp_percent", player.exp_percent if player else 45.0)
		)
	if stat_dict.has("role_id") and hud.has_method("set_player_role"):
		hud.set_player_role(int(stat_dict.role_id))

func _on_map_loaded(map_id: int) -> void:
	if map_renderer and player and "map_data" in player and "_map_data" in map_renderer:
		player.map_data = map_renderer._map_data
	
	var map_name := "Ship Deck"
	var target_bgm := ""
	var game_db = _get_autoload_node("/root/GameDatabase")
	if game_db and game_db.scenes:
		var sc = game_db.scenes.get_scene(map_id)
		if sc and not sc.name.is_empty():
			map_name = sc.name
		if sc and not sc.bgm_name.is_empty():
			target_bgm = sc.bgm_name
	match map_id:
		10001, 10011:
			map_name = "Ship Deck"
			if target_bgm.is_empty(): target_bgm = "BGM0007"
		10002:
			map_name = "Cabin"
			if target_bgm.is_empty(): target_bgm = "BGM0011"
		10003:
			map_name = "Newbie Island"
			if target_bgm.is_empty(): target_bgm = "BGM0024"
		12000:
			map_name = "Kelan Village"
			if target_bgm.is_empty(): target_bgm = "BGM0009"
		_:
			if map_name == "Ship Deck" and map_id != 10001:
				map_name = "Map %d" % map_id
	if not target_bgm.is_empty():
		_play_map_bgm(target_bgm)

	var map_size: Vector2 = Vector2.ZERO
	if map_renderer and map_renderer.has_method("get_map_pixel_size"):
		map_size = map_renderer.get_map_pixel_size()
	
	update_camera_limits()
	
	var loader := _get_autoload_node("/root/ArchiveLoader")
	var mm_tex: Texture2D = null
	if loader and loader.has_method("get_minimap_texture"):
		mm_tex = loader.get_minimap_texture(map_id)
	
	var p_norm := Vector2(0.5, 0.5)
	if player and map_size.x > 0 and map_size.y > 0:
		var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
		p_norm = Vector2(clampf(p_pos.x / map_size.x, 0.0, 1.0), clampf(p_pos.y / map_size.y, 0.0, 1.0))
	
	if hud:
		if hud.has_method("set_map_context"):
			hud.set_map_context(map_id, map_name, map_size, mm_tex)
		elif hud.has_method("update_map_name"):
			hud.update_map_name(map_name)
		if hud.has_method("update_minimap") and mm_tex:
			hud.update_minimap(mm_tex, p_norm)
	map_changed.emit(map_id, map_name)

func _on_player_movement_blocked(reason: String, _target_pos: Vector2) -> void:
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", reason, "System")

## Plays the BGM track for the current map. Stops previous track if different.
## bgm_name is in the form "BGM0007", "BGM0009", etc. from all_maps.json.
var _current_bgm_name: String = ""
func _play_map_bgm(bgm_name: String) -> void:
	if bgm_name.is_empty():
		return
	# Normalize: ensure uppercase prefix
	var normalized: String = bgm_name.to_upper()
	if normalized == _current_bgm_name and bgm_player and bgm_player.playing:
		return  # Same track already playing
	_current_bgm_name = normalized
	# Build candidate paths (wav has priority, ogg fallback)
	var candidates: Array[String] = [
		"res://assets/sound/%s.wav" % normalized,
		"res://assets/sound/%s.WAV" % normalized,
		"res://assets/sound/%s.ogg" % normalized,
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream:
				if bgm_player.playing:
					bgm_player.stop()
				bgm_player.stream = stream
				bgm_player.volume_db = 0.0
				bgm_player.bus = &"BGM" if AudioServer.get_bus_index("BGM") != -1 else &"Master"
				if bgm_player.is_inside_tree():
					bgm_player.play()
				return
func _resolve_npc_portrait(npc: Node2D) -> Texture2D:
	var n_id: int = npc.npc_id if "npc_id" in npc else 0
	var n_name: String = npc.npc_name.to_lower() if "npc_name" in npc else ""
	var path := "res://assets/hud/portraits/default_portrait.png"
	if n_id in [14003, 12032] or "captain" in n_name or "robinson" in n_name:
		path = "res://assets/hud/portraits/captain_portrait.png"
	elif n_id in [14062, 12001] or "kelang" in n_name:
		path = "res://assets/hud/portraits/elder_portrait.png"
	elif n_id in [14001, 14002] or "crew" in n_name or "sailor" in n_name:
		path = "res://assets/hud/portraits/crew_portrait.png"
	elif "elder" in n_name or n_id == 14042:
		path = "res://assets/hud/portraits/elder_portrait.png"
	elif "daniel" in n_name:
		path = "res://assets/hud/portraits/daniel_portrait.png"
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _resolve_npc_portrait_frames(npc: Node2D) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var n_id: int = npc.npc_id if "npc_id" in npc else 0
	
	var game_db = _get_autoload_node("/root/GameDatabase")
	var loader = _get_autoload_node("/root/ArchiveLoader")
	
	if game_db and "npcs" in game_db and game_db.npcs and loader:
		var n_rec = game_db.npcs.get_npc(n_id)
		if n_rec and n_rec.talk_image > 0:
			var jmp_name := "%d.jmp" % n_rec.talk_image
			var anim = loader.get_jma_animation("008.jma", jmp_name)
			if anim and anim.frames.size() > 0:
				for i in range(anim.frames.size()):
					var tex = anim.decode_frame(i)
					if tex:
						frames.append(tex)
	
	if frames.is_empty():
		var fb_tex := _resolve_npc_portrait(npc)
		if fb_tex:
			frames.append(fb_tex)
	
	return frames

## Determines if an NPC is a merchant shopkeeper (Props, Weapons, Pharmacy, General Store, Grandma)
func is_merchant_npc(npc: Node2D) -> bool:
	if not is_instance_valid(npc):
		return false
	var n_id: int = 0
	if "npc_id" in npc:
		n_id = int(npc.npc_id)
	elif npc.has_meta("npc_id"):
		n_id = int(npc.get_meta("npc_id"))
	elif npc.get("npc_id") != null:
		n_id = int(npc.get("npc_id"))

	var n_name: String = ""
	if "npc_name" in npc:
		n_name = str(npc.npc_name).to_lower()
	elif npc.has_meta("npc_name"):
		n_name = str(npc.get_meta("npc_name")).to_lower()
	elif npc.get("npc_name") != null:
		n_name = str(npc.get("npc_name")).to_lower()

	if n_id in [13000, 13001, 13007, 13009, 13011, 13016, 14129, 14177, 14508, 14592, 14710, 15107, 15215, 15622, 15623, 15887, 19129, 19177, 35216, 35804, 35805]:
		return true
	for kw in ["shop", "store", "merchant", "smith", "grocery", "pharmacy", "grandma"]:
		if kw in n_name:
			return true
	return false

## Opens the merchant shop window via HUD
func open_merchant_shop(merchant_id: int = 0, merchant_name: String = "", catalog: Array = []) -> void:
	if hud and hud.has_method("open_shop"):
		hud.open_shop(merchant_id, merchant_name, catalog)

## Determines if an NPC is an interactive container (treasure chest, cask, barrel, urn, crate)
func is_container_npc(npc: Node2D) -> bool:
	if not is_instance_valid(npc):
		return false
	var n_id: int = npc.npc_id if "npc_id" in npc else 0
	var t_id: int = npc.template_id if "template_id" in npc else 0
	var n_name: String = str(npc.npc_name if "npc_name" in npc else "").to_lower()
	if n_id in [19034, 19035, 19036, 19037, 19038]:
		return true
	if (n_id >= 16000 and n_id <= 16015) or (t_id >= 16000 and t_id <= 16015):
		return true
	if n_name.contains("chest") or n_name.contains("sandik") or n_name.contains("cask") or n_name.contains("barrel") or n_name.contains("box") or n_name.contains("treas") or n_name.contains("crate"):
		return true
	if "is_broken" in npc and "_anim_data" in npc and npc._anim_data and npc._anim_data.frames.size() == 2:
		return true
	return false

## Handles opening a treasure chest/cask: awards items & gold directly to inventory, shows notification, bypasses dialogue
func _handle_container_npc_interaction(npc: Node2D) -> void:
	var n_id: int = npc.npc_id if "npc_id" in npc else 0
	var n_name: String = npc.npc_name if "npc_name" in npc else "Chest"
	# Authentic loot and quest flags come from the chest Eve event; the table below is only a fallback.
	if npc.has_meta("eve_events") and not (npc.get_meta("eve_events") as Array).is_empty() and _try_eve_conversation(npc, n_name):
		return
	var cur_map: int = map_renderer.current_map_id if (map_renderer and "current_map_id" in map_renderer) else 10001
	var container_key: int = cur_map * 100000 + (n_id if n_id > 0 else int(npc.get_instance_id()))
	
	var is_open: bool = (npc.is_broken if "is_broken" in npc else false) or _opened_containers.get(container_key, false)
	
	if is_open:
		var empty_msg := "The %s is empty." % n_name
		if npc.has_method("show_speech_bubble"):
			npc.show_speech_bubble(empty_msg, 2.0)
		if hud and hud.has_method("add_chat_message"):
			hud.add_chat_message("System", empty_msg, "System")
		if hud and hud.has_method("play_sfx"):
			hud.play_sfx("wav0151")
		return
	
	# Mark container as opened / broken
	_opened_containers[container_key] = true
	if "is_broken" in npc:
		npc.is_broken = true
	if npc.has_method("_update_frame"):
		npc._update_frame()
	
	# Resolve authentic loot
	var loot_item_id: int = 34026 # Protective EXP Pill
	var loot_item_name: String = "Protective EXP Pill"
	var loot_count: int = 1
	var loot_icon: int = 1768
	var loot_gold: int = 150
	var loot_exp: float = 10.0
	
	match n_id:
		19034, 19035: # Beach Treasure Chests
			loot_item_id = 34014
			loot_item_name = "Tao Rice Ball"
			loot_count = 5
			loot_icon = 1859
			loot_gold = 100
			loot_exp = 8.0
		19036, 19037: # Beach Casks / Barrels
			loot_item_id = 32015
			loot_item_name = "Danish Bread"
			loot_count = 5
			loot_icon = 1015
			loot_gold = 150
			loot_exp = 10.0
		19038: # Beach Supplies Chest
			loot_item_id = 34026
			loot_item_name = "Protective EXP Pill"
			loot_count = 2
			loot_icon = 1768
			loot_gold = 200
			loot_exp = 15.0
		19039: # Beach Fallen Coconut
			loot_item_id = 41066
			loot_item_name = "Coconut"
			loot_count = 3
			loot_icon = 1379
			loot_gold = 50
			loot_exp = 5.0
		16000, 16001: # Wooden Treasure Box & Storage Cask
			loot_item_id = 32001 # White Rice
			loot_item_name = "White Rice"
			loot_count = 5
			loot_icon = 1290
			loot_gold = 250
			loot_exp = 12.0
		16002: # Chest (Footwear)
			loot_item_id = 24002 # Moppet's Shoes
			loot_item_name = "Moppet's Shoes"
			loot_count = 1
			loot_icon = 1092
			loot_gold = 200
			loot_exp = 12.0
		16003: # Iron / Bronze Chest
			loot_item_id = 34146 # 2 Holy EXP Potion
			loot_item_name = "2 Holy EXP Potion"
			loot_count = 2
			loot_icon = 1995
			loot_gold = 350
			loot_exp = 20.0
		16004: # Darkness Box
			loot_item_id = 34143 # 4 Holy EXP Potion
			loot_item_name = "4 Holy EXP Potion"
			loot_count = 1
			loot_icon = 1999
			loot_gold = 500
			loot_exp = 25.0
		16005: # Bottle
			loot_item_id = 30253 # Magic Potion
			loot_item_name = "Magic Potion"
			loot_count = 3
			loot_icon = 3199
			loot_gold = 100
			loot_exp = 8.0
		16006, 16007, 16008: # Gallipot / Ceramic Urn
			loot_item_id = 33023 # Cure Potion
			loot_item_name = "Cure Potion"
			loot_count = 5
			loot_icon = 1077
			loot_gold = 150
			loot_exp = 10.0
		_:
			if "cask" in n_name.to_lower() or "barrel" in n_name.to_lower():
				loot_item_id = 32015
				loot_item_name = "Danish Bread"
				loot_count = 5
				loot_icon = 1015
				loot_gold = 150
				loot_exp = 10.0
			else:
				loot_item_id = 34026
				loot_item_name = "Protective EXP Pill"
				loot_count = 2
				loot_icon = 1768
				loot_gold = 200
				loot_exp = 15.0
	
	# Synchronize exact name and icon from GameDatabase if available
	var gdb_loot = _get_autoload_node("/root/GameDatabase")
	if gdb_loot and gdb_loot.items:
		var rec = gdb_loot.items.get_item(loot_item_id)
		if rec:
			if not rec.name.is_empty():
				loot_item_name = rec.name
			if rec.icon_id > 0:
				loot_icon = rec.icon_id
	
	# Grant item to inventory
	if hud and hud.has_method("add_inventory_item"):
		hud.add_inventory_item(loot_item_id, loot_count, loot_item_name, loot_icon)
	
	# Award gold
	if loot_gold > 0:
		if hud and hud.has_method("add_gold"):
			hud.add_gold(loot_gold)
		if player and "gold" in player:
			player.gold += loot_gold
	
	# Award exp
	if loot_exp > 0.0 and player and "exp_percent" in player:
		player.exp_percent = minf(100.0, player.exp_percent + loot_exp)
	
	# Format notification banner & chat
	var notif_str := "%s x%d obtained!" % [loot_item_name, loot_count]
	if loot_gold > 0:
		notif_str += " +%d Gold" % loot_gold
	
	if hud and hud.has_method("show_center_notification"):
		hud.show_center_notification(notif_str, loot_icon)
	elif hud and hud.has_method("show_banner"):
		hud.show_banner(notif_str)
	
	if npc.has_method("show_speech_bubble"):
		npc.show_speech_bubble(notif_str, 2.5)
	
	if hud and hud.has_method("add_chat_message"):
		hud.add_chat_message("System", notif_str, "System")
	
	if hud and hud.has_method("play_sfx"):
		hud.play_sfx("wav9911")

	# Advance Quest 1002 Step 0: Search washed up beach chests/containers
	if quest_component:
		quest_component.advance_objective_by_type("SearchContainer")

## Directly interacts with quest component for an NPC
func interact_with_npc_quest(npc_id: int, npc_name: String = "", talk_id: int = 0) -> bool:
	ensure_quest_component()
	if quest_component:
		return quest_component.interact_with_npc(npc_id, npc_name, talk_id)
	return false

func _on_npc_interacted(npc: Node2D) -> void:
	if is_container_npc(npc):
		_handle_container_npc_interaction(npc)
		return

	var n_id: int = 0
	if "npc_id" in npc:
		n_id = int(npc.npc_id)
	elif npc.has_meta("npc_id"):
		n_id = int(npc.get_meta("npc_id"))
	elif npc.get("npc_id") != null:
		n_id = int(npc.get("npc_id"))

	var n_name: String = "NPC"
	if "npc_name" in npc and not str(npc.npc_name).is_empty():
		n_name = str(npc.npc_name)
	elif npc.has_meta("npc_name"):
		n_name = str(npc.get_meta("npc_name"))
	elif npc.get("npc_name") != null:
		n_name = str(npc.get("npc_name"))

	var n_text: String = ""
	if "dialogue_text" in npc:
		n_text = str(npc.dialogue_text)
	elif npc.has_meta("dialogue_text"):
		n_text = str(npc.get_meta("dialogue_text"))
	elif npc.get("dialogue_text") != null:
		n_text = str(npc.get("dialogue_text"))

	var n_choices: Array = []
	if "dialogue_choices" in npc:
		n_choices = npc.dialogue_choices
	elif npc.has_meta("dialogue_choices"):
		n_choices = npc.get_meta("dialogue_choices")
	elif npc.get("dialogue_choices") != null:
		n_choices = npc.get("dialogue_choices")
	var talk_rec: Dictionary = {}
	
	_interacting_npc_id = n_id
	_active_dialogue_npc = npc
	if "original_heading" in npc:
		if npc.original_heading < 0 and "heading" in npc:
			npc.original_heading = npc.heading
	if player and is_instance_valid(player):
		if "is_movement_locked" in player:
			player.is_movement_locked = true
		if "is_moving" in player:
			player.is_moving = false
		if "_current_waypoints" in player:
			player._current_waypoints.clear()
		var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
		var n_pos: Vector2 = npc.world_position if ("world_position" in npc) else npc.position
		if "current_heading" in player:
			player.current_heading = IsometricMath.get_heading(p_pos, n_pos)
			if player.has_signal("heading_changed"):
				player.heading_changed.emit(player.current_heading)
		if "heading" in npc:
			npc.heading = IsometricMath.get_heading(n_pos, p_pos)
			if "facing_direction" in npc:
				npc.facing_direction = npc.heading

	var is_captain: bool = (n_id == 14003 or "captain" in n_name.to_lower())
	if is_captain:
		_is_captain_dialogue_active = true

	var tid: int = npc.talk_id if "talk_id" in npc and npc.talk_id > 0 else 0

	# 1. Connect quest dialogue component: check if quest component handles or advances active quest dialogue
	if quest_component:
		var handled: bool = quest_component.interact_with_npc(n_id, n_name, tid)
		if handled:
			if npc.has_method("show_speech_bubble"):
				var preview_txt := n_text
				var q_act := quest_component.get_active_quest(1001)
				if q_act.is_empty(): q_act = quest_component.get_active_quest(1002)
				if not q_act.is_empty():
					var objs: Array = q_act.get("objectives", [])
					var cur_s: int = int(q_act.get("current_step", 0))
					if cur_s < objs.size():
						preview_txt = str(objs[cur_s].get("dialogue_preview", preview_txt))
				if not preview_txt.is_empty():
					npc.show_speech_bubble(preview_txt, 3.2)
			return

	if is_captain:
		if _quest_states.get(1, {}).get("state", 0) < 2:
			set_quest_state(1, 2, 1)
			for q in _quest_entries:
				if int(q.get("id", 0)) == 1:
					q["status"] = "Completed"
				elif int(q.get("id", 0)) == 2 and q.get("status", "") == "Available":
					q["status"] = "In Progress"
			_sync_hud_quest_log()
			_refresh_all_npc_quest_markers()
	elif n_id in [12032, 14062]:
		if _quest_states.get(2, {}).get("state", 0) < 2:
			set_quest_state(2, 2, 1)
			for q in _quest_entries:
				if int(q.get("id", 0)) == 2:
					q["status"] = "Completed"
			if hud and hud.has_method("show_quest_reward"):
				hud.show_quest_reward("Island Survival Guide", 1, 0, 100)
			_sync_hud_quest_log()
			_refresh_all_npc_quest_markers()
	elif n_id in [10000, 14303]:
		if _quest_states.get(3, {}).get("state", 0) < 2:
			set_quest_state(3, 2, 1)
			for q in _quest_entries:
				if int(q.get("id", 0)) == 3:
					q["status"] = "Completed"
			if hud and hud.has_method("show_quest_reward"):
				hud.show_quest_reward("", 0, 50, 50)
			_sync_hud_quest_log()
			_refresh_all_npc_quest_markers()
	
	if player and is_instance_valid(player):
		var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
		var n_pos: Vector2 = npc.world_position if ("world_position" in npc) else npc.position
		if "current_heading" in player:
			player.current_heading = IsometricMath.get_heading(p_pos, n_pos)
			if player.has_signal("heading_changed"):
				player.heading_changed.emit(player.current_heading)
		if "heading" in npc:
			npc.heading = IsometricMath.get_heading(n_pos, p_pos)
			if "facing_direction" in npc:
				npc.facing_direction = npc.heading
	
	var game_db = _get_autoload_node("/root/GameDatabase")
	if game_db and "talks" in game_db and game_db.talks:
		var cur_map_id: int = map_renderer.current_map_id if map_renderer else 10001
		if "talk_id" in npc and npc.talk_id > 0:
			tid = npc.talk_id
		if tid > 0:
			talk_rec = game_db.talks.get_talk(tid)
		elif n_id > 0:
			talk_rec = game_db.talks.resolve_talk_for_npc(n_id, cur_map_id)
		
		if not talk_rec.is_empty():
			if talk_rec.get("text", "") != "":
				n_text = talk_rec["text"]
			var rec_speaker: String = talk_rec.get("speaker", "")
			if is_captain:
				n_name = "Captain Robinson"
			elif "kelang" in n_name.to_lower():
				n_name = "Kelang"
			elif not rec_speaker.is_empty():
				n_name = rec_speaker
			if not talk_rec.get("choices", []).is_empty():
				n_choices.clear()
				for c in talk_rec["choices"]:
					if c is Dictionary and c.has("text"):
						n_choices.append(c["text"])
					else:
						n_choices.append(str(c))
			
			var sfx: String = talk_rec.get("sound_effect", "")
			if not sfx.is_empty() and hud and hud.has_method("play_sfx"):
				hud.play_sfx(sfx)
	
	if not is_merchant_npc(npc) and _try_eve_conversation(npc, n_name):
		return

	if n_text.is_empty() and not is_merchant_npc(npc):
		# No Talk.dat line is bound to this NPC yet (the real binding lives in the server's event scripts): show only a
		# "..." bubble instead of inventing a greeting.
		if npc.has_method("show_speech_bubble"):
			npc.show_speech_bubble("...", 2.0)
		_active_dialogue_npc = null
		_interacting_npc_id = 0
		if player and is_instance_valid(player) and "is_movement_locked" in player:
			player.is_movement_locked = false
		return

	var portrait_frames: Array[Texture2D] = _resolve_npc_portrait_frames(npc)
	var portrait_tex: Texture2D = portrait_frames[0] if not portrait_frames.is_empty() else null
	if npc.has_method("show_speech_bubble") and not n_text.is_empty():
		npc.show_speech_bubble(n_text, 3.2)
	
	var is_merchant: bool = is_merchant_npc(npc)
	if is_merchant:
		var has_trade_choice := false
		for c in n_choices:
			var c_str := str(c).to_lower()
			if "buy" in c_str or "sell" in c_str or "trade" in c_str or "shop" in c_str:
				has_trade_choice = true
				break
		if not has_trade_choice:
			if n_choices.is_empty():
				n_choices = ["Buy / Sell", "Chat", "Leave"]
			else:
				n_choices.insert(0, "Buy / Sell")
		if n_text.is_empty():
			n_text = "Welcome to %s! Would you like to buy or sell anything today?" % n_name

	var choice_callback: Callable = func(choice_idx: int, _choice_text: String) -> void:
		var c_low := _choice_text.to_lower()
		if is_merchant and (choice_idx == 0 or "buy" in c_low or "sell" in c_low or "trade" in c_low or "shop" in c_low):
			open_merchant_shop(n_id, n_name)
			return

		var has_branch := false
		if game_db and "talks" in game_db and game_db.talks and not talk_rec.is_empty():
			var choices_list: Array = talk_rec.get("choices", [])
			if choice_idx >= 0 and choice_idx < choices_list.size():
				var sel_choice = choices_list[choice_idx]
				var branch_id: int = sel_choice.get("next_talk_id", 0) if sel_choice is Dictionary else 0
				if branch_id > 0:
					has_branch = true
					var branch_rec: Dictionary = game_db.talks.get_talk(branch_id)
					if not branch_rec.is_empty():
						var b_text: String = branch_rec.get("text", "")
						var b_speaker: String = branch_rec.get("speaker", n_name)
						if is_captain:
							b_speaker = "Captain Robinson"
						elif "kelang" in n_name.to_lower():
							b_speaker = "Kelang"
						var b_choices: Array = branch_rec.get("choices", [])
						var b_choice_strs: Array[String] = []
						for bc in b_choices:
							if bc is Dictionary and bc.has("text"):
								b_choice_strs.append(bc["text"])
							else:
								b_choice_strs.append(str(bc))
						if hud and hud.has_method("show_dialogue"):
							hud.show_dialogue(b_speaker, b_text, portrait_tex, b_choice_strs, portrait_frames, Callable(), 0)
		if not has_branch and is_captain:
			_is_captain_dialogue_active = false
			trigger_ship_sinking_cutscene()

	if not hud:
		if is_captain:
			_is_captain_dialogue_active = false
			trigger_ship_sinking_cutscene()
		return

	# If dialogue has choices that branch to other dialogues, present current node and let user branch
	var has_branching_choices := false
	if not talk_rec.is_empty():
		for c in talk_rec.get("choices", []):
			if c is Dictionary and c.get("next_talk_id", 0) > 0:
				has_branching_choices = true
				break

	if not is_merchant and game_db and "talks" in game_db and game_db.talks and not talk_rec.is_empty() and talk_rec.get("next_talk_id", 0) > 0 and not has_branching_choices:
		var chain: Array[Dictionary] = game_db.talks.get_dialogue_chain(talk_rec["id"])
		var pages: Array[String] = []
		for step in chain:
			pages.append(step.get("text", ""))
		var choices_str: Array[String] = []
		for c in n_choices:
			choices_str.append(str(c))
		if hud and hud.has_method("show_dialogue_sequence"):
			hud.show_dialogue_sequence(n_name, pages, 0, choices_str, choice_callback, portrait_frames)
			return
	
	if hud and hud.has_method("show_dialogue"):
		hud.show_dialogue(n_name, n_text, portrait_tex, n_choices, portrait_frames, choice_callback)

func _ensure_sinking_cutscene() -> SinkingCutsceneController:
	if not sinking_cutscene:
		if has_node("SinkingCutscene"):
			sinking_cutscene = get_node("SinkingCutscene") as SinkingCutsceneController
		elif has_node("SinkingCutsceneController"):
			sinking_cutscene = get_node("SinkingCutsceneController") as SinkingCutsceneController
		else:
			var sc_scene = load("res://scenes/events/sinking_cutscene.tscn")
			if sc_scene:
				sinking_cutscene = sc_scene.instantiate() as SinkingCutsceneController
			if not sinking_cutscene:
				sinking_cutscene = SinkingCutsceneController.new()
			sinking_cutscene.name = "SinkingCutscene"
			add_child(sinking_cutscene)

	if camera and sinking_cutscene:
		sinking_cutscene.camera = camera

	if sinking_cutscene:
		var on_cutscene_done: Callable = func(_arg = null) -> void:
			_on_sinking_cutscene_finished()
		if not sinking_cutscene.cutscene_finished.is_connected(on_cutscene_done):
			sinking_cutscene.cutscene_finished.connect(on_cutscene_done)
		if not sinking_cutscene.transition_to_beach.is_connected(on_cutscene_done):
			sinking_cutscene.transition_to_beach.connect(on_cutscene_done)

	return sinking_cutscene

func trigger_ship_sinking_cutscene() -> SinkingCutsceneController:
	if _sinking_triggered:
		return sinking_cutscene
	_sinking_triggered = true
	if player and is_instance_valid(player):
		if "is_movement_locked" in player:
			player.is_movement_locked = true
		if "is_moving" in player:
			player.is_moving = false
		if "_current_waypoints" in player:
			player._current_waypoints.clear()
	_ensure_sinking_cutscene()
	if sinking_cutscene:
		sinking_cutscene.trigger_after_captain_dialogue()
	return sinking_cutscene

## NPC conversations come from the original server's event scripts (Eve.emg), exactly as the C# server runs them:
## the NPC's linked events pick the first branch whose quest condition holds; its ops are NPC / player lines, quest flags,
## and a final Yes/No question. Quest progress is tracked in `_quest_steps` (quest id -> step).
var _quest_steps: Dictionary = {}

func _talk_text_lookup(talk_id: int) -> Dictionary:
	var game_db = _get_autoload_node("/root/GameDatabase")
	if game_db and "talks" in game_db and game_db.talks:
		return game_db.talks.get_talk(talk_id)
	return {}


func _apply_script_actions(actions: Array) -> void:
	for action in actions:
		if not (action is Dictionary):
			continue
		if action.has("quest_id"):
			NpcEventScript.apply_quest_actions([action], _quest_steps)
		elif action.has("gold") and hud and hud.has_method("add_gold"):
			hud.add_gold(int(action["gold"]))
		elif action.has("exp"):
			if hud and "character_status_ctrl" in hud and hud.character_status_ctrl:
				hud.character_status_ctrl.add_experience(int(action["exp"]))
		elif action.has("reward_item") and hud:
			var item_id: int = int(action["reward_item"])
			var count: int = int(action.get("count", 1))
			var item_name := ""
			var game_db = _get_autoload_node("/root/GameDatabase")
			if game_db and "items" in game_db and game_db.items:
				var rec = game_db.items.get_item(item_id)
				if rec:
					item_name = str(rec.name).strip_edges()
			if hud.has_method("add_inventory_item"):
				hud.add_inventory_item(item_id, count, item_name)
			if hud.dialogue_ctrl:
				hud.dialogue_ctrl.show_quest_reward(item_name if not item_name.is_empty() else "item %d" % item_id, count)
	_mirror_eve_quest_to_log()
	_save_to_slot()


func _mirror_eve_quest_to_log() -> void:
	if quest_component == null:
		return
	var target: int = int(_quest_steps.get(12018, 0))
	var iterations: int = 0
	while iterations < 5 and quest_component.active_quests.has(1003) and int(quest_component.active_quests[1003].get("current_step", 0)) < target:
		quest_component.advance_objective(1003)
		iterations += 1
	if not _quest_steps.has(12018):
		if quest_component.active_quests.has(1003) and int(quest_component.active_quests[1003].get("current_step", 0)) >= 2:
			quest_component.advance_objective(1003)


## What the event conditions can see about the player (quests, bag, gold, level).
func _eve_state() -> Dictionary:
	var count_item := func(item_id: int) -> int:
		var total := 0
		if hud and hud.inventory_ctrl:
			for slot in hud.inventory_ctrl.inventory_data:
				if slot is Dictionary and int(slot.get("id", 0)) == item_id:
					total += int(slot.get("count", 1))
		return total
	var free := 0
	if hud and hud.inventory_ctrl:
		for slot in hud.inventory_ctrl.inventory_data:
			if not (slot is Dictionary) or slot.is_empty() or int(slot.get("id", 0)) <= 0:
				free += 1
	var level := 1
	if hud and "character_status_ctrl" in hud and hud.character_status_ctrl:
		level = int(hud.character_status_ctrl.current_level)
	return {"quests": _quest_steps, "item_count": count_item, "gold": hud.get_gold() if hud else 0, "level": level, "free_slots": free}


func _try_eve_conversation(npc: Node2D, n_name: String) -> bool:
	var eve = ground_parser.eve_parser if ground_parser else null
	if eve == null or not hud or not hud.dialogue_ctrl or not npc.has_meta("eve_events"):
		return false
	var npc_events: Array = npc.get_meta("eve_events")
	var map_id: int = int(npc.get_meta("eve_map", 0))
	if npc_events.is_empty() or map_id <= 0:
		return false
	var events: Array = eve.get_events_for_map(map_id)
	var lookup := Callable(self, "_talk_text_lookup")
	var built: Dictionary = NpcEventScript.build(events, npc_events, _eve_state(), lookup)
	if built["pages"].is_empty() and built["actions"].is_empty():
		return false
	var event: Dictionary = NpcEventScript.find_event(events, int(built["event_click_id"]))
	var tid := 0
	var game_db = _get_autoload_node("/root/GameDatabase")
	if game_db and "npcs" in game_db and game_db.npcs:
		var rec = game_db.npcs.get_npc(int(npc.npc_id))
		if rec:
			tid = int(rec.talk_image)
	var script: Dictionary = {"pages": built["pages"], "actions": built["actions"], "question": int(built.get("question", 0))}
	_present_eve_script(event, script, 0, n_name, tid, -1)
	return true


## Shows one script (lines + optional question). A question's text and options are the Talk record after the last line
## (Doll's Yes/No: 20227; Emilie's digits: 20337 "1/2/3", then 20338). The answer branch can ask the next question;
## once an answer branch is done the search falls through to the branches behind it (`resume_after`, array position of
## the answer branch; -1 = none), which is how Emilie's quiz reaches "wrong" (20339) or "right" (20340).
func _present_eve_script(event: Dictionary, script: Dictionary, last_talk_id: int, n_name: String, tid: int, resume_after: int) -> void:
	var dialogue = hud.dialogue_ctrl
	var lookup := Callable(self, "_talk_text_lookup")
	var pages: Array[Dictionary] = []
	for page in script["pages"]:
		pages.append(page)
	var actions: Array = script["actions"]
	var question: int = int(script.get("question", 0))
	if question <= 0:
		var finish := func() -> void:
			_apply_script_actions(actions)
			if resume_after < 0:
				return
			var fall: Dictionary = NpcEventScript.find_branch(event, _eve_state(), 0, 0, 0, resume_after + 1)
			if fall.is_empty():
				return
			_present_eve_script(event, NpcEventScript.branch_script(fall, lookup), last_talk_id, n_name, tid, -1)
		if pages.is_empty():
			finish.call()
			return
		dialogue.show_script(pages, n_name, tid, finish)
		return
	var base_id: int = int(pages[pages.size() - 1]["talk_id"]) if not pages.is_empty() else last_talk_id
	var prompt_id: int = base_id + 1
	var prompt: Dictionary = _talk_text_lookup(prompt_id)
	var options: Array = []
	for c in prompt.get("choices", []):
		options.append(str(c.get("text", "")) if c is Dictionary else str(c))
	if options.is_empty():
		options = ["Yes.", "No."]
	var prompt_text := NpcEventScript.clean_text(str(prompt.get("text", "")))
	if not prompt_text.is_empty():
		pages.append({"who": "npc", "talk_id": prompt_id, "text": prompt_text})
	if pages.is_empty():
		return
	var on_answer := func(choice_idx: int, _text: String) -> void:
		_apply_script_actions(actions)
		var answer_sub: Dictionary = NpcEventScript.find_branch(event, _eve_state(), 7, question, NpcEventScript.ANSWER_BASE + choice_idx)
		if answer_sub.is_empty():
			# A wrong digit has no branch of its own: the quiz marks decide what Emilie says next.
			var last_answer := -1
			for i in event.get("subs", []).size():
				var cand: Dictionary = event["subs"][i]
				if int(cand.get("cond_byte", 0)) == 7 and int(cand.get("words", [0])[0]) == question:
					last_answer = i
			_present_eve_script(event, {"pages": [], "actions": [], "question": 0}, prompt_id, n_name, tid, last_answer)
			return
		_present_eve_script(event, NpcEventScript.branch_script(answer_sub, lookup), prompt_id, n_name, tid, NpcEventScript.position_of(event, answer_sub))
	dialogue.show_script(pages, n_name, tid, Callable(), options, on_answer)


func _on_dialogue_closed() -> void:
	_pending_npc_interaction = null
	if _active_dialogue_npc and is_instance_valid(_active_dialogue_npc):
		if _active_dialogue_npc.has_method("restore_facing"):
			_active_dialogue_npc.restore_facing()
		_active_dialogue_npc = null
	
	if entities:
		for child in entities.get_children():
			if is_instance_valid(child) and child != player and child is NpcEntity:
				if child.has_method("restore_facing") and child.original_heading >= 0 and child.heading != child.original_heading:
					if not child.is_moving:
						child.restore_facing()

	if (_is_captain_dialogue_active or _interacting_npc_id == 14003) and not _sinking_triggered:
		_is_captain_dialogue_active = false
		trigger_ship_sinking_cutscene()
	elif not _sinking_triggered:
		if player and is_instance_valid(player) and "is_movement_locked" in player:
			player.is_movement_locked = false
	_is_captain_dialogue_active = false
	_interacting_npc_id = 0
	_release_movement_if_free()

func _release_movement_if_free() -> void:
	if player == null or not is_instance_valid(player):
		return
	if sinking_cutscene != null and sinking_cutscene.is_cutscene_active:
		return
	if "_is_animating_wakeup" in player and player._is_animating_wakeup:
		return
	if "is_prone" in player and player.is_prone:
		return
	if "is_movement_locked" in player:
		player.is_movement_locked = false

func _on_sinking_cutscene_finished() -> void:
	if _island_warped:
		return
	_island_warped = true
	
	unload_ship_entities()

	# Advance Quest 1001 Step 1: Survive Ship Sinking & Awaken on Deserted Island
	if quest_component:
		quest_component.advance_objective_by_type("SurviveSinking")
	
	# Warp player to Deserted Island (Map 10003: Newbie / Monkey Beach at Pos 1342, 2495)
	_on_portal_triggered(null, 10003, Vector2(1342, 2495))
	
	if camera:
		camera.offset = Vector2.ZERO
		camera.rotation = 0.0
	
	# Ensure Kelang and beach entities are present on beach
	_ensure_beach_entities()
		
	# Captain Robinson pulls the player out of the water (no Kelang conversation)
	var shore_point := Vector2(1342, 2495)
	if player and is_instance_valid(player):
		player.global_position = shore_point + Vector2(-160, 60)
	_robinson_pull_out(shore_point)

	# Play authentic awakening music (BGM0024 or BGM0012)
	play_awakening_music()

func unload_ship_entities() -> void:
	for e in _deck_entities:
		if is_instance_valid(e) and "visible" in e:
			e.visible = false
	for e in _cabin_entities:
		if is_instance_valid(e) and "visible" in e:
			e.visible = false
	for e in _kitchen_entities:
		if is_instance_valid(e) and "visible" in e:
			e.visible = false
	for e in _dynamic_npcs:
		if is_instance_valid(e) and "visible" in e:
			e.visible = false

func play_awakening_music() -> void:
	var candidates := [
		"res://assets/sound/BGM0024.wav",
		"res://assets/sound/BGM0012.wav",
		"res://assets/sound/BGM0003.wav"
	]
	for p in candidates:
		if ResourceLoader.exists(p):
			var stream = load(p)
			if stream:
				bgm_player.stream = stream
				bgm_player.play()
				break

var _beach_entities_created: bool = false
var _beach_entities: Array[Node] = []

func _ensure_beach_entities() -> void:
	if _beach_entities_created:
		for e in _beach_entities:
			if is_instance_valid(e) and "visible" in e:
				e.visible = true
		return
	_beach_entities_created = true
	
	if not entities:
		return
	var npc_scene = load("res://scenes/world/npc.tscn")
	if not npc_scene:
		return
		
	var kelang: NpcEntity = npc_scene.instantiate()
	kelang.name = "KelangNPC"
	kelang.npc_id = 14062
	kelang.npc_name = "Kelang"
	kelang.talk_id = 20305
	kelang.model_jmp = "1131.jmp"
	kelang.world_position = Vector2(1390, 2460)
	kelang.heading = IsometricMath.Heading.SOUTH_WEST
	kelang.dialogue_text = "This is a deserted island. How did you end up here?"
	kelang.dialogue_choices = ["I was on a ship...", "Where is this place?"]
	kelang.npc_interacted.connect(interact_with_npc)
	entities.add_child(kelang)
	_beach_entities.append(kelang)

## Loads any of the 1,119 maps in Wonderland Online, updating renderer, portals, ground items, and NPCs.
func load_map(target_map_id: int, spawn_pos: Vector2 = Vector2.ZERO) -> bool:
	_save_to_slot()
	_pending_npc_interaction = null
	if spawn_pos == Vector2.ZERO:
		spawn_pos = _resolve_default_spawn(target_map_id)
	
	if map_renderer:
		map_renderer.load_map(target_map_id)
		if "_map_data" in map_renderer:
			if player and "map_data" in player:
				player.map_data = map_renderer._map_data
			if entities:
				for child in entities.get_children():
					if child is NpcEntity and "map_data" in child:
						child.map_data = map_renderer._map_data
	
	if player and spawn_pos != Vector2.ZERO:
		if player.has_method("teleport_to"):
			player.teleport_to(spawn_pos)
		else:
			player.position = spawn_pos
			if "world_position" in player:
				player.world_position = spawn_pos
			if "world_pos" in player:
				player.world_pos = spawn_pos
			if player.has_method("set_target_world_position"):
				player.set_target_world_position(spawn_pos)
		_update_camera_to_player()
		if camera and camera.has_method("reset_smoothing"):
			camera.reset_smoothing()
		if hud and hud.has_method("update_coordinates"):
			var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
			hud.update_coordinates(p_pos)
	
	_switch_map_entities(target_map_id)
	
	# Mark destination portals inside so player doesn't instantly retrigger
	for p in _dynamic_portals:
		if player and is_instance_valid(p):
			var p_pos: Vector2 = player.world_position if ("world_position" in player) else player.position
			var dx: float = (p_pos.x - p.position.x)
			var dy: float = (p_pos.y - p.position.y) * 2.0
			var player_cell := Vector2i(int(floor(p_pos.x / 20.0)), int(floor(p_pos.y / 20.0)))
			var portal_cell := Vector2i(int(floor(p.position.x / 20.0)), int(floor(p.position.y / 20.0)))
			if sqrt(dx * dx + dy * dy) <= p.trigger_radius + 30.0 or player_cell == portal_cell:
				p.mark_player_inside()
	
	_on_map_loaded(target_map_id)
	return true

func _resolve_default_spawn(target_map_id: int) -> Vector2:
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
	if CANONICAL_SPAWNS.has(target_map_id):
		return CANONICAL_SPAWNS[target_map_id]
	
	if not _dynamic_npcs.is_empty() and is_instance_valid(_dynamic_npcs[0]):
		return _dynamic_npcs[0].world_position
	
	if not _dynamic_portals.is_empty() and is_instance_valid(_dynamic_portals[0]):
		return _dynamic_portals[0].target_coords if _dynamic_portals[0].target_coords != Vector2.ZERO else _dynamic_portals[0].position
	
	if map_renderer and map_renderer.has_method("get_map_pixel_size"):
		var sz: Vector2 = map_renderer.get_map_pixel_size()
		if sz.x > 0 and sz.y > 0:
			return Vector2(sz.x * 0.5, sz.y * 0.5)
	
	return Vector2(500, 400)

## Returns all currently active visible NpcEntity instances in the world
func get_active_npcs() -> Array[NpcEntity]:
	var active_list: Array[NpcEntity] = []
	if entities:
		for child in entities.get_children():
			if child is NpcEntity and child != player and child.visible:
				active_list.append(child)
	return active_list

## Single-player save: everything the player owns, written to the save slot chosen on the title screen.
var _restoring: bool = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_to_slot()


func _restore_single_player_state() -> void:
	var gdb: Node = get_tree().root.get_node_or_null("GameDatabase")
	if gdb == null or not ("active_character" in gdb) or gdb.active_character.is_empty():
		return
	var char_data: Dictionary = gdb.active_character
	if not char_data.has("save_slot"):
		return
	_restoring = true
	var map_id: int = int(char_data.get("map_id", 0))
	var pos: Vector2 = SaveGame.array_to_vec(char_data.get("position", []))
	if map_id > 0 and map_renderer and map_id != int(map_renderer.current_map_id):
		load_map(map_id, pos)
	elif player and pos != Vector2.ZERO:
		player.global_position = pos
	_apply_save_snapshot(char_data)
	_restoring = false


func _save_to_slot() -> void:
	if _restoring or not is_inside_tree():
		return
	var gdb: Node = get_tree().root.get_node_or_null("GameDatabase")
	if gdb == null or not ("active_character" in gdb) or gdb.active_character.is_empty():
		return
	var char_data: Dictionary = gdb.active_character
	if not char_data.has("save_slot"):
		return
	var slot: int = int(char_data["save_slot"])
	var snap: Dictionary = _gather_save_snapshot()
	var merged: Dictionary = char_data.duplicate(true)
	for key in snap:
		merged[key] = snap[key]
	if int(snap.get("level", 0)) > 0:
		merged["level"] = int(snap["level"])
	SaveGame.write_slot(slot, merged)
	gdb.active_character = merged.duplicate(true)


static func _json_safe(value: Variant) -> Variant:
	if value == null:
		return null
	var t: int = typeof(value)
	if t == TYPE_INT or t == TYPE_FLOAT or t == TYPE_STRING or t == TYPE_BOOL:
		return value
	if t == TYPE_ARRAY:
		var safe_arr: Array = []
		for item in (value as Array):
			var safe_item: Variant = _json_safe(item)
			if typeof(safe_item) != TYPE_NIL:
				safe_arr.append(safe_item)
		return safe_arr
	if t == TYPE_DICTIONARY:
		var safe_dict: Dictionary = {}
		var dict: Dictionary = value as Dictionary
		for k in dict:
			var safe_val: Variant = _json_safe(dict[k])
			if typeof(safe_val) != TYPE_NIL:
				safe_dict[str(k)] = safe_val
		return safe_dict
	return null


func _gather_save_snapshot() -> Dictionary:
	var map_id_val: int = 0
	if map_renderer != null and "current_map_id" in map_renderer and map_renderer.current_map_id != null:
		map_id_val = int(map_renderer.current_map_id)

	var pos_val: Array = [0.0, 0.0]
	if player != null and "global_position" in player and player.global_position != null:
		pos_val = [float(player.global_position.x), float(player.global_position.y)]

	var gold_val: int = 0
	if hud != null and hud.has_method("get_gold"):
		gold_val = int(hud.get_gold())

	var inv_val: Array = []
	if hud != null and "_inventory_data" in hud and hud._inventory_data is Array:
		var safe_inv: Variant = _json_safe(hud._inventory_data)
		if safe_inv is Array:
			inv_val = safe_inv

	var eq_val: Dictionary = {}
	if hud != null and "_equipment_data" in hud and hud._equipment_data is Dictionary:
		var safe_eq: Variant = _json_safe(hud._equipment_data)
		if safe_eq is Dictionary:
			eq_val = safe_eq

	var q_steps_val: Dictionary = {}
	if _quest_steps != null:
		for k in _quest_steps:
			q_steps_val[str(k)] = int(_quest_steps[k])

	var q_active_val: Dictionary = {}
	var q_completed_val: Dictionary = {}
	if quest_component != null:
		if "active_quests" in quest_component and quest_component.active_quests is Dictionary:
			for k in quest_component.active_quests:
				var safe_entry: Variant = _json_safe(quest_component.active_quests[k])
				if typeof(safe_entry) != TYPE_NIL:
					q_active_val[str(k)] = safe_entry
		if "completed_quests" in quest_component and quest_component.completed_quests is Dictionary:
			for k in quest_component.completed_quests:
				var safe_entry: Variant = _json_safe(quest_component.completed_quests[k])
				if typeof(safe_entry) != TYPE_NIL:
					q_completed_val[str(k)] = safe_entry

	var exp_val: int = 0
	var level_val: int = 1
	if hud != null and "character_status_ctrl" in hud and hud.character_status_ctrl != null:
		var csc: Variant = hud.character_status_ctrl
		if "current_exp" in csc and csc.current_exp != null:
			exp_val = int(csc.current_exp)
		if "current_level" in csc and csc.current_level != null:
			level_val = int(csc.current_level)

	return {
		"map_id": map_id_val,
		"position": pos_val,
		"gold": gold_val,
		"inventory": inv_val,
		"equipment": eq_val,
		"quest_steps": q_steps_val,
		"quests_active": q_active_val,
		"quests_completed": q_completed_val,
		"exp": exp_val,
		"level": level_val
	}


func _apply_save_snapshot(snap: Dictionary) -> void:
	if snap.is_empty():
		return

	if hud != null and snap.has("inventory") and snap["inventory"] is Array:
		var sanitized_inv: Array[Dictionary] = []
		for item in (snap["inventory"] as Array):
			if item is Dictionary:
				sanitized_inv.append(item as Dictionary)
		hud._inventory_data = sanitized_inv

	if hud != null and snap.has("gold") and hud.has_method("update_gold"):
		hud.update_gold(int(snap["gold"]))

	if hud != null and "character_status_ctrl" in hud and hud.character_status_ctrl != null:
		var csc: Variant = hud.character_status_ctrl
		if snap.has("equipment") and snap["equipment"] is Dictionary:
			var eq: Dictionary = snap["equipment"] as Dictionary
			csc.equipment_data = eq
			if csc.has_method("update_character_paper_doll"):
				csc.update_character_paper_doll(eq)
		if snap.has("exp") and snap.has("level"):
			csc.current_exp = int(snap["exp"])
			csc.current_level = int(snap["level"])
			if csc.has_method("_refresh_header"):
				csc._refresh_header()

	if _quest_steps != null:
		_quest_steps.clear()
		if snap.has("quest_steps") and snap["quest_steps"] is Dictionary:
			var steps_data: Dictionary = snap["quest_steps"] as Dictionary
			for k in steps_data:
				_quest_steps[int(k)] = int(steps_data[k])

	if quest_component != null:
		if snap.has("quests_active") and snap["quests_active"] is Dictionary:
			var active_dict: Dictionary = {}
			var raw_act: Dictionary = snap["quests_active"] as Dictionary
			for k in raw_act:
				if raw_act[k] is Dictionary:
					active_dict[int(k)] = raw_act[k] as Dictionary
			quest_component.active_quests = active_dict

		if snap.has("quests_completed") and snap["quests_completed"] is Dictionary:
			var completed_dict: Dictionary = {}
			var raw_comp: Dictionary = snap["quests_completed"] as Dictionary
			for k in raw_comp:
				if raw_comp[k] is Dictionary:
					completed_dict[int(k)] = raw_comp[k] as Dictionary
			quest_component.completed_quests = completed_dict

		if quest_component.has_method("ensure_initialized"):
			quest_component.ensure_initialized()


func _robinson_pull_out(shore_point: Vector2) -> void:
	var captain: Node = null
	for entity in _deck_entities:
		if is_instance_valid(entity) and entity.get("npc_id") == 14003:
			captain = entity
			break

	# Nearest open-sea tile to the landing point on map 10003 (found from the map collision data).
	var water_point: Vector2 = Vector2(1190, 2610)
	if is_instance_valid(player):
		player.global_position = water_point
		if "is_movement_locked" in player:
			player.is_movement_locked = true
		if "is_prone" in player:
			player.is_prone = true

	if captain != null:
		captain.visible = true
		captain.world_position = shore_point + Vector2(-48, 0)
		captain.heading = IsometricMath.Heading.SOUTH_WEST

	var tween: Tween = create_tween()
	tween.tween_property(player, "global_position", shore_point, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		if captain != null:
			captain.visible = false
		if is_instance_valid(player):
			if player.has_method("play_wakeup_animation"):
				player.play_wakeup_animation(2.0, _on_rescue_wakeup_done)
			else:
				if "is_prone" in player:
					player.is_prone = false
				if "is_movement_locked" in player:
					player.is_movement_locked = false
	)


func _on_rescue_wakeup_done() -> void:
	if is_instance_valid(player) and "is_movement_locked" in player:
		player.is_movement_locked = false
