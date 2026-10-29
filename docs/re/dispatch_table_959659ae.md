# aLogin.exe packet dispatcher (build sha 959659ae, decoded from the file bytes)

Dispatcher at `0x2f2334` (`mov al, bl; cmp eax, 0xC7; ja 0x303ce1; movzx al, [eax+0x2f234c]; jmp [eax*4+0x2f2414]`).
Byte table `0x2f234c` = 200 action entries, dword table `0x2f2414` = 95 case handlers.
Actions that go to the default (0x303ce1) are not listed. Strings are taken from the first 0x800 bytes of each handler (approximate).

Handled actions: 91 (of 200 possible)

| Action | Handler VA | Strings used (first 4) |
|---|---|---|
| 0x00 (0) | `0x2f2590` | Too Many Packets / Fail Q&A 3 Times / Wrong Pwd / Disconnected |
| 0x01 (1) | `0x2f2f9a` | Whisper  /  Offline / Unable to connect, try again. / Password wrong |
| 0x02 (2) | `0x2f3580` |  |
| 0x03 (3) | `0x2f4293` | 5:5i5 |
| 0x04 (4) | `0x2f4d49` | @u(j / Can't team if teleported to Carnie |
| 0x05 (5) | `0x2f4f0c` | Can't team if teleported to Carnie |
| 0x06 (6) | `0x2f53ac` | Total length in KB for all files in list |
| 0x07 (7) | `0x2f573b` | Total length in KB for all files in list / Name already in use / Illegal name, try another |
| 0x08 (8) | `0x2f599d` | Name already in use / Illegal name, try another |
| 0x09 (9) | `0x2f5d53` | Name already in use / Illegal name, try another / Use auto-heal |
| 0x0A (10) | `0x2f5e26` | Name already in use / Illegal name, try another / Use auto-heal |
| 0x0B (11) | `0x2f633d` | Use auto-heal / SVWU / Player busy |
| 0x0C (12) | `0x2f65af` | SVWU / Player busy / Morphed player cant ride |
| 0x0D (13) | `0x2f69af` | Player busy / Morphed player cant ride / Can't bathe now / sound\wav0155.wav |
| 0x0E (14) | `0x2f6e38` | sound\wav0155.wav / Player  /  friend accepted /  refused to add |
| 0x0F (15) | `0x2f7667` | Not enough fuel /  hr  /  min / Merc Time:  |
| 0x10 (16) | `0x2f7b0e` | You're really smart! / Oh~ You're wrong / City / You talk too much. Stop now or it'll be considered |
| 0x13 (19) | `0x2f7fd0` | I have no questions. Visit me in 2 hours / sound\wav0152.wav /  Pts /  Topped Up |
| 0x14 (20) | `0x2f8161` | I have no questions. Visit me in 2 hours / sound\wav0152.wav /  Pts /  Topped Up |
| 0x15 (21) | `0x2f99ae` | Login/Pwd error |
| 0x16 (22) | `0x2f9a77` |  |
| 0x17 (23) | `0x2f9ee5` | sound\wav0152.wav |
| 0x18 (24) | `0x2fd1dd` | Mark /  tags / Incr. fail / Reduce fail |
| 0x19 (25) | `0x2fd719` | A player is below LV25! / Player has not enough time online! / Player online time too short / Can't trade, player is below LV25 |
| 0x1A (26) | `0x2fda64` | Obtain  / Gold / sound\wav0152.wav / ..obtain failed |
| 0x1B (27) | `0x2fdfdd` | Complete / Not enough Gold! / Sorry, inventory is full! / Purchase can't fit in inventory! |
| 0x1D (29) | `0x2fe2b1` | Deposit / Gold / ..deposit failed / Withdraw |
| 0x1E (30) | `0x2fe4a9` | Come again! / Not enough Gold! / No need to rest / This stay free |
| 0x1F (31) | `0x2fe627` | Come again! / Not enough Gold! / No need to rest / This stay free |
| 0x20 (32) | `0x2fea30` | Target's PK is off / Target's join is off / Unable to watch event / Can't join battle |
| 0x21 (33) | `0x2feac9` | Target's PK is off / Target's join is off / Unable to watch event / Can't join battle |
| 0x22 (34) | `0x2fed57` | NWLO Point Remain:  /  Pts / Fail to edit / Old pwd err |
| 0x23 (35) | `0x2fee17` | Fail to edit / Old pwd err / Old del err / Pwd too short |
| 0x24 (36) | `0x300063` | Message banned / Note: Guild has less than 15 members of LV10+ and  / yyyy/m/d /  disband |
| 0x25 (37) | `0x3001bf` | Note: Guild has less than 15 members of LV10+ and  / yyyy/m/d /  disband / sound\wav0155.wav |
| 0x26 (38) | `0x30029a` | Note: Guild has less than 15 members of LV10+ and  / yyyy/m/d /  disband / sound\wav0155.wav |
| 0x27 (39) | `0x3002bc` | Note: Guild has less than 15 members of LV10+ and  / yyyy/m/d /  disband / sound\wav0155.wav |
| 0x28 (40) | `0x300e13` | Can't ally during Trojan War / Can't respond on TW / Can't leave on TW /  Reborn! |
| 0x29 (41) | `0x300e35` | Can't ally during Trojan War / Can't respond on TW / Can't leave on TW /  Reborn! |
| 0x2B (43) | `0x300e57` | Can't ally during Trojan War / Can't respond on TW / Can't leave on TW /  Reborn! |
| 0x2C (44) | `0x300fa4` |  Reborn! / No RB token required / No pet to reborn / LV is below 30 to reborn |
| 0x2D (45) | `0x30117c` | Can't team up / Only for owner and spouse / Can't drop here / Make furniture space to next mainten |
| 0x32 (50) | `0x3014e7` | Fixed stick prevented spawning! / Input ok / Input fail / Feature disabled |
| 0x33 (51) | `0x301592` | Fixed stick prevented spawning! / Input ok / Input fail / Feature disabled |
| 0x34 (52) | `0x3015c9` | Fixed stick prevented spawning! / Input ok / Input fail / Feature disabled |
| 0x35 (53) | `0x3015f6` | Fixed stick prevented spawning! / Input ok / Input fail / Feature disabled |
| 0x36 (54) | `0x30179a` | Input ok / Input fail / Feature disabled / Disabled by player |
| 0x37 (55) | `0x3017ab` | Input ok / Input fail / Feature disabled / Disabled by player |
| 0x38 (56) | `0x301831` | Feature disabled / Disabled by player / Lottery has been drawn! / Lottery redeem time from 8 PM to 6 PM next day |
| 0x39 (57) | `0x30183d` | Feature disabled / Disabled by player / Lottery has been drawn! / Lottery redeem time from 8 PM to 6 PM next day |
| 0x3A (58) | `0x301968` | Lottery has been drawn! / Lottery redeem time from 8 PM to 6 PM next day / Too much money / Didn't win lottery |
| 0x3B (59) | `0x30198a` | Lottery has been drawn! / Lottery redeem time from 8 PM to 6 PM next day / Too much money / Didn't win lottery |
| 0x3C (60) | `0x3019db` | Lottery has been drawn! / Lottery redeem time from 8 PM to 6 PM next day / Too much money / Didn't win lottery |
| 0x3D (61) | `0x301a43` | Lottery has been drawn! / Lottery redeem time from 8 PM to 6 PM next day / Too much money / Didn't win lottery |
| 0x3E (62) | `0x301ca2` | Too many tents on the area! / Owner retrieved tent / Max amount of tents on the server reached! / Tent is closed |
| 0x3F (63) | `0x301cb6` | Too many tents on the area! / Owner retrieved tent / Max amount of tents on the server reached! / Tent is closed |
| 0x40 (64) | `0x301d8a` | Too many tents on the area! / Owner retrieved tent / Max amount of tents on the server reached! / Tent is closed |
| 0x41 (65) | `0x301d9e` | Too many tents on the area! / Owner retrieved tent / Max amount of tents on the server reached! / Tent is closed |
| 0x42 (66) | `0x301f3f` | Can't claim or been claimed / Can't trade same type of pet / Skills forgotten:  / Cu.j |
| 0x43 (67) | `0x302031` | Can't claim or been claimed / Can't trade same type of pet / Skills forgotten:  / Cu.j |
| 0x44 (68) | `0x3021d0` | Cu.j / Inventory Full |
| 0x45 (69) | `0x3022c0` | Inventory Full |
| 0x46 (70) | `0x302317` | Inventory Full / MPEJECT |
| 0x47 (71) | `0x302457` | Inventory Full / MPEJECT |
| 0x48 (72) | `0x302b2f` | Player spawned / Not enough Points / Not enough Pts. / Server is busy |
| 0x4A (74) | `0x302b43` | Player spawned / Not enough Points / Not enough Pts. / Server is busy |
| 0x4B (75) | `0x302b94` | Player spawned / Not enough Points / Not enough Pts. / Server is busy |
| 0x4C (76) | `0x302cb7` | Player spawned / Not enough Points / Not enough Pts. / Server is busy |
| 0x4D (77) | `0x302ccb` | Player spawned / Not enough Points / Not enough Pts. / Server is busy |
| 0x4E (78) | `0x302d1c` | Player spawned / Not enough Points / Not enough Pts. / Server is busy |
| 0x4F (79) | `0x302d4c` | Not enough Points / Not enough Pts. / Server is busy / Only 3 messages allowed |
| 0x50 (80) | `0x302d85` | Not enough Points / Not enough Pts. / Server is busy / Only 3 messages allowed |
| 0x51 (81) | `0x302eb1` | Only 3 messages allowed / Message board is full / Info not found. Try again later / Can't use now |
| 0x52 (82) | `0x302fad` | Only 3 messages allowed / Message board is full / Info not found. Try again later / Can't use now |
| 0x53 (83) | `0x30326a` | Pet team full, can't open Pet Egg / You have same pet / Same pet in tent / Same pet at Pet Keeper |
| 0x54 (84) | `0x3033bc` | Server busy, try again later / Unavailable at Interserver / Interserver PVP at:  / Interserver PVP suspend |
| 0x55 (85) | `0x30344c` | Server busy, try again later / Unavailable at Interserver / Interserver PVP at:  / Interserver PVP suspend |
| 0x56 (86) | `0x3035e3` | Server busy, try again later / Unavailable at Interserver / Interserver PVP at:  / Interserver PVP suspend |
| 0x57 (87) | `0x303637` | Server busy, try again later / Unavailable at Interserver / Interserver PVP at:  / Interserver PVP suspend |
| 0x58 (88) | `0x3038c2` | Inventory full. Make space for reissue / ExpUP / 5:5i5 |
| 0x59 (89) | `0x3039da` | ExpUP / 5:5i5 |
| 0x5A (90) | `0x303abe` | 5:5i5 |
| 0x5B (91) | `0x303ad2` | 5:5i5 |
| 0x5C (92) | `0x303ae6` | 5:5i5 |
| 0x68 (104) | `0x303afa` | 5:5i5 |
| 0x69 (105) | `0x303b34` | 5:5i5 |
| 0x6B (107) | `0x303b6e` | 5:5i5 |
| 0xB7 (183) | `0x303b90` | 5:5i5 |
| 0xB8 (184) | `0x303ba4` | 5:5i5 |
| 0xBA (186) | `0x303bb8` | 5:5i5 |
| 0xC7 (199) | `0x303bcc` | 5:5i5 |
