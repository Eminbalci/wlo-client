# Server architecture: single player + online MMO

Decision (2026-10-29): the game runs in two modes that share one rule set.

- **Single player:** the rules run inside the Godot client (`LocalBackend`). Saves go to `user://`. No network.
- **Online MMO:** the same rules run in an authoritative **Python server** (`server/`). The client only sends intents
  (buy, use item, deliver quest, attack, talk) and renders the results the server sends back.

The C# server (`D:\GitHub\Wonderland-Private-Server`) is a **reference only**: packet layouts, Eve.emg behaviour and
data files are read from it and from `D:\GitHub\WLRI\docs`. Its runtime is not reused (it did not work reliably).

## Single source of truth for rules
Rules are written as **data + test vectors**, not as duplicated code:

- `rules/data/*.json`: tables (EXP per level, stat growth, shop prices, item effects, quest steps).
- `rules/vectors/*.json`: input state -> expected output for every rule (EXP gain, level-up, item use, quest step,
  Eve condition, battle damage, drop roll with a fixed seed).
- Godot (`scripts/rules/`) and Python (`server/rules/`) each implement the rules and must pass the **same** vectors.
  A failing vector in either language blocks the change.

Result: the two languages cannot silently disagree, and single player and MMO give the same numbers.

## Authority boundary
| Concern | Who decides | Client role |
|---|---|---|
| Position, movement speed | server (validates steps and speed) | predicts locally, reconciles |
| EXP, level, stats, gold | server | displays |
| Inventory, item use, shop | server | displays, sends intent |
| Quest steps, rewards | server | displays |
| NPC conversation (Eve) | server (conditions + branches) | renders lines and choices |
| Battle outcome | server | animates the result |
| Drop and reward rolls | server (seeded RNG, logged) | displays |

## Protocol
- New length-prefixed binary protocol over TCP (or WebSocket later), versioned. The original client packet
  format is **not** kept: the original client is no longer the target, the Godot client is.
- Every intent carries a sequence number; the server replies with the same sequence number and the new state
  or a rejection code. Rate limits and sanity checks run before any rule.

## Phases
1. Rules as data + vectors (EXP curve, item effects, shop prices) with both implementations.
2. Python server skeleton: login, character store (SQLite), one map, movement and chat.
3. Economy: shop, inventory, item use, gold, EXP and level-up through the server.
4. Quests and Eve conversations through the server (rules shared via vectors).
5. Battle resolution on the server; client animates results.
6. Single-player mode: `LocalBackend` runs the same rules in-process and saves to disk.
7. Hardening: rate limits, logging, reconnect, anti-cheat checks.

## Open points (need real-game observation)
- EXP curve: `docs/kelan_combat_and_leveling_spec.md` (30/70/130/210) and the C# server formula disagree.
  The vectors will contain whichever value is confirmed; until then the curve is marked provisional.
