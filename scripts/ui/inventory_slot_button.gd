class_name InventorySlotButton
extends Button

## Interactive inventory slot button with full drag-and-drop and hover tooltip support.
## Forwards drag, drop, click, and hover events to central HUD coordinator.

var slot_index: int = -1
var hud_ref: Control = null

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if hud_ref and hud_ref.has_method("show_inventory_item_tooltip"):
		hud_ref.show_inventory_item_tooltip(slot_index, global_position, size)

func _on_mouse_exited() -> void:
	if hud_ref and hud_ref.has_method("hide_item_tooltip"):
		hud_ref.hide_item_tooltip()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if hud_ref and hud_ref.has_method("hide_item_tooltip"):
		hud_ref.hide_item_tooltip()
	if hud_ref and hud_ref.has_method("get_inventory_drag_data"):
		var data = hud_ref.get_inventory_drag_data(slot_index)
		if data is Dictionary and data.has("icon_tex") and data["icon_tex"] != null:
			var preview := TextureRect.new()
			preview.texture = data["icon_tex"]
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.size = Vector2(32, 32)
			preview.position = -Vector2(16, 16)
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var c := Control.new()
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			c.add_child(preview)
			set_drag_preview(c)
		return data
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if hud_ref and hud_ref.has_method("can_drop_on_inventory_slot"):
		return hud_ref.can_drop_on_inventory_slot(slot_index, data)
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if hud_ref and hud_ref.has_method("drop_on_inventory_slot"):
		hud_ref.drop_on_inventory_slot(slot_index, data)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if hud_ref and hud_ref.has_method("on_inventory_slot_right_clicked"):
				hud_ref.on_inventory_slot_right_clicked(slot_index)
				accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			if hud_ref and hud_ref.has_method("on_inventory_slot_double_clicked"):
				hud_ref.on_inventory_slot_double_clicked(slot_index)
				accept_event()
