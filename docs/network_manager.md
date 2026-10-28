# Authentic Wonderland Online Live Network Client Specification

## 1. Executive Summary

This document specifies the authentic Wonderland Online live network protocol implementation in [`scripts/network/network_manager.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/network/network_manager.gd). The protocol was reverse engineered from official binary traffic against production server Rhodes1 (`20.187.103.41:6414`).

---

## 2. Wire Framing & Binary Specifications

### 2.1 Wire Packet Framing
Every packet transmitted over TCP consists of a 4-byte header followed by the payload:
```
[0x00..0x01]: 0x44F4 (Magic Header Sentinel: bytes 0xF4, 0x44 in Little-Endian)
[0x02..0x03]: Payload Length (uint16 Little-Endian)
[0x04..(N+3)]: Payload Bytes (N bytes, up to 16,384 bytes)
```

### 2.2 Symmetric XOR Keystream Obfuscation
The entire stream (Magic Header, Payload Length, and Payload) is XOR-encrypted symmetrically with static key `0xAD`:
- Encryption:
  ```
  wire_byte = plaintext_byte ^ 0xAD
  ```
- Decryption:
  ```
  plaintext_byte = wire_byte ^ 0xAD
  ```
- Header Wire Signature:
  - Byte 0: `0xF4 ^ 0xAD = 0x59`
  - Byte 1: `0x44 ^ 0xAD = 0xE9`
  - All valid frames transmitted or received over the wire begin with bytes `0x59, 0xE9`.

---

## 3. Protocol Payloads & State Machine

### 3.1 Keepalive / Ping Pong
- **Server Ping**: Action `0xBA`, Subcode `0x10`, Status `0x00` (Wire: `59 e9 ae ad 17 bd ad`).
- **Client Auto-Pong**: The client automatically responds with Action `0xBA`, Subcode `0x10`, Status `0x00` (`[0xBA, 0x10, 0x00]`).
- **Ping Measurement**: Records roundtrip latency in milliseconds upon receipt.

### 3.2 Authentication & Login Packet
- **Action**: `0x3F` (63)
- **Subcode**: `0x04`
- **Binary Layout**:
  ```
  [0x00]: 0x3F (Action Code)
  [0x01]: 0x04 (Sub Code)
  [0x02..0x03]: 0x04BE (Client Version 1214, uint16 little-endian: 0xBE, 0x04)
  [0x04]: Account Length (1 byte)
  [0x05..A]: Account string (ASCII bytes)
  [A+1]: Password Length (1 byte)
  [A+2..B]: Password string (ASCII bytes)
  [B+1..B+9]: Extra signature bytes: 0x07, 0x53, 0x60, 0x60, 0x63, 0x67, 0x63, 0x61, 0x65
  ```
- **Wire Prefix**: `59 e9 8b ad 92 a9 ...`

### 3.3 Server Authentication Responses
- **Success / User ID Assignment**: Action `0x3F`, Subcode `0x02`
  - Contains uint32 UserID or status 0x00. Emits `login_succeeded(user_id)`.
- **Character List**: Action `0x3F`, Subcode `0x01`
  - Contains array of character records (slot, name, level, element, HP, SP, EXP, Gold, body, head, equipment). Emits `character_list_received(characters)`.
- **Login Failure**: Action `0x01`, Subcode `0x0C` (Status 0x00) or Subcode `0x06`
  - Emits `login_failed(reason, code)` and disconnects.

### 3.4 Character Creation & Selection
- **Request Character Creation**: Action `0x3F`, Subcode `0x02`, Slot (1 byte: `0x01`).
- **Character Creation ACK**: Action `0x01`, Subcode `0x03`, Status (1 byte: `0x00` = success).
  - Emits `character_creation_ack(status)` and `character_creation_requested(slot)`.
- **Select Character to Enter World**: Action `0x3F`, Subcode `0x02`, Slot (1 byte).
- **World Entry Packets**: Actions `0x14` (20), `0x05`, `0x03`, `0x04`. Emits `world_entered(world_info)`.

---

## 4. NetworkManager Architecture

[`scripts/network/network_manager.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/scripts/network/network_manager.gd) implements:
1. **Non-blocking StreamPeerTCP Polling**:
   - Polled in `_process(delta: float)`.
   - Handles `STATUS_CONNECTING`, `STATUS_CONNECTED`, `STATUS_ERROR`, and `STATUS_NONE`.
2. **Plaintext Frame Accumulator**:
   - Slices and decrypts wire chunks with XOR `0xAD` immediately on receipt.
   - Detects frame boundary synchronization via `0xF4, 0x44` sentinel scanning.
   - Discards unaligned noise and handles partial frame reassembly across socket poll ticks.
3. **Dispatcher & Signal Routing**:
   - `connected_to_server(host, port)`
   - `connection_failed(reason)`
   - `disconnected`
   - `network_error(error_message)`
   - `packet_received(action_code, sub_code, payload)`
   - `frame_received(payload)`
   - `login_succeeded(user_id)`
   - `login_failed(reason, error_code)`
   - `character_list_received(characters)`
   - `character_selected(slot, character_data)`
   - `character_creation_requested(slot)`
   - `character_creation_ack(status)`
   - `world_entered(world_info)`
   - `ping_received(payload)`
   - `ping_updated(latency_ms)`

---

## 5. Automated Verification

Full test coverage is implemented in [`tests/test_network.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_network.gd):
- `test_network_manager_crypto`: Asserts `0xF4 ^ 0xAD == 0x59` and `0x44 ^ 0xAD == 0xE9`.
- `test_network_manager_framing`: Verifies 4-byte header generation and little-endian length.
- `test_network_manager_accumulator`: Validates noise resilience and cross-chunk frame assembly.
- `test_network_manager_login_packet`: Verifies byte-level wire trace match (`59e98bad92a9...`).
- `test_network_manager_ping_pong`: Verifies keepalive dispatching.
- `test_network_manager_dispatcher_responses`: Validates AC 1:12, AC 1:3, AC 63:2, AC 20 world entry.
- `test_network_manager_live_connection`: Performs non-blocking socket connect to live Rhodes1 (`20.187.103.41:6414`).
