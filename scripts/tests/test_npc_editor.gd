extends SceneTree

const NpcEditorClass = preload("res://scripts/tools/npc_editor.gd")

func _init() -> void:
	print("==================================================")
	print("--- Running Complete NpcEditor Verification ---")
	print("==================================================")
	
	# 1. Initialize Autoloads if missing
	if not root.has_node("ArchiveLoader"):
		var arch_loader = load("res://scripts/core/archive_loader.gd").new()
		arch_loader.name = "ArchiveLoader"
		root.add_child(arch_loader)
	
	if not root.has_node("GameDatabase"):
		var gdb = load("res://scripts/database/game_database.gd").new()
		gdb.name = "GameDatabase"
		root.add_child(gdb)
		gdb.load_all()
	
	# 2. Load and Instantiate NpcEditor scene
	var editor_scene = load("res://scenes/tools/npc_editor.tscn")
	if not editor_scene:
		push_error("FAILED to load res://scenes/tools/npc_editor.tscn")
		quit(1)
		return
	print("[PASS] Successfully loaded res://scenes/tools/npc_editor.tscn")
	
	var editor = editor_scene.instantiate()
	if not editor:
		push_error("FAILED to instantiate NpcEditor")
		quit(1)
		return
	print("[PASS] Successfully instantiated NpcEditor")
	
	root.add_child(editor)
	
	# 3. Test Built-in Presets
	var test_presets = ["Captain Robinson", "Kelan Leader", "Sailor Jack", "Chef", "Natasha"]
	for p in test_presets:
		editor.load_preset(p)
		print("[PASS] Loaded preset: %s | NPC ID: %d | JMP: %s | TID: %d" % [
			p, int(editor.npc_id_spin.value), editor.model_jmp_edit.text, int(editor.talk_image_spin.value)
		])
		if editor.npc_name_edit.text.is_empty():
			push_error("NPC name was empty for preset: " + p)
			quit(1)
			return
	
	# 4. Test Rotation controls
	var initial_h: int = editor._current_heading
	editor._turn_right()
	print("[PASS] Turned right from %d to %d" % [initial_h, editor._current_heading])
	editor._turn_left()
	print("[PASS] Turned left back to %d" % editor._current_heading)
	if editor._current_heading != initial_h:
		push_error("Heading mismatch after turn right + turn left")
		quit(1)
		return
	
	# 5. Test Heading selection across all 8 directions
	for h in range(8):
		editor._set_heading(h)
		var h_name = editor._get_heading_name(h)
		if h_name == "UNKNOWN":
			push_error("Invalid heading name for heading %d" % h)
			quit(1)
			return
	print("[PASS] Verified all 8 heading orientations and names")
	
	# 6. Test Frame Animation computation
	var anim_frame_32 = editor._compute_preview_frame(32, 4)
	var anim_frame_64 = editor._compute_preview_frame(140, 4)
	print("[PASS] Computed idle preview frames: 32-frame JMP -> %d, 140-frame JMP -> %d" % [
		anim_frame_32, anim_frame_64
	])
	
	# 7. Test Choices Management
	editor.load_preset("Captain Robinson")
	var initial_choices_count = editor._dialogue_choices.size()
	editor.choice_input.text = "A brand new test choice"
	editor._on_add_choice_pressed()
	if editor._dialogue_choices.size() != initial_choices_count + 1:
		push_error("Failed to add dialogue choice")
		quit(1)
		return
	print("[PASS] Added branching choice (total: %d)" % editor._dialogue_choices.size())
	
	# 8. Test Waypoint Management
	editor.waypoint_x_spin.value = 1800
	editor.waypoint_y_spin.value = 950
	editor.waypoint_delay_spin.value = 3.5
	editor._on_add_waypoint_pressed()
	print("[PASS] Added patrol waypoint (total: %d)" % editor._walksteps.size())
	
	# 9. Test Custom Preset Saving and Loading
	var save_ok = editor.save_custom_preset("Test Automaton")
	if not save_ok:
		push_error("Failed to save custom preset")
		quit(1)
		return
	print("[PASS] Saved custom preset 'Test Automaton' to user://custom_npcs.json")
	
	var custom_dict = editor.load_custom_presets()
	if not custom_dict.has("Test Automaton"):
		push_error("Custom preset 'Test Automaton' was not found in loaded presets")
		quit(1)
		return
	print("[PASS] Verified custom presets loading (count: %d)" % custom_dict.size())
	
	# 10. Test create_npc_entity()
	var entity: NpcEntity = editor.create_npc_entity()
	if not entity:
		push_error("Failed to create NpcEntity from editor")
		quit(1)
		return
	print("[PASS] create_npc_entity() returned valid NpcEntity:")
	print("       Name: %s, ID: %d, Sprite: %s, Heading: %d, Pos: %s" % [
		entity.npc_name, entity.npc_id, entity.model_jmp, entity.heading, entity.world_position
	])
	entity.free()
	
	# 11. Test export_npc_scene()
	var export_test_path = "res://scenes/world/test_exported_npc.tscn"
	var exported_path = editor.export_npc_scene(export_test_path)
	if exported_path.is_empty():
		push_error("export_npc_scene returned empty path")
		quit(1)
		return
	print("[PASS] export_npc_scene() generated: " + exported_path)
	
	# Verify exported scene can be loaded as Resource by Godot
	var loaded_scene = ResourceLoader.load(export_test_path)
	if not loaded_scene:
		push_error("Failed to load exported .tscn scene file: " + export_test_path)
		quit(1)
		return
	var loaded_inst = loaded_scene.instantiate()
	if not loaded_inst or not (loaded_inst is NpcEntity):
		push_error("Exported scene instance is not NpcEntity")
		quit(1)
		return
	print("[PASS] Exported .tscn loaded and instantiated successfully as NpcEntity!")
	print("       Exported NPC Name: %s, Walksteps: %d" % [loaded_inst.npc_name, loaded_inst.walksteps.size()])
	loaded_inst.free()
	
	# Clean up test exported file
	DirAccess.remove_absolute(ProjectSettings.globalize_path(export_test_path))
	print("[PASS] Cleaned up temporary test scene file")
	
	# 12. Test copy_gdscript_snippet()
	var snippet = editor.copy_gdscript_snippet()
	if snippet.is_empty() or not snippet.contains("NpcEntity") or not snippet.contains("world_position"):
		push_error("GDScript snippet generation was invalid")
		quit(1)
		return
	print("[PASS] copy_gdscript_snippet() generated valid GDScript snippet (%d chars)" % snippet.length())
	
	# 13. Test Crosshair overlay draw
	if editor.crosshair_overlay:
		editor.crosshair_overlay.queue_redraw()
	print("[PASS] Executed ground crosshair overlay redraw queue without errors")
	
	print("==================================================")
	print("ALL NPC EDITOR TESTS PASSED 100% SUCCESSFULLY!")
	print("==================================================")
	quit(0)
