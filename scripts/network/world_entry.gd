class_name WorldEntry
extends RefCounted

## Parsers for the packets the C# server sends when a character enters the world (verified against a
## live capture). Both carry data the world scene should start from instead of local defaults.
##
## Spawn (action 3): [3, char id u32, 1, map u16, x u16, y u16, ...]. The byte after the action is the
## low byte of the character id, not a sub code.
## Inventory (AC23:5): [23, 5, entries...]. Each entry is 31 bytes: slot u8 (1..50), item id u16,
## amount u8, damage u8, 26 bytes of item metadata (live capture: 8 entries in a 250-byte packet). The server may split the list across several
## packets, so entries carry their own slot and are merged by slot.

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
