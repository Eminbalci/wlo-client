class_name LoginDialog
extends Control

## Authentic Login Dialog for Wonderland Online (1:1 with ref_4oCL and ref_PvYEm).
## Features:
## - Centered form card (form_login_card.png)
## - account & password text fields
## - Triangle button revealing dropdown of saved accounts
## - Save Account checkbox
## - 4 authentic large buttons: Login, Previous, Sign Up, About Wonderland Online

signal login_requested(account: String, password: String, save: bool)
signal back_requested()
signal login_submitted(account: String, password: String, save_account: bool)
signal prev_pressed()
signal sign_up_pressed()
signal about_pressed()
signal virtual_keyboard_toggled()

const SavedAccountsManager = preload("res://scripts/ui/auth/saved_accounts_manager.gd")
const ServerConfig = preload("res://scripts/network/server_config.gd")
const AuthAudio = preload("res://scripts/ui/auth/auth_audio.gd")

@onready var card_window: Control = $CardWindow
@onready var card_bg: TextureRect = $CardWindow/CardBg
@onready var account_input: LineEdit = $CardWindow/AccountInput
@onready var password_input: LineEdit = $CardWindow/PasswordInput
@onready var btn_saved_accounts: TextureButton = $CardWindow/BtnSavedAccounts
@onready var save_account_checkbox: CheckBox = $CardWindow/SaveAccountCheckbox
@onready var btn_virtual_keyboard: TextureButton = $CardWindow/BtnVirtualKeyboard if has_node("CardWindow/BtnVirtualKeyboard") else null
@onready var btn_login: TextureButton = $CardWindow/BtnLogin
@onready var btn_prev: TextureButton = $CardWindow/BtnPrev
@onready var btn_sign_up: TextureButton = $CardWindow/BtnSignUp
@onready var btn_about: TextureButton = $CardWindow/BtnAbout
@onready var saved_accounts_popup: Control = $CardWindow/SavedAccountsPopup
@onready var saved_accounts_list: ItemList = $CardWindow/SavedAccountsPopup/SavedAccountsList
var server_label: Label:
	get:
		if not _server_label_inst:
			_server_label_inst = get_node_or_null("CardWindow/ServerLabel") as Label
			if not _server_label_inst:
				_server_label_inst = Label.new()
				_server_label_inst.name = "ServerLabel"
				if has_node("CardWindow"):
					$CardWindow.add_child(_server_label_inst)
				else:
					add_child(_server_label_inst)
		return _server_label_inst
var _server_label_inst: Label = null

# Backward compatibility accessors for test suites
var username_input: LineEdit:
	get: return account_input
var saved_popup: Control:
	get: return saved_accounts_popup
var saved_list: ItemList:
	get: return saved_accounts_list
var save_account_check: CheckBox:
	get: return save_account_checkbox
var triangle_button: TextureButton:
	get: return btn_saved_accounts
var login_button: TextureButton:
	get: return btn_login
var cancel_button: TextureButton:
	get: return btn_prev
var remember_account_check: CheckBox:
	get: return save_account_checkbox
var remember_button: CheckBox:
	get: return save_account_checkbox
var virtual_keyboard_button: TextureButton:
	get: return btn_virtual_keyboard

var current_server: ServerConfig.ServerEntry

func _ready() -> void:
	_setup_signals()
	_populate_initial_account()

func _setup_signals() -> void:
	if btn_login and not btn_login.pressed.is_connected(_on_login_pressed):
		btn_login.pressed.connect(_on_login_pressed)
	if btn_prev and not btn_prev.pressed.is_connected(_on_prev_pressed):
		btn_prev.pressed.connect(_on_prev_pressed)
	if btn_sign_up and not btn_sign_up.pressed.is_connected(_on_signup_pressed):
		btn_sign_up.pressed.connect(_on_signup_pressed)
	if btn_about and not btn_about.pressed.is_connected(_on_about_pressed):
		btn_about.pressed.connect(_on_about_pressed)
	if btn_virtual_keyboard and not btn_virtual_keyboard.pressed.is_connected(_on_virtual_keyboard_pressed):
		btn_virtual_keyboard.pressed.connect(_on_virtual_keyboard_pressed)

	if btn_saved_accounts and not btn_saved_accounts.pressed.is_connected(_toggle_saved_accounts_popup):
		btn_saved_accounts.pressed.connect(_toggle_saved_accounts_popup)

	if saved_accounts_list:
		if not saved_accounts_list.item_selected.is_connected(_on_saved_account_selected):
			saved_accounts_list.item_selected.connect(_on_saved_account_selected)
		if not saved_accounts_list.item_activated.is_connected(_on_saved_account_selected):
			saved_accounts_list.item_activated.connect(_on_saved_account_selected)

	if account_input:
		account_input.text_submitted.connect(func(_t: String):
			if password_input: password_input.grab_focus()
		)
	if password_input:
		password_input.text_submitted.connect(func(_t: String):
			_on_login_pressed()
		)

func _populate_initial_account() -> void:
	var last_acc: String = SavedAccountsManager.get_last_used_account()
	if not last_acc.is_empty() and account_input:
		account_input.text = last_acc
		if save_account_checkbox:
			save_account_checkbox.button_pressed = true

func set_server_info(group_name: String, subserver_name: String = "", channel_name: String = "") -> void:
	if server_label:
		server_label.text = group_name
	elif has_node("CardWindow/ServerLabel"):
		var lbl = get_node("CardWindow/ServerLabel") as Label
		if lbl:
			lbl.text = group_name
	pass

func _on_triangle_pressed() -> void:
	_toggle_saved_accounts_popup()

func _on_saved_account_activated(idx: int) -> void:
	_on_saved_account_selected(idx)

func set_server_info_entry(server: ServerConfig.ServerEntry) -> void:
	current_server = server

func _toggle_saved_accounts_popup() -> void:
	if not saved_accounts_popup:
		return
	if saved_accounts_popup.visible:
		saved_accounts_popup.visible = false
	else:
		_open_saved_accounts_popup()

func _open_saved_accounts_popup() -> void:
	if not saved_accounts_list or not saved_accounts_popup:
		return

	saved_accounts_list.clear()
	var accounts: Array[String] = SavedAccountsManager.get_saved_accounts()
	if accounts.is_empty():
		saved_accounts_list.add_item("(No saved accounts)")
	else:
		for acc in accounts:
			saved_accounts_list.add_item(acc)

	saved_accounts_popup.visible = true

func _on_saved_account_selected(idx: int) -> void:
	if saved_accounts_list and idx >= 0 and idx < saved_accounts_list.item_count:
		var item_txt := saved_accounts_list.get_item_text(idx)
		if not item_txt.begins_with("("):
			if account_input:
				account_input.text = item_txt
			if password_input:
				password_input.grab_focus()
	if saved_accounts_popup:
		saved_accounts_popup.visible = false

func _on_login_pressed() -> void:
	AuthAudio.play_click()
	var acc: String = account_input.text.strip_edges() if account_input else ""
	var pwd: String = password_input.text if password_input else ""
	var save_checked: bool = save_account_checkbox.button_pressed if save_account_checkbox else false

	if acc.is_empty():
		acc = "default"

	if save_checked:
		SavedAccountsManager.save_account(acc)

	login_submitted.emit(acc, pwd, save_checked)
	login_requested.emit(acc, pwd, save_checked)

func _on_prev_pressed() -> void:
	AuthAudio.play_click()
	if saved_accounts_popup:
		saved_accounts_popup.visible = false
	prev_pressed.emit()
	back_requested.emit()

func _on_signup_pressed() -> void:
	AuthAudio.play_click()
	sign_up_pressed.emit()

func _on_about_pressed() -> void:
	AuthAudio.play_click()
	about_pressed.emit()

func _on_virtual_keyboard_pressed() -> void:
	AuthAudio.play_click()
	virtual_keyboard_toggled.emit()

func is_save_account_checked() -> bool:
	return save_account_checkbox.button_pressed if save_account_checkbox else false

func get_account_name() -> String:
	return account_input.text.strip_edges() if account_input else ""

var status_label: Label:
	get:
		if not _status_label_inst:
			_status_label_inst = get_node_or_null("CardWindow/StatusLabel") as Label
			if not _status_label_inst:
				_status_label_inst = Label.new()
				_status_label_inst.name = "StatusLabel"
				_status_label_inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				_status_label_inst.add_theme_font_size_override("font_size", 11)
				_status_label_inst.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0))
				if has_node("CardWindow"):
					$CardWindow.add_child(_status_label_inst)
					_status_label_inst.position = Vector2(20, 186)
					_status_label_inst.size = Vector2(269, 16)
				else:
					add_child(_status_label_inst)
		return _status_label_inst
var _status_label_inst: Label = null

func set_status(text: String) -> void:
	if status_label:
		status_label.text = text
	print("[LoginDialog] Status: ", text)

func get_username() -> String:
	return get_account_name()

func get_password() -> String:
	return password_input.text if password_input else ""

