# Player Status Dock Layering, Sprite Green Defringing & Slot Item Z-Ordering Specification

## Overview
This specification details the draw order corrections for `PlayerStatusDock`, universal green chroma-key halo defringing for HUD sprites in `assets/hud/`, and slotted item z-index elevation in `CompoundWindow` and `HUDInventory`.

---

## 1. Player Status Dock Draw Hierarchy

### Issue
In `scenes/ui/hud.tscn`, `StatusBackground` was defined at line 86 and `AvatarRect` was at line 92. Consequently, Godot's 2D canvas rendered `AvatarRect` on top of `StatusBackground`, causing the character portrait to overlap the golden bezel aperture rather than being cradled beneath it.

### Resolution
The node tree in `scenes/ui/hud.tscn` was updated so `AvatarRect` is drawn before `StatusBackground`, `HpChannelUnder`, `SpChannelUnder`, `HpBar`, and `SpBar`:

1. `AvatarBg` (Index 0, ColorRect, hidden background backing)
2. `AvatarRect` (Index 1, TextureRect, role bust portrait)
3. `StatusBackground` (Index 2, TextureRect, golden filigree frame with channel apertures)
4. `HpChannelUnder` (Index 3, TextureRect)
5. `SpChannelUnder` (Index 4, TextureRect)
6. `HpBar` (Index 5, TextureProgressBar, crimson HP bar)
7. `SpBar` (Index 6, TextureProgressBar, cobalt SP bar)
8. `ElementIcon`, `NameLabel`, `LevelLabel`, etc.

### Script Safety Guarantees
In `scripts/ui/hud/hud_player_status.gd` and `scripts/ui/hud/status_dock.gd`, runtime guards dynamically reorder `AvatarRect` behind `StatusBackground` via `move_child(avatar_rect, status_bg.get_index())` if external instantiation alters the tree.

---

## 2. HUD Sprite Chroma Key Defringing Engine

### Background
Wonderland Online assets originate from 32-bit Borland Delphi client BMP archives (`.jma`, `.jmp`, `.bmp`) where pure bright green `RGB(0, 255, 0)` served as transparent chroma key. During bitmap extraction, slicing, and bilinear/bicubic resampling, green bleed pixels (both pure unkeyed chroma and 1-2px border halos) contaminated sliced sprite edges.

### Implementation: `scripts/tools/defringe_hud_sprites.py`
A high-throughput NumPy/Pillow defringing utility scans `assets/hud/*.png` (excluding natural green elements like `icon_element_4.png` and character standees):

1. **Unkeyed Pure Green Bleed Elimination:**
   Any pixel with `A > 0`, `G >= 180`, `R <= 70`, `B <= 70` is identified as unkeyed chroma backdrop and set to `A = 0`.
2. **2-Pixel Border Detection:**
   Generates a 2-pixel dilation mask of all transparent pixels via binary neighbor shifting.
3. **Halo Color Clamping:**
   On edge border pixels satisfying `G > R * 1.15` and `G > B * 1.15` and `G > 70`:
   - Strong chroma bleed (`G > 140 and R < 90 and B < 90`): pixel alpha set to 0.
   - Anti-aliased edge halo: Green channel clamped to `max(R, B)`. Preserves pixel luminosity, edge softness, and anti-aliasing alpha while neutralizing green fringing.

### Quantitative Results
- **Files Scanned:** 336 HUD sprites.
- **Files Cleaned:** 88 sprites (including `10017A.png`, `10017B.png`, `compounding_anim.png`, `btn_background_1.png`, `btn_background_2.png`, `hud_dock_buttons.png`, `hud_minimap.png`, `icon_use_compound_skill.png`).
- **Pixels Cleaned:**
  - 175,040 pure green chroma bleed pixels -> `A = 0`.
  - 1,108 strong edge bleed pixels -> `A = 0`.
  - 3,609 border halo pixels clamped to `max(R, B)`.

---

## 3. Slotted Item Z-Ordering & Compounding Overlay

### Compound Window (`scripts/ui/hud/compound_window.gd`)
- `SlotBacking` Panel is explicitly assigned `z_index = 0`.
- Slotted Item `icon_rect` is explicitly assigned `z_index = 2` and brought to front with `move_child(icon, -1)`.
- Stack count `count_lbl` is explicitly assigned `z_index = 3` and brought to front with `move_child(count_lbl, -1)`.
- `compounding_rect` (`CompoundingAnim`) overlay is initialized with `visible = false` and cleared (`visible = false`, `texture = null`) upon synthesis completion, window closing, or window toggling, preventing any obstruction of slotted materials.

### HUD Inventory (`scripts/ui/hud/hud_inventory.gd`)
- 45 inventory slot icons are assigned `z_index = 2` on instantiation and refreshed with `slot_btn.move_child(icon_rect, -1)`.
- Stack labels are assigned `z_index = 3`.
- Equipment sockets in `hud_character_status.gd` are updated with `icon.z_index = 2` and `btn.move_child(icon, -1)`.

---

## 4. Automated Verification Suite
Master headless test suite `tests/test_avatar_layering_and_defringe.gd` exercises all 5 validation gates:
1. `PlayerStatusDock` hierarchy: verifies `AvatarRect.index < StatusBackground.index < HpBar.index`.
2. Standalone `status_dock.tscn` hierarchy matches `hud.tscn`.
3. `CompoundWindow` slot icon `z_index >= 2`, `SlotBacking.z_index < icon.z_index`, `compounding_rect.visible == false`.
4. `HUDInventory` 45 slots icon `z_index >= 2` and stack label `z_index >= 3`.
5. Zero pure green chroma bleed across defringed assets (`compounding_anim.png`, `btn_background_2.png`, `hud_minimap.png`, `icon_use_compound_skill.png`).
- Pass rate: **100% zero-error pass rate**.
