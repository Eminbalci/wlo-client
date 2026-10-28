class_name PacketFramer
extends RefCounted

## Handles wire packet framing for the Wonderland Online client protocol.
## Wire format:
## [0x00..0x01]: 0x44F4 (Magic Header Sentinel, 0xF4, 0x44 Little-Endian)
## [0x02..0x03]: Payload Length (UInt16 Little-Endian)
## [0x04..(N+3)]: Encrypted Payload Bytes (N bytes)

const MAGIC_HEADER: int = 0x44F4
const HEADER_SIZE: int = 4
const MAX_PAYLOAD_SIZE: int = 16384

## Wraps an encrypted payload in a 4-byte wire frame header.
static func frame(payload: PackedByteArray) -> PackedByteArray:
	if payload.size() > MAX_PAYLOAD_SIZE:
		push_error("[PacketFramer] Payload size %d exceeds limit of %d" % [payload.size(), MAX_PAYLOAD_SIZE])
		return PackedByteArray()
	
	var buffer := PackedByteArray()
	buffer.resize(HEADER_SIZE + payload.size())
	buffer.encode_u16(0, MAGIC_HEADER)
	buffer.encode_u16(2, payload.size())
	
	for i in range(payload.size()):
		buffer[HEADER_SIZE + i] = payload[i]
	
	return buffer

## Convenience method to frame a Packet instance directly.
static func frame_packet(packet: Packet) -> PackedByteArray:
	if not packet:
		return PackedByteArray()
	return frame(packet.get_buffer())

## Attempts to extract a complete wire frame from a raw stream buffer.
## Returns a Dictionary with:
## - "success": bool
## - "payload": PackedByteArray (encrypted payload bytes)
## - "consumed_bytes": int (how many bytes to discard from buffer)
static func try_extract_frame(buffer: PackedByteArray) -> Dictionary:
	var result := {
		"success": false,
		"payload": PackedByteArray(),
		"consumed_bytes": 0
	}
	
	var search_offset: int = 0
	while search_offset + HEADER_SIZE <= buffer.size():
		var magic := buffer.decode_u16(search_offset)
		if magic == MAGIC_HEADER:
			var payload_len := buffer.decode_u16(search_offset + 2)
			if payload_len > MAX_PAYLOAD_SIZE:
				search_offset += 1
				continue
			
			var total_frame_size := HEADER_SIZE + payload_len
			if buffer.size() - search_offset < total_frame_size:
				# Awaiting remaining bytes
				result["consumed_bytes"] = search_offset
				return result
			
			# Complete frame present
			result["success"] = true
			result["payload"] = buffer.slice(search_offset + HEADER_SIZE, search_offset + total_frame_size)
			result["consumed_bytes"] = search_offset + total_frame_size
			return result
		
		search_offset += 1
	
	result["consumed_bytes"] = search_offset
	return result

## Extracts authentic XOR-encrypted wire frames: [wire bytes ^ key] -> [0xF4, 0x44] [len] [payload].
static func try_extract_wire_frame(wire_buffer: PackedByteArray, key: int = 0xAD) -> Dictionary:
	var plain := PackedByteArray()
	plain.resize(wire_buffer.size())
	for i in range(wire_buffer.size()):
		plain[i] = wire_buffer[i] ^ key
	return try_extract_frame(plain)
