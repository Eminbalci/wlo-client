# Sinking Event Cutscene Technical Documentation

## Overview
The Sinking Event Cutscene (`sec_176.png` to `sec_240.png`) marks the dramatic climax of the cruise ship prologue in Wonderland Online. During this sequence, the ship encounters an unforeseen hazard, leading to emergency alarms, severe structural distress, passenger panic, and ultimate evacuation to a deserted island beach.

## Implementation Architecture
The cutscene is driven by `scripts/events/sinking_cutscene.gd`, which coordinates camera shake, red emergency lighting overlays, audio triggers, NPC state transitions, and fade transitions.

### 1. Screen Shake (Camera2D & FastNoiseLite)
- Uses `FastNoiseLite` to generate smooth, organic 2D pseudo-random offsets.
- Trauma-based decay system (`trauma` variable starting at `1.0` during active sinking and decaying at `0.5` per second).
- Offset calculation: `shake = trauma * trauma`, multiplied by noise samples for X and Y axes.

### 2. Red Emergency Lighting Overlay
- Implemented via a fullscreen `ColorRect` (`red_overlay_path`) covering the viewport.
- Pulses dynamically using a sine wave function linked to elapsed time: `alpha = (sin(elapsed_time * 6.0) + 1.0) * 0.25`.
- Provides an atmospheric red hazard glow matching authentic visual cues from frames `sec_176` through `sec_240`.

### 3. Emergency Siren & Audio Triggers
- Integrated with `AudioStreamPlayer` to trigger siren sound effects (`sound/alarm.wav` or `Mp3s/siren.mp3`) at the onset of the WARNING stage (`t = 0.0`).

### 4. NPC Panic & Dialogue Cues
- NPCs on the main deck switch from idle waypoint navigation to fleeing panic state (increased movement speed, panic emote bubbles).
- Dialog prompts display urgent captain announcements ("Abandon ship!").

### 5. Transition to Beach Awakening
- At `t = 35.0s`, a smooth screen fade-to-black tween executes (`fade_overlay`).
- At `t = 64.0s`, the scene transitions to Map 10011 (Deserted Island Beach) with a fade-in sequence.
