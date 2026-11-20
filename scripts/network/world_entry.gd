class_name WorldEntry
extends RefCounted

## Parsers for the packets the C# server sends when a character enters the world (verified against a
## live capture). Both carry data the world scene should start from instead of local defaults.
##
## Spawn (action 3): [3, char id u32, 1, map u16, x u16, y u16, ...]. The byte after the action is the
## low byte of the character id, not a sub code.
## Inventory (AC23:5): [23, 5, entries...]. Each entry is 31 bytes: slot u8 (1..50), item id u16,
## amount u8, damage u8, 26 bytes of item metadata (live capture: 8 entries in a 250-byte packet). The server may split the list across several
## packets, so entries carry their own slot and are merged by slot. The amount is what the packet ADDS to
## the slot (the first full list adds to an empty bag); AC23:9 removes an amount from a slot.

const ENTRY_SIZE := 31


## Returns {char_id, map, x, y} or {} when the packet is not a spawn packet.
static func parse_spawn(payload: PackedByteArray) -> Dictionary:
	if payload.size() < 12 or payload[0] != 3 or payload[5] != 1:
		return {}
	return {
		"char_id": payload.decode_u32(1),
		"map": payload.decode_u16(6),
		"x": payload.decode_u16(8),
		"y": payload.decode_u16(10),
	}


## Returns [{slot, id, count, damage}] for the complete entries; a trailing partial entry is ignored.
static func parse_inventory(payload: PackedByteArray) -> Array:
	var out: Array = []
	if payload.size() < 2 or payload[0] != 23 or payload[1] != 5:
		return out
	var offset := 2
	while offset + ENTRY_SIZE <= payload.size():
		var slot := int(payload[offset])
		var item_id := payload.decode_u16(offset + 1)
		if slot >= 1 and slot <= 50 and item_id != 0:
			out.append({"slot": slot, "id": item_id, "count": int(payload[offset + 3]), "damage": int(payload[offset + 4])})
		offset += ENTRY_SIZE
	return out


## Removal: AC23:9 [23, 9, slot u8, removed u8]. Returns {slot, count} or {}.
static func parse_inventory_removal(payload: PackedByteArray) -> Dictionary:
	if payload.size() < 4 or payload[0] != 23 or payload[1] != 9:
		return {}
	return {"slot": int(payload[2]), "count": int(payload[3])}


## Character stats: AC5:3 [5, 3, element u8, hp u32, sp u16, CON u16, INT u16, STR u16, AGI u16,
## WIS u16, level u8, exp u32, max hp u16, max sp u16, ...]. The attribute order was read from a live
## capture of a character created with STR 6, CON 7, INT 8, WIS 9, AGI 10, which came back 7, 8, 6, 10, 9.
## Returns {} when the packet is not a stats packet.
static func parse_stats(payload: PackedByteArray) -> Dictionary:
	if payload.size() < 28 or payload[0] != 5 or payload[1] != 3:
		return {}
	return {
		"element": int(payload[2]),
		"hp": payload.decode_u32(3),
		"sp": payload.decode_u16(7),
		"con": payload.decode_u16(9),
		"int": payload.decode_u16(11),
		"str": payload.decode_u16(13),
		"agi": payload.decode_u16(15),
		"wis": payload.decode_u16(17),
		"level": int(payload[19]),
		"exp": payload.decode_u32(20),
		"max_hp": payload.decode_u16(24),
		"max_sp": payload.decode_u16(26),
	}
