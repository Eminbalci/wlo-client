extends SceneTree

## Captures the Skill Studio at the window size and prints each side column's width vs its content
## minimum (a column scrolls horizontally when content > column). CAPTURE_DIR sets the output folder.

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	root.size = Vector2i(1280, 720)
	var inst := (load("res://scenes/tools/skill_editor.tscn") as PackedScene).instantiate() as Control
	root.add_child(inst)
	inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 30:
		await process_frame
	for scroll_name in ["LeftScroll", "CenterScroll", "RightScroll"]:
		var scroll := inst.find_child(scroll_name, true, false) as ScrollContainer
		if scroll == null:
			continue
		var content := scroll.get_child(0) as Control
		var h_bar := scroll.get_h_scroll_bar()
		print("%s width=%d content_min=%d h_scroll_visible=%s" % [scroll_name, int(scroll.size.x), int(content.get_combined_minimum_size().x), h_bar.visible])
	var img := root.get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png(out_dir.path_join("skill_editor_1280.png"))
	quit()
