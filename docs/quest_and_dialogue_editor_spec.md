# Wonderland Online - Quest & Dialogue Tree Authoring Tool Specification

## Overview
The **Quest & Dialogue Studio** (`QuestEditor`) is an interactive authoring, sequencing, dialogue previewing, and code generation suite for Wonderland Online in Godot 4. It supports designing quest storylines, multi-step mission sequences, dialogue token parsing, branching conversation trees, and rewards allocation.

- **Script Path:** `res://scripts/tools/quest_editor.gd`
- **Scene Path:** `res://scenes/tools/quest_editor.tscn`
- **Class Identifier:** `QuestEditor` (inherits `Control`)
- **Verification Suite:** `res://tests/test_quest_editor.gd` / `res://scenes/tests/test_quest_editor.tscn`
- **Minimum Canvas Size:** 800x600 (responsive dark styled interface)

---

## Architecture & Subsystems

```
QuestEditor (Control, 800x600)
├── Background (Panel with Dark Navy StyleBoxFlat: Color(0.05, 0.07, 0.1, 1))
└── MainVBox (VBoxContainer)
    ├── TopBar (PanelContainer)
    │   └── TopHBox
    │       ├── StudioTitle ("QUEST & DIALOGUE STUDIO")
    │       ├── VSep
    │       ├── OptPresets (OptionButton)
    │       ├── BtnNewQuest (Button)
    │       ├── BtnSaveJson (Button)
    │       ├── BtnLoadJson (Button)
    │       └── BtnExportScript (Button)
    ├── BodyHBox (HBoxContainer, 3-Column Responsive Layout)
    │   ├── LeftScroll (ScrollContainer, Width: 250px)
    │   │   └── LeftColumn (VBoxContainer)
    │   │       ├── HeaderPanel (PanelContainer: Quest ID, Title, Category, Min Level, Prereq ID, Repeatable, Description)
    │   │       └── RewardsPanel (PanelContainer: EXP, Gold, Skill ID & Name, Reward Items List, Item Adder)
    │   ├── CenterScroll (ScrollContainer, Width: 280px, Stretch Ratio: 1.2)
    │   │   └── CenterColumn (VBoxContainer)
    │   │       └── SequencerPanel (PanelContainer)
    │   │           ├── ListObjectives (ItemList)
    │   │           ├── HBoxSeqTools (Move Up, Move Down, Remove, Clear All)
    │   │           ├── OptStepType (TalkToNPC, CollectItem, DefeatMonster, ReachArea)
    │   │           ├── PanelStepTalk (NPC ID, Name, Talk ID, Preview Text, Fetch DB Button)
    │   │           ├── PanelStepItem (Item ID, Name, Count Required)
    │   │           ├── PanelStepMonster (Monster ID, Name, Defeat Count)
    │   │           ├── PanelStepArea (Map ID, Name, Target Pos X/Y, Radius)
    │   │           └── HBoxStepActionBtns (Add As New Step, Apply To Selected)
    │   └── RightScroll (ScrollContainer, Width: 260px)
    │       └── RightColumn (VBoxContainer)
    │           └── DialoguePanel (PanelContainer)
    │               ├── HBoxTalkLookup (Talk ID SpinBox, Preview Button)
    │               ├── LblPreviewSpeaker (Speaker name)
    │               ├── LblPreviewMeta (Portrait Face Index, Sound SFX tag)
    │               ├── PanelRichDlg (RichTextLabel: BBCode parsed dialogue text)
    │               ├── EditPreviewRaw (TextEdit: Raw ShortString text and tokens)
    │               ├── ListPreviewChoices (ItemList: Branching choice options)
    │               └── BtnFollowChoice (Button: Traverses choice branch to next Talk ID)
    └── StatusBar (PanelContainer)
        └── StatusLabel (Label: Operation feedback and diagnostic messages)
```

---

## Core Features & Functionality

### 1. Quest Header Configuration
Tracks global mission parameters matching Wonderland Online quest structures:
- `quest_id: int`: Unique quest identifier (e.g. 1001..9999).
- `quest_title: String`: Display title for player journals and tracker widgets.
- `quest_category: String`: Categorization dropdown: `"Main"`, `"Branch"`, `"Daily"`, or `"Event"`.
- `min_level: int`: Minimum character level requirement (1..200).
- `prerequisite_quest_id: int`: Previous quest prerequisite required before accepting (0 for starter quests).
- `is_repeatable: bool`: Flag indicating whether the quest can be reset and recompleted.
- `quest_description: String`: Multi-line synopsis and background narrative.

### 2. Multi-step Objective Sequencer
Supports arbitrary ordered sequences of objectives with real-time editing, reordering, and type polymorphism:
- **Objective Types:**
  - `TalkToNPC`:
    - `npc_id: int`: Target NPC entity identifier.
    - `npc_name: String`: NPC display name.
    - `talk_id: int`: `Talk.dat` dialogue pointer.
    - `dialogue_preview: String`: Short preview of conversation text.
  - `CollectItem`:
    - `item_id: int`: Target item identifier (resolved against `Item.dat`).
    - `item_name: String`: Item display name.
    - `count: int`: Number of items required in player inventory.
  - `DefeatMonster`:
    - `monster_id: int`: Target enemy identifier.
    - `monster_name: String`: Monster display name.
    - `count: int`: Number of kills required.
  - `ReachArea`:
    - `map_id: int`: Scene / Map identifier.
    - `map_name: String`: Map display name.
    - `target_pos: Vector2`: Spatial world coordinates for trigger circle.
    - `radius: float`: Radius of detection area in pixels (default: 64.0).
- **Sequencer Controls:**
  - `▲ Up` / `▼ Down`: Reorders step position in sequence without data corruption.
  - `Remove`: Deletes active selected step and re-indexes remaining steps.
  - `Clear All`: Resets sequence.
  - `+ Add As New Step`: Appends configured parameters as new step.
  - `Apply To Selected`: Mutates selected step with updated parameters.

### 3. Dialogue Previewer & Authentic Token Parser
Directly bridges with `GameDatabase.talks` (`Talk.dat`, `Eve.emg`, `Npc.dat`):
- **WLO Token Decryption & Parsing:**
  - `#n` or `#n/#n`: Substituted with player name (e.g. `"Adventurer"` or custom character name).
  - `#s<id>`: Sound effect identifier extracted into metadata readout and stripped from presentation text.
  - `#f<index>`: Portrait face index extracted into metadata readout and stripped from presentation text.
  - `#R...#W` / `#R...#R`: Red text converted to BBCode `[color=red]...[/color]`.
  - `#G...#W` / `#G...#G`: Green text converted to BBCode `[color=green]...[/color]`.
  - `#B...#W` / `#B...#B`: Blue text converted to BBCode `[color=deep_sky_blue]...[/color]`.
  - `#Y...#W` / `#Y...#Y`: Yellow text converted to BBCode `[color=yellow]...[/color]`.
- **Dialogue Traversal:**
  - Parses interactive choices (`choices: Array[Dictionary]`) with their target `next_talk_id`.
  - `Traverse Selected Branch` button jumps editor inspector to selected target Talk ID, enabling interactive narrative graph traversal.

### 4. Rewards Configuration
Configures completion payouts:
- `reward_exp: int`: Experience points awarded upon completion.
- `reward_gold: int`: Gold currency awarded upon completion.
- `reward_skill_id: int`: Optional skill unlock (resolves skill name via `GameDatabase.skills`).
- `reward_items: Array[Dictionary]`: List of item rewards with schema `{"item_id": int, "item_name": String, "count": int}`. Supports real-time addition and removal.

### 5. Built-in Authentic Presets
Pre-loaded authentic Wonderland Online quest storylines:
1. **Prologue Ship Quest (Quest ID 1001, Main):**
   - Step 1: Talk to Captain Robinson (`npc_id: 14003`, `talk_id: 14003`).
   - Step 2: Visit Passenger Cabin (`map_id: 10002`, `target_pos: Vector2(750, 480)`, `radius: 64.0`).
   - Step 3: Return to Ship Deck (`map_id: 10001`, `target_pos: Vector2(1720, 906)`, `radius: 64.0`).
   - Rewards: 100 EXP, 50 Gold, Small Knife (`item_id: 23001`, count: 1).
2. **Monkey Beach Awakening (Quest ID 1002, Main):**
   - Step 1: Talk to Kelang (`npc_id: 14062`, `talk_id: 14062`).
   - Step 2: Gather Coconuts (`item_id: 32001`, count: 3).
   - Rewards: 150 EXP, 100 Gold.
3. **Kelan Trail Navigation (Quest ID 1003, Branch):**
   - Step 1: Travel to Kelan Trail (`map_id: 11016`, `target_pos: Vector2(400, 600)`, `radius: 80.0`).
   - Step 2: Defeat Gel Monsters (`monster_id: 1001`, count: 3).
   - Step 3: Reach Kelan Village (`map_id: 12000`, `target_pos: Vector2(1200, 850)`, `radius: 64.0`).
   - Rewards: 300 EXP, 200 Gold.

### 6. Export & Import Engine
- **JSON Serialization:**
  - `save_quest(path: String = "") -> bool`: Exports clean JSON payload to `user://custom_quests/quest_<id>.json` or custom path. Creates target directories automatically.
  - `load_quest(path: String) -> Dictionary`: Reads and parses JSON payload, synchronizing internal state and UI controls.
  - `create_quest_data() -> Dictionary`: Returns pure Dictionary payload.
- **Standalone RefCounted GDScript Generator:**
  - `export_quest_script(path: String = "") -> String`: Generates production-grade, strictly typed GDScript class extending `RefCounted` (named `Quest_<id>`).
  - Contains constant tables for metadata, objectives, rewards, and methods:
    - `get_quest_id() -> int`
    - `get_title() -> String`
    - `get_objectives_count() -> int`
    - `get_current_objective() -> Dictionary`
    - `advance_step() -> bool`
    - `complete_quest() -> Dictionary`
    - `reset_quest() -> void`

---

## Technical API Specification

### Class: `QuestEditor` (extends `Control`)

#### Signals
- `quest_loaded(quest_id: int)`: Emitted when a quest payload is loaded from JSON.
- `quest_saved(file_path: String)`: Emitted after successfully exporting JSON.
- `quest_script_exported(file_path: String)`: Emitted after writing a `.gd` quest script.
- `objective_added(step_index: int, objective_type: String)`: Emitted when an objective is added.
- `objective_removed(step_index: int)`: Emitted when an objective is removed.
- `objective_updated(step_index: int)`: Emitted when an objective is updated in-place.
- `reward_item_added(item_id: int, count: int)`: Emitted when a reward item is added.
- `reward_item_removed(index: int)`: Emitted when a reward item is removed.
- `dialogue_previewed(talk_id: int, preview_text: String)`: Emitted after querying dialogue.
- `preset_loaded(preset_name: String)`: Emitted when a preset is activated.

#### Methods
- `add_objective(obj_type: String, data: Dictionary = {}) -> int`: Appends a new objective step; returns step index.
- `remove_objective(index: int) -> bool`: Removes step at index; returns success status.
- `update_objective(index: int, data: Dictionary) -> bool`: Updates step attributes; returns success status.
- `move_objective_up(index: int) -> bool`: Swaps step with predecessor; returns success status.
- `move_objective_down(index: int) -> bool`: Swaps step with successor; returns success status.
- `clear_objectives() -> void`: Empties objectives list.
- `get_objective(index: int) -> Dictionary`: Returns copy of step data at index.
- `get_objectives() -> Array[Dictionary]`: Returns all objective steps.
- `set_rewards(exp: int, gold: int, items: Array[Dictionary], skill_id: int) -> void`: Updates reward payload.
- `add_reward_item(item_id: int, item_name: String, count: int) -> void`: Adds item reward entry.
- `remove_reward_item(index: int) -> bool`: Removes item reward entry by index.
- `clear_reward_items() -> void`: Clears item rewards.
- `lookup_dialogue(talk_id: int) -> Dictionary`: Queries `GameDatabase.talks` or built-in fallback records.
- `preview_dialogue(talk_id: int) -> Dictionary`: Previews dialogue and updates right-hand panel widgets.
- `parse_tokens(text: String, player_name: String = "Adventurer") -> String`: Converts WLO tags to BBCode.
- `extract_tokens(text: String) -> Dictionary`: Returns extracted `{ "sound": String, "face_index": int }`.
- `load_preset(preset_name: String) -> bool`: Loads named preset into editor.
- `get_preset_names() -> Array[String]`: Returns all preset keys.
- `create_quest_data() -> Dictionary`: Serializes quest to Dictionary.
- `apply_quest_data(data: Dictionary) -> void`: Restores quest from Dictionary.
- `save_quest(path: String = "") -> bool`: Writes JSON file to disk.
- `load_quest(path: String) -> Dictionary`: Reads JSON file from disk.
- `export_quest_script(path: String = "") -> String`: Generates and saves standalone GDScript.

---

## Verification & Headless Testing

Run headlessly via Godot 4 console executable:
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_quest_editor.tscn
```

### Automated Verification Results
- **Test 1 (Scene & UI Instantiation):** Passed. 800x600 layout and 26 unique widget bindings verified.
- **Test 2 (Header Configuration):** Passed. ID, Title, Category, Min Level, Prereq, Repeatable, Description verified.
- **Test 3 (Objective Sequencer):** Passed. All 4 objective types (`TalkToNPC`, `CollectItem`, `DefeatMonster`, `ReachArea`) tested across add, update, reorder (up/down), and remove.
- **Test 4 (Dialogue & Token Parser):** Passed. Authentic `#n`, `#s`, `#f`, and color tags (`#R`, `#G`, `#B`, `#Y`) converted to valid BBCode.
- **Test 5 (Rewards Configuration):** Passed. EXP, Gold, Skills, and dynamic Item lists verified.
- **Test 6 (Built-in Presets):** Passed. 100% verification for Presets 1001, 1002, and 1003.
- **Test 7 (Export/Import & GDScript Generation):** Passed. JSON roundtrip and standalone `Quest_<id>` RefCounted class generation verified.
