# Combat Skill VFX & Battle Animation Engine Specification

## 1. Overview
This specification details the architecture and implementation of authentic combat skill VFX animations, battle choreography, and character combat animations in the Wonderland Online Godot 4 client.
It fulfills the visual combat parity requirements by resolving skill visual effects from `006.jma`, `006_c01.jma`, and `006_c02.jma` (`6000.jmp`..`6100.jmp`), replacing plain `ColorRect` combat placeholders with authentic 128x128 animated character composite and monster standees, and driving a synchronized cast-lunge-VFX-hit recoil combat animation sequence.

---

## 2. Skill VFX Package Extraction (`006.jma`, `006_c01.jma`, `006_c02.jma`)

### 2.1 Archive Distribution
In Wonderland Online, combat visual effects are stored across 3 segmented JMA archives:
- `006.jma`: 28 entries (`6000.jmp` through `6027.jmp`), including starter stunts for all 14 playable characters (e.g. `6001.jmp` Rocco Summon Dogs, `6002.jmp` Sid Combo x3, `6003.jmp` Maria Cure, `6004.jmp` Iris Bomber, `6005.jmp` Betty Leap, `6009.jmp` Daniel Overarm Stumble, `6010.jmp` Nina Wine Flame).
- `006_c01.jma`: 72 entries (`6028.jmp` through `6099.jmp`), intermediate elemental spells and stunts.
- `006_c02.jma`: 1 entry (`6100.jmp`), advanced high-tier spell animations.

### 2.2 Extraction API (`ArchiveLoader.get_skill_vfx_frames`)
```gdscript
func get_skill_vfx_frames(anim_id: int) -> Array[ImageTexture]
```
- **Lookup Candidates**: Formats candidates e.g. for anim_id `60009` -> `60009.jmp`, `6009.jmp`, `%d.jmp` % anim_id.
- **Search Strategy**: Queries `006.jma`, then `006_c01.jma`, then `006_c02.jma`.
- **Canvas Decoding**: Decodes indexed palette frames with transparent chroma key onto a uniform bounding canvas preserving `(pivot_x, pivot_y)` offsets.
- **RAM Caching**: Caches decoded `Array[ImageTexture]` in `_skill_vfx_cache` to ensure instantaneous frame access during combat without disk I/O.

---

## 3. Battle View Standee & Animation Integration (`battle_view.gd`)

### 3.1 Authentic Standee Replacement
In `_create_actor_widget(is_enemy: bool, slot: int, data: Dictionary)`:
- Replaced placeholder `ColorRect` boxes with authentic `TextureRect` standees.
- **Players / Allies**: Render character composite standing frames (128x128) via `ArchiveLoader.get_player_composite_frames(role_id, equip_layers)`.
- **Enemies / Monsters**: Render authentic monster/NPC sprites (128x128) via `ArchiveLoader.get_jma_frame_128("001.jma", model_jmp, frame_idx)`.

### 3.2 VFX Playback Pipeline (`play_skill_vfx`)
```gdscript
func play_skill_vfx(anim_id: int, target_pos: Vector2, sfx_name: String = "", fps: float = 15.0) -> void
```
1. Retrieves frame array from `ArchiveLoader.get_skill_vfx_frames(anim_id)`.
2. Spawns an animated `TextureRect` on `vfx_layer` centered directly over `target_pos`.
3. Runs frame-by-frame animation at 15 FPS via Tween/timer.
4. Emits `skill_vfx_completed(anim_id)` and automatically frees the node upon animation conclusion.
5. Plays combat sound effect via `play_sfx(sfx_name)`.

### 3.3 Synchronized Action Execution Sequence
When an action executes via `_on_bm_action_executed(result: Dictionary)`:
1. **Caster Lunge**: Caster standee lunges forward along the 2:1 axonometric line towards the target (12px offset, 0.1s duration, then snaps back).
2. **VFX Spawning**: Look up skill `animation_id` from `result["skill"]` and spawn animated VFX on target screen position.
3. **Impact Reaction**: Target standee executes hurt flash (`Color(1.0, 0.2, 0.2, 1.0)` on crit or white on normal) and shake upon impact.
4. **Floating Combat Text**: Damage or heal popup spawns above target.

---

## 4. Verification Evidence
Executed automated test suite `tests/test_skill_vfx_animations.gd`:
- `[PASS]` `ArchiveLoader.get_skill_vfx_frames(6001)` returns 32 valid non-empty frames.
- `[PASS]` `ArchiveLoader.get_skill_vfx_frames(6009)` returns 64 valid non-empty frames.
- `[PASS]` Player composite standees and enemy monster standees initialize with authentic textures.
- `[PASS]` `play_skill_vfx` spawns on `vfx_layer`, plays full timeline, and self-frees cleanly.
- `[PASS]` Action execution triggers caster lunge, VFX spawning, and target impact reaction.
- Result: 5/5 test suites passed (100% pass rate, 0 errors).
