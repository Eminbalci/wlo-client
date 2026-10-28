# Player & NPC Drop Shadow Elevation & Sprite Grounding Specification

## Overview
This specification details the mathematical diagnosis, architectural resolution, and verification test suite for the character and NPC drop shadow elevation bug in the Wonderland Online Godot 4 client (`gölgenin çok üstünde uçuyoruz.png`).

---

## 1. Problem Diagnosis & Mathematical Analysis

### 1.1 The Elevation Bug
When rendering Player and NPC entities in axonometric 2:1 projection, entities appeared to float approximately 23 pixels above their oval drop shadows.

### 1.2 Root Cause Analysis
In `scripts/world/player.gd` and `scripts/world/npc.gd`, `_apply_texture(tex: Texture2D)` previously computed the sprite offset as:
```gdscript
var h := float(tex.get_height())
sprite.offset = Vector2(0, -h / 2.0)
```
On an authentic 128x128 Wonderland Online composite/JMP frame:
- Height `h = 128.0`, so `sprite.offset = Vector2(0, -64.0)`.
- In Godot `Sprite2D`, `centered = true` by default, meaning the texture coordinate `(width / 2.0, height / 2.0) = (64.0, 64.0)` aligns with `sprite.position + sprite.offset`.
- In the authentic WLO 128x128 canvas, character feet are placed at canvas `y = 105.0`.
- Therefore, the local Godot coordinate for feet was:
  $$\text{Feet}_y = \text{offset}_y + (\text{Canvas}_y - 64.0) = -64.0 + (105.0 - 64.0) = -23.0\text{ px}$$
- Meanwhile, the drop shadow is drawn at entity local origin `(0, 0)`.
- As a consequence, character feet floated 23 pixels in the air above their drop shadow.

---

## 2. Geometric Parity & Solution

### 2.1 Sprite Offset Grounding Math
To ground the character feet exactly at the center of the drop shadow (`y = 0.0`):
$$\text{offset}_y + (105.0 - 64.0) = 0.0 \implies \text{offset}_y = 64.0 - 105.0 = -41.0\text{ px}$$

For variable texture heights:
```gdscript
if int(h) == 128:
    sprite.offset = Vector2(0, -41.0)
else:
    sprite.offset = Vector2(0, -roundf(h * 0.32)) if h > 0 else Vector2(0, -41.0)
```

### 2.2 Nameplate Alignment
The top of the character's head on the 128x128 canvas is at canvas `y = 20.0`:
$$\text{Head}_y = -41.0 + (20.0 - 64.0) = -41.0 - 44.0 = -85.0\text{ px}$$
To provide 3 pixels of clearance above the head:
- `nameplate.offset_bottom = -88.0`
- `nameplate.offset_top = -108.0` (height = 20 px)

### 2.3 NPC ClickArea & Emotion Bubbles
- Humanoid NPC head height is normalized to `86.0 px` from ground.
- Interaction collision box `ClickArea.position = Vector2(0, -head_height / 2.0) = Vector2(0, -43.0)`, centering the 70px collision capsule squarely on the torso.
- Small models (e.g. Persian Cat `1035.jmp` / ID 11000) retain `head_height = 40.0`, positioning click area at `(0, -20.0)` and nameplate at `[-62.0, -42.0]`.
- Overhead emotion containers position at `Vector2(0, -head_height - 30.0) = Vector2(0, -116.0)`.
- Player speech and emote bubbles position at `Vector2(-36, -132.0)`, remaining unobstructed above the nameplate.

---

## 3. Modified Files

1. `scripts/world/player.gd`:
   - Updated `_sprite` getter default offset from `Vector2(0, -35)` to `Vector2(0, -41.0)`.
   - Updated `nameplate` getter with fallback instantiation.
   - Updated `_apply_texture` to set `sprite.offset = Vector2(0, -41.0)` for 128px textures, and nameplate offsets to `[-108.0, -88.0]`.
   - Lifted speech bubble container to `Vector2(-36, -132)`.

2. `scripts/world/npc.gd`:
   - Updated `_apply_texture` to set `sprite.offset = Vector2(0, -41.0)` for 128px textures.
   - Set default `_head_height` to `86.0`.
   - Bound `click_area.position` to `(0, -head_height / 2.0)` and `nameplate` offsets to `[-head_height - 22.0, -head_height - 2.0]`.
   - Added node fallback retrieval for `sprite`, `nameplate`, and `click_area`.

3. `scenes/world/player.tscn`:
   - Set Sprite2D `offset = Vector2(0, -41)`.
   - Set Nameplate `offset_top = -108.0`, `offset_bottom = -88.0`.

4. `scenes/world/npc.tscn`:
   - Set Sprite2D `offset = Vector2(0, -41)`.
   - Set Nameplate `offset_top = -108.0`, `offset_bottom = -88.0`.
   - Set ClickArea `position = Vector2(0, -43)`.

5. `scripts/tools/npc_editor.gd`:
   - Updated generated NPC scene template defaults to match the new offsets.

---

## 4. Verification Suite

Automated headless test runner: `tests/test_shadow_offset.gd`.

### Execution:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_shadow_offset.gd
```

### Verification Matrix:
- [x] **Part 1:** Player scene defaults in `player.tscn` validated (`offset=(0, -41.0)`, `nameplate=[-108.0, -88.0]`).
- [x] **Part 2:** Player `_apply_texture` math verified for 128x128 and variable heights.
- [x] **Part 3:** NPC scene defaults in `npc.tscn` validated (`offset=(0, -41.0)`, `nameplate=[-108.0, -88.0]`, `click_area=(0, -43.0)`).
- [x] **Part 4:** NPC `_apply_texture` math verified for standard humanoids and small models (Persian Cat).
- [x] **Part 5:** Ground contact proof: canvas `y = 105.0` calculates to Godot `y = 0.0` (shadow center) with zero elevation delta.
