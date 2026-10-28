# Beach Awakening Map 10011 (Deserted Island Beach)

## Overview
Map `10011` represents the **Deserted Island Beach** where characters wash ashore following the shipwreck sequence (covered in frames `sec_241.png` through `sec_320.png` of the video analysis).

## Key Components & Scene Characteristics
1. **Player Awakening Sequence**:
   - Ground truth frames: `sec_241.png` to `sec_320.png`.
   - Visual portrayal: The player character lies on the tropical beach sand, executing an animated get-up sprite sequence transitioning from prone to standing.
2. **NPC Integration (Kelang)**:
   - NPC ID and talk sequences situated near the shoreline.
   - Kelang greets the player, providing orientation on the deserted island and initiating the primary awakening questline.
3. **Environment & Visuals**:
   - Shoreline water animation featuring gentle tide cycles.
   - Shipwreck wooden debris scattered along the sand.
   - Tropical foliage backdrop consistent with Wonderland Online's opening island zones.
4. **Scene & Event Scripting**:
   - Integrated into the map system (`scenes/maps/` and `scripts/map/`).
   - Event triggers handle the initial camera pan, player wake-up animation state, and dialog box initialization with Kelang.
