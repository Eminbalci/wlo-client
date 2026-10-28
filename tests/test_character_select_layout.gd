extends SceneTree

## Layout regression suite for the character select screen (WLRI white skin).
## Guards against: sliced title banner used as slot tabs, stray duplicate arrow buttons,
## sprite overlapping the baked "Launched Character's Status" caption, EXP bar covering its label.

const SCENE_PATH: String = "res://scenes/ui/auth/character_select.tscn"
# Inner preview frame baked into Form_SelectRole_Info_R.jpg (card-local pixels).
const INNER_FRAME: Rect2 = Rect2(77, 193, 183, 130)

var _count: int = 0
var _failures: int = 0


func _init() -> void:
	_run()


func _check(ok: bool, label: String) -> void:
	_count += 1
	if ok:
		print("  [PASS] ", label)
	else:
		_failures += 1
		print("  [FAIL] ", label)


func _run() -> void:
	print("--- Character Select Layout Suite ---")
	var screen: Control = (load(SCENE_PATH) as PackedScene).instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame

	var title := screen.get_node_or_null("TitleImage") as TextureRect
	_check(title != null, "Full 'Character Select' title banner exists")
	if title:
		_check(title.texture != null and title.texture.get_size() == Vector2(225, 49), "Title banner keeps its 225x49 source size")
		_check(is_equal_approx(title.offset_left, -title.offset_right), "Title banner is centred horizontally")
		_check(title.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Title banner ignores mouse input")

	for slot in [0, 1]:
		var card := screen.get_node("CardSlot%d" % slot) as Control
		var tabs := card.get_node("SlotTabsBar") as Control
		_check(not tabs.visible, "Slot %d: sliced banner pieces are not shown as tabs" % slot)
		var overlay := card.get_node("InfoOverlay")
		_check(not overlay.has_node("BtnTurnL") and not overlay.has_node("BtnTurnR"), "Slot %d: no stray duplicate turn buttons" % slot)

		var sprite := overlay.get_node("SpritePreview") as Control
		var sprite_rect := Rect2(sprite.offset_left, sprite.offset_top, sprite.offset_right - sprite.offset_left, sprite.offset_bottom - sprite.offset_top)
		_check(sprite_rect.position.y >= INNER_FRAME.position.y, "Slot %d: sprite starts inside the inner preview frame" % slot)
		_check(sprite_rect.end.y <= INNER_FRAME.end.y, "Slot %d: sprite ends inside the inner preview frame" % slot)

		var bar := overlay.get_node("ExpBar") as Control
		var exp_label := overlay.get_node("ExpLabel") as Control
		_check(bar.offset_left >= 200.0, "Slot %d: EXP bar starts right of the baked 'EXP' caption" % slot)
		_check(bar.offset_right <= exp_label.offset_left, "Slot %d: EXP bar does not overlap its percentage label" % slot)

	var arrow_l := screen.btn_turn_l as TextureButton
	var arrow_r := screen.btn_turn_r as TextureButton
	_check(arrow_l != null and arrow_r != null, "Turn accessors resolve to the arrow buttons")
	var before: int = screen._slot_rotations[0]
	screen.selected_slot_index = 0
	arrow_r.pressed.emit()
	_check(screen._slot_rotations[0] == (before + 1) % 8, "Right arrow rotates the preview one heading")
	arrow_l.pressed.emit()
	_check(screen._slot_rotations[0] == before, "Left arrow rotates it back")

	# Test Loading state
	screen.set_loading(true)
	_check(screen.is_loading, "Character select is_loading flag is true")
	var loading_overlay_0 = screen.card_slot_0.get_node_or_null("LoadingOverlay")
	_check(loading_overlay_0 != null and loading_overlay_0.visible, "Slot 0 shows loading overlay")
	screen.set_loading(false)
	_check(not screen.is_loading, "Character select is_loading flag is false")
	_check(loading_overlay_0 != null and not loading_overlay_0.visible, "Slot 0 loading overlay is hidden")

	print("\n--- %d TESTS, %d FAILED ---" % [_count, _failures])
	quit(1 if _failures > 0 else 0)
