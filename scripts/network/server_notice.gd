class_name ServerNotice
extends RefCounted

## Reason texts of action 0 (server notice / disconnect) in the real client.
## Decoded from aLogin.exe: dispatcher 0x2de1d4, second-level switch table at 0x2de481
## (sub code = second payload byte, 0..0x52). See docs/re/protocol.md.

const TEXTS: Dictionary = {
	0: "Connection lost",
	1: "Too Many Packets",
	2: "Fail Q&A 3 Times",
	3: "Wrong Pwd",
	4: "Disconnected",
	5: "Illegal Activity #1",
	6: "Illegal Activity #2",
	7: "Event Error",
	8: "Incorrect Trigger",
	9: "Wrong Event Table",
	10: "Table Error",
	11: "Illegal Press",
	12: "Illegal Press",
	13: "Movement Too Fast",
	14: "Movement Too Fast",
	15: "Delete Successful",
	16: "Blocked IP Detected",
	17: "Update Game Files",
	18: "Data Altered",
	19: "Repeated Login",
	20: "Abnormal D/c",
	21: "Abnormal Safe File Data",
	22: "Invalid Packet Data",
	23: "Password Too Short",
	24: "Password Too Short",
	25: "Duplicated Name",
	26: "Event Trigger Error",
	27: "Login Error D/c",
	28: "Too Much Data",
	29: "Too Much Data",
	32: "Scene Error",
	33: "Scene Error",
	34: "Other Server Login",
	35: "Confirm Licence",
	36: "Invalid ID",
	37: "Scene Changed",
	38: "Wrong Target Scene",
	39: "Connection lost",
	40: "Packet Manipulation",
	41: "Battle Error",
	42: "Battle Error",
	43: "Battle Error #0",
	44: "Wrong Tigger Scene",
	45: "Account Banned",
	46: "Battle End Error",
	47: "Battle End Error",
	48: "Use illegal Skill",
	49: "Under 18 y/o Curfew",
	50: "Log into PVP Server",
	51: "Can't Login PVP Server",
	52: "Can't Login PVP Server",
	53: "Server Not Open Yet",
	54: "Left PVP Event",
	55: "No Transport On World Map",
	56: "Password Too Long",
	57: "Pwd & Del Pwd match",
	58: "Beta Access Error",
	59: "Relay Server D/c",
	60: "Connection lost",
	61: "Server Is Busy",
	62: "Incorrect Password",
	63: "Mini-Game Error D/c",
	64: "Wrong Version",
	65: "Wrong Version",
	66: "IP Zone Blocked",
	67: "External D/c",
	68: "Battle Protocol Error",
	69: "Battle Protocol Error",
	70: "Firewall Triggered",
	71: "Teleport Exploit",
	72: "Item.dat File Error",
	73: "Instance map purged",
	74: "Interserver D/c",
	75: "Max Logins Reached",
	76: "Event Violation",
	77: "IP Blocked",
	78: "IP Blocked",
	79: "Routing Error, Wait",
	80: "Acct Locked",
	81: "Log in again later",
	82: "Connection lost",
}

## Sub code 15 is the confirmation of a character deletion, not an error.
const DELETE_SUCCESS: int = 15


static func text_for(sub_code: int) -> String:
	return str(TEXTS.get(sub_code, "Connection lost"))


static func is_error(sub_code: int) -> bool:
	return sub_code != DELETE_SUCCESS
