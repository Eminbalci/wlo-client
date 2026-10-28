extends SceneTree

const HUDScene = preload("res://scenes/ui/hud.tscn")
const ArchiveLoaderClass = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	var al = ArchiveLoaderClass.new()
	al.name = "ArchiveLoader"
	root.add_child(al)
	al._ready()
	print("ArchiveLoader path: ", al.get_path())
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	var btn = hud.get_node("BottomActionDock/ButtonContainer/BtnStatus")
	print("btn texture_normal: ", btn.texture_normal)
	if not btn.texture_normal:
		var tex = al.get_ui_texture("menu/Skins/default/Btn_1.bmp")
		print("get_ui_texture returned: ", tex)
	quit(0)
