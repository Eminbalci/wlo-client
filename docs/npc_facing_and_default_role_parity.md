# NPC Facing & Default Character Role Parity Specification

## 1. Context & Overview
Resolves Issue 2 (Deck NPC facing angles), Issue 4 (HUD avatar bust), and Issue 5 (Player character sprite and default clothing).

## 2. Issues Addressed
1. **Issue 4 (HUD Status Dock Avatar Bust):**
   - Previous behavior: HUD defaulted to Betty (Role 2, Wind) showing Betty's head bust with green/pink tones.
   - Fixed behavior: HUD defaults to Daniel (Role 6, Fire, max_hp=245, max_sp=180) loading Daniel's avatar bust (`avatar_role_6_0.png` and `avatar_role_6_1.png` / 8027.jmp from `008.jma`).
2. **Issue 5 (Player Sprite & Equipment in World):**
   - Previous behavior: Player entity defaulted to Betty (Role 2) wearing Betty's starter dress (`003e.jma:3301.jmp`).
   - Fixed behavior: Player entity defaults to Daniel (Role 6) equipped with Dust Coat (`004e.jma:4300.jmp`, Item ID 21004) and Gentleman's Shoes (`004s.jma:4400.jmp`, Item ID 24004). Nameplate displays "Daniel".
3. **Issue 2 (Ship Deck NPC Facing Directions):**
   - Previous behavior: Several NPCs in `scenes/world/map_view.tscn` faced awkward angles into bulkheads or away from walkways.
   - Fixed behavior:
     - `CaptainNPC` (14003, Robinson at 1421, 632): `heading = 6` (EAST, down the bridge towards the deck).
     - `Crew2NPC` (14002 at 1393, 578): `heading = 6` (EAST, facing walkway).
     - `GirlNPC` (14065 at 1013, 902): `heading = 3` (SOUTH_WEST, towards her cat).
     - `CatNPC` (11000 at 1027, 957): `heading = 7` (NORTH_EAST, towards the Girl).
     - `Crew1NPC` (14002 at 343, 940): `heading = 5` (SOUTH_EAST, towards walkway).
     - `CrewDeck2NPC` (14001 at 405, 925): `heading = 5` (SOUTH_EAST, towards walkway).
     - `Visitor1NPC` (14080 at 855, 1302): `heading = 4` (SOUTH, towards sea).
     - `Visitor2NPC` (14087 at 814, 1313): `heading = 4` (SOUTH, towards sea).
     - `JackNPC` (14091 at 117, 1303): `heading = 3` (SOUTH_WEST, over bow railing).
     - `RossNPC` (14152 at 102, 1312): `heading = 3` (SOUTH_WEST, over bow railing).

## 3. Modified Files
- `scripts/world/player.gd`: Default export variables set to Daniel (Role 6, HP 245, SP 180).
- `scenes/world/player.tscn`: Nameplate text set to "Daniel".
- `scripts/ui/hud.gd`: Fallback character data set to Daniel (Role 6, Fire, HP/SP 245/180).
- `scripts/ui/hud/hud_player_status.gd`: Default role set to 6, element Fire.
- `scripts/ui/hud/hud_character_status.gd`: Default role set to 6, element Fire.
- `scripts/map/map_view.gd`: Active character resolution falls back to `CharacterManager.get_character(0, "default")` or Daniel Role 6 with dynamic `player.set_role()` and `hud.apply_character_data()`.
- `scenes/world/map_view.tscn`: Player node export properties set to Daniel Role 6; 10 Ship Deck NPCs set to authentic facing angles.
- `tests/test_npc_positioning.gd`: Headless test runner verifying NPC positioning and headings.
- `tests/test_animated_avatar.gd`: Headless test runner verifying animated avatar frames, blinking, and default Daniel Role 6.

## 4. Verification Evidence
- `godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_npc_positioning.gd`: 100% PASS
- `godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s res://tests/test_animated_avatar.gd`: 100% PASS
- `res://tests/test_hud_chat_and_status_features.gd`: 100% PASS (0 ERRORS)
- `res://tests/visual_flow_inspector.gd`: 100% PASS
