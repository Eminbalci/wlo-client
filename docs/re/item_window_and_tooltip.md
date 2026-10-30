# Item tooltip, Item.dat fields and inventory rules (aLogin.exe)

Recovered by disassembling `D:/GitHub/WLRI/aLogin.exe` (Delphi, image base 0x10000) with capstone.
All addresses are VAs. "o+X" is an offset into the in-memory item table entry
(`[0x4c94f8]` object, entry `i` at `obj + i*0x1C3`), and the file record offset is `rec = o - 4`.
Statements are verified in the disassembly or the data unless marked **guess**.

## 1. Item.dat record (0x1C3 = 451 bytes)

Loader 0x3e77c8 reads `\Data\Item.Dat` whole into `obj+4`; count goes to `obj+0x370F88`;
id -> index map is the word array at 0x794af8 (lookup 0x3e77bc). Decoder 0x3e7e40 reverses the
name (rec 1..14) and description (rec 0x93..0x190) in place and decodes each numeric field:
byte `(b ^ 0x9A) - 9`, word `(w ^ 0xEFC3) - 9`, dword `(d ^ 0x0B80F4B4) - 9`.

| rec | o | size | meaning (how we know) |
|---|---|---|---|
| 0x00 | 0x04 | str[14] | name (tooltip title) |
| 0x0F | 0x13 | byte | item type -> "Type: " name via 0x49f674 (table below) |
| 0x10 | 0x14 | word | item id |
| 0x12 | 0x16 | word | small icon |
| 0x14..0x1C | 0x18..0x20 | word x5 | large icon / model ids (not used by the tooltip) |
| 0x1E, 0x20 | 0x22, 0x24 | word x2 | status codes 1 and 2 |
| 0x24, 0x28 | 0x28, 0x2C | dword x2 | status values (+100 bias: shown value = v - 100) |
| 0x2D | 0x31 | byte | **rank** (printed as "Rank: N", 0x2a2fd0) |
| 0x2E | 0x32 | byte | equip_pos (1..6 = equipment, 0x3e92a4) |
| 0x2F | 0x33 | byte | sub-kind used by special cases (0x71, 0x72, 0x77, 0x8E, 0x95, 0x97 ...) |
| 0x71 | 0x75 | byte | **level requirement** ("LV Req: ", clamped to 199 for kind 0x72) |
| 0x72 | 0x76 | dword | buy price (read by the NPC store code near "Not enough Gold", 0x383ad5) |
| 0x76 | 0x7A | dword | sell price (Form_SaleEquip/Form_SaleThing total = sum(price x qty), 0x386c74) |
| 0x7A | 0x7E | byte | job restriction class for the "equipped" panel (switch 0x1c5f43, 14 cases) - **meaning partly guess** |
| 0x7B | 0x7F | word | flags: 0x02 = non-tradeable (0x2a6cec), 0x08 = "Can't craft" vs "Can't compound" (0x2a2da1), 0x40 checked by 0x1c63c3 |
| 0x81 | 0x85 | byte | set id (5 equipped pieces with the same id -> set bonus flag, 0x2a218c) |
| 0x88..0x90 | 0x8C..0x94 | word x5 | alchemy materials (names via 0x49f998) |
| 0x92 | 0x96 | str[254] | description |
| 0x196, 0x197 | 0x19A, 0x19B | byte x2 | bag footprint width/height in cells (0x10f8ec; default 1x1) |
| 0x19D | 0x1A1 | word | job/char restriction id compared with the character (0x1c6004) - **guess** |
| 0x1A5 | 0x1A9 | word | time limit in hours ("Time: ", 0x2a3a35) |
| 0x1A7 | 0x1AB | word | max uses ("Uses: ", 0x2a3bab) |

Other decoded fields (0x30.. 0x6C dword blocks, 0x195..0x1A8 bytes, 0x1AF..0x1BF) are not used by
the tooltip and remain unidentified.

### Status codes (switch at 0x2a28c0, strings 0x2a4a20..0x2a4abc)

25 Hp, 26 Sp, 36 EXP, 64 Amity, 100 Shoot RES, 207 MaxHp, 208 MaxSp, 210 ATK, 211 DEF,
214 SPD, 215 MATK, 216 MDEF. 250 is never printed. Any other code prints the value without a name.
(The Godot code previously mapped 211 to ATK and 212 to DEF - wrong; Copper Knife is 210/211 = ATK +2 / DEF +2.)

### Item type names (0x49f674, jump table 0x49f695, 26 entries)

1 Saber, 2 Sword, 3 Halberd, 4 Bow, 5 Wand, 6 Claw, 7 Knuckle, 8 Axe, 9 Club, 10 Exotic, 11 Hammer,
12 Body, 13 Head, 14 Hands, 15 Shoes, 16 Special Eq, 21 Quest Item, 25 Spec Prop, everything else "Prop".
The Delphi strings carry trailing blanks ("Saber    "), length-prefixed 4 for "Prop".

### equip_pos in the data (type x pos tabulation of Item.dat)

| pos | item types found | meaning |
|---|---|---|
| 1 | 13 | Head |
| 2 | 12 | Body |
| 3 | 1..11 | Weapon |
| 4 | 14 | Hands (gloves/bracers) |
| 5 | 15 | Shoes |
| 6 | 16 (+ a few 12/13/25) | Special Eq (costumes, masks) |
| 7 | 25, 39 ... | maps/tokens/vehicles - **not** equipment (0x3e92a4 accepts 1..6 only) |
| 8 | 20..41 | usable/consumable props |
| 9, 10 | 25 | containers (Token Egg, Packing Box, Memory Card) |

The character keeps equipped items at `[char + 0x64 + pos*4]` for pos 1..6 (0x1c63fc), i.e. the slot
index is the equip_pos itself. The status window's six equip image controls are `[[0x4c9170] + 0x1C0 + i*4]`, i = 1..6.

## 2. Main item tooltip - 0x2a2058

Callers: 0x14e4da, 0x2633cf, 0x480fb3 (item-image hover). A sibling 0x2a4e5c (caller 0x40c2b9) builds
the same lines for another control type (store/list rows). After building, both call 0x1c5df4, which
builds a second panel for the item currently equipped in the same slot ("[ Equipped ]" at 0x1c5c64).

`self+0x130` is a TStringList; each line is `Add`ed (vtable +0x34). Ten section flags are decided first
(switch at 0x2a229c):

1. stat lines - unless 0x3ec1f8 != 0 (kind 0x97 potion with code 25/26, or ids 0x85FA/0x85FB)
2. (always on) 3. LV Req (always on) 4. Uses - 0x3ec8cc 5. durability state - equipment and not "Uses"
6. Socket - equipment 7. Time - 0x3ec718 (pos 1..7 or 9 and time limit) 8. Model - instance +0xFA
9. Content - instance +0xFE 10. description - not inside TRe_CompoundForm/CompoundItem_Main/_Sub

Line order and format:

| # | text | source |
|---|---|---|
| 1 | `[ ` + name + forge + ` ]` | forge = `+N` from instance +0xF8 for pos 1..5 (or +0xFC for pos 6 special); shortstring "[ " 0x2a49f0, " ]" 0x2a49fc |
| 2 | `<Non-tradeable>` | flags & 2, or instance conditions (0x2a6cec) |
| 3 | `<Stat>: +N ` per status | N = value - 100 + forge nibble bonus (instance +0xF9, signed nibbles 0x2a202c); negative prints `-N`; then optional `+pet` / `+forge` bonuses; EXP on kind 0x71 adds `%, capped at N%` |
| 4 | `Type: ` + type name | 0x2a2c98 |
| 4b | compound window only: `Alch Type: `, `  Not a material`/`  Not for crafting`, `  Can't compound`/`  Can't craft`, `Alch Mat: `, `<mat> (Main) `, `<mat>  (Add) ` | 0x2a2ced..0x2a2fcd |
| 5 | `Rank: N` | rec 0x2D |
| 6 | `Uses: x/250` | only item 0x8759 (special counter) |
| 7 | `LV Req: N` (kind 0x72: `LV Req: N` + `Below `) | rec 0x71, skipped when 0 |
| 8 | potion `left/total` | value-100 minus used amount from the instance |
| 9 | `Time: ` + `Nday` + `H hr ` (or `1 hour `) | hours = time limit + remaining (instance double at +0xF0, x24) |
| 10 | `Uses: N ` | trunc((250 - wear) * maxUses / 250), wear = instance byte +0xE6 |
| 11 | `Content:` + item name (+ `+N`) | instance +0xFE |
| 12 | durability state | wear byte +0xE6: 0..149 Good (some ids "Usable"), 150..199 Used, 200..249 Wearing, >=250 Broken |
| 13 | `Socket: ` + item name | instance +0xEA |
| 14 | `Model: ` + item name | instance +0xFA |
| 15 | description | rec 0x92 |

Drawing (paint 0x2a6d74): every line at `(left+10, top+10+i*20)`, colour RGB565 **0xFFE0** (yellow),
clip width 0xB0 (176). The durability line is drawn as `State: ` (0x2a6f2c) in yellow and then the word
after six blanks in `self+0x140` = 0xFFE0 (Good/Usable/Used) or **0xF800** red (Wearing/Broken).
Size: width 0xC4 = 196 px; height = lines*20 + 20 + (len(desc)*8 div 130)*20. Position: x = slot left +
slot width + 2; if right edge > 800 then x = slot left - 196 - 2; bottom clamped to 600.

Not shown by the client tooltip: buy/sell price, element, materials (outside compound), durability numbers.

## 3. Inventory facts

- Stack limit **50**: add-to-stack 0x3f1c9a clamps count byte (+0x11) to 0x32 and returns the overflow;
  stack search 0x3f2d1b/0x3f2d88 skips stacks with count >= 50.
- Bag item array: `[[0x4c9918] + 0x27E8 + i*4]`, i = 1..50 (loops `cmp reg, 0x33`).
- Bag grid class ctor 0x10fa8c: cell count at +4, cells at +5, width byte +0xDA = 5, max row +0xDC = 9
  (rows 0..9); count 25 gives max row 4. All nine constructions pass 0x32 except Form_ThingGrid5x5 (0x19).
  Slot n (1-based) maps to row (n-1) div 5, column n - row*5 (0x10fa2c). Free-space test 0x10fd90 checks
  the item's w x h footprint (rec 0x196/0x197) against occupied cells.
- "Inventory is full" (0x13f3b9) is raised when 0x3f2cd0 -> 0x10fd90 finds no place.

## 4. Changes made in the Godot client

- `scripts/database/item_database.gd`: Item.dat loader now copies rank, level req, buy/sell price, flags,
  kind, set id, footprint, time limit, max uses and both status pairs from the decoded record;
  `get_rank()` returns the Item.dat rank (41 of 53 entries of the old `KNOWN_MATERIAL_RANKS` table
  disagreed); status names / type names / slot names follow the client; added `build_tooltip_lines()`,
  `durability_state()`, `STACK_LIMIT`, `BAG_*`, colour constants.
- `scripts/ui/item_tooltip.gd`: renders the client line list (yellow text, 196 px, 20 px lines,
  red durability word, client placement).
- `scripts/ui/hud/hud_inventory.gd`: stacks capped at 50 (overflow goes to new slots); equip_pos 7 no
  longer fits the special socket.
- Test: `tests/test_item_audit.gd`.

## 5. Open questions

- Tooltip background/border is not drawn by 0x2a6d74's text loop; the panel skin was not found
  (current Godot background is a guess).
- Exact y offset of the tooltip (`[ebp-0x2c]` added to the slot top) not traced.
- Item id lists behind 0x3f1e74/0x3f1e78 ("Usable" instead of "Good") not decoded.
- The Godot bag still uses 45 slots x 2 pages; the client bag is one 5 x 10 grid of 50 cells with
  multi-cell items. What the arrows beside the "item" title do was not traced. Not changed.
- Equipment socket screen positions in Form_RoleStatus are not recovered (layout comes from skin files).
- Material name strings are length-prefixed shorter than their text in this English build
  ("Whea", "Silv", "Copp" ...), so the real client likely displays the truncated names; not replicated.
- Fields rec 0x7A (o+0x7E) and 0x19D (o+0x1A1) are used for job/character restriction checks in 0x1c5df4;
  their exact meaning is a guess.
