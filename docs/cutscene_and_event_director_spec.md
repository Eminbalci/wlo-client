# Wonderland Online - Cutscene & In-Game Event Sequence Director Tool Specification

## 1. Overview
The **Cutscene & In-Game Event Sequence Director** (`CutsceneEditor`) is an interactive visual developer and authoring tool integrated into the Wonderland Online Godot 4 client. It enables rapid sequencing, keyframe authoring, live 2D viewport staging, audio/FX coordination, timeline scrubbing, JSON interchange, and standalone `.tscn` event scene export for cinematic in-game moments.

- **Script Path:** `res://scripts/tools/cutscene_editor.gd`
- **Scene Path:** `res://scenes/tools/cutscene_editor.tscn`
- **Playback Runner Script:** `res://scripts/events/cutscene_runner.gd`
- **Test Runner Scene:** `res://scenes/tests/test_cutscene_editor.tscn`
- **Test Suite Script:** `res://tests/test_cutscene_editor.gd`
- **Base Class:** `Control`
- **Minimum Resolution:** 800x600 (dark-themed slate/navy UI)

---

## 2. Architecture & Scene Hierarchy

```
CutsceneEditor (Control, min 800x600)
├── Background (Panel with Navy/Slate StyleBoxFlat)
└── MainVBox (VBoxContainer)
    ├── TopBar (PanelContainer)
    │   └── TopHBox: Title, CutsceneTitleEdit, DurationSpin, PresetOption, BtnLoadPreset, BtnNew, BtnLoadJSON, BtnSaveJSON, BtnExportScene
    ├── ContentHBox (HBoxContainer)
    │   ├── LeftArea (VBoxContainer, stretch_ratio=1.7)
    │   │   ├── CanvasPanel (PanelContainer, StyleBoxFlat_canvas)
    │   │   │   └── ViewportCanvas (Control, min 460x260, custom-drawn 2D staging preview)
    │   │   ├── ScrubberPanel (PanelContainer)
    │   │   │   └── ScrubberVBox:
    │   │   │       ├── PlaybackHBox: BtnPlay, BtnPause, BtnStop, TimeLabel, FrameLabel, TimeScaleOption (0.5x, 1x, 2x)
    │   │   │       └── SliderHBox: TimeSlider (0.0 .. total_duration)
    │   │   └── TimelineTracksPanel (PanelContainer, min_height 115)
    │   │       └── TracksVBox:
    │   │           ├── TracksHeader: "Timeline Multi-Track Lanes"
    │   │           ├── CameraTrackLane (Control, cyan markers, scrubber line)
    │   │           ├── ActorTrackLane (Control, green markers)
    │   │           ├── DialogueTrackLane (Control, gold markers)
    │   │           ├── AudioTrackLane (Control, purple markers)
    │   │           └── ScreenFXTrackLane (Control, red markers)
    │   └── RightPanel (VBoxContainer, min_width 280)
    │       └── InspectorTabs (TabContainer)
    │           ├── Tab 0: "Tracks & Keys" (Track selector, KeyframeItemList, + Add Key, - Remove Key, Clear Track)
    │           └── Tab 1: "Key Inspector" (Timestamp spinbox, dynamic property panels for active track type)
    └── StatusBar (PanelContainer)
        └── StatusHBox: StatusReadoutLabel ("Ready."), StateReadoutLabel (Cam pos, zoom, tilt, dialogue status)
```

---

## 3. Multi-Track Timeline System

The sequence director manages 5 dedicated timeline track types. Keyframes within each track are automatically ordered ascending by timestamp ($t \ge 0$).

### 3.1 Camera Track (`TRACK_CAMERA = "camera"`)
Controls the simulated 2D virtual camera:
- `time: float`: Timestamp in seconds ($0.0 \le t \le \text{total\_duration}$).
- `pan_target: Vector2`: Focus center coordinates in map/world space.
- `zoom: float`: Optical zoom multiplier ($0.1 \le z \le 10.0$, default `1.0`).
- `shake_intensity: float`: Normalized screen shake trauma ($0.0 \le s \le 1.0$).
- `shake_duration: float`: Trauma decay window in seconds.
- `interpolation: String`: Curve interpolation mode (`"Linear"`, `"EaseIn"`, `"EaseOut"`, `"EaseInOut"`, `"Step"`).

### 3.2 Actor Track (`TRACK_ACTOR = "actor"`)
Directs actor positioning, orientations, animations, and visibility:
- `time: float`: Timestamp in seconds.
- `actor_id: String`: Unique actor identifier (e.g., `"player"`, `"captain"`, `"kelang"`).
- `actor_name: String`: Display name tag.
- `position: Vector2`: Coordinate position in world space.
- `facing: int`: 8-directional orientation index (`0..7`: 0=S, 1=SW, 2=W, 3=NW, 4=N, 5=NE, 6=E, 7=SE).
- `action: String`: Character action animation (`"Idle"`, `"Walk"`, `"Pose"`, `"Prone"`, `"Attack"`).
- `visible: bool`: Actor render visibility flag.
- `interpolation: String`: Positional motion interpolation (`"Linear"`, `"Step"`).

### 3.3 Dialogue Track (`TRACK_DIALOGUE = "dialogue"`)
Synchronizes cinematic subtitles and dialogue boxes:
- `time: float`: Timestamp when the dialogue begins.
- `duration: float`: Display lifespan in seconds.
- `talk_id: int`: Optional Talk.dat database record ID.
- `speaker: String`: Speaker character display name.
- `text: String`: Full subtitle or dialogue string.
- `typewriter_delay: float`: Per-character delay in seconds ($0.0$ for instant reveal, $0.03$ for standard 30 CPS typing).

### 3.4 Audio Track (`TRACK_AUDIO = "audio"`)
Coordinates background score transitions and sound effect triggers:
- `time: float`: Audio cue timestamp.
- `audio_type: String`: Audio category (`"BGM"`, `"SFX"`, `"Ambient"`).
- `resource_id: String`: Audio file name (e.g., `"BGM0041.wav"`, `"SEB0279_alarm.wav"`).
- `volume_db: float`: Output gain modulation in decibels ($-80.0 \le v \le +6.0$).
- `pitch_scale: float`: Pitch frequency shift ($0.5 \le p \le 2.0$, default `1.0`).
- `fade_time: float`: Fade-in duration in seconds.

### 3.5 Screen FX Track (`TRACK_SCREEN_FX = "screen_fx"`)
Applies screen transitions, flashes, and physical camera roll:
- `time: float`: Effect activation timestamp.
- `duration: float`: Active lifespan in seconds.
- `fx_type: String`: Effect mode (`"FadeColor"`, `"Flash"`, `"CameraTilt"`, `"TintPulse"`, `"None"`).
- `color: Color`: Color payload for fade/flash (e.g., `Color(0,0,0,1)` for fade to black, `Color(1,0,0,0.45)` for red hazard).
- `intensity: float`: Effect opacity or strength ($0.0 \le i \le 1.0$).
- `tilt_angle: float`: Camera roll angle in degrees (e.g., $+8.0^\circ$ to $+14.5^\circ$ for listing ship hull).
- `pulse_frequency: float`: Strobe or pulse oscillation frequency in Hertz.

---

## 4. Mathematical State Evaluation Engine

At any arbitrary evaluation time $t \ge 0$, `evaluate_at_time(t: float) -> Dictionary` calculates the exact state:

```gdscript
{
    "time": float,
    "camera": {
        "position": Vector2,
        "zoom": float,
        "shake_intensity": float,
        "shake_offset": Vector2
    },
    "actors": {
        "<actor_id>": {
            "actor_id": String,
            "actor_name": String,
            "position": Vector2,
            "facing": int,
            "action": String,
            "visible": bool
        }
    },
    "dialogue": {
        "is_active": bool,
        "speaker": String,
        "text": String,
        "full_text": String,
        "talk_id": int
    },
    "audio": {
        "bgm": String,
        "volume_db": float,
        "pitch_scale": float,
        "sfx_triggers": Array[String]
    },
    "screen_fx": {
        "fade_color": Color,
        "flash_color": Color,
        "tilt_angle": float
    }
}
```

### 4.1 Positional Interpolation & Easing
Between keyframes $(k_1, k_2)$ where $t_1 \le t < t_2$:
$$\text{factor} = \frac{t - t_1}{t_2 - t_1}$$

Easing curves:
- **Linear:** $f = \text{factor}$
- **EaseIn:** $f = \text{factor}^2$
- **EaseOut:** $f = 1.0 - (1.0 - \text{factor})^2$
- **EaseInOut:** $f = \text{smoothstep}(0.0, 1.0, \text{factor})$
- **Step:** $f = 0.0$

$$\vec{P}(t) = \vec{P}_1 + (\vec{P}_2 - \vec{P}_1) \cdot f$$

### 4.2 Decaying Screen Shake Trauma
For any camera keyframe with intensity $I > 0$ and duration $D$:
$$r = 1.0 - \frac{t - t_k}{D}, \quad \text{trauma}(t) = I \cdot r$$
$$\vec{O}_{\text{shake}}(t) = \begin{pmatrix} \sin(t \cdot 43.7) \cdot \text{trauma}(t) \cdot 18.0 \\ \cos(t \cdot 37.3) \cdot \text{trauma}(t) \cdot 14.0 \end{pmatrix}$$

### 4.3 Typewriter Text Chunking
For an active dialogue keyframe starting at $t_k$ with typewriter delay $\delta_{\text{type}}$:
$$\text{chars}(t) = \min\left(\text{length}(\text{text}), \, \left\lfloor \frac{t - t_k}{\delta_{\text{type}}} \right\rfloor\right)$$
$$\text{visible\_text}(t) = \text{text}[0 \dots \text{chars}(t)]$$

---

## 5. Built-in Authentic Presets

| Preset Name | Duration | Map Theme | Key Highlights |
|---|---|---|---|
| **"Ship Sinking Climax"** | 15.0s | Ship Deck | Decaying tremor shake ($I=0.8..0.9$), listing ship tilt ($+8.0^\circ \to +14.5^\circ$), red emergency flash ($f=2.5\text{Hz}$), crew running across deck, Captain Robinson dialogue, fade to black. |
| **"Monkey Beach Awakening"** | 14.0s | Beach Shore | Fade in from black ($2.5\text{s}$), player prone standee waking up, ambient ocean wave audio, Kelang approach down shoreline, Talk 10011 dialogue tree. |
| **"Kelan Cave Ambush"** | 12.0s | Cavern | Deep cavern camera pan, monster ambush shockwave ($I=0.75$), Cave Bat swooping attack pose, Kelan Slime burst, battle transition. |

---

## 6. Standalone Scene Export Pipeline

### 6.1 `export_cutscene_scene(path: String) -> String`
Generates a complete, standalone Godot 4 scene (`.tscn`) bound to `CutsceneRunner` (`res://scripts/events/cutscene_runner.gd`):
- Root node: `CutsceneSequence` (`Node2D` extending `CutsceneRunner`).
- Child nodes:
  - `Camera2D`: Positioned and zoom-smoothed.
  - `Actors`: Sub-hierarchy of `Node2D` nodes with labels for each registered actor.
  - `ScreenFX`: `CanvasLayer` containing `FadeRect` and `FlashRect`.
  - `Dialogue`: `CanvasLayer` containing `DialogueBox`, `SpeakerLabel`, and `TextLabel`.
  - `Audio`: `AudioBGM` and `AudioSFX` audio stream players.
- Embedded metadata: `metadata/cutscene_data` serialized dictionary containing all tracks, keyframes, and timing.

### 6.2 Public API Reference

| Method Signature | Return Type | Description |
|---|---|---|
| `play()` | `void` | Begins playback at active time scale. |
| `pause()` | `void` | Pauses timeline playback. |
| `stop()` | `void` | Halts playback and resets playhead to $0.0\text{s}$. |
| `seek(time: float)` | `void` | Scrubs timeline to target time with bounds clamping. |
| `seek_frame(frame: int, fps: int = 30)` | `void` | Scrubs timeline to precise integer frame index. |
| `set_time_scale(scale: float)` | `void` | Adjusts playback speed ($0.1\text{x} \le s \le 10.0\text{x}$). |
| `set_total_duration(duration: float)` | `void` | Configures sequence duration in seconds. |
| `add_keyframe(track_type: String, data: Dictionary)` | `int` | Inserts keyframe into track with auto-sort; returns index. |
| `remove_keyframe(track_type: String, index: int)` | `bool` | Deletes keyframe at index. |
| `get_keyframes(track_type: String)` | `Array[Dictionary]` | Returns all keyframes in specified track. |
| `set_keyframe(track_type: String, index: int, data: Dictionary)` | `bool` | Modifies keyframe properties and re-sorts. |
| `clear_track(track_type: String)` | `void` | Clears all keyframes in specified track. |
| `clear_all_tracks()` | `void` | Empties all 5 timeline tracks. |
| `evaluate_at_time(time: float)` | `Dictionary` | Evaluates composite interpolated cutscene state at $t$. |
| `load_preset(preset_name: String)` | `bool` | Loads one of the 3 built-in story presets. |
| `get_preset_names()` | `Array[String]` | Returns list of available preset identifiers. |
| `save_cutscene_json(path: String = "")` | `bool` | Serializes cutscene tracks to JSON file on disk. |
| `load_cutscene_json(path: String)` | `Dictionary` | Parses cutscene tracks from JSON file on disk. |
| `export_cutscene_scene(path: String)` | `String` | Generates standalone Godot 4 `.tscn` playable scene. |
| `add_actor(id: String, name: String, pos: Vector2, facing: int, action: String)` | `bool` | Registers new actor in cutscene roster. |
| `remove_actor(id: String)` | `bool` | Removes actor from roster and deletes associated keyframes. |

---

## 7. Verification & Automated Test Results

The test suite at `tests/test_cutscene_editor.gd` executed headlessly under Godot Engine v4.6.2.stable:

```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_cutscene_editor.tscn
```

### Execution Log Output
```
=================================================================
--- Running WLO Cutscene & Event Sequence Director Test Suite ---
=================================================================

>>> [TEST 1] Verifying CutsceneEditor Instantiation & Layout (cutscene_editor.tscn)...
  PASS: CutsceneEditor instantiated with 800x600 size and all 32 required methods.
>>> [TEST 2] Verifying Multi-Track Management & Keyframe Sorting...
  PASS: Multi-track insertion, ascending sort order, modification & deletion verified across all 5 tracks.
>>> [TEST 3] Verifying Timeline Playback, Scrubber & Time Scaling...
  PASS: Playback, pause, stop, frame seek, time scaling & bounds clamping verified.
>>> [TEST 4] Verifying State Evaluation Engine (Interpolation, Shake & Typewriter)...
  PASS: Mathematical state evaluation (linear pan/zoom lerp, typewriter chunking, decaying shake & tilt) verified.
>>> [TEST 5] Verifying 3 Built-in Authentic Presets...
  PASS: All 3 authentic presets loaded and verified at critical story timestamps.
>>> [TEST 6] Verifying Actor Roster Registration & Staging...
  PASS: Actor roster add, lookup, info retrieval and removal verified.
>>> [TEST 7] Verifying JSON Serialization & Bidirectional File Roundtrip...
  PASS: JSON serialization, disk file write, parsing & state restoration verified.
>>> [TEST 8] Verifying Standalone Godot 4 .tscn Scene Export & Execution...
  PASS: Standalone .tscn exported, loaded, instantiated and runtime execution verified.

=================================================================
--- ALL CUTSCENE & EVENT DIRECTOR TESTS PASSED (100%) ---
=================================================================
```
