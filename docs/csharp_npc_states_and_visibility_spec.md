# C# NPC States & PreEvent Visibility Synchronization Specification

## Overview
This specification details the porting and synchronization of authentic Non-Player Character (NPC) visibility rules, lifecycle stages, and state attributes from the Wonderland Private Server (`wlo.pserver.core`) into the Godot 4 client.

Primary C# reference sources:
- `wlo.pserver.core/Game/QuestRelated/PreEventInterpreter.cs`: `ShouldNpcBeVisible`, `EvaluateMapPreEvents`, per-player scene isolation, quest lifecycle visibility, and `Eve.emg` PreEvent bytecode execution.
- `wlo.pserver.core/Game/Maps/Code/QuestNpc.cs`: `HP`, `SP`, `Element`, `Level`, `WalkBehavior`, `WalkSteps`, `IsWildMonster`, `IsStaticNpc`, and `IsBroken` gathering/defeat states.
- `wlo.pserver.core/Game/Maps/Map.cs`: Wire protocol AC 22:4 actor show/hide packet definitions (`0xFFFF` despawn state with `0x03E7FC18` duration code vs `0x00` visible reveal frame).
- `wlo.pserver.core/Game/Maps/Code/EveEventRuntime.cs`: `MatchesPreEventCondition`, compound condition grouping, and evaluation operators.

---

## Architecture & Class Design

### 1. NpcStateEvaluator (`scripts/map/npc_state_evaluator.gd`)
A dedicated evaluator providing static and instance evaluation methods for NPC visibility, lifecycle stages, and state attributes.

#### Core Constants
- `QUEST_IN_PROGRESS: int = 1`
- `QUEST_NOT_STARTED: int = 2`
- `QUEST_COMPLETED: int = 3`

#### Method Signatures

```gdscript
static func should_npc_be_visible(
	map_id: int,
	click_id: int,
	quest_states: Dictionary = {},
	party_companions: Array = [],
	player_pets: Array = [],
	is_broken: bool = false,
	eve_parser: EveParser = null
) -> bool
```
- **Parameters**:
  - `map_id` (`int`): Target map ID (1..65535).
  - `click_id` (`int`): Target entity click ID on the map.
  - `quest_states` (`Dictionary`): Current player quest states mapping quest IDs to integer states (`1`, `2`, `3`) or dictionaries (`{"state": int, "step": int}`).
  - `party_companions` (`Array[int]`): Template IDs of story companions currently recruited in the active party.
  - `player_pets` (`Array[int]`): Template IDs of active/stored pets.
  - `is_broken` (`bool`): Whether the entity is currently in a broken or defeated state.
  - `eve_parser` (`EveParser`): Optional binary parser instance to read Category 0 NPC headers and Category 9 PreEvents.
- **Returns**: `bool` — `true` if the entity should be spawned/visible and interactive; `false` if concealed/despawned.
- **Edge Cases & Priority Order**:
  1. *Defeated wild monsters*: When `is_broken == true`, returns `false`.
  2. *Story companions in party*: If the entity's `template_id` / `npc_id` is in `party_companions`, returns `false` to prevent duplicate NPC standees while traveling with the player.
  3. *Map 12000 Kelan Village Lifecycle Rules*:
     - Scenery Props (ClickID 10, 31 Guideposts, ClickID 17 Honeycomb): Always `true`.
     - Staged Cutscene Roca (ClickID 32): Always `false` in normal overworld; only dynamically staged during Quest 13098 Step 3 events.
     - Lina's Permanent Dog (ClickID 29): Always `true`.
     - Lina's Lost Dog (ClickID 28): Hidden while Quest 13046 is `NotStarted` (2) or (`InProgress` at step < 2 and flag 13047 != 1). Visible when step >= 2, `Completed` (3), or flag 13047 is set.
     - Lost Shiba Inu in trees/hogpen (ClickID 20): Visible ONLY when Quest 13046 is `InProgress` at Step 1 and flag 13047 != 1; hidden otherwise.
     - Baby Bees (ClickID 18 & 19): Hidden when Quest 13023 is `NotStarted` (2); visible once accepted or completed.
     - Staged Pig (ClickID 14): Visible when Quest 12020 is `InProgress` at step >= 2, `Completed` (3), or flag 12021 is set; hidden otherwise.
     - Stray Pig (ClickID 15): Visible ONLY when Quest 12020 is `InProgress` at step 1; hidden otherwise.
     - Staged Pig (ClickID 16): Hidden when Quest 13020 is `NotStarted` (2) or flag 13021 is set; visible otherwise.
  4. *Map 11016 Starter Beach*:
     - S. Monkey (ClickID 1, TID 17162): Returns `false` if monkey (TID 17162 or 10727) is in `party_companions`, `player_pets`, or Quest 12002 is `Completed`; returns `true` when unrecruited.
  5. *Map 11040 Clive's Actor*:
     - Clive (ClickID 4): Visible when Quest 13102 is `InProgress` at step 4 and Quest 13103 is not started.
  6. *Map 12002 Xaolan Story Stages*:
     - ClickID 2 & 7: Suppressed if Xaolan is in fate (flags 13004 or 13005).
     - ClickID 2 & 3: Evaluated against Quest 13033 rescue stages.
  7. *Map 60002 Hot Spring Departure*:
     - ClickID 43 & 44: Evaluated against Quest 50042 departure stages.
  8. *EVE Binary Entity Flags*:
     - Bit 0 of `unknownbyte1` (`entity_type`) dictates initial visibility: `visible = ((entity_type & 1) != 0)`.
     - Ephemeral / staged actors marked with `entity_type == 2` or `entity_type == 4` have bit 0 == 0 and are concealed by default.
  9. *Category 9 PreEvent Bytecode Evaluation*:
     - Applicable PreEvents from `Eve.emg` are evaluated against current quest marks. Action type 2 conceals (`visible = false`), action type 3 reveals (`visible = true`).

```gdscript
static func get_npc_state(
	map_id: int,
	click_id: int,
	eve_parser: EveParser = null,
	game_db = null
) -> Dictionary
```
- **Returns**: Complete dictionary matching C# `QuestNpc`:
  - `template_id`: int
  - `name`: String (canonical name from `all_npcs.json` / `Npc.dat` or EVE)
  - `level`: int
  - `hp`: int
  - `max_hp`: int
  - `sp`: int
  - `max_sp`: int
  - `element`: int (0=None, 1=Earth, 2=Water, 3=Fire, 4=Wind)
  - `entity_type`: int (1=living NPC, 2/4=staged prop/actor)
  - `walk_behavior`: int (1=Static, 2=Patrol, 3=Bounding Box Wander, 4=Roaming)
  - `walksteps`: Array[Vector2]
  - `walkstep_delays`: Array[float]
  - `rotation`: int (1..8)
  - `heading`: int (`IsometricMath.Heading`)
  - `world_position`: Vector2
  - `is_wild_monster`: bool
  - `is_static`: bool
  - `talk_id`: int
  - `dialogue_text`: String
  - `dialogue_choices`: Array[String]

---

### 2. Category 9 PreEvent Binary Parsing (`scripts/map/eve_parser.gd`)
Added native decoding of Category 9 (`cat_offsets[9]`) within `Eve.emg`:
- `PreEventAction`: Captures `action_op`, `target_click_id`, `action_type` (2=Hide, 3=Show, 5=PropState, 7=Pose), `state1`, `state2`, and raw 21-byte record.
- `PreEventRule`: Captures compound condition blocks (`condition_op`, `word1` quest ID, `word2` state selector, `word3` parameter, packed `value`, and `comparison` operator `1=<, 2=>, 3=<=, 4=>=, 5==, 6=!=`).
- `PreEventEntry`: Aggregates grouped rules per parent event click ID.
- `get_preevents_for_map(map_id: int) -> Array[PreEventEntry]`: Cached per map ID.

---

### 3. NpcEntity State Extensions (`scripts/world/npc.gd`)
Added state fields and visibility safeguards matching C# `QuestNpc`:
- Exported properties: `hp`, `max_hp`, `sp`, `max_sp`, `element`, `walk_behavior`, `entity_type`, `is_broken`, `is_wild_monster`, `spawn_position`, `is_hidden_by_preevent`.
- `set_preevent_visibility(p_visible: bool)`: Updates `visible`, toggles `is_hidden_by_preevent`, stops movement kinematics if hidden, and disables `click_area.monitoring`, `monitorable`, and `input_pickable`.
- Guards in `_ready()`, `_process(delta)`, and `_on_click_area_input_event(...)` ensure hidden entities never animate, consume pathfinding cycles, or receive cursor clicks.

---

### 4. MapView Dynamic Integration (`scripts/map/map_view.gd`)
- In `_spawn_dynamic_map_npcs(target_map_id: int)`:
  - Invokes `NpcStateEvaluator.should_npc_be_visible(...)` prior to final presentation.
  - Automatically populates NPC `hp`, `max_hp`, `sp`, `max_sp`, `element`, `walk_behavior`, and `is_wild_monster`.
  - Applies `set_preevent_visibility(is_visible)`.
- Live API methods:
  - `set_quest_state(quest_id: int, state: int, step: int = 0) -> void`
  - `set_party_companion(companion_id: int, present: bool = true) -> void`
  - `refresh_npc_visibilities() -> void`

---

## Automated Verification Suite

The dedicated test suite `tests/test_csharp_npc_states_and_visibility.gd` validates all ported behaviors:
1. **Test 1**: Map 12000 Staged Cutscene Roca (ClickID 32) is concealed in normal overworld by default.
2. **Test 2**: Map 12000 Permanent Entities (Guideposts 10/31, Comb 17, Lina's dog 29) are visible.
3. **Test 3**: Map 12000 Lina's Lost Dog lifecycle matches all 4 stages (Unstarted, Searching, Found, Completed) across ClickIDs 20 and 28.
4. **Test 4**: Map 12000 Staged Pigs lifecycle matches stages across ClickIDs 14, 15, and 16.
5. **Test 5**: Map 12000 Baby Bees (ClickIDs 18 & 19) are concealed when unstarted and revealed when active.
6. **Test 6**: Map 11016 Starter Beach S. Monkey (ClickID 1) is revealed when wild, and concealed when recruited into party, added to pets, or Quest 12002 is completed.
7. **Test 7**: Story Companion party suppression hides Map 12001 Roca (ClickID 2) when traveling in party, and suppresses staged ClickID 3.
8. **Test 8**: Map 11040 Clive (ClickID 4) appears exclusively during Quest 13102 Step 4 recruit offer.
9. **Test 9**: Authentic NPC stats (Pig Lv.43 HP.448 SP.326 Earth, Comb prop, Bee mob) verified bit-exact against C# database defaults.
10. **Test 10**: Live `MapView` integration verifies dynamic visibility switching upon `set_quest_state(...)` calls without map reload.

Execution result:
```
=================================================================
--- TEST SUMMARY: 10 PASSED, 0 FAILED ---
=================================================================
ALL C# NPC STATES & VISIBILITY TESTS PASSED (100% ZERO-ERROR)!
```
Existing suite `tests/test_universal_map_and_npc_spawner.gd` also maintains a 10/10 (100%) pass rate.
