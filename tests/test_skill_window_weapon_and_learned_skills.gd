class_name TestSkillWindowWeaponAndLearnedSkills
extends SceneTree

const SkillWindowClass = preload("res://scripts/ui/hud/skill_window.gd")
const SkillDatabaseScript = preload("res://scripts/database/skill_database.gd")

func _init() -> void:
	print("\n=================================================================")
	print("--- Running TestSkillWindowWeaponAndLearnedSkills ---")
	print("=================================================================\n")

	_test_database_weapon_and_proficiency_decoding()
	_test_skill_window_detail_weapon_and_proficiency_display()
	_test_learned_skills_model_and_filtering()

	print("\n=================================================================")
	print("--- ALL SKILL WEAPON & LEARNED SKILLS TESTS PASSED (100%) ---")
	print("=================================================================\n")
	quit(0)

func _test_database_weapon_and_proficiency_decoding() -> void:
	print(">>> [TEST 1] Verifying database weapon requirement & proficiency decoding...")
	var db := SkillDatabaseScript.new()
	var loaded := db.load_from_file("res://assets/data/Skill.dat")
	assert(loaded, "Skill.dat must be loaded successfully")

	# Check Hand Attack (10001)
	var hand_skill = db.get_skill(10001)
	assert(hand_skill != null, "Skill 10001 must exist")
	assert(hand_skill.weapon_requirement in ["Barehanded", "Any"], "Hand Attack must require Barehanded/Any, got %s" % hand_skill.weapon_requirement)
	assert(hand_skill.proficiency_required >= 1, "Hand Attack proficiency must be >= 1")

	# Check Blade Attack (10002) or Sword Attack (10005)
	var sword_skill = db.get_skill(10005)
	assert(sword_skill != null, "Skill 10005 must exist")
	assert(sword_skill.weapon_requirement == "Sword", "Sword Attack must require Sword, got %s" % sword_skill.weapon_requirement)

	# Check Bow Attack (10006)
	var bow_skill = db.get_skill(10006)
	assert(bow_skill != null, "Skill 10006 must exist")
	assert(bow_skill.weapon_requirement == "Bow", "Bow Attack must require Bow, got %s" % bow_skill.weapon_requirement)

	# Check Spell Attack (10004)
	var spell_skill = db.get_skill(10004)
	assert(spell_skill != null, "Skill 10004 must exist")
	assert(spell_skill.weapon_requirement == "Staff", "Spell Attack must require Staff, got %s" % spell_skill.weapon_requirement)

	# Check dictionary output has required fields
	var d := sword_skill.to_dict()
	assert(d.has("weapon_requirement"), "to_dict must contain weapon_requirement")
	assert(d.has("proficiency_required"), "to_dict must contain proficiency_required")
	assert(d.get("weapon_requirement") == "Sword", "Dict weapon_requirement must be Sword")

	print("  [PASS] Database weapon requirement and proficiency decoding verified.")

func _test_skill_window_detail_weapon_and_proficiency_display() -> void:
	print(">>> [TEST 2] Verifying SkillWindow detail panel weapon & proficiency display...")
	var win = SkillWindowClass.new()
	root.add_child(win)
	win._ready()

	# Select Sword Attack (10005) if available, or simulate selection
	var test_sword := {
		"id": 10005,
		"name": "Sword Attack",
		"element_name": "None",
		"skill_type_name": "Physical",
		"target_scope_name": "Single",
		"sp_cost": 0,
		"base_damage": 50,
		"damage_multiplier_1": 1.0,
		"rank": 1,
		"proficiency_required": 1,
		"weapon_requirement": "Sword"
	}

	win._update_detail_panel(test_sword)
	assert(win.detail_weapon_label != null, "detail_weapon_label must exist")
	assert(win.detail_weapon_label.text == "Sword", "Weapon label must display 'Sword', got '%s'" % win.detail_weapon_label.text)
	assert(win.detail_proficiency_label != null, "detail_proficiency_label must exist")
	assert(win.detail_proficiency_label.text == "Grade 1", "Proficiency label must display 'Grade 1', got '%s'" % win.detail_proficiency_label.text)

	# Test Bow skill
	var test_bow := {
		"id": 10006,
		"name": "Bow Attack",
		"element_name": "None",
		"skill_type_name": "Physical",
		"target_scope_name": "Single",
		"sp_cost": 0,
		"base_damage": 50,
		"damage_multiplier_1": 1.0,
		"rank": 2,
		"proficiency_required": 2,
		"weapon_requirement": "Bow"
	}
	win._update_detail_panel(test_bow)
	assert(win.detail_weapon_label.text == "Bow", "Weapon label must display 'Bow'")
	assert(win.detail_proficiency_label.text == "Grade 2", "Proficiency label must display 'Grade 2'")

	print("  [PASS] SkillWindow detail panel display verified.")
	win.queue_free()

func _test_learned_skills_model_and_filtering() -> void:
	print(">>> [TEST 3] Verifying learned skills model, methods, and filtering...")
	var win = SkillWindowClass.new()
	root.add_child(win)
	win._ready()

	# Test default learned skills initialization
	win.init_default_learned_skills(6, 3) # Daniel (Role 6), Fire (3)
	assert(win.is_skill_learned(10001), "Hand Attack (10001) must be learned by default")
	assert(win.is_skill_learned(60021), "Defense (60021) must be learned by default")
	assert(win.is_skill_learned(60041), "Flee (60041) must be learned by default")
	assert(win.is_skill_learned(15038), "Overarm Stumble (15038) must be learned by default for Daniel")
	assert(win.is_skill_learned(13001), "Fire Ball (13001) must be learned for Fire element")
	assert(not win.is_skill_learned(99999), "Unlearned skill must return false")

	# Test learning and unlearning skills
	win.learn_skill(12345)
	assert(win.is_skill_learned(12345), "Skill 12345 should be learned")
	win.unlearn_skill(12345)
	assert(not win.is_skill_learned(12345), "Skill 12345 should be unlearned")

	# Test learned_skills_only filtering
	win.select_tab(0) # Physical
	var total_physical_skills: int = win._displayed_skills.size()
	assert(total_physical_skills > 0, "Must have physical skills listed in full view")

	# Enable learned skills filter mode
	win.set_learned_skills_only(true)
	var learned_physical_skills: int = win._displayed_skills.size()
	assert(learned_physical_skills > 0, "Must have learned physical skills")
	assert(learned_physical_skills < total_physical_skills, "Learned skills count (%d) must be fewer than all database skills (%d)" % [learned_physical_skills, total_physical_skills])

	for skill in win._displayed_skills:
		var sid: int = int(skill.get("id", 0))
		assert(win.is_skill_learned(sid), "Skill %d in list must be in learned skills set" % sid)

	# Disable learned skills filter mode
	win.set_learned_skills_only(false)
	assert(win._displayed_skills.size() == total_physical_skills, "Full list must be restored when filter is disabled")

	print("  [PASS] Learned skills model and filtering verified.")
	win.queue_free()
