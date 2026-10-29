# aLogin.exe: functions and the strings they use (generated)

Source: `pe_survey.py` + `pe_xrefs.py` (scratchpad). Function starts = `55 8B EC` prologues, so a
function is the block starting at the listed address. Ghidra could not analyse this exe (timeout), so
these are prologue-based and approximate.

Functions with at least one referenced string: 1734

| function VA | strings (first 6) |
|---|---|
| `0x2f22fc` | EOutOfMemory / EAccessViolation / MPEG audio file path relative to output document (without fi / Total length in KB for all files in list / MPEJECT / Too Many Packets |
| `0x11ad74` | Mpeg audio file name / Mpeg audio file / FileName / Mpeg audio file name short (8+3) / FileNameShort / MPEG audio file path (without file name) |
| `0x15bee0` | menu\skins\default\Form_Repair.bmp / menu\skins\default\ / Load default / pic\images.Bmg / pic\images_1.Bmg / pic\images_2.Bmg |
| `0x92b28` | ActiveX / TBrushStyle / clInfoText / Sender / TUnDockEvent / ComCtrls |
| `0x284c14` | NewTarget / Icon_Career / icon_offline_1 / Btn_AssignLeave_1 / Btn_AssignLeave_2 / btn_release |
| `0x444314` | Double EXP event has begun! Don't miss it! / Double EXP event has ended! Thanks for participation / Double rewards in Item Mall mini-games has begun! / Double rewards in Item Mall mini-games has ended! / Dear Players, new years eve double expereience activity has  / New Year Eve's double EXP event has ended! |
| `0x275554` | Btn_saveFile_1 / Form_Business_1 / Btn_Close_s_1 / Btn_Abandon_1 / btn_TradeThing_1 / Btn_TradePet_1 |
| `0x25ef2c` | Graphics / TCheckBoxState / ParentBiDiMode / TScrollEvent / ScrollPos / Menu\Skins\white |
| `0x29fc80` | user\save / [System] / musicOn / musicOn= / soundOn / soundOn= |
| `0x447b14` | Team PVP begins in 5 minutes. Players LV10+ can  join at Cap / Team PVP has begun! Players LV10+ come to Capitol Building 2 / Team PVP will end in 5 minutes. Last chance to score! / Team PVP has ended. Come again next time! / Below LV10 can't participate / A team member is below LV10 |
| `0x46fa80` | S10321 / S10293 / S10294 / S10295 / S10296 / S10297 |
| `0x166fc4` | loadnewjmastart / 004c_1 / 004c_01 / 004c_b01 / 004c_c01 / 004e_1 |
| `0x37a938` | Poke_Exit_Btn / Item locked, can't use / EquipItemImage / Can't use at Interserver / Drag and drop this at home / Can't be used |
| `0x3a6dcc` | Fishing, can't act / Bathing, can't act / Can't PK here / Collecting, can't act / Can't PKSVW / Can't PK here |
| `0x22fe38` | btn_ok_1 / Btn_Next / Btn_Prev_1 / Btn_Default / Btn_ArrowL_1 / Btn_ArrowR_1 |
| `0x49f5a8` | Saber     / Sword     / Halberd   / Bow       / Wand      / Claw      |
| `0x1645d4` | Category / 001_a01 / 001_b01 / 001_C01 / 001_C02 / 001_C03 |
| `0x2967a4` | ScrollPos / Btn_MagicPutIn_1 / Num_Vip_3 / Num_SVip_3 / Num_VVip_3 / Icon_Career |
| `0x2a2058` | TRe_CompoundForm / CompoundItem_Main / CompoundItem_Sub / <Non-tradeable> / Shoot RES / , capped at  |
| `0x421ef0` | sound\wav / Teaming is turned off / Can't team here / Stall is in use / Fishing, can't act / Collecting, can't act |
| `0x3762a8` | DXDraws / icon_mail_1 / Full, can't store more / Must not be damaged / Can't use in Gacha Machine / Gachapon min qty is 10 per item |
| `0x19e268` | Icon_LimitLv / Form_DupChoose / Form_DupInnerMember / Form_DupInnerInfo / Icon_DupKillNum / Icon_Beat |
| `0x16ccd8` | Data\TrafficSetting.txt / MaxTrafficTool / TrafficID / TrafficCapsuleID / TrafficExchangeItem / TrafficWayKind |
| `0x369970` | Panel31 / Panel32 / Panel33 / Panel34 / Panel35 / Panel36 |
| `0x28d5c4` | NewTarget / Can't store item / TTH_ChangeColorForm / TTH_CellectionForm / Leader / Icon_online_1 |
| `0x153eb4` | \Photo / Sinfo.txt / WindowScreen / Simplified / FullMemory / HalfMemory |
| `0x2c3dcc` | Form_PlayerBattleBG / Btn_Close_S_1 / Btn_Close_1 / Btn_PlayerBattleMain / Btn_PlayerBattleRank / Btn_PlayerBattleSetting |
| `0x3cfea4` | Already in Guild / Guild is full / Not exist / No room in team / Can't apppint  / Can't appoint Vice |
| `0x2a7034` | String / Temporary unavailable / Can't use on yourself / Can't use at Interserver / Can't retrieve in battle / Can use only in battle |
| `0x1cee0c` | MiniGame_Explan_Form / btn_Start_1 / btn_Leave_1 / btn_close_s_1 / Throw_Exp_Form / btn_Start_1 |
| `0x36e758` | Can't use in event / Can't use props / Unable to use with remote on / Please select char / Item locked, can't use / Can't use at Interserver |
| `0x21e4cc` | Partner  / Requires LV30 to marry / Already married / Already applied / Queue full, pls wait / Aborted record |
| `0x29ca90` | Form_System_2 / System / icon_System / icon_VolumeBarOff / Btn_On_1 / Btn_Off_1 |
| `0x30ea10` | form_modulePlus / icon_Army / icon_Resource / panel16 / Btn_Close_s_1 / Btn_Close_1 |
| `0x408050` | TThread / Bathing, can't act / Can't do while using PC / Remove items from top / Can't place this / Can't place duplicate |
| `0x26f594` | btn_PrevMail_1 / form_NewRole_1 / icon_sexPatch / btn_Next / btn_cancel / icon_0 |
| `0x1a742c` | ]$SQRPj / Only same guild can join / Go to branch 1 for Troj War / Trojan War prepares / Weekly Trojan War will begin in 5 mins  / Trojan War has begun |
| `0x37e57c` | Stat to reallocate is same / Forget: STR (  / Forget: CON (  / Forget: INT (  / Forget: WIS (  / Forget: AGI (  |
| `0x1d4680` | Form_AutoPlayerPlus_1 / Btn_Close_S_1 / Btn_Close_2 / Btn_OK_2 / Btn_Cancel_3 / Icon_AutoTab_ |
| `0x1da04c` | EOutOfMemory / Target uses Secure Lock / Target uses Stall / Lover uses Magnet / Blocked by Target / Unable in event |
| `0x3c4ebc` | user\save / infoDisplayA / infoDisplayA= / infoDisplayB / infoDisplayB= / chanel |
| `0x23d308` | Icon_Inn_1 / Form_Inn_1 / Btn_Close_1 / Btn_Close_s_1 / Btn_ArrowL_8 / Btn_ArrowR_8 |
| `0x27d58c` | main_input_1 / Anim_GotMailS_1 / Btn_expression_1 / Chat Emotes / Btn_Close_s_1 / icon_expre_ |
| `0x2956e8` | EStringListError / Icon_online_1 / Icon_Busy_1 / Icon_inline_1 / icon_offline_1 / Icon_Element_0_1 |
| `0x29e534` | user\save / [System] / musicOn / soundOn / SpecSoundOn / musicVolume |
| `0x3c6a7c` | Hunting_Exit_Btn / Form_Top100_1 / Btn_ArrowL_8 / Btn_ArrowR_8 / Btn_TopLV_1 / Btn_TopGold_1 |
| `0x1b6638` | Form_InsteadEcis / Btn_Close_s_1 / Color_G / icon_Time_1 / Check Time Left / Btn_Expand |
| `0x1b8b28` | Can't use, EXP at 0 / Target has no Card / Target trade / Used Stall / Blacklisted by target / In Event |
| `0x235340` | Form_Compound_1 / Btn_Close_S_1 / Btn_Close_1 / Btn_CompSk_1 / Btn_CompSk_ / Icon_RoleSelectFrame |
| `0x26dc58` | Master, what can I do for you? / voice\A_robo_013 / voice\A_robo_012 / voice\A_robo_011 / Props Keeper / Pet Keeper |
| `0x2805b8` | form_status / Status [Ctrl+A] / icon_Rail1 / icon_HP1 / icon_SP1 / icon_exp1 |
| `0x2c92b4` | Can't join below LV50 / Leave event first / Can't join from tent / Leave Training Island to join event / In battle now / In event now |
| `0x3d9110` | form_Mailplus / Mail [Ctrl+F]    / icon_mail / anim_Gotmail / 55X57Grid / online |
| `0x27e2c4` | Can't talk when Chat closed / You're muted / World Channel is Off / (System):World Channel requires Radio Set / (Alert):Not enough SP to use Radio Setq / (System):Wait for 5 sec for Radio to charge |
| `0x2af1b8` | MainBtnBackGround / Btn_BackGround_2 / Inventory / Skills / Alchemy / Social |
| `0x34a24c` | Not allowed here / Can't sell here / Not available here / Can't set in bath / Can't perform during remote control / Fishing, can't use |
| `0x34e17c` | UUMethods / icon_Snow1 / icon_Snow2 / icon_Snow3 / icon_steam_1 / icon_steam_2 |
| `0x3a35c8` | ParentShowHint / Player unavailable yet / Low SP / Can't attack this / Can't use on foe / Can only use on yourself |
| `0x498208` | Read Npc. / Read Npc:: ParaNode / Read Door. / Read Mine. / Read Goods. / Read Eve. |
| `0x1a10c4` | Instance created / Max instance amount / LV too low / Finished today / Instance complete. / Instance complete. Claim rewards |
| `0x364d24` | sound\WB0020.wav / sound\WB0019.wav / sound\WB0018.wav / sound\WB0017.wav / sound\WB0016.wav / sound\WB0015.wav |
| `0x3711a8` | CompoundItem_Sub / Express / CompoundItem_Main / FixTrafficSpace / CarCase / ParkCase |
| `0x4a6760` | user\save / [Talk] / FormMode / FormMode= / FormPositionX / FormPositionX= |
| `0x12868c` |  HTTP/1.0 / OPTIONS  / PATCH  / UNLINK  / DELETE  / TRACE  |
| `0x27a084` | Main_Status_1 / Main_Hp / Main_Sp / Main_Word_Lv / Main_Word_Hp / Main_Word_Sp |
| `0x3168f4` | pic\item1_1.Bmg / form_module / icon_allies / icon_online / icon_offline / icon_AllyInfo |
| `0x3bf480` | form_module_1 / Btn_Close_s_1 / btn_module_1 / Volume /  disband / Spectate |
| `0x176444` | Form_ExchangeLock / Btn_Close_S_1 / Btn_Close_1 / Btn_OK_1 / btn_Uncheck_1 / Btn_ExchangeLockChang |
| `0x290c68` | Mailbox is empty / btn_Dead / btn_AssignRest_1 / Change name / btn_LeaveTeam_1 / btn_DismissTeam_1 |
| `0x3429d4` | Form_KeepPETStall_1 / Icon_PetInCage / Private Shop / Btn_KeepStall_1 / Btn_RevokeStall_1 / Icon_KeepStall_1 |
| `0x3f7aec` | TButton8 / Can't be used by player / Can't use on it! / Can't be used / Hot Spring Pack used / Not needed now |
| `0x1aa9b0` | Killer / Level reduced  / Select job / Stat points have to be allocated / Job is not selected / Stat points have to be allocated |
| `0x1fa9b4` | sound\wav0150.wav / Form_Express_1 / Express / btn_blank / Friend List / Guild List |
| `0x28c540` | crDrag / Can't remove when craft / Occupied in delivery / Can't remove pets from pack / Pet currently for sale / Can't remove during TW |
| `0x2a4e5c` | Shoot RES / , capped at  / Type:  / Rank:  / Uses:  / LV Req: :  |
| `0x3294fc` | Button48Click / JRole_5_2 / JRole_5_27 / JRole_5_8 / JRole_5_4 / JRole_5_25 |
| `0x33d6dc` | Not allowed here / Can't sell here / Not available here / Bathing, unable to make / Can't perform during remote control / Fishing, can't use |
| `0x385358` | Close Stall first / Target uses Stall / System busy, trade later / Player disconnected / Player is busy / Trade canceled |
| `0x3d5830` | cursor\cursor1.ani / cursor\cursor3.ani / cursor\cursor4.ani / cursor\cursor5.ani / cursor\cursor11.ani / cursor\cursor6.ani |
| `0x3e193c` | System busy, trade later / Player disconnected / Player is busy / Trade canceled / Canceled / Trade complete |
| `0x4498a4` | yyyy/m/d / Golden 30:  / White Gold 30:  / Diamond 30:  / Silver 30:  / Emerald 30:  |
| `0x457018` | AFK Mode / Auto Atk:  / Adv Setting:  / Pets Adv Setting:  / Auto Walk:  / Auto Heal:  |
| `0x14aef0` | Form_TurnGame / Btn_TGFresh / Icon_TGFresh_G / Btn_TGDouble / Icon_TGDouble_G / Btn_TGStart |
| `0x1a4e44` | Battle Royale has begun. Players LV10+ can go to Capitol Bui / Battle Royale will end in 10 minutes! / Battle Royale has ended. / Go to branch 1 for the event / Battle Royale: / In Battle Royale |
| `0x1c07a0` | Select activity / Claim reward from last event / Event hasn't started / Can't teleport / Teleport to the event? / Can't teleport |
| `0x1c5df4` | <Non-tradeable> / Shoot RES / , capped at  / Type:  / Rank:  / Uses:  |
| `0x226220` | Form_Magnet_1 / Panel26 / Btn_OK_2 /  uses  / btn_Check_1 / bar_H4 |
| `0x233cfc` | Menu\Skins\White\Form_CreateRole_1.jpg / Menu\Skins\White\Form_CreateRole_2.jpg / Menu\Skins\White\Form_CreateRole_3.jpg / Menu\Skins\White\Form_CreateRole_4.jpg / Form_InputPw_1 / Btn_Ok_1 |
| `0x32e034` | panel17 / Icon_GPS / btn_015 / Btn_Arrow_nW / Btn_Arrow_n / Btn_Arrow_nE |
| `0x3326e8` | Name taken / Char 1 Locked / Lock 1 space is full / Acct Unlock / Acct Not Locked / Banned player messages |
| `0x335d2c` | Insufficient LV / Close Stall first / Target uses Stall / Non-tradeable / Can't trade this type of pet / Pet in Express delivery |
| `0x33fa00` | Points Card / MyCard  / Icon_Card / Shoot RES / LV Req  / (Uses:  |
| `0x3443c8` | Can't sell here / Not available here / Not allowed here / Can't set in bath / Can't perform during remote control / Can't do in team |
| `0x349840` | Form_KeepUtensilStall / Btn_KeepStall_1 / Btn_RevokeStall_1 / Icon_KeepStall_1 / Icon_RevokeStall_1 / Btn_Cancel_1 |
| `0x3c38f4` | form_module / icon_option / icon_VolumeBarOff / Btn_Close_s_1 / Btn_Close_1 / icon_system |
| `0x3c4344` | user\save / infoDisplayA / btn_no / infoDisplayB / Chanel / Channel_On |
| `0x42b194` | Can't be blank / This game closed / Too far away / Mount on and off! / Can't do in battle! / Unable to ride! |
| `0x4647f8` | Stall is in use, can't do / Bathing, can't do / Fishing, can't act / Collecting, can't act / Can't use transport here / Transports not allowed |
| `0x4a5848` | Unable to make / panel_TalkForm / panel_TalkForm2_1 / panel10 / TTalkMsgForm / Btn_Resize_1 |
| `0x4d608` | USER32 / WINNLSEnableIME / IMM32.DLL / ImmGetContext / ImmReleaseContext / ImmGetConversionStatus |
| `0x17f5c4` | GameHall / Gobang_BG2 / GdMoney2 / Gobang_W / Gobang_B / Gobang_S |
| `0x1a8d98` | TThread / Auto Remote / Clover / Join Inst. / Exit Inst. / EXP Boost |
| `0x1bd810` |  reached max / Reached max Chaos Crystals / Confirm use  / Enhance?SVWUQ / Can't use here / Can't use for this |
| `0x21fbb4` | Form_setup_2 / Btn_Close_S_1 / Panel31 / Panel32 / Panel33 / Panel34 |
| `0x224414` | <Part> / <Tool> / <Furniture> / <Vehicle> / Shoot RES / Type:  |
| `0x232290` | ElementInfo_ / RoleInfo_2_1 / RoleInfo_2_2 / RoleInfo_1_1 / RoleInfo_4_3 / RoleInfo_4_2 |
| `0x252648` | form_modulePlus / icon_invitation / icon_InputPlayerName / Btn_Close_s_1 / btn_ok_1 / btn_cancel |
| `0x26a52c` | form_module / btn_module_1 / Pause3 / PlayNext3 / PlayPrev3 / repeat3 |
| `0x29db54` | Unavailable at Interserver / Can't return from tent / Can't return from this map / Can't return from jail / Can't return from event / Close Stall to return |
| `0x2ac548` | TPicture / Form_ChangePassword_1 / Btn_Close_s_1 / btn_ok_1 / btn_cancel_1 / Old pwd must be 6 to 10 char |
| `0x2ba1f0` | Icon_Weapon / Form_Skill_2 / Skills [Ctrl+S] / Btn_Close_s_1 / btn_Close_1 / bar_H4 |
| `0x322330` | File Date time formated for sorting (yyyymmddhhmmss). / EXP gained  / Reg success / Teammate already registered for TGC / Please apply in team of 4 people / Reg failed |
| `0x33c99c` | Icon_KeepStall_1 / Icon_RevokeStall_1 / Form_KeepItemStall_1 / Btn_Close_s_1 / Btn_ArrowL_9 / Btn_ArrowR_9 |
| `0x3d4894` | cursor1 / cursor1 / cursor3 / cursor11 / cursor5 / cursor4 |
| `0x3e0a6c` | System busy, trade later / Player disconnected / Player is busy / Trade canceled / Canceled / Trade complete |
| `0x3fd644` | Player removed items / Machine sales has reached limit / No eggs remaining / Seller changed amount / Machine suspended / Cabinet is full, can't store |
| `0x1beb68` | Form_Magnet_1 / Panel26 / Btn_OK_2 /  uses  / btn_Check_1 / bar_H4 |
| `0x1cd190` | S10416 / HitMouse / Mouse_1 / Mouse_2 / Bomb_1 / HiTurtle_1 |
| `0x1d8fa8` | Form_Magnet_1 / Panel26 / Btn_OK_2 /  uses  / btn_Check_1 / bar_H4 |
| `0x1ffca4` | form_autoPlay_1 / Btn_Close_S_1 / Btn_Close_2 / Btn_OK_2 / Btn_Stop_2 / Btn_readFile_1 |
| `0x235e90` | Book can't be base item / Can use only 1 Alchemy Book / Use at least 2 materials / Use at least 2 mats and Alchemy Book / Can't compound with Lucky Bags / Compound equipment part with Gem/Spar to socket it |
| `0x2440e8` | Icon_Exchange_1 / Icon_Exchange_2 / Icon_Exchange_3 / Form_ReFill_1 / Btn_Cancel_1 / Btn_Close_s_1 |
| `0x2abe58` | form_DeleteRole / Btn_Close_s_1 / btn_ok_1 / btn_cancel / Can't delete now / Enter pwd |
| `0x2ae8d8` | Pa.Wed / Clt.Wed / Slk.Wed / Ivo.Wed / Jde. Wed / Cry.Wed |
| `0x2b00b8` | Btn_BackGround_1 / Btn_PlayerBattle / World PK / Jump In / Spectate / Join Team |
| `0x2c9ba4` | Num_Vip_3 / Num_SVip_3 / Num_VVip_3 / Icon_CooperationTeam_G / btn_Check_1 / btn_UnCheck_1 |
| `0x3129a0` | form_Mailplus / Icon_LV / online / offline / OnBusy / icon_Member |
| `0x344ac8` | Can't be sold / Use Pet Cage to trade / Pet food has been used. Can't trade / Can't sell, no Amity / Pet in Express delivery / Can't sell, pet uses item |
| `0x37f744` | Num_Vip_1 / Num_SVip_1 / Num_VVip_1 / Form_TradeItem_1 / OtherSafeTradeItem / MySafeTradeItem |
| `0x3cb020` | EStringListError / You're unranked / Top damage: %u / Top DMG: %u, Rank %d / Icon_Asn / Killer |
| `0x41dcec` | Sound\BGM0014.wav / Sound\BGM0003.wav / Sound\BGM0010.wav / Sound\BGM0011.wav / Sound\BGM0009.wav / Mp3s\WM0011.mp3 |
| `0x4a5014` | Grats to [ / ] used  /  Obtain  / Egg Mach / Egg Mach 2 / Doll Machine |
| `0x4a6048` | user\save / [Talk] / FormMode / FormPositionX / FormPositionY / FormSizeW |
| `0x34d98` | comctl32.dll / InitializeFlatSB / UninitializeFlatSB / FlatSB_GetScrollProp / FlatSB_SetScrollProp / FlatSB_EnableScrollBar |
| `0x17bf5c` | GdMoney2 / S10416 / icon_LD_GhostF / icon_LD_GhostB / icon_LD_GhostG / MiniGame_Score_1 |
| `0x1e3064` | Can't use for this / Can't use Mall equip / Use Zeus Sword Soul item / Use only for Zeus Swords / Forging is over 100, can't use / Forging is less 100, can't use |
| `0x23a9f4` | Icon_Enough_1 / Icon_Lack_1 / Icon_MakeThingInfo_Grid_1 / Icon_MakeThingInfo_Plus_1 / Icon_MakeThingInfo_MakeQuant_1 / Icon_MakeThingInfo_MakeQuant_2 |
| `0x245c98` | Reg success /  registered /  in chess game / Reg failed / Not enough Gold (Req. 30g) / Max gold |
| `0x267300` | EAccessViolation / Locked  / Use Zeus Sword Soul item / Can't forge this / Can't forge this Eq / Forging at max |
| `0x268db8` | Menu\Skins\white / form_BlackNameList / Blocked / Panel26 / Btn_OK_2 / Btn_Delete_1 |
| `0x2c640c` | Can't join below LV50 / Leave event first / Can't join from tent / Leave Training Island to join event / In battle now / In event now |
| `0x2c6acc` | Form_ChooseCooperation / Btn_Close_S_1 / Btn_Close_1 / Btn_CooperationChoose / Btn_CreateCooperation / Icon_CooperationList |
| `0x3351a8` | Form_TradePet_1 / Icon_PetInCage / Btn_Close_s_1 / Btn_ArrowL_5 / Btn_ArrowR_5 / Btn_confirm_1 |
| `0x338d90` | OnePrice / Form_KeepItemStall_1 / Btn_Close_s_1 / Btn_ArrowL_5 / Btn_ArrowR_5 / Arrow_L2 |
| `0x384354` | Num_Vip_1 / Num_SVip_1 / Num_VVip_1 / Item_Block / Icon_Trade_1 / Icon_Confirm_1 |
| `0x384a48` | JRole_ / Not enough Gold / Close Stall first / Target uses Stall / Retrieve transport before trade / Feature disabled |
| `0x3c9b34` | EStringListError / You're unranked / Your rank is  / Icon_Asn / Killer / Icon_Samurai |
| `0x3d3668` | Num_White3_1 / Num_Black1_1 / Num_Blue1_1 / Num_Red1_1 / Num_White1_1 / Num_White3_2 |
| `0x3dac5c` | form_MailReceive_1 / icon_NextMail_1 / icon_PrevMail_1 / form_invitation2 / Btn_Close_s_1 / btn_reply_1 |
| `0x497c2c` | Read SceneHead. / Read Npc. / Fail!! When  / Read Door. / Read Mine. / Read Goods. |
| `0x4a487c` | (SystemPromp): / (Yell) / (World) / (Local) GM / (Local) / (GM) Cupid |
| `0x1865fc` | S10816L / S10152 / MiniGame_Score_1 / icon_heart / MiniGame_Time_1 / MiniGame_Life_1 |
| `0x191f6c` | Congrats! Can play free slots! / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points / Tokens left: / Tokens per game  |
| `0x1acc18` | form_MailReceive_1 / icon_NextMail_1 / icon_PrevMail_1 / form_invitation2 / Btn_Close_s_1 / btn_reply_1 |
| `0x1ba44c` | Form_MemCard2 / Color_G / Main_Word_Lv / Num_White3_1 / icon_online_1 / icon_offline_1 |
| `0x1ef80c` | EMathError / Form_GiftExchange_1 / Btn_Close_S_1 / Btn_Close_1 / Btn_GiftExchange_1 / Btn_ArrowL_5 |
| `0x2030fc` | Shoot RES / LV Req:  / 1 hour  / Broken / (Time:  / Content: |
| `0x22193c` | GlobaMap / Btn_Close_s_3 / Med. Sea / GlobaBtn / Unable in party / Item locked, can't use |
| `0x27b9bc` | Icon_Asn / Icon_Samurai / Icon_Knight / Icon_Sage / Icon_Clergyman / Icon_Prophet |
| `0x2c8b94` | Can't join below LV50 / Leave event first / Stall is in use / Can't join from tent / Leave Training Island to join event / In battle now |
| `0x33bde8` | Form_CardStall_1 / btn_ok_1 / btn_cancel_1 / Btn_Close_s_1 / Unable to apply card nowSV / Re-open Stall to sell |
| `0x3700b0` | EOutOfMemory / Form_RoleStatus_1 / Form_RoleStatus_2 / Form_RoleStatus_3 / Status Only / Inventory Only |
| `0x3c63d4` | form_module / Btn_Close_s_1 / Btn_Close_1 / icon_channel / btn_on / Btn_BlockMsg |
| `0x406294` | Riding, can't use / Team cannot use / Busy, can't use / sound\SEB0017.wav / sound\wav1510.wav / Can't use mounted |
| `0x41669c` | Follow role instructions / Collecting, can't take off / Insufficient level / Can't use on it / LV is low to equip / Can't change equips |
| `0x469a7c` | Poke_Exit_Btn / World channel is Off / Local channel is Off / Whisper channel is Off / Team channel is Off / Can't fish in battle |
| `0x46e53c` |  ATK up + /  DEF up + /  MATK up + /  MDEF up + /  SPD up + / ATK up  |
| `0x138b00` | SheepGameBG_2 / S10151 / sheepDreamLife / sheepDreamLife_ / Sleepbabo / SheepDream_ |
| `0x13bb68` | From_Transmi / Skills [Ctrl+S] / Btn_Close_s_1 / btn_Close_1 / bar_H4 / Rail_H5 |
| `0x13df70` | Form_GPS / Btn_Close_s_1 / Btn_SetPoint / Btn_Transmi / btn_close_1 / Btn_ArrowL_7 |
| `0x1756bc` | Form_ExchangeLockChang / Btn_Close_S_1 / Btn_Close_1 / Btn_OK_1 / IDField / Enter Password |
| `0x178098` | form_MusicCenter / Btn_Close_s_1 / btn_Close_1 / icon_m_Play / btn_m_Play / btn_m_Stop |
| `0x184930` | IM Points:  / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points / Price per game  /  Points! |
| `0x187a58` | MiniGame_Exit_Btn / Menu\Skins\White\Form_Conundrum_1.jpg / Icon_SecondBar_1 / Icon_O_1 / Icon_X_1 / Icon_Miss |
| `0x1a3e68` | Killer's priority is to kill their enemies with greatly incr / Equipped with full body armour, the warrior sacrifices agili / Speed and mobility are the hallmarks of a knight. Their ridi / Wits are mages who specialise in offensive magic. Their MATK / Faith enables priests to insulate themselves from all kinds  / * Increase ATK by 10% (without equips)    * Decrease counter |
| `0x1b5770` | Transformation time out / Transformed / Untransform / Can't use now / Can't use in shower / Can't use in bath |
| `0x1bac80` | Icon_Asn / Icon_Samurai / Icon_Knight / Icon_Sage / Icon_Clergyman / Icon_Prophet |
| `0x1e4d48` | Form_Potential_1 / Btn_Close_s_1 / Btn_Cancel_1 / btn_ok_1 / PotentialFire1 / PotentialFire2 |
| `0x1e7b48` | Form_Potential_2 / Btn_Close_s_1 / Btn_Cancel_1 / btn_ok_1 / PotentialFire1 / PotentialFire2 |
| `0x21d558` | Married is ordained by God, it shows bond of love and respon / Marriage matched in heaven for the lifetime. / Do you choose to marry each other, respect and love? / Hold hands and make an oath in front of God, relatives and f / I give you this ring with love and joy. Be my wife. / From today onwards, we will love and support each other in g |
| `0x222028` | Unable in party / Not for Stall / Unable in event / Unable in craft / Can't use here / Unavailable here |
| `0x2513d4` | form_modulePlus / icon_block / icon_BlockMsg / Btn_Close_s_1 / Btn_Close_1 / panel10 |
| `0x256830` | Form_SkillTree1 / icon_levelUp / icon_sk11003 / icon_sk11002 / icon_SKILLINFO / Btn_Close_s_1 |
| `0x29387c` | yyyymmdd / Btn_UnCheck_1 / Btn_Check_1 / Btn_on_1 / Btn_off_1 / Btn_on_1 |
| `0x2a6380` | <Part> / <Tool> / <Furniture> / <Vehicle> / Size:  / Shoot RES |
| `0x2adda4` | form_module / icon_SelectFeather / icon_SelectTreasure / icon_Feather / btn_Element_ / btn_ok_1 |
| `0x2b15a0` | BattleStatus_1 / Btn_Battle_ / Btn_Battle_5_1 / Cancel / No pet / Main_Hp |
| `0x2b74a4` | Icon_PetInCage / Word_Hp_1 / Pet_Bmp_Hp / Pet_Frame_Hp / Word_Sp_1 / Pet_Bmp_Sp |
| `0x2c154c` | Limit reached, try again later / In another team / Not enough coupons, can't join / Player %s lacks coupons / Lack Pts, can't team up / Lack Pts, can't do this |
| `0x2ce584` | btn_Bank_Gold_R / btn_Bank_Gold_L / Form_BankMoney_1 / Btn_ArrowR_5 / Withdraw / arrow_up1 |
| `0x3086dc` | form_taskview_1 / bar_H4 / rail_H4 / Arrow_L3 / Arrow_R3 / Btn_Close_s_1 |
| `0x325208` | MiniMap_1 / MiniMap_3 / MiniMap_4 / MiniMap_2 / MiniMap_5 / Form_HotKey_Mini |
| `0x339720` | Can't put here / Can't use in team / Enter a name / Don't use Illegal words / Name is too long / Don't use illegal letters |
| `0x33a6c8` | OnePrice / form_BuyQ_Npc / Btn_Close_s_1 / bar_H3 / rail_H3 / arrow_up1 |
| `0x373e0c` | Form_Sale / Btn_Close_s_1 / Btn_Close_1 / btn_Bank_Gold_L / btn_Bank_Gold_R / icon_SaleLink |
| `0x3cf0dc` | You left Guild / Leaves Guild / Not in Guild / You can't leave / Not allowed / Other ReasonSV |
| `0x419a5c` | Menu\Skins\White\Form_IdPassword_1.jpg / IDField / Panel26 / Btn_ArrowDn_1 / Btn_Login_L / Btn_Prev_L |
| `0x41a6a0` | Menu\Skins\White\Form_SelectRole_Empty_L.jpg / Menu\Skins\White\Form_SelectRole_Empty_R.jpg / Menu\Skins\White\Form_SelectRole_Info_L.jpg / Menu\Skins\White\Form_SelectRole_Info_R.jpg / Icon_Empty / Icon_LoginLogo_1 |
| `0x459548` | s51016L / S50616L / S40004 / S40002 / S40003 / S40001 |
| `0x12434c` | Connecting / Already connected / Host Lookup Timed Out / Host Lookup Canceled / Null Remote Address / Connection Timed out |
| `0x13e5d0` | ]$SQRPj / Can't use now / Can't teleport / Unavailable in event / Stall is being used / Can't do from a transport |
| `0x17706c` | btn_Check_1 / btn_UnCheck_1 / Security Lock In Use / Security Lock Set / Btn_ExchangeLockSet / Open the lock first |
| `0x179ef8` | Wrong object / Can't use when Riding    / Can't use when Following / Can't use when Trading    / Wrong object / Remove Pet equip first |
| `0x17eab0` | Form_Ante / Btn_Close_s_1 / btn_Ok_1 / btn_Cancel_1 / btn_Gobang_A0 / btn_Gobang_A1 |
| `0x18858c` | Apologize: / Arranging ranks. / Arranging ranks.. / Arranging ranks... / Waiting. / Waiting.. |
| `0x18f5c4` | Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points / Tokens left: / Tokens per game  / Tokens per game  |
| `0x194ba8` | Congrats! Can play free slots! / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points / Tokens left: / Tokens per game  |
| `0x19ccb8` | Form_DupDetail / Btn_Close_1 / Btn_Join / Btn_Close_s_1 / bar_H4 / Rail_H5 |
| `0x1b1f60` | Form_ChangeRoleName / Don't use obscene words / Don't use existing names / Don't use similar names / Panel26 / CreateRoleName |
| `0x1bd020` | Form_ConfuseStone / Btn_confirm_1 / Btn_Cancel_1 / Btn_Close_S_1 / EnhanceEquipItem / PotentialFire1 |
| `0x1eada8` | Form_MailBox_1 / Btn_Close_S_1 / Btn_Close_1 / Btn_sendMail_2 / Btn_deleteMail_1 / Btn_PrePage_1 |
| `0x21662c` | ChangCamp_Form / Btn_Close_S_1 / Btn_ok_1 / Btn_Close_1 / Arrow_L3 / Arrow_R3 |
| `0x22bb00` | Form_Capsulem / Btn_Close_s_3 / Btn_OK_1 / Btn_Cancel_1 / Capsule / Can't fix in battle |
| `0x22c460` | Form_Capsulem_2 / Btn_Close_s_3 / Btn_OK_1 / Btn_Cancel_1 / FurnitureCapsule / Can't fix in battle |
| `0x24a7f0` | Btn_Makebet / Btn_Sel / Btn_ClearN / Btn_LHelp / Btn_Lexit / Thanks!{! |
| `0x24c84c` | Icon_Price / panel16 / btn_readme / btn_quit / Btn_TDice1 / Thanks!{! |
| `0x24e2b8` | form_NPCUpgrade / newborn / Btn_Close_s_1 / btn_ok_1 / btn_cancel / Arrow_L2 |
| `0x24f6fc` | form_Donate / icon_Resource / icon_ItemGrids / icon_Resource1 / Btn_Close_s_1 / panel16 |
| `0x2506f0` | form_Donate / icon_weaponry / icon_ItemGrids / Btn_Close_s_1 / Btn_Close_1 / editorBG |
| `0x253938` | form_module / icon_allies / icon_SelectCouple / Btn_Close_s_1 / Btn_Close_1 / Btn_UpdateAllyInfo |
| `0x253ec4` | form_module / icon_Gift / icon_inputCashGift / icon_male / icon_female / icon_Resource1 |
| `0x2706e0` | form_NewRole_1 / form_NewRole_3 / form_NewRole_2 / form_NewRole_4 / form_NewRole_5 / form_NewRole_3 |
| `0x2744b8` | form_module / editorBG / Take NPC back? / btn_module_1 / Cancel / Passengers limit |
| `0x28ad24` | Disband your Guild? / Can't use now / Can't teleport / Unavailable in event / Stall is being used / Can't do from a transport |
| `0x28f90c` | Icon_Asn / Killer / Icon_Samurai / Warrior / Icon_Knight / Knight |
| `0x29c0cc` | Form_channel_1 / Btn_On_1 / Btn_OK_2 / Btn_Close_2 / Btn_On_1 / Btn_Off_1 |
| `0x29c55c` | Form_Huminfo_1 / btn_Check_1 / Btn_OK_2 / Btn_Close_2 / Unavailable / btn_Check_1 |
| `0x2ae564` | form_module / btn_Element / Icon_LV / online / offline / OnBusy |
| `0x2cd24c` | form_BuyQ_Npc / icon_System / bar_H3 / rail_H3 / btn_module_1 / arrow_up1 |
| `0x2d28e0` | form_module / editorBG / Visited / btn_SeekName / Btn_Close_s_1 / Btn_Close_1 |
| `0x30ab3c` | Form_onLineInfo_1 / txt\hotkeyt.txt / bar_H4 / rail_H4 / txt\hotkeye.txt / Btn_Prev_1 |
| `0x317e74` | jma\006.jma / jma\002w.jma / jma\003w.jma / jma\004w.jma / jma\005w.jma / jma\002w1.jma |
| `0x32c514` | Form_NoteBook / Btn_MissionBook / Quest Book / Btn_MonsterBook / Monster Data / Btn_StarBook |
| `0x360808` | Christian Rap / Not available here / Leave this team to join another / user\Map\ / form_module / Btn_Close_s_1 |
| `0x380480` | ]$SQRPj / Can't sell directly, too big! / Not an item / Item locked, can't use@ / Can't sell directly, too big! / Not an item |
| `0x3e03d8` | Can't trade here / Trade is locked / In fishing / Close Stall first / Target uses Stall / Player busy |
| `0x3f45ec` | LV Req: :  / Item's [ / ] durability run out / Damage reset / ] out of uses. Item lost / Equipped [[ |
| `0x1257a4` | EStringListError / Initializing Winsock / Version=  / High Version=  / Description=  / System=  |
| `0x12a238` | txt\Agrees / txt\Agree / Sinfo.txt / txt\Agree.txt / WindowScreen / Simplified |
| `0x13a75c` | form_module_1 / Btn_Close_s_1 / btn_module_1 / Computer / Teleport / FNpcMK |
| `0x13d794` | Pet in battle! / Pet is mounted! / Can't craft / Only 1 item at time / Unable to make / Bathing, unable to make |
| `0x14f9f0` | Form_Alchemist / Btn_Query / Btn_Cancel_1 / Btn_Close_S_1 / SelectUitem / Num_White3_1 |
| `0x17951c` | Form_BodyOff_1 / Btn_Close_S_1 / Btn_OK_1 / btn_close_1 / Btn_ArrowL_9 / Btn_confirm_1 |
| `0x18a64c` | You can right click to move, when unable to move / Sound\Wav1609.wav / Sound\Wav1610.wav / Sound\Wav0150.wav / Correct answer ( / [Quiz Zone] Rankings:  |
| `0x19d4b0` | Joined instance / Max members reached / LV too low / Instance started / Instance aborted / Finished today |
| `0x1b7dd0` | LV is below 10 / Insufficient online time / Contracted, can't entrust / Can't use in battle / Can't use self / Enter the name |
| `0x1db87c` | Form_IceBox_1 / Btn_Close_s_1 / btn_close_1 / Icon_IceBox_1 / IceBoxSpace / Form_Cupboard_2 |
| `0x1e043c` | Form_Packing / Btn_Cancel_3 / Btn_OK_2 / Item_PackingSpace / Only for Mall equips / Item locked, can't use |
| `0x1f8850` | Form_itemBank_1 / panel_restrainBank_1 / Btn_ArrowL_5 / Btn_ArrowR_5 / Btn_Close_s_1 / Btn_Close_1 |
| `0x21b57c` | Form_ATM_List / btn_Check_1 / bar_H4 / Rail_H5 / TransferList / Btn_Close_s_1 |
| `0x223198` | Form_Property / Btn_Close_S_1 / Btn_Close_1 / Btn_ok_1 / bar_H4 / Rail_H5 |
| `0x22512c` | Form_Marry / Btn_Close_S_1 / Btn_Divorice / Btn_Divorice1 / Btn_Close_1 / Form_Divorce |
| `0x2385dc` | Icon_Minute_1 / Form_MakeThing_1 / Btn_Close_1 / Btn_Close_S_1 / Btn_ArrowUp_3 / Btn_ArrowDn_3 |
| `0x2436cc` | Icon_BringUpFurTitle_1 / Form_MakeThing_1 / Btn_Close_1 / Btn_Close_s_1 / Icon_BlueNet32x32_1 / Btn_ArrowUp_3 |
| `0x247510` | ZMC_Piece / ZMC_Btn1 / ZMC_Btn2 / ZMC_Btn3 / ZMC_Btn4 / btn_readme |
| `0x255f34` | form_module / Licence / txt\Agree1.dat / txt\Agree1.txt / bar_H4 / rail_H4 |
| `0x25cf74` | Menu\Skins\white / Form_ShoppingCar_1 / Item Mall / Btn_DelItem / Btn_Return / Btn_PayOffOK |
| `0x2a18dc` | Start Beach / Recorded / No saved record / Carnie / In Carnie / Can't use underwater |
| `0x2a916c` | Form_HotKey_V / Btn_Minimize_1 / Btn_ArrowL_3 / Btn_ArrowR_3 / Form_HotKey_H / Btn_ArrowUp_2 |
| `0x2c30b0` | Form_STSetPwd / Btn_Close_S_1 / Btn_Close_1 / Btn_OK_1 / IDField / Set the Security Code |
| `0x30a528` | Open message / : not enough characters / : item doen't exist in database / : wrong item compound / Mate kind ratA ratB / Result |
| `0x314b44` | form_module / icon_livelihood / icon_task / icon_LV / icon_HP_SP_EXP / icon_exp1 |
| `0x375418` | Form_SaleNet / Btn_Close_s_1 / Btn_Close_1 / arrow_up1 / arrow_dw1 / icon_Get |
| `0x3f2110` | Item selected for compounding / Item selected for trade / Item locked, can't use / Item selected for sale / Item selected for props keeper / Item selected for express |
| `0x3f7474` | Don't litter In Hot Springs! / Item locked, can't use / Can't act when using Vehicle / Max number of items on floor / Can't be thrown on floor / Can't drop items at home |
| `0x401808` | Confirm / No inv. space / No tent space / Funiture limit / Craft  /  paused |
| `0x411490` | Unbound Gate expansion not found / King's Glory exnapsion not found / Temple Guardian expansion not found / Fairy Whisper expansion not found / Unbound Gate expansion not found / King's Glory exnapsion not found |
| `0x429fa8` | Shadow / Monster_Shadow / icon_KillEmyNum / icon_DeadMan / Banner / icon_Fan |
| `0x44938c` | 4-PVP event begins in 5 minutes. Players can go to event are / 4-PVP event has begun! Good luck in ranking! / 4-PVP event will end in 5 minutes. Last chance to score! / 4-PVP event has ended. Wait for score announcement / Can't use second character on 4-PVP event server! / This is not your team leader |
| `0x46db14` | String /  Time Left:  / Go to Training Isle? / sound\wav0152.wav / Status effect expired /  in use |
| `0x111660` | Not a JXAN file / JXAN version mismatch (need Ver=2 for JmpWhole) / JXAN flags mismatch (not whole-jmp mode) / JXAN record not found for %s / JmpMem size mismatch: mem=%d rec=%d / Nonce mismatch (wrong JMA name or wrong record) |
| `0x19715c` | Sound\SEB0173.wav / Sound\SEB0221.wav / Sound\SEB0156.wav / Sound\SEB0199.wav / icon_heart / S10151 |
| `0x1a7f84` | AutoplayTool_1 / Btn_ExitGuest_1 / Btn_GoToDup / StopExp / default\ / Btn_Cachet |
| `0x1b25b8` | No name / Name is too long / Don't use Illegal words / Change your name #R / Name changed / No name |
| `0x1b3a74` | Btn_Close_S_1 / Piano_do / Piano_re / Piano_mi / Piano_fa / Piano_sol |
| `0x1b5018` | Gas Storage tank is full / Can't use now / Can't use in shower / Can't use in bath / No transport / Riding, can't use |
| `0x1b5d20` | Form_SmallGasCan / Btn_Gas / Btn_Cancel_2 / Btn_Close_S_1 / Num_White3_1 / SmallGasCan |
| `0x1c4fa4` | Can't store item / Item locked, can't use@ / Inventory is full / Can't auto-use at Interserv / Auto-use EXP Potion is on / Can't use here |
| `0x1d3dfc` | Tokens per game  / Item locked, can't use / Can only be used on Voyage Map / _Mini_Form / Btn_Minimize_1 / Form_HotKey_Mini |
| `0x1d9a38` | Can't use self / Enter the name / Player offline of don't exist / Lover's Magnet is not equipped / Can't use below LV 50 / Can't use, target is below LV 50 |
| `0x1dace8` | Only for Vehicles / Item locked, can't use / Doesn't need repairs / Only for Vehicles / Item locked, can't use / Doesn't need repairs |
| `0x1e68b8` | Not for mercenaries / Reached max potential / Potential is below 10! / Failure will forget skill, sure? / Will make pet #Rnon-tradeable/#R. / Confirm use SVWU |
| `0x1ea6c4` | Btn_Cancel_5 / Btn_MagicPutIn_1 / Btn_Cancel_5 / Btn_MagicPutIn_1 / Btn_StoreFiring_1 / Bottle full |
| `0x1f41d8` | Form_ChangeColor_1 / Menu\Skins\default\ / Btn_ArrowL_2 / Btn_ArrowR_2 / Btn_primal_1 / btn_ok_1 |
| `0x1fed8c` | WordBool / Remote config loading failed / btn_Check_1 / btn_UnCheck_1 / Remote settings loaded / No Remote config |
| `0x212380` | fishbow / Btn_Minimize_1 / Btn_AddFish / BuyFish / Btn_DelFish / Discard |
| `0x212d14` | FormBuyFish / Btn_Close_S_1 / Btn_ok_1 / Btn_Close_1 / Arrow_L3 / Arrow_R3 |
| `0x222b58` | Max Gold reached / Not enough Pts. / Deduct #R#B / /#R/#B /  Points / G.Coin |
| `0x225aec` | Queue is full / Divorced / Spouse force divorce / Consent required, spouse offline for less 30 days / Divorce canceled / Response timeout, canceled |
| `0x22de9c` | form_modulePlus / Btn_Close_s_1 / Btn_Close_1 / Arrow_L2 / Arrow_R2 / Panel22 |
| `0x254e08` | form_task / icon_OfficerList / icon_OfficerDiscribe / bar_H4 / rail_H4 / Arrow_L2 |
| `0x2572b8` | EStringListError / btn_blank1 / Requires  / , per level / , can  / , consume SP |
| `0x26eb38` | Sound\Wav0152.wav / Master, how do I look?~ / Master, is it good?~ / Master, I will be embarrassed... / Master, you don't have this suit / Master, I'm already wearing this~ |
| `0x28ba10` | Can't be blank / Can't remove during TW / Pet is riddenv! /  Remove hired #RMercenary NPC/#R?R / Disband this team? / Leave this team?? |
| `0x292354` | Cant change in event / Can't do in battle / Can't change in transport / Switch team leader / Can't do when craft / Can't do when bathe |
| `0x292c34` | hotkey / btn_Action_ / Btn_on_1 / Btn_off_1 / btn_Check_1 / btn_UnCheck_1 |
| `0x2a9b88` | HP and SP are full / HP restored / No HP potions  / SP restored / Icon_UnSavelock / Security Lock: Unlocked |
| `0x2c0254` | Form_VIP / Btn_Close_S_1 / Btn_VipUseAll / Btn_VipReward_1 / Panel43 / Num_Vip_1 |
| `0x2d1220` | btn_Bank_Gold_R / btn_Bank_Gold_L / form_INN_FNpc / SelFNpcRect / Deposit / Withdraw |
| `0x313970` | Continue? / Members:  / Online:  / yyyy/m/d / Founded:  / Leader:  |
| `0x314614` | Form_EditRule_1 / inputCursor / bar_H4 / Btn_ArrowUp_1 / Btn_ArrowDn_1 / Btn_Close_s_1 |
| `0x32148c` | EAccessViolation / Someone / 's Home  / Floor 1 / Floor 2 / Cherry Grove |
| `0x365e40` | TCheckBoxState / panel22 / btn_ok_1 / btn_cancel_1 / Btn_Close_1 / bar_H4 |
| `0x36d39c` | Delivery canceled / Target player offline / No space in target inventory / Target player in dungeon / Leave dungeon first / Can't send, wrong data |
| `0x382dac` | NpcStoreExchangeNeedItem / NpcStoreSelectedItem / Btn_Buy_1 / Btn_Close_1 / Btn_Close_S_1 / Btn_ArrowUp_3 |
| `0x3bdb00` | Icon_Asn_2 / Icon_Samurai_2 / Icon_Knight_2 / Icon_Sage_2 / Icon_Clergyman_2 / Icon_Prophet_2 |
| `0x3d1c9c` | Ally broken / No alliance / Only leader can use / Error leaving alliance / Leader offline / Leader offline |
| `0x3e0ee8` | Can't trade here / In fishing / Close Stall first / Target uses Stall / Player busy / Unable to apply, player is busy |
| `0x3e1e64` | Can't trade here / In fishing / Player busy / Close Stall first / Target uses Stall / Unable to apply, player is busy |
| `0x3fb18c` | Elevator_LB / Fire_LB / BianPao_LB / GuGuClock_L / Elevator_RB / Fire_RB |
| `0x428488` | \Data\AdjustRidePetPos.txt / npccount / npcpic / fixedposonfirst / standposx / standposy |
| `0x454038` | equipped / removed / Attack /  risen /  drops / Defense |
| `0x462de0` | Can't use transport here / Can't use indoors / Transports not allowed / Too far from water / Vehicle is damaged / Transport used up |
| `0x46aa38` | 15010.sty / 14035.sty / 25094.sty / 25099.sty / 25110.sty / 25129.sty |
| `0x471530` | [Anti-addiction] After 3 hours your income decreases 50%. Go / [Anti-addiction] Online time maxed  / [Anti-addiction] You're fatigued, income decreases 50%. Go o / [Anti-addiction] You play too much. Go offline to rest! / Can't start, someone fatigued / Can't use cause of fatigue |
| `0x474714` | Can't use now / Can't teleport / Unavailable in event / Stall is being used / Can't do from a transport / Currently fishing |
| `0x476810` | Unlock to buy items / Unlock to trade items / Unlock to set a Stall / Unlock to Express items / Unlock to discard items / Unlock to compound |
| `0x106294` | ole32.dll / CoCreateInstanceEx / CoInitializeEx / CoAddRefServerProcess / CoReleaseServerProcess / CoResumeClassObjects |
| `0x10dac0` | Suggest format failed ! / Open stream failed ! / Assertion failure / Prepare header failed ! / Unprepare header failed ! / Prepare header failed ! |
| `0x1424ac` | BoxingBackground / StrengthBarFrame / BoxingBar / BoxingGameMonst / BoxingGameBoxer / BoxerLose |
| `0x143790` | IM Points:  / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points / Price per game  /  Points! |
| `0x149ec8` | CJ_BG1 / little_circle / Icon_X_1 / Icon_O_1 / MiniGame_Score_1 / MiniGame_Time_1 |
| `0x14d208` | IM Points:  / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points / Price per game  /  Points! |
| `0x174bec` | Form_LotteryOL / Btn_Close_s_1 / Btn_Close_2 / Btn_LotteryOL / Icon_UnKnow / Click to see reward |
| `0x175e64` | Form_ExchangeLockCancel / Btn_Close_S_1 / Btn_Close_1 / Btn_OK_1 / IDField / Enter Password |
| `0x17ae74` | Wrong object / Can't use when Riding    / Can't use when Following / Can't use when Trading    / Can't use when selling / Remove Pet equip first |
| `0x180df4` | m/d/yy / Start The Game? / Game Has Started / Sound\wav0154.wav / Draw Game / You Win  |
| `0x18f104` | IM Points:  / Price per game  / Want to play? / Price per game  / Tokens left: / Tokens per game  |
| `0x19de44` | Num_MainInfo / Form_CreateDupMis / Btn_Cancel_1 / Btn_Create / Btn_Close_s_1 / Btn_ArrowL_5 |
| `0x1ad530` | Need Mailbox to send / No target player / No mail content / GMCenter / Can't send to GM / sound\wav0155.wav |
| `0x1ae8d8` | Panel16 / Form_MailBox / Btn_Close_s_1 / Btn_sendMail_2 / btn_PastMail_1 / Btn_Close_1 |
| `0x1b384c` | sound\WAV9904.wav / sound\WAV9905.wav / sound\WAV9906.wav / sound\WAV9907.wav / sound\WAV9908.wav / sound\WAV9909.wav |
| `0x1b814c` | Capacity at max / Expand to  / . Sure? / Do you want to upgrade? / Can't expand in training / Capacity at max |
| `0x1c35cc` | Can't store item / Item locked, can't use@ / Inventory is full / Can't use at Interserver / Please Reply / Can't use at Interserver |
| `0x1c4858` | Form_ExpBox / btn_UnCheck_1 / Btn_confirm_1 / Btn_Cancel_1 / StoreExpPCase / btn_Check_1 |
| `0x1dec24` | Wrong item type / Can't be matched / Can't use non-player eq / Item locked, can't use / Equip's model and forging will #Rdisappear./#R / sound\wav0154.wav |
| `0x1e12a4` | Form_Packing / Btn_Cancel_3 / Btn_OK_2 / Item_ReduceItemSpace / Icon_MagicBox_1 / Item locked, can't use |
| `0x1e9658` | images/middle/baha.gif / class="style1" / </span> / class="style4" / <a href=" / "_blank"> |
| `0x1ec868` | user\Server / \MsgFriendLog / \*.Dat / UnReadMsg.dat / yyyy"/"mm"/"dd hh:mm:ss / \MsgArmyLog |
| `0x1f20c0` | Can't use now / Transport required / Item locked, can't use / No suitable fuel type / Can't store item / Item locked, can't use |
| `0x1f6554` | Btn_Close_s_2 / icon_blueprint / Form_blueprint_1 / Btn_Close_3 / Complete / Form_blueprint_3 |
| `0x1fb5f0` | Can't send this / Can't act when using Vehicle / Item is too big to deliver / Can't send this / Can't be traded / Item locked, can't use |
| `0x206598` | Form_EggMachine_1 / Btn_Close_S_1 / Btn_Close_2 / Btn_setup_1 / Btn_Stop_2 / Panel_itemGr_10_1 |
| `0x208af0` | Inventory full / Can't store when mounted / Can't store NPC / Crafting, can't use / Can't store Merc / Storage full |
| `0x20b5a0` | Form_Computer_1 / Btn_Close_S_1 / Btn_Close_1 / Btn_OK_1 / Btn_STOP_1 / Bathing, can't act |
| `0x2119ac` | Form_CarCase / Btn_Close_S_1 / Btn_Close_1 / CarCase / default\ / Form_Display |
| `0x214998` | Form_pickup / Btn_OK_2 / Btn_Cancel_3 / Btn_Close_2 / SelectUitem / Item seach active |
| `0x218c9c` | notice2 / Btn_Close_S_1 / Btn_Close_1 / Btn_deleteMail_1 / Btn_Del_B / Btn_sendMail_2 |
| `0x2191b8` | Notice / Btn_Close_S_1 / Btn_Close_1 / Btn_AddNew_1 / Btn_PrePage_1 / Btn_NextPage_1 |
| `0x21a558` | Form_ATM_Deposit / Btn_Close_S_1 / btn_close_1 / Btn_ArrowR_5 / Withdraw / Btn_ArrowL_5 |
| `0x21cbfc` | Form_Marry / Btn_Close_S_1 / btn_Marry_1 / btn_Marry_2 / Btn_Close_1 / btn_Marry_1 |
| `0x22f5f0` | Can't use in other player home / Item in crafting process / Remove items from top / Normal Mode / Build Mode / Can't use in other player home |
| `0x240fc8` | Life Skill / Collect / Craft  / Fishing / Alchemy / Level:  |
| `0x24abd4` | form_module / icon_HELP / bar_H4 / rail_H4 / panel10 / btn_ok_1 |
| `0x24c3a8` | form_module / icon_HELP / bar_H4 / rail_H4 / panel10 / btn_ok_1 |
| `0x25933c` | form_npcSkillTree / icon_levelUp / Btn_Close_s_1 / btn_ok_1 / btn_cancel / btn_Readme |
| `0x25d404` | Level:  / Shoot RES / Crit Chance / Seal Resist / Can't be traded or gifted / Atk all enemies. Can't trade. Not for PK |
| `0x260e6c` | Req. LV:  / Shoot RES / Crit Chance / Seal Resist / Can't be traded or gifted / Atk all enemies. Can't trade. Not for PK |
| `0x267fec` | Forge at max / Confirm?  / You have#R%d tokens/#R / You have#R%d tokens/#R / IM Points:  / Price per game  |
| `0x26868c` | Success / sound\SEB0300.wav / Failed / Not enough Points / Not enough Scrolls / Forge Succes |
| `0x26e614` | voice\A_robo_021 / Master, you're so funny~ (Smiles) / Master, you're so funny~ (Blush) / voice\A_robo_033 / voice\A_robo_032 / voice\A_robo_031 |
| `0x28b210` | Pick members first / Pick member first / Select 1 member first / This member offline / Request to switch? / btn_UnCheck_1 |
| `0x2beb38` | Btn_Apply1 / Btn_Apply2 / Form_PlayerTitle / btn_close_s_1 / Btn_ArrowL_8 / Btn_ArrowR_8 |
| `0x2bf5fc` | Form_Exchange2 / btn_close_s_1 / Enter a code / btn_ok_1 / Redeem / Btn_Cancel_1 |
| `0x2c1018` | form_ReFill_2 / Btn_Close_S_1 / Btn_MPay / 980xPay / Btn_NewebPay / NewebPay (Taiwan) |
| `0x2cf3dc` | form_module / icon_inn / panel10 / btn_YES / btn_NO / Btn_Close_s_1 |
| `0x30a04c` | form_module / Btn_Close_s_1 / editorBG / bar_H4 / rail_H4 / btn_module_1 |
| `0x30bd94` | On monthly fee / Monthly fee: / Points remain  / Switched to fee mode / No enough points for a fee / To toggle fee needed |
| `0x315a4c` | form_module / icon_LV / form_status / Btn_Close_s_1 / Btn_Close_1 / Arrow_L2 |
| `0x316308` | form_module / icon_ArmyCmd1 / icon_ArmyCmd2 / Btn_cmd1_ / Btn_Close_s_1 / Btn_Close_1 |
| `0x327a20` | Label11p / Form_PetStatus / Btn_AssignRest_1 / Btn_AssignFight_1 / Battle / Btn_AssignRide_1 |
| `0x34b7b8` | Form_Buy3Utensil_1 / BeStallUtenSil / Btn_Buy_1 / Btn_CLose_1 / btn_close_s_1 / UtensilStalllPanel |
| `0x3a5b78` | Sound\BGM0014.wav / Sound\BGM0003.wav / triangle1 / triangle2 / AwlYellow / Icon_AutoTarget_1 |
| `0x3aee84` |  level up  / LevelUP /  EXP gained:  /  EXP lost  /  Amity lost  / LevelUp |
| `0x3af730` | ,let me help / Who push me  / Forced... / Ops! Wrong side! / Use Kung Fu to attack? / I'm so fast! Seriously, asking me to attack? |
| `0x3c2ac4` | Spectate / btn_module_1 / Jump In / form_module / You're in team / You're in team |
| `0x3d9c88` | Form_MailSend_1 / Btn_Close_s_1 / Btn_sendMail_2 / btn_PastMail_1 / Btn_Close_1 / btn_Clear_1 |
| `0x3dc6f8` | Formula.dat missing / Members:  / Online:  / yyyy/m/d / Founded:  / Leader:  |
| `0x3ef904` | EStringListError / CompoundItem_Sub / Express / CompoundItem_Main / EggItem / BookCaseItem |
| `0x40e208` | Sport_bar_1 / menu\skins\default\ / Sport_bar_2 / Sport_poise_1 / Sport_poise_2 / Panel_makeThingTimeForm_1 |
| `0x418b90` | Menu\Skins\White\Form_ServerList_1.jpg / icon_ServerSignal / bar_H4 / Btn_ArrowUp_1 / Btn_ArrowDn_1 / btn_Leave_1 |
| `0x4233b4` | Target team is full / Team is full / Target is busy cant join / Can't team, you haven't reached this floor yet / Can't team, player won more than you / Can't team, player haven't reached this floor yet |
| `0x432538` | Unbound Gate expansion not found / King's Glory exnapsion not found / Temple Guardian expansion not found / Fairy Whisper expansion not found / Dark Spell expansion not found / Stall is in use |
| `0x125204` | Capture String / Socket capture aborted / Accepting / Accepting Canceled / Error creating Data Connection / Socket send aborted |
| `0x139088` | Num_White5_1 / You Lose / You Win / You Lose / You Win / Can't create during TW |
| `0x14164c` | IM Points:  / Price per game  /  Points! / Tokens left: / Tokens per game  / Inv. full |
| `0x143470` | IM Points:  / Price per game  /  Points! / Tokens left: / Tokens per game  / Inv. full |
| `0x1464f8` | Price per game  / IM Points:  / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points /  Points! |
| `0x146758` | Price per game  / IM Points:  / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points /  Points! |
| `0x1469b8` | Price per game  / Tokens per game  / IM Points:  /  Points! / Tokens left: / Inv. full |
| `0x146cf0` | Price per game  / Tokens per game  / IM Points:  / Inv. full /  Points! / Tokens left: |
| `0x172b10` | PK unavailable here  / PK unavailable here  / No PK, transformed   / No PK while teamed   / #RInventory is full/#R / Insufficient activity, no chest awarded |
| `0x17d9f0` | Btn_ExitGuest_1 / Return / btn_Gobang_Exit / btn_Gobang_T / No players       / Enemy turn |
| `0x183730` | PokeGameBG / PokeCardBack / Icon_Currect_1 / Icon_Miss_1 / Poke_Text_Tc / PokeCard_ |
| `0x18937c` | psDash / You've lost. To continue register again / Quiz Event: / Quiz is at server branch 1 / [Quiz Event] Rankings:  / Timeout. Please retry               U |
| `0x18b310` | form_module_1 / Btn_Close_s_1 / editorBG / btn_module_1 / Garage / Content |
| `0x18dc78` | S10797 / sound\SEB0153.wav / S10241 / sound\SEB0031.wav / S10767 / sound\SEB0017.wav |
| `0x18e4d0` | TrunEggBG2 / TrunEggBG / TrunEggItemDB / TrunEggButton2 / TrunEggButton / TrunEggA |
| `0x191b70` | IM Points:  / Price per game  / Want to play? / Lucky7 tries amount  / Tokens left: / Tokens per game  |
| `0x1935c8` | Sorry, inventory is full! / Congrats! Can play free slots! / IM Points:  / Price per game  / Continue? / Lucky7 tries amount  |
| `0x1947ac` | IM Points:  / Price per game  / Want to play? / Lucky7 tries amount  / Tokens left: / Tokens per game  |
| `0x19944c` | icon_heart / animAtt / S10151 / MiniGame_Score_1 / MiniGame_Time_1 / MiniGame_Life_1 |
| `0x1a9bc4` | Form_Career / Btn_OK_1 / Btn_Cancel_1 / Btn_Close_S_1 / Icon_WarTotem / Icon_MagicTotem |
| `0x1b47e4` | Form_GasCan2 / Btn_Gas / Btn_Cancel_2 / Btn_Close_S_1 / Num_White3_1 / GasCanCap |
| `0x1b7438` | Memory card has experience value / Player is offline / Player is offline / Memory card has experience value / Can't use in battle / Can't remove during TW |
| `0x1c0204` | Form_ActionList_2 / Btn_Close_s_1 / Btn_Leave_1 / Arrow_L3 / Arrow_R3 / Btn_Transmi |
| `0x1c2464` | panel21 / btn_close_s_3 / Start:  / Area:  / LV Req:  / Desc:  |
| `0x1d77c8` |  Hp/Sp: Max /  Hp: Max / Basic Atk / Defense / Escape / <'<C<]<k< |
| `0x1de41c` | Btn_Close_s_1 / btn_close_1 / Btn_confirm_1 / SewingKitSpace / Form_SewingKit_1 / Form_WeaponMold_1 |
| `0x1e1d6c` | Form_SewingKit_2 / Btn_Close_s_1 / btn_close_1 / Btn_confirm_1 / Item_HighReduceItemSpace / No inventory space |
| `0x1e8c9c` | Not for mercenaries / No potential on this / Free 1 inventory slot to use / Factory Reset Potential / Not for mercenaries / No potential on this |
| `0x1e9f58` | Form_Pledge_1 / btn_close_1 / PledgeSpace / Item locked, can't use / Can't store item / Inventory is full |
| `0x1eb394` | Friends / System / Normal  / Unknown / yyyy"/"mm"/"dd hh:mm:ss / rail_H4 |
| `0x1f55e0` | Num_MainInfo / Icon_Element_0_1 / Icon_Element_1_1 / Icon_Element_2_1 / Icon_Element_3_1 / Icon_Element_4_1 |
| `0x1fc368` | Pet in Battle state / Set delivery target / Can't deliver. Player offline of don't exist / Not enough Gold / Delivery fee is  /  gold. Send it? |
| `0x1fd5ec` | TThread / Below LV10 can't use this / Insufficient online time / Can't set this item /  Hp/Sp: Max / Shoot RES |
| `0x201410` | Form_SelectMsgForm_1 / Btn_Close_S_1 / Btn_Cancel_1 / Btn_confirm_1 / btn_Check_1 / btn_UNCheck_1 |
| `0x20a1fc` | Form_Cupboard_2 / Btn_Close_S_1 / Btn_Close_1 / BookCaseItem / Full, can't store more / Icon_BookCase_1 |
| `0x20a7c0` | Form_Cupboard_2 / Btn_Close_S_1 / Btn_Close_1 / BookDeskItem / Full, can't store more / Icon_BookDesk_1 |
| `0x20c288` | Form_BlackBoard_1 / Btn_Close_S_1 / Btn_Close_2 / Btn_OK_2 / Btn_Delete_1 / Btn_Cancel_3 |
| `0x2177b0` | Form_CarCase / Btn_Close_S_1 / Btn_Close_1 / ParkCase / default\ / Form_Parkinglot |
| `0x21adcc` | Form_ATM_Transfer / Btn_Close_S_1 / Btn_List / btn_ok_1 / Btn_Cancel_1 / Panel26 |
| `0x222424` | Form_Exchange / Btn_Close_S_1 / Btn_Close_2 / Btn_ok_2 / default\ / Form_headling |
| `0x22dbd8` | [PVP Rank 1] / [PVP Rank 2] / [PVP Rank 3] / [PVP Rank 4] /  Server /  Event |
| `0x22ec40` | form_module_1 / Btn_Close_s_1 / btn_Rotate_1 / btn_Gather_1 / btn_Module_1 / SendData |
| `0x23bffc` | Bathing, unable to make / Only 1 item at time / Unable to make / Already 5 semi-finished crafts / Can't be zero / Needs Design |
| `0x23f564` | Form_HomeAdorn_1 / Btn_Close_1 / Btn_Close_s_1 / Btn_AddNew_1 / Btn_Move_1 / Btn_Remove_1 |
| `0x247ea8` | panel21 / Arrow_L2 / Arrow_R2 / btn_WantQuit / btn_WantConti / btn_GetBill |
| `0x249b1c` | btn_readme / btn_quit / panel16 / icon_price / BiDaXiao_Da / BiDaXiao_Xiao |
| `0x24f254` | Can't donate now / Can't donate now / Can't donate now / Can't donate now / Can't donate now / Can't donate now |
| `0x2597b4` | icon_sk / btn_blank1 / , can  / , consume SP / , press to upgrade / Requires  |
| `0x274278` | form_module / editorBG / Mount? / btn_module_1 / Riding / Cancel |
| `0x274d9c` | ]$SQRPj / Exit transport first / Passengers limit / Invited player in transport / Morphed player cant ride / Can't bathe now |
| `0x280198` | Hot Bar / Btn_Minimize_1 / Toggle View / HotKey / HotKeyPage_ / <'<C<]<k< |
| `0x294ea0` | Select friends to delete / Delete these friends? / Delete this friend? / btn_UnCheck_1 / btn_Check_1 / btn_UnCheck_1 |
| `0x29ad00` | Icon_Organ_1 / Form_setauthority_1 / Btn_Close_s_1 / Btn_OK_1 / Btn_Close_1 / btn_UnCheck_1 |
| `0x2ad138` | Form_ReFill_1 / icon_cancel_Disable / icon_close_Disable / btn_ok_1 / btn_cancel_1 / Btn_Close_s_1 |
| `0x2b0844` | Jump In / Spectate / Join Team / Make Friends / Guild Invite / Events |
| `0x2c3664` | Security Code is set / Security Lock will be active on next login / Open System > Security Lock and protect items / Secure Code & Del Pwd must not match / Secure Code & Pwd must not match / Failed to set Sec Code |
| `0x2c38dc` | Form_STUnLock / Btn_Close_S_1 / Btn_Close_1 / Btn_OK_1 / IDField / Use 6 to 10 chars and numbers |
| `0x2cfb94` | Form_SaleQ_Item / arrow_up1 / arrow_dw1 / btn_Sale / Btn_Close_1 / Btn_Close_s_1 |
| `0x2d0b58` | form_module / icon_inn / panel10 / Thanks! / Btn_Close_1 / Btn_Close_s_1 |
| `0x2d23c8` | form_module / panel10 / bar_H3 / rail_H3 / Btn_Close_s_1 / Btn_Close_1 |
| `0x2d55c8` | form_module / icon_Ability / bar_H3 / rail_H3 / Btn_Close_s_1 / Btn_Close_1 |
| `0x2d5c34` | form_module / icon_LoverName / editorBG / Btn_Close_s_1 / btn_ok_1 / btn_cancel |
| `0x3154a4` | form_module / panel8 / bar_H3 / rail_H3 / Btn_Close_s_1 / Btn_Close_1 |
| `0x324c70` | MiniMapForm / Btn_ArrowDn_2 / Btn_Minimize_1 / Minimize Map / Btn_Reload / Reload Mini-map |
| `0x328458` | Form_HotKey_Mini / Btn_Window_1 / Expand Map / _Mini_Form / Btn_Minimize_1 / Minimize map |
| `0x33eef4` | Form_BuyItemStall_1 / Btn_Buy_1 / Btn_Close_1 / Btn_Close_s_1 / ItemStallSelectedItem / <'<C<]<k< |
| `0x346bc4` | Icon_PetInCage / Form_BuyPet3Stall_1 / Btn_Buy_1 / Btn_CLose_1 / btn_close_s_1 / PetShadow |
| `0x3488cc` | Player is below LV25 / Not enough Gold / Feature disabled / Can't buy duplicated pet / Can't buy, Pet team full / Select pet to buy first |
| `0x349168` | icon_Card / VenderItemImage / Points Card / MyCard  / ItemStallSelectedItem / Private ShopSV |
| `0x370b88` | Bg_Asn / Bg_Samurai / Bg_Knight / Bg_Sage / Bg_Clergyman / Bg_Prophet |
| `0x3724a8` | Form_ThrowThing / Panel26 / btn_ok_1 / btn_Cancel_1 / Btn_ArrowL_5 / Btn_ArrowR_5 |
| `0x37dcec` | TUnDockEvent / No points to forget / Return 1 status point? / No points to forget / Can't return basic / Pick stat to add to |
| `0x3a4bb8` | Icon_Asn_2 / Icon_Samurai_2 / Icon_Knight_2 / Icon_Sage_2 / Icon_Clergyman_2 / Icon_Prophet_2 |
| `0x3cee2c` | Wrong Guild name / Not allowed to create / Repeatedly failures / Too many Guilds / Name already used / Unknown failure |
| `0x3d3b50` | Word_Red_64L / Word_Red_64U / Word_Orange_56L / Word_Orange_56U / Word_Pink_55L / Word_Pink_55U |
| `0x4414b4` | DragMode / wav000 / No pet to train / No training object / Pet training complete, level up to continue / Your training done, level up to continueSV |
| `0x453720` | Max number of items on floor / Can't drop items at home / Can't discard / You are below LV25! / Not enough online time! / Want to destroy this item? |
| `0x456b68` | Whisper / Alliance / GM Chat / Direct:  / System muted  / Banned by GMSVW |
| `0x471204` | Can't teleport from here / Forged / Too many players on map, animations reduced / Too many players on map, for stability animations reduced / Amount of players reduced. Animations fixed / Amount of players reduced. Animations fixed |
| `0x180fc` | Magellan MSWHEEL / MouseZ / MSWHEEL_ROLLMSG / MSH_WHEELSUPPORT_MSG / MSH_SCROLL_LINES_MSG |
| `0x108348` | olepro32.dll / OleCreatePropertyFrame / OleCreateFontIndirect / OleCreatePictureIndirect / OleLoadPicture |
| `0x11a7b8` | %20.0n / %20.0n / %20.1f / Stereo / MPGTools 1.8 |
| `0x1255a8` | Looking Up Error Message / Unknown Error No.  / Timer Triggered / Timer On / Timer Off |
| `0x125e88` | Data Available / Resolve Host / Host Lookup Timed Out / Host Lookup Canceled / Host Lookup Failed |
| `0x13c3a4` | Form_CarCase / Btn_Close_S_1 / Btn_Close_1 / CarCase / panel_restrainCarCase_1 |
| `0x13cc9c` | Form_NPCMake / Btn_Close_S_1 / Btn_Close_1 / Can't use when Trading    / Icon_PetStall_L_ |
| `0x13f1d4` | Item locked, can't use / No upgrade available / Inventory is full / Upgrade / Are you sure? |
| `0x1410bc` | IM Points:  / Play again? / Points used / Tokens left: / Token cost  |
| `0x141970` | IM Points:  / Playing with #RFun Token, Play Token/#R at event will not do / Payment Method? / Points / Price per game  |
| `0x1430d0` | IM Points:  / Play again? / Points used / Tokens left: / Token cost  |
| `0x14596c` | MarioGround / Mario_Up / Mario_Mid / Mario_Buttom / Mario_Bingo |
| `0x147a54` | IM Points:  / Play again? / Points used / Tokens left: / Need Tokens |
| `0x147d38` | IM Points:  / Play again? / Points used / Tokens left: / Need Tokens |
| `0x14a464` | Num_White5_1 / Num_YellowRed10_2 / sound\wav1607.wav / You Win / You Lose |
| `0x14db68` | Not enough token / Inv. full / sound\BGM0019.wav / Not enough Points! / Not enough token |
| `0x173d70` | ATK Up / DEF Up / MATK Up   / MDEF Up   / SPD Up |
| `0x1775c4` | Form_SetAccount / Btn_Close_S_1 / Btn_Close_1 / Btn_OK_1 / IDField |
| `0x180368` | Player left! / You Win  / sound\wav0153.wav / You Lose / sound\wav1607.wav |
| `0x182ca8` | IM Points:  / Price per game  /  Points! / Not enough Points! / Inv. full |
| `0x1845d4` | IM Points:  / Price per game  /  Points! / Tokens left: / Tokens per game  |
| `0x18fdfc` | Btn_Leave_1 / Btn_LuckyStar / Left-click to use / Icon_LSUse / Icon_LSNoUse |
| `0x1913c0` | SlotmachBG / SlotmachItemT / SlotmachBtnBG / SlotmachRing / SlotmachText |
| `0x192e24` | SlotmachBG / SlotmachItemT / SlotmachBtnBG / SlotmachRing / SlotmachText |
| `0x193c5c` | sound\wav9915.wav / Obtain  / sound\wav0152.wav / Sorry, inventory is full! / Congrats! Can play free slots! |
| `0x1944b0` | SlotmachBG / SlotmachItemT / SlotmachBtnBG / SlotmachRing / SlotmachText |
| `0x198ae0` | Color_R / Sound\SEB0173.wav / Sound\SEB0221.wav / Sound\SEB0156.wav / Sound\SEB0199.wav |
| `0x1a26bc` | Icon_Element_0_1 / Icon_Element_1_1 / Icon_Element_2_1 / Icon_Element_3_1 / Icon_Element_4_1 |
| `0x1a2ef0` | Defeated / Complete  / Goal:  / Not Started / Not entered yet |
| `0x1a7d08` | Grats [ /  is new Castle owner / Guild [ /  conquered unoccupied Castle / Trojan War has ended! Come again next week. |
| `0x1ac7c4` | Job is not selected / Stat points have to be allocated / Job is not selected / Stat points have to be allocated / Job's cape must be in inventory |
| `0x1aed4c` | Form_EightTwelve / NpcStoreSelectedItem / Btn_Buy_1 / Btn_Close_1 / Btn_Close_S_1 |
| `0x1b9e10` | Can't do in battle / Target offline / Target player on diff branch / Cancel leveling?S / Target offline |
| `0x1c8a68` | Icon_Heart / Icon_Element_3_1 / S10203 / S10004 / Str_Bar |
| `0x1cc0b8` | Btn_Leave_1 / ThrowGame_Exit_Btn / HitMouse_Exit_Btn / Hunting_Exit_Btn / MiniGame_Exit_Btn |
| `0x1da850` | Form_FixTraffic / Btn_Close_s_1 / Btn_Close_2 / Btn_OK_2 / FixTrafficSpace |
| `0x1dce58` | Form_StallCase_1 / Btn_Close_s_1 / btn_close_1 / Btn_setup_1 / StallCase |
| `0x1e2c88` | Form_Reinforce_1 / Btn_Close_s_1 / Btn_Cancel_3 / Btn_OK_2 / Item_ReinforceSpace |
| `0x1ec510` | user\Server / \MailBoxMsgLog / \MailData.dat / \BKMailData.dat / Can't retrieve now |
| `0x1ed7bc` | user\Server / \MailBoxMsgLog / \MailData.dat / Can't save file / \BKMailData.dat |
| `0x1f5168` | Form_Cellection_1 / Btn_Close_1 / Btn_Close_s_1 / Btn_ArrowR_8 / Btn_ArrowL_8 |
| `0x20211c` | Form_setPrice_1 / Btn_Cancel_1 / Btn_confirm_1 / Btn_ArrowR_5 / Btn_ArrowL_5 |
| `0x206a58` | Gachapon below 10  / Stop sale to change price / Bid price is incorrect / Gachapon min qty is 10 per item / Confirm to set a price per spin |
| `0x207804` | Form_EggMachine_1 / Btn_Close_S_1 / Btn_Close_2 / Btn_OK_2 / EggItem |
| `0x208130` | Form_Bed_1 / Btn_Close_S_1 / Btn_Close_1 / Btn_ArrowL_8 / Btn_ArrowR_8 |
| `0x20c68c` | Input message / Don't use Illegal words / Message being edited / Select a message  / You are not author |
| `0x210fa8` | Can't fix in battle / Nothing inserted / Gem rank is too high / Free 1 inventory slot to use / sound\wav0152.wav |
| `0x218148` | Can't use Garage / sound\wav0152.wav / Parking is full / Riding Vehicle, can't use / Not enough Pts. |
| `0x21b2b0` | Can't be blank / Can't be zero / Not enough / Can't transfer, player offline / Transfer  |
| `0x222f08` | Pay ATM 1000g fee / ATM is busy, can't use / ATM 1000g fee received / Gold limit overflow, 1000g fee transferred to ATM / Not opened |
| `0x227ef0` | Form_mobile / Arrow_L3 / Arrow_R3 / Btn_Close_s_3 / Btn_Close_1 |
| `0x2298a4` | From_PetUp / Btn_Close_S_1 / rand_pet / Btn_OK_1 / Btn_Close_1 |
| `0x2339a8` | Strength influences basic physical damage and physical skill / Constitution increases maximum health (HP) and basic defense / Intelligence determines magical skills damage and sealing sk / Wisdom increases maximum mana (SP), defense against magic at / Agility determines movement order in battle and ability to p |
| `0x2378b8` | user\save / MiddleCompoundUse / MiddleCompoundUse= / HighCompoundUse / HighCompoundUse= |
| `0x240c64` | Form_Module_1 / Btn_Close_1 / Btn_Close_s_1 / Btn_ArrowL_5 / Btn_ArrowR_5 |
| `0x2419ec` | Panel_RestrainBank_1 / Form_ThingGrid5x5_1 / Btn_Close_1 / Btn_Close_s_1 / ItemImage |
| `0x24a19c` | form_module / Btn_Close_1 / Panel10 / bar_h4 / rail_H4 |
| `0x24d880` | Form_Warehouse / Btn_Close_s_1 / Btn_Close_1 / btn_Bank_Gold_R / btn_Bank_Gold_L |
| `0x257018` | Can't learn Earth skill / Can't learn Water skill / Can't learn Fire skill / Can't learn Wind skill / Form_SkillTree |
| `0x262240` | EStringListError / Can't use on it / Trying [ / Trial [ / ] taken off |
| `0x269eb0` | Enter name first / List is full / Player already blacklisted / Can't blacklist GM / Select a name to remove |
| `0x274054` | form_module / editorBG / Take active NPC? / btn_module_1 / Cancel |
| `0x2771ec` | Form_ThrowMoney / btn_ok_1 / btn_Cancel_1 / Arrow_L3 / Arrow_R3 |
| `0x2842d0` | form_Moral / Faction / icon_08 / Btn_Close_s_1 / Btn_Close_1 |
| `0x28b6dc` | Pick members first / Remove selected members? / Remove this member? / btn_UnCheck_1 / btn_UnCheck_1 |
| `0x2999f4` | hotkey / btn_Action_13 / btn_Action_ / Btn_on_1 / Btn_off_1 |
| `0x29b16c` | EStringListError / btn_Check_1 / btn_UnCheck_1 / btn_UnCheck_1 / btn_Check_1 |
| `0x29bbb0` | Icon_Organ_1 / Form_MYauthority_1 / Btn_Close_s_1 / Btn_Close_1 / icon_check_1 |
| `0x2ada38` | form_module / editorBG / btn_ok_1 / btn_cancel / Enter iCafe num |
| `0x2b5774` | Icon_Forbid_2 / Form_BattleSkill_1 / Btn_ArrowUp_1 / Btn_ArrowDn_1 / Btn_Close_1 |
| `0x2bc334` | Basic Atk / Defense / Ranged / Nearby / Life Skill |
| `0x2bfdb8` | Can't be blank / Can't use on this / Can't use when pet active / Can't use when mounted / Item [%s] is non-tradeable. Can't be used |
| `0x2cba24` | Form_ReceiveReward / Btn_Close_S_1 / btn_close_1 / Btn_Reward / Free some inventory space to receive reward |
| `0x2cce00` | form_module / editorBG / btn_module_1 / Del Mark / Add TagO |
| `0x2cf8d0` | panel15 / editorBG / btn_module_2 / Deducted  / Increased  |
| `0x2d4e8c` | form_module / bar_H3 / rail_H3 / Btn_Close_s_1 / Btn_Close_1 |
| `0x30b980` | Form_onLineInfo_1 / txt\charge.txt / Btn_Close_s_1 / Btn_ChangeMode_1 / btn_Close_1 |
| `0x30d560` | form_module / btn_module_1 / Cancel / editorBG / Newbie |
| `0x31303c` | Player offline / Remove Vice Leader? / Remove this member? / Btn_ArmyList2_ / Btn_ArmyList2 |
| `0x3142b4` | Form_CreatArmyGroup_1 / btn_ok_1 / Btn_Cancel_1 / Unavailable at Interserver / Don't use Illegal words |
| `0x31778c` | No guild allies / Our allies / Other allies / No ally / %-14s %-10s %3s %-14s |
| `0x32804c` | _Mini_Form / Btn_Minimize_1 / Minimize Map / Btn_Reload / Reload Mini-map |
| `0x333e30` | Form_Trade / Btn_Close_s_1 / btn_BothOk / btn_Trade / btn_Cancel |
| `0x336a20` | Insufficient LV / Close Stall first / Target uses Stall / Non-tradeable / Feature disabled |
| `0x34cd54` | \Data\Talk.Dat / Talk.Dat Missing / <Error In Talk.Dat> / Error in Talk.Dat file Dupe ID Found / Yes, Please Fix!!! |
| `0x35da30` | icon_Skin_1 / form_module_1 / panel10 / Btn_Close_s_1 / Btn_Close_1 |
| `0x383a48` | Btn_Buy_1 / Form_EquipStore_1 / Form_ThingStore_1 / Form_ActivityExchange / Btn_Exchange_1 |
| `0x3bf020` | panel15 / editorBG / btn_module_1 / Update / Finish |
| `0x3d1a0c` | join as Ally / refused Ally /  ignore / Ally failed / Target's ally off |
| `0x3fa6e0` | GdMoney1 / GdMoney2 / GdMoney3 / GdMoney4 / GdMoney5 |
| `0x3fa990` | GdMoney1 / GdMoney2 / GdMoney3 / GdMoney4 / GdMoney5 |
| `0x3fab64` | GdMoney1 / GdMoney2 / GdMoney3 / GdMoney4 / GdMoney5 |
| `0x41fe5c` | \Data\Mark.Dat / Mark.dat Missing / <Error In Mark.dat> / Failed To Read Mark.dat Dupe ID's / Yes, Please Fix!!! |
| `0x442d6c` | Matchmaking in progress... / Solo PVP Matchmaking... / Team PVP Matchmaking... / 4-PVP Matchmaking... / Canceled |
| `0x471f3c` | Adv Level / Adv Level? / Adv Level?? / %s gift / Np inventory space |
| `0x472ed4` | Incompatible weapon / Insufficient SP / Wrong EXCEL file / Skill file doesn't exist / Can't use skill |
| `0x5a730` | clInactiveCaption / PixelsPerInch / TextHeight / IgnoreFontProperty |
| `0x75950` | IDirect3DDevice3 / Direct3DRMCreate / D3DRM.dll / IDirect3DRMDevice2 |
| `0x1198d4` | NEWLINE / SOFTNEWLINE / is NoExec Item! /  association error!!!  |
| `0x11a444` | yyyymmddhhnnss / %20.0n / %20.1n / %20.1n |
| `0x12941c` | SET-COOKIE: / LOCATION: / CONTENT-LENGTH: / ENGTH: |
| `0x13acd0` | form_module_1 / Btn_Close_s_1 / editorBG / btn_module_1 |
| `0x13f5d8` | GlobaMap / Btn_Close_s_3 / GlobaBtn / Med. Sea |
| `0x13fb1c` | CatchButton / L Shift / R Shift / Hunting_Exit_Btn |
| `0x140f48` | Not enough Points! / Inv. full / sound\BGM0019.wav / Minimize Map |
| `0x142dd0` | Got reward:  / Consolation: / Game Result:  / sound\wav0152.wav |
| `0x1441e8` | Leave the game? / Leave the game? / Leave the game? / The result based on score |
| `0x145284` | IM Points:  / Price per game  /  Points! / Inventory Full |
| `0x148e74` | ]$SQRPj / sound\9912.wav / sound\9911.wav / sound\wav0152.wav |
| `0x14d4e8` | IM Points:  / Price per game  /  Points! / Tokens left: |
| `0x150878` | Unable to query / Confirm use  / Check mats? / Lack of pts, can't check |
| `0x1529c8` | Welcome to [ /  Server / \Pic\Grid.bmp / btn_UnCheck_1 |
| `0x156ba8` | Can't exit here / Taking tent back will stop crafting / btn_Abort_1 / Moving will pause crafting |
| `0x159234` | TeamStatus:  / LeaderID:  / PartnerNum:  / NpcCount:  |
| `0x163b64` | Sound\BGM0013.wav / No quest record, can't trigger event / Moving will pause crafting / btn_Abort_1 |
| `0x175d10` | Code changed / Secure Code & Del Pwd must not match / Secure Code & Pwd must not match / Wrong Pwd |
| `0x177c98` | Success. Use new name to login again / Pwd or Del Pwd is incorrect / Account is in use. Reset it / Setting failed. Reset itU |
| `0x179024` | BGM0011.WAV / 9911.WAV / Sound\ / BGM0011 |
| `0x17cc0c` | TCustomMemo / sound\BGM0019.wav / sound\wav0145.wav / sound\wav1610.wav |
| `0x1820ac` | DigHole / DigHole_Hole / DigHole_Finger / icon_dig_1 |
| `0x18edd8` | sound\wav9913.wav / Obtain  / sound\wav0152.wav / sound\wav9911.wav |
| `0x1967f4` | sound\SEB0027.wav / sound\SEB0018.wav / sound\SEB0033.wav / sound\SEB0039.wav |
| `0x197a9c` | sound\SEB0027.wav / sound\SEB0018.wav / sound\SEB0033.wav / sound\SEB0039.wav |
| `0x1986c0` | Num_White5_1 / panel20 / icon_SP1 / You Lose |
| `0x19db54` | Form_DupEnterMsg / Btn_Cancel_1 / Btn_OK_1 / Btn_Close_s_1 |
| `0x19f754` | EStringListError / LV Req:  / Players:  / Guild:  |
| `0x1a0380` | Creator left / Guild:  / Creator: / Info:  |
| `0x1a68ac` | Grats [ /  is new Castle owner / No guild own Castle / Area will be cleared in 5 mins. Leave area before that. |
| `0x1a7190` | broken /  def decreased / City def items destroyed / City defense  |
| `0x1ab7f4` | Form_BeforeCareer / Btn_OK_1 / Btn_Cancel_1 / Btn_Close_S_1 |
| `0x1ac9f0` | Form_Repair / Btn_OK_2 / Btn_Cancel_3 / SelectUitem |
| `0x1b1164` | Poke_Exit_Btn / form_module_1 / Btn_Close_s_1 / btn_module_1 |
| `0x1b5634` | Can't use now / Not reusable / Can't transform / Can't use now |
| `0x1b8750` | Cancel leveling?S / Can't do in battle / Target offline / Target player on diff branch |
| `0x1bf314` | Enter the name / Player offline of don't exist / btn_Check_1 / btn_UnCheck_1 |
| `0x1bfd7c` | Form_DupEnterMsg / Btn_Cancel_1 / Btn_OK_1 / Btn_Close_s_1 |
| `0x1c2fb0` | Form_Picnic / Btn_Cancel_1 / PicnicBoxCase / In use, can't use again |
| `0x1cdde8` | Sound\Wav1611.wav / Sound\SEB0008.wav / Num_White5_1 / Num_YellowRed10_2 |
