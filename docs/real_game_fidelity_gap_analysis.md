# Wonderland Online Client - Real Game Fidelity Gap Analysis (Eksik ve Farklılık Matrisi)

## Overview & Methodology
This audit provides an itemized, component-by-component comparison between the original 32-bit Borland Delphi client (`aLogin.exe` / `Main.exe`, window class `TForm1`, running resolution 800x600) and the Godot 4 client (`wonderland-online-client`).
Evidence base:
- Live client captures: `docs/reference/real_client/*.png` (World HUD, Inventory, Compound, Skill, Group, Social, System, Shop, Chat, Dialogue, Battle, Notebook, Monster Book, Star Book).
- Disassembly & Decompilation: `docs/re/dispatch_table.md`, `docs/re/binary_notes.md`, `docs/re/ui_windows.md`, `docs/re/battle.md`.
- Live socket packet traces (WSARecv / send XOR 0xAD frames).
- Godot client source code (`scripts/`, `scenes/`).

---

## 1. World HUD & Screen Overlays

| Component | Real Game (Delphi Client) | Godot Client Status | Discrepancy / Missing Element |
|---|---|---|---|
| **Top-Right Action Bar** | 10 round buttons (`Btn_PlayerBattle`, `Btn_1`..`Btn_6`, `Btn_8`, `Btn_9`, `Btn_711`): PK, Jump In, Spectate, Join Team, Make Friends, Money, Events, Lucky Draw, Item Mall. | Present in `hud_top_bar.gd` (10 buttons). | 8 out of 10 buttons are non-functional stubs ("not available in this client yet"). Only Team and Battle Settings open windows. |
| **System Announcement Ticker** | A continuous yellow text ticker running directly underneath the top action bar displaying global server broadcasts, lucky draw wins, and GM event prompts. | Completely absent. | No ticker control exists in `HUD` or scene graph. |
| **Status Dock Auto-Heal ("+")** | A small circular blue "+" icon directly beneath the character bust portrait with tooltip `"Restore HP/SP using Potions and Bottles"`. Clicking instantly consumes healing items from the bag to restore HP/SP. | Completely absent. | Missing from `HUDPlayerStatus` and `PlayerStatusDock`. |
| **Radar Minimap** | Hidden during normal world view by default (opened via hotkey/dock); strictly hidden during combat encounters. | Always visible at top-right (offset 40px down); remains visible during combat. | Does not auto-hide during combat; placement overlaps default WLO layout. |
| **Chat Dock Display Mode** | Bare text with dark outline rendered directly over the game world without a background panel or tab row when idle; sender's character face icon displayed on the left of each line. | Uses a persistent framed PanelContainer or partial nine-patch toggle in `hud_chat.gd`. | Sender face icons not universally attached; frameless idle overlay is not identical. |
| **Chat Channel Selector** | Clicking the green `Local` channel button pops up a vertical stack of bright green channel pills directly above it without a backdrop. | Dropdown menu or tab bar. | Pop-up stack layout and skinning differ from real game. |
| **Chat Window Drag Resize** | The ornate gold filigree in the top-right corner of the chat frame acts as an interactive drag handle to enlarge or shrink chat height. | Partially implemented in `ChatDragHandle`. | Requires synchronization with the frameless idle rendering state. |
| **Chat Emotes** | Clicking the smiley button opens a grid of animated faces; sent emotes render inline inside chat lines as small graphical icons. | Emote grid popup exists, but emotes in received chat lines often render as text tokens rather than embedded inline sprites. | Inline chat emote texture rendering missing. |

---

## 2. VCL Floating Windows

| Window | Real Game (Delphi Client) | Godot Client Status | Discrepancy / Missing Element |
|---|---|---|---|
| **Item / Inventory Window** (`Form_RoleStatus_1`) | Single unified 385x440 window titled `"item"`. Contains header navigation arrows (`< item >`) to toggle between player and active pet; Potential stat button; shoe socket equipment page arrows; 50 inventory slots (5x10 grid); bottom `Close` pill. | Split into two separate floating windows: `CharacterWindow` and `InventoryWindow`. | Grid is only 45 slots (5x9) instead of 50 (5x10); header arrows for pet inventory missing; Potential button missing; shoe socket toggle missing; window is unnaturally split. |
| **Compound / Alchemy Window** (`Form_Compound_1`) | Titled `"compound"`. Left: 50-slot inventory grid; Top-right: Large authentic cauldron graphic in base slot; Center-right: 5 synthesis slots arranged with `+` connectors between them; Bottom: `Synthesis` and `Close` pills. | Straight vertical slot column at x=206; inventory grid on left. | Missing the large cauldron graphic inside the base slot; missing the visual `+` connector graphics between slots. |
| **Skill Window** (`Form_Skill_1`) | Header features `< Character Name >` arrows to toggle between player skills and pet skills. Tabs: Physical, Magical, Assistant, Life, Intro. Lists ONLY unlocked/learned skills with actual proficiency progression and weapon requirements. | Lists ALL skills in `Skill.dat` for the element; shows placeholder `-` / `Any` for proficiency and weapon requirement. | Learned-skills database filter missing; pet skill inspection missing; proficiency and weapon requirements not hooked to data. |
| **Group / Team Window** (`Form_Team_2`) | Tabs: `Party` and `Instance`. Top table: 4 rows of PETS (portrait, name, LV, HP/SP mini-bars, element orb, `Battle` and `Dismiss` buttons). Lower section: 3 party TEAMMATES. | Godot originally had top section as party members and bottom as companions; recently modified. | `Instance` tab is empty/stubbed; pet `Dismiss` confirmation and amity penalties not hooked to server logic. |
| **Social / Friends Window** (`Form_Friend_2`) | Titled `"social"`. Tabs: `Friend`, `Emote`, `Set Up`. 5 rows per page with avatar, nickname, guild, level, online light, mail icon, tick box, and pager `1 / 1`. Buttons: `Send Mail`, `Del Friend`, `Close`. | Standalone friends list without tabs. | Missing `Emote` and `Set Up` tabs; missing pagination controls (`1 / 1`); missing `Send Mail` button integration. |
| **System Settings Window** (`Form_System_2`) | Full operational suite: PVP/PK toggle, Join Battle, Trade Lock, Party Invite Lock, Security Lock, Change Login, Blacklist, Color Pickers. | Sliders for BGM/SFX and display mode work. | Gameplay toggles (PVP/PK, Join Battle, Trade Lock, Security Lock, Blacklist) are cosmetic only and do not affect game rules. |
| **Shop / Merchant Window** (`Form_ThingStore_1`) | Title matches store name ("Weapon store", "Grocery store"). Columns: `name`, `effects` (stat deltas: ATK +7, SPD -3, Req LV 4), `single price`. Bottom: 10-slot purchase staging tray, `purchase amount`, `money held`, pills `Buy` and `Close`. | Mode toggle tabs ("Buy" / "Sell"), quantity SpinBox (1..99). | Missing 10-slot purchase staging tray; quantity SpinBox is non-authentic (real game uses click-to-tray); missing equipment stat modifiers column. |
| **Notebook Window** (`Form_NoteBook`) | Accessed via double-clicking Notepad in inventory. Opens 3 sub-books: Quest Log (Missions), Monster Book (`Form_Cellection_1`, 10 rows/page, monster stats/art), and Star Book (28 constellations sky map). | Partial implementation in `notebook_window.gd`. | Live battle encounter auto-logging to Monster Book is not hooked; Star Book is static without interactive constellation stars. |

---

## 3. Battle System

| Feature | Real Game (Delphi Client) | Godot Client Status | Discrepancy / Missing Element |
|---|---|---|---|
| **Battle Arena Backdrop** | Fullscreen environmental backdrops (Forest, Mountain, Cave, Ocean) determined by map `bg_id`. Plain green grass or cave floor. | Takes a screen capture of the overland map and blurs it (`_capture_clean_backdrop()`). | Synthetic map blur instead of authentic WLO pre-rendered battle backgrounds. |
| **Grid & Positioning** | Free-standing combatants without visible grids or diamonds. Party on the right (Player ~(658,425), Pet ~(592,417)), enemies on the left (Single enemy ~(160,415)). | Renders 2:1 axonometric isometric diamond grid overlays and dividing lines. | Synthetic diamond grids and dividers do not exist in the original battle view. |
| **Fighter Overhead Info** | Player name in yellow, pet/enemies in cyan. A direct thin red horizontal HP line located immediately beneath the name. No bulky floating health bars or SP bars over heads. | Uses thick floating HP and SP ProgressBars over character heads. | Non-authentic bulky overhead health/mana bars instead of thin red HP line. |
| **Turn Timeline / UI Panels** | No turn order timeline, no initiative order dock, no turn banners, no diamond panels. | Features `TurnTimelineDock` with initiative turn cards and SPD sorting. | Timeline dock is completely synthetic and absent from real game. |
| **Round Countdown Timer** | Large cyan digital number in the center of the screen counting down from 20 to 0 (20-second command input timer). | Missing or represented as generic UI timer. | Authentic centered 20s cyan countdown number missing. |
| **Command Radial Ring** | 7 round 28x28 icons (`Btn_Battle_1..7`) arranged in a radial circle around the active fighter's feet: Defend (top), Catch (top-right), Escape (right), Item (bottom-right), Auto (bottom-left), Attack (left), Skill (top-left). | Buttons docked at bottom-right or contextual menu. | Radial ring geometry and sheet icon ordering differ from real game. |
| **Turn Sequencing** | 2-phase input per round: Command ring appears around Player -> Player selects action & target -> Ring immediately jumps to Pet -> Pet selects action & target -> Round executes. | Single-action player turn flow; pet turn is not sequenced as a radial handoff. | 2-step player-to-pet radial ring handoff missing. |
| **Target Hover Card** | Hovering a fighter displays a plain white text info card to the left: `Name / Element / LV: n / HP: cur/max` (no background panel). | Uses selection reticles or generic popups. | Authentic plain white text hover card missing. |
| **Combat Camera & Animation** | Dynamic camera zooms in toward the attacking party; fighters physically step forward, perform combat swing with a golden circular slash ring; defeated enemies collapse flat on the ground. | Static camera; basic linear tweens without dynamic zoom or authentic enemy collapse animation. | Camera zoom, forward step lunges, slash rings, and enemy collapse missing. |
| **Network Battle Protocol** | Server-driven combat: Start (`32 06`), Client command (`32 01`, 51 bytes with round counter), Stat updates (`33 01` HP 0x19, SP 0x1A), Round scripts (`32 04`). | Completely offline/simulated in `battle_manager.gd` using client-side RNG. | Zero wire synchronization with real battle packets. |

---

## 4. NPC Dialogue, Quests & Events

| Feature | Real Game (Delphi Client) | Godot Client Status | Discrepancy / Missing Element |
|---|---|---|---|
| **Dialogue Window Position** | Dual-position system: **NPC speaking:** Frame at TOP CENTER (`~x135..665, y58..205`) with NPC portrait on right and name below; **Player speaking:** Frame moves to BOTTOM (`~y440..590`) with a full-body illustrated standee at lower-left (`x40..210`). | Static middle/bottom dock (768x169). | Missing top-center placement for NPCs, missing bottom placement for player, and missing player full-body standee. |
| **Keyword Highlighting** | Quest key terms and item names appear in highlighted bright red inside dialogue text (e.g. `"Hill Pepper"`). | Plain uniform yellow/white BBCode text. | Red keyword highlighting missing from dialogue parser. |
| **Branching Choices** | Choices list embeds directly inside the main dialogue frame beneath the text, surrounded by a light-blue border with blue row hover fill and a `Close` pill button. | Opens a separate standalone popup window (`Form_Talk_3`, 324x168). | Separate popup window instead of embedded frame expansion. |
| **Quest Reward Banner** | A dedicated small translucent frame with gold filigree appears in the screen center: `"Obtain 1 pcs [Item Name]"` with `wav9911` audio. | Chat message or generic toast banner. | Authentic centered reward frame banner missing. |
| **NPC Click Range & Motion** | Talking requires the player to be within interaction range; moving NPCs must be clicked directly on their moving body and cannot be triggered from distance. | Player can click NPCs from any distance (auto-walks, but does not enforce stationary body click rules). | Authentic interaction range gating and moving target picking discrepancies. |

---

## 5. Network Protocol & Server Dispatch Table

| Protocol Area | Real Game (Delphi Client) | Godot Client Status | Discrepancy / Missing Element |
|---|---|---|---|
| **Dispatch Table Coverage** | 91 active action codes switched in `aLogin.exe` (`0x2de1d4` / `dispatch_table.md`). | Only 6 action codes handled: 0x00 (Notice), 0x01 (Status), 0x06 (Walk), 0x23 (Chat), 0x3F (Login), 0xBA (Ping). | **85 action handlers are completely missing** (Battle 0x32/0x33, Items 0x0B/0x0C/0x0D, Trade 0x18/0x19, Stall 0x1A, Party 0x1B, Friend 0x20, Mail 0x24, Tent 0x28/0x29, Guild 0x44, Crafting 0x48). |
| **Keepalive / Ping Subcode** | Live server packets capture keepalive as Action `0xBA`, Sub `0x09` (`BA 09 01 00`). | Godot client sends Action `0xBA`, Sub `0x10` (`BA 10 00`). | Subcode mismatch between client ping and live server keepalive expectation. |
| **Battle Packets** | Real client exchanges `32 01` (command), `33 01` (HP/SP stat sync), `32 06` (round start), `32 04` (action resolution). | Zero battle packets implemented in `network_manager.gd`. | All combat is executed in offline simulation mode without server wire binding. |
| **Inventory & Equipment Sync** | Server tracks inventory slots, equipment swaps, durability, and ground drops via dedicated item packets. | Managed entirely on client via local Dictionary array in `hud_inventory.gd`. | Client-side inventory state is not synchronized with real server packets. |

---

## 6. Core Gameplay Mechanics & Data Tables

| Mechanic | Real Game (Delphi Client) | Godot Client Status | Discrepancy / Missing Element |
|---|---|---|---|
| **Damage & Combat Formulas** | Encoded in 407-byte `Formula.dat` using exact IEEE double-precision multipliers for element affinity (Fire > Wind > Earth > Water > Fire), ATK/MATK ratios, combo multipliers, and defense reductions. | Uses simplified heuristic formula: `damage = max(1, int(atk * 2.0 - def * 1.2))`. | Formula.dat multipliers not loaded or applied; combo attacks missing. |
| **Consumable Item Recovery** | `Item.dat` specifies exact HP, SP, status cure (poison/freeze), and pet amity recovery values per consumable item. | `HUDInventory.use_or_equip_inventory_item()` only decrements count and prints `"Used [Item]"`. | Consumables do not actually restore HP, SP, amity, or remove status ailments. |
| **Attribute Point Distribution** | Leveling up grants unallocated attribute points (`POINT` in `Form_RoleStatus_1`) that can be freely invested into STR, CON, INT, WIS, AGI. | Auto-allocates or leaves unspent points static without interactive allocation buttons. | Free stat point allocation mechanic missing. |
| **Tent / Mobile Player Housing** | Players can deploy their tent in any outdoor field map, enter the tent interior, arrange furniture, craft at workbenches, and store pets. | Only exists as an offline developer editor in `TentEditor` (`scripts/tools/tent_editor.gd`). | In-game overworld tent deployment and interior transitions missing. |
| **Pet Capture Mechanic** | Catch command in battle (`Btn_Battle_2`) allows capturing wild monsters into the pet roster if their HP is low. | Catch command button exists, but does not capture monsters or add them to the party. | Pet capture gameplay loop missing. |

---

## 7. Completely Missing Subsystems

The following major systems from the original Wonderland Online MMORPG are completely absent in the current client:
1. **Player Vending Stalls:** Setting up street vendor shops (`Btn_StallThing_1`, `Btn_StallPet_1`) to sell items and pets for gold to other players while AFK.
2. **Player-to-Player Secure Trading:** 2-player direct trade interface with item slots, gold input, lock confirmation, and trade execution.
3. **In-Game Mailbox & Delivery:** Postal system for sending messages, gold, and parcel attachments to offline/online characters (`Btn_Mail_1`, `Btn_SendMail_1`).
4. **Guilds / Organizations:** Guild creation, ranks, member management, organization chat channel, and guild emblem customization (`Btn_ArmyGrounp_1`, `OrgLeader.bmp`).
5. **Vehicle Manufacturing & Fuel:** Workshop blueprints for crafting rafts, canoes, steamships, hot air balloons, airplanes, and cars in the tent, requiring fuel items (`Btn_Gas.bmp`).
6. **Rebirth & Potential System:** High-level character rebirth questline, attribute uncapping, and Potential point mechanics.
7. **Mini-Games:** Integrated classic mini-games: Gomoku / Five in a Row (`Gobang_C.bmp`), Whack-a-Mole (`HitMouse_Exit_Btn.bmp`), and Hunting (`Hunting_Exit_Btn.bmp`).
8. **Item Mall & Daily Roulette:** In-game cash shop (`Btn_711`) and daily lucky draw wheel (`Btn_LotteryOL` / `Btn_TurnGame`).
