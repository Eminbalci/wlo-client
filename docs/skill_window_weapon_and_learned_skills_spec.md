# Wonderland Online - Skill Window Weapon Requirements, Proficiency & Learned Skills Specification

## 1. Overview
This specification details the authentic decoded skill requirements and player progression model in `SkillWindow` (`scripts/ui/hud/skill_window.gd`) and `SkillDatabase` (`scripts/database/skill_database.gd`), achieving full parity with the Delphi binary (`Skill.dat` and `SkillData.MBTM`).

Prior to this update, the detail card at (24, 337) displayed static placeholders `"-"` for proficiency and `"Any"` for weapon requirements across all skills, and the list listed all 953 database skills for the active element regardless of player character level or unlock state.

---

## 2. Decoded Binary Weapon Requirements & Proficiency

### 2.1 Weapon Requirements in `Skill.dat`
In `Skill.dat` (148-byte records), offset `27..28` encodes the combat mechanism and weapon class:
- **`0` (Basic / Any / Barehanded):** Hand Attack, Palm, Fist, Kick, Item Usage, Flee, Defense.
- **`1` (Melee / Slashing / Piercing):** Sword, Blade, Spear, Lance, Hammer, Axe.
- **`2` (Magic / Casting):** Staff, Wand, Magic spells.
- **`3` (Ranged / Projectile):** Bow, Arrow, Gun, Bazooka.
- **`4` (Life Tools):** Pickaxe, Axe, Fishing Rod, Saw.

In `SkillRecord`:
- `weapon_requirement: String` ("Sword", "Staff", "Bow", "Gun", "Spear", "Hammer", "Barehanded", "Any").
- `weapon_requirement_type: int` (0: Any, 1: Sword/Blade/Spear, 2: Staff/Wand, 3: Bow/Gun, 4: Tool, 5: Barehanded).

### 2.2 Proficiency / Grade Requirements
In `Skill.dat`, offset `30` encodes skill rank / grade (1..10):
- `proficiency_required = maxi(1, rank)`
- Displayed in `detail_proficiency_label` as `"Grade %d"` (e.g. `"Grade 1"`, `"Grade 2"`).

---

## 3. Learned Skills Progression Model

### 3.1 Default Starter Skills (`init_default_learned_skills`)
A player character begins exploration with:
1. **Universal Actions:** Hand Attack (`10001`), Defense (`60021`), Flee (`60041`).
2. **Role Starter Stunt:** Derived from `SkillDatabase.STARTER_SKILLS` (e.g. Daniel `15038` Overarm Stumble, Nina `15039` Wine Flame, Betty `12036` Leap, Rocco `11075` Summon Dogs, Vanessa `15042` Recover, etc.).
3. **Starter Element Spells:**
   - **Earth (1):** Rock Attack (`11001`).
   - **Water (2):** Water Bullet (`12001`), Recover (`15042`).
   - **Fire (3):** Fire Ball (`13001`), Fiery Attack (`13002`).
   - **Wind (4):** Wind Blade (`14001`).
4. **Life Skills:** Collection (`10021`), Cutting (`10022`), Mining (`10023`).

### 3.2 Filtering & Dynamic Learning
- `is_skill_learned(skill_id: int) -> bool`: Checks if character has unlocked skill.
- `learn_skill(skill_id: int) -> void`: Adds skill ID to character's learned set and triggers UI refresh.
- `unlearn_skill(skill_id: int) -> void`: Removes skill ID from character's learned set.
- `set_learned_skills_only(enabled: bool) -> void`: Toggles between learned-skills view and full database inspection view.
- `get_learned_skill_ids() -> Array[int]`: Exports active skill IDs for persistence in `user://characters.json`.

---

## 4. Verification & Automated Tests
- `tests/test_skill_window_weapon_and_learned_skills.gd`:
  - `_test_database_weapon_and_proficiency_decoding()`: Verifies Sword, Bow, Staff, and Barehanded decoding from `Skill.dat`.
  - `_test_skill_window_detail_weapon_and_proficiency_display()`: Verifies detail panel labels update dynamically to `"Grade 1"` / `"Grade 2"` and `"Sword"` / `"Bow"`.
  - `_test_learned_skills_model_and_filtering()`: Verifies default learned skills, dynamic learning/unlearning, and `learned_skills_only` list filtering.
- 100% zero-error pass rate across all test suites.
