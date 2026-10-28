extends SceneTree

func _init() -> void:
	var mv_scene = preload("res://scenes/world/map_view.tscn")
	var mv: MapView = mv_scene.instantiate()
	root.add_child(mv)
	
	# Load map 10002
	var mr = mv.get_node("MapRenderer")
	mr.load_map(10002)
	mv._switch_map_entities(10002)
	
	# Wait a frame or process
	for i in range(5):
		mv._process(0.016)
		for c in mv.entities.get_children():
			if c.has_method("_process"):
				c._process(0.016)
	
	# Check where NPCs are
	print("Checking Cabin NPCs:")
	for c in mv.entities.get_children():
		if c is NpcEntity:
			print("NPC: %s, pos=%s, z_index=%d, visible=%s, sprite_tex=%s" % [
				c.npc_name, c.world_position, c.z_index, c.visible,
				c.sprite.texture != null if c.sprite else false
			])
	
	quit(0)
