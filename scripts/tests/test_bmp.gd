extends SceneTree

const HUDScene = preload("res://scenes/ui/hud.tscn")
const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var al = ArchiveLoaderClass.new()
	al.name = "ArchiveLoader"
	root.add_child(al)
	print("al path: ", al.get_path())
	print("from root search: ", root.get_node_or_null("ArchiveLoader"))
	var loader = root.get_node_or_null("/root/ArchiveLoader")
	print("from /root/ArchiveLoader: ", loader)
	
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	print("hud instantiated")
	
	var dock = hud.get_node_or_null("BottomActionDock")
	var btn = dock.get_node_or_null("ButtonContainer/BtnStatus")
	print("BtnStatus normal: ", btn.texture_normal)
	quit(0)
