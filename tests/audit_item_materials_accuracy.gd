extends SceneTree

func _init() -> void:
	print("=== Running Item Database Material Audit ===")
	
	var db := ItemDatabase.new()
	var loaded := db.load_from_file("res://assets/data/Item.dat")
	if not loaded:
		print("Failed to load Item.dat from res://, trying absolute path...")
		loaded = db.load_from_file("D:/Godot/WonderlandOnline/wonderland-online-client/assets/data/Item.dat")
	
	var all_items := db.get_all_items()
	var total_items := all_items.size()
	print("Total loaded items in ItemDatabase: %d" % total_items)
	
	var misc_count := 0
	var valid_mat_count := 0
	var multi_mat_count := 0
	var pure_mat_count := 0
	
	var equip_weapons := 0
	var equip_weapons_valid := 0
	var equip_armors := 0
	var equip_armors_valid := 0
	var consumables := 0
	var consumables_misc := 0
	
	var material_dist := {}
	
	for item_id: int in all_items:
		var item: ItemDatabase.ItemRecord = all_items[item_id]
		var mats := item.get_materials()
		var mat_name := item.get_material_name()
		
		if mat_name == "Misc" or mats.is_empty() or (mats.size() == 1 and mats[0] == "Misc"):
			misc_count += 1
		else:
			valid_mat_count += 1
			for m in mats:
				material_dist[m] = material_dist.get(m, 0) + 1
			if mats.size() > 1:
				multi_mat_count += 1
			else:
				pure_mat_count += 1
		
		if item.equip_pos == 3: # Weapon
			equip_weapons += 1
			if mat_name != "Misc":
				equip_weapons_valid += 1
		elif item.equip_pos in [1, 2, 4, 5, 6]: # Armor / Equipment
			equip_armors += 1
			if mat_name != "Misc":
				equip_armors_valid += 1
		elif item.equip_pos in [7, 8] or item.item_type in [21, 22, 23]:
			consumables += 1
			if mat_name == "Misc":
				consumables_misc += 1
	
	print("\n--- Current Heuristic Resolution Statistics ---")
	print("Total items: %d" % total_items)
	print("Items with valid resolved materials: %d (%.2f%%)" % [valid_mat_count, float(valid_mat_count) / float(total_items) * 100.0])
	print("Items falling back to 'Misc': %d (%.2f%%)" % [misc_count, float(misc_count) / float(total_items) * 100.0])
	print("Multi-material composite items: %d (%.2f%%)" % [multi_mat_count, float(multi_mat_count) / float(total_items) * 100.0])
	print("Single material items: %d (%.2f%%)" % [pure_mat_count, float(pure_mat_count) / float(total_items) * 100.0])
	print("Weapons with valid material: %d / %d (%.2f%%)" % [equip_weapons_valid, equip_weapons, float(equip_weapons_valid) / float(maxi(1, equip_weapons)) * 100.0])
	print("Armors/Accessories with valid material: %d / %d (%.2f%%)" % [equip_armors_valid, equip_armors, float(equip_armors_valid) / float(maxi(1, equip_armors)) * 100.0])
	print("Consumables defaulting to 'Misc': %d / %d (%.2f%%)" % [consumables_misc, consumables, float(consumables_misc) / float(maxi(1, consumables)) * 100.0])
	
	print("\nTop 15 resolved material categories in ItemDatabase:")
	var sorted_mats := []
	for m in material_dist:
		sorted_mats.append({"name": m, "count": material_dist[m]})
	sorted_mats.sort_custom(func(a, b): return a["count"] > b["count"])
	for i in range(mini(15, sorted_mats.size())):
		print("  %s: %d" % [sorted_mats[i]["name"], sorted_mats[i]["count"]])
	
	quit()
