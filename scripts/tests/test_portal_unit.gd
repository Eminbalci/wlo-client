extends SceneTree

func _init() -> void:
	print("START PORTAL TEST")
	var portal_script = load("res://scripts/map/portal.gd")
	var p = portal_script.new()
	p.portal_name = "Test Portal"
	root.add_child(p)
	
	# Verify label is hidden and text is empty or hidden
	if p.has_node("Label"):
		var lbl = p.get_node("Label") as Label
		print("Label found. Visible: ", lbl.visible)
		assert(lbl.visible == false, "Portal label must be invisible!")
	
	# Verify doorlight offset
	var sprite = p.get_node("DoorLightSprite") as Sprite2D
	print("Sprite offset: ", sprite.offset)
	assert(sprite.offset == Vector2(0, -42), "DoorLight offset must be Vector2(0, -42)")

	# Verify small door style
	p.set_portal_style(portal_script.STYLE_SMALL_DOOR)
	sprite = p.get_node("DoorLightSprite") as Sprite2D
	print("Small door sprite offset: ", sprite.offset)
	assert(sprite.offset == Vector2(0, -22), "SmallDoor offset must be Vector2(0, -22)")
	assert(sprite.texture != null, "SmallDoor texture must not be null")
	
	print("PORTAL TEST PASSED SUCCESSFULLY")
	quit(0)
