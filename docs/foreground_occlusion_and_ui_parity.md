# Foreground Map Occlusion, Role Cutout Avatars, Quest Log, and 2-Slot Character Select

## 1. Universal Map Foreground Occlusion & Animated Background Objects (`ArchiveLoader` & `MapView`)

### Parameters & Archive Resolution
- **Method:** `ArchiveLoader.get_map_object_texture(event_id: int) -> ImageTexture`
  - **Parameters:** `event_id: int` (e.g., `10001029`, `10002009`).
  - **Returns:** `ImageTexture` extracted from `images1.BMg`, `images1_d01.BMg`, `images4.BMg`, `images4_c01.BMg`, or `images4_d01.BMg` with green (`Color(0, 1, 0)`) and magenta (`Color(1, 0, 1)`) chroma keys converted to alpha `0`.
- **Method:** `MapView._spawn_map_objects(map_id: int) -> void`
  - **Parameters:** `map_id: int` (target map ID, e.g., `10001`, `10002`, `10003`, `12000`).
  - **Behavior:**
    - Queries `GroundParser.load_map(lookup_map_id)` and `GroundParser.load_wem_event(t.event_id)` for all triggers on the map.
    - **Background Layer Objects (`wem.flag2 == 1` or `wem.flag3 == 1`):** Instantiated as `Sprite2D` children of `MapRenderer` (`z_index = 0`, behind `Entities`). Multi-frame vertical strips (`wem.trigger_type > 1`) animate at `float(wem.param) / 1000.0` seconds per frame.
    - **Foreground Occlusion Objects (`wem.flag2 in [3, 5]` and `wem.flag3 == 0`):** Instantiated as `Sprite2D` children of `Entities` (`y_sort_enabled = true`) at `sort_y = maxi(t.world_y + frame_h, t.world_y + wem.sub_id * 20)` with `offset = Vector2(0, -float(sort_y - t.world_y))` and `z_index = clampi(sort_y, -4096, 4096)`. Players and NPCs standing north of `sort_y` render behind ship masts, counters, railings, trees, and pillars.

## 2. Authentic Playable Role Cutout Avatars (`GameDatabase`, `ArchiveLoader`, `HUDPlayerStatus`)

- **Role Face Archives (`GameDatabase.ROLES`):**
  - Maps all 14 playable roles (`Role 1..14`) to their authentic `002f.jma`, `003f.jma`, `004f.jma`, and `005f.jma` cutout face `.jmp` files (`3600.jmp`, `3601.jmp`, `2600.jmp`, `5602.jmp`, `5601.jmp`, `4601.jmp`, `4600.jmp`, `5604.jmp`, `5605.jmp`, `5600.jmp`, `5606.jmp`, `4602.jmp`, `4603.jmp`, `5607.jmp`).
- **Method:** `ArchiveLoader.get_avatar_frames(role_id: int) -> Array[ImageTexture]`
  - Decodes frame `0` (`00-1.bmp` idle open eyes) and frame `1` (`00-2.bmp` blink closed eyes) onto a `72x72` RGBA8 canvas aligned at the bottom neck curve (`y = 72`).
- **HUD Placement (`HUDPlayerStatus` & `scenes/ui/hud.tscn`):**
  - `AvatarBg.visible = false` eliminates the opaque gray square behind the transparent cutout head.
  - `AvatarRect` is positioned at `Vector2(28, -7)` with `size = Vector2(72, 72)` so the curved neck sits flush on the oval rim (`y = 65`) of `StatusBackground`.

## 3. Centered 2-Slot Character Select & Separated Leave Button (`CharacterSelect`)

- **Scene & Script:** `scenes/ui/auth/character_select.tscn`, `scripts/ui/auth/character_select.gd`
- **Layout:**
  - `CardSlot0` (`offset_left = -349.0, offset_top = -196.0, offset_right = -12.0, offset_bottom = 156.0`) and `CardSlot1` (`offset_left = 12.0, offset_top = -196.0, offset_right = 349.0, offset_bottom = 156.0`) are both anchored to the screen center (`anchors_preset = 8`) so both `337x352` slots appear side-by-side and stay centered at any window resolution.
  - `BtnBack` (`[ Leave ]`) is placed outside the two character cards as a direct child of `CharacterSelect`, centered below the cards (`offset_left = -28.0, offset_top = 172.0, offset_right = 28.0, offset_bottom = 192.0`).

## 4. Map 10001 Patrol, Map 10003 Entities, Quest Log, and Speech Bubbles

- **NPC Patrol & Props (`NpcEntity`):**
  - `_process_walksteps(delta)` only enforces `map_data.is_walkable` when both start and target waypoints lie on walkable grid cells, allowing `CrewDeck1NPC` to patrol along the upper deck on Map 10001.
  - 2-frame interactive props (`Chest`, `Cask`, `Treas Ches`) display frame `0` when closed and transition to frame `1` (`is_broken = true`) upon interaction.
- **PreEvent Continuation Conditions (`EveParser` & `NpcStateEvaluator`):**
  - Preserves `blen2 == 0` continuation sub-conditions so all 8 `Eve.emg` entities on Map 10003 (`Robinson`, `Burke`, `Chest` x2, `Cask`, `Treas Ches` x2, `Coconut`) spawn and remain visible.
- **Quest Log & Overhead Speech Bubbles (`HUDWindowManager`, `NpcEntity`, `MapView`):**
  - `QuestWindow/QuestLogRichText` renders active and completed quests with objectives and rewards.
  - `NpcEntity.show_speech_bubble(text: String, duration: float)` renders an overhead speech bubble when interacting with NPCs alongside `FormTalk1` / `FormTalk3` dialogue windows.
