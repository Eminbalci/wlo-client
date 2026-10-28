# Technical Documentation: Network Protocol & Stream Framing

## 1. Wire Protocol Framing
The Wonderland Online wire protocol uses a 4-byte little-endian header followed by an encrypted payload:
```
[0x00..0x01]: 0x44F4 (Magic Header Sentinel: bytes 0xF4, 0x44 in Little-Endian)
[0x02..0x03]: Payload Length (uint16 little-endian)
[0x04..(N+3)]: Encrypted Payload Bytes (N bytes, up to 16,384 bytes)
```

## 2. Cryptographic Obfuscation (`NetworkManager` / `WloCrypto`)
Packets are transformed across the entire wire stream (Magic Header, Payload Length, and Payload) using a symmetric static XOR cipher:
- Symmetric XOR Key: `0xAD`
- Transformation:
  ```
  wire_byte = plaintext_byte ^ 0xAD
  plaintext_byte = wire_byte ^ 0xAD
  ```
- Magic Wire Signature:
  - Byte 0: `0xF4 ^ 0xAD = 0x59`
  - Byte 1: `0x44 ^ 0xAD = 0xE9`
  - All valid frames transmitted or received begin on wire with `0x59, 0xE9`.

## 3. Protocol Handshake & Authentication Flow
1. **Initial Connection**:
   - Client connects via StreamPeerTCP to `20.187.103.41:6414` (Rhodes1).
2. **Keepalive / Ping**:
   - Server sends `Action 0xBA, Subcode 0x10, Status 0x00`.
   - Client automatically responds with ping pong `[0xBA, 0x10, 0x00]`.
3. **Authentication (Action 0x3F, Subcode 0x04)**:
   - Client sends:
     `[0x3F, 0x04, ClientVersion (uint16 1214), len(user), user, len(pass), pass, extra_bytes]`
     where `extra_bytes = [0x07, 0x53, 0x60, 0x60, 0x63, 0x67, 0x63, 0x61, 0x65]`.
   - Server returns:
     - Action 0x3F, Subcode 0x02: User ID assignment (`login_succeeded`).
     - Action 0x3F, Subcode 0x01: Character List records (`character_list_received`).
     - Action 0x01, Subcode 0x0C: Invalid credentials (`login_failed`).
4. **Character Creation**:
   - Request Create: Action `0x3F`, Subcode `0x02`, Slot (`0x01`).
   - Server ACK: Action `0x01`, Subcode `0x03`, Status (`0x00` = success).
5. **World Entry**:
   - Client sends Action `0x3F`, Subcode `0x02` with selected slot.
   - Server responds with Game World initialization packets: Actions `0x14` (20), `0x05`, `0x03`, `0x04` (`world_entered`).
