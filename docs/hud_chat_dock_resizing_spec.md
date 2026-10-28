# HUD Chat Dock Resizing and Channel Tabs Specification

## Overview
The HUD Chat Dock provides real-time chat logging, channel filtering, whisper routing, emote picking, compact/framed mode toggling, and smooth vertical resizing matching Wonderland Online client behavior (cross-referenced with video seconds 321 to 360 and skin assets).

## Resizing & Drag Mechanics
- **Handle:** Top resizer handle / bar on the chat history panel.
- **Drag Clamp:** Height offset clamped between minimum height (~90px / -90.0) and maximum height (~350px / -350.0).
- **Cursor:** Vertical resize cursor (CURSOR_VSIZE) active during hover and drag.
- **Real-Time Update:** Smooth adjustment of ChatHistoryPanel vertical offset and container sizing.

## Channel Tabs & Filtering
- **Channels Supported:** All, Current (Local), Team, Guild, Whisper, System.
- **Filtering:** Tab selection filters incoming and historical chat messages by channel type.
- **Visuals:** Selected vs unselected tab graphics, precise font color styling (#38c850 for Local, #55aaff for Team, #ff77bb for Whisper, #ffaa33 for System).

## Background Panel Opacity & Dimming
- Background panel supports opacity toggling and transparency dimming in both compact and framed modes (Form_Talk_1.bmp / Form_Talk_2.bmp).
