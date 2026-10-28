# Portal and NPC Patrol System Technical Documentation

## 1. Overview
This document specifies the technical implementation of authentic warp portals, additive blending shader configurations, Eve.emg NPC rotation mappings, and waypoint-based NPC patrol movement AI.

---

## 2. Portal Transparency & Additive Blending

### Root Cause of Black Background
The WLM source texture `Atlas_DoorLight.png` was authored for Unity's `Mobile/Particles/Additive` shader (`Blend One One` / `Blend SrcAlpha One`). In this pipeline, the black background `RGB(0, 0, 0)` is intended to contribute zero energy to the frame buffer, rather than rely on alpha transparency.
When imported into Godot with default `BLEND_MODE_MIX`, Godot rendered the opaque black pixels `(0, 0, 0, 255)` as a solid black rectangular occluder over the ship deck.

### Solution
1. **Luminance Alpha Conversion**:
   - Re-sliced each of the 13 animation frames (`doorlight_00.png` through `doorlight_12.png`) and `doorlight_strip.png`.
   - Alpha channel recalculated as `alpha = min(255, int(max(r, g, b) * 1.5))`.
   - Dark background pixels `< 10` brightness are cleared to `(0, 0, 0, 0)`.
2. **CanvasItemMaterial Additive Blending**:
   - `_doorlight_sprite.material = CanvasItemMaterial.new()` with `blend_mode = CanvasItemMaterial.BLEND_MODE_ADD`.
   - Yields authentic glowing light columns with zero black artifacts.

---

## 3. Authoritative Portal Placement (SceneData.dat & Eve.emg)

### Coordinate Reconciliation
| Portal Identifier | Location | Target Map | Target Position | Eve.emg Source Entry |
|---|---|---|---|---|
| `CabinPortal` | Ship Deck `(1814, 904)` | Map 10002 (Cabin) | `(674, 1067)` | Map 10001 `WarpLoc[1]` (`船艙切換`) |
| `DeckPortal` | Cabin `(674, 1067)` | Map 10001 (Deck) | `(1814, 904)` | Map 10002 `WarpLoc[0]` (`類點1`) |
| `IslandPortal` | Shipwreck Trigger | Map 10003 (Beach) | `(1038, 2235)` | Map 10001 `WarpLoc[0]` (`沙灘至11016`) |

The ship deck cabin entrance is located at the wooden cabin door next to the starboard staircase at world coordinates `(1814, 904)`, rather than on the central mast.

---

## 4. NPC Rotations & Patrol Movement (Eve.emg)

### Rotational Direction Mapping
Wonderland Online aligns the 8-directional isometric angle as follows:
- `0`: South (S)
- `1`: South-West (SW)
- `2`: West (W)
- `3`: North-West (NW)
- `4`: North (N)
- `5`: North-East (NE)
- `6`: East (E)
- `7`: South-East (SE)

### Ship Deck Entities (Map 10001)
| NPC Name | Template ID | Model JMP | World Coordinates | Heading | Walk Steps (Patrol) |
|---|---|---|---|---|---|
| Jack | 14091 | `1010.jmp` | `(117, 1303)` | 6 (East) | Static |
| Ross | 14152 | `1207.jmp` | `(102, 1312)` | 6 (East) | Static |
| Crew 1 | 14002 | `1037.jmp` | `(343, 940)` | 4 (North) | Static |
| CrewDeck 1 | 14001 | `1037.jmp` | `(1461, 315)` | 6 (East) | `[(1462, 316), (1982, 601)]`, delay: 2.0s |
| Visitor 1 | 14080 | `1012.jmp` | `(855, 1302)` | 4 (North) | Static |
| Visitor 2 | 14087 | `1013.jmp` | `(814, 1313)` | 4 (North) | Static |
| Girl | 14065 | `1009.jmp` | `(1013, 902)` | 6 (East) | Static |
| Persian Cat | 11000 | `1035.jmp` | `(1027, 957)` | 6 (East) | `[(936, 942), (1126, 943)]`, delay: 3.0s |
| Crew 2 | 14002 | `1037.jmp` | `(1393, 578)` | 6 (East) | Static |
| Captain | 14003 | `1038.jmp` | `(1421, 632)` | 6 (East) | Static |
| CrewDeck 2 | 14001 | `1037.jmp` | `(405, 925)` | 6 (East) | Static |

### Autonomous Patrol Engine
When `walksteps` contains waypoints:
1. NPC determines direction vector towards active step index `diff = walksteps[idx] - world_position`.
2. Heading is dynamically set using `IsometricMath.get_heading(Vector2.ZERO, dir)`.
3. Entity plays running/walking frames (0..31) at 6 FPS.
4. Upon reaching destination within tolerance, entity enters idle state (`is_moving = false`), switches to standing frames (32..63), and counts down `walkstep_delays[idx]` before transitioning to next waypoint.

---

## 5. Dynamic Nameplate Grounding
Previous implementations offset nameplates blindly by `-canvas_height - 22 = -150px`. Because small animals (e.g., Persian Cat) are only ~25px tall and human avatars are ~70px tall within the 128x128 padded texture canvas, this caused labels to float high above entities and overlap entities behind them.

Labels are now positioned dynamically:
- Human NPCs / Player: `offset_top = -100.0`, `offset_bottom = -80.0`
- Persian Cat / Small Animals: `offset_top = -62.0`, `offset_bottom = -42.0`
- Arcade Machines: `offset_top = -107.0`, `offset_bottom = -87.0`
