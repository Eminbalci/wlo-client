# Captain Robinson Dialogue Sinking Cutscene and Deserted Island Warp Specification

## 1. Overview
This specification details the end-to-end integration between Captain Robinson (NPC 14003) on the Cruise Ship Deck (Map 10001), the authentic Ship Sinking Event Sequence (`SinkingCutsceneController`), and the automated warp to Deserted Island (Map 10003: Monkey Beach, coordinate `Vector2(1342, 2495)`).

## 2. Architecture & Trigger Flow
```
[Player interacts with Captain Robinson (NPC 14003)]
                      │
                      ▼
[HUD displays Dialogue Sequence (Talk ID 30124 -> 30125)]
                      │
                      ▼
[Player concludes dialogue (Choice Selected / Window Closed / Sequence End)]
                      │
                      ▼
[MapView triggers trigger_ship_sinking_cutscene()]
                      │
                      ▼
[SinkingCutsceneController executes 4 stages: WARNING -> SINKING -> FADED -> AWAKENED]
  • 0.0s - 2.0s: WARNING Stage (Alarm sirens, red hazard pulse, trauma camera shake)
  • 2.0s - 4.5s: SINKING Stage (Hull breach SFX, climax trauma 1.0, starboard ship tilt)
  • 4.5s - 6.0s: FADED Stage (Fade overlay smoothly tweens to solid black)
  • >= 6.0s: AWAKENED Stage (Emits cutscene_finished & transition_to_beach)
                      │
                      ▼
[MapView._on_sinking_cutscene_finished()]
  • Unloads all ship entities (_deck_entities, _cabin_entities, _kitchen_entities)
  • Warps player via _on_portal_triggered(null, 10003, Vector2(1342, 2495))
  • Resets camera offset and rotation tilt to Vector2.ZERO
  • Plays player prone get-up animation (play_wakeup_animation)
  • Starts authentic awakening music (BGM0012.wav / BGM0003.wav)
  • Dynamically spawns Deserted Island beach entities (Kelang NPC 14062)
```

## 3. Class & Method Specifications

### 3.1 `SinkingCutsceneController` (`scripts/events/sinking_cutscene.gd`)
- **Signals**:
  - `signal cutscene_started(trigger_source: String)`
  - `signal stage_changed(stage_name: String)`
  - `signal cutscene_finished`
  - `signal transition_to_beach(beach_scene_path: String)`
- **Configuration Properties**:
  - `@export var warning_duration: float = 2.0`
  - `@export var sinking_duration: float = 2.5`
  - `@export var fade_duration: float = 1.5`
  - `@export var time_scale: float = 1.0`
- **Public Methods**:
  - `trigger_after_captain_dialogue() -> void`: Triggers the cutscene with reason `"captain_dialogue"`.
  - `trigger_cutscene(p_trigger_source: String = "manual") -> void`: Master trigger initializing UI overlays, audio players, camera shake, and stage timing.
  - `fast_forward() -> void`: Instantly advances elapsed time to cutscene conclusion for fast headless testing.
  - `accelerate(multiplier: float = 10.0) -> void`: Adjusts `time_scale`.
  - `reset_visuals() -> void`: Restores camera offset, rotation tilt, and red overlay alpha.
  - `stop_all_audio() -> void`: Stops alarm sirens and sinking sound effects.

### 3.2 `MapView` (`scripts/map/map_view.gd`)
- **Variables**:
  - `_interacting_npc_id: int`: Tracks currently active NPC dialog.
  - `_is_captain_dialogue_active: bool`: Set when Captain Robinson (14003) is interacted with.
  - `_sinking_triggered: bool`: Reentrancy guard preventing duplicate cutscene invocations.
  - `_island_warped: bool`: Reentrancy guard preventing multiple warp dispatches.
- **Methods**:
  - `_ensure_sinking_cutscene() -> SinkingCutsceneController`: Dynamically ensures an instance of `SinkingCutsceneController` exists, attaches camera, and connects completion signals.
  - `trigger_ship_sinking_cutscene() -> SinkingCutsceneController`: Initiates cutscene and triggers Captain sequence.
  - `_on_dialogue_closed() -> void`: Captures HUD dialogue close signal and activates cutscene if Captain dialogue was active.
  - `_on_sinking_cutscene_finished() -> void`: Unloads ship entities, warps to Map 10003 at `(1342, 2495)`, resets camera, triggers wakeup animation, and starts awakening BGM.
  - `unload_ship_entities() -> void`: Hides all entities from ship deck, cabin, and kitchen.
  - `play_awakening_music() -> void`: Loads and plays `BGM0012.wav` (fallback `BGM0003.wav`).
  - `_ensure_beach_entities() -> void`: Dynamically instantiates Kelang NPC (14062) at `Vector2(1390, 2460)`.

## 4. Edge Cases & Resilience
1. **Headless / Missing HUD**: If `hud` is null or missing signals, `_on_npc_interacted` triggers `trigger_ship_sinking_cutscene` directly.
2. **Missing UI Overlays**: If `CanvasLayer`, `RedOverlay`, or `FadeOverlay` are not preset in the scene, `SinkingCutsceneController._ensure_ui_overlays()` instantiates them dynamically at CanvasLayer 55 with `mouse_filter = MOUSE_FILTER_IGNORE`.
3. **Missing Audio Streams**: Uses multi-fallback candidate audio paths (`BGM0012.wav`, `BGM0003.wav`, `wav9911.wav`, `SEB0011.WAV`).
4. **Circular Scene Preloading Prevention**: `SinkingCutsceneController` is instantiated dynamically via GDScript to prevent Godot 4.6 circular dependency between `MapView` and `BeachAwakeningController`.

## 5. Verification
- Test script: `scripts/tests/test_captain_dialogue_sinking_cutscene.gd`
- Total tests: 13 automated checks
- Status: All 13 tests passed cleanly.
