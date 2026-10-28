# Portal, Ground Item, and Map Systems Specification

## Overview
This document specifies the technical architecture, binary decoding, rendering rules, collision boundaries, and interactive behaviors for **Portals (Warp Gates)**, **Ground Items**, and **Map Fallback Backgrounds** in the Wonderland Online Godot client ([`GroundParser`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/ground_parser.gd), [`EveParser`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/eve_parser.gd), [`Portal`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/portal.gd), and [`MapRenderer`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/map_renderer.gd)).

---

## 1. Portal (Warp Gate) System

### Rendering & Visual Pipeline
- **Class Implementation:** [`Portal`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/portal.gd) extending `Node2D`.
- **DoorLight & SmallDoor Animation:**
  - **Outdoor Large Portals (`PortalType.DOOR_LIGHT`):** Uses authentic 13-frame WLM door light sprites (`Atlas_DoorLight.png`) with vertical offset `Vector2(0, -42)` positioning the light cone directly over door thresholds, pulsating at authentic 8.0 FPS.
  - **Indoor Small Portals (`PortalType.SMALL_DOOR`):** Uses 4-frame door light sprites (`Atlas_SmallDoorLight.png`) with vertical offset `Vector2(0, -22)` pulsating at authentic 3.5 FPS to prevent rapid fluttering and deliver a smooth magical glow.
- **Additive Blending:** Applied via `CanvasItemMaterial` with `BLEND_MODE_ADD` to achieve the authentic glowing magical aura characteristic of Wonderland Online warp gates.
- **Ground Circles Removal:** Ground circles and ellipse rings are entirely removed (`_draw()` is a pass) to prevent artificial circular artifacts on terrain.
- **Label Display Suppression:** Floating name labels above portals are unconditionally suppressed (`label.visible = false`, `label.text = ""`), matching authentic Wonderland Online aesthetics where warp doorlights have no text floating over them.

### C# Server Geometric Reverse Warp Parity (`Map.cs` lines 975-1025)
- **Algorithm Parity:** Implements the exact reverse warp matching logic from C# server `wlo.pserver.core/Game/Maps/Map.cs`:
  1. **Priority 1 (Explicit Door Match):** Checks if an unclaimed Door (`trigger_type == 2`) within 600px matches the warp via `w.click_id in ep.event_ids` or `w.click_id == ep.click_id`.
  2. **Priority 2 (C# Priority A - Geometric Reverse Matching):** Finds the return warp on `w.target_map_id` leading back to `map_id` (`rev_w.target_map_id == map_id`) with return coordinates `rev_pos = Vector2(rev_w.dest_x, rev_w.dest_y)`. Selects the closest unclaimed EntryPoint `ep` where `ep.center_px.distance_to(rev_pos) < 600.0`.
  3. **Priority 3 (C# Priority B - Event & Click ID Fallback):** Matches unclaimed EntryPoints by `w.click_id == ep.click_id` or `w.click_id in ep.event_ids`.
- **Doorway Threshold Alignment:** Portals are placed at the physical doorway threshold (`ep.center_px`), not at the target spawn coordinate.
- **Interior Safety Bounds Clamping:** For small rooms (e.g. 12001, 12002, 12003, 12004, 12005) whose dimensions are <= 832x640, out-of-bounds destinations (e.g. `(3407, 2420)`) are safely clamped to `Vector2(400, 380)` to prevent spawning players in the black void outside map geometry.
- **Bijective Non-Colliding Spawns:** Player spawn locations inside interior maps (e.g. `(335, 442)` in Chief House 12001) are physically separated from the exit portal doorway (`(240, 500)` by 111.3px), preventing immediate bounce-back teleport loops.
- **Handcrafted Verified Ship Portals:** Ship decks, cabins, and kitchens (maps 10001, 10002, 10003) use verified bijective portal links:
  - 10001 Ship Cabin Entrance: `(1814, 904)` -> 10002 at `(674, 1067)`.
  - 10001 Gangway: `(1038, 2235)` -> 10003 at `(134, 1126)`.
  - 10002 Exit to Deck: `(674, 1067)` -> 10001 at `(1814, 904)`.
  - 10002 Stairs to Kitchen: `(483, 631)` -> 10003 at `(483, 631)`.
  - 10003 Stairs to Cabin: `(420, 360)` -> 10002 at `(530, 670)`.
  - 10003 Gangway to Deck: `(134, 1126)` -> 10001 at `(1038, 2235)`.

### Positioning & Threshold Detection
- **Z-Sorting:** Dynamically calculated based on world Y-coordinate (`z_index = int(position.y) - 5`) ensuring proper depth sorting relative to player and NPC feet.
- **Threshold Distance & Cell Match:** 
  - Calculates 2:1 axonometric distance: `dx = player_pos.x - portal_pos.x`, `dy = (player_pos.y - portal_pos.y) * 2.0`, `dist = sqrt(dx*dx + dy*dy)`.
  - Triggers teleportation when `dist <= trigger_radius` (default 56.0 pixels) or when the player's 20x20 cell matches the portal's cell coordinate.
- **Click-to-Path Interaction:** Clicking left-mouse button within `trigger_radius` sets the player target world position to the portal location.

---

## 2. Ground Item System

### Rendering & Visual Pipeline
- **Class Implementation:** [`GroundItem`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/ground_item.gd) extending `Node2D`.
- **Static Positioning & Hover Tooltip:**
  - Items remain firmly anchored on the ground terrain without vertical floating/bobbing.
  - Item names appear exclusively on mouse hover (`mouse_pos.distance_to(global_position + Vector2(0, -6)) <= 28.0`).
- **Blue Aura & Glints:**
  - Draws a 2:1 axonometric drop shadow ellipse beneath the item.
  - Renders a pulsing blue glowing aura ring (`Color(0.2, 0.65, 1.0)`) with rotating particle glints (`draw_circle`) for high visual fidelity.
- **Flight Tween & Notification Toast:**
  - When picked up, the item performs a quadratic ease-in tween flying towards the player (`global_position`, scale reduction to `0.3`), triggering `item_picked_up`.
  - Central notification toast confirms item acquisition.
- **Respawn Loop:** Supports configurable `respawn_seconds` (default 120.0s) timer before item reappears on the map.

---

## 3. MapRenderer & Fallback Backdrop Pipeline

### Visual Continuity for Maps Without Static Archive JPEGs
- **Problem Statement:** In Wonderland Online data archives (`map.JMG`), 765 maps (such as 12008 Cave/Woods) do not contain static pre-rendered background `.jpg` images. In vanilla clients, these rely on tile-by-tile floor composition. Without a background texture, clients previously rendered a black void with zero camera boundaries (`background_size = Vector2.ZERO`).
- **Procedural Isometric Slate Cavern Generator (`_get_fallback_dungeon_texture()`):**
  - Generates a 3200x2800 pixel procedural isometric stone slate floor texture in under 6 milliseconds.
  - Implements alternating rhombic stone pavers, mortar gaps, and subtle luminescent mineral fissures (`Color(0.18, 0.22, 0.26)` to `Color(0.24, 0.30, 0.34)`).
  - Establishes full navigation, collision boundaries, and camera clamping (`cam.limit_right = 3200`, `cam.limit_bottom = 2800`).
- **ArchiveLoader Fallback Integration:**
  - [`MapRenderer._get_archive_loader()`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/map/map_renderer.gd) checks `/root/ArchiveLoader` first; if uninstantiated (such as in headless test runs), automatically creates and initializes `ArchiveLoader` so maps always resolve authentic background textures from `map.JMG`.

---

## 4. Test Verification Suites

- **C# Parity Portals and Maps Test:** [`tests/test_csharp_portals_and_maps.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_csharp_portals_and_maps.gd)
  - Section 1: EveParser EntryPoint 32-byte binary unpacking.
  - Section 2: Map 12000 Kelan Village 8-portal door threshold and C# server destination verification.
  - Section 3: Map 12001 Chief House interior exit doorway and spawn point collision separation (111.3px).
  - Section 4: Ship deck, cabin, and kitchen bijective portal connectivity.
  - Section 5: Portal visual label suppression and DoorLight sprite offset.
  - Section 6: MapRenderer background loading (12000 at 3328x2560, 12001 at 832x640, and 12008 procedural fallback at 3200x2800).
- **Portal & Ground Item Harvesting Test:** [`tests/test_portals_and_ground_items.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_portals_and_ground_items.gd)
  - Full suite testing Wem.MMG, Ground.MMG, Eve.emg, additive doorlight blending, and ground item hover/harvesting.
