extends SceneTree

const AUTH_SCENES = {
    "server_select": "res://scenes/ui/auth/server_select.tscn",
    "login_dialog": "res://scenes/ui/auth/login_dialog.tscn",
    "character_select": "res://scenes/ui/auth/character_select.tscn"
}

func _init():
    print("Visual Parity Inspector starting...")
    var dir = DirAccess.open("res://")
    if not dir.dir_exists("screenshots_auth"):
        dir.make_dir("screenshots_auth")
    
    var root = get_root()
    var viewport = root.get_viewport()
    if viewport:
        viewport.size = Vector2i(1024, 768)
    
    for key in AUTH_SCENES:
        var path = AUTH_SCENES[key]
        print("Loading scene: ", path)
        var packed = load(path)
        if packed:
            var instance = packed.instantiate()
            root.add_child(instance)
            
            for i in range(10):
                await process_frame
            
            if viewport:
                var img = viewport.get_texture().get_image()
                var save_path = "res://screenshots_auth/%s.png" % key
                var err = img.save_png(save_path)
                print("Saved screenshot to: ", ProjectSettings.globalize_path(save_path))
            
            root.remove_child(instance)
            instance.queue_free()
        else:
            print("Failed to load scene: ", path)
            
    print("All screenshots captured successfully.")
    quit()
