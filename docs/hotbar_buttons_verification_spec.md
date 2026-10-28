# Hotbar and Quick Slot Buttons Verification Specification

## Overview
The Wonderland Online client features an authentic Right Hotbar Dock (`HotbarDock`, 56x274 pixels) housing exactly 8 vertical quick slot buttons corresponding to keys `F1` through `F8`.

## Technical Specifications & Verification

1. **Slot Structure & Layout**:
   - Exactly 8 slots (`Slot1` through `Slot8`) configured in `_setup_hotbar()` ([hud.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd#L622-L680)).
   - Stride: 27 pixels vertical spacing starting at offset `y = 28`.
   - Dimensions: 44x25 pixels per slot button (`flat = true`).

2. **Key Indicators & Icon Display**:
   - `KeyLabel` rendered on the left tab (`x = 0..18`, font size 9) displaying `F1` to `F8`.
   - `Icon` TextureRect placed in the 24x24 authentic slot box (`x = 19..43`).

3. **Input Handling & Action Triggers**:
   - Mouse click triggers `activate_hotbar_slot(slot_index)` which emits `hotkey_action_triggered(slot_index)` and logs system message.
   - Keyboard unhandled input handler listens for `KEY_F1` through `KEY_F8` and triggers corresponding hotbar slot activation.

4. **Automated Verification Test**:
   - Executed via `tests/test_hotbar_slots.gd` against `scenes/ui/hud.tscn`.
