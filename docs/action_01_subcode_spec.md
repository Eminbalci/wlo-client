# Action 0x01 Sub Codes & Authentication Disconnect Specification

## Overview
This document specifies the authentic code-to-text mapping and semantics for server Action 0x01 packets (Session Handshake, Login Authentication, Character Creation ACK) as reverse engineered from `aLogin.exe` and verified against `Wonderland-Private-Server/Src/Network/ActionCodes/AC63.cs` and `AC01.cs`.

## 1. Action 0x01 Sub Code Reference Matrix

| Sub Code | Hex | Direction | Description | Response / UI Message | Reference |
|---|---|---|---|---|---|
| 1 | `0x01` | S -> C | Handshake ACK / Entity Position | Handshake Confirmed / Updates Entity Pos | `AC01.HandleAuthHandshake` |
| 3 | `0x03` | S -> C | Character Creation ACK | Status 0 = Success (proceed to creation), Status 1 = Creation Failed | `AC63.Recv3`, `AC01.cs` |
| 6 | `0x06` | S -> C | Login Authentication Failure: Bad Username / Password | "Login/Pwd error" (Triggers disconnect) | `AC63.Recv4` Case 1 (`[1, 6]`) |
| 7 | `0x07` | S -> C | Session Termination: Account Banned / Locked | "Account is banned or session timed out." | `AC63.Recv4` Case 5 (`[1, 7]`) |
| 12 | `0x0C` | S -> C | Account Nonexistent / Password Mismatch | "Login/Pwd error" | `NetworkManager._handle_ac1` |

## 2. Server Authentication Result Sequences (Action 63 -> Action 01/00)

When client authenticates with Action 63 Sub 4 (`0x3F 0x04`):
1. **Success (State 0):** Server sends `[63, 2, <uint32 UserID>]` followed by character list `[63, 1, ...]` and world readiness packet `[35, 11]`.
2. **Bad Username or Password (State 1):** Server sends `[63, 2]` followed by Action 0x01 Sub 0x06 (`[1, 6]`) which prompts "Login/Pwd error" and terminates socket.
3. **Repeated / Duplicate Login (State 2):** Server sends `[63, 2]` followed by Action 0x00 Sub 0x13 (`[0, 19]`) -> `ServerNotice.REPEATED_LOGIN` ("Repeated Login").
4. **Outdated Version (State 3):** Server sends Action 0x00 Sub 0x11 (`[0, 17]`) -> `ServerNotice.UPDATE_GAME_FILES` ("Update Game Files").
5. **Wrong Client Version (State 4):** Server sends Action 0x00 Sub 0x41 (`[0, 65]`) -> `ServerNotice.WRONG_VERSION_2` ("Wrong Version").
6. **Account Banned / Locked (State 5):** Server sends Action 0x01 Sub 0x07 (`[1, 7]`) -> "Account is banned or session timed out."
7. **Server Maintenance / Routing Wait (State 6):** Server sends Action 0x00 Sub 0x4F (`[0, 79]`) -> `ServerNotice.ROUTING_ERROR_WAIT` ("Routing Error, Wait").

## 3. Implementation in NetworkManager
All confirmed mappings are implemented in `scripts/network/network_manager.gd`:
- `_handle_ac1` processes sub codes `0x01`, `0x03`, `0x06`, `0x07`, and `0x0C`.
- `_handle_ac0` cross-references `ServerNotice` for the complete 83-entry Delphi text table.
- Verified in automated test suite `tests/test_network.gd`.
