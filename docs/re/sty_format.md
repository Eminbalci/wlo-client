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
