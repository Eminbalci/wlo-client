extends SceneTree

## Verification test for Player Status Dock Parity, Level, HP/SP, and Avatar bust mismatch fix

func _init() -> void:
	print("\n=================================================================")
	print("--- Running Test Player Status Dock Parity & Runtime Sync ---")
	print("=================================================================\n")
	
	# 1. Instantiate HUD Scene directly
	var hud_scene = preload("res://scenes/ui/hud.tscn")
	var hud: HUD = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	
	# Check HUD defaults
	assert(hud.name_label != null, "NameLabel missing")
	assert(hud.name_label.text == "Daniel", "Default NameLabel text must be 'Daniel', got: %s" % hud.name_label.text)
	print("[PASS] HUD NameLabel defaults to Daniel")
	
	assert(hud.level_label != null, "LevelLabel missing")
	assert(hud.level_label.text == "LV 10", "Default LevelLabel text must be 'LV 10', got: %s" % hud.level_label.text)
	print("[PASS] HUD LevelLabel defaults to LV 10")
	
	assert(hud.hp_label != null, "HpLabel missing")
	assert(hud.hp_label.text == "HP   245/245", "Default HpLabel text must be 'HP   245/245', got: %s" % hud.hp_label.text)
	assert(hud.hp_bar.value == 245.0 and hud.hp_bar.max_value == 245.0, "HpBar values mismatch: %f/%f" % [hud.hp_bar.value, hud.hp_bar.max_value])
	print("[PASS] HUD HpLabel and HpBar default to 245/245")
	
	assert(hud.sp_label != null, "SpLabel missing")
	assert(hud.sp_label.text == "SP   180/180", "Default SpLabel text must be 'SP   180/180', got: %s" % hud.sp_label.text)
	assert(hud.sp_bar.value == 180.0 and hud.sp_bar.max_value == 180.0, "SpBar values mismatch: %f/%f" % [hud.sp_bar.value, hud.sp_bar.max_value])
	print("[PASS] HUD SpLabel and SpBar default to 180/180")
	
	assert(hud.avatar_rect != null and hud.avatar_rect.texture != null, "AvatarRect texture must not be null")
	print("[PASS] HUD AvatarRect default texture verified")
	
	assert(hud.element_icon != null and hud.element_icon.texture != null, "ElementIcon texture must not be null")
	print("[PASS] HUD ElementIcon default texture verified")
	
	# 2. Test PlayerEntity signals and setters
	var player = PlayerEntity.new()
	root.add_child(player)
	await process_frame
	
	var received_stats: Array[Dictionary] = []
	player.stats_changed.connect(func(data: Dictionary): received_stats.append(data))
	
	player.character_name = "Alice"
	assert(player.nameplate.text == "Alice", "Player nameplate did not update with character_name")
	assert(received_stats.size() >= 1, "stats_changed was not emitted on name change")
	assert(received_stats[-1].name == "Alice", "stats_changed name mismatch")
	print("[PASS] PlayerEntity character_name setter updates nameplate and emits stats_changed")
	
	player.level = 25
	player.hp = 300
	player.max_hp = 400
	player.sp = 150
	player.max_sp = 250
	player.exp_percent = 75.5
	assert(received_stats[-1].level == 25, "Level signal mismatch")
	assert(received_stats[-1].hp == 300, "HP signal mismatch")
	assert(received_stats[-1].max_hp == 400, "Max HP signal mismatch")
	assert(received_stats[-1].sp == 150, "SP signal mismatch")
	assert(received_stats[-1].max_sp == 250, "Max SP signal mismatch")
	assert(received_stats[-1].exp_percent == 75.5, "EXP percent signal mismatch")
	print("[PASS] PlayerEntity stat mutations emit stats_changed correctly")
	
	# 3. Test HUD wiring to PlayerEntity
	hud.player = player
	assert(hud.name_label.text == "Alice", "HUD NameLabel did not sync from player: %s" % hud.name_label.text)
	assert(hud.level_label.text == "LV 25", "HUD LevelLabel did not sync from player: %s" % hud.level_label.text)
	assert(hud.hp_label.text == "HP   300/400", "HUD HpLabel did not sync from player: %s" % hud.hp_label.text)
	assert(hud.hp_bar.value == 300.0 and hud.hp_bar.max_value == 400.0, "HUD HpBar did not sync from player")
	assert(hud.sp_label.text == "SP   150/250", "HUD SpLabel did not sync from player: %s" % hud.sp_label.text)
	assert(hud.sp_bar.value == 150.0 and hud.sp_bar.max_value == 250.0, "HUD SpBar did not sync from player")
	assert(hud.exp_label.text == "75%", "HUD ExpLabel did not sync from player: %s" % hud.exp_label.text)
	print("[PASS] HUD player setter auto-sync verified")
	
	# Dynamic change while connected
	player.hp = 120
	assert(hud.hp_label.text == "HP   120/400", "Dynamic player HP change did not sync to HUD: %s" % hud.hp_label.text)
	assert(hud.hp_bar.value == 120.0, "Dynamic player HP bar value did not update")
	print("[PASS] Dynamic player stat update reflected immediately in HUD")
	
	player.queue_free()
	hud.queue_free()
	
	print("\n=================================================================")
	print("--- ALL PLAYER STATUS PARITY TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)
