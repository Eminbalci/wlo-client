class_name WorldPkState
extends RefCounted

## World PK window state (Go client: worldpk/form.go). Presentation only: the server supplies the
## rank, wins, chances, ranking entries and the offline-allow setting. Tabs are PVP (0), Rankings (1)
## and Settings (2). Rankings show 4 rows per page, up to 300 entries. The settings draft is only
## saved with Confirm; Cancel or leaving the tab discards it.

const TAB_PVP := 0
const TAB_RANKINGS := 1
const TAB_SETTINGS := 2
const ROWS_PER_PAGE := 4
const RANKING_LIMIT := 300
const PREVIEW_CHANCES := 10

var rank: int = 0
var wins: int = 0
var chances: int = PREVIEW_CHANCES
var entries: Array = [] # [{name, level, wins}]
var allow_offline: bool = true
var tab: int = TAB_PVP
var page: int = 1
var draft_allow: bool = true


func reset() -> void:
	rank = 0
	wins = 0
	chances = PREVIEW_CHANCES
	entries = []
	allow_offline = true
	tab = TAB_PVP
	page = 1
	draft_allow = true


func ranked_count() -> int:
	return mini(entries.size(), RANKING_LIMIT)


func page_count() -> int:
	return maxi(1, (ranked_count() + ROWS_PER_PAGE - 1) / ROWS_PER_PAGE)


func select_tab(next: int) -> void:
	if next < TAB_PVP or next > TAB_SETTINGS:
		return
	tab = next
	draft_allow = allow_offline
	page = clampi(page, 1, page_count())


func set_page(target: int) -> void:
	page = clampi(target, 1, page_count())


## Rows on the current page: [{index (1-based rank), name, level, wins}].
func page_rows() -> Array:
	var out: Array = []
	var first := (page - 1) * ROWS_PER_PAGE
	for row in ROWS_PER_PAGE:
		var index := first + row
		if index >= ranked_count():
			break
		var e: Dictionary = entries[index]
		out.append({"rank": index + 1, "name": e.get("name", ""), "level": e.get("level", 0), "wins": e.get("wins", 0)})
	return out


func can_view_my_ranking() -> bool:
	return rank > 0 and rank <= ranked_count()


## The Confirm and Cancel buttons show only on the settings tab with an unsaved change.
func settings_dirty() -> bool:
	return tab == TAB_SETTINGS and draft_allow != allow_offline


func set_draft_allow(value: bool) -> void:
	draft_allow = value


## Saves the draft. Returns true when there was something to save.
func confirm_settings() -> bool:
	if not settings_dirty():
		return false
	allow_offline = draft_allow
	return true


func cancel_settings() -> void:
	draft_allow = allow_offline


## Fraction of the chance bar that is filled (0..1), as the Go bar width over 140 px.
func chance_fraction() -> float:
	return float(clampi(chances, 0, PREVIEW_CHANCES)) / PREVIEW_CHANCES
