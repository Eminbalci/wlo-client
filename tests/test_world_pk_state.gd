extends SceneTree

## World PK window state: tabs, paging, my-ranking, settings draft and chance bar.

const WorldPkState = preload("res://scripts/ui/hud/world_pk_state.gd")

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
	print("--- World PK State Suite ---")
	await process_frame
	var s := WorldPkState.new()
	_record(s.tab == WorldPkState.TAB_PVP and s.page == 1, "the window starts on the PVP tab, page 1")
	_record(s.page_count() == 1, "no entries still gives one page")

	for i in 10:
		s.entries.append({"name": "P%d" % i, "level": 10 + i, "wins": i})
	_record(s.page_count() == 3, "10 entries at 4 per page give 3 pages")
	s.select_tab(WorldPkState.TAB_RANKINGS)
	s.set_page(3)
	var rows := s.page_rows()
	_record(rows.size() == 2 and rows[0].rank == 9 and rows[1].name == "P9", "the last page shows the remaining rows with their ranks")
	s.set_page(99)
	_record(s.page == 3, "paging clamps to the last page")

	s.rank = 9
	_record(s.can_view_my_ranking(), "my ranking is available when ranked inside the list")
	s.rank = 0
	_record(not s.can_view_my_ranking(), "my ranking is unavailable at rank 0")

	s.select_tab(WorldPkState.TAB_SETTINGS)
	_record(not s.settings_dirty(), "a fresh settings tab has no unsaved change")
	s.set_draft_allow(false)
	_record(s.settings_dirty(), "a changed draft shows Confirm and Cancel")
	s.cancel_settings()
	_record(not s.settings_dirty() and s.allow_offline, "Cancel restores the saved setting")
	s.set_draft_allow(false)
	_record(s.confirm_settings() and not s.allow_offline, "Confirm saves the draft")
	_record(not s.confirm_settings(), "Confirm does nothing without a change")

	s.select_tab(WorldPkState.TAB_PVP)
	s.chances = 5
	_record(is_equal_approx(s.chance_fraction(), 0.5), "five of ten chances fill half the bar")
	s.chances = 99
	_record(s.chance_fraction() == 1.0, "the chance bar never overfills")

	s.reset()
	_record(s.allow_offline and s.chances == WorldPkState.PREVIEW_CHANCES and s.entries.is_empty(), "reset restores the defaults")

	print("--- %d CHECKS, %d FAILED ---" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
