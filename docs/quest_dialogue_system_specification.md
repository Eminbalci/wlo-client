# Quest to Dialogue & Event System Specification

## Overview
This specification details the end-to-end architecture connecting quests to NPC dialogues, talk database chains, cutscene events, container interactions, and UI quest logs in the Wonderland Online Godot 4 client.

---

## 1. Core Architecture: `QuestDialogueComponent`

Located in `scripts/ui/quest/quest_dialogue_component.gd`, `QuestDialogueComponent` serves as the quest state evaluator and dialogue bridge.

### Signals
- `quest_dialogue_started(quest_id: int, npc_id: int)`: Emitted when an NPC matching an active quest objective is engaged.
- `quest_objective_completed(quest_id: int, step_index: int)`: Emitted whenever a quest step objective is fulfilled.
- `quest_completed(quest_id: int, rewards: Dictionary)`: Emitted upon completion of the final objective of a quest.
- `quest_reward_displayed(msg: String)`: Emitted with formatted reward text and triggers the `wav9911` fanfare audio.

### Objective Evaluation & Progression
Supports flexible objective types:
1. `TalkToNPC`:
   - Matches by primary `npc_id`, `alt_npc_ids` list, or substring matching on `npc_name`.
   - Triggers NPC conversation through `HUDDialogue`, `DialogueManager`, or `DialogueBox`.
   - Binds dialogue window closure (`dialogue_closed`) to `complete_objective(quest_id, step_index)`.
2. `SurviveSinking`:
   - Event objective triggered when the player survives the ship sinking cutscene and awakens on Monkey Beach (Map 10003).
   - Advanced via `quest_component.advance_objective_by_type("SurviveSinking")`.
3. `SearchContainer`:
   - Container objective triggered when opening washed-up wreckage chests and casks on Monkey Beach.
   - Advanced via `quest_component.advance_objective_by_type("SearchContainer")`.

---

## 2. Default Starter Quests

Pre-registered in `_init_starter_quests()` in `scripts/map/map_view.gd` to make the storyline playable from the first spawn on Ship Deck (Map 10001):

### Quest 1001: "The Awakening Voyage"
- **Step 0**: Talk to Captain Robinson (NPC 14003) on Ship Deck (Map 10001).
- **Step 1**: Survive Ship Sinking & Awaken on Deserted Island (Map 10003).
- **Step 2**: Talk to Kelang (NPC 12032) on Monkey Beach.
- **Rewards**:
  - Gold: 100
  - EXP: 250
  - Items: Fresh Coconut x3 (Item ID 41066, Icon 1379)

### Quest 1002: "Supplies from the Wreck"
- **Step 0**: Search washed up beach chests/containers.
- **Step 1**: Report back to Kelang (NPC 12032).
- **Rewards**:
  - Gold: 150
  - EXP: 300
  - Items: Protective EXP Pill x1 (Item ID 34026, Icon 1768)

---

## 3. MapView & HUD Integration

Located in `scripts/map/map_view.gd`:
- **Instance Management**: `ensure_quest_component() -> QuestDialogueComponent` provides lazy initialization and signal binding.
- **NPC Interaction Hook**: `_on_npc_interacted(npc: Node2D)` and `interact_with_npc_quest(npc_id, npc_name, talk_id)` evaluate active quest objectives. If an active quest matches, it shows NPC speech bubbles, displays HUD dialogue, and hooks completion upon dismissal.
- **Container Interaction Hook**: `_handle_container_npc_interaction(npc: Node2D)` advances `SearchContainer` objectives when beach chests/casks are looted.
- **Awakening Event Hook**: `_on_sinking_cutscene_finished()` advances `SurviveSinking` upon warping to Map 10003.
- **Reward Handling**:
  - Gold is credited to `HUD` and `PlayerEntity`.
  - EXP is credited to `PlayerEntity.exp_percent`.
  - Items are deposited via `hud.add_inventory_item(...)`.
  - Progress is persisted to `CharacterManager` save data.
  - Center toast notification and system chat announcements are displayed.
  - `_refresh_all_npc_quest_markers()` updates NPC quest exclamation indicators dynamically.

---

## 4. QuestWindow & QuestLogRichText BBCode Formatting

Located in `scripts/ui/hud/hud_window_manager.gd`:
- `update_quest_log(quests: Variant)` partitions active and completed quests with formatted BBCode:
  - `[b][color=#ffe066]--- ACTIVE QUESTS ---[/color][/b]`
    - Quest title, current step count `(Step %d/%d)`.
    - Checkmarked completed steps `[color=#66bb6a][x] Step description[/color]`.
    - Active step with pointer `[color=#ffd54f][→] Current objective[/color]`.
    - Upcoming steps `[color=#777777][ ] Pending objective[/color]`.
    - Formatted reward preview `[color=#ffcc33]Rewards: %s[/color]`.
  - `[b][color=#87ceeb]--- COMPLETED QUESTS ---[/color][/b]`
    - Completed quest titles with green checkmark `[color=#81c784]✓[/color]` and earned reward summary.

---

## 5. Automated Verification

Master test suite: `tests/test_quest_dialogue_connection.gd`:
1. `_test_quest_dialogue_registration`: Verifies Quest 1001 & Quest 1002 data structure initialization.
2. `_test_quest_1001_progression_and_completion`: Simulates Captain Robinson dialogue -> sinking cutscene -> Kelang beach talk -> 100 Gold, 250 EXP, Fresh Coconut x3 reward delivery.
3. `_test_quest_1002_container_and_completion`: Simulates container looting -> Kelang report -> 150 Gold, 300 EXP, Protective EXP Pill x1 reward delivery.
4. `_test_quest_window_bbcode_formatting`: Verifies QuestWindow rich text BBCode parsing, active/completed partitioning, and step checkboxes.
5. `_test_map_view_quest_component_integration`: Verifies MapView lazy initialization, signal wiring, and NPC interaction helper.
