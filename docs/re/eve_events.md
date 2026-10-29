# Eve.emg event scripts (NPC conversations) - ported from the C# server

Source: `D:\GitHub\Wonderland-Private-Server\wlo.pserver.core\Game\Maps\Code\EveEventRuntime.cs` (`FindBranch`, `MatchesCondition`),
`EveEventInterpreter.cs` (`ExecuteOpcode`) and `DataFiles\EveLoader.cs`. Godot: `scripts/map/eve_parser.gd` (`get_events_for_map`),
`scripts/map/npc_event_script.gd`, tests `test_npc_event_script.gd` (fixtures) and `test_eve_real_npc_scripts.gd` (real Eve.emg).

## Data
- Map block category 4 = events: `u16 click_id, u8, char[20] name, u8 n_subs`, each sub: `u8 index, u8 cond_byte, 6 x u16 words, 2 x u32, u8 n_ops`,
  each op (22 bytes): `u8 index, u8 opcode, 4 x u16 d1..d4, 3 x u32`.
- An NPC (Npclist entry) lists its linked event ids; the first linked event that has a matching branch runs.

## Branch selection (a click)
1. Walk the subs in order. Subs without ops are conditions, not branches. `cond_byte` 4, 7, 8 are callbacks (answers) and are skipped on a click.
2. The branch's own condition must hold AND the next `max(1, words[5] >> 8) - 1` subs (pure conditions) must hold too.
3. First match wins.

## Conditions (`value = (w3 >> 8) | (w4 << 8) | ((w5 & 255) << 24)`, `comparison = w3 & 255`: 1 <, 2 >, 3 <=, 4 >=, 5 ==, 6 !=)
| cond_byte | Meaning |
|---|---|
| 0, 6 | always (6 = normal greeting) |
| 1 | all of w0..w3 are zero |
| 5 | quest: `w1 == 2` quest NOT in progress; `w1 == 1` compare the quest step with `value` (absent quest = step 0, "active" only matters for `w1 == 2`) |
| 2 | `w0 == 1`: `w1 == 1` item count of item `w2`, `w1 == 2` gold, `w1 == 3` level; `w0 == 2` pets/companions (not modelled) |
| 3 | chest/prop opened state (never opened in Godot) |
| 10 | learned grade of skill `w0` |
| 13, 14, 17 | team size / gathering timer / special gates: unsupported -> false |
| 15 | free bag slots compared with `value` |
| other | unsupported conditions never match (they must not authorise rewards) |

## Ops
- opcode 2: NPC speaks Talk id `d3` (speaker click id `d1`); `d2 == 6` = ask a question (`d3` = question id).
- opcode 1: `d1 == 2` the player speaks Talk id `d2`; `d1 == 1, d2 == 1` item reward `d3` (count `d4 >> 8`); `d1 == 1, d2 == 2` gold; `d1 == 1, d2 == 5` exp
  (amount = `(d4 >> 8) | (dw0 << 8)`, signed); `d1 == 3` scene transition; `d1 == 5` record point; `d1 == 6/7` client events.
- opcode 5: quest flag, quest id `d1`, new step `d2`.
- opcode 3: companion action; 4/6: battle with formation `d2`; 7: ...; others see `ExecuteOpcode`.

## Questions and answers
A question branch ends with opcode 2 `d2 == 6`. The answer arrives as a callback: `cond_byte` 7 with `w0 == question id` and `w1 == answer` (first option 30, second 31).
The question text is the Talk line after the branch's last line (verified for Doll: 20227).

## Verified on the real data (Kelan Village, map 12000)
- Doll (14141): fresh -> 20222..20226 + question 1; Yes (30) -> quest 12018 step 1; No (31) -> 20229; step 1 -> 20228 (go to Emilie);
  step 2 without the pepper (item 30028) -> 20228; step 2 with it -> 20233..20235 + Radio Set (34076). Emilie fresh -> 30552, Guard -> 30037.
