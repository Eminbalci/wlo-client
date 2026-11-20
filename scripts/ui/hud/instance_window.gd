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
## C# server flavour state: the room the player is in (0 = none), its map, started flag and roster.
var room_id: int = 0
var room_map: int = 0
var room_started: bool = false
var roster: Array = []
var _send: Callable = Callable()
var _create_open := false


## `send` takes a PackedByteArray and delivers it to the server.
func configure(send: Callable) -> void:
	_send = send


func set_definitions(list: Array) -> void:
	definitions = list
	selected_definition = -1


## The Go protocol's AC85:1 is a room browse, but the C# server (the original client's protocol)
## uses AC85:1 to create or enter a room. Sending it as a browse creates a room on that server, so the
## browse request is off until a server that implements the Go browse is targeted.
var browse_enabled: bool = false


func show_page() -> void:
	if not browse_enabled:
		return
	_request(InstanceProtocol.encode_browse(page))


func go_page(delta: int) -> void:
	if not browse_enabled:
		return
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
	refresh_controls()
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
		0:
			var r := InstanceProtocol.parse_roster(payload)
			if r.is_empty():
				return false
			room_map = r.map
			roster = r.members
			return true
		4:
			var j := InstanceProtocol.parse_room_joined(payload)
			if j.is_empty():
				return false
			room_id = j.room
			room_map = j.map
			return true
		5:
			var st := InstanceProtocol.parse_started(payload)
			if st.is_empty():
				return false
			room_id = st.room
			room_map = st.map
			room_started = true
			return true
	return false


## C# server: AC85:1 creates or enters the player's room on `map_id`. Returns false with a message when
## the player is already in a room.
func enter_room(map_id: int, max_members: int = 4) -> bool:
	if room_id != 0:
		status_message.emit("Leave the current instance room first.")
		return false
	_request(InstanceProtocol.encode_enter(map_id, max_members))
	return true


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


## Visible controls: five listing rows (name, creator, member count), page label and arrows, and
## Create. Built on demand so tests and the HUD can add the window before it is shown.
var _rows: Array[Label] = []
var _page_label: Label = null
var _create_button: Button = null
var _prev_button: Button = null
var _next_button: Button = null


func build_controls() -> void:
	if not _rows.is_empty():
		return
	for i in PAGE_ROWS:
		var l := Label.new()
		l.name = "Row%d" % i
		l.position = Vector2(30, ROW_TOP + i * ROW_STEP)
		l.size = Vector2(240, 42)
		add_child(l)
		_rows.append(l)
	_page_label = Label.new()
	_page_label.name = "Page"
	_page_label.position = Vector2(170, 434)
	add_child(_page_label)
	_prev_button = Button.new()
	_prev_button.name = "PrevPage"
	_prev_button.text = "<"
	_prev_button.position = Vector2(135, 430)
	_prev_button.size = Vector2(21, 21)
	_prev_button.pressed.connect(func() -> void: go_page(-1))
	add_child(_prev_button)
	_next_button = Button.new()
	_next_button.name = "NextPage"
	_next_button.text = ">"
	_next_button.position = Vector2(220, 430)
	_next_button.size = Vector2(21, 21)
	_next_button.pressed.connect(func() -> void: go_page(1))
	add_child(_next_button)
	_create_button = Button.new()
	_create_button.name = "Create"
	_create_button.text = "Create"
	_create_button.position = Vector2(149, 465)
	_create_button.size = Vector2(71, 20)
	add_child(_create_button)
	refresh_controls()


## Fills the rows and the page label from the current listings.
func refresh_controls() -> void:
	if _rows.is_empty():
		return
	for i in PAGE_ROWS:
		if i < listings.size():
			var r: Dictionary = listings[i]
			_rows[i].text = "%s  (%s, %d players)" % [r.name, r.creator, r.members]
			_rows[i].visible = true
		else:
			_rows[i].text = ""
			_rows[i].visible = false
	_page_label.text = "%d/%d" % [page, maxi(pages, 1)]


func _request(p: PackedByteArray) -> void:
	if _send.is_valid():
		_send.call(p)
