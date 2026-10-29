# Packet dispatcher of aLogin.exe (decoded)

> **Older build.** The addresses below (0x2de1d4, 0x2de224, 0x2de2ec) belong to an earlier aLogin.exe (sha 190dae51...). The current file (sha 959659ae...) has its dispatcher at 0x2f2334 with tables 0x2f234c / 0x2f2414. Current table: [dispatch_table_959659ae.md](dispatch_table_959659ae.md).

Function `0x2de1d4` reads the action code (first payload byte, `bl`) and switches over 0..0xC7:
byte table `0x2de224` (action -> case index), dword table `0x2de2ec` (case index -> handler).
Case 0 (`0x2efbd1`) is the default / ignore path. Evidence: **decoded** (capstone disassembly of the exe).

| Action | Handler VA |
|---|---|
| 0x00 (0) | 0x2de468 (server notice, see below) |
| 0x01 (1) | 0x2dee72 |
| 0x02 (2) | 0x2df458 |
| 0x03 (3) | 0x2e016b |
| 0x04 (4) | 0x2e0c21 |
| 0x05 (5) | 0x2e0de4 |
| 0x06 (6) | 0x2e1284 |
| 0x07 (7) | 0x2e1613 |
| 0x08 (8) | 0x2e1875 |
| 0x09 (9) | 0x2e1c2b |
| 0x0A (10) | 0x2e1cfe |
| 0x0B (11) | 0x2e2215 |
| 0x0C (12) | 0x2e2487 |
| 0x0D (13) | 0x2e2887 |
| 0x0E (14) | 0x2e2d10 |
| 0x0F (15) | 0x2e353f |
| 0x10 (16) | 0x2e39e6 |
| 0x13 (19) | 0x2e3ea8 |
| 0x14 (20) | 0x2e4039 |
| 0x15 (21) | 0x2e5886 |
| 0x16 (22) | 0x2e594f |
| 0x17 (23) | 0x2e5dbd |
| 0x18 (24) | 0x2e90b5 |
| 0x19 (25) | 0x2e95f1 |
| 0x1A (26) | 0x2e993c |
| 0x1B (27) | 0x2e9eb5 |
| 0x1D (29) | 0x2ea189 |
| 0x1E (30) | 0x2ea381 |
| 0x1F (31) | 0x2ea4ff |
| 0x20 (32) | 0x2ea908 |
| 0x21 (33) | 0x2ea9a1 |
| 0x22 (34) | 0x2eac2f |
| 0x23 (35) | 0x2eacef |
| 0x24 (36) | 0x2ebf53 |
| 0x25 (37) | 0x2ec0af |
| 0x26 (38) | 0x2ec18a |
| 0x27 (39) | 0x2ec1ac |
| 0x28 (40) | 0x2ecd03 |
| 0x29 (41) | 0x2ecd25 |
| 0x2B (43) | 0x2ecd47 |
| 0x2C (44) | 0x2ece94 |
| 0x2D (45) | 0x2ed06c |
| 0x32 (50) | 0x2ed3d7 |
| 0x33 (51) | 0x2ed482 |
| 0x34 (52) | 0x2ed4b9 |
| 0x35 (53) | 0x2ed4e6 |
| 0x36 (54) | 0x2ed68a |
| 0x37 (55) | 0x2ed69b |
| 0x38 (56) | 0x2ed721 |
| 0x39 (57) | 0x2ed72d |
| 0x3A (58) | 0x2ed858 |
| 0x3B (59) | 0x2ed87a |
| 0x3C (60) | 0x2ed8cb |
| 0x3D (61) | 0x2ed933 |
| 0x3E (62) | 0x2edb92 |
| 0x3F (63) | 0x2edba6 |
| 0x40 (64) | 0x2edc7a |
| 0x41 (65) | 0x2edc8e |
| 0x42 (66) | 0x2ede2f |
| 0x43 (67) | 0x2edf21 |
| 0x44 (68) | 0x2ee0c0 |
| 0x45 (69) | 0x2ee1b0 |
| 0x46 (70) | 0x2ee207 |
| 0x47 (71) | 0x2ee347 |
| 0x48 (72) | 0x2eea1f |
| 0x4A (74) | 0x2eea33 |
| 0x4B (75) | 0x2eea84 |
| 0x4C (76) | 0x2eeba7 |
| 0x4D (77) | 0x2eebbb |
| 0x4E (78) | 0x2eec0c |
| 0x4F (79) | 0x2eec3c |
| 0x50 (80) | 0x2eec75 |
| 0x51 (81) | 0x2eeda1 |
| 0x52 (82) | 0x2eee9d |
| 0x53 (83) | 0x2ef15a |
| 0x54 (84) | 0x2ef2ac |
| 0x55 (85) | 0x2ef33c |
| 0x56 (86) | 0x2ef4d3 |
| 0x57 (87) | 0x2ef527 |
| 0x58 (88) | 0x2ef7b2 |
| 0x59 (89) | 0x2ef8ca |
| 0x5A (90) | 0x2ef9ae |
| 0x5B (91) | 0x2ef9c2 |
| 0x5C (92) | 0x2ef9d6 |
| 0x68 (104) | 0x2ef9ea |
| 0x69 (105) | 0x2efa24 |
| 0x6B (107) | 0x2efa5e |
| 0xB7 (183) | 0x2efa80 |
| 0xB8 (184) | 0x2efa94 |
| 0xBA (186) | 0x2efaa8 |
| 0xC7 (199) | 0x2efabc |

## Action 0 sub codes (server notices / disconnect reasons)

Second switch at `0x2de46f`: `cmp eax,0x52; jmp [eax*4+0x2de481]`.

| Sub | Text |
|---|---|
| 0x00 (0) | Connection lost |
| 0x01 (1) | Too Many Packets |
| 0x02 (2) | Fail Q&A 3 Times |
| 0x03 (3) | Wrong Pwd |
| 0x04 (4) | Disconnected |
| 0x05 (5) | Illegal Activity #1 |
| 0x06 (6) | Illegal Activity #2 |
| 0x07 (7) | Event Error |
| 0x08 (8) | Incorrect Trigger |
| 0x09 (9) | Wrong Event Table |
| 0x0A (10) | Table Error |
| 0x0B (11) | Illegal Press |
| 0x0C (12) | Illegal Press |
| 0x0D (13) | Movement Too Fast |
| 0x0E (14) | Movement Too Fast |
| 0x0F (15) | Delete Successful |
| 0x10 (16) | Blocked IP Detected |
| 0x11 (17) | Update Game Files |
| 0x12 (18) | Data Altered |
| 0x13 (19) | Repeated Login |
| 0x14 (20) | Abnormal D/c |
| 0x15 (21) | Abnormal Safe File Data |
| 0x16 (22) | Invalid Packet Data |
| 0x17 (23) | Password Too Short |
| 0x18 (24) | Password Too Short |
| 0x19 (25) | Duplicated Name |
| 0x1A (26) | Event Trigger Error |
| 0x1B (27) | Login Error D/c |
| 0x1C (28) | Too Much Data |
| 0x1D (29) | Too Much Data |
| 0x1E (30) | (no text) |
| 0x1F (31) | (no text) |
| 0x20 (32) | Scene Error |
| 0x21 (33) | Scene Error |
| 0x22 (34) | Other Server Login |
| 0x23 (35) | Confirm Licence |
| 0x24 (36) | Invalid ID |
| 0x25 (37) | Scene Changed |
| 0x26 (38) | Wrong Target Scene |
| 0x27 (39) | Connection lost |
| 0x28 (40) | Packet Manipulation |
| 0x29 (41) | Battle Error |
| 0x2A (42) | Battle Error |
| 0x2B (43) | Battle Error #0 |
| 0x2C (44) | Wrong Tigger Scene |
| 0x2D (45) | Account Banned |
| 0x2E (46) | Battle End Error |
| 0x2F (47) | Battle End Error |
| 0x30 (48) | Use illegal Skill |
| 0x31 (49) | Under 18 y/o Curfew |
| 0x32 (50) | Log into PVP Server |
| 0x33 (51) | Can't Login PVP Server |
| 0x34 (52) | Can't Login PVP Server |
| 0x35 (53) | Server Not Open Yet |
| 0x36 (54) | Left PVP Event |
| 0x37 (55) | No Transport On World Map |
| 0x38 (56) | Password Too Long |
| 0x39 (57) | Pwd & Del Pwd match |
| 0x3A (58) | Beta Access Error |
| 0x3B (59) | Relay Server D/c |
| 0x3C (60) | Connection lost |
| 0x3D (61) | Server Is Busy |
| 0x3E (62) | Incorrect Password |
| 0x3F (63) | Mini-Game Error D/c |
| 0x40 (64) | Wrong Version |
| 0x41 (65) | Wrong Version |
| 0x42 (66) | IP Zone Blocked |
| 0x43 (67) | External D/c |
| 0x44 (68) | Battle Protocol Error |
| 0x45 (69) | Battle Protocol Error |
| 0x46 (70) | Firewall Triggered |
| 0x47 (71) | Teleport Exploit |
| 0x48 (72) | Item.dat File Error |
| 0x49 (73) | Instance map purged |
| 0x4A (74) | Interserver D/c |
| 0x4B (75) | Max Logins Reached |
| 0x4C (76) | Event Violation |
| 0x4D (77) | IP Blocked |
| 0x4E (78) | IP Blocked |
| 0x4F (79) | Routing Error, Wait |
| 0x50 (80) | Acct Locked |
| 0x51 (81) | Log in again later |
| 0x52 (82) | Connection lost |

## Handler size and strings referenced (hints for what each action does)

| Action | Handler | Size | Calls | Strings seen |
|---|---|---|---|---|
| 0x00 | 0x2de468 | 2570 | 119 | Fail Q&A 3 Times; Wrong Pwd; Disconnected; Illegal Activity #1 |
| 0x01 | 0x2dee72 | 1510 | 0 |  |
| 0x02 | 0x2df458 | 3347 | 137 | (All) |
| 0x03 | 0x2e016b | 2742 | 101 |  |
| 0x04 | 0x2e0c21 | 451 | 17 |  |
| 0x05 | 0x2e0de4 | 1184 | 43 | Can't team if teleported to Carnie |
| 0x06 | 0x2e1284 | 911 | 23 |  |
| 0x07 | 0x2e1613 | 610 | 22 |  |
| 0x08 | 0x2e1875 | 950 | 21 |  |
| 0x09 | 0x2e1c2b | 211 | 3 | Name already in use; Illegal name, try another |
| 0x0A | 0x2e1cfe | 1303 | 40 | Name already in use; Illegal name, try another |
| 0x0B | 0x2e2215 | 626 | 20 | Use auto-heal |
| 0x0C | 0x2e2487 | 1024 | 27 |  |
| 0x0D | 0x2e2887 | 1161 | 35 | Player busy; Can't bathe now |
| 0x0E | 0x2e2d10 | 2095 | 72 | sound\wav0155.wav; Player ;  refused to add; Player busy |
| 0x0F | 0x2e353f | 1191 | 43 | Not enough fuel;  hr ; Merc Time:  |
| 0x10 | 0x2e39e6 | 1218 | 45 | You're really smart!; Oh~ You're wrong; City; You talk too much. Stop now or it'll be considered spam |
| 0x13 | 0x2e3ea8 | 401 | 8 |  |
| 0x14 | 0x2e4039 | 6221 | 154 | I have no questions. Visit me in 2 hours; sound\wav0152.wav;  Topped Up; Every Wed/Fri/Sun 7 to 9 PM join our PVP event! |
| 0x15 | 0x2e5886 | 201 | 9 | Login/Pwd error |
| 0x16 | 0x2e594f | 1134 | 39 |  |
| 0x17 | 0x2e5dbd | 13048 | 0 |  |
| 0x18 | 0x2e90b5 | 1340 | 50 | Mark;  tags; Incr. fail; Reduce fail |
| 0x19 | 0x2e95f1 | 843 | 24 | A player is below LV25!; Player has not enough time online!; Can't trade, player is below LV25; Player is below LV25! |
| 0x1A | 0x2e993c | 1401 | 55 | Obtain ; sound\wav0152.wav; ..obtain failed; Gold reached max.. |
| 0x1B | 0x2e9eb5 | 724 | 15 | Not enough Gold!; Sorry, inventory is full!; Purchase can't fit in inventory!; Trade failed |
| 0x1D | 0x2ea189 | 504 | 20 | Deposit; hD#/; Bank is full.. |
| 0x1E | 0x2ea381 | 382 | 7 |  |
| 0x1F | 0x2ea4ff | 1033 | 25 | Come again!; Not enough Gold!; No need to rest; This stay free |
| 0x20 | 0x2ea908 | 153 | 5 |  |
| 0x21 | 0x2ea9a1 | 654 | 20 | Target's PK is off; Unable to watch event; Can't join battle; City gate ally limit |
| 0x22 | 0x2eac2f | 192 | 8 |  |
| 0x23 | 0x2eacef | 4708 | 156 | Old pwd err; Old del err; Pwd too short; Pass and Sec Code must be different |
| 0x24 | 0x2ebf53 | 348 | 12 | Message banned |
| 0x25 | 0x2ec0af | 219 | 8 |  |
| 0x26 | 0x2ec18a | 34 | 1 |  |
| 0x27 | 0x2ec1ac | 2903 | 0 |  |
| 0x28 | 0x2ecd03 | 34 | 1 |  |
| 0x29 | 0x2ecd25 | 34 | 1 |  |
| 0x2B | 0x2ecd47 | 333 | 9 | Can't respond on TW; Can't leave on TW |
| 0x2C | 0x2ece94 | 472 | 12 |  Reborn!; No pet to reborn; LV is below 30 to reborn; Pet shouldn't be at Pet Keeper |
| 0x2D | 0x2ed06c | 875 | 33 | Can't team up; Only for owner and spouse; Can't drop here |
| 0x32 | 0x2ed3d7 | 171 | 6 |  |
| 0x33 | 0x2ed482 | 55 | 2 |  |
| 0x34 | 0x2ed4b9 | 45 | 1 |  |
| 0x35 | 0x2ed4e6 | 420 | 15 | Fixed stick prevented spawning! |
| 0x36 | 0x2ed68a | 17 | 1 |  |
| 0x37 | 0x2ed69b | 134 | 4 | Input ok; Input fail |
| 0x38 | 0x2ed721 | 12 | 0 |  |
| 0x39 | 0x2ed72d | 299 | 9 | Disabled by player |
| 0x3A | 0x2ed858 | 34 | 1 |  |
| 0x3B | 0x2ed87a | 81 | 3 |  |
| 0x3C | 0x2ed8cb | 104 | 4 |  |
| 0x3D | 0x2ed933 | 607 | 17 | Lottery has been drawn!; Lottery redeem time from 8 PM to 6 PM next day; Too much money; Didn't win lottery |
| 0x3E | 0x2edb92 | 20 | 1 |  |
| 0x3F | 0x2edba6 | 212 | 6 |  |
| 0x40 | 0x2edc7a | 20 | 1 |  |
| 0x41 | 0x2edc8e | 417 | 0 |  |
| 0x42 | 0x2ede2f | 242 | 8 |  |
| 0x43 | 0x2edf21 | 415 | 14 | Can't claim or been claimed |
| 0x44 | 0x2ee0c0 | 240 | 9 |  |
| 0x45 | 0x2ee1b0 | 87 | 3 |  |
| 0x46 | 0x2ee207 | 320 | 11 |  |
| 0x47 | 0x2ee347 | 1752 | 46 |  |
| 0x48 | 0x2eea1f | 20 | 1 |  |
| 0x4A | 0x2eea33 | 81 | 3 |  |
| 0x4B | 0x2eea84 | 291 | 11 |  |
| 0x4C | 0x2eeba7 | 20 | 1 |  |
| 0x4D | 0x2eebbb | 81 | 3 |  |
| 0x4E | 0x2eec0c | 48 | 1 | Player spawned |
| 0x4F | 0x2eec3c | 57 | 2 |  |
| 0x50 | 0x2eec75 | 300 | 8 | Not enough Points; Not enough Pts.; Server is busy |
| 0x51 | 0x2eeda1 | 252 | 5 |  |
| 0x52 | 0x2eee9d | 701 | 22 | Only 3 messages allowed; Message board is full; Info not found. Try again later; Can't use now |
| 0x53 | 0x2ef15a | 338 | 10 | Pet team full, can't open Pet Egg; You have same pet; Same pet in tent; Same pet at Pet Keeper |
| 0x54 | 0x2ef2ac | 144 | 5 |  |
| 0x55 | 0x2ef33c | 407 | 15 |  |
| 0x56 | 0x2ef4d3 | 84 | 3 |  |
| 0x57 | 0x2ef527 | 651 | 14 | Unavailable at Interserver; Interserver PVP suspend |
| 0x58 | 0x2ef7b2 | 280 | 10 | Inventory full. Make space for reissue |
| 0x59 | 0x2ef8ca | 228 | 9 | ExpUP |
| 0x5A | 0x2ef9ae | 20 | 1 |  |
| 0x5B | 0x2ef9c2 | 20 | 1 |  |
| 0x5C | 0x2ef9d6 | 20 | 1 |  |
| 0x68 | 0x2ef9ea | 58 | 2 |  |
| 0x69 | 0x2efa24 | 58 | 2 |  |
| 0x6B | 0x2efa5e | 34 | 1 |  |
| 0xB7 | 0x2efa80 | 20 | 1 |  |
| 0xB8 | 0x2efa94 | 20 | 1 |  |
| 0xBA | 0x2efaa8 | 20 | 1 |  |
| 0xC7 | 0x2efabc | 2048 | 34 |  |
