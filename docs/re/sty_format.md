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

## Open items
- Decode the 33-byte family (119 files).
- Confirm f2 = actor model with a render check.
- The storm CG is not in `.sty`; the sinking sequence stays a code reproduction.
