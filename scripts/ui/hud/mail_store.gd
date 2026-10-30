class_name MailStore
extends RefCounted

## Offline mailbox persistence shared by MailBoxWindow and MailSendWindow.
## The original client keeps two local files per server/character:
##   user\Server<N>\MailBoxMsgLog<id>\MailData.dat   -> "Mail Inbox" tab (Btn_MailBoxTab_1)
##   user\Server<N>\MailBoxMsgLog<id>\BKMailData.dat -> "Backup" tab   (Btn_MailBoxTab_2)
## (strings referenced by 0x1ec510 load / 0x1ed7bc save). Records there are 0xB9 (185) bytes:
## +0x168 type byte, +0x169 read flag, +0x16e sender name (shortstring), +0x180 content (shortstring)
## relative to the form's record array (offsets as used by the paint routine 0x1eb3a0).
## Here everything goes to one JSON file instead.

signal changed

const DEFAULT_PATH: String = "user://mailbox.json"
const FOLDER_INBOX: String = "inbox"
const FOLDER_BACKUP: String = "backup"
const CAPACITY: int = 1000 ## paint rejects record index > 0x3E8
const WARN_COUNT: int = 900 ## page counter turns red (0xF800) above 0x384

## Type byte -> label (switch at 0x1eb725). 1..4 named, anything else "Normal ".
const TYPE_NAMES: Dictionary = {1: "Friends", 2: "Guild", 3: "System", 4: "Pet"}
const TYPE_NORMAL: int = 0

var path: String = DEFAULT_PATH
var _folders: Dictionary = {FOLDER_INBOX: [], FOLDER_BACKUP: []}
var _next_id: int = 1


func _init(p_path: String = DEFAULT_PATH) -> void:
	path = p_path
	load_from_disk()


static func type_name(type_id: int) -> String:
	return TYPE_NAMES.get(type_id, "Normal ")


func get_mails(folder: String) -> Array:
	return _folders.get(folder, [])


func count(folder: String) -> int:
	return get_mails(folder).size()


func unread_count(folder: String = FOLDER_INBOX) -> int:
	var n := 0
	for m in get_mails(folder):
		if not bool(m.get("read", false)):
			n += 1
	return n


## Adds a mail; returns the stored record (or {} when the folder is full).
func add_mail(folder: String, name: String, content: String, type_id: int = TYPE_NORMAL, time_unix: int = -1, read: bool = false) -> Dictionary:
	if not _folders.has(folder):
		_folders[folder] = []
	var arr: Array = _folders[folder]
	if arr.size() >= CAPACITY:
		return {}
	var rec := {
		"id": _next_id, "type": type_id, "read": read, "name": name, "content": content,
		"time": time_unix if time_unix >= 0 else int(Time.get_unix_time_from_system()),
	}
	_next_id += 1
	arr.push_front(rec) # newest first
	save_to_disk()
	changed.emit()
	return rec


func find(folder: String, mail_id: int) -> Dictionary:
	for m in get_mails(folder):
		if int(m.id) == mail_id:
			return m
	return {}


func mark_read(folder: String, mail_id: int) -> void:
	var m := find(folder, mail_id)
	if not m.is_empty() and not bool(m.read):
		m.read = true
		save_to_disk()
		changed.emit()


func delete_mail(folder: String, mail_id: int) -> bool:
	var arr: Array = get_mails(folder)
	for i in arr.size():
		if int(arr[i].id) == mail_id:
			arr.remove_at(i)
			save_to_disk()
			changed.emit()
			return true
	return false


func clear() -> void:
	_folders = {FOLDER_INBOX: [], FOLDER_BACKUP: []}
	_next_id = 1
	save_to_disk()
	changed.emit()


func save_to_disk() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"next_id": _next_id, "folders": _folders}, "\t"))


func load_from_disk() -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return
	_next_id = int(parsed.get("next_id", 1))
	var folders = parsed.get("folders", {})
	if folders is Dictionary:
		for key in folders.keys():
			var list: Array = []
			for m in folders[key]:
				if m is Dictionary:
					m["id"] = int(m.get("id", 0))
					m["type"] = int(m.get("type", 0))
					m["time"] = int(m.get("time", 0))
					m["read"] = bool(m.get("read", false))
					list.append(m)
			_folders[key] = list
