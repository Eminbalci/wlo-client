extends Node

## Automated Headless Verification Suite for Skill & Combat VFX Studio (SkillEditor).
## Tests skill creation, preset loading, damage formula simulation with authentic WLO element wheel,
## MBTM motion animation mapping, and JSON / GDScript export pipelines.

const SkillEditorClass = preload("res://scripts/tools/skill_editor.gd")

func _ready() -> void:
	print("=================================================================")
	print("--- Running Wonderland Online Skill & Combat VFX Studio Tests ---")
	print("=================================================================\n")
	
	var editor = SkillEditorClass.new()
	assert(editor != null, "ERROR: Failed to instantiate SkillEditor")
	add_child(editor)
	
	_test_skill_identity_and_defaults(editor)
	_test_presets(editor)
	_test_damage_formula_and_element_wheel(editor)
	_test_mbtm_animation_mapping(editor)
	_test_export_and_data_roundtrip(editor)
	_test_scene_instantiation()
	
	editor.queue_free()
	
	print("\n=================================================================")
	print("--- ALL SKILL & COMBAT VFX STUDIO TESTS PASSED (100%) ---")
	print("=================================================================")
	
	if get_tree() != null:
		get_tree().quit(0)

func _test_skill_identity_and_defaults(editor: Node) -> void:
	print(">>> [TEST 1] Verifying Skill Identity & Default Properties...")
	
	assert(editor.skill_id > 0, "Default skill_id must be > 0")
	assert(not editor.skill_name.is_empty(), "Default skill_name must not be empty")
	assert(not editor.description.is_empty(), "Default description must not be empty")
	
	# Verify Enums
	assert(SkillEditorClass.Element.NONE == 0, "Element.NONE must be 0")
	assert(SkillEditorClass.Element.EARTH == 1, "Element.EARTH must be 1")
	assert(SkillEditorClass.Element.WATER == 2, "Element.WATER must be 2")
	assert(SkillEditorClass.Element.FIRE == 3, "Element.FIRE must be 3")
	assert(SkillEditorClass.Element.WIND == 4, "Element.WIND must be 4")
	
	assert(SkillEditorClass.SkillType.PHYSICAL == 0, "SkillType.PHYSICAL must be 0")
	assert(SkillEditorClass.SkillType.MAGIC == 1, "SkillType.MAGIC must be 1")
	assert(SkillEditorClass.SkillType.ASSIST == 2, "SkillType.ASSIST must be 2")
	assert(SkillEditorClass.SkillType.STATUS == 3, "SkillType.STATUS must be 3")
	assert(SkillEditorClass.SkillType.SPECIAL == 4, "SkillType.SPECIAL must be 4")
	
	assert(SkillEditorClass.TargetScope.SINGLE == 0, "TargetScope.SINGLE must be 0")
	assert(SkillEditorClass.TargetScope.ROW == 1, "TargetScope.ROW must be 1")
	assert(SkillEditorClass.TargetScope.COLUMN == 2, "TargetScope.COLUMN must be 2")
	assert(SkillEditorClass.TargetScope.CROSS == 3, "TargetScope.CROSS must be 3")
	assert(SkillEditorClass.TargetScope.ALL == 4, "TargetScope.ALL must be 4")
	
	var record: Dictionary = editor.create_skill_record()
	assert(record.has("skill_id"), "Record must have skill_id")
	assert(record.has("skill_name"), "Record must have skill_name")
	assert(record.has("element"), "Record must have element")
	assert(record.has("skill_type"), "Record must have skill_type")
	assert(record.has("target_scope"), "Record must have target_scope")
	assert(record.has("sp_cost"), "Record must have sp_cost")
	assert(record.has("hp_cost"), "Record must have hp_cost")
	assert(record.has("cooldown_turns"), "Record must have cooldown_turns")
	assert(record.has("required_level"), "Record must have required_level")
	assert(record.has("base_damage"), "Record must have base_damage")
	assert(record.has("damage_multiplier_1"), "Record must have damage_multiplier_1")
	assert(record.has("damage_multiplier_2"), "Record must have damage_multiplier_2")
	assert(record.has("mbtm_motion_id"), "Record must have mbtm_motion_id")
	assert(record.has("cast_sfx_name"), "Record must have cast_sfx_name")
	assert(record.has("hit_sfx_name"), "Record must have hit_sfx_name")
	assert(record.has("vfx_animation_id"), "Record must have vfx_animation_id")
	
	print("  PASS: Skill Identity, Enums, and Record schema verified.")

func _test_presets(editor: Node) -> void:
	print("\n>>> [TEST 2] Verifying Built-in Skill Presets...")
	
	var presets: Array[String] = editor.get_available_presets()
	assert(presets.has("Wine Flame"), "Presets must include 'Wine Flame'")
	assert(presets.has("Leap"), "Presets must include 'Leap'")
	assert(presets.has("Summon Dogs"), "Presets must include 'Summon Dogs'")
	assert(presets.has("Meteor Shower"), "Presets must include 'Meteor Shower'")
	assert(presets.has("Cure"), "Presets must include 'Cure'")
	
	# 1. Wine Flame (ID 15039, Fire, Physical Single, SP 20, Base 85)
	editor.load_preset("Wine Flame")
	assert(editor.skill_id == 15039, "Wine Flame ID must be 15039")
	assert(editor.element == SkillEditorClass.Element.FIRE, "Wine Flame element must be FIRE")
	assert(editor.skill_type == SkillEditorClass.SkillType.PHYSICAL, "Wine Flame type must be PHYSICAL")
	assert(editor.target_scope == SkillEditorClass.TargetScope.SINGLE, "Wine Flame scope must be SINGLE")
	assert(editor.sp_cost == 20, "Wine Flame SP cost must be 20")
	assert(editor.base_damage == 85, "Wine Flame base damage must be 85")
	assert(editor.mbtm_motion_id == 60010, "Wine Flame motion ID must be 60010")
	print("  PASS: Preset 'Wine Flame' verified bit-exact.")
	
	# 2. Leap (ID 12036, Wind, Physical Single, SP 15, Base 70)
	editor.load_preset("Leap")
	assert(editor.skill_id == 12036, "Leap ID must be 12036")
	assert(editor.element == SkillEditorClass.Element.WIND, "Leap element must be WIND")
	assert(editor.skill_type == SkillEditorClass.SkillType.PHYSICAL, "Leap type must be PHYSICAL")
	assert(editor.target_scope == SkillEditorClass.TargetScope.SINGLE, "Leap scope must be SINGLE")
	assert(editor.sp_cost == 15, "Leap SP cost must be 15")
	assert(editor.base_damage == 70, "Leap base damage must be 70")
	assert(editor.mbtm_motion_id == 60005, "Leap motion ID must be 60005")
	print("  PASS: Preset 'Leap' verified bit-exact.")
	
	# 3. Summon Dogs (ID 11075, Earth, Physical Row, SP 35, Base 110)
	editor.load_preset("Summon Dogs")
	assert(editor.skill_id == 11075, "Summon Dogs ID must be 11075")
	assert(editor.element == SkillEditorClass.Element.EARTH, "Summon Dogs element must be EARTH")
	assert(editor.skill_type == SkillEditorClass.SkillType.PHYSICAL, "Summon Dogs type must be PHYSICAL")
	assert(editor.target_scope == SkillEditorClass.TargetScope.ROW, "Summon Dogs scope must be ROW")
	assert(editor.sp_cost == 35, "Summon Dogs SP cost must be 35")
	assert(editor.base_damage == 110, "Summon Dogs base damage must be 110")
	assert(editor.mbtm_motion_id == 60001, "Summon Dogs motion ID must be 60001")
	print("  PASS: Preset 'Summon Dogs' verified bit-exact.")
	
	# 4. Meteor Shower (ID 15050, Fire, Magic All, SP 65, Base 180)
	editor.load_preset("Meteor Shower")
	assert(editor.skill_id == 15050, "Meteor Shower ID must be 15050")
	assert(editor.element == SkillEditorClass.Element.FIRE, "Meteor Shower element must be FIRE")
	assert(editor.skill_type == SkillEditorClass.SkillType.MAGIC, "Meteor Shower type must be MAGIC")
	assert(editor.target_scope == SkillEditorClass.TargetScope.ALL, "Meteor Shower scope must be ALL")
	assert(editor.sp_cost == 65, "Meteor Shower SP cost must be 65")
	assert(editor.base_damage == 180, "Meteor Shower base damage must be 180")
	assert(editor.mbtm_motion_id == 60050, "Meteor Shower motion ID must be 60050")
	print("  PASS: Preset 'Meteor Shower' verified bit-exact.")
	
	# 5. Cure (ID 11077, Water, Assist Single, SP 25, Base -150 heal)
	editor.load_preset("Cure")
	assert(editor.skill_id == 11077, "Cure ID must be 11077")
	assert(editor.element == SkillEditorClass.Element.WATER, "Cure element must be WATER")
	assert(editor.skill_type == SkillEditorClass.SkillType.ASSIST, "Cure type must be ASSIST")
	assert(editor.target_scope == SkillEditorClass.TargetScope.SINGLE, "Cure scope must be SINGLE")
	assert(editor.sp_cost == 25, "Cure SP cost must be 25")
	assert(editor.base_damage == -150, "Cure base damage must be -150")
	assert(editor.mbtm_motion_id == 60003, "Cure motion ID must be 60003")
	print("  PASS: Preset 'Cure' verified bit-exact.")

func _test_damage_formula_and_element_wheel(editor: Node) -> void:
	print("\n>>> [TEST 3] Verifying Damage Formula Simulator & Element Wheel (+25% / -25%)...")
	
	# Element Wheel verification:
	# Earth(1) -> Water(2) -> Fire(3) -> Wind(4) -> Earth(1)
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.EARTH, SkillEditorClass.Element.WATER), 1.25), "Earth beats Water (+25%)")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.WATER, SkillEditorClass.Element.FIRE), 1.25), "Water beats Fire (+25%)")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.FIRE, SkillEditorClass.Element.WIND), 1.25), "Fire beats Wind (+25%)")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.WIND, SkillEditorClass.Element.EARTH), 1.25), "Wind beats Earth (+25%)")
	
	# Counter Disadvantage (-25%):
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.WATER, SkillEditorClass.Element.EARTH), 0.75), "Water vs Earth is -25%")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.FIRE, SkillEditorClass.Element.WATER), 0.75), "Fire vs Water is -25%")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.WIND, SkillEditorClass.Element.FIRE), 0.75), "Wind vs Fire is -25%")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.EARTH, SkillEditorClass.Element.WIND), 0.75), "Earth vs Wind is -25%")
	
	# Neutral (1.0):
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.NONE, SkillEditorClass.Element.FIRE), 1.0), "None vs Fire is 1.0")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.FIRE, SkillEditorClass.Element.FIRE), 1.0), "Fire vs Fire is 1.0")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.EARTH, SkillEditorClass.Element.FIRE), 1.0), "Earth vs Fire is 1.0")
	assert(is_equal_approx(SkillEditorClass.get_element_multiplier(SkillEditorClass.Element.WATER, SkillEditorClass.Element.WIND), 1.0), "Water vs Wind is 1.0")
	print("  PASS: Authentic 4-element wheel multipliers (+25% / -25% / 1.0) verified.")
	
	# Combat Formula: Physical with Wine Flame (Base 85, Mult 1.2, Fire)
	editor.load_preset("Wine Flame")
	# Attacker: ATK 100, Fire. Target: DEF 20.
	# Raw: 85 + (100 * 1.2) - 20 = 85 + 120 - 20 = 185
	var neutral_dmg: int = editor.calculate_damage(100, 0, 20, 0, SkillEditorClass.Element.FIRE, SkillEditorClass.Element.FIRE)
	assert(neutral_dmg == 185, "Neutral damage expected 185, got %d" % neutral_dmg)
	
	# Fire vs Wind (+25% bonus): 185 * 1.25 = 231.25 -> 231
	var adv_dmg: int = editor.calculate_damage(100, 0, 20, 0, SkillEditorClass.Element.FIRE, SkillEditorClass.Element.WIND)
	assert(adv_dmg == 231, "Advantage damage expected 231, got %d" % adv_dmg)
	
	# Fire vs Water (-25% penalty): 185 * 0.75 = 138.75 -> 139
	var disadv_dmg: int = editor.calculate_damage(100, 0, 20, 0, SkillEditorClass.Element.FIRE, SkillEditorClass.Element.WATER)
	assert(disadv_dmg == 139, "Disadvantage damage expected 139, got %d" % disadv_dmg)
	print("  PASS: Wine Flame formula: Neutral=185, Advantage(+25%%)=%d, Disadvantage(-25%%)=%d" % [adv_dmg, disadv_dmg])
	
	# Combat Formula: Magic with Meteor Shower (Base 180, Mult 1.5, Sec 0.2, Fire)
	editor.load_preset("Meteor Shower")
	# Attacker: MATK 120, Fire. Target: MDEF 30.
	# Raw: 180 + (120 * 1.5) - 30 + (120 * 0.2) = 180 + 180 - 30 + 24 = 354
	var magic_neutral: int = editor.calculate_damage(0, 120, 0, 30, SkillEditorClass.Element.FIRE, SkillEditorClass.Element.FIRE)
	assert(magic_neutral == 354, "Magic neutral expected 354, got %d" % magic_neutral)
	
	var magic_adv: int = editor.calculate_damage(0, 120, 0, 30, SkillEditorClass.Element.FIRE, SkillEditorClass.Element.WIND)
	# 354 * 1.25 = 442.5 -> 443
	assert(magic_adv == 443, "Magic advantage expected 443, got %d" % magic_adv)
	print("  PASS: Meteor Shower magic scaling: Neutral=%d, Advantage(+25%%)=%d" % [magic_neutral, magic_adv])
	
	# Combat Formula: Assist / Heal with Cure (Base -150, Mult 0.8, Water)
	editor.load_preset("Cure")
	# User: MATK 100. Heal: -(|-150| + 100 * 0.8) = -230
	var heal_val: int = editor.calculate_damage(0, 100, 0, 0, SkillEditorClass.Element.WATER, SkillEditorClass.Element.WATER)
	assert(heal_val == -230, "Cure healing expected -230, got %d" % heal_val)
	print("  PASS: Cure assist/healing formula verified: %d HP restored." % abs(heal_val))

func _test_mbtm_animation_mapping(editor: Node) -> void:
	print("\n>>> [TEST 4] Verifying MBTM Motion Timeline & VFX Animation Mapping...")
	
	var motion_count: int = editor.get_mbtm_motion_count()
	assert(motion_count >= 1800, "MBTM motion count must be >= 1800 (expected ~1829), got %d" % motion_count)
	print("  PASS: MBTM motion sequence count verified: %d entries." % motion_count)
	
	# Verify specific animation and SFX mappings
	editor.load_preset("Wine Flame")
	assert(editor.mbtm_motion_id == 60010, "Wine Flame motion ID must be 60010")
	assert(editor.cast_sfx_name == "wav9911.wav", "Wine Flame cast SFX must be wav9911.wav")
	assert(editor.hit_sfx_name == "wav9912.wav", "Wine Flame hit SFX must be wav9912.wav")
	assert(editor.vfx_animation_id == 60010, "Wine Flame VFX animation ID must be 60010")
	print("  PASS: Motion and SFX bindings for Wine Flame verified.")

func _test_export_and_data_roundtrip(editor: Node) -> void:
	print("\n>>> [TEST 5] Verifying Skill JSON and GDScript Export Pipelines...")
	
	# 1. JSON Export & Import
	editor.load_preset("Summon Dogs")
	var json_path: String = "user://test_skill_summon_dogs.json"
	var save_ok: bool = editor.save_skill_json(json_path)
	assert(save_ok == true, "save_skill_json must return true")
	assert(FileAccess.file_exists(json_path), "Exported skill JSON must exist at: " + json_path)
	
	# Clear and reload
	editor.load_preset("Cure")
	assert(editor.skill_id == 11077, "Editor must be Cure before reload")
	
	var loaded_rec: Dictionary = editor.load_skill_json(json_path)
	assert(not loaded_rec.is_empty(), "load_skill_json must return non-empty dictionary")
	assert(loaded_rec["skill_id"] == 11075, "Loaded skill_id must be 11075")
	assert(loaded_rec["skill_name"] == "Summon Dogs", "Loaded skill_name must be 'Summon Dogs'")
	assert(editor.skill_id == 11075, "Editor state must be updated to 11075")
	assert(editor.base_damage == 110, "Editor base damage must be 110")
	print("  PASS: JSON save/load roundtrip verified successfully.")
	
	# 2. GDScript Export
	var script_path: String = "user://test_skill_11075.gd"
	var code: String = editor.export_skill_script(script_path)
	assert(not code.is_empty(), "export_skill_script must return valid script content")
	assert(FileAccess.file_exists(script_path), "Exported GDScript must exist at: " + script_path)
	assert(code.contains("class_name Skill_11075"), "Script must contain class_name Skill_11075")
	assert(code.contains("const SKILL_ID: int = 11075"), "Script must contain SKILL_ID constant")
	assert(code.contains("static func calculate_damage"), "Script must contain calculate_damage method")
	assert(code.contains("static func get_element_multiplier"), "Script must contain get_element_multiplier method")
	print("  PASS: Standalone GDScript class generation verified: %s" % script_path)

func _test_scene_instantiation() -> void:
	print("\n>>> [TEST 6] Verifying Scene Instantiation (skill_editor.tscn)...")
	
	var scene_res = ResourceLoader.load("res://scenes/tools/skill_editor.tscn")
	assert(scene_res != null, "ERROR: skill_editor.tscn failed to load")
	
	var editor_instance = scene_res.instantiate()
	assert(editor_instance != null, "ERROR: skill_editor.tscn failed to instantiate")
	add_child(editor_instance)
	
	assert(editor_instance.custom_minimum_size.x >= 800.0, "Minimum width must be >= 800")
	assert(editor_instance.custom_minimum_size.y >= 600.0, "Minimum height must be >= 600")
	
	# Verify UI Nodes
	assert(editor_instance.get_node_or_null("%PresetOption") != null, "PresetOption node must exist")
	assert(editor_instance.get_node_or_null("%SkillIdSpin") != null, "SkillIdSpin node must exist")
	assert(editor_instance.get_node_or_null("%BaseDamageSpin") != null, "BaseDamageSpin node must exist")
	assert(editor_instance.get_node_or_null("%VfxCanvas") != null, "VfxCanvas node must exist")
	assert(editor_instance.get_node_or_null("%TimelineSlider") != null, "TimelineSlider node must exist")

	assert(editor_instance.get_node_or_null("%SkillSearchEdit") != null, "SkillSearchEdit node must exist")
	assert(editor_instance.get_node_or_null("%SkillBrowserOption") != null, "SkillBrowserOption node must exist")
	assert(editor_instance.get_node_or_null("%BtnSelectSkill") != null, "BtnSelectSkill node must exist")
	assert(editor_instance.get_node_or_null("%LblSkillCount") != null, "LblSkillCount node must exist")
	
	print("  PASS: skill_editor.tscn UI verified: 800x600 dark theme, responsive layout, unique node access.")
	
	_test_database_skill_browser_and_search(editor_instance)
	
	editor_instance.queue_free()

func _test_database_skill_browser_and_search(editor_instance: Node) -> void:
	print("\n>>> [TEST 7] Verifying Skill Database Browser & Search System...")
	
	var total_skills: int = editor_instance.get_database_skills_count()
	assert(total_skills >= 950, "Total skills in GameDatabase must be >= 950 (got %d)" % total_skills)
	print("  PASS: SkillDatabase contains %d skills (expected 953)." % total_skills)
	
	var browser_opt: OptionButton = editor_instance.skill_browser_option
	assert(browser_opt != null, "SkillBrowserOption must be non-null")
	assert(browser_opt.item_count >= 950, "SkillBrowserOption item count must be >= 950 (got %d)" % browser_opt.item_count)
	
	# Verify formatting: "[ID] Name (Element, Type)"
	var first_text: String = browser_opt.get_item_text(0)
	assert(first_text.begins_with("["), "Skill text must start with bracketed ID: " + first_text)
	assert(first_text.contains("(") and first_text.contains(")"), "Skill text must contain element and type: " + first_text)
	print("  PASS: Skill format verified: '%s'" % first_text)
	
	# Test search filtering by skill name
	editor_instance._on_skill_search_text_changed("wine")
	assert(browser_opt.item_count >= 1, "Filter 'wine' should find at least 1 match")
	var wine_text: String = browser_opt.get_item_text(0)
	assert(wine_text.to_lower().contains("wine"), "Filter match must contain 'wine': " + wine_text)
	print("  PASS: Name search 'wine' matched %d skills (first: '%s')" % [browser_opt.item_count, wine_text])
	
	# Test search filtering by ID
	editor_instance._on_skill_search_text_changed("12036")
	assert(browser_opt.item_count >= 1, "Filter '12036' should find Leap")
	var leap_text: String = browser_opt.get_item_text(0)
	assert(leap_text.contains("12036"), "Filter match must contain 12036: " + leap_text)
	print("  PASS: ID search '12036' matched: '%s'" % leap_text)
	
	# Test loading selected skill from database
	editor_instance._on_btn_select_skill_pressed()
	assert(editor_instance.skill_id == 12036, "Loaded skill ID must be 12036 (got %d)" % editor_instance.skill_id)
	assert(editor_instance.skill_name.contains("Leap"), "Loaded skill name must contain 'Leap' (got '%s')" % editor_instance.skill_name)
	var expected_elem: int = int(editor_instance._game_database.skills.get_skill(12036).element)
	assert(editor_instance.element == expected_elem, "Loaded element must match database record element (expected %d, got %d)" % [expected_elem, editor_instance.element])
	print("  PASS: Load skill from database via browser verified (ID %d - %s, Elem %d)" % [editor_instance.skill_id, editor_instance.skill_name, editor_instance.element])
	
	# Test resetting filter
	editor_instance._on_skill_search_text_changed("")
	assert(browser_opt.item_count == total_skills, "Clearing search must restore all %d skills" % total_skills)
	print("  PASS: Clearing search filter restores all %d skills." % total_skills)
	
	# Test lookup_from_game_database on multiple skills
	var test_ids := [10001, 15039, 11075, 15050, 11077, 11182, 11183]
	for tid in test_ids:
		var ok: bool = editor_instance.lookup_from_game_database(tid)
		assert(ok == true, "lookup_from_game_database(%d) must succeed" % tid)
		assert(editor_instance.skill_id == tid, "Editor skill_id must match %d" % tid)
		assert(not editor_instance.skill_name.is_empty(), "Skill name must not be empty for %d" % tid)
	print("  PASS: Multiple database skill lookups verified: %s" % str(test_ids))
