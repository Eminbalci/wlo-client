class_name WorldPkWindow
extends Control

## World PK window drawing (Go client: worldpk/form.go). Shows the WorldPkState: the PVP tab with rank,
## wins and the chance bar, the Rankings tab with four rows per page, and the Settings tab with the
## offline toggle and Confirm/Cancel. Positions are the Go constants in form-local pixels: size
## 356x493, rank at (111,429), chance bar at (142,362) 140 px wide, ranking rows from y 82 step 78.

const WorldPkState = preload("res://scripts/ui/hud/world_pk_state.gd")
const SIZE := Vector2(356, 493)
const BAR_POS := Vector2(142, 362)
const BAR_MAX_WIDTH := 140.0
const ROW_TOP := 82
const ROW_STEP := 78
const INK := Color("#2b2b2b")

signal confirm_pressed
signal cancel_pressed

var state: WorldPkState = WorldPkState.new()
var _tabs: Array[Button] = []
var _rows: Array[Label] = []
var _rank_label: Label = null
var _wins_label: Label = null
var _bar: ColorRect = null
var _page_label: Label = null
var _offline_check: CheckBox = null
var _confirm: Button = null
var _cancel: Button = null


func _ready() -> void:
	size = SIZE
	custom_minimum_size = SIZE
	visible = false
	_build()
	refresh()


func _build() -> void:
	for i in 3:
		var t := Button.new()
		t.name = "Tab%d" % i
		t.text = ["PVP", "Rankings", "Settings"][i]
		t.position = Vector2(24 + i * 100, 36)
		t.size = Vector2(90, 20)
		var tab := i
		t.pressed.connect(func() -> void:
			state.select_tab(tab)
			refresh())
		add_child(t)
		_tabs.append(t)
	_rank_label = _label("Rank", Vector2(155, 95))
	_wins_label = _label("Wins", Vector2(155, 137))
	_bar = ColorRect.new()
	_bar.name = "ChanceBar"
	_bar.position = BAR_POS
	_bar.size = Vector2(0, 4)
	_bar.color = Color("#5a5ef0")
	add_child(_bar)
	for row in WorldPkState.ROWS_PER_PAGE:
		_rows.append(_label("Row%d" % row, Vector2(173, ROW_TOP + row * ROW_STEP)))
	_page_label = _label("Page", Vector2(165, 400))
	_offline_check = CheckBox.new()
	_offline_check.name = "AllowOffline"
	_offline_check.text = "Allow offline"
	_offline_check.position = Vector2(40, 120)
	_offline_check.toggled.connect(func(on: bool) -> void:
		state.set_draft_allow(on)
		refresh())
	add_child(_offline_check)
	_confirm = Button.new()
	_confirm.name = "Confirm"
	_confirm.text = "Confirm"
	_confirm.position = Vector2(51, 426)
	_confirm.size = Vector2(56, 20)
	_confirm.pressed.connect(func() -> void:
		state.confirm_settings()
		confirm_pressed.emit()
		refresh())
	add_child(_confirm)
	_cancel = Button.new()
	_cancel.name = "Cancel"
	_cancel.text = "Cancel"
	_cancel.position = Vector2(196, 426)
	_cancel.size = Vector2(56, 20)
	_cancel.pressed.connect(func() -> void:
		state.cancel_settings()
		cancel_pressed.emit()
		refresh())
	add_child(_cancel)


func _label(node_name: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.name = node_name
	l.position = pos
	l.add_theme_color_override("font_color", INK)
	add_child(l)
	return l


## Redraws every control from the state.
func refresh() -> void:
	if _rank_label == null:
		return
	for i in _tabs.size():
		_tabs[i].disabled = i == state.tab
	var pvp := state.tab == WorldPkState.TAB_PVP
	var rankings := state.tab == WorldPkState.TAB_RANKINGS
	var settings := state.tab == WorldPkState.TAB_SETTINGS
	_rank_label.visible = pvp
	_wins_label.visible = pvp
	_bar.visible = pvp
	_rank_label.text = str(state.rank)
	_wins_label.text = str(state.wins)
	_bar.size.x = BAR_MAX_WIDTH * state.chance_fraction()
	var rows := state.page_rows() if rankings else []
	for i in _rows.size():
		_rows[i].visible = rankings and i < rows.size()
		if _rows[i].visible:
			var r: Dictionary = rows[i]
			_rows[i].text = "%d. %s  Lv %d  Wins %d" % [r.rank, r.name, r.level, r.wins]
	_page_label.visible = rankings
	_page_label.text = "%d/%d" % [state.page, state.page_count()]
	_offline_check.visible = settings
	_offline_check.button_pressed = state.draft_allow
	_confirm.visible = state.settings_dirty()
	_cancel.visible = state.settings_dirty()


## Escape closes the window (Go WorldPKKey).
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	state.select_tab(state.tab)
	refresh()
	visible = true
	move_to_front()


func close() -> void:
	visible = false
