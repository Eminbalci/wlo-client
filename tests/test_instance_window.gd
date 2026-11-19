extends SceneTree

## Instance browser: browse requests and paging, browse replies, status messages, create requests.

const InstanceWindow = preload("res://scripts/ui/hud/instance_window.gd")

var _checks := 0
var _failed := 0
var _sent: Array = []


func _init() -> void:
	_run()


func _record(ok: bool, label: String) -> void:
	_checks += 1
	if ok:
		print("  [PASS] " + label)
	else:
		_failed += 1
		print("  [FAIL] " + label)


func _capture(p: PackedByteArray) -> void:
	_sent.append(p)


func _run() -> void:
	print("--- Instance Window Suite ---")
	await process_frame
	var w = InstanceWindow.new()
	w.configure(Callable(self, "_capture"))
	root.add_child(w)

	w.build_controls()
	w.show_page()
	_record(_sent.back() == PackedByteArray([85, 1, 1]), "opening the browser requests page 1")

	# Browse reply: 3 pages, page 1, one row.
	var reply := PackedByteArray([85, 1, 3, 1, 1, 7, 0, 3, 65, 110, 110, 4, 72, 97, 108, 108, 3, 0])
	_record(w.handle_packet(85, 1, reply), "a browse reply is consumed")
	_record(w.pages == 3 and w.listings.size() == 1 and w.listings[0].name == "Hall", "the reply fills the listings and page count")

	_record(w._rows[0].text.begins_with("Hall") and w._rows[0].visible and not w._rows[1].visible, "the listing shows one row and hides the empty ones")
	_record(w._page_label.text == "1/3", "the page label shows page and total")
	w.go_page(1)
	_record(_sent.back() == PackedByteArray([85, 1, 2]), "the next arrow requests page 2")
	w.page = 3
	w.go_page(1)
	_record(w.page == 3, "paging stops at the last page")

	var messages: Array = []
	w.status_message.connect(func(t: String) -> void: messages.append(t))
	_record(w.handle_packet(85, 2, PackedByteArray([85, 2, 2])), "a status reply is consumed")
	_record(messages.size() == 1 and messages[0] == "Your level is too low for this instance.", "the status code shows its message")

	w.set_definitions([{"id": 1, "name": "A"}, {"id": 0x1234, "name": "B"}])
	w.select_definition(1)
	_record(w.create_room("Hi"), "create sends a request for the selected definition")
	_record(_sent.back() == PackedByteArray([85, 3, 0x34, 0x12, 2, 72, 105]), "the create request carries the definition id and name")

	var empty = InstanceWindow.new()
	empty.configure(Callable(self, "_capture"))
	var before := _sent.size()
	_record(not empty.create_room("X") and _sent.size() == before, "create without a selection sends nothing")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
