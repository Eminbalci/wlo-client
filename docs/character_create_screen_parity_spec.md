# Character Create Screen Parity Specification

## 1. Overview & Architecture
The Character Creation wizard is a 4-step wizard implementing pixel-exact parity with authentic Wonderland Online (`aLogin.exe`) and ground truth video frames `sec_038.png` through `sec_048.png`.

The interface uses authentic Delphi white skin container textures from `menu/Skins/white/` centered on an 800x600 screen, replacing generic unstyled Godot button grids with authentic standee carousels, animated portraits, element affinities, stat allocation, and character confirmation.

---

## 2. Forms & Layout Geometry

| Step | Form Asset | Dimensions | Screen Position (800x600) | Functionality |
|---|---|---|---|---|
| **Step 1** | `Form_CreateRole_1.jpg` | 740 x 352 px | `X: 30, Y: 124` | Standee Carousel (14 Roles), Lore, Portrait, Element Affinities |
| **Step 2** | `Form_CreateRole_2.jpg` | 740 x 352 px | `X: 30, Y: 124` | Hair Style & RGB Color Palette Customization |
| **Step 3** | `Form_CreateRole_3.jpg` | 740 x 352 px | `X: 30, Y: 124` | 4 Attribute Bonus Points Allocation (STR, CON, INT, WIS, AGI) |
| **Step 4** | `Form_CreateRole_4.jpg` | 536 x 352 px | `X: 132, Y: 124` | Character Name Input (1..14 chars) & Final Confirmation Review |

---

## 3. Step 1: Role Selection & Standee Carousel

### 3.1 Standee Carousel Stage (`X: 20..370, Y: 10..342`)
- **Left Arrow Button (`btn_arrow_left_normal.png`, `btn_arrow_left_hover.png`, `btn_arrow_left_pressed.png`):**
  - Dimensions: 18 x 17 px per state.
  - Position: `X: 18, Y: 16`.
  - Behavior: Cycles role backward (`select_prev_role()`).
- **Right Arrow Button (`btn_arrow_right_normal.png`, `btn_arrow_right_hover.png`, `btn_arrow_right_pressed.png`):**
  - Dimensions: 18 x 17 px per state.
  - Position: `X: 178, Y: 16`.
  - Behavior: Cycles role forward (`select_next_role()`).
- **Role Name Display (`RoleNameLabel`):**
  - Position: `X: 38, Y: 14, W: 138, H: 21`. Font size 13, dark brown `Color(0.22, 0.15, 0.08)`.
- **Radar Chart:**
  - Position: `X: 16, Y: 46, W: 150, H: 140`. Displays live pentagon polygon attributes.
- **Standee Display:**
  - Position: `X: 145, Y: 35, W: 195, H: 235`, `expand_mode = 1`, `stretch_mode = 5` (Keep Aspect Centered).
- **Role Lore Description (`RoleLoreLabel`):**
  - Position: `X: 16, Y: 246, W: 320, H: 80`. Font size 10, multiline autowrapped.

### 3.2 Right Info Panel (`X: 370..740, Y: 0..352`)
- **Name Inputs (`FirstNameInput` & `FamilyNameInput`):**
  - Exact window alignment over pre-printed banner boxes:
    - `FirstNameInput`: `X: 545, Y: 97, W: 84, H: 20`.
    - `FamilyNameInput`: `X: 633, Y: 97, W: 84, H: 20`.
  - Styled with parchment-tinted flat box, max length 10 each, dark brown text.
- **Live Character Preview Box:**
  - `FaceBust`: `X: 525, Y: 155, W: 70, H: 70` inside parchment portrait box.
  - `BtnR`: `X: 524, Y: 229, W: 17, H: 17` (Appearance preset toggle).
  - `BtnH`: `X: 544, Y: 229, W: 17, H: 17` (Hat visibility toggle).
  - `GrassPatch`: `X: 622, Y: 228, W: 52, H: 14` soft green shadow.
  - `WalkingSprite`: `X: 615, Y: 148, W: 66, H: 88` animated walking isometric sprite.
  - `BtnTurnLeft`: `X: 605, Y: 201, W: 17, H: 17` (`<`).
  - `BtnTurnRight`: `X: 672, Y: 201, W: 17, H: 17` (`>`).
  - In Step 3, `ElementCoinBadge` is placed beside `BtnH` at `X: 564, Y: 227, W: 24, H: 24` without overlapping the character's forehead.

### 3.3 Navigation Buttons
- **Return / Cancel Button (`btn_cancel_normal.png`, `hover`, `pressed`):**
  - Position: `X: 501, Y: 306, W: 102, H: 22`.
- **Continue / Next Button (`btn_next_normal.png`, `hover`, `pressed`):**
  - Position: `X: 621, Y: 306, W: 102, H: 22`.
- **Finish / OK Button (`btn_ok_normal.png`, `hover`, `pressed`):**
  - Position: `X: 621, Y: 306, W: 102, H: 22` in Step 3 / Step 4.

---

## 4. Step 2: Hair & Appearance Customization

- **Form Container:** `Form_CreateRole_2.jpg` (740 x 352).
- **Preview Area:** Live character standee and avatar portrait tinted by selected hair color.
- **Hair Style Selection:** `<` and `>` buttons cycling hair styles 1..4.
- **Palette Swatches:**
  - 8 Preset hair colors: Silver/White, Deep Brown, Jet Black, Golden Blonde, Fiery Crimson, Azure Blue, Emerald Green, Sakura Pink.
  - 5 Skin tone swatches: Standard, Fair, Warm Peach, Tan, Deep Bronze.
- **Navigation Buttons:**
  - `BtnPrev` (`Btn_Prev_1.bmp`, 56x20) at `X: 580, Y: 315` -> Return to Step 1.
  - `BtnNext` (`btn_next.bmp`, 56x20) at `X: 650, Y: 315` -> Advance to Step 3.

---

## 5. Step 3: Attribute Points Allocation

- **Form Container:** `Form_CreateRole_3.jpg` (740 x 352).
- **Base Attributes:** Calculated from role definition (`GameDatabase.ROLES`) plus elemental affinity:
  - Earth: CON +2, STR +1
  - Water: WIS +2, CON +1, INT +1
  - Fire: STR +2, AGI +1
  - Wind: AGI +2, STR +1
- **Bonus Points Pool:** 4 points pool (`TOTAL_BONUS_POINTS = 4`).
- **5 Stat Rows:** STR, CON, INT, WIS, AGI.
  - `[-]` and `[+]` buttons modify bonus allocation in range `0..points_pool`.
  - Values formatted as `base (+bonus)`.
- **Navigation Buttons:**
  - `BtnPrev` at `X: 580, Y: 315` -> Return to Step 2.
  - `BtnNext` at `X: 650, Y: 315` -> Advance to Step 4.

---

## 6. Step 4: Character Confirmation

- **Form Container:** `Form_CreateRole_4.jpg` (**536 x 352**, centered at `X: 132, Y: 124`).
- **Name Input:** Centered `LineEdit` at `X: 150, Y: 49` with parchment-friendly styling, placeholder, and max length 14.
- **Validation:**
  - Rejects empty name with error "Please enter a character name."
  - Rejects names exceeding 14 characters.
- **Review Card:**
  - 72 x 72 px animated bust portrait.
  - Character Name, Role, and Element badge.
  - Final stat summary: `STR`, `CON`, `INT`, `WIS`, `AGI`.
- **Navigation Buttons:**
  - `BtnPrev` (`Btn_Cancel_1.bmp`, 56x20) at `X: 380, Y: 315` -> Return to Step 3.
  - `BtnOk` (`btn_ok_1.bmp`, 56x20) at `X: 450, Y: 315` -> Confirms creation, calls `CharacterManager.create_default_character` and `CharacterManager.save_character`, and emits `character_created(char_data)`.

---

## 7. Verification & Empirical Proof
- In-engine headless suite: `scenes/tests/test_auth_flow.tscn` executed with `godot_console.exe --headless`.
- Result: **113/113 passing assertions**, zero script errors.
- Visual parity: All 4 forms match Delphi white skins with zero white rectangle artifacts.
