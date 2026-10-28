# Real battle (observed by playing + reading live packets, 2026-10-28, Rhodes North Island forest, 1 Fresh Mush vs player + pet)

Evidence: screenshots `docs/reference/real_client/battle_*.png`; packets read with Frida hooks on `ws2_32!WSARecv` / `send` of aLogin.exe
(frames decoded by XOR 0xAD). Login frames (action 0x3F) were never recorded. **inferred** = guessed from values, not yet verified.

## Screen
- The world HUD stays: portrait + LV + HP/SP/EXP/Gold, F1..F8 bar, chat (as framed panel), bottom icon bar, top-right icon row.
  The top-right minimap is hidden during the fight. A full-screen **forest backdrop** replaces the map; ground is plain grass.
- Fighters stand freely on the grass (no grid): player party on the **right** (player feet ~ (658,425), pet ~ (592,417)), enemies on the **left** (single enemy ~ (160,415)).
  Names above heads: own name yellow ("restr"), pet / enemies cyan, a thin **red HP line** under each name. No turn banner, no timeline, no panels.
- **Big cyan number in the centre of the screen = command countdown** (starts at 20 and counts down 1 per second), not damage.
- Hovering a fighter shows a white text card left of it: `Name / element (Wind, Watr...) / LV:n / HP:cur/max` (no box).
- The enemy falls flat when beaten; afterwards the game returns to the map (victory dialog not captured).

## Command ring (28x28 icons = `Btn_Battle_1..7` sheets, 3 frames each)
Drawn around the fighter whose command is being entered, offsets from that fighter's feet:
| Icon | Sheet | Offset (x,y) | Meaning |
|---|---|---|---|
| shield | Btn_Battle_1 | (+2,-90) | Defend |
| fist + monster | Btn_Battle_2 | (+47,-68) | Catch / capture |
| running man | Btn_Battle_3 | (+57,-20) | Escape |
| bag | Btn_Battle_4 | (+29,+18) | Item |
| auto | Btn_Battle_5 | (-20,+18) | Auto battle |
| sword | Btn_Battle_6 | (-49,-20) | Attack (click it, then click the enemy) |
| wand | Btn_Battle_7 | (-41,-69) | Skill / magic |
- Flow: player's ring -> click sword -> click enemy -> the ring jumps to the **pet** (two commands per turn: player, then pet) -> when both are set the round plays.
  The chosen action's icon floats over the fighter. The camera then zooms in on the attackers and fighters step toward the enemy (attack animation with a gold slash ring).
- Our Godot `BTN_PATHS` ties Btn_Battle_1 to ATTACK but the artwork is the shield: the ring order above is the real one.

## Packets (framing `F4 44 len16`, then action, sub, data; hex below is decoded payload)
- **C->S `32 01`** = battle command, payload 51 bytes: `04 02 01 02 11 27 45 e0 00 46 56 | 02 01 NN 00 00 00 | 32 bytes of unreadable tail`.
  `NN` counts the round (01, 02 ...). The tail changes every packet (looks like a signature/encrypted block) - **do not forge**.
- **S->C `33 01 <fighter> 02 <stat> <u32>`**: stat update. `stat 0x19` = current HP, `0x1a` = current SP (inferred: values matched the on-screen
  numbers: HP 173 -> `ad 00 00 00`, ally HP 232 -> `e8 00`, mushroom HP 23 -> `17 00`). Fighter bytes seen: `04 02` own char, `03 02` pet, `01 02` enemy.
- **S->C `32 06 01 02 00`**, `32 04 00 01 02 0f 00 00 00`, `32 01 11 00 01 02 27 27 00 01 03 02 01 00 01 00 00 00 ...` = round events (start of round, action list). **inferred**, not decoded.
- **S->C `16 02 xx 00 aa bb cc 04`** (9-byte frames, very frequent, `xx` in 1a,1b,1c,28) = periodic ticks/animation sync (also seen outside battle). Unknown.
- **S->C `05 01 ce 7a 00 00 .. ..`** (8 bytes) and `05 08 91 e3 00 00 00` appear around round starts. Unknown.
- **S->C `23 0c <u32 sender> <emote>`** = emote chat (7-byte payload), shown as a small yellow face in the chat line; text chat has the length+text form.
- **C->S `ba 09 01 00` / S->C `ba 09 01 00 01 00 00 00 00`** = ping/keepalive (action 0xBA, sub 0x09 here).
- Ping `ba 10` from our docs differs from the `ba 09` seen live: the live server uses sub 0x09.

## Godot gaps to close
1. Command ring around the active fighter, pet command step, countdown number in the screen centre, no panels/timeline/diamonds.
2. Fighter positions as above; names/HP line style; hover info card; attack camera zoom.
3. Forest battle backdrop selection by map type (backdrop art not located yet; `bg_id` comes in the battle-prepare packet).
