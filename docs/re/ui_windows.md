# Real window layouts (observed in the live client, 800x600 view, origin = view top-left)

Captures: `docs/reference/real_client/`. Window origin estimates carry about +-4 px.

## World HUD (`world_hud.png`)
- Top-left: portrait, `LV n`, HP/SP/EXP/Gold text rows. Top-right action row of **10** round icons, pitch ~37 px, starting x~432:
  Btn_PlayerBattle (sword+chest), Btn_1 (crossed swords), Btn_2 (sword+figure), Btn_3 (sword+eye), Btn_4 (two figures = team),
  Btn_5 (handshake), Btn_6 (coins), Btn_8 (trophy), Btn_9 (chest), Btn_711 (storefront). Sheet heights 108/99/102/99/99/99/99/99/99/102.
- Right: F1..F8 hotkey bar. Bottom-left chat with `Local` channel tab; bottom-right icon bar (6 round icons). Location text bottom right
  "Rhodes1 Kelan Village X:2282 Y:2055". Hovering an icon shows a blue tooltip label ("Inventory", "Skills", "Team", "Social", "Options", "Alchemy").
- A scrolling yellow system ticker runs under the top icon row (e.g. "Grats to [..] daily draw ...").

## item / inventory (`inventory.png`, bottom icon 557,603) - window ~385x440 at (210,104)
- Title "item" with blue arrow buttons left/right of it (title centre rel (190,29), arrows rel (155,29) and (230,29)).
- Element orb (rel 30,59), character name (rel 49,59), `LV n` (rel 21,86), `Potential` button (rel 126,80, 42x18) + number (rel 175,88).
- Paper doll with sockets head/hand/arm/special/body/shoes; grey arrow pair around "shoes" (rel 49,245 and 148,245).
- HP/SP/EXP bars, Gold and POINT, ATK/DEF/MAT/MDF/SPD and STR/CON/INT/WIS/AGI rows.
- Right: 5-column item grid with counts; bottom centre `Close` button (Btn_Close_1, 56x20, rel centre 192,423).

## compound (`compound.png`, bottom icon 633,603)
- Title "compound", item grid left, big cauldron picture top-right, five `x` slots joined by `+`, `Synthesis` and `Close` buttons at the bottom.

## skill (`skill.png`, 597,603)
- Title "Skill", character name with arrows, tabs Physical / Magical / Assistant / Life / Intro, list rows `<icon> Name  N sp`, scrollbar,
  detail box ("Grade proficiency / attack way weapon"), Close.

## group (`group.png`, 675,603)
- Title "group", tabs Party / Instance. **Top table = the player's PETS** (4 rows: portrait, name, LV, tiny HP/SP bars, element orb, `Battle` and `Dismiss` buttons). Confirmed by the user.
- Lower "status" section = **TEAMMATES** (3 large framed boxes, empty when alone). Close at bottom.

## social (`social.png`, 709,603)
- Title "social", tabs Friend / Emote / Set Up. 5 rows (avatar, nickname, guild, LV, online, mail icon, tick checkbox), pager `1 / 1`,
  buttons `Send Mail`, `Del Friend`, Close.

## system (`system.png`, 745,603)
- Left column: PVP and PK (Off), Joining Battle (On), Trading (On), Chat Channels (Setup), Info Visibility (Setup), Zoom Mode (On),
  Party Invites (Off), Set Own Title (Setup), Local/Whisper/Party/Guild/World Color (arrow pickers).
- Right: Sound Options, BG Music On + Min/Max slider, SFX On + slider, Security Lock, Change Login, Blacklist Setup,
  Official Site, Change Password, Readme, Spawn Point, Chat Box, Balance Inquiry, Redeem Code, VIP, Redeem MyCard, Log Out,
  Buy IM Points, Exit, Close.

## chat (world view, bottom-left; `r_chat` capture)
- No panel and no tab row: bare text with a dark outline straight over the world, one line per message in the channel colour:
  `(World)LUCIANA:S>50 10x potion for 25usdt`, `(System)...`. A small face icon of the sender sits at the left of each line.
- Left ornate strip with up/down scroll arrows and two round purple buttons (lock, size). Bottom bar: mail icon, `Local` channel button filled
  bright green with white outlined text, recipient field, message field, smiley button at the right end.
- Windows close with their `Close` button; the tooltip on it reads `[ESC]` (ESC is the hotkey of the focused window's Close).

## Observed behaviours (live play, 2026-10-28)
- Top icon row tooltips (hover, blue box with white text): PK, Jump In, Spectate, Join Team, Make Friends, Money <gold>, Events, Lucky Draw, Item Mall
  (first icon, sword+chest, = Player Battle skin `Btn_PlayerBattle`, tooltip not captured).
- The blue "+" icon under the portrait: tooltip "Restore HP/SP using Potions and Bottles"; clicking it healed HP 198/208 -> 208/208 (auto-heal from the bag).
- System messages are **red** in the chat (`IM Points: 0`, `(SystemPrompt)Double EXP event has begun!...`); server announcements scroll as a yellow ticker below the top icon row.
- Chat input keeps keyboard focus: hotkeys (Q, I ...) are typed into the chat field instead; clicking the world does not release it. Backspace clears it.
- NPC interaction needs the player within a certain range (told by the user); clicking an NPC from afar does nothing. Godot already walks up first (`_pending_npc_interaction` in map_view.gd).

## NPC dialogue (`npc_dialogue.png`, click an NPC in range)
- Translucent window over the world: yellow title line ("What can I do for you?") top-left, NPC portrait top-right with the NPC name under it,
  option rows (`Buy equipment`, `Selling equipment.`) with the hovered row filled blue, a `Close` pill at the bottom centre, ornate gold corners.

## Weapon store (`shop.png`, option "Buy equipment")
- Title = the shop's name ("Weapon store"), no Buy/Trade tabs. Columns `name` / `effects` / `single price`; 5 fixed rows with icon, name, effects as
  stat changes (`ATK: +7, SPD: -3, Req LV: 4`, `MATK: +3, MDEF: +3, Req LV: 6`), price number only (no "G").
- Below: a strip of 10 empty purchase slots, `purchase amount 0`, `money held 0`, pills `Buy` and `Close` (no quantity spinner).
- Stock seen at Kelan Village Weapon Shop: Stone Ax 30, Mage's Wand 50, Leather Garmen 30, Lauan Stick 50, Bronze Claws 50.

## Chat controls (observed + told by the user, 2026-10-28)
- Top purple button of the left strip = lock: tooltip `Chatbox: Unlocked` / `Chatbox: Locked`, the icon turns gold while locked.
- Up / down arrows (yellow highlight on hover) scroll the log; between them a slider thumb.
- Bottom purple button = **Chat Box Switch** (tooltip "Chat Box Switch"): hides the whole log and leaves only the input bar with a single purple button at (8,591); press it again to restore.
- The ornate gold corner at the top-right of the chat box is a **drag handle**: dragging it up/down enlarges or shrinks the chat (told by the user).
- `Local` button (tooltip "Switch Channel") opens a stack of bright green buttons above it (Guild, Team, Whisper ...), no panel behind.
- Smiley button at the right end (tooltip "Chat Emotes") opens a grid of emotes with a close X.
- Chat lines start with the sender's small face icon.
- While the chat input has keyboard focus the log gets a translucent blue-grey framed panel with the gold corner ornament; when the field loses focus the log is bare text again (`_chat_is_framed` follows focus in `hud_chat.gd`).
- Emotes sent by players appear inline as small yellow face images inside the line (`(World)name:<face>`), not as text codes.
- Enter does not release chat focus; hotkeys (Q, I, ...) keep landing in the input field, so the quest window could not be opened by key during capture.
- Chat art (Godot): the gold frame is `Panel_TalkForm.bmp` (524x86, chroma key) as a 9-patch with a translucent blue-grey fill while typing; otherwise only its left strip `Panel_TalkForm2_1.bmp` (45x86) is drawn. Each log row is a 2-column table (face column + wrapping text) so continuation lines hang under the first letter. The recipient field (x74, w86) is always visible next to the message field (x163).

## Notebook (Notepad item, double-click in the inventory)
- `notebook.png`: small "Notebook" window (Form_NoteBook 223x223) with three skin buttons: Quest Log, Monster Book, Star Book, and a Close pill.
- Quest Log -> the "mission" window (see above). Monster Book -> **"collection book"** (`monster_book*.png`, skin `Form_Cellection_1.bmp` 463x367): 10-row list of
  met monsters (names cut at 12 chars), pager `1/1`, detail card (name, LV, element orb, HP, SP, STR, CON, INT, WIS, AGI, monster picture), Close.
  Star Book -> full-screen night sky of 28 constellation pictures (`Star_N.bmp`, two frames: plain and labelled), a tiny close button at the top-right.
- Godot: `scripts/ui/hud/notebook_window.gd`; met monsters persist in `user://monster_book.json` and are added after every won battle.
- Chat resizing: the gold ornament at the top-right of the chat frame is a drag handle (Godot: `ChatDragHandle`, `test_chat_drag_resize.gd`).

## NPC dialogue system (played the Kelan "Hill Pepper" quest with Doll and Emilie, 2026-10-28)
Captures: `docs/reference/real_client/quest_doll_*.png`, `emilie_*.png`, `player_speaks.png`, `doll_return_*.png`, `quest_reward_banner.png`.
- **NPC speaks:** translucent blue frame (`Form_Talk_1`, gold bars) at the TOP centre (~x135..665, y58..205). Text is yellow, centred, wraps in ~310 px; the NPC's own face (Npc.dat `talk_image`, jma 008) sits at the right with the NPC name centred below it; a pointing hand blinks at the bottom centre = click to continue. Key words are red inside the text ("Hill Pepper").
- **Player speaks:** the frame moves to the BOTTOM (y~440..590, over the chat), no portrait box; instead a **full-body player illustration** stands at the lower left (x40..210). Text yellow centred. Click advances.
- **Choices:** the frame grows downwards; a light-blue bordered list with rows (`Yes.` / `No.` or `1.` `2.` `3.` ...) appears under the text, hovered row filled blue, and a `Close` pill below. Clicking a row makes the player say it (the player's speech line appears next).
- **Quest flow (Doll):** talk (3 pages) -> choice Yes/No -> "I'll go to fetch some for you" -> quest `Hill Pepper` starts. Emilie (up the stairs north of the village) asks 3 quiz questions ("tens digit": 1/2/3, "units digit": 1,3,5,7,9 ... with the answer 29 -> gives Hill Pepper) -> back to Doll: player says "Doll, I have the Hill Pepper now." -> thanks -> asks the player's name -> gift -> **reward banner** "Obtain 1 pcs Radio Set" (small translucent frame with gold bars in the middle of the screen, text yellow).
- Click on an NPC works only within range and when the NPC is standing still; walking NPCs (Emilie) must be clicked on their body.
- **Dialogue frame technique (user's hint, 2026-10-28):** `Form_Talk_1.bmp` is a 50% checker already (every second pixel is chroma-key green), so the translucent look comes from the skin itself. To widen/heighten it, keep the four ends at native size (200x45) and tile a slice cut from the middle between them. Every piece must keep the source's pixel parity: frame width even, height odd (`_compose_frame` in `hud_dialogue.gd`).
