# Chat Dock Buttons & Input Verification Specification

## Overview
This specification documents the complete verification and implementation details for the HUD Chat Dock in Wonderland Online Client (`scenes/ui/hud.tscn` and `scripts/ui/hud.gd`), matching authentic video analysis seconds 321-424.

---

## 1. Verified Channels & Tabs System
The chat dock features a dedicated channel tab bar (`ChannelTabs`) positioned dynamically above the chat history viewport:
1. **All Tab (`BtnTabAll`)**: Displays all incoming and outgoing messages across channels.
2. **Current (Local) Tab (`BtnTabCurrent`)**: Filters messages tagged as local map chatter (`[Current]`).
3. **Team Tab (`BtnTabTeam`)**: Filters messages tagged as party/team communication (`[Team]`).
4. **Guild Tab (`BtnTabGuild`)**: Filters messages tagged as guild communication (`[Guild]`).
5. **Whisper Tab (`BtnTabWhisper`)**: Filters private direct messages (`[Whisper]`).
6. **System Tab (`BtnTabSystem`)**: Filters server announcements and alerts (`[System]`).

### Dynamic Message Buffering & Filter Architecture
- All dispatched and incoming messages are persisted in memory in `_chat_messages: Array[Dictionary]`.
- Each record stores `sender`, `message`, `channel`, and `line` (the rich BBCode-formatted output).
- Calling `select_chat_tab(tab_name: String)` clears the visible `RichTextLabel` and re-populates only the messages matching the selected tab criteria via `_message_matches_tab()`.
- Active tab styling highlights the active tab with gold font color (`Color(1.0, 0.9, 0.3, 1.0)`) and outline, while inactive tabs remain subdued.

---

## 2. Authentic Message Formatting & Channel Color Tags
Chat messages are formatted using authentic BBCode color palettes and clickable metadata:
- **System**: Amber tag `[color=#ffaa33][System][/color] [color=#ffffbb]%s[/color]`
- **Current / Local**: Emerald green tag `[color=#38c850][Current][/color] [url=whisper:%s][color=#e8e8b0]%s:[/color][/url] %s`
- **Team**: Cyan tag `[color=#55aaff][Team][/color] [url=whisper:%s][color=#e8e8b0]%s:[/color][/url] %s`
- **Guild**: Orange tag `[color=#ff8833][Guild][/color] [url=whisper:%s][color=#e8e8b0]%s:[/color][/url] %s`
- **Whisper**: Magenta tag `[color=#ff77bb][Whisper][/color] [url=whisper:%s][color=#e8e8b0]%s:[/color][/url] %s`
- **World**: Yellow tag `[color=#ffff55][World][/color] [url=whisper:%s][color=#e8e8b0]%s:[/color][/url] %s`
- **Spam Suppression**: Duplicate identical messages within $1.5$ seconds are suppressed by rate limiter.

---

## 3. Vertical Draggable Resizer & Sizing Controls
- **Top Resize Handle (`ChatResizeHandle`)**: 8px tall top drag margin with vertical sizing cursor (`CURSOR_VSIZE`).
- **Triangular Size Cycle Button (`BtnChatSize`)**: Sliced from `assets/hud/btn_chat_size.png`.
- **Height Cycling**: Clicking `BtnChatSize` steps through standard offsets:
  - Default: `-86.0px`
  - Medium: `-140.0px`
  - Expanded: `-200.0px`
- **Continuous Dragging**: Mouse drag events on `ChatResizeHandle` or `BtnChatSize` smoothly interpolate `offset_top` between `-250.0px` and `-60.0px`.
- **Global Mouse Tracking**: `_input(event)` captures `InputEventMouseMotion` and release globally while `_chat_is_resizing` is active, preventing lost focus when mouse moves outside the dock.
- **Synchronized Tab Repositioning**: `_update_channel_tabs_position()` automatically shifts `ChannelTabs` along with `ChatHistoryPanel.offset_top`.

---

## 4. Opacity & Background Mode Toggle
- **Toggle Mechanism (`BtnChatSwitch` / `toggle_chat_opacity()`)**:
  - **Transparent Mode (Default)**: Background set to `Color(0, 0, 0, 0)`; text renders cleanly over the world canvas with drop shadows.
  - **Framed Mode**: Enables the authentic `Panel_TalkForm` NinePatchRect border (`assets/hud/panel_talk_form.png`) with semi-transparent dark slate tint (`Color(0.04, 0.08, 0.12, 0.55)`).

---

## 5. Whisper Targeting & Emoticon Integration
- **`/target` Syntax**:
  - Typing `/target <PlayerName> [Message]` sets the whisper target, auto-switches to Whisper channel, and immediately sends the message if present.
  - Also supports `/w <PlayerName> [Message]` and `/whisper <PlayerName> [Message]`.
- **Player Name Click-to-Whisper**:
  - Sender names are enclosed in `[url=whisper:<PlayerName>]`.
  - Clicking a name fires `_on_chat_meta_clicked()`, automatically populating `WhisperTarget`, switching transmission channel to `Whisper`, and focusing `ChatInput`.
- **31-Emote Popup Grid (`BtnEmote`)**:
  - Displays authentic $263 \times 69$ gold popup containing all 31 animated emoticons (`#01` to `#31`).
  - Clicking any emoticon appends `#XX` into `ChatInput` and triggers an overhead speech bubble above the player entity.

---

## 6. Verification Test Suites
Verified through headless execution in Godot 4:
```powershell
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" -s res://tests/test_hud_chat_and_status_features.gd
& "C:\Godot\godot_console.exe" --headless --path "D:\Godot\WonderlandOnline\wonderland-online-client" scenes/tests/test_hud_runner.tscn
```
- Results:
  - `[PASS] Chat switch button toggles between authentic compact and framed mode`
  - `[PASS] Chat message lock button toggles autoscroll behavior`
  - `[PASS] Chat size button cycles heights (-86, -140, -200)`
  - `[PASS] Channel dropdown selection works cleanly`
  - `[PASS] Whisper target automatically updates channel and formats chat output`
  - `[PASS] Emote popup with 31 authentic emotes verified, inserting code and emitting overhead bubble`
  - `[PASS] Vertical draggable resizer handle verified`
  - `[PASS] Channel tabs (All, Current, Team, Guild, Whisper, System) filtering verified`
  - `[PASS] /target syntax correctly sets whisper target and dispatches private message`
  - `[PASS] Clicking player name in chat automatically routes to whisper targeting`
  - `--- ALL CHAT DOCK & PLAYER STATUS TESTS PASSED (0 ERRORS) ---`
