# Ship Cabins (Map 10002 & Map 10003) & Dialogue System Technical Specification

## Overview
This document specifies the authentic architecture, portal geometry, collision bounds, NPC placement, dialogue tree branching, avatar bust streaming from `008.jma`, and ground item harvesting mechanics for **Map 10002 (Passenger Cabin)** and **Map 10003 (Ship Kitchen / Bunk)** in Wonderland Online, verified against original client binary tables (`Talk.dat`, `Npc.dat`, `Eve.emg`, `Ground.MMG`, `Wem.MMG`) and intro video footage (seconds 116–175).

---

## 1. Map Architecture & Geometry

### Map 10002: Passenger Cabin
- **Scene Dimensions**: 1659 x 1266 px (83 x 64 isometric tiles, 20px/tile).
- **Background Asset**: `t10002.bmp` rendered via [`MapRenderer`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/map_renderer.gd).
- **Staircase Portals**:
  - **Portal 1 (Up to Ship Deck 10001)**: Position `Vector2(674, 1067)` -> Deck destination `Vector2(1814, 904)`, radius `56.0` px, trigger type `1`.
  - **Portal 2 (Down to Ship Kitchen / Bunk 10003)**: Position `Vector2(483, 631)` -> Kitchen destination `Vector2(420, 360)`, radius `56.0` px, color `Color(0.3, 0.85, 0.5, 0.85)`.
- **NPC Occupants**:
  - **Drunk Man**: NPC ID `14042`, sprite `1050.jmp`, TID `8017`, position `Vector2(851, 539)`, heading `NORTH_WEST`. Talk ID `30127`.
  - **Peter**: NPC ID `14146`, sprite `1050.jmp`, TID `8017`, position `Vector2(1302, 800)`, heading `NORTH_EAST`. Talk ID `30160` -> Branches `30161` / `30162`.
  - **John**: NPC ID `14145`, sprite `1050.jmp`, TID `8017`, position `Vector2(1309, 714)`, heading `SOUTH_EAST`. Talk ID `30163` -> Branches `30164` / `30165`.
  - **Natasha**: NPC ID `14303`, sprite `1068.jmp`, TID `8083`, position `Vector2(1440, 682)`, heading `SOUTH_WEST`. Talk ID `30166` -> Branches `30167` / `30168`.
  - **Breillat**: NPC ID `10000`, sprite `1170.jmp`, TID `8092`, position `Vector2(1155, 580)`, heading `SOUTH_WEST`. Talk ID `30139`.
  - **Arcade Machines**: IDs `18000` (`1088.jmp` at `226, 795`) and `18001` (`1089.jmp` at `141, 829`).

### Map 10003: Ship Kitchen / Bunk
- **Background Asset**: `t10003.bmp` rendered via [`MapRenderer`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/map_renderer.gd).
- **Staircase Portal**:
  - **Portal Up to Cabin 10002**: Position `Vector2(420, 360)` -> Cabin destination `Vector2(530, 670)`, radius `56.0` px, color `Color(0.3, 0.85, 0.5, 0.85)`.
- **NPC Occupants**:
  - **Chef**: NPC ID `12006`, sprite `1144.jmp`, TID `8021`, position `Vector2(780, 520)`, heading `SOUTH_EAST`. Talk ID `30170` -> Branches `30171` ("Can I have some food?") / `30172` ("Smells delicious!").
  - **Kitchen Crew**: NPC ID `14002`, sprite `1037.jmp`, TID `8026`, position `Vector2(950, 480)`, heading `SOUTH_WEST`. Talk ID `30173`.
  - **Bunk Crew**: NPC ID `14001`, sprite `1037.jmp`, TID `8026`, position `Vector2(620, 680)`, heading `NORTH_EAST`. Talk ID `30174`.
- **Interactive Ground Harvestable Items**:
  - **Apple**: Item ID `41040`, slot `1`, click ID `101`, icon `1001.bmp`, position `Vector2(710, 560)`, respawn `120.0` s.
  - **Bread**: Item ID `32011`, slot `2`, click ID `102`, icon `1011.bmp`, position `Vector2(860, 540)`, respawn `120.0` s.
  - **Cutlery**: Item ID `10002`, slot `3`, click ID `103`, icon `1120.bmp`, position `Vector2(800, 600)`, respawn `120.0` s.

---

## 2. Dialogue & Avatar Engine Implementation

### Input Progression & Dismissal
- **Mouse Click**: Left-click on `dialogue_bg` or screen unhandled click advances to next dialogue page or dismisses when on last page.
- **Keyboard Navigation**:
  - `KEY_SPACE`: Advances dialogue page or dismisses active dialogue when focus is not on `chat_input`.
  - `KEY_ENTER` & `KEY_KP_ENTER`: Advances dialogue page or dismisses active dialogue.

### Branching Choices System (`FormTalk3`)
- Multi-choice branches are populated into `choices_container` (`$DialogueSystem/FormTalk3/ChoiceList`).
- Interactive buttons connect to `_on_choice_clicked.bind(choice_idx, choice_text)`.
- Dispatches user selection to `_current_choice_callback`, triggering chained dialogue continuation.

### Authentic Animated Avatar Busts (`008.jma`)
- Portraits decode directly from archive `008.jma` using the NPC's `talk_image` TID:
  - Captain Robinson: TID `8025` (`8025.jmp`)
  - Jack: TID `8004` (`8004.jmp`)
  - Ross: TID `8005` (`8005.jmp`)
  - Peter / John / Drunk Man: TID `8017` (`8017.jmp`)
  - Chef: TID `8021` (`8021.jmp`)
  - Crew (Kitchen / Bunk / Deck): TID `8026` (`8026.jmp`)
  - Natasha: TID `8083` (`8083.jmp`)
  - Breillat: TID `8092` (`8092.jmp`)
- Frames cycle between talking and blinking states automatically at 4 FPS (`0.25s` interval).

---

## 3. Automated Verification & Test Results

All test suites executed headlessly and passed with 100% success:

1. **`scenes/tests/test_dialogue_cursor_and_ui.tscn`**:
   - `[PASS]` Top-Left Avatar aperture scaling and positioning verified: pos=(18, 18), size=(64, 64)
   - `[PASS]` All redundant window title text labels verified hidden (Delphi skin bitmaps have baked titles)
   - `[PASS]` Single-page dialogue dismissal on background click verified
   - `[PASS]` Multi-page dialogue sequence progression and dismissal on screen click verified
   - `[PASS]` Space key dialogue sequence progression and dismissal verified
   - `[PASS]` Enter and Keypad Enter key dialogue sequence progression and dismissal verified
   - `[PASS]` Branching dialogue choice display and interactive button selection verified
   - `[PASS]` Authentic TID avatar bust decoding verified (Captain=8025, Chef=8021, Natasha=8083)
   - `[PASS]` Map 10002 staircase portals verified: Up to Deck (10001 at 674, 1067), Down to Kitchen (10003 at 483, 631)
   - `[PASS]` Map 10003 staircase portal verified: Up to Cabin (10002 at 420, 360 -> 530, 670)
   - `[PASS]` Map 10003 Kitchen NPCs (Chef, Kitchen Crew, Bunk Crew) & Harvestables (Apple, Bread, Cutlery) verified
   - `[PASS]` In-world interactive kitchen ground item harvest executed cleanly
   - `[PASS]` Authentic TalkDatabase dialogue trees & choice branches verified (Peter, John, Natasha, Chef, Crews)
   - `[PASS]` ChatDock panel style verified
   - `[PASS]` Global CursorManager all 5 authentic cursor states & 10 FPS animation loop verified

2. **`tests/test_talk_database.gd`**:
   - 10/10 tests passed (100%). Total decoded dialogue records: 17,493.

3. **`tests/test_portals_and_ground_items.gd`**:
   - 5/5 parts passed (100%). Ground.MMG, Wem.MMG, Eve.emg, Portal door-light blending, and GroundItem harvesting verified.

4. **`scripts/tests/test_collision_and_pathfinding.gd`**:
   - 7/7 tests passed (100%). Column-major grid, Map 10001 railings, Map 10002 cabin furniture, corner cutting prevention, and player kinematics verified.
