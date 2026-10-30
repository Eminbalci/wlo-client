# WLRI scene layout files (sty/*.sty)

Status: partially decoded. The 45-byte family is confirmed; meaning of most fields is a hypothesis.

## Family and framing (checked on all 768 files)
- 638 files use a 45-byte record stride (detected by byte periodicity: about 85% matches at offset 45).
- 119 files use a 33-byte stride (e.g. `11005.sty`, 695 bytes). Not decoded yet.
- 11 files are tiny (under 400 bytes).
- Record = 11 little-endian u32 values (44 bytes) + 1 tail byte. Parser: `tools/reference_analysis/sty_parse.py`.

## Fields of a 45-byte record (hypothesis, from `123.sty` = Map 10001, 2432x1792 px)
| field | meaning | evidence |
|---|---|---|
| f0 | x in pixels | 120 of 173 records fall inside the map bounds |
| f1 | y in pixels | same |
| f2 | model id: sprite file `<id>.jmp` in the archives | 1025 is a character model in `001.jma` (23x80 px frames); 1281 and 1537 also exist |
| f3..f10 | flags and sizes (256, 2048, 7680, ...) | not yet decoded |

Records repeat in groups (e.g. five records at x=1600, y=670, model 1025): likely one actor with several layers or animation states.

## What it is not
- Not the Eve NPC spawns: no record matches an Eve NPC world position on Map 10001 (Captain 14003 is at 1421,632; no record there).
- The first record of each file looks like a header (f0=256, f1=2304, ...).

## Model check (visual, `001.jma` frames)
- 1025 = a worm (creature), 1281 = a farmer NPC with a pitchfork, 1537 = an egg nest (prop).
- So a 45-byte record places a sprite of a creature, NPC or prop at a pixel position on the map.
- Map 10001 records include creatures (1025) on the ship deck, so these are not only crew. Only the Eve NPC spawns are separate.

## Working hypothesis (updated)
Each 45-byte file is the map's ambient actor/prop layout: creatures, villagers and props. Whether the client should spawn them
(and how many are animated) is not yet verified. The next check: compare with the Ground.MMG / Wem objects the client already draws
on Map 10001 to see if they are duplicates or additional actors.

## Comparison with the Ground triggers of Map 10001 (checked)
- The client draws map objects from Ground.MMG triggers (72 on Map 10001, Wem event ids 10001xxx).
- Distance from each in-bounds sty record (120) to the nearest trigger: median 288 px, 8 within 40 px.
- Random points on the same map: median 157 px, 23 of 300 within 40 px.
- So the sty records do NOT duplicate the Ground trigger objects. They are a separate actor layer (or use another coordinate system).

## Open items
- Decode the 33-byte family (119 files).
- Decide whether the sty actor layer should be spawned (not a duplicate of the Ground triggers; check the coordinate system first).
- Confirm f2 = actor model with a render check.
- The storm CG is not in `.sty`; the sinking sequence stays a code reproduction.

## Families of all 768 files (checked by stride and embedded names)
| stride | embedded name | files | meaning (hypothesis) |
|---|---|---|---|
| 45 | `MapXXXXX` | 565 | map actor/prop layout (section above) |
| 45 | `JRPJRole_N_M` | 6 | character style record (role image archive) |
| 45 | `NNNNNNN` (e.g. 11003004) | 67 | event/NPC style record, not decoded |
| 33 | `JRPJRole_N_M` | 51 | character style record (33-byte variant), e.g. `11005.sty` -> `JRole_5_1` |
| 33 | `MapXXXXX` | 19 | map layout, 33-byte variant (e.g. `11081.sty`, Map60013) |
| 33 | none | 49 | not decoded (e.g. `113.sty`) |

Next: decode the 33-byte character style records (51 files). Compare them with `JRole_N_M` frame counts in the archives.

## 33-byte character style family: findings (JRole)
- `JRole_N_M.jpg` in `jRole.JMG` / `JRole_c01.JMg` (832x640) is a full-screen character illustration (a CG), not a sprite sheet. Checked visually with `JRole_5_1`.
- The 33-byte record (checked on `11005.sty`) reads as: 1 byte type + 8 u32, with fields 400 and 340 repeating (a display size or position of the illustration). Hypothesis: the family places an illustration (CG or portrait) in a scene.
- `Jpeg.JMg` = mini-game backgrounds (Boxing, Slot machine, Poke, etc.), not the storm.
- `map.JMG` = one background per map id (`10001.jpg` = ship deck). Not a storm CG either.
- Conclusion: the storm/rescue CG is not in the pic archives checked so far; the 33-byte JRole records are illustration placements, so they may be the CG layouts the original uses in dialogues and cutscenes.

## 33-byte fields (profile over 51 JRole files, 981 records)
| field | observed values | reading |
|---|---|---|
| 0 | 0 in 901 records, small values otherwise | type or index (not decoded) |
| 1 | 0 in 918 records | not decoded |
| 2 | 0 in 809, 16777216 (0x01000000) in 51 | flags |
| 3 | 400 (328x), 432, 430 | width of the display area (hypothesis) |
| 4 | 300 (281x), 340, 320 | height of the display area (hypothesis) |
| 5 | 1024 (428x), 1025 (116x) | flags (0x400, 0x401) |
| 6-8 | some records carry ASCII (e.g. 1246777930 = "JRP"); a fixed 4-byte text tail | text, not a value |

Check: 832x640 / 400x300 = 2.08 and 2.13, almost the same scale, so fields 3-4 are probably the illustration's display size.
