extends Node

func _ready():
	print("=== Running Map 10001 (Ship Deck) Parity Verification ===")
	
	# 1. Verify Map 10001 Scene Record
	var scene_db = SceneDatabase.new()
	var success = scene_db.load_from_file("res://assets/data/SceneData.dat")
	if success:
		var scene = scene_db.get_scene(10001)
		if scene:
			print("Map 10001 found in SceneData.dat: Name = %s, BGM = %s (ID: %d)" % [scene.name, scene.bgm_name, scene.bgm_id])
		else:
			print("WARNING: Map 10001 not found in SceneData.dat.")
	else:
		print("SceneData.dat could not be loaded directly.")

	# 2. Check Map Data files for 10001
	var map_ground_path = "res://assets/map/10001.map"
	var map_eve_path = "res://assets/map/10001.eve"
	print("Map ground file exists (%s): %s" % [map_ground_path, FileAccess.file_exists(map_ground_path)])
	print("Map eve file exists (%s): %s" % [map_eve_path, FileAccess.file_exists(map_eve_path)])
	
	if FileAccess.file_exists(map_ground_path):
		var map_data = MapData.new()
		if map_data.load_map(10001):
			print("Map 10001 loaded successfully via MapData. Width: %d, Height: %d" % [map_data.width, map_data.height])
		else:
			print("Failed to load map 10001 via MapData.")

	# 3. Check NPC database for ship deck NPCs
	var npc_db = NpcDatabase.new()
	if npc_db.load_from_file("res://assets/data/NpcData.dat"):
		print("NpcData.dat loaded successfully. Total records: %d" % npc_db.get_all_npcs().size())
	else:
		print("Failed to load NpcData.dat")

	print("=== Map 10001 Parity Verification Complete ===")
	get_tree().quit()
