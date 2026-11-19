class_name InstanceWindow
extends Control

## Instance (dungeon) browser on the team form (Go client: team/instances.go). Browse pages of
## rooms, create a room from a definition, and show status messages. Joining, leaving and starting
## rooms use the Gonline extension codes 200-202, whose native layout is unverified, so they are not
## sent here. Layout constants are the Go ones: list rows at y 87 + 70*i, page arrows (135,430) and
## (220,430), Create (149,465), definition rows at y 94 + 29*i (width 149), 10 per page.

signal status_message(text: String)

const PAGE_ROWS := 5
const ROW_TOP := 87
const ROW_STEP := 70
const DEFINITION_PAGE := 10
const DEFINITION_TOP := 94
const DEFINITION_STEP := 29

var page: int = 1
var pages: int = 0
var listings: Array = []
var definitions: Array = [] # [{id, name}]
var definition_page: int = 0
var selected_definition: int = -1
var _send: Callable = Callable()
var _create_open := false


## `send` takes a PackedByteArray and delivers it to the server.
func configure(send: Callable) -> void:
	_send = send


func set_definitions(list: Array) -> void:
	definitions = list
	selected_definition = -1


func show_page() -> void:
	_request(InstanceProtocol.encode_browse(page))


func go_page(delta: int) -> void:
	var next := page + delta
	if next < 1 or (pages > 0 and next > pages):
		return
	page = next
	show_page()


func apply_browse(p: PackedByteArray) -> bool:
	var parsed := InstanceProtocol.parse_browse(p)
	if parsed.is_empty():
		return false
	pages = parsed.pages
	page = parsed.page
	listings = parsed.rows
	return true


## Routes an AC 85 reply. Returns true when the packet belonged to the browser.
func handle_packet(action: int, sub: int, payload: PackedByteArray) -> bool:
	if action != InstanceProtocol.ACTION:
		return false
	match sub:
		InstanceProtocol.BROWSE:
			return apply_browse(payload)
		InstanceProtocol.STATUS:
			var code := InstanceProtocol.parse_status(payload)
			if code < 0:
				return false
			status_message.emit(InstanceProtocol.status_message(code))
			return true
		InstanceProtocol.DEFINITIONS:
			return not InstanceProtocol.parse_definitions(payload).is_empty()
	return false


func select_definition(index: int) -> void:
	var absolute := definition_page * DEFINITION_PAGE + index
	if absolute >= 0 and absolute < definitions.size():
		selected_definition = absolute


func change_definition_page(delta: int) -> void:
	var pages_total := maxi(1, int(ceil(float(definitions.size()) / DEFINITION_PAGE)))
	definition_page = clampi(definition_page + delta, 0, pages_total - 1)


## Sends the create request for the selected definition. Returns false with a status message when
## nothing is selected or the name cannot be encoded.
func create_room(room_name: String) -> bool:
	if selected_definition < 0 or selected_definition >= definitions.size():
		status_message.emit("Select an instance first.")
		return false
	var p := InstanceProtocol.encode_create(int(definitions[selected_definition].id), room_name)
	if p.is_empty():
		status_message.emit("The room name is too long.")
		return false
	_request(p)
	_create_open = false
	return true


func _request(p: PackedByteArray) -> void:
	if _send.is_valid():
		_send.call(p)
