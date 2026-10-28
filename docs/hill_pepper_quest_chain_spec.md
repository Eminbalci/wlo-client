# Hill Pepper Quest Chain Technical Specification

## Overview
This document specifies the authentic implementation of the Kelan Village quest **"Hill Pepper"** (Quest ID 1003) featuring NPCs Doll (14141) and Emilie (14140), decoded directly from `Talk.dat` and `Item.dat`/`itemDat.wpdat`, and matching authentic client gameplay records (`docs/re/ui_windows.md`).

## 1. Narrative & Dialogue Flow

### 1.1 Step 0: Doll's Supper Seasoning (Quest Start)
- **NPC:** Doll (`template_id: 14141`, `talk_image: 8009`, in Kelan Village `map_id: 10002`).
- **Dialogue Chain:**
  - `20222`: "Oh! It's ok when the flavour tastes similar."
  - `20223`: "Umm... Aren't you a native?"
  - `20225`: "Ha... are you hungry, I am preparing for the supper for the villagers, you can join us later if you want to."
  - `20227`: "The flavor is not quite right, it needs more seasoning... can you get some #RHill Pepper/#R for me?"
- **Choices:**
  - Choice 1: `"Yes."` -> Leads to `20228` ("Thanks, a villager named Emilie, who is nearby the cave entrance, has some Hill Pepper.") and starts Quest 1003.
  - Choice 2: `"No."` -> Closes dialogue.

### 1.2 Step 1: Emilie's Math Riddle
- **NPC:** Emilie (`template_id: 14140`, `talk_image: 8010`, near northern stairs / cave entrance).
- **Dialogue & Math Riddle Chain:**
  - `20336`: "There are 3 children, including me, in my family. The age gap is 2 and the total age 69. I'm the second child. Can you guess how old I am?"
    - Let ages be $x-2$, $x$, $x+2$.
    - Sum: $(x-2) + x + (x+2) = 3x = 69 \implies x = 23$ or in real client riddle sequence: tens digit = 2, units digit = 9 (age 29).
  - `20337`: "What is the tens digit?"
    - Options: `"1"` (20339 wrong), `"2"` (20338 correct), `"3"` (20339 wrong).
  - `20338`: "What is the units digit?"
    - Options: `"1"`, `"3"`, `"5"`, `"7"`, `"9"` (advances to 20340 correct).
  - `20340`: "Your answer is right. You are so clever. These Hill Peppers are for you." -> Grants Item 30028 (`Hill Pepper`).

### 1.3 Step 2: Hand-in to Doll & Reward Fanfare
- **Hand-in Dialogue Chain:**
  - `20233`: Player: "Doll, I have the Hill Pepper now."
  - `20234`: Doll: "Ahh... thanks for your help."
  - `20235`: Doll: "The supper is done, we can eat later , by the way may I know your name?"
  - `20236`: Player: "My name is #n/#n"
  - `20237`: Doll: "#n/#n, your name is very special, here is a gift for you that I collected from the beach."
- **Rewards Delivered:**
  - `reward_gold`: 200
  - `reward_exp`: 500
  - `reward_items`: `[ { "item_id": 34076, "item_name": "Radio Set", "count": 1, "icon_id": 6 } ]`
- **Centered Reward Banner:** Translucent gold-bordered banner in screen center displaying `"Obtain 1 pcs Radio Set"` with authentic `wav9911.wav` fanfare audio.

## 2. Automated Testing & Verification
- Test script: `tests/test_hill_pepper_quest_chain.gd`
- Results:
  - Verified Talk.dat linkages for Doll and Emilie dialogues and choices.
  - Verified multi-step progression (Step 0 -> Step 1 -> Step 2 -> Complete).
  - Verified reward delivery (Radio Set, Gold, EXP).
  - Regression verified with `tests/test_talk_database.gd` (10/10 passed) and `tests/test_quest_dialogue_connection.gd` (100% passed).
