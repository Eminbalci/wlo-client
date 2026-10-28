# Wonderland Online Dialogue Layout and Speaker Parity Specification

## 1. Overview

This document specifies the technical implementation and parity requirements for the Wonderland Online dialogue presentation system, addressing parchment background clipping/misalignment, skin asset resolution, speaker nameplate accuracy, and multi-page/branching dialogue navigation.

---

## 2. Authentic Skin Texture Resolution

### 2.1 FormTalk Parchment Assets
In the original Wonderland Online client assets (`menu/Skins/white/`):
- `Form_Talk_1.bmp`: Contains the outer frame with a solid blue placeholder `(102, 155, 224)` interior meant for dynamic fill or color keying.
- `Form_Talk_2.bmp`: Contains the authentic 768x169 white gradient parchment texture with golden scrollwork borders and transparent chroma key `Color(0, 1, 1)` corners.
- `Form_Talk_3.bmp`: Contains the 226x169 dialogue choice frame.

### 2.2 Archive Loader Texture Remapping
To ensure backward compatibility with scenes requesting `menu/skins/white/form_talk_1.bmp`, [`ArchiveLoader`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/core/archive_loader.gd) automatically redirects requests for `menu/skins/white/form_talk_1.bmp` to `Form_Talk_2.bmp`:
```gdscript
if lower_path.ends_with("menu/skins/white/form_talk_1.bmp"):
    var alt_path: String = "menu/skins/white/form_talk_2.bmp"
    var alt_tex = load_texture_from_file(alt_path)
    if alt_tex:
        return alt_tex
```

---

## 3. UI Anchors & Layout Geometry

### 3.1 Background Control Configuration
To prevent clipping, aspect ratio distortion, or bottom margin letterboxing (exposing Godot's default clear color `Color(0.1137, 0.1137, 0.1137)` / `[29, 29, 29]`):
- Both `TalkBackground` (`FormTalk1`) and `ChoiceBackground` (`FormTalk3`) in [`scenes/ui/hud.tscn`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scenes/ui/hud.tscn) are configured with full rect stretch:
  - `layout_mode = 1`
  - `anchors_preset = 15`
  - `anchor_right = 1.0`
  - `anchor_bottom = 1.0`
  - `grow_horizontal = 2`
  - `grow_vertical = 2`
  - `expand_mode = 1` (`EXPAND_IGNORE_SIZE`)
  - `stretch_mode = 0` (`STRETCH_SCALE`)

### 3.2 Responsive Positioning
- `FormTalk1` is anchored horizontally to screen center (`anchor_left = 0.5`, `anchor_right = 0.5`, `offset_left = -384.0`, `offset_right = 384.0`) and vertically to screen bottom (`anchor_top = 1.0`, `anchor_bottom = 1.0`, `offset_top = -189.0`, `offset_bottom = -20.0`).
- Validated across window resolutions from 800x600 up to 3840x2160 without background clipping or letterbox gaps.

---

## 4. Speaker Nameplate & Dialogue Progression

### 4.1 Speaker Nameplate Accuracy
- Captain NPC interactions set speaker name to `"Captain Robinson"` (replacing placeholder `"Captain"`).
- Kelang interactions on Deserted Island set speaker name to `"Kelang"` with portrait TID 8038 mapped to `res://assets/portraits/kelang.png`.
- Custom speaker names are preserved across multi-page transitions and choice branches.

### 4.2 Multi-Page Dialogue Chaining
- [`HUDDialogue.show_dialogue_sequence()`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud/hud_dialogue.gd) loads array of pages.
- Page 0 is displayed immediately; choice buttons in `FormTalk3` remain hidden during intermediate pages.
- Choices are held in `_pending_choices` and presented only upon reaching the final page via `advance_dialogue()`.

### 4.3 Interactive Branching vs Chaining
- In [`TalkDatabase.get_dialogue_chain()`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/database/talk_database.gd), dialogue chaining automatically terminates if an entry defines interactive choice options with `next_talk_id > 0`.
- This ensures dialogue prompts requiring player decision (such as Kelang Talk 20305) present choice prompts rather than auto-stepping into unrelated branches.

---

## 5. Verification & Test Suite

The following automated test suites validate dialogue parity:
1. `res://scripts/tests/test_captain_dialogue_sinking_cutscene.gd`: Validates Captain Robinson dialogue completion, choice triggers, sinking cutscene stages, and Deserted Island warp (13 tests passed).
2. `res://scripts/tests/test_dialogue_parity_and_layout.gd`: Validates texture resolution (768x169), speaker nameplate parity, multi-page progression, choice visibility gating, and Kelang branching parity (14 tests passed).
3. `res://tests/test_talk_database.gd`: Validates binary decoding of `Talk.dat` and `Npc.dat`, token extraction, portrait offsets, and chain limits (10 tests passed).
4. `res://tests/test_game_resizable.gd`: Validates window resize resilience and dock anchoring across 8 resolution tiers (all tests passed).
