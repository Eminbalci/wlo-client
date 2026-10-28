extends SceneTree

const ArchiveLoaderScript = preload("res://scripts/core/archive_loader.gd")

func _init() -> void:
	print("--- Testing UI Loading ---")
	var loader = ArchiveLoaderScript.new()
	loader.initialize_archives()
	print("ArchiveLoader created!")
	
	var bg = loader.get_ui_texture("pic/LogPic1.jpg")
	print("LogPic1: ", bg, " size: ", bg.get_size() if bg else "null")
	
	var form = loader.get_ui_texture("menu/Skins/white/Form_IdPassword_1.jpg")
	print("Form_IdPassword_1: ", form, " size: ", form.get_size() if form else "null")
	
	var logo = loader.get_ui_texture("menu/Skins/default/Icon_LoginLogo_1.bmp")
	print("Icon_LoginLogo_1: ", logo, " size: ", logo.get_size() if logo else "null")
	
	var btn = loader.get_ui_texture("menu/Skins/default/btn_logIn.bmp")
	print("btn_logIn: ", btn, " size: ", btn.get_size() if btn else "null")
	
	quit(0)
