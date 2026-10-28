extends SceneTree

## Captures every tab of the World Editor (CAPTURE_DIR sets the output folder).

func _init() -> void:
	_run()


func _run() -> void:
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir == "":
		out_dir = "res://screenshots_auth"
	var inst := (load("res://scenes/tools/world_editor.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 30:
		await process_frame
	var tabs := inst.find_children("*", "TabContainer", true, false)
	print("TABS containers=", tabs.size())
	if tabs.is_empty():
		root.get_texture().get_image().save_png(out_dir.path_join("we_0.png"))
		quit()
		return
	var tab: TabContainer = tabs[0]
	for i in tab.get_tab_count():
		tab.current_tab = i
		for f in 15:
			await process_frame
		print("TAB ", i, " ", tab.get_tab_title(i))
		root.get_texture().get_image().save_png(out_dir.path_join("we_%d.png" % i))
	quit()
