extends Node

var frames_rendered := 0
var map_view: Node = null

func _ready() -> void:
	print("--- Running In-Engine Screen Capture ---")
	map_view = preload("res://scenes/world/map_view.tscn").instantiate()
	add_child(map_view)

func _process(_delta: float) -> void:
	frames_rendered += 1
	
	# Capture 1: Ship Deck World with NPCs (CharacterWindow closed)
	if frames_rendered == 6:
		var img: Image = get_viewport().get_texture().get_image()
		var out1 := "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/godot_deck_world.png"
		img.save_png(out1)
		print("[PASS] Saved world capture to: ", out1)
		
		# Now open CharacterWindow for Capture 2
		var hud = map_view.get_node("CanvasLayer/HUD")
		if hud and hud.has_method("toggle_character_status"):
			hud.toggle_character_status()
	
	# Capture 2: CharacterWindow open with paper doll and inventory grid
	if frames_rendered == 12:
		var img: Image = get_viewport().get_texture().get_image()
		var out2 := "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/godot_deck_with_charwin.png"
		img.save_png(out2)
		print("[PASS] Saved CharacterWindow capture to: ", out2)
		
		# Close CharacterWindow and move camera to Cabin Portal
		var hud = map_view.get_node("CanvasLayer/HUD")
		if hud and hud.has_method("toggle_character_status"):
			hud.toggle_character_status()
		var player = map_view.get_node("Entities/Player")
		if player:
			player.world_position = Vector2(1750, 920)
			map_view._update_camera_to_player()
	
	# Capture 3: Cabin Portal with DoorLight animation
	if frames_rendered == 18:
		var img: Image = get_viewport().get_texture().get_image()
		var out3 := "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/godot_deck_portal.png"
		img.save_png(out3)
		print("[PASS] Saved Portal capture to: ", out3)
		
		# Trigger portal to enter Cabin (Map 10002)
		var portal = map_view.get_node("Entities/CabinPortal")
		if portal and map_view.has_method("_on_portal_triggered"):
			map_view._on_portal_triggered(portal, 10002, Vector2(674, 1067))
	
	# Capture 4: Cabin Interior (Map 10002)
	if frames_rendered == 24:
		var img: Image = get_viewport().get_texture().get_image()
		var out4 := "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986/godot_cabin_world.png"
		img.save_png(out4)
		print("[PASS] Saved Cabin capture to: ", out4)
		get_tree().quit(0)
