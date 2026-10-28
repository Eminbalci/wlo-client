# Character Normal Animations (216-Frame Composite) & Motion State Machine Specification

## 1. Overview
In authentic Wonderland Online, character models across all 14 roles (`002.jma:2000.jmp`, `003.jma:3000.jmp`, `004.jma:4000.jmp`, `005.jma:5000.jmp`) are equipped with a complete 216-frame normal animation set. Previously, `ArchiveLoader.get_player_composite_frames()` capped compositing at frame 63, truncating sitting, combat attack strikes, defend/hurt recoils, knockouts/wakeups, and victory emotes.

This specification documents the expansion to full 216-frame multi-layer compositing and the implementation of the `MotionState` state machine in `PlayerEntity`.

---

## 2. Authentic 216-Frame Action Cycle Breakdown

| Frame Range | Action / Motion Description | Headings & Sub-Frames | JMP Frame Group / Names |
|---|---|---|---|
| **0..31** | Walk Cycle | 8 headings x 4 frames | `00-1.bmp` .. `07-4.bmp` |
| **32..63** | Stand / Idle Breathing | 8 headings x 4 frames | `08-1.bmp` .. `15-4.bmp` |
| **64..95** | Sit / Rest Cycle | 8 headings x 4 frames | `16-1.bmp` .. `23-4.bmp` |
| **96..143** | Attack / Combat Strike / Spell Cast | 8 headings x 4-6 frames (melee strike at 112..143) | `24-1.bmp` .. `39-4.bmp` (`32..39`) |
| **144..175** | Defend / Hurt / Hit Recoil | 8 headings x 4 frames | `40-1.bmp` .. `55-2.bmp` |
| **176..199** | Prone / Knockout / Defeat / Wakeup | Knockout sequences & prone (includes frame 105: `26-2.bmp` and frame 104: `26-1.bmp`) | `56-1.bmp` .. `65-4.bmp` |
| **200..215** | Victory Cheer / Emote / Wave | 8 headings x 2 frames | `66-1.bmp` .. `73-2.bmp` |

---

## 3. ArchiveLoader Compositing Engine (`scripts/core/archive_loader.gd`)

### Dynamic Frame Bounds
```gdscript
var total_frames: int = mini(body_anim.frames.size(), 216) if (body_anim and body_anim.frames.size() > 0) else 216
```
- Determines frame count dynamically from base body animation, defaulting to 216 when body animation has >= 216 frames.
- Safely composites all active equipment layers (body, clothes, shoes, hair, cap, weapon) across all 216 frames.

### Layer Bounds & Out-of-Bounds Safety
Equipment layers vary in frame count depending on the item type (e.g., weapons often contain 192 frames; certain boots/robes contain 200 frames):
```gdscript
for anim in cur_layers:
    if not anim or frame_idx >= anim.frames.size():
        continue
    var j_frame = anim.get_frame(frame_idx)
    if not j_frame or j_frame.width <= 0 or j_frame.height <= 0:
        continue
    var layer_img: Image = anim.decode_frame_image(frame_idx)
    if layer_img:
        var ox: int = int((j_frame.bound_w - 128) / 2) if j_frame.bound_w > 128 else 0
        var oy: int = int((j_frame.bound_h - 128) / 2) if j_frame.bound_h > 128 else 0
        canvas.blend_rect(
            layer_img,
            Rect2i(0, 0, j_frame.width, j_frame.height),
            Vector2i(j_frame.pivot_x - ox, j_frame.pivot_y - oy)
        )
```
- Dialogue face expression portraits (20 frames) are excluded from full body walk/action layering.
- Weapon layer is drawn behind torso when facing South/East/West (headings 2..6) and in front when facing North (headings 0, 1, 7).

---

## 4. PlayerEntity Motion State Machine (`scripts/world/player.gd`)

### MotionState Enum
```gdscript
enum MotionState {
    WALK,
    IDLE,
    SIT,
    ATTACK,
    DEFEND,
    PRONE,
    VICTORY
}
```

### Public API Methods
- `play_sit_animation()`: Transitions to `MotionState.SIT`. Cycles sitting frames 64..95. Movement stopped.
- `play_stand_animation()`: Transitions to `MotionState.IDLE`. Releases prone and unlocks movement.
- `play_attack_animation()`: Transitions to `MotionState.ATTACK`. Cycles combat weapon strike frames 112..143.
- `play_hurt_animation()`: Transitions to `MotionState.DEFEND`. Cycles hit recoil frames 144..175.
- `play_victory_animation()`: Transitions to `MotionState.VICTORY`. Cycles cheer/emote frames 200..215.
- `set_prone(prone: bool)`: Sets or releases prone state (`MotionState.PRONE`). Locks kinematics while prone.
- `get_prone_frame_index() -> int`: Returns authentic prone frame index (index 105: `26-2.bmp`).

### Kinematic & Input Behaviors
1. **Prone Lock:** When `motion_state == MotionState.PRONE` or `is_prone == true`, `set_target_world_position` rejects pathing requests and emits `movement_blocked`.
2. **Sitting Auto-Stand:** When sitting (`MotionState.SIT`), requesting movement via click-to-move or keyboard automatically calls `play_stand_animation()` and commences walking.
3. **Movement Transitions:** When moving (`is_moving == true`), ground state transitions to `MotionState.WALK`. When stopping, ground state transitions to `MotionState.IDLE`.

---

## 5. Verification Suite

The verification script `tests/test_character_normal_animations.gd` validates:
1. `ArchiveLoader.get_player_composite_frames(6)` yields exactly 216 frames.
2. `ArchiveLoader.get_player_composite_frames(2)` yields exactly 216 frames.
3. Pixel validation confirms non-empty rendering across:
   - Walk frames (0, 8, 16, 24)
   - Idle frames (32, 48)
   - Sitting frames (64, 80, 92)
   - Attack strike frames (112, 128, 140)
   - Defend recoil frames (144, 160)
   - Prone & rising frames (105, 104)
   - Knockout & victory emote frames (192, 200, 215)
4. State transitions: `IDLE` -> `WALK` -> `SIT` -> `ATTACK` -> `DEFEND` -> `VICTORY` -> `STAND` -> `PRONE` -> `IDLE`.
5. Kinematic movement rejection during prone and auto-standing during sitting.
