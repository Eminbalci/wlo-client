# Adding game content (all types)

Where each content type lives in the Godot client, the data files it reads, and the steps to add one.
Source of truth for binary formats: the original `Item.dat`, `Npc.dat`, `Skill.dat`, `Talk.dat`, `Eve.emg`,
`SceneData.dat`, `Ground.MMG`, `Wem.MMG` (files under `Data/`). The client reads them through `scripts/database/*`.
JSON files in `assets/data/` are derived copies (`all_npcs.json`, `all_maps.json`, `all_scenes.json`, `starter_items.json`).

| Content | Data file(s) | Loader | Steps to add one |
|---|---|---|---|
| Item | `Item.dat` (record) | `item_database.gd`, `item_data.gd` | Add the record to `Item.dat`, check the tooltip (`item_tooltip.gd`), icon and buy/sell prices (offsets 0x72, 0x76). |
| NPC | `Npc.dat`, `all_npcs.json` | `npc_database.gd` | Add the template; place it on a map with `Ground`/`Eve` entries; dialogue in `Talk.dat`. |
| Dialogue | `Talk.dat` | `talk_database.gd` | Add the talk entry; link it from the NPC's Eve script. |
| Event / quest step | `Eve.emg` (+ flags) | `npc_event_script.gd`, `eve_parser.gd` | Add the Eve branch (conditions, ops); quest flags are set by op 5. Quest reward ops: op 1 (d1==1). |
| Map / scene | `SceneData.dat`, `all_maps.json`, `all_scenes.json`, `Ground.MMG`, `Wem.MMG` | `scene_database.gd`, `map_view.gd` | Add the scene record and its ground/portal entries; add a transition (op 1, d1==3) from a neighbouring map. |
| Skill | `Skill.dat`, `SkillData.MBTM` | `skill_database.gd`, `skill_window.gd` | Add the skill record; the learned-skill list is filled by `init_default_learned_skills` and tree rules. |
| Shop (merchant) | shop catalogs in code (`shop_window.gd` `PROPS_SHOP_ITEM_IDS`), `starter_items.json` | `shop_window.gd` | Add the item id to the shop catalog; buy price override if it differs from `Item.dat`. |
| Item card (redeem) | server `Data/item_cards.json` | `ItemCardManager` (server) | Add a rule with `card_id` and `rewards`. |
| Quest disguise | server `Data/quest_disguises.json` | `QuestDisguiseTable` (server) | Add a rule with the map, event, branch and op pattern. |
| Arcade game | server `Data/arcade_games.json` | `ArcadeGameTable` (server) | Add a game with `kind`, `point_cost` and `rewards` (weights, reels). |

## Verification for every type

1. Run the matching test script under `tests/` (`test_npc_event_script.gd`, `test_eve_real_npc_scripts.gd`,
   `test_shop_window_and_merchant_trading.gd`, `test_props_shop_catalog.gd`, etc.) and the full suite before a push.
2. Open the game and trigger the content. This step needs a live client and a server; it is not covered by tests.

## Open decisions

- Which content type to start with is the user's call; each type above is independent.
- Server-side tables (item cards, quest disguises, arcade) are read by the C# server at startup; a restart is needed.
