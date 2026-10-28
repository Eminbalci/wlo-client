extends SceneTree

## Visual Flow Inspector & Interactive Test Runner
## Executes the complete interactive sequence, clicks buttons, verifies Daniel (Level 1, Fire) vs Betty,
## toggles character and inventory HUD windows, and captures screenshots to the required artifact directory.

const ARTIFACT_DIR = "C:/Users/muham/.gemini/antigravity-cli/brain/c43cf149-bb6e-436c-95e5-06c734294986"

func _init() -> void:
	print("=================================================================")
	print("--- Starting Visual Flow & Live Screenshot Inspector ---")
	print("=================================================================\n")
	
	var root_node = Node2D.new()
	root.add_child(root_node)
	
	var dir = DirAccess.open("C:/Users/muham/.gemini/antigravity-cli/brain")
	if dir == null:
		DirAccess.make_dir_recursive_absolute(ARTIFACT_DIR)
	
	run_visual_flow_sequence(root_node)

func run_visual_flow_sequence(parent: Node) -> void:
	print("[STEP 1] Loading Server Selection Screen...")
	var server_sel_scene = load("res://scenes/ui/auth/server_select.tscn")
	assert(server_sel_scene != null, "ERROR: server_select.tscn could not be loaded")
	var server_node = server_sel_scene.instantiate()
	parent.add_child(server_node)
	
	for i in range(5):
		await process_frame
	capture_viewport_screenshot("visual_flow_01_server_select.png")
	
	print("[ACTION] Clicking Confirm / Channel button...")
	var confirm_btn = find_node_by_class(server_node, "Button")
	if confirm_btn:
		confirm_btn.emit_signal("pressed")
	server_node.queue_free()
	
	print("[STEP 2] Loading Login Dialog Screen...")
	var login_scene = load("res://scenes/ui/auth/login_dialog.tscn")
	assert(login_scene != null, "ERROR: login_dialog.tscn could not be loaded")
	var login_node = login_scene.instantiate()
	parent.add_child(login_node)
	
	for i in range(5):
		await process_frame
	capture_viewport_screenshot("visual_flow_02_login_dialog.png")
	
	print("[ACTION] Clicking Login Game / Offline button with account 'player1'...")
	var line_edits = find_all_nodes_by_class(login_node, "LineEdit")
	for le in line_edits:
		if "user" in le.name.to_lower() or "account" in le.name.to_lower():
			le.text = "player1"
	var login_btn = find_button_by_text(login_node, "Login")
	if login_btn == null:
		login_btn = find_node_by_class(login_node, "Button")
	if login_btn:
		login_btn.emit_signal("pressed")
	login_node.queue_free()
	
	print("[STEP 3] Loading Character Selection Screen...")
	var char_sel_scene = load("res://scenes/ui/auth/character_select.tscn")
	assert(char_sel_scene != null, "ERROR: character_select.tscn could not be loaded")
	var char_sel_node = char_sel_scene.instantiate()
	parent.add_child(char_sel_node)
	
	for i in range(5):
		await process_frame
	capture_viewport_screenshot("visual_flow_03_char_select.png")
	
	print("[ACTION] Clicking 'Create Character' button...")
	var create_btn = find_button_by_text(char_sel_node, "Create")
	if create_btn == null:
		create_btn = find_node_by_class(char_sel_node, "Button")
	if create_btn:
		create_btn.emit_signal("pressed")
	
	print("[STEP 4] Loading Character Create Step 1 (Standees carousel)...")
	var char_create_scene = load("res://scenes/ui/auth/character_create.tscn")
	assert(char_create_scene != null, "ERROR: character_create.tscn could not be loaded")
	var char_create_node = char_create_scene.instantiate()
	parent.add_child(char_create_node)
	
	for i in range(5):
		await process_frame
	capture_viewport_screenshot("visual_flow_04_char_create_standees.png")
	
	print("[ACTION] Inspecting standees and clicking Cancel to return to Character Select...")
	var cancel_btn = find_button_by_text(char_create_node, "Cancel")
	if cancel_btn:
		cancel_btn.emit_signal("pressed")
	char_create_node.queue_free()
	char_sel_node.queue_free()
	
	print("[STEP 5] Setting active character to Daniel (Role 6, Fire, Level 1) in GameDatabase...")
	var daniel_data: Dictionary = {
		"slot_index": 0,
		"name": "Daniel",
		"role_id": 6,
		"role_name": "Daniel",
		"element": "Fire",
		"level": 1,
		"hp": 190,
		"max_hp": 190,
		"sp": 124,
		"max_sp": 124,
		"str": 12,
		"con": 10,
		"int": 8,
		"wis": 8,
		"agi": 10,
		"gold": 500,
		"exp": 0,
		"max_exp": 10000
	}
	var gdb = root.get_node_or_null("/root/GameDatabase")
	if gdb:
		gdb.active_character = daniel_data
	
	print("[STEP 6] Loading MapView (Map 10001 Ship Deck) with authentic PlayerEntity & HUD...")
	var map_view_scene = load("res://scenes/world/map_view.tscn")
	assert(map_view_scene != null, "ERROR: map_view.tscn could not be loaded")
	var map_view_node = map_view_scene.instantiate()
	parent.add_child(map_view_node)
	
	for i in range(10):
		await process_frame
	capture_viewport_screenshot("visual_flow_05_ship_deck.png")
	
	var hud = map_view_node.get_node_or_null("CanvasLayer/HUD")
	assert(hud != null, "ERROR: HUD node not found in map_view")
	
	print("[ACTION] Toggling Character Status and Inventory windows...")
	if hud.has_method("toggle_character_status"):
		hud.toggle_character_status()
	if hud.has_method("toggle_inventory"):
		hud.toggle_inventory()
	
	for i in range(10):
		await process_frame
	
	print("[STEP 7] Capturing Character & Inventory Window open verification...")
	capture_viewport_screenshot("visual_flow_06_inventory_character_match.png")
	
	# Verify that Character window displays Daniel's exact stats and name (NOT Betty!)
	var stat_name = hud.get_node_or_null("FloatingWindows/CharacterWindow/StatName") as Label
	var stat_elem = hud.get_node_or_null("FloatingWindows/CharacterWindow/StatElement") as Label
	var stat_lvl = hud.get_node_or_null("FloatingWindows/CharacterWindow/StatLevel") as Label
	var stat_hp = hud.get_node_or_null("FloatingWindows/CharacterWindow/StatLeftHp") as Label
	var stat_sp = hud.get_node_or_null("FloatingWindows/CharacterWindow/StatLeftSp") as Label
	var paper_doll = hud.get_node_or_null("FloatingWindows/CharacterWindow/PaperDoll") as TextureRect
	
	print("[VERIFICATION] Character Window Data:")
	if stat_name: print("  -> Name: '%s' (Expected: Daniel)" % stat_name.text)
	if stat_elem: print("  -> Element: '%s' (Expected: Fire)" % stat_elem.text)
	if stat_lvl: print("  -> Level: '%s' (Expected: 1)" % stat_lvl.text)
	if stat_hp: print("  -> HP: '%s' (Expected: 190 / 190)" % stat_hp.text)
	if stat_sp: print("  -> SP: '%s' (Expected: 124 / 124)" % stat_sp.text)
	if paper_doll: print("  -> PaperDoll Texture: %s" % ("Present" if paper_doll.texture != null else "Missing"))
	
	assert(stat_name != null and stat_name.text == "Daniel", "ERROR: Character window name mismatch! Found: " + str(stat_name.text if stat_name else "null"))
	assert(stat_elem != null and stat_elem.text == "Fire", "ERROR: Character window element mismatch! Found: " + str(stat_elem.text if stat_elem else "null"))
	assert(stat_lvl != null and stat_lvl.text == "1", "ERROR: Character window level mismatch! Found: " + str(stat_lvl.text if stat_lvl else "null"))
	assert(paper_doll != null and paper_doll.texture != null, "ERROR: Character PaperDoll texture is null!")
	
	print("\n=================================================================")
	print("--- ALL VISUAL FLOW INSPECTION STEPS COMPLETED SUCCESSFULLY ---")
	print("=================================================================\n")
	quit(0)

func capture_viewport_screenshot(filename: String) -> void:
	var vp = root.get_viewport()
	if vp == null:
		print("ERROR: Viewport is null, cannot capture screenshot: " + filename)
		return
	var img = vp.get_texture().get_image()
	if img != null:
		var path = ARTIFACT_DIR + "/" + filename
		img.save_png(path)
		print("  -> Saved screenshot: " + path)
	else:
		print("ERROR: Failed to retrieve image from viewport for " + filename)

func find_node_by_class(node: Node, class_name_str: String) -> Node:
	if node.is_class(class_name_str):
		return node
	for child in node.get_children():
		var found = find_node_by_class(child, class_name_str)
		if found != null:
			return found
	return null

func find_all_nodes_by_class(node: Node, class_name_str: String) -> Array:
	var results = []
	if node.is_class(class_name_str):
		results.append(node)
	for child in node.get_children():
		results.append_array(find_all_nodes_by_class(child, class_name_str))
	return results

func find_button_by_text(node: Node, text_substr: String) -> Button:
	if node is Button and text_substr.to_lower() in node.text.to_lower():
		return node
	for child in node.get_children():
		var found = find_button_by_text(child, text_substr)
		if found != null:
			return found
	return null
