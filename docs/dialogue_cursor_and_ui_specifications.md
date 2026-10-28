# Dialogue Click Dismissal, Global Multi-State Animated Cursor & UI Specifications

## 1. Overview
This specification details the architecture, implementation, and verification of the interactive dialogue dismissal system, the global multi-state animated cursor engine (`CursorManager`), the removal of redundant synthetic window title labels, the top-left status dock avatar aperture scaling, and the chat history translucent parchment panel styling in the Wonderland Online Godot 4 client.

---

## 2. Interactive Dialogue Advancement and Click Dismissal

### 2.1 Problem Analysis
In previous iterations, mouse click signals were only connected to the tiny $16 \times 16$ `next_icon` child node. `FormTalk1`, `TalkBackground` (`TextureRect`), and `DialogueText` (`RichTextLabel`) defaulted to `mouse_filter = MOUSE_FILTER_STOP`, swallowing all mouse clicks across the dialogue box without triggering page progression. Furthermore, clicks on the game world or screen outside the dialogue box were ignored or resulted in unintended player movement.

### 2.2 Dual-Layer Click Kinematics
1. **Direct Dialogue Component Input**:
   - In `hud.gd` (`_setup_dialogue()`), `gui_input` is bound across `dialogue_dock` (`FormTalk1`), `dialogue_bg` (`TalkBackground`), `dialogue_text` (`DialogueText`), and `next_icon`.
   - Any `InputEventMouseButton` with `pressed = true` and `button_index == MOUSE_BUTTON_LEFT` invokes `advance_dialogue()` and marks the event as handled via `get_viewport().set_input_as_handled()`.
2. **Global Viewport Unhandled Input**:
   - In `hud.gd` (`_unhandled_input(event)`), if `dialogue_dock` is visible and branching choices (`branching_dock`) are not active:
   - Any left mouse button click anywhere across the viewport invokes `advance_dialogue()` and sets `set_input_as_handled()`, preventing player pathfinding or unwanted clicks while reading dialogue.
3. **Multi-Page Progression and Choice Safeguards**:
   - `advance_dialogue()` increments `_dialogue_current_page`.
   - If further pages exist, it updates `dialogue_text.text` to `_dialogue_pages[_dialogue_current_page]`.
   - On the final page, if branching choices exist (`FormTalk3`), it presents the choice buttons; otherwise, it invokes `hide_dialogue()`, cleanly dismissing the dialogue box.

---

## 3. Global Multi-State Animated Cursor Engine (`CursorManager`)

### 3.1 Architectural Design
The cursor system is implemented as an engine-wide autoload singleton:
- **Autoload Node**: `CursorManager` (`scripts/core/cursor_manager.gd`) registered in `project.godot`.
- **Animation Frequency**: Runs continuously at 10 FPS (`const FRAME_INTERVAL: float = 0.1`), matching the original Borland Delphi client's `jif_rate = 10` RIFF/ACON specification.
- **Hardware Cursor Dispatch**: Executes `Input.set_custom_mouse_cursor(active_texture, Input.CURSOR_ARROW, hotspot)` every 100 ms, ensuring seamless cursor animations across all scenes, UI windows, chat docks, and world viewports.

### 3.2 Authentic Cursor State Mapping

| Cursor Enum | Target File | Frame Count | Hotspot | Trigger Condition |
| :--- | :--- | :--- | :--- | :--- |
| `CursorType.NORMAL` | `cursor1.ani` | 8 frames | `Vector2(0, 0)` | Standard movement, world navigation, and open UI hover |
| `CursorType.TALK` | `cursor3.ani` | 6 frames | `Vector2(0, 0)` | Mouse hovering over NPC entity within 42px interaction radius |
| `CursorType.PORTAL` | `cursor6.ani` | 6 frames | `Vector2(0, 0)` | Mouse hovering over active warp portal / door within 42px |
| `CursorType.HARVEST` | `cursor4.ani` | 1 frame | `Vector2(4, 2)` | Mouse hovering over harvestable ground item within 32px |
| `CursorType.ATTACK` | `cursor2.ani` | 8 frames | `Vector2(0, 0)` | Mouse hovering over hostile enemy or battle combat target |
| `CursorType.MINING` | `cursor8.ani` | 2 frames | `Vector2(0, 0)` | Resource mining / gathering node hover |
| `CursorType.QUEST` | `cursor11.ani` | 6 frames | `Vector2(0, 0)` | Quest giver / interactive question prompt |

### 3.3 Dynamic Hover Detection in MapView
In `scripts/map/map_view.gd` (`_process(delta)`):
1. `hud.is_mouse_over_ui()` check: If the mouse pointer is hovering over any open floating window, chat dock, or dialogue box, the cursor immediately remains `CursorType.NORMAL`.
2. World entities scan: Computes distance between `get_global_mouse_position()` and NPC world coordinates (`<= 42.0` px). Upon match, switches to `CursorType.TALK`.
3. Portals scan: Scans `_dynamic_portals` (`<= 42.0` px). Upon match, switches to `CursorType.PORTAL`.
4. Ground items scan: Scans `_dynamic_ground_items` (`<= 32.0` px). Upon match, switches to `CursorType.HARVEST`.
5. Fallback: If no interactive entity is hovered, resets to `CursorType.NORMAL`.

---

## 4. Window Title Label Removal & Delphi Graphics Parity

### 4.1 Visual Redundancy Elimination
Authentic Wonderland Online UI windows are skinned using high-detail Borland Delphi bitmap graphics (`Form_RoleStatus_1.bmp`, `form_skill.bmp`, `Form_Taskview_1.bmp`, `Form_Team_2.bmp`, `Form_Friend_2.bmp`, `Form_System_2.bmp`). These bitmaps already contain pre-printed, ornate metallic Chinese/English titles baked directly into the top title bar.

### 4.2 Implementation
Synthetic procedural `TitleLabel` nodes across all 7 floating windows have been disabled:
- `FloatingWindows/InventoryWindow/TitleLabel`: `visible = false`
- `FloatingWindows/CharacterWindow/TitleLabel`: `visible = false`
- `FloatingWindows/FriendsWindow/TitleLabel`: `visible = false`
- `FloatingWindows/SkillWindow/TitleLabel`: `visible = false`
- `FloatingWindows/TeamWindow/TitleLabel`: `visible = false`
- `FloatingWindows/QuestWindow/TitleLabel`: `visible = false`
- `FloatingWindows/SystemWindow/TitleLabel`: `visible = false`
- In `hud.gd` (`_setup_floating_windows()`), any existing `TitleLabel` node is set to `visible = false` and `mouse_filter = MOUSE_FILTER_IGNORE` to guarantee smooth title bar dragging without text overlap.

---

## 5. Top-Left Status Dock Avatar Aperture Alignment

### 5.1 Dimensional Calibration
The gold circular status frame aperture in `hud_status_frame_transparent_channels.png` ($241 \times 116$) has an inner opening centered at $(50, 50)$ with diameter $\approx 60$ px. Setting the avatar to $92 \times 92$ at $Y=0$ stretched the portrait by $1.28\times$ and pushed it outside the oval frame.

### 5.2 Adjusted Coordinates
- **AvatarBg** (`ColorRect`): Position `Vector2(18, 18)`, Size `Vector2(64, 64)`, Color `Color(0.16, 0.16, 0.16, 1.0)`.
- **AvatarRect** (`TextureRect`): Position `Vector2(18, 18)`, Size `Vector2(64, 64)`, `expand_mode = EXPAND_IGNORE_SIZE`, `stretch_mode = STRETCH_KEEP_ASPECT_CENTERED`.
- Portrait frames sliced from `008.jma` ($72 \times 72$) now fit completely inside the gold bezel without protruding into the HP bar or the viewport boundary.

---

## 6. Chat History Parchment Styling

### 6.1 Panel Restoration
In `scripts/ui/hud.gd` (`_setup_chat()`), the previous `StyleBoxEmpty` override was removed. `ChatHistoryPanel` is now styled with a translucent slate/parchment background and gold border matching authentic game aesthetics:
- **Background Color**: `Color(0.04, 0.05, 0.07, 0.72)`
- **Border**: Width 1px, `Color(0.72, 0.58, 0.32, 0.85)`
- **Corner Radius**: 3px (top-left and top-right)
- **Margins**: Left 8px, Top 6px, Right 8px, Bottom 6px
- Text color is crisp white with black outline and shadow, ensuring optimal readability over any terrain.

---

## 7. Automated Test Verification

All requirements are verified via automated headless test suites:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_dialogue_cursor_and_ui.tscn
```
Output:
- `[PASS] Top-Left Avatar aperture scaling and positioning verified: pos=(18, 18), size=(64, 64)`
- `[PASS] All redundant window title text labels verified hidden (Delphi skin bitmaps have baked titles)`
- `[PASS] Single-page dialogue dismissal on background click verified`
- `[PASS] Multi-page dialogue sequence progression and dismissal on screen click verified`
- `[PASS] ChatDock parchment panel background & gold border verified`
- `[PASS] Global CursorManager all 5 authentic cursor states & 10 FPS animation loop verified`
- `--- ALL VERIFICATIONS PASSED (100% SUCCESS) ---`
