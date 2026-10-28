# Wonderland Online Dialogue & Talk.dat Engine

## Overview

The Wonderland Online Dialogue Engine provides bit-exact decoding, rich BBCode token formatting, NPC portrait animation streaming, emotion bubble reactions, and branching dialogue progression reverse-engineered from authentic client data files ([Talk.dat](file:///D:/GitHub/WLRI/data/Talk.dat), [Npc.dat](file:///D:/GitHub/WLRI/data/Npc.dat), [Eve.emg](file:///D:/GitHub/WLRI/data/Eve.emg), and [008.jma](file:///D:/Godot/WonderlandOnline/wonderland-online-client/assets/jma/008.jma)).

---

## Binary Data Specifications

### 1. Talk.dat Binary Structure
- **File Size**: 5,108,248 bytes
- **Record Count**: 17,494 records (Index 0 is null/header; Indices 1..17,493 are active dialogue entries)
- **Record Size**: 292 bytes fixed length
- **Header Encryption Cipher**:
  ```c
  ushort raw_u16 = *(ushort*)(buffer + offset);
  ushort decoded_word = ((raw_u16 ^ 0xECEA) - 5) & 0xFFFF;
  ```
- **Record Layout**:
  - `Offset 0..1`: Dialogue ID (`((word ^ 0xECEA) - 5) & 0xFFFF`)
  - `Offset 2`: Text String Length (`byte`)
  - `Offset 3`: Padding / control flags
  - `Offset 4..31`: Encrypted parameter words (Next Talk ID, speaker flags, conditions, choices)
  - `Offset 257 (292 - 35)`: Text Length Sentinel
  - `Offset 257 - Length`: Start of reversed XOR-encrypted text buffer:
    ```c
    byte decoded_byte = raw_byte ^ 0xEA;
    ```
  - Characters are reversed in memory; decoded sequentially by reversing indices.

### 2. Npc.dat Binary Structure
- **File Size**: 680,340 bytes
- **Record Count**: 4,930 records (Indices 1..4,929 active)
- **Record Size**: 138 bytes fixed length
- **Cipher Formula**:
  ```c
  ushort decoded_word = ((raw_u16 ^ 0x5209) - 1) & 0xFFFF;
  ```
- **Field Offsets**:
  - `Offset 0`: Name length byte (max 10)
  - `Offset 1..10`: ASCII/Big5 reversed name buffer
  - `Offset 12`: NPC ID (`ushort`, e.g., Captain = 14003, Jack = 14091, Ross = 14152)
  - `Offset 14`: Sprite ID (`ushort`, e.g., Breillat = 1170 -> `1170.jmp`, Persian Cat = 1035 -> `1035.jmp`)
  - `Offset 88`: `TalkImage` Portrait ID (`ushort`, e.g., Captain = 8025 -> `8025.jmp` in `008.jma`, Jack = 8004, Ross = 8005)

### 3. Portrait Packages (008.jma)
- All NPC talking and blinking portrait JMP animations reside in [008.jma](file:///D:/Godot/WonderlandOnline/wonderland-online-client/assets/jma/008.jma).
- Example: Captain (`8025.jmp`) contains 2 frames of 70x70 pixels:
  - Frame 0: Talking expression (open mouth / active dialogue).
  - Frame 1: Blinking / idle expression.

---

## Token Parsing & BBCode Formatting

Authentic WLO dialogue strings contain proprietary inline control tags:

| Token Pattern | Description | Translation Target |
|:---|:---|:---|
| `#n` or `#n/#n` | Player Name Placeholder | Replaced with active character name (e.g. `Adventurer`) |
| `#s<id>/#s` or `#s<id>` | Audio SFX Trigger | Extracted to trigger authentic WAV playback from `assets/sound/` |
| `#f<index>/#f` or `#f<index>` | Portrait Expression Frame | Extracted to select active talking frame (0, 1, etc.) |
| `#[Rr]<text>#[Rr]` or `#[Rr]<text>#W` | Red Text Highlight | Replaced with BBCode `[color=red]<text>[/color]` |
| `#[Bb]<text>#[Bb]` or `#[Bb]<text>#W` | Blue Text Highlight | Replaced with BBCode `[color=deep_sky_blue]<text>[/color]` |
| `#[Gg]<text>#[Gg]` or `#[Gg]<text>#W` | Green Text Highlight | Replaced with BBCode `[color=green]<text>[/color]` |
| `#[Yy]<text>#[Yy]` or `#[Yy]<text>#W` | Yellow Text Highlight | Replaced with BBCode `[color=yellow]<text>[/color]` |

---

## Class Architecture

### 1. [`TalkDatabase`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/database/talk_database.gd)
- **Extends**: `RefCounted`
- **Location**: [talk_database.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/database/talk_database.gd)
- **Key Methods**:
  - `load_from_file(talk_path: String, npc_path: String = "", eve_path: String = "") -> bool`
    - **Parameters**: File paths to `Talk.dat`, `Npc.dat`, and `Eve.emg`.
    - **Return**: `true` if loaded successfully.
    - **Exceptions**: Pushes error if file cannot be opened.
  - `get_talk(talk_id: int) -> Dictionary`
    - **Parameters**: `talk_id` (e.g. 30124).
    - **Return**: Dictionary containing `id`, `speaker`, `text`, `raw_text`, `next_talk_id`, `choices`, `conditions`, `rewards`, `sound_effect`, `face_index`.
  - `get_dialogue_chain(start_talk_id: int, max_depth: int = 10) -> Array[Dictionary]`
    - **Parameters**: Starting dialogue ID, maximum traversal depth.
    - **Return**: Ordered array of dialogue page dictionaries sequentially linked via `next_talk_id`.
  - `resolve_talk_for_npc(npc_id: int, map_id: int = 10001) -> Dictionary`
    - **Parameters**: NPC ID and current Map ID.
    - **Return**: Resolved dialogue record dictionary matching authentic quest and event states.
  - `format_tokens(text: String, player_name: String = "Adventurer") -> String`
    - **Parameters**: Raw dialogue text and player name.
    - **Return**: Rich Godot BBCode string.
  - `extract_sound_effect(text: String) -> String`
    - **Parameters**: Raw dialogue text.
    - **Return**: Extracted sound effect identifier string or empty string.
  - `extract_face_index(text: String) -> int`
    - **Parameters**: Raw dialogue text.
    - **Return**: Extracted integer face frame index.

### 2. [`NpcEntity`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/world/npc.gd)
- **Extends**: `Node2D`
- **Location**: [npc.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/world/npc.gd)
- **Key Properties**:
  - `@export var talk_id: int = 0`: Explicit dialogue override ID.
  - `@export var talk_image: int = 0`: Explicit portrait image ID.
  - `var emotion_container: Node2D`: Floating overhead emotion bubble node.
  - `var emotion_label: Label`: Visual label node for glyph rendering.
- **Key Methods**:
  - `show_emotion(emotion_type: String, duration: float = 2.0) -> void`
    - **Parameters**: Emotion type (`"!"`, `"?"`, `"heart"`, `"sweat"`, `"anger"`, `"shock"`, `"..."`), display duration.
    - **Behavior**: Spawns floating bubble with bounce tween and smooth fadeout.
  - `set_quest_marker(type: String) -> void`
    - **Parameters**: Marker type (`"available"`, `"turn_in"`, `"in_progress"`, `"none"`).
    - **Behavior**: Displays continuously bobbing gold `!` or gold `?` indicator.

### 3. [`HUD`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd)
- **Extends**: `CanvasLayer`
- **Location**: [hud.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/ui/hud.gd)
- **Key Additions**:
  - `portrait_frames: Array[Texture2D]`: Active multi-frame portrait animation buffer.
  - `_process(delta)`: Cycles between Frame 0 (talking) and Frame 1 (blinking) while dialogue window is visible.
  - `play_sfx(sfx_name: String) -> void`: Streams authentic WAV effects from `assets/sound/`.
  - `show_quest_reward(reward_name: String, count: int, gold: int, exp_pts: int) -> void`: Emits floating gold reward notification with fanfare audio.

---

## Edge Cases & Error Handling

1. **Reversed String Byte Offsets**:
   - `Talk.dat` record text offsets are calculated from the record tail: `offset + 292 - 35 - len`. If `len == 0` or length exceeds 254 bytes, record is marked invalid and safely skipped.
2. **Big5 vs ASCII Multi-Byte Characters**:
   - Decoding first checks UTF-8 validity, then Big5 traditional Chinese encoding, falling back to ASCII printable bytes (`32..126`) to eliminate corrupted control glyphs (`fffff` prefixes).
3. **Dialogue Loops & Infinite Chaining**:
   - `get_dialogue_chain` enforces a visited ID set (`visited[id] = true`) and a depth limit of 10 to protect against circular `next_talk_id` references.
4. **Missing or Incomplete Portraits**:
   - `_resolve_npc_portrait_frames` checks for `talk_image` in `008.jma`. If absent, it gracefully falls back to the NPC's in-world model frame or role avatar texture.
5. **Headless & Programmatic Node Safety**:
   - All `@onready` child references in `NpcEntity` guard against null pointers, permitting safe standalone execution in headless tests without scene dependencies.

---

## Verification Suite

- **Automated Test File**: [test_talk_database.gd](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_talk_database.gd)
- **Execution Command**:
  ```powershell
  C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s tests/test_talk_database.gd
  ```
- **Verification Matrix**:
  - Test 1: Bit-exact binary loading of 17,493 dialogues from `Talk.dat`.
  - Test 2: Standard dialogues (`10001` Yes, `10002` No, `20038` S.Monkey intro, `30124`/`30125` Captain, `30126` Jack, `30120` Ross).
  - Test 3: Multi-page dialogue chaining (`30124` -> `30125`).
  - Test 4: Branching choice options (Lake Spirit `30129` -> `30143` Golden Axe / `30144` Iron Axe).
  - Test 5: Token extraction and BBCode conversion (`#n`, `[color=red]`, `#s`, `#f`).
  - Test 6: NPC talk resolution across Map 10001 and Map 10002.
  - Test 7: `NpcDatabase` `talk_image` decoding (`8025` Captain, `8004` Jack, `8005` Ross).
  - Test 8: Portrait extraction and frame decoding from `008.jma`.
  - Test 9: `NpcEntity` emotion bubbles and bobbing quest markers.
  - Test 10: `GameDatabase` autoload singleton integration.
