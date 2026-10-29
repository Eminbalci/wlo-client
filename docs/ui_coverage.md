# Real-client windows vs. the Godot client

Source: every `Form_*` skin name referenced in `D:/GitHub/WLRI/aLogin.exe` (165 base names, 2026-10-29), matched against
`scripts/` and `scenes/` (tools and tests excluded). A window counts as present when a Godot script or scene references its skin.
Some windows may exist under another skin name (for example the combat settings window uses `BattleStatus_1`); recheck before building.

## Present (15)
Form_RoleStatus (character), Form_ThingGrid5x5 (inventory), Form_Skill, Form_Team, Form_Friend, Form_System, Form_Compound,
Form_ThingStore (shop), Form_Talk (dialogue), Form_NoteBook and Form_Cellection (notebook / collection), Form_HotKey (hotbar),
Form_ServerList, Form_SelectRole, Form_CreateRole.

## Missing, by priority

### P1: needed for the beginner island and Kelan Village
| Window | Purpose |
|---|---|
| Form_PetStatus | pet / companion status |
| Form_Trade, Form_TradeItem, Form_TradePet | player trade |
| Form_Warehouse | item storage |
| Form_Repair | equipment repair |
| Form_World, Form_GPS | world map, coordinates / navigation |
| Form_Potential | potential (item window button) |
| Form_PlayerTitle | titles |
| Form_MailBox, Form_MailSend | mail |
| Form_channel | chat channel picker |
| Form_SkillTree, Form_SkillTree1, Form_BattleSkill | skill tree, battle skill picker |
| Form_Emotion | emote picker |
| Form_Huminfo, Form_ActionList | other player's info, action menu |
| Form_ThrowThing, Form_ThrowMoney, Form_pickup | drop item / gold, pick up |
| Form_EquipStore, Form_Shopping, Form_Buy, Form_ShoppingCar | other store types |
| Form_Inn, Form_Medical | inn, doctor |
| Form_ReceiveReward, Form_ExpBox | rewards |

### P2: mid game
Jobs (Form_Career, Form_BeforeCareer), crafting (Form_MakeThing, Form_MakeThingInfo, Form_NPCMake, Form_blueprint, Form_Alchemist,
Form_Reinforce, Form_dismantle, Form_WeaponMold, Form_SewingKit, Form_Pattern), guild (Form_ChooseCooperation, Form_CreateCooperation,
Form_CooperationTeam, Form_ArmyGrounp, Form_ArmyGrounpInfo, Form_CreatArmyGroup, Form_OrgNotice, Form_Emblem, Form_MYauthority,
Form_setauthority, Form_EditRule), instances (Form_DupChoose, Form_DupDetail, Form_DupEnterMsg, Form_DupInnerInfo, Form_DupInnerMember,
Form_CreateDupMis: the Group window's Instance tab), PvP (Form_PlayerBattleMain, Form_PlayerBattleBG, Form_PlayerBattleRank,
Form_MyPlayerBattleRank, Form_PlayerBattleSetting), Form_Top100, Form_Marry, Form_Divorce, Form_Pledge, Form_PetCage,
Form_ConfuseStone, Form_Conundrum, Form_Magnet, Form_Capsulem.

### P3: housing, stalls, vehicles, account and mall
Housing (Form_HomeAdorn, Form_BuyItemInHome, Form_Bed, Form_Cabinet, Form_Cupboard, Form_IceBox, Form_Computer, Form_Display,
Form_TryClotheRoom, Form_Picnic, Form_BlackBoard), vehicles (Form_Garage, Form_Parkinglot, Form_CarCase, Form_GasCan2,
Form_SmallGasCan, Form_StoreTank, Form_FixTraffic, Form_ReFill), stalls and sales (Form_StallCase, Form_BuyItemStall,
Form_BuyPet1/2/3Stall, Form_CardStall, Form_KeepItemStall, Form_KeepPETStall, Form_KeepUtensilStall, Form_Buy1Utensil,
Form_Buy3Utensil, Form_Sale, Form_SaleEquip, Form_SaleNet, Form_SaleQ, Form_SaleThing, Form_setPrice, Form_Business,
Form_Packing, Form_Express, Form_Vendingmachine), banking and exchange (Form_ATM, Form_BankMoney, Form_itemBank, Form_Exchange,
Form_Exchange2, Form_ExchangeLock*, Form_GiftExchange, Form_ActivityExchange), mini games (Form_Ante, Form_LotteryOL,
Form_EggMachine, Form_TurnGame, Form_EightTwelve), account (Form_ChangePassword, Form_ChangeRoleName, Form_ChangeColor,
Form_IdPassword, Form_InputPw, Form_SetAccount, Form_STSetPwd, Form_STUnLock, Form_MemCard2, Form_mobile), misc (Form_VIP,
Form_AutoPlayerPlus, Form_InsteadEcis, Form_Module, Form_Property, Form_SelectMsgForm, Form_onLineInfo, Form_headling,
Form_setup, Form_BodyOff, Form_UtensilStall).
