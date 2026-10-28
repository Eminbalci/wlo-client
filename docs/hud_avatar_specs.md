# HUD Avatar Masking and Role JMP Mapping Specifications

## Overview
This document specifies the technical architecture and rendering implementation for the HUD Avatar circular masking, gold frame bezels, and the 14 playable role JMP mapping in the Wonderland Online client (`D:/Godot/WonderlandOnline/wonderland-online-client`).

---

## 1. Circular Shader Masking & Gold Frame Bezel

### Rendering Architecture
- **Shader Pipeline:** Avatars are rendered within HUD status docks and character selection screens using custom circular masking shaders (`circular_avatar.shader` or UI clipping nodes) that crop rectangular character portraits into crisp circular apertures.
- **Gold Frame Bezel:** A polished gold decorative metallic ring/bezel encircles each avatar mask, maintaining authentic VCL interface aesthetics from the original Wonderland Online client.
- **Dimensions & Layout:** Standardized diameter (typically 64x64 or 80x80 pixels) with centered scaling and anti-aliased edge smoothing.

---

## 2. 14 Playable Role JMP Mapping

The client maps the 14 authentic Wonderland Online playable characters/roles (indices 1 through 14) across male and female variants (`avatar_role_X_0.png` and `avatar_role_X_1.png`):

| Role ID | Character Name / Archetype | Gender Variant 0 | Gender Variant 1 |
| :---: | :--- | :--- | :--- |
| **1** | Alex / Swordsman | `avatar_role_1_0.png` | `avatar_role_1_1.png` |
| **2** | Ryan / Mage | `avatar_role_2_0.png` | `avatar_role_2_1.png` |
| **3** | Jessica / Archer | `avatar_role_3_0.png` | `avatar_role_3_1.png` |
| **4** | Betty / Healer | `avatar_role_4_0.png` | `avatar_role_4_1.png` |
| **5** | Daniel / Knight | `avatar_role_5_0.png` | `avatar_role_5_1.png` |
| **6** | Charlotte / Rogue | `avatar_role_6_0.png` | `avatar_role_6_1.png` |
| **7** | Max / Gunner | `avatar_role_7_0.png` | `avatar_role_7_1.png` |
| **8** | Lisa / Shaman | `avatar_role_8_0.png` | `avatar_role_8_1.png` |
| **9** | Edward / Brawler | `avatar_role_9_0.png` | `avatar_role_9_1.png` |
| **10** | Rachel / Cleric | `avatar_role_10_0.png` | `avatar_role_10_1.png` |
| **11** | Gordon / Viking | `avatar_role_11_0.png` | `avatar_role_11_1.png` |
| **12** | Sophia / Bard | `avatar_role_12_0.png` | `avatar_role_12_1.png` |
| **13** | Kevin / Ninja | `avatar_role_13_0.png` | `avatar_role_13_1.png` |
| **14** | Nicole / Alchemist | `avatar_role_14_0.png` | `avatar_role_14_1.png` |

---

## 3. Verification Suite
- Verified via [`test_animated_status_dock_avatar.gd`](file:///D:/Godot/WonderlandOnline/wonderland-online-client/tests/test_animated_status_dock_avatar.gd) and related role parity tests ensuring correct texture loading, masking shader compilation, and bezel alignment.
