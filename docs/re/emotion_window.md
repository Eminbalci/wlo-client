# Emote picker (chat emote panel) and Form_Emotion

Godot: `scripts/ui/hud/emotion_window.gd`, `scenes/ui/hud/emotion_window.tscn`, test `tests/test_emotion_window.gd`.

## Two different things in the binary
1. **Chat emote panel** - built by the chat bar constructor **0x27d58c** (strings `main_input_1`, `Btn_expression_1`,
   `Chat Emotes`, `panel_expression_1`, `icon_expre_`). This is the emote picker; `EmotionWindow` reproduces it.
2. **Form_Emotion_1** (356x493, title "social") - the Emote tab of the social window, built by **0x2967a4**
   (same constructor creates Form_Friend_2 and Form_setup_1 tabs). Not rebuilt; partial findings below.

## Chat emote panel (verified, 0x27d58c)
Coordinates are relative to the chat bar; Godot uses panel-relative = minus (492, -69).

| control | chat-bar coords | panel coords | size |
|---|---|---|---|
| `Btn_expression_1` (hint "Chat Emotes", OnClick 0x2837a0 toggles panel+icons+close) | (492, 0) | - | 25 x 26 |
| `panel_expression_1` (class 0x47f408 image) | (492, -69) | (0, 0) | 263 x 69 |
| `icon_expre_i`, i=1..30 | (500 + 23*((i-1) mod 10), -62 + 20*((i-1) div 10)) | (8+23c, 7+20r) | 16 x 16 |
| `icon_expre_31` | (730, -22) | (238, 47) | 16 x 16 |
| `Btn_Close_s_1` (OnClick 0x2837ec hides) | (733, -66) | (241, 3) | 18 x 18 |

- Icons are 2-frame sheets (set-frames call 0x485960 with count 2): normal, hover.
- Hint per icon = shortcut table **0x4bcb24** + name table **0x4bcba4**, e.g. `@|Arrogant`, `:$Blush`, ... `-PNod`.
- 0x283834 scans chat text for emote codes (table at 0x4c8cf0) to render inline faces - not reconstructed. The Godot
  window emits `#NN` (the convention already used by chat_dock.gd and player.gd), which is a project convention, not
  the client's wire text.

## Form_Emotion_1 (social Emote tab, 0x2967a4) - partial, not rebuilt
- 5 `Btn_ctrl{1..5}_1` at left 34, 42x16 (tops from runtime table 0x4bc754 - zero in the file), 5 edits 239x17 at left 77
  (Ctrl+1..5 chat macros), 4 `Btn_onstate{1..4}_1` at (140 + 45*(i-1), 400) 43x20.
- `btn_Action_1..24` (class 0x278dec): left 180 + 34*((i-1) mod 4), top 180 + 34*((i-1) div 4), 32x32 -> right grid of
  the skin = action icons, not expressions.
- 8 `btn_blank4` slots (Alt+1..8): top 404, 32x32, lefts from runtime table 0x4bc730.
- The left 4x6 grid's contents were not identified.

## Assets
`emotion_panel.png` (panel_expression_1), `emotion_btn_expression_{normal,hover,pressed}.png`, existing
`icon_expre_N.png`, `skin_btn_close_s_1_*`.
