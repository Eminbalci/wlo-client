class_name CreateRequest
extends RefCounted

## Builds the server create-character packet from a locally created character (see CharacterManager).
## The local slot is 0-based, the server's is 1..2. Element names map to the server's codes
## (Earth 1, Water 2, Fire 3, Wind 4). The deletion-code hash travels as the optional trailing string.

const ELEMENT_CODES := {"earth": 1, "water": 2, "fire": 3, "wind": 4}


static func element_code(element: Variant) -> int:
	if element is int:
		return clampi(int(element), 1, 4)
	return int(ELEMENT_CODES.get(str(element).to_lower(), 3))


static func server_slot(local_slot: int) -> int:
	return clampi(local_slot + 1, 1, 2)


static func payload_from_character(char_data: Dictionary) -> PackedByteArray:
	return NetworkManager.build_create_payload(
		server_slot(int(char_data.get("slot_index", 0))),
		str(char_data.get("name", "")),
		int(char_data.get("role_id", 1)),
		element_code(char_data.get("element", "Fire")),
		int(char_data.get("str", 10)),
		int(char_data.get("con", 10)),
		int(char_data.get("int", 10)),
		int(char_data.get("wis", 10)),
		int(char_data.get("agi", 10)),
		str(char_data.get("deletion_code_hash", "")))
