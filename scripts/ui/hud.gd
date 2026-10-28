class_name HUD
extends Control

## Refined, modular Wonderland Online HUD Facade Coordinator.
## Coordinates 9 dedicated sub-controllers in scripts/ui/hud/ while exposing
## 100% backward-compatible signals, node references, and public methods.

const MinimapMarker = preload("res://scripts/ui/minimap_marker.gd")
const ItemTooltipScene = preload("res://scripts/ui/item_tooltip.gd")
const AuthAudio = preload("res://scripts/ui/auth/auth_audio.gd")

# Sub-controller preloads
const HUDPlayerStatusClass = preload("res://scripts/ui/hud/hud_player_status.gd")
const HUDMinimapClass = preload("res://scripts/ui/hud/hud_minimap.gd")
const HUDActionDockClass = preload("res://scripts/ui/hud/hud_action_dock.gd")
const HUDHotbarClass = preload("res://scripts/ui/hud/hud_hotbar.gd")
const HUDWindowManagerClass = preload("res://scripts/ui/hud/hud_window_manager.gd")
const HUDInventoryClass = preload("res://scripts/ui/hud/hud_inventory.gd")
const NotebookWindowScript = preload("res://scripts/ui/hud/notebook_window.gd")
const HUDCharacterStatusClass = preload("res://scripts/ui/hud/hud_character_status.gd")
const HUDChatClass = preload("res://scripts/ui/hud/hud_chat.gd")
const HUDDialogueClass = preload("res://scripts/ui/hud/hud_dialogue.gd")

# 11 Public Signals
signal dialogue_choice_selected(choice_index: int, choice_text: String)
signal hotkey_action_triggered(slot_index: int)
signal dialogue_closed
signal chat_message_sent(channel: String, text: String)
signal equipment_changed(equip_layers: Dictionary)
signal banner_emitted(text: String)
signal minimap_clicked(norm_pos: Vector2)
signal chat_tab_changed(tab_name: String)
signal overhead_bubble_emitted(text_or_code: String)
signal minimap_zoom_changed(new_zoom: float)
signal minimap_collapsed_changed(is_collapsed: bool)
signal logout_requested

# Top-Left Player Status Dock (241x116)
@onready var status_dock: Control = $PlayerStatusDock
@onready var status_bg: TextureRect = $PlayerStatusDock/StatusBackground
@onready var avatar_bg: ColorRect = $PlayerStatusDock/AvatarBg
@onready var avatar_rect: TextureRect = $PlayerStatusDock/AvatarRect
@onready var name_label: Label = $PlayerStatusDock/NameLabel
@onready var level_label: Label = $PlayerStatusDock/LevelLabel
@onready var hp_label: Label = $PlayerStatusDock/HpLabel
@onready var hp_bar: Range = $PlayerStatusDock/HpBar
@onready var sp_label: Label = $PlayerStatusDock/SpLabel
@onready var sp_bar: Range = $PlayerStatusDock/SpBar
@onready var exp_label: Label = $PlayerStatusDock/ExpLabel
@onready var exp_bar: Range = $PlayerStatusDock/ExpBar
@onready var element_icon: TextureRect = $PlayerStatusDock/ElementIcon if has_node("PlayerStatusDock/ElementIcon") else null
@onready var hp_channel_under: TextureRect = $PlayerStatusDock/HpChannelUnder if has_node("PlayerStatusDock/HpChannelUnder") else null
@onready var sp_channel_under: TextureRect = $PlayerStatusDock/SpChannelUnder if has_node("PlayerStatusDock/SpChannelUnder") else null

# Top-Right Radar Minimap Dock (226x144)
@onready var minimap_dock: Control = $RadarMinimapDock
@onready var minimap_frame: TextureRect = $RadarMinimapDock/MinimapFrame
@onready var minimap_view: TextureRect = $RadarMinimapDock/MinimapView
@onready var minimap_bg: TextureRect = $RadarMinimapDock/MinimapView
@onready var map_name_label: Label = $RadarMinimapDock/MapNameLabel
@onready var coord_label: Label = $RadarMinimapDock/CoordinatesLabel
@onready var player_marker: Control = $RadarMinimapDock/MinimapView/PlayerMarker if has_node("RadarMinimapDock/MinimapView/PlayerMarker") else null
@onready var waypoint_marker: Control = $RadarMinimapDock/MinimapView/WaypointMarker if has_node("RadarMinimapDock/MinimapView/WaypointMarker") else null
@onready var btn_zoom_in: Button = $RadarMinimapDock/BtnZoomIn if has_node("RadarMinimapDock/BtnZoomIn") else null
@onready var btn_zoom_out: Button = $RadarMinimapDock/BtnZoomOut if has_node("RadarMinimapDock/BtnZoomOut") else null
@onready var btn_minimap_toggle: Button = $RadarMinimapDock/BtnMinimapToggle if has_node("RadarMinimapDock/BtnMinimapToggle") else null

# Bottom-Left Chat Dock
@onready var chat_dock: Control = $ChatDock
@onready var chat_history_panel: PanelContainer = $ChatDock/ChatHistoryPanel
@onready var chat_history: RichTextLabel = $ChatDock/ChatHistoryPanel/ChatHistory
@onready var chat_input_bg: TextureRect = $ChatDock/ChatInputBackground
@onready var chat_bar_rect: TextureRect = $ChatDock/ChatInputBackground
@onready var btn_mail: TextureButton = $ChatDock/BtnMail
@onready var btn_channel: Button = $ChatDock/BtnChannel
@onready var chat_input: LineEdit = $ChatDock/ChatInput
@onready var send_button: Button = $ChatDock/SendButton
@onready var chat_frame_nine_patch: NinePatchRect = $ChatDock/ChatHistoryPanel/ChatFrameNinePatch if has_node("ChatDock/ChatHistoryPanel/ChatFrameNinePatch") else null
@onready var panel_talk_form_left: TextureRect = $ChatDock/ChatHistoryPanel/PanelTalkFormLeft if has_node("ChatDock/ChatHistoryPanel/PanelTalkFormLeft") else null
@onready var btn_msg_lock: TextureButton = $ChatDock/ChatHistoryPanel/PanelTalkFormLeft/BtnMsgLock if has_node("ChatDock/ChatHistoryPanel/PanelTalkFormLeft/BtnMsgLock") else null
@onready var btn_chat_switch: TextureButton = $ChatDock/ChatHistoryPanel/PanelTalkFormLeft/BtnChatSwitch if has_node("ChatDock/ChatHistoryPanel/PanelTalkFormLeft/BtnChatSwitch") else null
@onready var btn_chat_size: TextureButton = $ChatDock/ChatHistoryPanel/BtnChatSize if has_node("ChatDock/ChatHistoryPanel/BtnChatSize") else null
@onready var chat_resize_handle: Control = $ChatDock/ChatHistoryPanel/ChatResizeHandle if has_node("ChatDock/ChatHistoryPanel/ChatResizeHandle") else null
@onready var whisper_target: LineEdit = $ChatDock/WhisperTarget if has_node("ChatDock/WhisperTarget") else null
@onready var btn_emote: TextureButton = $ChatDock/BtnEmote if has_node("ChatDock/BtnEmote") else null
@onready var channel_dropdown: Control = $ChatDock/ChannelDropdown if has_node("ChatDock/ChannelDropdown") else null
@onready var emote_popup: Control = $ChatDock/EmotePopup if has_node("ChatDock/EmotePopup") else null
@onready var emote_grid: GridContainer = $ChatDock/EmotePopup/EmoteGrid if has_node("ChatDock/EmotePopup/EmoteGrid") else null
@onready var emote_close_btn: Button = $ChatDock/EmotePopup/EmoteCloseBtn if has_node("ChatDock/EmotePopup/EmoteCloseBtn") else null

# Channel Tabs Bar
@onready var channel_tabs: Control = $ChatDock/ChannelTabs if has_node("ChatDock/ChannelTabs") else null
@onready var btn_tab_all: Button = $ChatDock/ChannelTabs/BtnTabAll if has_node("ChatDock/ChannelTabs/BtnTabAll") else null
@onready var btn_tab_current: Button = $ChatDock/ChannelTabs/BtnTabCurrent if has_node("ChatDock/ChannelTabs/BtnTabCurrent") else null
@onready var btn_tab_team: Button = $ChatDock/ChannelTabs/BtnTabTeam if has_node("ChatDock/ChannelTabs/BtnTabTeam") else null
@onready var btn_tab_guild: Button = $ChatDock/ChannelTabs/BtnTabGuild if has_node("ChatDock/ChannelTabs/BtnTabGuild") else null
@onready var btn_tab_whisper: Button = $ChatDock/ChannelTabs/BtnTabWhisper if has_node("ChatDock/ChannelTabs/BtnTabWhisper") else null
@onready var btn_tab_system: Button = $ChatDock/ChannelTabs/BtnTabSystem if has_node("ChatDock/ChannelTabs/BtnTabSystem") else null

# Right Hotbar Dock (56x274)
@onready var hotbar_dock: Control = $HotbarDock
@onready var hotbar_bg: TextureRect = $HotbarDock/HotbarBackground
@onready var slots_container: Control = $HotbarDock/SlotsContainer

# Bottom Action Dock (280x70) - 6 Circular Buttons
@onready var action_dock: Control = $BottomActionDock
@onready var action_bg: TextureRect = $BottomActionDock/ActionBackground
@onready var location_label: Label = $BottomActionDock/LocationLabel
@onready var btn_status: TextureButton = $BottomActionDock/ButtonContainer/BtnStatus
@onready var btn_skill: TextureButton = $BottomActionDock/ButtonContainer/BtnSkill
@onready var btn_quest: TextureButton = $BottomActionDock/ButtonContainer/BtnQuest
@onready var btn_team: TextureButton = $BottomActionDock/ButtonContainer/BtnTeam
@onready var btn_friends: TextureButton = $BottomActionDock/ButtonContainer/BtnFriends
@onready var btn_system: TextureButton = $BottomActionDock/ButtonContainer/BtnSystem

# Button compatibility aliases
var btn_11: TextureButton:
	get: return btn_status
var btn_12: TextureButton:
	get: return btn_skill
var btn_13: TextureButton:
	get: return btn_quest
var btn_14: TextureButton:
	get: return btn_team
var btn_15: TextureButton:
	get: return btn_friends
var btn_16: TextureButton:
	get: return btn_system
var btn_inventory: TextureButton:
	get: return btn_status
var btn_battle: TextureButton:
	get: return btn_system

# Dual-Form Dialogue System (Form_Talk_1 & Form_Talk_3)
@onready var dialogue_system: Control = $DialogueSystem
@onready var dialogue_dock: Control = $DialogueSystem/FormTalk1
@onready var dialogue_bg: TextureRect = $DialogueSystem/FormTalk1/TalkBackground
@onready var portrait_frame: Control = $DialogueSystem/FormTalk1/PortraitFrame
@onready var portrait_rect: TextureRect = $DialogueSystem/FormTalk1/PortraitFrame/PortraitTexture
@onready var speaker_label: Label = $DialogueSystem/FormTalk1/SpeakerNameplate
@onready var dialogue_text: RichTextLabel = $DialogueSystem/FormTalk1/DialogueText
@onready var next_icon: TextureRect = $DialogueSystem/FormTalk1/NextIcon

@onready var branching_dock: Control = $DialogueSystem/FormTalk3
@onready var branching_bg: TextureRect = $DialogueSystem/FormTalk3/ChoiceBackground
@onready var choice_title: Label = $DialogueSystem/FormTalk3/ChoiceTitle
@onready var choices_container: VBoxContainer = $DialogueSystem/FormTalk3/ChoiceList

# Floating Windows
@onready var floating_windows: Control = $FloatingWindows
@onready var inventory_window: Control = $FloatingWindows/InventoryWindow
@onready var inventory_bg: TextureRect = $FloatingWindows/InventoryWindow/Background
@onready var char_window: Control = $FloatingWindows/CharacterWindow
@onready var char_bg: TextureRect = $FloatingWindows/CharacterWindow/Background
@onready var char_paper_doll: TextureRect = $FloatingWindows/CharacterWindow/PaperDoll
@onready var stat_name: Label = $FloatingWindows/CharacterWindow/StatName
@onready var stat_level: Label = $FloatingWindows/CharacterWindow/StatLevel
@onready var stat_element: Label = $FloatingWindows/CharacterWindow/StatElement
@onready var stat_left_hp: Label = $FloatingWindows/CharacterWindow/StatLeftHp
@onready var stat_left_sp: Label = $FloatingWindows/CharacterWindow/StatLeftSp
@onready var stat_left_exp: Label = $FloatingWindows/CharacterWindow/StatLeftExp
@onready var stat_atk: Label = $FloatingWindows/CharacterWindow/StatAtk
@onready var stat_def: Label = $FloatingWindows/CharacterWindow/StatDef
@onready var stat_matk: Label = $FloatingWindows/CharacterWindow/StatMatk
@onready var stat_mdef: Label = $FloatingWindows/CharacterWindow/StatMdef
@onready var stat_spd: Label = $FloatingWindows/CharacterWindow/StatSpd
@onready var stat_str: Label = $FloatingWindows/CharacterWindow/StatLeftStr if has_node("FloatingWindows/CharacterWindow/StatLeftStr") else null
@onready var stat_con: Label = $FloatingWindows/CharacterWindow/StatLeftCon if has_node("FloatingWindows/CharacterWindow/StatLeftCon") else null
@onready var stat_int: Label = $FloatingWindows/CharacterWindow/StatLeftInt if has_node("FloatingWindows/CharacterWindow/StatLeftInt") else null
@onready var stat_wis: Label = $FloatingWindows/CharacterWindow/StatLeftWis if has_node("FloatingWindows/CharacterWindow/StatLeftWis") else null
@onready var stat_agi: Label = $FloatingWindows/CharacterWindow/StatLeftAgi if has_node("FloatingWindows/CharacterWindow/StatLeftAgi") else null
@onready var stat_free: Label = $FloatingWindows/CharacterWindow/StatLeftFree if has_node("FloatingWindows/CharacterWindow/StatLeftFree") else null
@onready var inventory_grid: Control = $FloatingWindows/CharacterWindow/InventoryGrid
@onready var gold_label: Label = $FloatingWindows/CharacterWindow/GoldLabel

var stat_left_str: Label:
	get: return stat_str
var stat_left_con: Label:
	get: return stat_con
var stat_left_int: Label:
	get: return stat_int
var stat_left_wis: Label:
	get: return stat_wis
var stat_left_agi: Label:
	get: return stat_agi
var stat_left_free: Label:
	get: return stat_free

@onready var fight_window: Control = $FloatingWindows/FightWindow
@onready var fight_bg: TextureRect = $FloatingWindows/FightWindow/Background
@onready var skill_window: Control = $FloatingWindows/SkillWindow
@onready var skill_bg: TextureRect = $FloatingWindows/SkillWindow/Background
@onready var team_window: Control = $FloatingWindows/TeamWindow
@onready var team_bg: TextureRect = $FloatingWindows/TeamWindow/Background
@onready var quest_window: Control = $FloatingWindows/QuestWindow
@onready var quest_bg: TextureRect = $FloatingWindows/QuestWindow/Background
@onready var friends_window: Control = $FloatingWindows/FriendsWindow
@onready var friends_bg: TextureRect = $FloatingWindows/FriendsWindow/Background
@onready var system_window: Control = $FloatingWindows/SystemWindow
@onready var system_bg: TextureRect = $FloatingWindows/SystemWindow/Background
@onready var compound_window: Control = $FloatingWindows/CompoundWindow if has_node("FloatingWindows/CompoundWindow") else null
@onready var shop_window: Control = $FloatingWindows/ShopWindow if has_node("FloatingWindows/ShopWindow") else null

# Shared and delegated variables
var _item_tooltip: PanelContainer = null
var current_map_id: int:
	get: return minimap_ctrl.current_map_id if minimap_ctrl else 10001
	set(val):
		if minimap_ctrl: minimap_ctrl.current_map_id = val
var current_map_pixel_size: Vector2:
	get: return minimap_ctrl.current_map_pixel_size if minimap_ctrl else Vector2(2432, 1792)
	set(val):
		if minimap_ctrl: minimap_ctrl.current_map_pixel_size = val
var current_player_norm_pos: Vector2:
	get: return minimap_ctrl.current_player_norm_pos if minimap_ctrl else Vector2(0.5, 0.5)
	set(val):
		if minimap_ctrl: minimap_ctrl.current_player_norm_pos = val
var minimap_zoom: float:
	get: return minimap_ctrl.minimap_zoom if minimap_ctrl else 1.0
	set(val):
		if minimap_ctrl: minimap_ctrl.minimap_zoom = val

var _minimap_is_collapsed: bool:
	get: return minimap_ctrl._minimap_is_collapsed if minimap_ctrl else false
	set(val):
		if minimap_ctrl: minimap_ctrl._minimap_is_collapsed = val

var current_equip_layers: Dictionary:
	get: return character_status_ctrl.current_equip_layers if character_status_ctrl else {}
	set(val):
		if character_status_ctrl: character_status_ctrl.current_equip_layers = val

var base_atk: int:
	get: return character_status_ctrl.base_atk if character_status_ctrl else 26
	set(val):
		if character_status_ctrl: character_status_ctrl.base_atk = val
var base_def: int:
	get: return character_status_ctrl.base_def if character_status_ctrl else 25
	set(val):
		if character_status_ctrl: character_status_ctrl.base_def = val
var base_matk: int:
	get: return character_status_ctrl.base_matk if character_status_ctrl else 15
	set(val):
		if character_status_ctrl: character_status_ctrl.base_matk = val
var base_mdef: int:
	get: return character_status_ctrl.base_mdef if character_status_ctrl else 14
	set(val):
		if character_status_ctrl: character_status_ctrl.base_mdef = val
var base_spd: int:
	get: return character_status_ctrl.base_spd if character_status_ctrl else 21
	set(val):
		if character_status_ctrl: character_status_ctrl.base_spd = val

var player: Node2D = null:
	set(val):
		if player and is_instance_valid(player) and player.has_signal("stats_changed"):
			if player.is_connected("stats_changed", _on_player_stats_changed):
				player.disconnect("stats_changed", _on_player_stats_changed)
		player = val
		if character_status_ctrl:
			character_status_ctrl.player = val
			if val and val.has_method("set_equipment") and not character_status_ctrl.current_equip_layers.is_empty():
				val.set_equipment(character_status_ctrl.current_equip_layers)
		if player and is_instance_valid(player):
			if player.has_signal("stats_changed"):
				if not player.is_connected("stats_changed", _on_player_stats_changed):
					player.connect("stats_changed", _on_player_stats_changed)
			_sync_player_stats_from_player()

# 9 Dedicated Sub-Controllers
var player_status_ctrl: HUDPlayerStatusClass = null
var minimap_ctrl: HUDMinimapClass = null
var action_dock_ctrl: HUDActionDockClass = null
var hotbar_ctrl: HUDHotbarClass = null
var window_manager_ctrl: HUDWindowManagerClass = null
var inventory_ctrl: HUDInventoryClass = null
var character_status_ctrl: HUDCharacterStatusClass = null
var chat_ctrl: HUDChatClass = null
var dialogue_ctrl: HUDDialogueClass = null

# Sub-controller direct accessors
var inventory: HUDInventoryClass:
	get: return inventory_ctrl
var character_status: HUDCharacterStatusClass:
	get: return character_status_ctrl
var chat: HUDChatClass:
	get: return chat_ctrl
var dialogue: HUDDialogueClass:
	get: return dialogue_ctrl
var hotbar: HUDHotbarClass:
	get: return hotbar_ctrl
var player_status: HUDPlayerStatusClass:
	get: return player_status_ctrl
var minimap: HUDMinimapClass:
	get: return minimap_ctrl
var action_dock_sub: HUDActionDockClass:
	get: return action_dock_ctrl
var window_manager: HUDWindowManagerClass:
	get: return window_manager_ctrl

# Compatibility properties for tests and legacy callers
var _hotkey_buttons: Array[Button]:
	get:
		var empty_btns: Array[Button] = []
		return hotbar_ctrl._hotkey_buttons if hotbar_ctrl else empty_btns
	set(val):
		if hotbar_ctrl: hotbar_ctrl._hotkey_buttons = val

var _hotkey_icons: Array[TextureRect]:
	get:
		var empty_icons: Array[TextureRect] = []
		return hotbar_ctrl._hotkey_icons if hotbar_ctrl else empty_icons
	set(val):
		if hotbar_ctrl: hotbar_ctrl._hotkey_icons = val

func _setup_hotbar() -> void:
	if hotbar_ctrl: hotbar_ctrl._setup_slots()
var _inventory_data: Array[Dictionary]:
	get:
		var empty_inv: Array[Dictionary] = []
		return inventory_ctrl.inventory_data if inventory_ctrl else empty_inv
	set(val):
		if inventory_ctrl: inventory_ctrl.inventory_data = val

var _equipment_data: Dictionary:
	get: return character_status_ctrl.equipment_data if character_status_ctrl else {}
	set(val):
		if character_status_ctrl: character_status_ctrl.equipment_data = val

var _portrait_frames: Array[Texture2D]:
	get:
		var empty_portraits: Array[Texture2D] = []
		return dialogue_ctrl._portrait_frames if dialogue_ctrl else empty_portraits
	set(val):
		if dialogue_ctrl: dialogue_ctrl._portrait_frames = val

var _dragging_window: Control:
	get: return window_manager_ctrl._dragging_window if window_manager_ctrl else null
	set(val):
		if window_manager_ctrl: window_manager_ctrl._dragging_window = val

var _drag_offset: Vector2:
	get: return window_manager_ctrl._drag_offset if window_manager_ctrl else Vector2.ZERO
	set(val):
		if window_manager_ctrl: window_manager_ctrl._drag_offset = val

var _current_player_role_id: int:
	get: return player_status_ctrl._current_player_role_id if player_status_ctrl else 6
	set(val):
		if player_status_ctrl: player_status_ctrl._current_player_role_id = val

var _avatar_frames: Array[Texture2D]:
	get: return player_status_ctrl._avatar_frames if player_status_ctrl else []
	set(val):
		if player_status_ctrl: player_status_ctrl._avatar_frames = val

var _avatar_is_blinking: bool:
	get: return player_status_ctrl._avatar_is_blinking if player_status_ctrl else false
	set(val):
		if player_status_ctrl: player_status_ctrl._avatar_is_blinking = val

var _chat_is_framed: bool:
	get: return chat_ctrl._chat_is_framed if chat_ctrl else false
	set(val):
		if chat_ctrl: chat_ctrl._chat_is_framed = val

var _chat_is_locked: bool:
	get: return chat_ctrl._chat_is_locked if chat_ctrl else false
	set(val):
		if chat_ctrl: chat_ctrl._chat_is_locked = val

var _current_channel: String:
	get: return chat_ctrl._current_channel if chat_ctrl else "Local"
	set(val):
		if chat_ctrl: chat_ctrl._current_channel = val

var _chat_is_resizing: bool:
	get: return chat_ctrl._chat_is_resizing if chat_ctrl else false
	set(val):
		if chat_ctrl: chat_ctrl._chat_is_resizing = val

var _active_chat_tab: String:
	get: return chat_ctrl._active_chat_tab if chat_ctrl else "All"
	set(val):
		if chat_ctrl: chat_ctrl._active_chat_tab = val

func _select_channel(channel: String) -> void:
	if chat_ctrl: chat_ctrl._select_channel(channel)

func _on_chat_size_gui_input(event: InputEvent) -> void:
	if chat_ctrl: chat_ctrl._on_chat_size_gui_input(event)

func _on_chat_submitted(text: String) -> void:
	if chat_ctrl: chat_ctrl.on_chat_submitted(text)

func _on_chat_meta_clicked(meta: Variant) -> void:
	if chat_ctrl: chat_ctrl._on_chat_meta_clicked(meta)

func start_window_drag(win: Control, global_mouse_pos: Vector2) -> void:
	if window_manager_ctrl:
		window_manager_ctrl.start_window_drag(win, global_mouse_pos)

func _start_window_drag(win: Control, global_mouse_pos: Vector2) -> void:
	start_window_drag(win, global_mouse_pos)



func _ready() -> void:
	_item_tooltip = ItemTooltipScene.new()
	_item_tooltip.name = "ItemTooltip"
	add_child(_item_tooltip)
	
	_init_sub_controllers()
	
	# Apply default fallback character data (Daniel, Role 6)
	apply_character_data({
		"role_id": 6,
		"name": "Daniel",
		"level": 10,
		"element": "Fire",
		"hp": 245,
		"max_hp": 245,
		"sp": 180,
		"max_sp": 180,
		"exp": 4500,
		"max_exp": 10000,
		"str": 14,
		"con": 12,
		"int": 6,
		"wis": 5,
		"agi": 11,
		"gold": 500
	})
	
	add_chat_message("System", "Welcome to Wonderland Online! Use Arrow Keys or Mouse to move.", "System")
	add_chat_message("System", "Hotkeys: [C] Status | [I] Item | [S] Skill | [T] Team | [Q] Quest | [F] Friends | [P] PK | [Esc] System", "System")

func _ensure_sub_controllers() -> void:
	if inventory_ctrl == null:
		_init_sub_controllers()

func _init_sub_controllers() -> void:
	if inventory_ctrl != null:
		return
	var nodes := {
		"status_dock": status_dock,
		"status_bg": status_bg,
		"avatar_bg": avatar_bg,
		"avatar_rect": avatar_rect,
		"name_label": name_label,
		"level_label": level_label,
		"hp_label": hp_label,
		"hp_bar": hp_bar,
		"sp_label": sp_label,
		"sp_bar": sp_bar,
		"exp_label": exp_label,
		"exp_bar": exp_bar,
		"element_icon": element_icon,
		"hp_channel_under": hp_channel_under,
		"sp_channel_under": sp_channel_under,
		
		"minimap_dock": minimap_dock,
		"minimap_frame": minimap_frame,
		"minimap_view": minimap_view,
		"map_name_label": map_name_label,
		"coord_label": coord_label,
		"player_marker": player_marker,
		"waypoint_marker": waypoint_marker,
		"btn_zoom_in": btn_zoom_in,
		"btn_zoom_out": btn_zoom_out,
		"btn_minimap_toggle": btn_minimap_toggle,
		
		"action_dock": action_dock,
		"action_bg": action_bg,
		"location_label": location_label,
		"btn_status": btn_status,
		"btn_skill": btn_skill,
		"btn_quest": btn_quest,
		"btn_team": btn_team,
		"btn_friends": btn_friends,
		"btn_system": btn_system,
		
		"hotbar_dock": hotbar_dock,
		"hotbar_bg": hotbar_bg,
		"slots_container": slots_container,
		
		"floating_windows": floating_windows,
		"inventory_window": inventory_window,
		"char_window": char_window,
		"fight_window": fight_window,
		"skill_window": skill_window,
		"team_window": team_window,
		"quest_window": quest_window,
		"friends_window": friends_window,
		"system_window": system_window,
		
		"inventory_grid": inventory_grid,
		"gold_label": gold_label,
		"item_tooltip": _item_tooltip,
		
		"char_paper_doll": char_paper_doll,
		"stat_name": stat_name,
		"stat_level": stat_level,
		"stat_element": stat_element,
		"stat_left_hp": stat_left_hp,
		"stat_left_sp": stat_left_sp,
		"stat_left_exp": stat_left_exp,
		"stat_atk": stat_atk,
		"stat_def": stat_def,
		"stat_matk": stat_matk,
		"stat_mdef": stat_mdef,
		"stat_spd": stat_spd,
		"stat_str": stat_str,
		"stat_con": stat_con,
		"stat_int": stat_int,
		"stat_wis": stat_wis,
		"stat_agi": stat_agi,
		"stat_free": stat_free,
		
		"chat_dock": chat_dock,
		"chat_history_panel": chat_history_panel,
		"chat_history": chat_history,
		"chat_input_bg": chat_input_bg,
		"btn_mail": btn_mail,
		"btn_channel": btn_channel,
		"chat_input": chat_input,
		"send_button": send_button,
		"chat_frame_nine_patch": chat_frame_nine_patch,
		"panel_talk_form_left": panel_talk_form_left,
		"btn_msg_lock": btn_msg_lock,
		"btn_chat_switch": btn_chat_switch,
		"btn_chat_size": btn_chat_size,
		"chat_resize_handle": chat_resize_handle,
		"whisper_target": whisper_target,
		"btn_emote": btn_emote,
		"channel_dropdown": channel_dropdown,
		"emote_popup": emote_popup,
		"emote_grid": emote_grid,
		"emote_close_btn": emote_close_btn,
		"channel_tabs": channel_tabs,
		"btn_tab_all": btn_tab_all,
		"btn_tab_current": btn_tab_current,
		"btn_tab_team": btn_tab_team,
		"btn_tab_guild": btn_tab_guild,
		"btn_tab_whisper": btn_tab_whisper,
		"btn_tab_system": btn_tab_system,
		
		"dialogue_system": dialogue_system,
		"dialogue_dock": dialogue_dock,
		"dialogue_bg": dialogue_bg,
		"portrait_frame": portrait_frame,
		"portrait_rect": portrait_rect,
		"speaker_label": speaker_label,
		"dialogue_text": dialogue_text,
		"next_icon": next_icon,
		"branching_dock": branching_dock,
		"branching_bg": branching_bg,
		"choice_title": choice_title,
		"choices_container": choices_container,
	}
	
	# Instantiate and wire controllers
	player_status_ctrl = HUDPlayerStatusClass.new()
	minimap_ctrl = HUDMinimapClass.new()
	action_dock_ctrl = HUDActionDockClass.new()
	hotbar_ctrl = HUDHotbarClass.new()
	window_manager_ctrl = HUDWindowManagerClass.new()
	inventory_ctrl = HUDInventoryClass.new()
	character_status_ctrl = HUDCharacterStatusClass.new()
	chat_ctrl = HUDChatClass.new()
	dialogue_ctrl = HUDDialogueClass.new()
	
	player_status_ctrl.setup(self, nodes)
	minimap_ctrl.setup(self, nodes)
	action_dock_ctrl.setup(self, nodes)
	hotbar_ctrl.setup(self, nodes)
	window_manager_ctrl.setup(self, nodes)
	if not window_manager_ctrl.logout_requested.is_connected(_on_window_manager_logout_requested):
		window_manager_ctrl.logout_requested.connect(_on_window_manager_logout_requested)
	inventory_ctrl.setup(self, nodes)
	character_status_ctrl.setup(self, nodes)
	chat_ctrl.setup(self, nodes)
	dialogue_ctrl.setup(self, nodes)
	_connect_system_settings_to_chat()
	_build_top_action_bar()

const HUDTopBarScript = preload("res://scripts/ui/hud/hud_top_bar.gd")
var top_action_bar: Control = null

## Round action icons along the top-right edge, as in the real client.
func _build_top_action_bar() -> void:
	if top_action_bar != null:
		return
	top_action_bar = HUDTopBarScript.new()
	add_child(top_action_bar)
	top_action_bar.setup(self)
	# The minimap sits under the icon row.
	var minimap_dock := get_node_or_null("RadarMinimapDock") as Control
	if minimap_dock:
		minimap_dock.offset_top += 40.0
		minimap_dock.offset_bottom += 40.0

## The System window's chat colour pickers drive the chat tag colours (initial values and changes).
func _connect_system_settings_to_chat() -> void:
	if not system_window or not chat_ctrl or not system_window.has_signal("settings_changed"):
		return
	if not system_window.settings_changed.is_connected(_on_system_settings_changed):
		system_window.settings_changed.connect(_on_system_settings_changed)
	if system_window.has_method("get_settings_data"):
		_on_system_settings_changed(system_window.get_settings_data())

func _on_system_settings_changed(settings: Dictionary) -> void:
	if chat_ctrl and chat_ctrl.has_method("apply_chat_colors") and settings.get("chat_colors") is Dictionary:
		chat_ctrl.apply_chat_colors(settings["chat_colors"])

func _process(delta: float) -> void:
	if minimap_ctrl: minimap_ctrl.process(delta)
	if dialogue_ctrl: dialogue_ctrl.process(delta)
	if player_status_ctrl: player_status_ctrl.process(delta)
	if character_status_ctrl: character_status_ctrl.process(delta)

func _input(event: InputEvent) -> void:
	if chat_ctrl and chat_ctrl.handle_input(event):
		return
	if window_manager_ctrl and window_manager_ctrl.handle_input(event):
		return

func _mark_input_handled() -> void:
	if is_inside_tree():
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	# Mouse left-click anywhere advances dialogue if active
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dialogue_dock and dialogue_dock.visible and not (branching_dock and branching_dock.visible):
			advance_dialogue()
			_mark_input_handled()
			return

	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	
	var key_event := event as InputEventKey
	
	# Dialogue advancement via Space or Enter
	if dialogue_dock and dialogue_dock.visible and not (branching_dock and branching_dock.visible):
		if not (chat_input and chat_input.has_focus()):
			if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
				advance_dialogue()
				_mark_input_handled()
				return

	# Enter key: Chat activation
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		if chat_input and chat_input.has_focus():
			_on_send_pressed()
		elif chat_input:
			chat_input.grab_focus()
		_mark_input_handled()
		return
	
	# Space key: Dialogue advancement fallback
	if key_event.keycode == KEY_SPACE and dialogue_dock and dialogue_dock.visible:
		advance_dialogue()
		_mark_input_handled()
		return
	
	# Escape key: Close open dialogues / floating windows
	if key_event.keycode == KEY_ESCAPE:
		if branching_dock and branching_dock.visible:
			hide_choices()
			_mark_input_handled()
			return
		elif dialogue_dock and dialogue_dock.visible:
			hide_dialogue()
			_mark_input_handled()
			return
		elif window_manager_ctrl and window_manager_ctrl.close_top_or_system_window():
			_mark_input_handled()
			return
	
	# Hotkey dock actions (F1..F8)
	if key_event.keycode >= KEY_F1 and key_event.keycode <= KEY_F8:
		var slot_idx: int = key_event.keycode - KEY_F1
		activate_hotbar_slot(slot_idx)
		_mark_input_handled()
		return
	
	# Window toggle hotkeys
	if not (chat_input and chat_input.has_focus()):
		match key_event.keycode:
			KEY_C, KEY_E:
				toggle_character_status()
				_mark_input_handled()
			KEY_V:
				toggle_compound_window()
				_mark_input_handled()
			KEY_S, KEY_K:
				toggle_skill_window()
				_mark_input_handled()
			KEY_I:
				toggle_inventory()
				_mark_input_handled()
			KEY_T, KEY_P:
				toggle_team_window()
				_mark_input_handled()
			KEY_Q:
				toggle_quest_window()
				_mark_input_handled()
			KEY_F, KEY_G:
				toggle_friends_window()
				_mark_input_handled()
			KEY_M:
				toggle_minimap()
				_mark_input_handled()
			KEY_PAGEUP:
				prev_hotbar_page()
				_mark_input_handled()
			KEY_PAGEDOWN:
				next_hotbar_page()
				_mark_input_handled()
			KEY_INSERT:
				if player and is_instance_valid(player) and player.has_method("toggle_sit_stand"):
					player.toggle_sit_stand()
				_mark_input_handled()

# ==============================================================================
# Public API Delegation
# ==============================================================================

func apply_character_data(char_data: Dictionary) -> void:
	if character_status_ctrl: character_status_ctrl.apply_character_data(char_data)
	if player_status_ctrl:
		var exp_pct: float = 0.0
		if char_data.has("exp_percent"):
			exp_pct = float(char_data.get("exp_percent", 0.0))
		elif int(char_data.get("max_exp", 10000)) > 0:
			exp_pct = (float(char_data.get("exp", 0)) / float(char_data.get("max_exp", 10000))) * 100.0
		
		player_status_ctrl.set_player_stats(
			str(char_data.get("name", "Daniel")),
			int(char_data.get("level", 10)),
			int(char_data.get("hp", 245)),
			int(char_data.get("max_hp", 245)),
			int(char_data.get("sp", 180)),
			int(char_data.get("max_sp", 180)),
			exp_pct
		)
		player_status_ctrl.set_player_role(int(char_data.get("role_id", 6)))
		if char_data.has("element"):
			player_status_ctrl.set_player_element(char_data.get("element"))

	var tw: Node = get_node_or_null("FloatingWindows/TeamWindow")
	if tw and tw.has_method("set_player_data"):
		tw.set_player_data(char_data)

func set_player_stats(p_name: String, p_lvl: int, p_hp: int, p_max_hp: int, p_sp: int, p_max_sp: int, p_exp: Variant, p_max_exp: int = 100) -> void:
	if player_status_ctrl: player_status_ctrl.set_player_stats(p_name, p_lvl, p_hp, p_max_hp, p_sp, p_max_sp, p_exp, p_max_exp)
	var tw: Node = get_node_or_null("FloatingWindows/TeamWindow")
	if tw and tw.has_method("set_player_data"):
		tw.set_player_data({
			"name": p_name,
			"level": p_lvl,
			"hp": p_hp,
			"max_hp": p_max_hp,
			"sp": p_sp,
			"max_sp": p_max_sp
		})

func update_player_stats(p_name: String, p_lvl: int, p_hp: int, p_max_hp: int, p_sp: int, p_max_sp: int, p_exp: Variant, p_max_exp: int = 100) -> void:
	if player_status_ctrl: player_status_ctrl.update_player_stats(p_name, p_lvl, p_hp, p_max_hp, p_sp, p_max_sp, p_exp, p_max_exp)

func _sync_player_stats_from_player() -> void:
	if not player:
		return
	var p_name: String = str(player.get("character_name")) if "character_name" in player else "Daniel"
	var p_lvl: int = int(player.get("level")) if "level" in player else 10
	var p_hp: int = int(player.get("hp")) if "hp" in player else 245
	var p_max_hp: int = int(player.get("max_hp")) if "max_hp" in player else 245
	var p_sp: int = int(player.get("sp")) if "sp" in player else 180
	var p_max_sp: int = int(player.get("max_sp")) if "max_sp" in player else 180
	var p_exp: Variant = player.get("exp_percent") if "exp_percent" in player else 45.0
	set_player_stats(p_name, p_lvl, p_hp, p_max_hp, p_sp, p_max_sp, p_exp)
	if "role_id" in player:
		set_player_role(int(player.get("role_id")))

func _on_player_stats_changed(stat_dict: Dictionary) -> void:
	var p_name: String = str(stat_dict.get("name", player.get("character_name") if player and "character_name" in player else "Daniel"))
	var p_lvl: int = int(stat_dict.get("level", player.get("level") if player and "level" in player else 10))
	var p_hp: int = int(stat_dict.get("hp", player.get("hp") if player and "hp" in player else 245))
	var p_max_hp: int = int(stat_dict.get("max_hp", player.get("max_hp") if player and "max_hp" in player else 245))
	var p_sp: int = int(stat_dict.get("sp", player.get("sp") if player and "sp" in player else 180))
	var p_max_sp: int = int(stat_dict.get("max_sp", player.get("max_sp") if player and "max_sp" in player else 180))
	var p_exp: Variant = stat_dict.get("exp_percent", player.get("exp_percent") if player and "exp_percent" in player else 45.0)
	set_player_stats(p_name, p_lvl, p_hp, p_max_hp, p_sp, p_max_sp, p_exp)
	if stat_dict.has("role_id"):
		set_player_role(int(stat_dict.role_id))

func set_player_role(role_id: int) -> void:
	if player_status_ctrl: player_status_ctrl.set_player_role(role_id)
	if character_status_ctrl: character_status_ctrl.current_role_id = role_id

func set_player_element(elem: Variant) -> void:
	if player_status_ctrl: player_status_ctrl.set_player_element(elem)
	if character_status_ctrl: character_status_ctrl.current_element = str(elem)

func update_player_element(elem: Variant) -> void:
	if player_status_ctrl: player_status_ctrl.update_player_element(elem)

func update_character_stats(c_name: String, c_lvl: int, c_elem: String, c_hp: int, c_max_hp: int, c_sp: int, c_max_sp: int, c_exp: int, c_max_exp: int, c_str: int, c_con: int, c_int: int, c_wis: int, c_agi: int, c_free: int) -> void:
	if character_status_ctrl: character_status_ctrl.update_character_stats(c_name, c_lvl, c_elem, c_hp, c_max_hp, c_sp, c_max_sp, c_exp, c_max_exp, c_str, c_con, c_int, c_wis, c_agi, c_free)

func add_inventory_item(item_id: int, count: int = 1, item_name: String = "", icon_id: int = 0, desc: String = "") -> bool:
	_ensure_sub_controllers()
	if inventory_ctrl: return inventory_ctrl.add_inventory_item(item_id, count, item_name, icon_id, desc)
	return false

func remove_inventory_item(item_id: int, count: int = 1) -> bool:
	_ensure_sub_controllers()
	if inventory_ctrl: return inventory_ctrl.remove_item_by_id(item_id, count)
	return false

func remove_item_by_id(item_id: int, count: int = 1) -> bool:
	return remove_inventory_item(item_id, count)

func set_inventory_item(slot_idx: int, icon_id: int, count: int = 1, item_id: int = 0, iname: String = "") -> void:
	_ensure_sub_controllers()
	if inventory_ctrl: inventory_ctrl.set_inventory_item(slot_idx, icon_id, count, item_id, iname)

func clear_inventory_slot(slot_idx: int) -> void:
	_ensure_sub_controllers()
	if inventory_ctrl: inventory_ctrl.clear_inventory_slot(slot_idx)

func clear_inventory() -> void:
	_ensure_sub_controllers()
	if inventory_ctrl: inventory_ctrl.clear_inventory()

func get_inventory_slot(slot_idx: int) -> Button:
	_ensure_sub_controllers()
	if inventory_ctrl: return inventory_ctrl.get_inventory_slot(slot_idx)
	return null

func get_gold() -> int:
	_ensure_sub_controllers()
	if inventory_ctrl:
		if "current_gold" in inventory_ctrl and inventory_ctrl.current_gold > 0:
			return inventory_ctrl.current_gold
		if inventory_ctrl.gold_label and inventory_ctrl.gold_label.text.is_valid_int():
			return inventory_ctrl.gold_label.text.to_int()
	return 0

func update_gold(amount: int) -> void:
	_ensure_sub_controllers()
	if inventory_ctrl:
		inventory_ctrl.update_gold(amount)
	if shop_window and shop_window.has_method("refresh_gold"):
		shop_window.refresh_gold()

func add_gold(amount: int) -> void:
	_ensure_sub_controllers()
	var cur: int = get_gold()
	update_gold(cur + amount)

func set_equipment(layers: Dictionary) -> void:
	if character_status_ctrl: character_status_ctrl.set_equipment(layers)

func set_equipment_slot(slot_name: String, item_id: int) -> void:
	if character_status_ctrl: character_status_ctrl.set_equipment_slot(slot_name, item_id)

func equip_item(slot_name: String, jma_file: String = "", jmp_file: String = "", icon_id: int = -1, iname: String = "") -> void:
	if character_status_ctrl: character_status_ctrl.equip_item(slot_name, jma_file, jmp_file, icon_id, iname)

func unequip_item(slot_name: String) -> void:
	if character_status_ctrl: character_status_ctrl.unequip_item(slot_name)

func get_equipment() -> Dictionary:
	if character_status_ctrl: return character_status_ctrl.get_equipment()
	return {}

func update_character_paper_doll(equip_dict: Dictionary = {}) -> void:
	if character_status_ctrl: character_status_ctrl.update_character_paper_doll(equip_dict)

func zoom_in_minimap() -> void:
	if minimap_ctrl: minimap_ctrl.zoom_in()

func zoom_out_minimap() -> void:
	if minimap_ctrl: minimap_ctrl.zoom_out()

func set_minimap_zoom(z: float) -> void:
	if minimap_ctrl: minimap_ctrl.set_zoom(z)

func toggle_minimap_collapse() -> void:
	if minimap_ctrl: minimap_ctrl.toggle_collapse()

func set_minimap_waypoint(norm_pos: Vector2) -> void:
	if minimap_ctrl: minimap_ctrl.set_waypoint(norm_pos)

func clear_minimap_waypoint() -> void:
	if minimap_ctrl: minimap_ctrl.clear_waypoint()

func get_minimap_content_rect() -> Rect2:
	if minimap_ctrl: return minimap_ctrl.get_content_rect()
	return Rect2(Vector2.ZERO, Vector2(212, 131))

func _on_minimap_gui_input(event: InputEvent) -> void:
	if minimap_ctrl: minimap_ctrl.on_gui_input(event)

func update_minimap(map_texture: Texture2D = null, player_norm_pos: Vector2 = Vector2(-1, -1)) -> void:
	if minimap_ctrl: minimap_ctrl.update_minimap(map_texture, player_norm_pos)

func set_map_context(p_map_id: int, p_map_name: String, p_map_size: Vector2, p_map_texture: Texture2D = null) -> void:
	if minimap_ctrl: minimap_ctrl.set_map_context(p_map_id, p_map_name, p_map_size, p_map_texture)

func set_map_info(p_map_name: String, p_coord_x: int, p_coord_y: int) -> void:
	if minimap_ctrl: minimap_ctrl.set_map_info(p_map_name, p_coord_x, p_coord_y)

func update_map_name(m_name: String) -> void:
	if minimap_ctrl: minimap_ctrl.update_map_name(m_name)

func update_coordinates(world_pos: Vector2) -> void:
	if minimap_ctrl: minimap_ctrl.update_coordinates(world_pos)
	if action_dock_ctrl:
		var m_name = map_name_label.text if map_name_label else "Ship Deck"
		action_dock_ctrl.update_location(m_name, int(world_pos.x), int(world_pos.y))

func update_location(map_name: String, x: int, y: int) -> void:
	if action_dock_ctrl: action_dock_ctrl.update_location(map_name, x, y)

func add_chat_message(sender: String, message: String, channel: String = "Local", role_id: int = 0) -> void:
	if chat_ctrl: chat_ctrl.add_chat_message(sender, message, channel, role_id)

func is_chat_box_collapsed() -> bool:
	return chat_ctrl != null and chat_ctrl.is_chat_box_collapsed()

func select_chat_tab(tab_name: String) -> void:
	if chat_ctrl: chat_ctrl.select_chat_tab(tab_name)

func toggle_chat_opacity() -> void:
	if chat_ctrl: chat_ctrl.toggle_chat_opacity()

func whisper_to_player(target_name: String, initial_msg: String = "") -> void:
	if chat_ctrl: chat_ctrl.whisper_to_player(target_name, initial_msg)

func set_chat_height(offset_top_val: float) -> void:
	if chat_ctrl:
		if chat_history_panel:
			chat_history_panel.offset_top = offset_top_val
		chat_ctrl._update_channel_tabs_position()

func set_dock_width(new_width: float) -> void:
	if chat_ctrl: chat_ctrl.set_dock_width(new_width)

var _dock_width: float:
	get: return chat_ctrl._dock_width if chat_ctrl else 524.0
	set(val):
		if chat_ctrl: chat_ctrl.set_dock_width(val)

func display_player_overhead_bubble(text_or_code: String, duration: float = 3.5) -> void:
	if chat_ctrl: chat_ctrl.display_player_overhead_bubble(text_or_code, duration)

func show_dialogue_sequence(speaker: String, pages: Array[String], portrait_index: int = 0, choices: Variant = "", choice_cb: Callable = Callable(), sfx_or_frames: Variant = "") -> void:
	var sfx: String = sfx_or_frames if sfx_or_frames is String else ""
	if dialogue_ctrl: dialogue_ctrl.show_dialogue_sequence(speaker, pages, portrait_index, choices, choice_cb, sfx)

func show_dialogue(speaker: String, text: String, portrait_tex: Texture2D = null, choices: Array = [], portrait_frames: Array = [], choice_cb: Callable = Callable(), portrait_tid: int = 0) -> void:
	if dialogue_ctrl: dialogue_ctrl.show_dialogue(speaker, text, portrait_tex, choices, portrait_tid, choice_cb, portrait_frames)

func advance_dialogue() -> void:
	if dialogue_ctrl: dialogue_ctrl.advance_dialogue()

func hide_dialogue() -> void:
	if dialogue_ctrl: dialogue_ctrl.hide_dialogue()

func is_dialogue_active() -> bool:
	return dialogue_ctrl.is_dialogue_active() if dialogue_ctrl else false

var dialogue_choices: Array:
	get:
		if dialogue_ctrl and dialogue_ctrl.choices_container:
			var res: Array = []
			for child in dialogue_ctrl.choices_container.get_children():
				if child is Button:
					res.append(child.text)
			return res
		return []

func _on_choice_clicked(choice_idx: int, choice_txt: String) -> void:
	if dialogue_ctrl and dialogue_ctrl.has_method("_on_choice_clicked"):
		dialogue_ctrl._on_choice_clicked(choice_idx, choice_txt)

func show_choices(choices: Array[String], callback: Callable = Callable()) -> void:
	if dialogue_ctrl: dialogue_ctrl.show_choices(choices, callback)

func hide_choices() -> void:
	if dialogue_ctrl: dialogue_ctrl.hide_choices()

func show_quest_reward(reward_name: String = "", count: int = 1, gold: int = 0, exp_pts: int = 0) -> void:
	if dialogue_ctrl: dialogue_ctrl.show_quest_reward(reward_name, count, gold, exp_pts)

func play_sfx(sfx_name: String) -> void:
	if dialogue_ctrl: dialogue_ctrl.play_sfx(sfx_name)

func activate_hotbar_slot(slot_index: int) -> void:
	if hotbar_ctrl: hotbar_ctrl.activate_slot(slot_index)

func set_hotbar_page(page_index: int) -> void:
	if hotbar_ctrl: hotbar_ctrl.set_page(page_index)

func get_hotbar_page() -> int:
	return hotbar_ctrl.get_current_page() if hotbar_ctrl else 0

func next_hotbar_page() -> void:
	if hotbar_ctrl: hotbar_ctrl.next_page()

func prev_hotbar_page() -> void:
	if hotbar_ctrl: hotbar_ctrl.prev_page()

func toggle_inventory() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_inventory()

func toggle_character_status() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_character_status()

func allocate_stat_point(stat_name: String) -> bool:
	if character_status_ctrl:
		return character_status_ctrl.allocate_stat_point(stat_name)
	return false

func toggle_fight_menu() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_fight_menu()

func toggle_skill_window() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_skill_window()

## Casts or activates a combat/overland skill by ID
func use_skill(skill_id: int) -> bool:
	var sname: String = "Skill %d" % skill_id
	var sp_cost: int = 10
	
	var db = null
	var gdb: Node = get_node_or_null("/root/GameDatabase") if is_inside_tree() else null
	if not gdb and Engine.get_main_loop() is SceneTree:
		var st := Engine.get_main_loop() as SceneTree
		if st and st.root:
			gdb = st.root.get_node_or_null("GameDatabase")
	if gdb and "skills" in gdb:
		db = gdb.skills
	
	if db and db.has_skill(skill_id):
		var rec = db.get_skill(skill_id)
		sname = str(rec.name)
		sp_cost = int(rec.sp_cost)
	
	var current_sp: int = 150
	var max_sp: int = 150
	var char_name: String = "Player"
	var lvl: int = 1
	var hp: int = 200
	var max_hp: int = 200
	var exp_val: Variant = 0.0
	
	if character_status_ctrl:
		current_sp = character_status_ctrl.current_sp
		max_sp = character_status_ctrl.current_max_sp
		char_name = character_status_ctrl.stat_name.text if (character_status_ctrl.stat_name and not character_status_ctrl.stat_name.text.is_empty()) else "Player"
		lvl = character_status_ctrl.current_level
		hp = character_status_ctrl.current_hp
		max_hp = character_status_ctrl.current_max_hp
		exp_val = character_status_ctrl.current_exp
	elif player_status_ctrl and "sp_bar" in player_status_ctrl and player_status_ctrl.sp_bar:
		current_sp = int(player_status_ctrl.sp_bar.value)
		max_sp = int(player_status_ctrl.sp_bar.max_value)
	
	if current_sp < sp_cost:
		AuthAudio.play_error()
		add_chat_message("System", "Not enough SP to cast %s! (Need %d SP, have %d SP)" % [sname, sp_cost, current_sp], "System")
		show_center_notification("Not enough SP! (%d / %d)" % [current_sp, sp_cost])
		return false
	
	# Deduct SP
	current_sp -= sp_cost
	if character_status_ctrl:
		character_status_ctrl.current_sp = current_sp
		if character_status_ctrl.stat_left_sp:
			character_status_ctrl.stat_left_sp.text = "%d / %d" % [current_sp, max_sp]
	
	set_player_stats(char_name, lvl, hp, max_hp, current_sp, max_sp, exp_val)
	AuthAudio.play_click()
	add_chat_message("System", "Cast %s! (-%d SP, Remaining SP: %d)" % [sname, sp_cost, current_sp], "System")
	show_center_notification("Cast: %s (-%d SP)" % [sname, sp_cost])
	
	# Trigger speech bubble if player exists
	var tree := get_tree()
	if tree:
		var p = tree.root.find_child("Player", true, false)
		if p and p.has_method("show_speech_bubble"):
			p.show_speech_bubble(sname, 2.0)
	
	return true

func toggle_team_window() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_team_window()

func get_team_window() -> Control:
	return get_node_or_null("FloatingWindows/TeamWindow") as Control

## The Notepad item opens the Notebook (Quest Log / Monster Book / Star Book).
var notebook_window: Control = null

func open_notebook() -> void:
	if notebook_window == null or not is_instance_valid(notebook_window):
		notebook_window = NotebookWindowScript.new()
		add_child(notebook_window)
		notebook_window.quest_log_requested.connect(func() -> void:
			if window_manager_ctrl and not window_manager_ctrl.quest_window.visible:
				window_manager_ctrl.toggle_quest_window())
	notebook_window.open_menu()

func register_monster_seen(template_id: int, monster_name: String) -> void:
	if notebook_window == null or not is_instance_valid(notebook_window):
		notebook_window = NotebookWindowScript.new()
		add_child(notebook_window)
		notebook_window.quest_log_requested.connect(func() -> void:
			if window_manager_ctrl and not window_manager_ctrl.quest_window.visible:
				window_manager_ctrl.toggle_quest_window())
	notebook_window.register_monster(template_id, monster_name)

func toggle_quest_window() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_quest_window()

func toggle_friends_window() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_friends_window()

func toggle_system_window() -> void:
	if window_manager_ctrl: window_manager_ctrl.toggle_system_window()

func _on_window_manager_logout_requested() -> void:
	logout_requested.emit()

func toggle_compound_window() -> void:
	if not compound_window:
		var scene = load("res://scenes/ui/hud/compound_window.tscn")
		if scene and floating_windows:
			compound_window = scene.instantiate()
			compound_window.visible = false
			floating_windows.add_child(compound_window)
			if compound_window.has_method("setup"):
				compound_window.setup(self)
	if compound_window:
		if compound_window.has_method("toggle_window"):
			compound_window.toggle_window()
		else:
			compound_window.visible = not compound_window.visible
		if compound_window.visible and compound_window.has_method("refresh_inventory_from_hud"):
			compound_window.refresh_inventory_from_hud()

func get_or_create_shop_window() -> Control:
	_ensure_sub_controllers()
	if not shop_window:
		if has_node("FloatingWindows/ShopWindow"):
			shop_window = get_node("FloatingWindows/ShopWindow") as Control
		else:
			var scene = load("res://scenes/ui/shop/shop_window.tscn")
			if scene and floating_windows:
				shop_window = scene.instantiate()
				shop_window.name = "ShopWindow"
				shop_window.visible = false
				floating_windows.add_child(shop_window)
			elif not shop_window and floating_windows:
				var sw_script = load("res://scripts/ui/shop/shop_window.gd")
				if sw_script:
					shop_window = sw_script.new()
					shop_window.name = "ShopWindow"
					shop_window.visible = false
					floating_windows.add_child(shop_window)
	if shop_window and shop_window.has_method("setup"):
		shop_window.setup(self)
	return shop_window

func open_shop(p_merchant_id: int = 0, p_merchant_name: String = "", catalog: Array = []) -> void:
	var win = get_or_create_shop_window()
	if win and win.has_method("open_shop"):
		win.open_shop(p_merchant_id, p_merchant_name, catalog)

func toggle_shop_window() -> void:
	var win = get_or_create_shop_window()
	if win:
		if win.visible:
			if win.has_method("close_shop"):
				win.close_shop()
			else:
				win.visible = false
		else:
			if win.has_method("open_shop"):
				win.open_shop(0, "Grocery Store")
			else:
				win.visible = true

func toggle_minimap() -> void:
	if minimap_ctrl: minimap_ctrl.toggle_collapse()

func is_mouse_over_ui() -> bool:
	if window_manager_ctrl and window_manager_ctrl.is_mouse_over_window():
		return true
	var mpos := get_viewport().get_mouse_position()
	if status_dock and Rect2(status_dock.global_position, status_dock.size).has_point(mpos):
		return true
	if minimap_dock and Rect2(minimap_dock.global_position, minimap_dock.size).has_point(mpos):
		return true
	if action_dock and Rect2(action_dock.global_position, action_dock.size).has_point(mpos):
		return true
	if hotbar_dock and Rect2(hotbar_dock.global_position, hotbar_dock.size).has_point(mpos):
		return true
	if dialogue_dock and dialogue_dock.visible and Rect2(dialogue_dock.global_position, dialogue_dock.size).has_point(mpos):
		return true
	if branching_dock and branching_dock.visible and Rect2(branching_dock.global_position, branching_dock.size).has_point(mpos):
		return true
	if chat_dock and Rect2(chat_dock.global_position, chat_dock.size).has_point(mpos):
		return true
	return false

var _banner_panel: Control = null
var _center_notif_panel: Control = null

## Displays a prominent, centered on-screen notification badge confirming item pickup or achievement
func show_center_notification(text: String, icon_id: int = 0, duration: float = 2.4) -> void:
	banner_emitted.emit(text)
	
	if is_instance_valid(_center_notif_panel):
		_center_notif_panel.queue_free()
		_center_notif_panel = null
	
	var panel := PanelContainer.new()
	panel.name = "CenterNotificationToast"
	panel.z_index = 60
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Responsive horizontal centering at screen middle
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.42
	panel.anchor_bottom = 0.42
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Stylish dark theme with gold border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.13, 0.88)
	style.border_color = Color(0.85, 0.72, 0.35, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Authentic Item Icon if icon_id provided
	if icon_id > 0 and is_inside_tree() and get_tree() and get_tree().root:
		var loader = get_tree().root.get_node_or_null("ArchiveLoader")
		if loader and loader.has_method("get_item_icon"):
			var icon_tex: ImageTexture = loader.get_item_icon(icon_id)
			if icon_tex:
				var trect := TextureRect.new()
				trect.texture = icon_tex
				trect.custom_minimum_size = Vector2(28, 28)
				trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				hbox.add_child(trect)
	
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	hbox.add_child(label)
	
	add_child(panel)
	_center_notif_panel = panel
	_banner_panel = panel
	
	# Smooth rise and fade animation
	panel.modulate.a = 0.0
	panel.position.y += 15.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(panel, "position:y", panel.position.y - 15.0, 0.2).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration)
	tw.tween_property(panel, "position:y", panel.position.y - 35.0, 0.4).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(panel, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tw.finished.connect(func():
		if _center_notif_panel == panel:
			_center_notif_panel = null
		if _banner_panel == panel:
			_banner_panel = null
		if is_instance_valid(panel):
			panel.queue_free()
	)

func show_banner(text: String, duration: float = 3.0) -> void:
	show_center_notification(text, 0, duration)

## Updates the quest log in QuestWindow
func update_quest_log(quests: Array) -> void:
	if window_manager_ctrl and window_manager_ctrl.has_method("update_quest_log"):
		window_manager_ctrl.update_quest_log(quests)

func _on_send_pressed() -> void:
	if chat_ctrl: chat_ctrl.on_send_pressed()

func on_inventory_slot_right_clicked(slot_idx: int) -> void:
	if inventory_ctrl: inventory_ctrl.on_inventory_slot_right_clicked(slot_idx)

func on_inventory_slot_double_clicked(slot_idx: int) -> void:
	if inventory_ctrl: inventory_ctrl.on_inventory_slot_double_clicked(slot_idx)

func get_inventory_drag_data(slot_idx: int) -> Variant:
	if inventory_ctrl: return inventory_ctrl.get_inventory_drag_data(slot_idx)
	return null

func can_drop_on_inventory_slot(target_slot: int, data: Variant) -> bool:
	if inventory_ctrl: return inventory_ctrl.can_drop_on_inventory_slot(target_slot, data)
	return false

func drop_on_inventory_slot(target_slot: int, data: Variant) -> void:
	if inventory_ctrl: inventory_ctrl.drop_on_inventory_slot(target_slot, data)

func get_equipment_drag_data(socket_name: String) -> Variant:
	if character_status_ctrl: return character_status_ctrl.get_equipment_drag_data(socket_name)
	return null

func can_drop_on_equipment_socket(target_socket: String, data: Variant) -> bool:
	if character_status_ctrl: return character_status_ctrl.can_drop_on_equipment_socket(target_socket, data)
	return false

func drop_on_equipment_socket(target_socket: String, data: Variant) -> void:
	if character_status_ctrl: character_status_ctrl.drop_on_equipment_socket(target_socket, data)

func on_equipment_socket_clicked(socket_name: String) -> void:
	if character_status_ctrl: character_status_ctrl.on_equipment_socket_clicked(socket_name)

func show_inventory_item_tooltip(slot_idx: int, slot_global_pos: Vector2, slot_size: Vector2) -> void:
	if inventory_ctrl: inventory_ctrl.show_inventory_item_tooltip(slot_idx, slot_global_pos, slot_size)

func show_equipment_item_tooltip(socket_name: String, socket_global_pos: Vector2, socket_size: Vector2) -> void:
	if character_status_ctrl: character_status_ctrl.show_equipment_item_tooltip(socket_name, socket_global_pos, socket_size)

func hide_item_tooltip() -> void:
	if _item_tooltip: _item_tooltip.visible = false
