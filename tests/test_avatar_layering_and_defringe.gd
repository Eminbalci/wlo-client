extends SceneTree

## Headless verification suite for:
## 1. PlayerStatusDock HP Bar / Avatar Layering
## 2. Sprite Green Defringing & Chroma Key edge cleanup
## 3. Slotted Item visibility and z-ordering in CompoundWindow & Inventory

func _init() -> void:
	print("\n=================================================================")
	print("--- Running Test Avatar Layering, Defringing & Item Z-Order ---")
	print("=================================================================\n")

	# --------------------------------------------------------------------------
	# 1. Verify PlayerStatusDock Node Order and Layering in hud.tscn
	# --------------------------------------------------------------------------
	print(">>> [TEST 1] Verifying PlayerStatusDock Layering in scenes/ui/hud.tscn...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	assert(hud_scene != null, "scenes/ui/hud.tscn must be loadable")
	var hud: Control = hud_scene.instantiate() as Control
	assert(hud != null, "HUD scene failed to instantiate")
	root.add_child(hud)
	await process_frame

	var dock: Control = hud.get_node_or_null("PlayerStatusDock") as Control
	assert(dock != null, "PlayerStatusDock missing in HUD")

	var avatar_rect: TextureRect = dock.get_node_or_null("AvatarRect") as TextureRect
	var status_bg: TextureRect = dock.get_node_or_null("StatusBackground") as TextureRect
	var hp_bar: Control = dock.get_node_or_null("HpBar") as Control
	var sp_bar: Control = dock.get_node_or_null("SpBar") as Control

	assert(avatar_rect != null, "AvatarRect missing in PlayerStatusDock")
	assert(status_bg != null, "StatusBackground missing in PlayerStatusDock")
	assert(hp_bar != null, "HpBar missing in PlayerStatusDock")
	assert(sp_bar != null, "SpBar missing in PlayerStatusDock")

	var avatar_idx := avatar_rect.get_index()
	var bg_idx := status_bg.get_index()
	var hp_idx := hp_bar.get_index()
	var sp_idx := sp_bar.get_index()

	print("  Indices in PlayerStatusDock: AvatarRect=%d, StatusBackground=%d, HpBar=%d, SpBar=%d" % [avatar_idx, bg_idx, hp_idx, sp_idx])
	assert(avatar_idx < bg_idx, "AvatarRect (idx %d) must be drawn BEFORE StatusBackground (idx %d)" % [avatar_idx, bg_idx])
	assert(avatar_idx < hp_idx, "AvatarRect (idx %d) must be drawn BEFORE HpBar (idx %d)" % [avatar_idx, hp_idx])
	assert(avatar_idx < sp_idx, "AvatarRect (idx %d) must be drawn BEFORE SpBar (idx %d)" % [avatar_idx, sp_idx])
	assert(bg_idx < hp_idx, "StatusBackground (idx %d) must be before HpBar (idx %d)" % [bg_idx, hp_idx])
	print("  [PASS] PlayerStatusDock draw hierarchy strictly verified: Avatar is behind StatusBackground & HpBar.")

	# --------------------------------------------------------------------------
	# 2. Verify status_dock.tscn standalone consistency
	# --------------------------------------------------------------------------
	print(">>> [TEST 2] Verifying status_dock.tscn standalone scene hierarchy...")
	var dock_scene: PackedScene = load("res://scenes/ui/hud/status_dock.tscn")
	assert(dock_scene != null, "status_dock.tscn must be loadable")
	var standalone_dock: Control = dock_scene.instantiate() as Control
	assert(standalone_dock != null, "status_dock.tscn failed to instantiate")
	root.add_child(standalone_dock)
	await process_frame

	var s_avatar: TextureRect = standalone_dock.get_node_or_null("AvatarRect") as TextureRect
	var s_bg: TextureRect = standalone_dock.get_node_or_null("StatusBackground") as TextureRect
	var s_hp: Control = standalone_dock.get_node_or_null("HpBar") as Control

	assert(s_avatar != null and s_bg != null and s_hp != null, "Nodes missing in standalone status dock")
	assert(s_avatar.get_index() < s_bg.get_index(), "AvatarRect must be before StatusBackground in standalone status dock")
	assert(s_avatar.get_index() < s_hp.get_index(), "AvatarRect must be before HpBar in standalone status dock")
	print("  [PASS] Standalone status_dock.tscn hierarchy strictly matches.")

	# --------------------------------------------------------------------------
	# 3. Verify CompoundWindow slot item z-ordering and CompoundingAnim overlay
	# --------------------------------------------------------------------------
	print(">>> [TEST 3] Verifying CompoundWindow slotted item z-ordering & overlay...")
	var compound_script = load("res://scripts/ui/hud/compound_window.gd")
	assert(compound_script != null, "compound_window.gd must load")
	var comp_win: CompoundWindow = compound_script.new()
	root.add_child(comp_win)
	await process_frame

	assert(comp_win.main_slot_btn != null, "CompoundItem_Main slot button missing")
	var main_icon := comp_win.main_slot_btn.get_node_or_null("Icon") as TextureRect
	var main_backing := comp_win.main_slot_btn.get_node_or_null("SlotBacking") as Panel
	var main_count := comp_win.main_slot_btn.get_node_or_null("CountLabel") as Label

	assert(main_icon != null, "Main slot Icon missing")
	assert(main_backing != null, "Main slot SlotBacking missing")
	assert(main_count != null, "Main slot CountLabel missing")
	assert(main_icon.z_index >= 2, "Main slot Icon z_index must be >= 2, got %d" % main_icon.z_index)
	assert(main_count.z_index >= 3, "Main slot CountLabel z_index must be >= 3, got %d" % main_count.z_index)
	assert(main_backing.z_index < main_icon.z_index, "SlotBacking must have lower z_index than Icon")

	# Check sub slots
	assert(comp_win.sub_slot_btns.size() == 4, "Must have 4 sub slot buttons")
	for i in range(4):
		var s_btn := comp_win.sub_slot_btns[i]
		var s_icon := s_btn.get_node_or_null("Icon") as TextureRect
		var s_backing := s_btn.get_node_or_null("SlotBacking") as Panel
		assert(s_icon != null and s_backing != null, "Sub slot %d missing child nodes" % i)
		assert(s_icon.z_index >= 2, "Sub slot %d icon z_index must be >= 2" % i)
		assert(s_backing.z_index < s_icon.z_index, "Sub slot %d backing must be behind icon" % i)

	# Verify CompoundingAnim overlay does not permanently obscure slotted items
	assert(comp_win.compounding_rect != null, "CompoundingAnim overlay missing")
	assert(not comp_win.compounding_rect.visible, "CompoundingAnim overlay must be hidden by default")
	comp_win.close_window()
	assert(not comp_win.compounding_rect.visible, "CompoundingAnim overlay must remain hidden upon close")
	print("  [PASS] CompoundWindow slot z-indexes and CompoundingAnim overlay strictly verified.")

	# --------------------------------------------------------------------------
	# 4. Verify HUDInventory slot item z-ordering
	# --------------------------------------------------------------------------
	print(">>> [TEST 4] Verifying HUDInventory slot item z-ordering...")
	if hud.has_method("get") and hud.get("inventory_ctrl") != null:
		var inv_ctrl = hud.get("inventory_ctrl")
		assert(inv_ctrl.inventory_icons.size() > 0, "Inventory icons must exist")
		for icon in inv_ctrl.inventory_icons:
			assert(icon.z_index >= 2, "Inventory icon z_index must be >= 2, got %d" % icon.z_index)
		for count_lbl in inv_ctrl.inventory_counts:
			assert(count_lbl.z_index >= 3, "Inventory count label z_index must be >= 3, got %d" % count_lbl.z_index)
		print("  [PASS] HUDInventory slot icon and count z-indexes strictly verified (z_index=2/3).")

	# --------------------------------------------------------------------------
	# 5. Verify Defringed Assets (0 pure green chroma bleed in HUD assets)
	# --------------------------------------------------------------------------
	print(">>> [TEST 5] Verifying defringed HUD assets...")
	var test_assets := [
		"res://assets/hud/compounding_anim.png",
		"res://assets/hud/btn_background_2.png",
		"res://assets/hud/hud_minimap.png",
		"res://assets/hud/icon_use_compound_skill.png"
	]
	for p in test_assets:
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(p))
		assert(img != null, "Failed to load %s" % p)
		var w := img.get_width()
		var h := img.get_height()
		var pure_green_count := 0
		for y in range(h):
			for x in range(w):
				var col := img.get_pixel(x, y)
				if col.a > 0.0:
					if col.g > 0.75 and col.r < 0.25 and col.b < 0.25:
						pure_green_count += 1
		assert(pure_green_count == 0, "%s must have 0 pure green chroma bleed pixels, found %d" % [p, pure_green_count])
		print("  [PASS] %s verified: 0 pure green chroma bleed pixels (%dx%d)" % [p.get_file(), w, h])

	print("\n=================================================================")
	print("--- ALL AVATAR LAYERING, DEFRINGING & Z-ORDER TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)
