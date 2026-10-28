extends SceneTree

const NpcDatabase = preload("res://scripts/database/npc_database.gd")

func _init() -> void:
	print("==================================================")
	print("[TEST] Running Wonderland Online NPC Database Test")
	print("==================================================")
	
	var db := NpcDatabase.new()
	var ok := db.load_from_file("res://assets/data/all_npcs.json")
	if not ok:
		print("FAIL: Failed to load all_npcs.json")
		quit(1)
		return
	
	print("[PASS] Successfully loaded NPC database. Total records: %d" % db.get_total_npcs())
	assert(db.get_total_npcs() >= 4929, "Expected at least 4,929 NPC templates")
	
	# 1. Test key story / town NPC resolution
	var robinson := db.get_npc(14003)
	assert(robinson != null, "Captain Robinson (14003) must exist")
	print("[PASS] 14003: %s | Sprite: %d (%s) | Lvl: %d | HP: %d | Spawns: %d" % [
		robinson.name, robinson.sprite_id, robinson.model_jmp, robinson.level, robinson.max_hp, robinson.maps_present.size()
	])
	assert(robinson.name == "Captain Robinson", "Name must be Captain Robinson")
	assert(robinson.sprite_id == 1038, "Sprite must be 1038")
	assert(robinson.model_jmp == "1038.jmp", "Model JMP must be 1038.jmp")
	
	var jack := db.get_npc(14091)
	assert(jack != null, "Jack (14091) must exist")
	print("[PASS] 14091: %s | Sprite: %d (%s) | Lvl: %d | HP: %d | Spawns: %d" % [
		jack.name, jack.sprite_id, jack.model_jmp, jack.level, jack.max_hp, jack.maps_present.size()
	])
	assert(jack.name == "Jack", "Name must be Jack")
	assert(jack.sprite_id == 1010, "Sprite must be 1010")
	
	var ross := db.get_npc(14152)
	assert(ross != null, "Ross (14152) must exist")
	print("[PASS] 14152: %s | Sprite: %d (%s) | Lvl: %d | HP: %d | Spawns: %d" % [
		ross.name, ross.sprite_id, ross.model_jmp, ross.level, ross.max_hp, ross.maps_present.size()
	])
	assert(ross.name == "Ross", "Name must be Ross")
	assert(ross.sprite_id == 1207, "Sprite must be 1207")

	var natasha := db.get_npc(14303)
	assert(natasha != null, "Natasha (14303) must exist")
	print("[PASS] 14303: %s | Sprite: %d (%s) | Lvl: %d | HP: %d | Spawns: %d" % [
		natasha.name, natasha.sprite_id, natasha.model_jmp, natasha.level, natasha.max_hp, natasha.maps_present.size()
	])
	assert(natasha.name == "Natasha", "Name must be Natasha")
	assert(natasha.sprite_id == 1068, "Sprite must be 1068")

	# 2. Test get_npcs_by_name
	var captains := db.get_npcs_by_name("Captain Robinson")
	assert(not captains.is_empty(), "Must find Captain Robinson by name query")
	print("[PASS] get_npcs_by_name('Captain Robinson'): found %d record(s)" % captains.size())

	var jacks := db.get_npcs_by_name("Jack")
	assert(not jacks.is_empty(), "Must find Jack by name query")
	print("[PASS] get_npcs_by_name('Jack'): found %d record(s)" % jacks.size())

	# 3. Test get_npcs_by_sprite
	var kelan_sprites := db.get_npcs_by_sprite(1131)
	assert(not kelan_sprites.is_empty(), "Must find NPCs with sprite 1131")
	print("[PASS] get_npcs_by_sprite(1131): found %d record(s)" % kelan_sprites.size())

	# 4. Test map spawns lookup for Map 10001 (Ship Deck)
	var deck_npcs := db.get_npcs_on_map(10001)
	print("[PASS] get_npcs_on_map(10001): found %d unique NPC templates on Ship Deck" % deck_npcs.size())
	assert(deck_npcs.size() >= 5, "Ship deck must have at least 5 NPC templates")

	# 5. Test monsters query
	var monsters := db.get_monsters()
	print("[PASS] get_monsters(): found %d combat monster templates" % monsters.size())
	assert(monsters.size() >= 1000, "Expected at least 1,000 monster templates")

	# 6. Test binary Npc.dat decoding fallback
	var bin_db := NpcDatabase.new()
	var bin_ok := bin_db._load_from_dat("D:/GitHub/WLRI/data/Npc.dat")
	assert(bin_ok, "Binary decoding of Npc.dat must succeed")
	print("[PASS] Binary fallback loaded %d templates from Npc.dat" % bin_db.get_total_npcs())
	var bin_breillat := bin_db.get_npc(10000)
	assert(bin_breillat != null and bin_breillat.name == "Breillat", "Binary Breillat must decode")
	assert(bin_breillat.max_hp == 36, "Binary Breillat HP must be 36")
	assert(bin_breillat.sprite_id == 1170, "Binary Breillat sprite must be 1170")
	print("[PASS] Binary record 10000 matches bit-exact specs: %s (HP: %d, Sprite: %d)" % [
		bin_breillat.name, bin_breillat.max_hp, bin_breillat.sprite_id
	])

	print("==================================================")
	print("[ALL TESTS PASSED] Wonderland Online NPC Database Verified!")
	print("==================================================")
	quit(0)
