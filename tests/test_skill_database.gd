extends SceneTree

## Automated test suite for SkillDatabase & SkillData.MBTM.
## Executes headlessly via: godot_console.exe --headless -s tests/test_skill_database.gd

func _init() -> void:
	print("==================================================================")
	print("=== Running Wonderland Online Skill Database Automated Tests   ===")
	print("==================================================================")
	
	# Determine data directory
	var data_dir := "D:/GitHub/WLRI/data"
	if not DirAccess.dir_exists_absolute(data_dir):
		data_dir = "res://assets/data"
	
	var skill_file := data_dir + "/Skill.dat"
	var mbtm_file := data_dir + "/SkillData.MBTM"
	
	print("[Test] Loading Skill.dat from: %s" % skill_file)
	print("[Test] Loading SkillData.MBTM from: %s" % mbtm_file)
	
	var db := SkillDatabase.new()
	var loaded := db.load_from_file(skill_file)
	assert(loaded, "Skill.dat must load successfully")
	print("PASS: Skill.dat loaded successfully.")
	
	var all_skills := db.get_all_skills()
	print("[Test] Total skills decoded: %d" % all_skills.size())
	assert(all_skills.size() >= 950, "Expected at least 950 skills, got %d" % all_skills.size())
	print("PASS: Total decoded skills count verified (>= 950).")
	
	# -------------------------------------------------------------
	# Test 1: Fundamental Skill Parsing (Hand Attack 10001)
	# -------------------------------------------------------------
	var hand_atk := db.get_skill(10001)
	assert(hand_atk != null, "Hand Attack 10001 must exist")
	assert(hand_atk.name == "Hand Attack", "Hand Attack name mismatch: '%s'" % hand_atk.name)
	assert(hand_atk.element == SkillDatabase.Element.NONE, "Hand Attack element must be NONE (0)")
	assert(hand_atk.skill_type == SkillDatabase.SkillType.PHYSICAL, "Hand Attack must be PHYSICAL")
	assert(hand_atk.sp_cost == 0, "Hand Attack SP cost must be 0")
	assert(hand_atk.base_damage == 0, "Hand Attack base damage must be 0")
	assert(hand_atk.target_scope == SkillDatabase.TargetScope.SINGLE, "Hand Attack target scope must be SINGLE")
	assert(hand_atk.animation_id == 60022, "Hand Attack animation ID must be 60022, got %d" % hand_atk.animation_id)
	print("PASS: Test 1 - Hand Attack (ID 10001) parsed bit-exact.")
	
	# -------------------------------------------------------------
	# Test 2: Element Classification (None=0, Earth=1, Water=2, Fire=3, Wind=4)
	# -------------------------------------------------------------
	var earth_skill := db.get_skill(15085) # Rock Attack
	assert(earth_skill != null and earth_skill.element == SkillDatabase.Element.EARTH, "Rock Attack must be Earth (1)")
	assert(earth_skill.element_name == "Earth", "Element name must be Earth")
	
	var water_skill := db.get_skill(15091) # Ice Attack
	assert(water_skill != null and water_skill.element == SkillDatabase.Element.WATER, "Ice Attack must be Water (2)")
	assert(water_skill.element_name == "Water", "Element name must be Water")
	
	var fire_skill := db.get_skill(15039) # Wine Flame
	assert(fire_skill != null and fire_skill.element == SkillDatabase.Element.FIRE, "Wine Flame must be Fire (3)")
	assert(fire_skill.element_name == "Fire", "Element name must be Fire")
	
	var wind_skill := db.get_skill(25269) # Wind Slash
	assert(wind_skill != null and wind_skill.element == SkillDatabase.Element.WIND, "Wind Slash must be Wind (4)")
	assert(wind_skill.element_name == "Wind", "Element name must be Wind")
	print("PASS: Test 2 - 4-Element classification verified (Earth=1, Water=2, Fire=3, Wind=4).")
	
	# -------------------------------------------------------------
	# Test 3: Skill Type Classification (Physical, Magic, Assist, Status, Special)
	# -------------------------------------------------------------
	var magic_skill := db.get_skill(10004) # Spell Attack
	assert(magic_skill != null and magic_skill.skill_type == SkillDatabase.SkillType.MAGIC, "Spell Attack must be Magic")
	
	var assist_skill := db.get_skill(11077) # Cure 2 Players
	assert(assist_skill != null and assist_skill.skill_type == SkillDatabase.SkillType.ASSIST, "Cure 2 Players must be Assist")
	
	var defense_skill := db.get_skill(60021) # Defense
	assert(defense_skill != null and defense_skill.skill_type == SkillDatabase.SkillType.SPECIAL, "Defense must be Special")
	print("PASS: Test 3 - Skill types verified (Physical, Magic, Assist, Special).")
	
	# -------------------------------------------------------------
	# Test 4: Target Scope Taxonomy (Single, Row, Column, Cross, All)
	# -------------------------------------------------------------
	var single_tgt := db.get_skill(12036) # Leap
	assert(single_tgt != null and single_tgt.target_scope == SkillDatabase.TargetScope.SINGLE, "Leap must be Single")
	assert(single_tgt.target_scope_name == "Single", "Scope name must be Single")
	
	var row_tgt := db.get_skill(11090) # Rockfall Hit (2 targets row)
	assert(row_tgt != null and row_tgt.target_scope == SkillDatabase.TargetScope.ROW, "Rockfall Hit must be Row")
	assert(row_tgt.target_scope_name == "Row", "Scope name must be Row")
	
	var col_tgt := db.get_skill(11092) # Rock Blast Beating (3 targets column)
	assert(col_tgt != null and col_tgt.target_scope == SkillDatabase.TargetScope.COLUMN, "Rock Blast Beating must be Column")
	assert(col_tgt.target_scope_name == "Column", "Scope name must be Column")
	
	var cross_tgt := db.get_skill(15108) # Blaze Beating (Cross area)
	assert(cross_tgt != null and cross_tgt.target_scope == SkillDatabase.TargetScope.CROSS, "Blaze Beating must be Cross")
	assert(cross_tgt.target_scope_name == "Cross", "Scope name must be Cross")
	
	var all_tgt := db.get_skill(11041) # Arrow Rain (All enemies)
	assert(all_tgt != null and all_tgt.target_scope == SkillDatabase.TargetScope.ALL, "Arrow Rain must be All")
	assert(all_tgt.target_scope_name == "All", "Scope name must be All")
	print("PASS: Test 4 - Target Scope taxonomy verified (Single, Row, Column, Cross, All).")
	
	# -------------------------------------------------------------
	# Test 5: Base Damage & SP Progression
	# -------------------------------------------------------------
	var r_atk := db.get_skill(15085) # Rock Attack: SP=7, BaseDmg=7
	var r_hit := db.get_skill(11085) # Rock Hit: SP=8, BaseDmg=14
	var r_beat := db.get_skill(15074) # Rock Beating: SP=11, BaseDmg=25
	assert(r_atk.sp_cost == 7 and r_atk.base_damage == 7, "Rock Attack stats mismatch")
	assert(r_hit.sp_cost == 8 and r_hit.base_damage == 14, "Rock Hit stats mismatch")
	assert(r_beat.sp_cost == 11 and r_beat.base_damage == 25, "Rock Beating stats mismatch")
	print("PASS: Test 5 - SP cost and Base Damage scaling verified.")
	
	# -------------------------------------------------------------
	# Test 6: SkillData.MBTM Integration (1829 Motion Timeline Records)
	# -------------------------------------------------------------
	var mbtm_loaded := db.load_mbtm_from_file(mbtm_file)
	assert(mbtm_loaded, "SkillData.MBTM must load successfully")
	assert(db.get_mbtm_count() == 1829, "SkillData.MBTM must contain exactly 1829 entries, got %d" % db.get_mbtm_count())
	
	assert(db.has_mbtm_entry(12036), "Betty Leap (12036) must have MBTM motion timeline")
	var leap_entry := db.get_mbtm_entry(12036)
	assert(leap_entry["length"] == 691, "Betty Leap payload length must be 691, got %d" % leap_entry["length"])
	
	var leap_payload := db.get_mbtm_payload(12036)
	assert(leap_payload.size() == 691, "Betty Leap payload size must match entry length")
	print("PASS: Test 6 - SkillData.MBTM binary index and payload extraction verified (1829 entries).")
	
	# -------------------------------------------------------------
	# Test 7: Starter Skill Assignments for all 14 Playable Roles
	# -------------------------------------------------------------
	var expected_stunts: Dictionary = {
		1: {"name": "Wine Flame", "id": 15039, "anim": 60010, "sp": 9, "dmg": 40},
		2: {"name": "Leap", "id": 12036, "anim": 60005, "sp": 9, "dmg": 38},
		3: {"name": "Summon Dogs Groups", "id": 11075, "anim": 60001, "sp": 18, "dmg": 50},
		4: {"name": "Recover Normal", "id": 15042, "anim": 11055, "sp": 179, "dmg": 50},
		5: {"name": "Love Wish", "id": 15041, "anim": 60012, "sp": 10, "dmg": 24},
		6: {"name": "Overarm Stumble", "id": 15038, "anim": 60009, "sp": 8, "dmg": 35},
		7: {"name": "Combo x3 Attack", "id": 11076, "anim": 60002, "sp": 9, "dmg": 38},
		8: {"name": "Hagendis Attack", "id": 15044, "anim": 12047, "sp": 41, "dmg": 93},
		9: {"name": "Hagendis Beating", "id": 15045, "anim": 12047, "sp": 67, "dmg": 139},
		10: {"name": "Bomber Attack", "id": 11078, "anim": 60004, "sp": 20, "dmg": 90},
		11: {"name": "Cure 2 Players", "id": 11077, "anim": 60003, "sp": 8, "dmg": 45},
		12: {"name": "Deacon Attack", "id": 11183, "anim": 60009, "sp": 7, "dmg": 28},
		13: {"name": "Ghost Hammer", "id": 11182, "anim": 10018, "sp": 9, "dmg": 38},
		14: {"name": "Palm", "id": 15040, "anim": 60011, "sp": 7, "dmg": 28}
	}
	
	for role_id in range(1, 15):
		var exp_info: Dictionary = expected_stunts[role_id]
		var stunt: SkillDatabase.SkillRecord = db.get_starter_skill_for_role(role_id)
		assert(stunt != null, "Role %d stunt must exist" % role_id)
		assert(stunt.name == exp_info["name"], "Role %d name mismatch: expected '%s', got '%s'" % [role_id, exp_info["name"], stunt.name])
		assert(stunt.animation_id == exp_info["anim"], "Role %d anim mismatch: expected %d, got %d" % [role_id, exp_info["anim"], stunt.animation_id])
		assert(stunt.sp_cost == exp_info["sp"], "Role %d SP mismatch: expected %d, got %d" % [role_id, exp_info["sp"], stunt.sp_cost])
		assert(stunt.base_damage == exp_info["dmg"], "Role %d Damage mismatch: expected %d, got %d" % [role_id, exp_info["dmg"], stunt.base_damage])
		assert(db.has_mbtm_entry(stunt.id), "Role %d stunt (%d) must have MBTM animation entry" % [role_id, stunt.id])
		
		# Test loadout contains Hand Attack 10001 and the role stunt
		var loadout := db.get_starter_skills_for_role(role_id)
		assert(loadout.size() == 2, "Role %d starter loadout must contain 2 skills" % role_id)
		assert(loadout[0].id == 10001, "Role %d first skill must be Hand Attack" % role_id)
		assert(loadout[1].id == stunt.id, "Role %d second skill must be stunt" % role_id)
	
	print("PASS: Test 7 - All 14 playable role starter stunt skills and loadouts verified bit-exact.")
	
	# -------------------------------------------------------------
	# Test 8: Betty Wind Leap Stunt Specific Verification
	# -------------------------------------------------------------
	var betty_stunt := db.get_starter_skill_for_role(2)
	assert(betty_stunt.id == 12036, "Betty starter stunt must be 12036")
	assert(betty_stunt.name == "Leap", "Betty stunt name must be Leap")
	assert(betty_stunt.sp_cost == 9, "Betty Leap SP cost must be 9")
	assert(betty_stunt.base_damage == 38, "Betty Leap base damage must be 38")
	assert(betty_stunt.animation_id == 60005, "Betty Leap animation ID must be 60005")
	assert(db.has_mbtm_entry(12036), "Betty Leap must have MBTM entry")
	print("PASS: Test 8 - Betty Wind Leap stunt (12036) specifically verified.")
	
	# -------------------------------------------------------------
	# Test 9: GameDatabase Autoload Singleton Integration
	# -------------------------------------------------------------
	var gd_cls = load("res://scripts/database/game_database.gd")
	var g_db = gd_cls.new()
	g_db.load_all()
	assert(g_db.skills != null, "GameDatabase.skills must be initialized")
	assert(g_db.skills.get_all_skills().size() >= 950, "GameDatabase.skills must contain >= 950 skills")
	
	var gd_betty_skill = g_db.get_skill(12036)
	assert(gd_betty_skill != null and gd_betty_skill.name == "Leap", "GameDatabase.get_skill(12036) must return Leap")
	
	var gd_betty_stunt = g_db.get_starter_stunt_for_role(2)
	assert(gd_betty_stunt != null and gd_betty_stunt.id == 12036, "GameDatabase.get_starter_stunt_for_role(2) must return 12036")
	
	var gd_betty_loadout = g_db.get_starter_skills_for_role(2)
	assert(gd_betty_loadout.size() == 2, "GameDatabase starter skills for Betty must have 2 skills")
	print("PASS: Test 9 - GameDatabase autoload coordinator integration verified.")
	
	print("==================================================================")
	print("=== ALL SKILL DATABASE TESTS PASSED SUCCESSFULLY (9/9)       ===")
	print("==================================================================")
	quit(0)
