class_name ServerConfig
extends RefCounted

## Parses server connection endpoints from SERVER.INI.
## Supports group headers (e.g. "01[Local Server]1") and server entries ("Local*127.0.0.1" or "Name*Host:Port").
## Default game port is 6414 (standard Wonderland Online game server port).

const DEFAULT_GAME_PORT: int = 6414
const DEFAULT_INI_PATH: String = "res://assets/SERVER.INI"

class ServerEntry:
	var name: String
	var host: String
	var port: int
	var group_title: String
	var group_id: String

	func _init(p_name: String, p_host: String, p_port: int = DEFAULT_GAME_PORT, p_group_title: String = "", p_group_id: String = "") -> void:
		name = p_name
		host = p_host
		port = p_port
		group_title = p_group_title
		group_id = p_group_id

	func get_endpoint_string() -> String:
		return "%s:%d" % [host, port]

	func _to_string() -> String:
		return "[%s] %s (%s:%d)" % [group_title if not group_title.is_empty() else "Default", name, host, port]

class ServerGroup:
	var id: String
	var title: String
	var flags: String
	var servers: Array[ServerEntry] = []

	func _init(p_id: String = "", p_title: String = "", p_flags: String = "") -> void:
		id = p_id
		title = p_title
		flags = p_flags

var groups: Array[ServerGroup] = []
var servers: Array[ServerEntry] = []

## Loads and parses SERVER.INI from a given file path.
static func load_from_ini(file_path: String = DEFAULT_INI_PATH) -> ServerConfig:
	return load_from_file(file_path)

static func load_from_file(file_path: String = DEFAULT_INI_PATH) -> ServerConfig:
	var config := ServerConfig.new()
	if not FileAccess.file_exists(file_path):
		# Fallback to local default endpoint
		var default_group := ServerGroup.new("01", "Local Server", "1")
		var default_entry := ServerEntry.new("Local", "127.0.0.1", DEFAULT_GAME_PORT, "Local Server", "01")
		default_group.servers.append(default_entry)
		config.groups.append(default_group)
		config.servers.append(default_entry)
		return config

	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[ServerConfig] Could not open file: %s" % file_path)
		return config

	var current_group: ServerGroup = null

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("//") or line.begins_with("#") or line.begins_with(";"):
			continue

		# Group header pattern: e.g. 01[Local Server]1 or [Local Server]
		if line.contains("[") and line.contains("]"):
			var open_bracket := line.find("[")
			var close_bracket := line.find("]")
			var group_id := line.substr(0, open_bracket).strip_edges()
			var group_title := line.substr(open_bracket + 1, close_bracket - open_bracket - 1).strip_edges()
			var group_flags := line.substr(close_bracket + 1).strip_edges()

			current_group = ServerGroup.new(group_id, group_title, group_flags)
			config.groups.append(current_group)
			continue

		# Server entry pattern: e.g. Local*127.0.0.1 or peuloom*187.77.49.75:6414
		if line.contains("*"):
			var parts := line.split("*", false, 2)
			if parts.size() >= 2:
				var s_name := parts[0].strip_edges()
				var s_host := parts[1].strip_edges()
				var s_port := DEFAULT_GAME_PORT

				if s_host.contains(":"):
					var host_parts := s_host.split(":")
					s_host = host_parts[0].strip_edges()
					if host_parts.size() > 1 and host_parts[1].is_valid_int():
						s_port = host_parts[1].to_int()

				var g_title := current_group.title if current_group else ""
				var g_id := current_group.id if current_group else ""

				var entry := ServerEntry.new(s_name, s_host, s_port, g_title, g_id)
				config.servers.append(entry)
				if current_group:
					current_group.servers.append(entry)

	# Fallback if no valid server entries found
	if config.servers.is_empty():
		var fallback_entry := ServerEntry.new("Local", "127.0.0.1", DEFAULT_GAME_PORT, "Local Server", "01")
		var fallback_group := ServerGroup.new("01", "Local Server", "1")
		fallback_group.servers.append(fallback_entry)
		config.groups.append(fallback_group)
		config.servers.append(fallback_entry)

	return config

## Returns the first configured server or fallback.
func get_default_server() -> ServerEntry:
	if not servers.is_empty():
		return servers[0]
	return ServerEntry.new("Local", "127.0.0.1", DEFAULT_GAME_PORT, "Local Server", "01")

## Searches for a server entry by name.
func find_server(server_name: String) -> ServerEntry:
	for s in servers:
		if s.name.to_lower() == server_name.to_lower():
			return s
	return null
