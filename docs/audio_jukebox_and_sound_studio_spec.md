# Wonderland Online - Audio Jukebox & Sound Design Studio Specification

## 1. Overview
The **Audio Jukebox & Sound Design Studio** (`AudioEditor`) is a production-grade visual developer tool integrated into the Wonderland Online Godot 4 client. It centralizes inspection, playback, loop point configuration, live spectrum/waveform visualization, game map BGM bindings, combat/skill SFX associations, atmospheric ambience layering, and manifest generation for over 1,300 audio assets across Wonderland Online.

- **Editor Script Path:** `res://scripts/tools/audio_editor.gd`
- **Editor Scene Path:** `res://scenes/tools/audio_editor.tscn`
- **Test Suite Script:** `res://tests/test_audio_editor.gd`
- **Test Runner Scene:** `res://scenes/tests/test_audio_editor.tscn`
- **SceneTree Runner:** `res://scripts/tests/test_audio_editor.gd`
- **Base Class:** `Control`
- **Minimum Resolution:** 800x600 (Dark navy/slate theme, responsive split layout)

---

## 2. Architecture & Scene Hierarchy

```text
AudioEditor (Control, min 800x600)
├── Background (Panel with Navy/Charcoal StyleBoxFlat)
└── MainVBox (VBoxContainer)
    ├── TopToolbar (PanelContainer)
    │   └── HBoxToolbar: Title, OptPreset, BtnApplyPreset, BtnSaveConfig, BtnLoadConfig, BtnExportManifest
    └── BodySplit (HSplitContainer, split_offset=260)
        ├── LeftPane (PanelContainer - Sound Asset Browser)
        │   └── VBoxLeft:
        │       ├── LblBrowser ("SOUND ASSET BROWSER")
        │       ├── EditSearch (LineEdit)
        │       ├── HBoxFilters: OptCategory (OptionButton), EditTagFilter (LineEdit)
        │       ├── ListSounds (ItemList)
        │       └── FooterLeft: LblAssetCount (Label), BtnRescan (Button)
        └── RightPane (VBoxContainer - Player, Visualizer & Studio Tabs)
            ├── PlayerSection (PanelContainer)
            │   └── VBoxPlayer:
            │       ├── VisualizerCanvas (Control, min height 110px)
            │       ├── NowPlayingBox: LblNowPlaying (Label), LblTime (Label)
            │       ├── SliderScrubber (HSlider, step 0.05s)
            │       ├── TransportControls: BtnPlay, BtnPause, BtnStop, ChkLoop, SliderVolume, SliderPitch
            │       └── LoopControls: SpinLoopStart, SpinLoopEnd, SpinFadeIn, SpinFadeOut
            └── TabContainer (TabContainer)
                ├── TabMapBgm ("Map BGM Binding")
                │   └── VBoxMap: MapInputBar (SpinMapId, EditMapName, BtnAssignMapBgm, BtnRemoveMapBgm), TreeMapBindings
                ├── TabCombatSkill ("Combat / Skill SFX")
                │   └── VBoxSkill: SkillInputBar (SpinSkillId, OptSfxType, BtnAssignSkillSfx), EventInputBar (OptBattleEvent, BtnAssignEventSfx), TreeSkillBindings
                ├── TabAmbience ("Ambience Layering")
                │   └── VBoxAmb: AmbienceConfigBar (ChkAmbience, OptAmbienceTrack, SliderAmbienceVol), AmbiencePresetsBar (BtnAmbOcean, BtnAmbCave, BtnAmbWind), LblAmbienceDesc
                └── TabLogSummary ("Log & Summary")
                    └── VBoxLog: LblSummary (Label), TextLog (TextEdit)
```

---

## 3. Sound Asset Browser & Scanning Engine

### 3.1 Scanning Scope
`AudioEditor.scan_sound_assets(custom_paths: Array[String] = []) -> int` recursively scans:
- `res://assets/sound` (273 core WAV/OGG files)
- `res://assets/voice` (1,037 vocal dialogue tracks)
- `D:/GitHub/WLRI/sound` (External fallback)
- `D:/GitHub/WLRI/voice` (External fallback)
- Total scanned assets: **1,310 assets**.

### 3.2 Automated Classification Matrix
Sound files are categorized into 5 functional categories:

| Category Enum | Category Name | Classification Rule | Example Assets |
|---|---|---|---|
| `SoundCategory.BGM` | BGM | File name begins with `BGM` or `bgm` | `BGM0001.wav`, `BGM0011.wav`, `BGM0041.wav` |
| `SoundCategory.SEB` | SEB | File name begins with `SEB` or generic buffer | `SEB0018.wav`, `SEB0050.wav` |
| `SoundCategory.COMBAT` | Combat | Combat hits, misses, casts, skill numbers | `wav0010.wav` (hit), `wav0020.wav` (miss), `wav0030.wav` (cast), `SEB0017.wav` (crit) |
| `SoundCategory.VOICE` | Voice | Stored in `/voice/` directory, dialogue clips | `act_001.wav`, `talk_002.wav` |
| `SoundCategory.AMBIENCE` | Ambience | Coastal surf, cavern drips, squalls | `SEB0037.wav` (waves), `SEB0042.wav` (cave drip), `SEB0049.wav` (wind) |

### 3.3 Search and Filter Methods
- `filter_assets(query: String = "", category: SoundCategory = SoundCategory.ALL, tag_filter: String = "") -> Array[Dictionary]`
- Supports multi-criteria filtering:
  - Substring search against file names, display names, and assigned metadata tags.
  - Category selector filter.
  - Tag filter (e.g., `beach`, `ship_deck`, `ocean_waves`, `hit`, `cast`, `map_10001`).

---

## 4. Interactive Audio Player & Scrubber Controls

### 4.1 Playback State Machine
- `PlaybackState.STOPPED`: Player idle, position set to `0.0s`.
- `PlaybackState.PLAYING`: Primary stream active on `Master` bus, time ticking, visualizer animated.
- `PlaybackState.PAUSED`: Stream stopped, current position retained.

### 4.2 Transport Controls & Ranges
- **Play:** `play_sound(file_name: String = "", from_sec: float = 0.0) -> bool`
- **Pause:** `pause_sound() -> void`
- **Resume:** `resume_sound() -> void`
- **Stop:** `stop_sound() -> void`
- **Seek:** `seek_sound(to_sec: float) -> void`
- **Master Volume:** `set_volume_db(vol_db: float) -> void` (Clamped between `-40.0 dB` and `+6.0 dB`, linear conversion via `db_to_linear`)
- **Pitch Scale:** `set_pitch_scale(pitch: float) -> void` (Clamped between `0.5x` and `2.0x`)
- **Loop Toggle:** `set_looping(enabled: bool) -> void`

### 4.3 Custom Loop Points & Fade Interpolation
- `set_loop_points(start_sec: float, end_sec: float) -> void`
- `set_fade_durations(fade_in: float, fade_out: float) -> void`
- **Loop Wraparound Logic:** In `_update_playback_tick(delta)`:
  - When `current_position_sec >= loop_end_sec`, automatic seek occurs back to `loop_start_sec`.
  - If `fade_in_duration > 0.0` and `current_position_sec < fade_in_duration`, volume smoothly lerps from `(master_volume_db - 36.0)` to `master_volume_db`.
  - If `fade_out_duration > 0.0` near `loop_end_sec`, volume smoothly decreases toward `(master_volume_db - 36.0)`.

---

## 5. Real-Time Spectrum & Waveform Visualizer

### 5.1 Frequency Band Simulation & Analysis
- Visualizer resolution: **32 spectrum bands**.
- Fallback procedural harmonic generation:
  - Computes sinusoidal frequency band amplitudes from `current_position_sec`, volume linear factor, pitch scale, and band indices.
  - Ensures 100% deterministic, artifact-free visualizer performance in headless CI and test environments without an active hardware audio output.

### 5.2 Peak Hold & Decay Dynamics
- Peak hold indicators track the maximum band amplitude.
- Decay velocity: `PEAK_DECAY_RATE = 0.95`.
- Canvas rendering:
  - Gradient columns: Neon cyan `Color(0.15, 0.85, 1.0)` at bottom to neon magenta `Color(0.95, 0.3, 0.75)` at top.
  - Floating peak caps: White horizontal line `Color(1.0, 1.0, 1.0, 0.95)`.
  - Oscilloscope curve: 40-point polyline in emerald green `Color(0.3, 0.9, 0.6, 0.5)` centered vertically.

---

## 6. Game Tagging & Association System

### 6.1 Map BGM Binding
Assigns background music tracks to specific Scene Map IDs:
- `bind_map_bgm(map_id: int, bgm_file: String) -> void`
- `unbind_map_bgm(map_id: int) -> void`
- `get_map_bgm(map_id: int) -> String`
- `get_all_map_bgm_bindings() -> Dictionary`
- Built-in map associations:
  - `Map 10001` -> `BGM0011.wav` (Ship Deck)
  - `Map 10002` -> `BGM0012.wav` (Ship Cabins)
  - `Map 10003` -> `BGM0012.wav` (Ship Lower Deck)
  - `Map 10011` -> `BGM0041.wav` (Beach Awakening)
  - `Map 10012` -> `BGM0013.wav` (Kelan Village)

### 6.2 Combat / Skill SFX Binding
Associates specific sound effects with Skill IDs and general battle events:
- `bind_skill_sfx(skill_id: int, sfx_type: String, sfx_file: String) -> void`
- `get_skill_sfx(skill_id: int, sfx_type: String) -> String`
- `bind_battle_event_sfx(event_name: String, sfx_file: String) -> void`
- `get_battle_event_sfx(event_name: String) -> String`
- Supported Battle Events: `battle_start`, `cast`, `hit`, `miss`, `critical`, `victory`, `defeat`, `escape`.

### 6.3 Ambience Layering Engine
Secondary audio stream player (`_ambience_player`) operating concurrently with BGM:
- `play_ambience(file_name: String) -> bool`
- `stop_ambience() -> void`
- `set_ambience_volume_db(vol_db: float) -> void`
- `set_ambience_enabled(enabled: bool) -> void`
- Built-in atmospheric ambience presets:
  - **Ocean Waves:** `SEB0037.wav` at `-6.0 dB`, coastal tides.
  - **Cave Dripping:** `SEB0042.wav` at `-8.0 dB`, limestone cavern droplets.
  - **Wind Howling:** `SEB0049.wav` at `-10.0 dB`, oceanic squall.

---

## 7. Presets System

The studio provides 3 authentic Wonderland Online audio presets:

### 7.1 "Ship Deck Theme"
- **Primary Sound:** `BGM0011.wav`
- **Volume:** `0.0 dB`
- **Pitch Scale:** `1.0x`
- **Looping:** `true`
- **Loop Points:** In `0.0s`, Out `45.2s`, Fade-in `0.5s`, Fade-out `1.0s`
- **Map Binding:** `Map 10001` ("Ship Deck")
- **Ambience:** Disabled

### 7.2 "Monkey Beach Ambience"
- **Primary Sound:** `BGM0041.wav`
- **Volume:** `-2.0 dB`
- **Pitch Scale:** `1.0x`
- **Looping:** `true`
- **Loop Points:** In `0.0s`, Out `60.0s`, Fade-in `1.0s`, Fade-out `2.0s`
- **Map Binding:** `Map 10011` ("Beach Awakening")
- **Ambience:** Enabled, track `SEB0037.wav` (Ocean Waves), volume `-6.0 dB`

### 7.3 "Standard Battle Theme"
- **Primary Sound:** `BGM0001.wav`
- **Volume:** `0.0 dB`
- **Pitch Scale:** `1.05x` (Fast tempo battle intro)
- **Looping:** `true`
- **Loop Points:** In `2.5s`, Out `48.0s`, Fade-in `0.2s`, Fade-out `0.8s`
- **Event Binding:** Battle event `battle_start`
- **Ambience:** Disabled

---

## 8. Export & Persistence Methods

### 8.1 Configuration JSON (`save_audio_config` / `load_audio_config`)
- `save_audio_config(path: String) -> bool`
- `load_audio_config(path: String) -> Dictionary`
- **JSON Schema:**
```json
{
	"version": "1.0.0",
	"engine": "Godot 4.6.2",
	"saved_at": "2026-10-25T17:24:19",
	"master_volume_db": 0.0,
	"pitch_scale": 1.0,
	"is_looping": true,
	"current_sound": "BGM0011.wav",
	"map_bgm_bindings": {
		"10001": "BGM0011.wav",
		"10002": "BGM0012.wav"
	},
	"skill_sfx_bindings": {
		"10001": {
			"cast": "wav0030.wav",
			"hit": "wav0010.wav"
		}
	},
	"battle_event_sfx_bindings": {
		"battle_start": "BGM0001.wav",
		"victory": "BGM0002.wav"
	},
	"ambience_layers": {
		"Ocean Waves": {
			"sound_file": "SEB0037.wav",
			"volume_db": -6.0,
			"loop": true,
			"enabled": true
		}
	},
	"custom_loop_points": {
		"BGM0011.wav": {
			"loop_start": 0.0,
			"loop_end": 45.2,
			"fade_in": 0.5,
			"fade_out": 1.0
		}
	}
}
```

### 8.2 Audio Manifest Export (`export_audio_manifest`)
- `export_audio_manifest(path: String) -> bool`
- Generates a full audio inventory manifest with file counts, categories breakdown, durations, loop points, and active game bindings.

---

## 9. Verification & Headless Test Suite

### 9.1 Test Execution
The test suite is verified via Godot 4 headless console:
```powershell
godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client scenes/tests/test_audio_editor.tscn
```

### 9.2 Verification Summary
- **[TEST 1] Instantiation & Layout:** Confirmed 800x600 size, dark theme panels, and 25+ `@onready` node bindings.
- **[TEST 2] Sound Asset Scanning:** Successfully scanned 1,310 audio assets across 4 directories (36 BGMs, 220 SEBs, 14 Combat, 3 Ambience, 1037 Voice).
- **[TEST 3] Search & Filtering:** Verified name searches, category filtering, and tag filtering.
- **[TEST 4] Audio Player & Controls:** Verified STOPPED -> PLAYING -> PAUSED -> PLAYING -> STOPPED transitions, seek position, volume clamping (-40 to +6 dB), and pitch scaling (0.5x to 2.0x).
- **[TEST 5] Loop Points & Fade Logic:** Verified custom loop bounds and loop wraparound at `loop_end_sec`.
- **[TEST 6] Spectrum Visualizer:** Verified 32 frequency bands, peak hold calculations, and decay dynamics.
- **[TEST 7] Game Tagging & Associations:** Confirmed Map BGM bindings, Skill SFX bindings, Battle events, and Ambience layering.
- **[TEST 8] Presets:** Verified Ship Deck Theme, Monkey Beach Ambience, and Standard Battle Theme.
- **[TEST 9] Serialization & Manifest Export:** Verified complete roundtrip persistence and valid manifest JSON generation.
- **Result:** **100% Pass (All 9 tests passed, zero errors, zero warnings).**
