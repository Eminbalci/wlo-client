# Ship Cabins Parity Verification (Maps 10002 & 10003)

This document establishes the verified parity specifications, layout geometries, NPC spawn parameters, and portal connections for **Map 10002** and **Map 10003** (Cruise Ship Passenger Cabins & Corridors), corresponding to ground-truth video frames `sec_116.png` through `sec_175.png`.

---

## 1. Architectural Layout & Room Geometry

- **Map 10002 (Passenger Cabin Interior / Suite A):**
  - **Dimensions:** Standard cabin grid (approx. 20x15 tiles).
  - **Flooring:** Red/brown patterned luxury carpet (`t10002.bmp`).
  - **Furniture & Props:** Twin wooden bunk beds, nightstands, study desk with lamp, and wardrobe cabinet (`Form_Cabinet.bmp`).
  - **Collision Boundaries:** Strict isometric bounding boxes preventing movement across bed frames, desks, and walls.

- **Map 10003 (Cabin Corridor & Suite B / Connecting Hallways):**
  - **Dimensions:** Long hallway layout connecting individual passenger cabins.
  - **Flooring:** Corridor carpeting with wood-paneled walls (`t10003.bmp`).
  - **Doors & Portals:** Seamless bi-directional portal triggers connecting Map 10001 (Main Deck) -> Map 10002 -> Map 10003.

---

## 2. NPC Spawn Positions & Talk Interactions

- **Cabin Steward / Passenger NPCs:**
  - **Spawn Coordinates:** Positioned near cabin entryways and corridor intersections.
  - **Interaction Radius:** 1.5 tile radius triggering dialogue box popup with matching talk script IDs from `talk_database.gd`.
  - **Facing State:** Default southern/western orientation with idle animation loops.

---

## 3. Portal Triggers & Deck Connectivity

- **Portal 1:** Map 10001 (Deck) coordinates `(X: 45, Y: 12)` -> Map 10002 Entrance `(X: 5, Y: 10)`.
- **Portal 2:** Map 10002 Interior -> Map 10003 Corridor transition at cabin exit door.
- **Verification Status:** Fully integrated into `portal.gd` and verified via pathfinding integration tests.
