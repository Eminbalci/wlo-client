# Multi-JMG Map Archives & NPC Texture Extraction Specification

## 1. Overview & Architectural Scope
In the original Wonderland Online (WLRI) client, map background artwork is partitioned across multiple sequential `.JMG` packages in `pic/`:
- `map.JMG`: Base client map backgrounds (326 entries, 260,079,918 bytes)
- `map_d01.JMg`: Expansion and dungeon map backgrounds (27 entries, 10,636,134 bytes)
- `map_c01.JMg`: Event and interior map backgrounds (4 entries, 1,027,655 bytes)

Total verified map backgrounds across all packages: **357 unique entries**.

This specification outlines the unified Multi-Archive loader architecture implemented in `ArchiveLoader` (`scripts/core/archive_loader.gd`), `WloArchiveReader` (`scripts/core/wlo_archive_reader.gd`), and `MapRenderer` (`scripts/map/map_renderer.gd`). It guarantees zero disk writes by streaming raw JPEG and BMP buffers directly from memory, uploading them as GPU `ImageTexture` objects, automatically adjusting `Camera2D` viewport boundaries, and dynamically extracting authentic NPC, monster, and player role standees across `007.jma`, `001.jma`, and `002.jma`..`005.jma`.

---

## 2. Multi-JMG Package Indexing Architecture

### 2.1 Binary Layout (`.JMG` / `.BMg`)
Wonderland Online package files (`map.JMG`, `map_d01.JMg`, `map_c01.JMg`, `item.BMg`, `JRole.JMg`) follow a standardized little-endian binary format:
- **Header (2 bytes)**:
  - `entry_count`: uint16 little-endian
- **Directory Table (`entry_count * 32` bytes)**:
  - `name_len`: uint8 (1 byte, clamped to 23)
  - `name`: ASCII string (23 bytes, null-terminated, case-insensitive)
  - `offset`: uint32 little-endian (4 bytes)
  - `size`: uint32 little-endian (4 bytes)
- **Data Payload**:
  - Raw uncompressed JPEG (`0xFF 0xD8 0xFF`) or BMP (`0x42 0x4D`) streams starting at `offset`.

### 2.2 Indexing Strategy in `ArchiveLoader`
In `ArchiveLoader.initialize_archives()`:
```gdscript
_map_archives.clear()
var map_files: Array[String] = [
	"map.JMG", "map_d01.JMg", "map_c01.JMg",
	"map.jmg", "map_d01.jmg", "map_c01.jmg"
]
var loaded_map_paths: Dictionary = {}
for mfile: String in map_files:
	var mpath: String = str(pic_path) + "/" + mfile
	if FileAccess.file_exists(mpath):
		var norm_path: String = mpath.to_lower()
		if not loaded_map_paths.has(norm_path):
			loaded_map_paths[norm_path] = true
			var reader = WloArchiveReader.open_archive(mpath)
			if reader:
				_map_archives.append(reader)
if not _map_archives.is_empty():
	_map_archive = _map_archives[0]
```

### 2.3 Map Background Candidate Resolution
When `get_map_background(scene_id: int) -> ImageTexture` is queried:
1. Check in-memory GPU texture cache (`_texture_cache["map_%d" % scene_id]`).
2. Generate prioritized candidate filenames:
   - `"%d.jpg" % scene_id` (e.g. `10001.jpg`, `10075.jpg`, `10202.jpg`)
   - `"%05d.jpg" % scene_id`
   - `"%04d.jpg" % scene_id`
   - If `scene_id == 10011` (Deserted Island Beach Awakening): alias to `"10003.jpg"`
3. Sequentially query all archives in `_map_archives`.
4. Decode buffer into GPU `ImageTexture` via `Image.load_jpg_from_buffer` and cache.
5. If absent across all archives, output clean `push_warning`.

---

## 3. Dynamic NPC, Monster & Role Texture Extraction

### 3.1 Method Signature
```gdscript
func get_npc_texture(sprite_id: int, heading: int = 0) -> ImageTexture
```

### 3.2 Resolution Pipeline
1. **Cache Lookup**: `cache_key = "npc_tex_%d_%d" % [sprite_id, heading]`.
2. **Playable Role Standees (IDs 1..14)**:
   - Evaluates whether `sprite_id >= 1 and sprite_id <= 14`.
   - Invokes `get_player_composite_frames(sprite_id)` to generate 128x128 paper-doll composites from `002.jma`..`005.jma` (body, face, clothes, hair, shoes).
   - Computes standing frame index for the requested heading: `frame_idx = (32 + (heading % 8) * 4) % total_frames`.
   - Fallback to `get_role_sprite_sheet(sprite_id, 0)` if composite generation is unavailable.
3. **NPC Model Packages (`007.jma` & `007_c01.jma`)**:
   - Queries `"%d.jmp" % sprite_id` for IDs 7000..7999, or `"%d.jmp" % (7000 + sprite_id)` for relative indices.
   - Decodes JMP animation and applies heading frame selection.
4. **Monsters and Standard NPCs (`001.jma` & `001_c01.jma`..`001_c04.jma`)**:
   - Queries `"%d.jmp" % sprite_id` for IDs 1000..6999 (e.g. Captain Robinson `1038.jmp`, Breillat `1170.jmp`), or `"%d.jmp" % (1000 + sprite_id)` for relative indices.
5. **NPC ID to Sprite ID Resolution Fallback**:
   - If `sprite_id` matches an NPC record in `GameDatabase.npcs` (e.g. NPC ID `14003`), resolves `rec.sprite_id` (`1038`) and recurses.
6. **Error Handling**:
   - If completely missing across all packages, logs clean `push_error` and returns `null`.

### 3.3 Heading Frame Computation Table
| Frame Count | Moving Frame Index Formula | Idle/Standing Frame Index Formula | Notes |
|:---|:---|:---|:---|
| **64+ frames** | `(heading % 8) * 4 + sub_idx` | `32 + (heading % 8) * 4 + sub_idx` | Full 8-way player/monster |
| **32 frames** | `diag_idx * 4 + sub_idx` | `16 + diag_idx * 4 + sub_idx` | 4-way diagonal (Captain, Sailors) |
| **16 frames** | `diag_block * 4 + sub_idx` | `diag_block * 4` | Compact 4-way animations |
| **8 frames** | `heading % 8` | `heading % 8` | Static 8-direction turns |
| **4 frames** | `diag_4` | `diag_4` | Static 4-direction turns |
| **1 frame** | `0` | `0` | Static objects (Props, Chests) |

---

## 4. MapRenderer Camera Bounds & Size Synchronization

In `MapRenderer` (`scripts/map/map_renderer.gd`):
1. **Background Size Tracking**:
   `background_size: Vector2` records exact pixel dimensions of the decoded map. `get_map_pixel_size() -> Vector2` exposes it publicly.
2. **Camera2D Clamping**:
   `update_camera_limits(cam: Camera2D = null) -> void` dynamically adjusts camera limits:
   ```gdscript
   var map_size: Vector2 = get_map_pixel_size()
   var vp_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(800, 600)
   if map_size.x < vp_size.x:
       var extra_x: float = (vp_size.x - map_size.x) * 0.5
       cam.limit_left = int(-extra_x)
       cam.limit_right = int(map_size.x + extra_x)
   else:
       cam.limit_left = 0
       cam.limit_right = int(map_size.x)

   if map_size.y < vp_size.y:
       var extra_y: float = (vp_size.y - map_size.y) * 0.5
       cam.limit_top = int(-extra_y)
       cam.limit_bottom = int(map_size.y + extra_y)
   else:
       cam.limit_top = 0
       cam.limit_bottom = int(map_size.y)
   ```
3. **Parent & Window Notification**:
   - Automatically synchronizes `get_parent().map_size` when embedded in `MapView`.
   - Connects to `get_viewport().size_changed` to ensure dynamic window resizing maintains camera limits without letterboxing glitches.
   - Supports explicit dependency injection via `@export var archive_loader: Node = null`.

---

## 5. Verification Matrix & Empirical Benchmarks

| Scene ID | Description | Source Archive | Resolution (WxH) | Payload Size | Camera Limits [L, R, T, B] |
|:---|:---|:---|:---|:---|:---|
| **10001** | Ship Deck | `map.JMG` | 2432 x 1792 | 1,415,293 bytes | [0, 2432, 0, 1792] |
| **10002** | Ship Cabin | `map.JMG` | 1659 x 1266 | 381,706 bytes | [0, 1659, 0, 1266] |
| **10003** | Deserted Island | `map.JMG` | 4672 x 5056 | 4,709,718 bytes | [0, 4672, 0, 5056] |
| **10075** | Interior Scene | `map_c01.JMg` | 832 x 640 | 124,647 bytes | [0, 832, 0, 640] |
| **10202** | Expansion Scene | `map_d01.JMg` | 1728 x 1216 | 369,941 bytes | [0, 1728, 0, 1216] |
| **10011** | Beach Awakening | `map.JMG` (alias 10003) | 4672 x 5056 | 4,709,718 bytes | [0, 4672, 0, 5056] |

### NPC Texture Verification Benchmarks
| Query | Expected Entity | Source | Decoded Canvas | Result |
|:---|:---|:---|:---|:---|
| `get_npc_texture(2, 0)` | Betty (Playable Role) | `003.jma` + `003f/e/s/h` | 128 x 128 | Success |
| `get_npc_texture(1038, 0)` | Captain Robinson | `001.jma:1038.jmp` | 128 x 128 | Success |
| `get_npc_texture(1170, 0)` | Breillat | `001.jma:1170.jmp` | 128 x 128 | Success |
| `get_npc_texture(7000, 0)` | Static Prop / Model | `007.jma:7000.jmp` | 128 x 128 | Success |
| `get_npc_texture(999999, 0)` | Invalid ID | None | N/A | Clean null + error log |

---

## 6. Execution Command
```powershell
C:\Godot\godot_console.exe --headless --path D:\Godot\WonderlandOnline\wonderland-online-client -s tests/test_multi_jmg_map_archives.gd
```
Result: 100% pass, zero errors.
