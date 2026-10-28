extends SceneTree

const HUDScene = preload("res://scenes/ui/hud.tscn")
const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	print("--- Comprehensive HUD & BottomActionDock Test ---")
	
	if not root.get_node_or_null("ArchiveLoader"):
		var al = ArchiveLoaderClass.new()
		al.name = "ArchiveLoader"
		root.add_child(al)
		al._ready()
	
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	
	assert(hud != null, "HUD is null")
	
	var dock = hud.get_node_or_null("BottomActionDock")
	assert(dock != null, "BottomActionDock not found")
	print("[PASS] BottomActionDock found: size = ", dock.size)
	
	var button_names = [
		"BtnStatus", "BtnInventory", "BtnSkill", "BtnTeam",
		"BtnQuest", "BtnFriends", "BtnBattle", "BtnSystem"
	]
	
	for bname in button_names:
		var btn: TextureButton = dock.get_node_or_null("ButtonContainer/" + bname)
		assert(btn != null, "Button " + bname + " not found")
		assert(btn.texture_normal != null, "Button " + bname + " texture_normal is null")
		assert(btn.texture_hover != null, "Button " + bname + " texture_hover is null")
		assert(btn.texture_pressed != null, "Button " + bname + " texture_pressed is null")
		print("[PASS] Button %s textures verified (normal=%s, hover=%s, pressed=%s)" % [
			bname,
			btn.texture_normal.get_size(),
			btn.texture_hover.get_size(),
			btn.texture_pressed.get_size()
		])
	
	var window_mapping = {
		"BtnStatus": "CharacterWindow",
		"BtnInventory": "InventoryWindow",
		"BtnSkill": "SkillWindow",
		"BtnTeam": "TeamWindow",
		"BtnQuest": "QuestWindow",
		"BtnFriends": "FriendsWindow",
		"BtnBattle": "FightWindow",
		"BtnSystem": "SystemWindow"
	}
	
	for bname in window_mapping:
		var wname = window_mapping[bname]
		var win: Control = hud.get_node_or_null("FloatingWindows/" + wname)
		assert(win != null, "Window " + wname + " not found")
		assert(win.visible == false, "Window " + wname + " should be initially hidden")
		
		# Test button click toggles window open
		var btn: TextureButton = dock.get_node_or_null("ButtonContainer/" + bname)
		btn.pressed.emit()
		assert(win.visible == true, "Window " + wname + " failed to open on " + bname + " click")
		
		# Test close button
		var close_btn: Button = win.get_node_or_null("CloseButton")
		assert(close_btn != null, "Close button not found on " + wname)
		close_btn.pressed.emit()
		assert(win.visible == false, "Window " + wname + " failed to close on CloseButton click")
		
		# Test window background texture is loaded
		var bg: TextureRect = win.get_node_or_null("Background")
		assert(bg != null, "Background not found on " + wname)
		assert(bg.texture != null, "Background texture not loaded on " + wname)
		print("[PASS] Window %s verified: size=%s, bg_tex_size=%s" % [wname, win.size, bg.texture.get_size()])
	
	print("--- ALL HUD AND BUTTON DOCK TESTS PASSED CLEANLY ---")
	quit(0)
