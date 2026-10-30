# Wonderland Online Client - Task Tracker

# Skill Window Weapon Requirements, Proficiency, & Learned Skills Model
- [x] 1. Data Decoding in `SkillDatabase`:
  - [x] 1.1 Decoded combat mechanism (offset 27..28) and weapon classes (Sword, Bow, Gun, Spear, Staff, Barehanded, Any).
  - [x] 1.2 Decoded proficiency requirement from rank (offset 30, Grade 1..10).
  - [x] 1.3 Extended `SkillRecord` and `to_dict()` with `weapon_requirement`, `weapon_requirement_type`, and `proficiency_required`.
- [x] 2. Skill Window Detail Inspection Parity:
  - [x] 2.1 Replaced static `"-"` and `"Any"` placeholders in `_update_detail_panel()` with dynamic `detail_weapon_label` and `detail_proficiency_label` ("Grade %d").
- [x] 3. Learned Skills Model & Filtering:
  - [x] 3.1 Implemented `_learned_skill_ids` dictionary, `is_skill_learned()`, `learn_skill()`, `unlearn_skill()`, and `init_default_learned_skills()`.
  - [x] 3.2 Implemented `learned_skills_only` toggle mode to filter listed skills to only unlocked skills.
- [x] 4. Automated Testing & Verification:
  - [x] 4.1 Created `tests/test_skill_window_weapon_and_learned_skills.gd` verifying database weapon/proficiency decoding, UI detail panel updates, and learned skills filtering.
  - [x] 4.2 Executed test suite with headless Godot console (100% pass, 0 failures).
  - [x] 4.3 Verified regression suites `tests/test_skill_window_and_hotbar.gd` (83/83 passed) and `tests/test_floating_windows_and_system_settings.gd` (146/146 passed).
- [x] 5. Technical Documentation & Global Updates:
  - [x] 5.1 Created `docs/skill_window_weapon_and_learned_skills_spec.md`.
  - [x] 5.2 Updated `README.md`.
  - [x] 5.3 Marked completed in `todo.md`.

# Compound Window Authentic Parity (Form_Compound_1)
- [x] 1. Authentic Visual Assets Extraction:
  - [x] 1.1 Extracted pixel-perfect cauldron illustration (`assets/hud/compound_cauldron.png`, 80x95) from real client capture (`compound.png`).
  - [x] 1.2 Extracted authentic `+` connector sign (`assets/hud/icon_compound_plus.png`, 16x16) linking the 5 synthesis slots.
- [x] 2. UI Layout & Slot State Parity:
  - [x] 2.1 Added `cauldron_rect` TextureRect displaying authentic cauldron artwork at Vector2(198, 70).
  - [x] 2.2 Added 4 `plus_connectors` between Main Base slot and Sub Material slots 0..3 (Y=212, 269, 320, 371).
  - [x] 2.3 Implemented empty base slot watermark (`compound_cauldron.png` at 45% alpha), switching to full opacity item icon when filled.
- [x] 3. Dynamic Bag Grid Population:
  - [x] 3.1 Initialized 50-slot inventory bag grid (`GridBag`) dynamically from player inventory (`HUDInventory.inventory_data`).
  - [x] 3.2 Added authentic default compoundable materials (ores, wood, grass, clay, water, alchemy books) when opened in standalone mode.
  - [x] 3.3 Maintained full left-click and right-click transfer between bag and synthesis slots, returning placed items on close.
- [x] 4. Automated Testing & Verification:
  - [x] 4.1 Created `tests/test_compound_window_parity.gd` verifying cauldron picture, plus connectors, main slot watermark, item placement, and 50-slot grid population.
  - [x] 4.2 Executed test suite via headless Godot console (100% pass, 0 failures).
  - [x] 4.3 Verified regression suite `tests/test_compound_window_and_simulator_spawner.gd` (10/10 passed, 100%).
- [x] 5. Technical Documentation & Global Updates:
  - [x] 5.1 Created `docs/compound_window_parity_specification.md`.
  - [x] 5.2 Updated `README.md`.
  - [x] 5.3 Marked completed in `todo.md`.

# System Window Options, Chat Colors, & Gameplay Flags
- [x] 1. Dynamic Chat Color Propagation:
  - [x] 1.1 In `scripts/ui/hud/chat_dock.gd`, added `apply_chat_colors()` and `_channel_colors` dictionary.
  - [x] 1.2 Updated `_format_line()` and `_update_channel_button_style()` to use dynamic channel colors from SystemWindow.
  - [x] 1.3 Wired `_on_system_settings_changed()` in `scripts/ui/hud.gd` to dispatch `chat_colors` to both `chat_ctrl` and `chat_dock`.
- [x] 2. Gameplay Option Synchronization:
  - [x] 2.1 Wired `system_options["pvp_pk"]` to invert PK safety lock in `FightWindow` and `BattleManager`.
  - [x] 2.2 Added gameplay permission query methods on `HUD`: `is_trading_allowed()`, `is_party_invites_allowed()`, `is_join_battle_allowed()`, `is_pvp_allowed()`.
  - [x] 2.3 Guarded `TopActionBar` trade requests against disabled trading settings.
- [x] 3. Automated Testing & Verification:
  - [x] 3.1 Created `tests/test_system_window_options_and_chat_colors.gd` testing dynamic chat colors, HUD option dispatch, PK safety inversion, and TopBar trade guard.
  - [x] 3.2 Executed test suite via headless Godot console (19/19 passed, 0 failures, 100%).
- [x] 4. Technical Documentation & Global Updates:
  - [x] 4.1 Created `docs/system_window_options_and_chat_colors_spec.md`.
  - [x] 4.2 Updated `README.md`.
  - [x] 4.3 Marked completed in `todo.md`.

# Consumable Item Recovery & Status Effects System
- [x] 1. Data Decoding & ItemRecord Status Math:
  - [x] 1.1 Decoded status types 25 (HP), 26 (SP), 64 (Amity), and 36 (EXP) in `itemDat.wpdat` / `Item.dat` with `delta = raw_val - 100`.
  - [x] 1.2 Added `get_hp_restore()`, `get_sp_restore()`, and `get_amity_restore()` to `ItemRecord`.
  - [x] 1.3 Updated `get_formatted_stats()` to render consumable recovery badges ("HP +50", "SP +150") in tooltips.
- [x] 2. Character Status & HUD Synchronization:
  - [x] 2.1 Added `restore_hp(amount)` and `restore_sp(amount)` in `HUDCharacterStatus` with clamping up to `current_max_hp` / `current_max_sp`.
  - [x] 2.2 Synchronized `stat_left_hp`, `stat_left_sp`, `CharacterManager.save_character`, and HUD player status dock bar tweens.
- [x] 3. Inventory Item Consumption Pipeline:
  - [x] 3.1 Extended `HUDInventory.use_or_equip_inventory_item()` to execute HP/SP healing when consuming foods and medicines.
  - [x] 3.2 Implemented audio feedback (`wav0151.wav`), chat logging (`Used Bread (+50 HP)`), and floating toast notifications.
  - [x] 3.3 Decremented item stacks properly down to empty slots.
- [x] 4. Automated Testing & Verification:
  - [x] 4.1 Created `tests/test_consumable_item_recovery.gd` covering database decoding, status math, controller healing, inventory use, and tooltip badges.
  - [x] 4.2 Ran test suite via headless Godot console (35/35 passed, 0 failures, 100%).
- [x] 5. Technical Documentation & Global Updates:
  - [x] 5.1 Created `docs/consumable_item_recovery_specification.md`.
  - [x] 5.2 Updated `README.md`.
  - [x] 5.3 Marked completed in `todo.md`.

# Clean Workspace & Repository Deployment (Eminbalci/wlo-client)
- [x] 1. Clean Unnecessary Temporary Files & Dumps:
  - [x] 1.1 Remove loose screenshot, debug render, and crop PNGs + .import files from root folder.
  - [x] 1.2 Remove temporary reverse-engineering dump folders: `dump_008`, `dump_bmg`, `dump_btn_rolepic`, `dump_heads_test`, `dump_jrole`, `dump_roleinfo`, `dump_rolepic_clean`, `scratch`, `screenshots_auth`, `test_screenshots`.
  - [x] 1.3 Remove 1.4 GB unused dead file `assets/data/odd.dat` and `assets/pic/Thumbs.db`.
- [x] 2. Configure Git & .gitignore:
  - [x] 2.1 Write production Godot 4 `.gitignore` excluding `.godot/`, temporary dumps, and oversized binary archives (>100MB) that exceed GitHub file limits.
  - [x] 2.2 Initialize git repository and set remote to `https://github.com/Eminbalci/wlo-client.git`.
  - [x] 2.3 Verify repository status with `git status`.
- [x] 3. Commit & Push to GitHub:
  - [x] 3.1 Stage all clean source code, scenes, shaders, assets, docs, and tests.
  - [x] 3.2 Commit with descriptive commit message.
  - [x] 3.3 Push to `main` branch on `https://github.com/Eminbalci/wlo-client`.
- [x] 4. Documentation & Verification:
  - [x] 4.1 Update `README.md` with repository link and clean project setup instructions.
  - [x] 4.2 Document workspace cleanup and repository structure in `docs/workspace_cleanup_and_git_setup.md`.
  - [x] 4.3 Update `todo.md` marking completed tasks.

# Companion Ride Mode (NPC / Pet Mounting System)
- [x] 1. Asset Slicing & UI Controls (`team_window.gd`):
  - [x] 1.1 Slice `Btn_AssignRide_1.bmp` into authentic 3-state transparent textures: `btn_assign_ride_normal.png`, `btn_assign_ride_hover.png`, `btn_assign_ride_pressed.png` in `assets/hud/`.
  - [x] 1.2 In `scripts/ui/hud/team_window.gd`, add "Ride" button alongside "Battle" / "Dismiss" on each pet row (`row_ride_buttons`).
  - [x] 1.3 Implement Ride state machine: a pet can be Rest, Battle, or Ride (mutually exclusive across all pets).
  - [x] 1.4 Wire `companion_ride_toggled(pet_id, is_riding)` and `companion_mounted(pet_dict)` signals.
- [x] 2. AdjustRidePetPos Data Parser & Offset Calculations:
  - [x] 2.1 Create parser in `scripts/world/ride_data.gd` to load and parse `assets/data/AdjustRidePetPos.txt`.
  - [x] 2.2 Provide heading-indexed (0..7) offset resolution for `StandPos` and `MovePos` per character sex/role and NPC model.
  - [x] 2.3 Provide graceful defaults for pets not explicitly listed in `AdjustRidePetPos.txt` (e.g. S. Monkey 1103).
- [x] 3. Player Entity & MapView Mount Kinematics:
  - [x] 3.1 In `scripts/world/player.gd`, implement `mount_pet(pet_data: Dictionary)` and `dismount_pet()`.
  - [x] 3.2 In `PlayerEntity`, manage mount display under player: mount plays walk (0..31) / stand (32..63) matching player heading, while player assumes sitting/riding pose (frames 64..95) offset by `AdjustRidePetPos`.
  - [x] 3.3 Apply authentic mounted speed bonus (e.g. 1.35x, 160 px/s).
  - [x] 3.4 In `scripts/map/map_view.gd`, connect `team_window` ride signals to `player.mount_pet()` / `player.dismount_pet()`, hiding overland follower while mounted.
- [x] 4. Automated Testing & Verification:
  - [x] 4.1 Create test suite in `tests/test_companion_ride_mode.gd` verifying Ride button toggling, mutual exclusion with Battle mode, offset math, mount attachment, speed bonus, and dismount.
  - [x] 4.2 Run tests via headless Godot runner and confirm 100% zero-error pass rate.
- [x] 5. Technical Documentation & Global Updates:
  - [x] 5.1 Create `docs/companion_ride_mode_specification.md`.
  - [x] 5.2 Update global `readme.md`.
  - [x] 5.3 Mark completed tasks in `todo.md`.

# Companion Follower Breadcrumb Walking & Path Kinematics (No-Teleport Fix)
- [x] 1. Follower Breadcrumb Trail & Smooth Walking Kinematics:
  - [x] 1.1 In `scripts/map/map_view.gd`, implement breadcrumb trail (`_follower_trail`) so the companion walks along the player's path rather than snapping to an instant backward vector.
  - [x] 1.2 Keep `_companion_follower.is_moving = true` continuously while following breadcrumbs so the authentic 4-frame walk animation plays smoothly without stopping every frame.
  - [x] 1.3 Stop walking (`is_moving = false`, call `_update_frame()`) only when the follower arrives within trailing distance (<= 48px) and the player has stopped, orienting heading to face the player.
  - [x] 1.4 Remove artificial teleport threshold (`dist > 450.0`) during normal walking; only allow position snap on extreme map transitions (> 900px).
- [x] 2. Interaction & Signal Conflict Fixes:
  - [x] 2.1 In `find_npc_near_world_pos`, explicitly exclude `_companion_follower` so clicking near the pet does not interrupt player movement.
  - [x] 2.2 Disable `ClickArea` on `_companion_follower` in `spawn_companion_follower()`.
  - [x] 2.3 Remove redundant call from `_on_player_position_updated()` to let `_process(delta)` drive smooth movement exclusively.
- [x] 3. Automated Testing & Verification:
  - [x] 3.1 Update `tests/test_team_window_and_companions.gd` to verify breadcrumb trailing, continuous walk state, and no-teleport behavior.
  - [x] 3.2 Run headless test suites and confirm 100% zero-error pass rate.
- [x] 4. Documentation & Global Updates:
  - [x] 4.1 Update `docs/companion_battle_mode_and_follower_spec.md`.
  - [x] 4.2 Update `readme.md`.
  - [x] 4.3 Mark tasks completed in `todo.md`.

# Companion Battle Mode, Walking Follower, & Authentic NPC Portraits
- [x] 1. Single Pet Battle Mode Enforcement & UI State:
  - [x] 1.1 In `scripts/ui/hud/team_window.gd`, enforce strictly ONE pet in Battle mode at any time.
  - [x] 1.2 Update `_refresh_pet_rows()` and `_refresh_real_client_controls()` so `row_battle_buttons[i]` displays "Rest" when summoned (`is_summoned == true`) and "Battle" when inactive.
  - [x] 1.3 Update `_on_pet_row_button()`: if clicking "Battle" on an inactive pet, recall all other summoned pets and summon the target pet; if clicking "Rest" on the currently summoned pet, recall it.
- [x] 2. Companion Overland Walking & Follow Movement:
  - [x] 2.1 Correct S. Monkey model JMP from `1118.jmp` (boulder) to `1103.jmp` in both `team_window.gd` and `map_view.gd`.
  - [x] 2.2 In `scripts/map/map_view.gd`, hook companion follower movement into `_process(delta)` for smooth continuous movement.
  - [x] 2.3 Set `_companion_follower.is_moving = true` when distance > 16.0 px so authentic 4-frame walk animation plays, moving toward player with appropriate speed and heading.
  - [x] 2.4 Set `_companion_follower.is_moving = false` when within 16.0 px, facing player.
- [x] 3. Authentic NPC Companion Portraits & Avatars:
  - [x] 3.1 In `scripts/ui/hud/team_window.gd`, replace human player role fallbacks in `_resolve_companion_avatar()`.
  - [x] 3.2 Fetch authentic portraits from `008.jma` via `ArchiveLoader.get_npc_portrait(talk_image)` (Roca 8090, Kelan Leader 8038, Robinson 8067, etc.).
  - [x] 3.3 For non-humanoid companions (`talk_image == 0`, e.g. S. Monkey 1103), resolve sprite texture via `ArchiveLoader.get_npc_texture(sprite_id, 0)` or `ArchiveLoader.get_jma_animation("001.jma", model_jmp)`.
- [x] 4. Automated Testing & Verification:
  - [x] 4.1 Update `tests/test_team_window_and_companions.gd` with tests for single battle mode, button text/state transitions, and authentic companion avatars.
  - [x] 4.2 Run headless test suites and confirm 100% pass rate with zero errors.
- [x] 5. Technical Documentation & Global Updates:
  - [x] 5.1 Create `docs/companion_battle_mode_and_follower_spec.md`.
  - [x] 5.2 Update global `readme.md`.
  - [x] 5.3 Mark tasks completed in `todo.md`.

- [x] 1. Asset Inspection & Slicing:
  - [x] 1.1 Inspect `D:/GitHub/wlridecode/menu/Skins/` for store bitmaps: `Form_PharmacyStore.bmp`, `Form_ThingStore_1.bmp`, `Form_WeaponStore_1.bmp`, `Form_Shopping_1.bmp`, `ShopTab_1..7.bmp`, `Icon_ShopMark_1.bmp`.
  - [x] 1.2 Convert to transparent PNG assets in `assets/hud/` with green `[0, 255, 0]` chroma-keying and defringing (`form_store_1.png`, `form_thing_store_1.png`, `form_weapon_store_1.png`, `form_pharmacy_store.png`, `form_shopping_1.png`, `form_equip_store_1.png`, `shop_tab_1..7.png`, `btn_buy_1.png`, `btn_trade_1.png`).
- [x] 2. Shop Window Implementation (`scripts/ui/shop/shop_window.gd` & scene):
  - [x] 2.1 Create `scripts/ui/shop/shop_window.gd` with modular Control architecture.
  - [x] 2.2 Add authentic background texture and 18x18 close button.
  - [x] 2.3 Implement Mode Tabs ("Buy" and "Sell").
  - [x] 2.4 Implement Buy Tab: Merchant catalog display, unit price, selection preview, quantity SpinBox (1..99), total cost, "Buy" button (gold check, deduction, inventory add, coin audio).
  - [x] 2.5 Implement Sell Tab: Player inventory display, 50% sell price calculation, selection preview, quantity SpinBox, "Sell" button (inventory remove, gold award, coin audio).
  - [x] 2.6 Dynamic gold display updating on transactions and inventory changes.
  - [x] 2.7 Connect `ShopWindow` into `HUD` floating windows / scene hierarchy.
- [x] 3. MapView & Merchant Dialogue Integration:
  - [x] 3.1 Hook merchant NPCs in `scripts/map/map_view.gd` / `scripts/ui/hud/hud_dialogue.gd` / `scripts/map/npc_dialogue_component.gd`.
  - [x] 3.2 Define merchant catalogs (Grocery, Pharmacy, Weapon Smith).
  - [x] 3.3 Trigger ShopWindow open with specific merchant catalog upon selecting "Buy / Sell" / "Trade".
- [x] 4. Headless Automated Testing & Verification:
  - [x] 4.1 Create `tests/test_shop_window_and_merchant_trading.gd`.
  - [x] 4.2 Run test suite with `C:\Godot\godot_console.exe --headless` (59/59 passed).
- [x] 5. Documentation & Reporting:
  - [x] 5.1 Create technical documentation in `docs/merchant_shop_system_specification.md`.
  - [x] 5.2 Update global `readme.md`.
  - [x] 5.3 Report completed actions to caller agent.

# Combat Settings & Auto-Battle Window (FightWindow)
- [x] 6. Skin & Asset Slicing:
  - [x] 6.1 Inspect bitmaps (`BattleStatus_1.bmp`, `Btn_PlayerBattleSetting.bmp`, `Btn_AssignFight_1.bmp`, `Btn_PlayerBattleRestore.bmp`, `Btn_TopPK_1.bmp`, `btn_Check_1.bmp`, `btn_UnCheck_1.bmp`).
  - [x] 6.2 Convert and defringe transparent PNG assets into `assets/hud/` (`form_fight_1.png`, `form_player_battle_setting.png`, `btn_checkbox_checked.png`, `btn_checkbox_unchecked.png`, button slices).
- [x] 7. Fight Window Controller Implementation (`scripts/ui/hud/fight_window.gd`):
  - [x] 7.1 Geometry 153x115 with 18x18 close button at Vector2(123, 8).
  - [x] 7.2 Auto-Battle Toggle CheckBox.
  - [x] 7.3 PK Safety Lock Toggle CheckBox.
  - [x] 7.4 Battle Animation Speed selector (1.0x Normal, 1.5x Fast, 2.0x Hyper).
  - [x] 7.5 Auto-Flee HP Threshold control (0%..30%).
  - [x] 7.6 Integrate into `scenes/ui/hud.tscn` and `scripts/ui/hud/hud_window_manager.gd`.
- [x] 8. BattleManager & BattleView Integration:
  - [x] 8.1 Wire auto-battle state, PK safety, and battle animation speed into `BattleManager` & `BattleView`.
  - [x] 8.2 Implement auto-flee logic when player/companion HP falls below threshold.
  - [x] 8.3 Persist settings in `user://system_settings.json` under `"combat"` key.
- [x] 9. Headless Automated Testing:
  - [x] 9.1 Create `tests/test_fight_window_and_combat_settings.gd`.
  - [x] 9.2 Execute test suite with `C:\Godot\godot_console.exe --headless` (8/8 tests passed, 100%).
- [x] 10. Documentation & Reporting:
  - [x] 10.1 Write `docs/fight_window_and_combat_settings_spec.md`.
  - [x] 10.2 Update `README.md`.
  - [x] 10.3 Send completion message to caller agent.

# Team / Party Window & Companion Management (TeamWindow)
- [x] 11. Skin & Asset Slicing:
  - [x] 11.1 Sliced and defringed `Form_Team_2.bmp` into `assets/hud/form_team_2.png` (371x539).
  - [x] 11.2 Sliced 3-state buttons: `btn_leave_team_*.png`, `btn_dismiss_team_*.png`, `btn_assign_leader_*.png`, `btn_assign_fight_*.png`, `btn_assign_rest_*.png`, `btn_team_tab_*.png`.
  - [x] 11.3 Sliced authentic leader badge `org_leader_badge.png` from `OrgLeader.bmp`.
- [x] 12. Team Window UI Implementation:
  - [x] 12.1 Created `scripts/ui/hud/team_window.gd` & `scenes/ui/hud/team_window.tscn` (371x539, 18x18 close button at (341, 8)).
  - [x] 12.2 Implemented 4 party member cards (Slot 0 leader bust, name, level, element, HP/SP, leader badge; Slots 1..3 empty states, selection highlight, dismissal, leader promotion).
  - [x] 12.3 Implemented 3 companion cards (Slot 4 active + 2 reserves) with portrait apertures, level, element, HP/SP, status badges ("Summoned" / "Resting"), and authentic Fight/Rest buttons.
  - [x] 12.4 Integrated TeamWindow into `scenes/ui/hud.tscn` under `FloatingWindows/TeamWindow` and `scripts/ui/hud/hud_window_manager.gd`.
- [x] 13. MapView & Overland Follower Integration:
  - [x] 13.1 Dynamic overland follower spawning behind player (`_companion_follower`) with smooth trailing and heading alignment.
  - [x] 13.2 Overworld duplicate NPC suppression via `_party_companions` and `NpcStateEvaluator.should_npc_be_visible`.
  - [x] 13.3 Map transition follower re-instantiation in `_switch_map_entities()`.
- [x] 14. Headless Automated Testing & Verification:
  - [x] 14.1 Created `tests/test_team_window_and_companions.gd`.
  - [x] 14.2 Executed test suite with `C:\Godot\godot_console.exe --headless` (92/92 passed, 0 failures, 100%).
- [x] 15. Technical Documentation & Global Updates:
  - [x] 15.1 Created `docs/team_window_and_companion_management_spec.md`.
  - [x] 15.2 Updated root `README.md`.
  - [x] 15.3 Reported completion to caller agent via `send_message`.

# Skill Window Interactive Parity & Hotbar Binding (SkillWindow)
- [x] 16. Asset Slicing & Defringing:
  - [x] 16.1 Inspected bitmaps `Form_Skill_1.bmp`, `Form_Skill_2.bmp`, `SkillIcon.bmp`, `1x1Grid.bmp`, `1x1Grid_2.bmp`.
  - [x] 16.2 Extracted and defringed `form_skill_1.png` (290x459), `form_skill_2.png` (290x459), `btn_skill_icon_1..5.png` (38x63) plus normal, hover, pressed states (38x21), and `slot_grid_1x1.png` (32x32) into `assets/hud/`.
- [x] 17. Skill Window Controller & View Implementation:
  - [x] 17.1 Created `scripts/ui/hud/skill_window.gd` with 290x459 geometry, 18x18 close button at Vector2(260, 8), and `window_closed` signal.
  - [x] 17.2 Created `scripts/ui/hud/skill_row_button.gd` with custom icon, name, SP cost, level/rank, selection feedback, and `_get_drag_data` payload.
  - [x] 17.3 Created standalone scene `scenes/ui/hud/skill_window.tscn` and embedded into `scenes/ui/hud.tscn` under `FloatingWindows/SkillWindow`.
  - [x] 17.4 Implemented 5 category tabs (Earth, Water, Fire, Wind, Special/Physical) with reactive filtering from `GameDatabase.skills` (or fallback).
  - [x] 17.5 Implemented Lower Detail Inspection Card at (24, 308) displaying skill icon, name, element, target type, SP cost, description, and damage formula.
  - [x] 17.6 Implemented 8 quick-bind buttons (F1..F8) for click-to-assign hotbar mapping.
  - [x] 17.7 Wired hotkey toggle ('S') in `scripts/ui/hud/hud_window_manager.gd` and `hud.gd`.
- [x] 18. Hotbar Integration & Skill Activation:
  - [x] 18.1 Extended `scripts/ui/hud/hud_hotbar.gd` with `bind_skill`, `get_slot_data`, `can_drop_on_slot`, and `drop_on_slot`.
  - [x] 18.2 Extended `scripts/ui/hud.gd` with `use_skill(skill_id)`: validates player SP, deducts SP on success, synchronizes `character_status_ctrl` and player status dock, sends chat message, and displays center toast notifications with sound.
- [x] 19. Headless Automated Testing & Verification:
  - [x] 19.1 Created comprehensive test suite `tests/test_skill_window_and_hotbar.gd` covering geometry, tabs, filtering, row data, dragging, hotbar binding, SP deduction, and close button interaction.
  - [x] 19.2 Executed test suite via `godot_console.exe --headless` (76/76 passed, 0 failures, 100%).
  - [x] 19.3 Executed floating window regression test `tests/test_floating_windows_and_system_settings.gd` (139/139 passed, 0 failures, 100%).
- [x] 20. Technical Documentation & Global Updates:
  - [x] 20.1 Created `docs/skill_window_interactive_parity_and_hotbar_binding_spec.md`.
  - [x] 20.2 Updated global `readme.md`.
  - [x] 20.3 Sent completion message to caller agent `bb1ca306-20ed-4c6b-b716-8db2b0f6fa52`.

# Audit 2026-10-28 (full headless run of tests/test_*.gd)
- [x] Loading screen from aLogin.exe decode (`tests/test_loading_screen.gd`, 23/23).
- [x] `test_friends_window_and_whisper`: shared on-disk state made the list 4 instead of 5; the test now resets it.
- [x] ChatDock channel-tab offset and whisper input positions: tests aligned with the code (-21 px / 74 / 163).
- [x] `test_inspect_stretch`: aligned with the real stretch settings; no longer hangs.
- [x] Editor tests run through `tests/run_node_test.gd` / `tools/run_all_tests.sh` (`test_item_editor`, `test_quest_editor`, `test_skill_editor`, `test_audio_editor`, `test_battle_editor`, `test_cutscene_editor`, `test_all_world_tools`, `test_battle_view_scene`) do not extend SceneTree, so they cannot run with `--script`; they need a scene-based runner.
- [x] Compare aLogin screens (server select, login, character select/create) against original screenshots and rebuild from decoded DFM/skin data (done by the items below: select layout fixes, server/login review, create wizard rebuild).
- [x] Character select layout fixes (title banner, stray arrows, sprite and EXP bar placement; `tests/test_character_select_layout.gd`, 19/19).
- [x] Server select and login screens reviewed: layout matches their skins (no defects found by screenshot).
- [x] Optional: 'Loading' state on the character select cards (seen in the reference video before character data arrives; implemented in `character_select.gd` and verified).
- [x] Character create wizard rebuilt on the matching skins (`tests/test_character_create_layout.gd`, 30/30).
- [x] Admin tools first pass: Battle Studio toolbar wraps (was cut off at 1280 px). Still open there: Skill Studio side columns scroll horizontally.
- [x] LAST (requested by the user): admin tools: all 13 studio/editor suites run through `tools/run_all_tests.sh` (full run 117/117 ok, 2026-10-30); Skill Studio columns fit at 1280x720 (left column fixed 320 px, no horizontal scroll, `_test_columns_fit_1280`); formula breakdown showed a literal "%%".
- [x] HUD windows realigned to their baked skins: System, Friends, Skill (new categories), Shop (Buy/Trade toggles), Combat settings (light frame). See README "HUD Windows Realigned".
- [x] Apply System window options/colours: chat channel colours into the chat renderer (two chat implementations: `hud_chat.gd` and `chat_dock.gd`), PVP/PK and trading flags into gameplay.
- [x] Quest ("mission") and Team ("group") windows: verify against their skins (text slightly clipped in the quest window resolved with TitleLabel ellipsis and HP/SP bar repositioning).
- [x] Skill window: no proficiency / weapon requirement data yet (shows "-" / "Any"); learned-skills model instead of listing all element skills.
- [x] Character select: "Loading" state while character data arrives (implemented `set_loading(bool)`, `is_loading`, centered loading overlay with disabled button controls; verified in `tests/test_character_select_layout.gd`).
- [x] Close buttons over the baked x sphere, cursor mapping, chat colours, compound window, sinking cutscene visuals, battle sprites/buttons/gauge, encounters and battle-to-world flow (see README).
- [x] Battle: real battle backgrounds by environment/bg_id (Forest, Beach, Cave, Deck), 20-30s centered cyan digital countdown timer with warning red color below 5s, configurable turn limit in BattleManager.
- [x] Battle: 2-phase player-to-pet command radial ring handoff, permission gating (Catch/Item disabled for pet), dynamic combat camera attack zoom, and caster lunges.
- [x] Level / EXP curve decoded from aLogin.exe (0x388628 / 0x388748 / 0x3886fc): step n -> n+1 costs Round((n+1)^A + B), A = double at Formula.dat 0xF1 (3.1), B = int32 at 0x169 (5); reborn uses 3.3 / 50 (and (L-150)^4.9 above 150); cap 199 (190 reborn). Matches the C# server; the 30/70/130/210 table in the WLRI docs is wrong (real: 14, 35, 79, 152). `scripts/database/formula_data.gd`, `tests/test_exp_curve.gd` (30/30). Confirmed by Gemini (round half to even, 4.9).
  - `add_experience` now levels up on that curve (battle and quest EXP go through it); the EXP bar percent bug (0..1 passed as 0..100) is fixed.
- [x] Combat stats decoded from aLogin.exe (stat getter 0x430580, ids 41..45 = ATK/DEF/MATK/MDEF/SPD): Round(attr*c0 + L*c1 + equip*c2 + L*elem*c3) + Round(base*0.1 for the stat's job), coefficients from Formula.dat (0x01/0x21/0x41/0x61/0x81), element bonus Fire->ATK/MATK, Earth->DEF/MDEF, Wind->SPD, rounding half up (0x1297d8), L = level + 100*reborn. Used by the character window and the battle actor (`FormulaData.combat_stat`, `tests/test_stat_formulas.gd`).
  - Max HP/SP (ids 205/206) are only stored by the client; growth now follows the C# server's MaxHp/MaxSp formula (level up and CON/WIS points).
- [x] Stat points per level: 3 (both C# server paths, SetLevel and AddExp). Job byte 0x1f9c = reborn job (RebornJob 1 Killer..6 Seer), matching the client's +10% stat per job. Flag 0x20a5 = active pet slot (written at 0x292179, action 0x0F/0x0B); its per-stat bonus is server data (`FormulaData.combat_stat` pet_bonus).
- [x] Items: audit against the real client binary (`docs/re/item_window_and_tooltip.md`, `tests/test_item_audit.gd` 35/35): Item.dat fields (rank, LV req, prices, flags, footprint, time limit, uses), status names (211 = DEF, was ATK), type and slot names, tooltip line order/colours/size/placement (builder 0x2a2058), stack limit 50.
- [x] Bag layout: gerçek client yakalaması (`docs/reference/real_client/inventory_real.png`) 5x10 = 50 hücre gösteriyor. Godot `hud_inventory.gd` 50 slota çıkarıldı (`test_item_audit` 35/35, `test_character_item_window_navigation` geçti). Çok hücreli item yerleşimi (footprint) henüz yok.
- [x] Item editor slot names now match the client (Head, Body, Weapon, Hands, Shoes, Special Eq).
- [x] "UI missing elements": the real client has 165 windows (`Form_*` in aLogin.exe), 15 exist in Godot. Prioritised list in `docs/ui_coverage.md`.
- [ ] P1 windows (`docs/ui_coverage.md`). Already present: pet status, trade, warehouse, repair, world map, GPS, potential, titles, mail, channel, emotes, drop/pick up, inn, rewards, battle skill picker.
  - [ ] P1-a Form_Huminfo (other player's info): BLOKLU. Orijinal belge ve düzen yakalaması yok; oyunda başka bir oyuncuya sağ tıklayıp pencereyi yakalamak gerekiyor (kullanıcı).
  - [x] P1-b Kelan Props Shop (gerçek client yakalaması 2026-10-30, `docs/reference/real_client/shop_buy_real.png`): 5 item (Bread, Rice Wine, Ordinary Wood, Lauan, Copper Ore). İsim, ikon, açıklama ve fiyat Item.dat'tan okunuyor (`tests/test_props_shop_catalog.gd` 3/3). Açık: Lauan fiyatı mağazada 30, Item.dat'ta 45003 için 50; hangisinin doğru olduğu sorusu var. Diğer mağaza türleri (Armory, Shopping/Buy/ShoppingCar) için ayrı yakalama gerekiyor.
  - [x] P1-c Form_Medical (doktor): Eve opcode 7 (d1 6/7) onay sorar, evet denince oyuncu HP/SP tam dolar (`tests/test_clinic_rest.gd` 5/5). Açık noktalar: pet iyileştirmesi yok, onay metni orijinal değil.
  - [ ] P1-d Form_SkillTree: gerçek client yakalaması yapıldı (`docs/reference/real_client/skill_real.png`). Oyundaki Skill penceresi sekmeli bir yetenek listesi (Physical/Magical/Assistant/Life/Intro, sp maliyeti, alt bilgi paneli); ağaç görünümü yok. Godot'taki `skill_window` yapısı buna yakın, piksel düzeni karşılaştırılmadı.
- [x] Cursors: verify the inferred roles (cursor1 normal, cursor3 attack, cursor4 talk, cursor8 harvest, cursor17 examine, cursor6 portal, cursor12 mining, cursor18 shop, cursor15 skill, cursor16 quest, cursor10 busy, cursor11 target; verified all 12 types, animation and hotspots in `tests/test_cursor_manager.gd`).
- [x] Top-right action bar added after comparing with the running real client.
- [ ] Real client comparison still open: ask the user to open the inventory, a shop, the skill window and a battle in the real game, then capture each with `PrintWindow` (see README) and compare layouts.
- [x] Item use: consumables restore HP/SP from Item.dat status types 25/26 and show a stat tooltip (`tests/test_consumable_item_recovery.gd`, 35/35). Verified 2026-10-29; the earlier 'not decoded' note was stale.

## Real-client fidelity (2026-10-28)
- [x] Decode the dispatcher handlers (`docs/re/dispatch_table.md`): implemented Action 0x02 (Item Pickup/Entity Update), Action 0x05 (NPC Dialogue/Portal), Action 0x07 (Map Warp), Action 0x19/0x1B (Trade/Shop), and Action 0x32/0x33 (Battle Command/Stat Sync) with signals in `network_manager.gd`, verified in `tests/test_network.gd`.
- [ ] Quest, shop, status, battle and chat windows: capture the real ones with `tools/game_input.ps1` and compare (battle needs a fight started by the user).
- [x] Compound window: big cauldron picture in the base slot, items listed in the grid.
- [x] Item window: header arrows and shoe arrows switch pages / equipment views (implemented `TitlePrev`/`TitleNext` inventory page switching and `ShoesPrev`/`ShoesNext` riding shoes toggle, verified in `tests/test_character_item_window_navigation.gd`).
- [ ] Group window Instance tab content, pet Battle/Dismiss semantics against the real client.
- [x] Verify the remaining code->text mappings of action 0x01 sub codes (6, 7, 0x0C) (reverse-engineered and verified from `AC63.cs`: Sub 6 bad username/password, Sub 7 banned/timed out, Sub 0x0C login error; documented in `docs/action_01_subcode_spec.md`).
- [x] Battle: pet command step in the ring, attack camera zoom/step-forward animation, hover info card, forest/beach/cave/deck backdrops by map (`tests/test_battle_round_timer_and_backdrop_parity.gd`).
- [x] Decode battle packets (`32 01` command, `33 01` stat updates, `32 xx` round events) and compare with `battle_manager.gd` (wired Action 0x32 and 0x33 into `battle_packet_received` in `network_manager.gd`, verified in `test_network.gd`).
- [x] Quest 'Hill Pepper' (Doll/Emilie) as a real quest chain in Godot: quiz choices (tens 2 / units 9), hand-in, Radio Set reward, centered reward banner ("Obtain 1 pcs Radio Set") and fanfare audio (`tests/test_hill_pepper_quest_chain.gd`).

## Global Gemini MCP Server Setup for Claude
- [x] 1. Extract and validate Google API keys from `C:\Users\muham\Desktop\google api.txt`
- [x] 2. Update `gemini_mcp.py` dependency pinning (`mcp>=1.2,<2`) and set active default model (`gemini-3.1-flash-lite`)
- [x] 3. Deploy script to permanent tools location `C:\Users\muham\tools\gemini-mcp\gemini_mcp.py` and sync with Desktop
- [x] 4. Register Gemini MCP in Claude Code globally (`user` scope) with multi-account environment variables
- [x] 5. Configure Claude Desktop (`%APPDATA%\Claude\claude_desktop_config.json`) with identical MCP configuration
- [x] 6. Verify server health, tools connectivity (`list_accounts`, `ask_gemini`, `list_models`) via Claude CLI
- [x] 7. Create technical documentation in `docs/gemini_mcp_setup.md` and report results

## Real Game vs Godot Client Fidelity & Discrepancy Audit (Tek Tek Eksik Analizi)
- [x] 1. Audit HUD, Navigation & Screen Overlays: Compare status dock, top action bar (10 icons), system ticker, chat dock behavior (transparent floating log vs focus frame, face icons, drag resize, channel buttons), auto-heal '+' button, and minimap placement against real game captures.
- [x] 2. Audit VCL Floating Windows: Compare Item/Inventory (header arrows, paperdoll shoes toggle, stats, potential), Compound (cauldron graphic, 5 ingredients layout), Skill (tabs, learned skills filter, weapon/proficiency reqs), Group/Team (top pet roster vs bottom party teammates), Social/Friends (mail/delete/pager/tabs), System (toggles hookup), and Shop (5 fixed rows, 10 purchase slots, no spinbox) against real game.
- [x] 3. Audit Battle System: Compare combat presentation (fullscreen environmental backdrops vs frozen map crop, free standing vs grid, thin red HP line under names, 20s center countdown number, 7-icon radial command ring, 2-phase player+pet turn order, attack camera zoom & lunges, enemy collapse) with `battle.md` and real captures.
- [x] 4. Audit Dialogue, Cutscene & Quest System: Compare NPC dialogue positioning (top centered for NPC with portrait/hand vs bottom for player with full body standee), choices layout, quest completion reward banners, notebook/monster book/star book, and NPC interaction distance gating.
- [x] 5. Audit Network Protocol & Dispatch Table: Compare Godot network handlers with the ~91 Delphi dispatch table actions (`dispatch_table.md`), live packet captures (battle `32 01`, stat sync `33 01`, keepalive `ba 09`), and missing server packet handling.
- [x] 6. Audit Core Gameplay Mechanics & Data: Compare Formula.dat multipliers with current hardcoded combat formulas, consumable item status recovery in Item.dat, and leveling/stat allocation rules.
- [x] 7. Compile Technical Documentation & Detailed Discrepancy Matrix: Write comprehensive itemized gap analysis in `docs/real_game_fidelity_gap_analysis.md`, update root `README.md`, and report all findings.

## Chat Background Cleanup & Input Bar Image Removal (Chat Arkaplan Temizliği)
- [x] 1. Remove Chat Input Bar Background Image: Removed `chat_input_bg.png` from `ChatInputBackground` to prevent baked screenshot text ("channel") and ghost button graphics from showing under live Godot controls.
- [x] 2. Procedural Gold Frame & Dark Input Styling: Styled `ChatInput` with clean dark slate background (`Color(0.04, 0.06, 0.09, 0.90)`) and authentic 1px gold border (`Color(0.70, 0.58, 0.35, 0.85)`).
- [x] 3. Authentic Transparent Overworld Floating: Kept `ChatHistoryPanel` transparent in normal overworld exploration matching real WLO client behavior; subtle highlight frame only while typing.
- [x] 4. Sender Character Avatar Icons Preserved: Maintained authentic role avatar portraits (`avatar_role_N_0.png`) on player chat lines while keeping system messages clean.
- [x] 5. Headless Automated Verification: Tested `test_hud_chat_and_status_features.gd` (100% OK, 0 errors), `test_hud_dock_system.gd`, and combat test suites.
- [x] 6. Documentation & Readme Update: Updated `docs/chat_visual_cleanup_specification.md` and root `README.md`.




## Oturum 2026-10-30 (tek oyunculu, kaptan, sandıklar)
- [x] Başlık ekranı: TEK OYUNCU / ÇOK OYUNCU / Çıkış (`scripts/ui/title/title_screen.gd`, ana sahne).
- [x] Tek oyunculu kayıt slotları (5 slot: yeni oyun, devam, sil) `scripts/core/save_game.gd`, `scripts/ui/title/single_player_slots.gd`; `tests/test_single_player_slots.gd` 26/26.
- [x] Oyun içi durum kaydı (envanter, ekipman, gold, EXP, görevler, görev adımları, harita, konum): `tests/test_single_player_state.gd` 10/10.
- [x] Kaptan: konuşmadan sonra donma düzeltildi (`_release_movement_if_free`); Kelang konuşması kaldırıldı; Robinson oyuncuyu sudan çekiyor (`_robinson_pull_out`); `tests/test_captain_rescue.gd` 4/4.
- [x] Ada sandıkları Eve ödüllerini veriyor (elle yazılmış tablo sadece Eve olayı olmayan sandıklarda). `tests/test_island_chest_eve_loot.gd` 4/4.
- [x] Fırtına/kurtarma orijinal CG'si: karar — oyunda oynatılabilir CG dosyası yok (sahne video olarak kaydedilmiş). Kod ile yeniden üretim (`sinking_cutscene.gd`) kabul edildi. `.sty` formatı çözülmedi, görevlerle bağlantı bulunamadı; ileride gerçek bir CG dosyası bulunursa bu madde yeniden açılır.
- [x] Robinson'un çekme sahnesi: captain sprite'ı + oyuncu sürüklemesi (`_robinson_pull_out`, `tests/test_captain_rescue.gd` 4/4). Orijinal kare dizisi yok, kabul edildi.
- [ ] Yetenek penceresinin son satırı sohbet kutusunun altında kalıyor (layout bulgusu, test uyarı olarak işaretli).
- [x] Eve gemi-enkazı geçişi (10014–10018 → 10035): transition 1 batmayı başlatıyor, 10035'e iniyor (`tests/test_shipwreck_transition.gd` 4/4).
- [x] Eve pet sayısı koşulu (tür 2, w1==5: 4 eksik pet): `tests/test_npc_event_script.gd` 26/26.
- [x] Eve companion takibi (tür 2, w1==6): aktif companion haritadan okunuyor (`active_companion`), `tests/test_npc_event_script.gd` 29/29.
- [x] Fırtına/kurtarma CG'si (kapandı, yukarıdaki karar): oyunda ayrı bir CG dosyası yok. Orijinal sahne video olarak kaydedilmiş (`docs/video_analysis_sinking_event_seconds_176_240.md`): sarsıntı, kırmızı uyarı, siren, kararma. Bunların hepsi `sinking_cutscene.gd` içinde kodla yeniden üretilmiş. `.sty` dosyaları bu sahneye bağlanamadı.
- [x] EXP eğrisi: `aLogin.exe` + `Formula.dat`'tan çözüldü (commit 7b46d13, `scripts/database/formula_data.gd`, `tests/test_exp_curve.gd` 30/30). Seviye n→n+1 = round((n+1)^3.1 + 5), sunucuyla aynı. Spec'teki 30/70/130/210 tablosu yanlış (AI tarafından yazılmış, mock testli).

## Gerçek client yakalamaları (2026-10-30, `docs/reference/real_client/`)
- [ ] Props Shop satış penceresi (`props_shop_sell_real.png`): "Select props to sell" başlığı, çanta ile aynı 5×10 ikon ızgarası, altında "selling amount" ve "money held", Confirm/Close. Godot satış sekmesi liste satırları kullanıyor; ızgaraya çevrilmeli.
- [ ] Item tooltip (ızgarada üzerine gelince): ad, "Non-tradeable" gibi durum, etki (örn. Hp +100), tür (prop), rank ve açıklama. Godot tooltip biçimi karşılaştırılmadı.
- [x] Lauan fiyatı: satış ve alım fiyatları farklı; mağaza alım fiyatı 30 (`SHOP_BUY_PRICE_OVERRIDE`), Item.dat 50 item değeri olarak kalıyor. Kullanıcı kararıyla kapandı.
- [ ] Satış penceresi ayrı bir panel olmalı (gerçek: "Select props to sell", ızgara ortada, altında "selling amount" ve "money held", Confirm/Close). Şu an sell modu buy düzenini kullanıyor; ızgara sol üstte liste satırlarının üstüne biniyor (`godot_shop_sell_grid.png`). Yakalama aracı: `scripts/tools/capture_shop_sell_grid.gd`.
- [x] Sat paneli: başlık "Select props to sell", 5×10 ızgara (33,63), "selling amount"/"money held" alanları, Confirm/Close, gerçek ölçümlerle (`build_sell_panel`). Sat modunda alım parçaları gizleniyor, alıma dönünce geri açılıyor. Test: `test_sell_grid_build` 10/10, mağaza 54/54.
- [x] Sat paneli arka planı: ORİJİNAL skin bulundu, `menu/Skins/white/Form_SaleThing_1.bmp` ("Select props to sell", 5x10 ızgara, selling amount, money held); `assets/ui/shop/form_sale_thing_1.png` olarak eklendi. Eşi `Form_SaleEquip_1.bmp` ("Select equipments to sell"). Yakalama: `godot_shop_sell_panel_v3.png`. Eski not: WLRI'de `sell`/`props` adlı skin yok (tüm `menu/Skins` ve `pic` tarandı). Mağaza skin'leri şunlar: `white/Form_ThingStore_1.bmp` (Miscellaneous, alım), `white/Form_EquipStore_1.bmp` (Weapon store, alım). Gerçek sat penceresi altın köşeli, açık mavi bir çerçeve kullanıyor; bu çerçeve mağaza formuna benziyor. Öneri: mağaza çerçevesinin köşe parçalarını ve iç rengini kullanıp iç tablo çizgilerini kaldırmak (gerçek sat penceresi boş ızgara kullanıyor). Henüz yapılmadı.
- [x] Tooltip biçimi: `scripts/ui/item_tooltip.gd` aLogin.exe çözümünden kurulu; satır sırası ve renk gerçek yakalamayla (Chocolate) uyuşuyor. Piksel genişliği ölçülmedi.
- [x] Sepet penceresi (`scripts/ui/shop/shopping_cart_window.gd`, orijinal `form_shoppingcar_1.png` arka planı, 7 satır, Total, Continue/Checkout/Leave; `tests/test_shopping_cart_window.gd` 5/5). Henüz mağazadan açılmıyor; sepet mantığı (ekleme, toplam, satın alma) yok. Eski not: assetler `assets/ui/shop/` altında. `form_shopping_1.png` ve `form_shopping_2.png` Çince puan (mall) penceresi ("目前點數", "紅利點數"), `form_shoppingcar_1.png` alışveriş sepeti (Name / Effect / Price / Amount, Total, "繼續購買 / 確定結帳 / 離開商城"). Sepet penceresi için ayrı bir pencere gerekiyor; henüz bağlanmadı.
- [ ] Armory: `Form_WeaponStore_1` / `Form_EquipStore_1` zaten `assets/hud` altında mağaza arka planı olarak kullanılıyor; Armory'ye özel bir skin tespit edilmedi.
- [x] Sepet satın alma: `ShopWindow.buy_cart` sepet satırlarını mevcut satın alma yoluyla alır (`tests/test_cart_checkout.gd` 3/3, altın 500 → 420). Sepet mağazadan açılmıyor (tetikleyici gerçek client'ta yakalanmadı).
- [x] Sepet mağaza penceresinde: `add_to_cart`, `show_cart`, `hide_cart` (`tests/test_cart_checkout.gd` 10/10, toplam 80). Açma tetikleyicisi (gerçek client'ta hangi tuşla/akışla açıldığı) henüz yakalanmadı; şu an kod çağrısıyla açılıyor.

