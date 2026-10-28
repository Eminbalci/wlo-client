class_name HotbarSlotButton
extends Button

## Interactive hotbar action slot button supporting drag-and-drop, right-click clear, and tooltips.
## Forwards drag, drop, and click events to HUDHotbar controller.

var slot_index: int = -1
var hotbar_ref: RefCounted = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if hotbar_ref and hotbar_ref.has_method("get_slot_drag_data"):
		var data = hotbar_ref.get_slot_drag_data(slot_index)
		if data is Dictionary and data.has("icon_tex") and data["icon_tex"] != null:
			var preview := TextureRect.new()
			preview.texture = data["icon_tex"]
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.size = Vector2(24, 24)
			preview.position = -Vector2(12, 12)
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var c := Control.new()
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(preview)
			set_drag_preview(c)
		return data
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if hotbar_ref and hotbar_ref.has_method("can_drop_on_slot"):
		return hotbar_ref.can_drop_on_slot(slot_index, data)
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if hotbar_ref and hotbar_ref.has_method("drop_on_slot"):
		hotbar_ref.drop_on_slot(slot_index, data)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if hotbar_ref and hotbar_ref.has_method("on_slot_right_clicked"):
				hotbar_ref.on_slot_right_clicked(slot_index)
				accept_event()
