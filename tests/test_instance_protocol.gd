extends SceneTree

## Instance (AC 85) packets: request bytes and the reply parsers, checked against the Go layouts.

const InstanceProtocol = preload("res://scripts/network/instance_protocol.gd")

var _checks := 0
var _failed := 0


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _run() -> void:
	print("--- Instance Protocol Suite ---")
	await process_frame
	_record(InstanceProtocol.encode_browse(2) == PackedByteArray([85, 1, 2]), "browse request is AC85:1 with the page")
	_record(InstanceProtocol.encode_browse(0) == PackedByteArray([85, 1, 1]), "browse page 0 is sent as page 1")

	var create := InstanceProtocol.encode_create(0x1234, "Hi")
	_record(create == PackedByteArray([85, 3, 0x34, 0x12, 2, 72, 105]), "create is AC85:3, u16 definition, length-prefixed name")
	_record(InstanceProtocol.encode_create(1, "x".repeat(256)).is_empty(), "a name over 255 bytes is refused")

	# Browse reply: 2 pages, page 1, one row (id 7, creator "Ann", name "Hall", 3 members, 2 guild bytes).
	var browse := PackedByteArray([85, 1, 2, 1, 1, 7, 0, 3, 65, 110, 110, 4, 72, 97, 108, 108, 3, 2, 9, 9])
	var b := InstanceProtocol.parse_browse(browse)
	_record(b.get("pages") == 2 and b.get("page") == 1, "browse reply carries pages and page")
	_record(b.get("rows", []).size() == 1 and b.rows[0].id == 7 and b.rows[0].creator == "Ann" and b.rows[0].name == "Hall" and b.rows[0].members == 3, "a browse row is parsed with its guild bytes skipped")
	_record(InstanceProtocol.parse_browse(PackedByteArray([85, 1, 1, 1, 6])).is_empty(), "a browse count above the page size is refused")
	_record(InstanceProtocol.parse_browse(browse + PackedByteArray([0])).is_empty(), "trailing bytes make a browse reply malformed")

	# Room snapshot: room 5, definition 9, one member (id 100, level 12, name "Bo").
	var room := PackedByteArray([85, 203, 5, 0, 9, 0, 1, 100, 0, 0, 0, 12, 2, 66, 111])
	var s := InstanceProtocol.parse_room_snapshot(room)
	_record(s.get("room") == 5 and s.get("definition") == 9, "room snapshot carries room and definition")
	_record(s.get("members", []).size() == 1 and s.members[0].id == 100 and s.members[0].level == 12 and s.members[0].name == "Bo", "a member is parsed")
	var empty_room := PackedByteArray([85, 203, 0, 0, 0, 0, 1, 100, 0, 0, 0, 12, 0])
	_record(InstanceProtocol.parse_room_snapshot(empty_room).is_empty(), "room 0 with members is malformed")

	_record(InstanceProtocol.parse_status(PackedByteArray([85, 2, 11])) == InstanceProtocol.STATUS_UNAVAILABLE, "status 11 is read")
	_record(InstanceProtocol.parse_status(PackedByteArray([85, 2])) == -1, "a status packet without a code is malformed")
	_record(InstanceProtocol.status_message(2) == "Your level is too low for this instance.", "status 2 has its message")
	_record(InstanceProtocol.status_message(77) == "Instance status 77.", "an unknown status names its number")

	var defs := InstanceProtocol.parse_definitions(PackedByteArray([85, 14, 2, 1, 0, 1, 2, 0, 0]))
	_record(defs.size() == 2 and defs[0].id == 1 and defs[1].flag == 0, "definitions are read as id and flag pairs")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
