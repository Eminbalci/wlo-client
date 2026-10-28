class_name ServerSelect
extends Control

## Authentic Server Selection Screen for Wonderland Online (1:1 with ref_zir2b and ref_HRtuk).
## Features:
## - 309x352 centered Form_ServerList_1.jpg
## - Left column: Server groups (e.g. "Local Server")
## - Right column: Subservers / channels with ping indicator lights
## - Next & Leave buttons

signal channel_selected(server_entry)
signal leave_requested()
signal exit_requested()

const ServerConfig = preload("res://scripts/network/server_config.gd")
const AuthAudio = preload("res://scripts/ui/auth/auth_audio.gd")

const FORM_SERVER_PATH: String = "res://assets/auth/form_server_list.jpg"
const BTN_NEXT_NORM: String = "res://assets/auth/btn_next_normal.png"
const BTN_NEXT_HOV: String = "res://assets/auth/btn_next_hover.png"
const BTN_NEXT_PRESS: String = "res://assets/auth/btn_next_pressed.png"
const BTN_LEAVE_NORM: String = "res://assets/auth/btn_leave_normal.png"
const BTN_LEAVE_HOV: String = "res://assets/auth/btn_leave_hover.png"
const BTN_LEAVE_PRESS: String = "res://assets/auth/btn_leave_pressed.png"

enum ViewMode {
	MAIN_SERVERS = 0,
	CHANNELS = 1
}

@export var ini_path: String = "res://assets/SERVER.INI"

@onready var card_window: Control = $CardWindow
@onready var card_bg: TextureRect = $CardWindow/CardBg
@onready var main_server_list: ItemList = $CardWindow/MainServerList
@onready var channel_list: ItemList = $CardWindow/ChannelList
@onready var btn_next: TextureButton = $CardWindow/BtnNext
@onready var btn_leave: TextureButton = $CardWindow/BtnLeave

# Backward compatibility accessors
var main_server_window: Control:
	get: return card_window
var channel_window: Control:
	get: return channel_list
var btn_main_login: TextureButton:
	get: return btn_next
var btn_channel_ok: TextureButton:
	get: return btn_next
var btn_main_cancel: TextureButton:
	get: return btn_leave
var btn_channel_prev: TextureButton:
	get: return btn_leave
var btn_ok: TextureButton:
	get: return btn_next
var btn_cancel: TextureButton:
	get: return btn_leave
var region_tabs: ItemList:
	get: return main_server_list
var server_items: ItemList:
	get: return main_server_list
var channel_buttons: ItemList:
	get: return channel_list

var config: ServerConfig
var current_group: ServerConfig.ServerGroup
var selected_server_entry: ServerConfig.ServerEntry
var _signal_textures: Array[Texture2D] = []
var _current_mode: ViewMode = ViewMode.MAIN_SERVERS

func _ready() -> void:
	_load_textures()
	_setup_signals()
	_load_server_config()
	show_main_servers()

func _load_textures() -> void:
	# Load ping lights
	for i in range(4):
		var p := "res://assets/auth/icon_signal_%d.png" % i
		if ResourceLoader.exists(p):
			_signal_textures.append(load(p))

	if btn_next:
		if ResourceLoader.exists(BTN_NEXT_NORM): btn_next.texture_normal = load(BTN_NEXT_NORM)
		if ResourceLoader.exists(BTN_NEXT_HOV): btn_next.texture_hover = load(BTN_NEXT_HOV)
		if ResourceLoader.exists(BTN_NEXT_PRESS): btn_next.texture_pressed = load(BTN_NEXT_PRESS)
	if btn_leave:
		if ResourceLoader.exists(BTN_LEAVE_NORM): btn_leave.texture_normal = load(BTN_LEAVE_NORM)
		if ResourceLoader.exists(BTN_LEAVE_HOV): btn_leave.texture_hover = load(BTN_LEAVE_HOV)
		if ResourceLoader.exists(BTN_LEAVE_PRESS): btn_leave.texture_pressed = load(BTN_LEAVE_PRESS)

func _setup_signals() -> void:
	if btn_next and not btn_next.pressed.is_connected(_on_next_pressed):
		btn_next.pressed.connect(_on_next_pressed)
	if btn_leave and not btn_leave.pressed.is_connected(_on_leave_pressed):
		btn_leave.pressed.connect(_on_leave_pressed)

	if main_server_list:
		main_server_list.item_activated.connect(func(_idx: int): _on_group_activated())
		main_server_list.item_selected.connect(func(idx: int): _on_group_selected(idx))
	if channel_list:
		channel_list.item_activated.connect(func(_idx: int): _on_channel_activated())
		channel_list.item_selected.connect(func(idx: int): _on_channel_selected_index(idx))

func _load_server_config() -> void:
	config = ServerConfig.load_from_ini(ini_path)

func show_main_servers() -> void:
	_current_mode = ViewMode.MAIN_SERVERS
	if channel_list:
		channel_list.visible = false
		channel_list.clear()

	if not main_server_list:
		return

	main_server_list.clear()
	if not config or config.groups.is_empty():
		main_server_list.add_item("Local Server")
	else:
		for grp in config.groups:
			main_server_list.add_item(grp.title)

	if main_server_list.item_count > 0:
		main_server_list.select(0)
		_on_group_selected(0)

func show_sub_servers(group: Dictionary) -> void:
	# Compatibility wrapper taking Dictionary
	var s_group := ServerConfig.ServerGroup.new(group.get("id", ""), group.get("title", ""), group.get("flags", ""))
	if group.has("servers"):
		for s in group["servers"]:
			if s is ServerConfig.ServerEntry:
				s_group.servers.append(s)
	show_channels(s_group)

func show_channels(group: ServerConfig.ServerGroup) -> void:
	_current_mode = ViewMode.CHANNELS
	current_group = group
	if channel_list:
		channel_list.visible = true
		channel_list.clear()

	if not group or group.servers.is_empty():
		if channel_list:
			var sig: Texture2D = _signal_textures[1] if not _signal_textures.is_empty() else null
			channel_list.add_item("Local", sig)
		return

	if channel_list:
		for i in range(group.servers.size()):
			var s := group.servers[i]
			var sig: Texture2D = null
			if not _signal_textures.is_empty():
				# 1 = Green, 2 = Yellow, 3 = Red
				sig = _signal_textures[1 if i == 0 else 1]
			channel_list.add_item(s.name, sig)

		if channel_list.item_count > 0:
			channel_list.select(0)
			_on_channel_selected_index(0)

func _on_group_selected(idx: int) -> void:
	AuthAudio.play_click()
	if config and idx < config.groups.size():
		current_group = config.groups[idx]
	else:
		current_group = null

func _on_group_activated() -> void:
	if current_group:
		show_channels(current_group)
	elif config and not config.servers.is_empty():
		var fake_grp := ServerConfig.ServerGroup.new("01", "Local Server", "1")
		fake_grp.servers.append_array(config.servers)
		show_channels(fake_grp)

func _on_channel_selected_index(idx: int) -> void:
	AuthAudio.play_click()
	if current_group and idx < current_group.servers.size():
		selected_server_entry = current_group.servers[idx]
	elif config and idx < config.servers.size():
		selected_server_entry = config.servers[idx]
	elif config and not config.servers.is_empty():
		selected_server_entry = config.servers[0]
	else:
		selected_server_entry = ServerConfig.ServerEntry.new("Local", "127.0.0.1", 6414)

func _on_channel_activated() -> void:
	_confirm_channel()

func _on_next_pressed() -> void:
	AuthAudio.play_click()
	if _current_mode == ViewMode.MAIN_SERVERS:
		_on_group_activated()
	else:
		_confirm_channel()

func _on_channel_ok_pressed() -> void:
	AuthAudio.play_click()
	_confirm_channel()

func _on_main_login_pressed() -> void:
	_on_next_pressed()

func _confirm_channel() -> void:
	if not selected_server_entry:
		if current_group and not current_group.servers.is_empty():
			selected_server_entry = current_group.servers[0]
		elif config and not config.servers.is_empty():
			selected_server_entry = config.servers[0]
		else:
			selected_server_entry = ServerConfig.ServerEntry.new("Local", "127.0.0.1", 6414)

	channel_selected.emit(selected_server_entry)

func _on_leave_pressed() -> void:
	AuthAudio.play_click()
	leave_requested.emit()
	exit_requested.emit()
	if _current_mode == ViewMode.CHANNELS:
		show_main_servers()

func _on_main_cancel_pressed() -> void:
	_on_leave_pressed()

func _on_channel_prev_pressed() -> void:
	show_main_servers()

func get_selected_server() -> ServerConfig.ServerEntry:
	return selected_server_entry

func get_current_mode() -> ViewMode:
	return _current_mode


