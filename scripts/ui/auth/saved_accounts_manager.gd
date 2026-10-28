class_name SavedAccountsManager
extends RefCounted

## Manages persistent saved accounts for the Wonderland Online client.
## Stored in user://saved_accounts.json.

const STORAGE_PATH: String = "user://saved_accounts.json"

static func get_saved_accounts() -> Array[String]:
	if not FileAccess.file_exists(STORAGE_PATH):
		return []

	var file := FileAccess.open(STORAGE_PATH, FileAccess.READ)
	if not file:
		return []

	var text := file.get_as_text()
	var json := JSON.new()
	var parse_err := json.parse(text)
	if parse_err != OK:
		return []

	var data = json.data
	var result: Array[String] = []
	if data is Dictionary and data.has("accounts") and data["accounts"] is Array:
		for item in data["accounts"]:
			if item is String and not (item as String).is_empty():
				result.append(item as String)
	elif data is Array:
		for item in data:
			if item is String and not (item as String).is_empty():
				result.append(item as String)

	return result

static func save_account(account_name: String) -> void:
	var trimmed := account_name.strip_edges()
	if trimmed.is_empty():
		return

	var accounts := get_saved_accounts()
	if not accounts.has(trimmed):
		accounts.append(trimmed)

	var payload: Dictionary = {
		"last_used": trimmed,
		"accounts": accounts
	}

	var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

static func remove_account(account_name: String) -> void:
	var trimmed := account_name.strip_edges()
	var accounts := get_saved_accounts()
	if accounts.has(trimmed):
		accounts.erase(trimmed)

	var last_used := get_last_used_account()
	if last_used == trimmed:
		last_used = accounts[0] if not accounts.is_empty() else ""

	var payload: Dictionary = {
		"last_used": last_used,
		"accounts": accounts
	}

	var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))

static func get_last_used_account() -> String:
	if not FileAccess.file_exists(STORAGE_PATH):
		return ""

	var file := FileAccess.open(STORAGE_PATH, FileAccess.READ)
	if not file:
		return ""

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return ""

	var data = json.data
	if data is Dictionary and data.has("last_used") and data["last_used"] is String:
		return data["last_used"] as String

	var accounts := get_saved_accounts()
	return accounts[0] if not accounts.is_empty() else ""

static func get_last_account() -> String:
	return get_last_used_account()

static func set_last_used_account(account_name: String) -> void:
	var trimmed := account_name.strip_edges()
	var accounts := get_saved_accounts()
	var payload: Dictionary = {
		"last_used": trimmed,
		"accounts": accounts
	}
	var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))
