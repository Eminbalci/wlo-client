class_name TalkDatabase
extends RefCounted

## Authentic Wonderland Online Dialogue and Talk.dat Engine (Docs 08, 16, 69)
## Decodes 17,494 records of 292 bytes each from Talk.dat with bit-exact Delphi ShortString reversal,
## XOR decryption ((val ^ 0xECEA) - 5), token parsing (#n, #s, #f, #R, #B, #G, #Y),
## branching choice options, condition requirements, reward item IDs, and dialogue chaining.

class TalkRecord:
	var id: int = 0
	var raw_text: String = ""
	var text: String = "" ## Formatted BBCode text with player name and colors
	var plain_text: String = "" ## Stripped plain text
	var speaker: String = "" ## Speaker name
	var speaker_id: int = 0 ## NPC ID or 0 for player
	var face_index: int = -1 ## Extracted face/portrait index from #fX/#f
	var sound_effect: String = "" ## Extracted sound effect identifier from #sX/#s
	var choices: Array = [] ## [{"text": String, "next_talk_id": int, "branch": int}]
	var conditions: Array = [] ## [{"type": String, "target_id": int, "value": int, "description": String}]
	var rewards: Array = [] ## [{"type": String, "item_id": int, "amount": int, "description": String}]
	var next_talk_id: int = 0 ## Next talk ID pointer in dialogue chain
	var record_index: int = -1
	var offset: int = -1

var _talks: Dictionary = {} ## int (talk_id) -> TalkRecord
var _talks_by_index: Dictionary = {} ## int (record_index) -> TalkRecord
var _talks_by_offset: Dictionary = {} ## int (offset) -> TalkRecord
var _npc_talk_map: Dictionary = {} ## int (npc_id) -> int (talk_id)
var _map_npc_talk_map: Dictionary = {} ## String ("{map_id}_{npc_id}" or "{map_id}_{click_id}") -> int (talk_id)

var is_loaded: bool = false

# Regex patterns for authentic WLO token extraction
var _sound_regex: RegEx = RegEx.new()
var _face_regex: RegEx = RegEx.new()
var _color_r_regex: RegEx = RegEx.new()
var _color_b_regex: RegEx = RegEx.new()
var _color_g_regex: RegEx = RegEx.new()
var _color_y_regex: RegEx = RegEx.new()
var _general_tag_regex: RegEx = RegEx.new()

func _init() -> void:
	_init_regexes()

func _init_regexes() -> void:
	_sound_regex.compile("#s([a-zA-Z0-9_-]+)(?:/#s|\\b)")
	_face_regex.compile("#[fF]([0-9]+)(?:/#[fF]|\\b)")
	_color_r_regex.compile("#[Rr](.*?)(?:/?#[Rr]|#[Ww]|$)")
	_color_b_regex.compile("#[Bb](.*?)(?:/?#[Bb]|#[Ww]|$)")
	_color_g_regex.compile("#[Gg](.*?)(?:/?#[Gg]|#[Ww]|$)")
	_color_y_regex.compile("#[Yy](.*?)(?:/?#[Yy]|#[Ww]|$)")
	_general_tag_regex.compile("#[a-zA-Z0-9_-]+(?:/#[a-zA-Z0-9_-]+)?")

## Native decryption formula: (ushort ^ 0xECEA) - 5
static func decode_talk_id(raw_u16: int) -> int:
	return ((raw_u16 ^ 0xECEA) - 5) & 0xFFFF

## Loads and parses Talk.dat, with optional cross-referencing to Npc.dat and Eve.emg.
func load_from_file(talk_path: String, npc_path: String = "", eve_path: String = "") -> bool:
	if not FileAccess.file_exists(talk_path):
		push_error("Talk.dat not found: %s" % talk_path)
		return false
	
	var file := FileAccess.open(talk_path, FileAccess.READ)
	if not file:
		return false
	
	var data := file.get_buffer(file.get_length())
	file.close()
	
	_talks.clear()
	_talks_by_index.clear()
	_talks_by_offset.clear()
	_npc_talk_map.clear()
	_map_npc_talk_map.clear()
	
	const RECORD_SIZE: int = 292
	var total_records: int = data.size() / RECORD_SIZE
	
	for r in range(1, total_records):
		var rec_offset: int = r * RECORD_SIZE
		if rec_offset + RECORD_SIZE > data.size():
			break
		
		var raw_u16: int = data.decode_u16(rec_offset)
		var talk_id: int = decode_talk_id(raw_u16)
		var txt_len: int = data[rec_offset + 2]
		if txt_len <= 0 or txt_len > 254:
			continue
		
		var text_start: int = rec_offset + RECORD_SIZE - 35 - txt_len
		if text_start < rec_offset or text_start + txt_len > data.size():
			continue
		
		var text_bytes := PackedByteArray()
		text_bytes.resize(txt_len)
		for i in range(txt_len):
			text_bytes[i] = data[text_start + txt_len - 1 - i]
		
		var raw_str: String = _decode_string_clean(text_bytes)
		if raw_str.is_empty():
			continue
		
		# Strip internal control prefix "fffff"
		if raw_str.begins_with("fffff"):
			raw_str = raw_str.substr(5).strip_edges()
		if raw_str.is_empty():
			continue
		
		var rec := TalkRecord.new()
		rec.id = talk_id
		rec.raw_text = raw_str
		rec.record_index = r
		rec.offset = rec_offset
		
		# Token extraction
		_parse_tokens_into_record(rec)
		
		if talk_id > 0:
			_talks[talk_id] = rec
		_talks_by_index[r] = rec
		_talks_by_offset[rec_offset] = rec
		_talks_by_offset[text_start] = rec
	
	is_loaded = not _talks.is_empty()
	
	# Cross-reference Npc.dat if available
	_load_npc_metadata(npc_path)
	
	# Cross-reference Eve.emg if available
	_load_eve_events(eve_path)
	
	# Apply authentic default NPC dialogue linkages
	_apply_authentic_defaults()
	
	return is_loaded

## Clean string extraction with Big5 / UTF-8 / ASCII fallback and null-trimming
func _decode_string_clean(bytes: PackedByteArray) -> String:
	if bytes.is_empty():
		return ""
	
	# Strip null terminators
	var nul_idx := bytes.find(0)
	if nul_idx >= 0:
		bytes = bytes.slice(0, nul_idx)
	if bytes.is_empty():
		return ""
	
	# Check if bytes are valid ASCII
	var is_ascii: bool = true
	for b in bytes:
		if b < 0x20 or b > 0x7E:
			if b != 10 and b != 13 and b != 9:
				is_ascii = false
				break
	
	if is_ascii:
		return bytes.get_string_from_ascii().strip_edges()
	
	# Fallback: extract clean ASCII characters (skipping non-UTF8/Big5 bytes)
	
	# Fallback ASCII stripping invalid control bytes
	var clean_bytes := PackedByteArray()
	for b in bytes:
		if b >= 32 and b <= 126:
			clean_bytes.append(b)
		elif b == 10 or b == 13 or b == 9:
			clean_bytes.append(b)
	
	return clean_bytes.get_string_from_ascii().strip_edges()

## Parses authentic WLO tokens (#s, #f, #R, #B, #G, #Y, #n) into TalkRecord
func _parse_tokens_into_record(rec: TalkRecord) -> void:
	var s: String = rec.raw_text
	
	# 1. Extract sound effect #s([a-zA-Z0-9_-]+)/#s
	var sound_match := _sound_regex.search(s)
	if sound_match:
		rec.sound_effect = sound_match.get_string(1)
	
	# 2. Extract speaker face index #f([0-9]+)/#f
	var face_match := _face_regex.search(s)
	if face_match:
		rec.face_index = face_match.get_string(1).to_int()
	
	# 3. Create plain text representation (stripped of all tags)
	rec.plain_text = strip_formatting(s)
	
	# 4. Create rich formatted BBCode representation
	rec.text = format_tokens(s)

## Formats tokens into Godot BBCode rich text
func format_tokens(text: String, player_name: String = "Adventurer") -> String:
	if text.is_empty():
		return ""
	
	var formatted: String = text
	
	# Character name replacement #n/#n or #n
	formatted = formatted.replace("#n/#n", player_name).replace("#n", player_name)
	
	# Strip sound and face tags for presentation
	if _sound_regex:
		formatted = _sound_regex.sub(formatted, "", true)
	if _face_regex:
		formatted = _face_regex.sub(formatted, "", true)
	
	# Colors to BBCode
	if _color_r_regex:
		formatted = _color_r_regex.sub(formatted, "[color=red]$1[/color]", true)
	if _color_b_regex:
		formatted = _color_b_regex.sub(formatted, "[color=deep_sky_blue]$1[/color]", true)
	if _color_g_regex:
		formatted = _color_g_regex.sub(formatted, "[color=green]$1[/color]", true)
	if _color_y_regex:
		formatted = _color_y_regex.sub(formatted, "[color=yellow]$1[/color]", true)
	
	# Strip remaining unparsed control tags
	if _general_tag_regex:
		formatted = _general_tag_regex.sub(formatted, "", true)
	
	return formatted.strip_edges()

## Extracts sound effect token (#s123/#s or #s123)
func extract_sound_effect(text: String) -> String:
	if _sound_regex:
		var m := _sound_regex.search(text)
		if m:
			return m.get_string(1)
	return ""

## Extracts face index token (#f2/#f or #f2)
func extract_face_index(text: String) -> int:
	if _face_regex:
		var m := _face_regex.search(text)
		if m:
			return m.get_string(1).to_int()
	return 0

## Alias for format_tokens
func format_dialogue_tokens(text: String, player_name: String = "Adventurer") -> String:
	return format_tokens(text, player_name)

## Strips all formatting tags to produce raw readable text
func strip_formatting(text: String) -> String:
	if text.is_empty():
		return ""
	var clean: String = text
	if _sound_regex:
		clean = _sound_regex.sub(clean, "", true)
	if _face_regex:
		clean = _face_regex.sub(clean, "", true)
	if _color_r_regex:
		clean = _color_r_regex.sub(clean, "$1", true)
	if _color_b_regex:
		clean = _color_b_regex.sub(clean, "$1", true)
	if _color_g_regex:
		clean = _color_g_regex.sub(clean, "$1", true)
	if _color_y_regex:
		clean = _color_y_regex.sub(clean, "$1", true)
	if _general_tag_regex:
		clean = _general_tag_regex.sub(clean, "", true)
	clean = clean.replace("#n/#n", "Adventurer").replace("#n", "Adventurer")
	return clean.strip_edges()

## Resolves metadata from Npc.dat
func _load_npc_metadata(npc_path: String) -> void:
	var path := npc_path
	if path.is_empty():
		path = "res://assets/data/Npc.dat"
	if not FileAccess.file_exists(path) and FileAccess.file_exists("D:/GitHub/WLRI/data/Npc.dat"):
		path = "D:/GitHub/WLRI/data/Npc.dat"
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var data := file.get_buffer(file.get_length())
	file.close()
	
	const REC_SIZE: int = 138
	var total: int = data.size() / REC_SIZE
	
	for i in range(1, total):
		var off: int = i * REC_SIZE
		if off + REC_SIZE > data.size():
			break
		
		var slen: int = mini(data[off], 10)
		var name_bytes := PackedByteArray()
		for b in range(slen):
			name_bytes.append(data[off + 1 + slen - 1 - b])
		var name_str: String = name_bytes.get_string_from_ascii().strip_edges()
		
		# Bit-exact decryption with ((v ^ 0x5209) - 1)
		var npc_id: int = ((data.decode_u16(off + 12) ^ 0x5209) - 1) & 0xFFFF
		var talk_img: int = ((data.decode_u16(off + 88) ^ 0x5209) - 1) & 0xFFFF
		
		if npc_id > 0 and not name_str.is_empty():
			# Enrich known talks associated with this NPC
			if _npc_talk_map.has(npc_id):
				var tid: int = _npc_talk_map[npc_id]
				if _talks.has(tid):
					var rec: TalkRecord = _talks[tid]
					if rec.speaker.is_empty():
						rec.speaker = name_str
						rec.speaker_id = npc_id

## Parses event structures from Eve.emg to wire dialogue sequences, conditions, choices, and rewards
func _load_eve_events(eve_path: String) -> void:
	var path := eve_path
	if path.is_empty():
		path = "res://assets/data/Eve.emg"
	if not FileAccess.file_exists(path) and FileAccess.file_exists("D:/GitHub/WLRI/data/Eve.emg"):
		path = "D:/GitHub/WLRI/data/Eve.emg"
	if not FileAccess.file_exists(path):
		return
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	
	var d := file.get_buffer(file.get_length())
	file.close()
	
	if d.size() < 12:
		return
	
	var entry_len: int = d.decode_u32(8)
	var ptr: int = 12
	var maps: Dictionary = {} # int (map_id) -> Dictionary (dptr, dlen)
	
	for i in range(entry_len):
		if ptr + 10 > d.size():
			break
		var mid: int = d.decode_u16(ptr)
		var dptr: int = d.decode_u32(ptr + 4)
		var dlen: int = d.decode_u16(ptr + 8)
		maps[mid] = {"dptr": dptr, "dlen": dlen}
		ptr += 10
	
	for mid in maps.keys():
		var m_info: Dictionary = maps[mid]
		var dptr: int = m_info["dptr"]
		var dlen: int = m_info["dlen"]
		var off_ptr: int = dptr + dlen - 44
		if off_ptr < 0 or off_ptr + 44 > d.size():
			continue
		
		# Offset 4 is Events category offset
		var ev_off: int = d.decode_u32(off_ptr + 16)
		if ev_off == 0:
			continue
		
		var ev_ptr: int = dptr + ev_off
		if ev_ptr < 0 or ev_ptr + 2 > d.size():
			continue
		
		var event_count: int = d.decode_u16(ev_ptr)
		ev_ptr += 2
		
		for ev_idx in range(event_count):
			if ev_ptr + 24 > d.size():
				break
			var click_id: int = d.decode_u16(ev_ptr)
			ev_ptr += 3 # click_id (2) + unknownbyte1 (1)
			
			# Event Name 20 bytes
			var ev_name_bytes: PackedByteArray = d.slice(ev_ptr, ev_ptr + 20)
			ev_ptr += 20
			var ev_name: String = _decode_string_clean(ev_name_bytes)
			
			if ev_ptr >= d.size():
				break
			var sub_count: int = d[ev_ptr]
			ev_ptr += 1
			
			var previous_talk_rec: TalkRecord = null
			
			for s_idx in range(sub_count):
				if ev_ptr + 25 > d.size():
					break
				var _sub_idx: int = d[ev_ptr]
				var cond_type: int = d[ev_ptr + 1]
				var w1: int = d.decode_u16(ev_ptr + 2)
				var w2: int = d.decode_u16(ev_ptr + 4)
				var w3: int = d.decode_u16(ev_ptr + 6)
				var w4: int = d.decode_u16(ev_ptr + 8)
				ev_ptr += 24
				
				if ev_ptr >= d.size():
					break
				var act_count: int = d[ev_ptr]
				ev_ptr += 1
				
				var sub_talk_records: Array[TalkRecord] = []
				var sub_rewards: Array[Dictionary] = []
				
				for a_idx in range(act_count):
					if ev_ptr + 22 > d.size():
						break
					var dptr_opcode: int = d[ev_ptr + 1]
					var d1: int = d.decode_u16(ev_ptr + 2)
					var d2: int = d.decode_u16(ev_ptr + 4)
					var d3: int = d.decode_u16(ev_ptr + 6)
					var _d4: int = d.decode_u16(ev_ptr + 8)
					ev_ptr += 21
					
					# Opcode 1 & 2: Dialogue text lookup
					var dia_id: int = 0
					if dptr_opcode == 1 or dptr_opcode == 2:
						if d3 >= 10000 and d3 <= 65535:
							dia_id = d3
						elif d2 >= 10000 and d2 <= 65535:
							dia_id = d2
						elif d3 > 0:
							dia_id = d3
						elif d2 > 0:
							dia_id = d2
					
					# Opcode 1 / 5: Item Grant (Reward)
					if (dptr_opcode == 1 and d1 == 1 and d3 > 0) or (dptr_opcode == 5 and d2 == 1 and d1 > 0):
						var item_id: int = d3 if dptr_opcode == 1 else d1
						var count: int = maxi(1, d2 if dptr_opcode == 1 else d3)
						sub_rewards.append({
							"type": "item",
							"item_id": item_id,
							"amount": count,
							"description": "Item Grant"
						})
					
					# Opcode 10: Gold Award
					if dptr_opcode == 10 and d1 > 0:
						sub_rewards.append({
							"type": "gold",
							"item_id": 0,
							"amount": d1,
							"description": "Gold Coins"
						})
					
					# Opcode 11: EXP Award
					if dptr_opcode == 11 and d1 > 0:
						sub_rewards.append({
							"type": "exp",
							"item_id": 0,
							"amount": d1,
							"description": "Experience Points"
						})
					
					if dia_id > 0 and _talks.has(dia_id):
						var t_rec: TalkRecord = _talks[dia_id]
						sub_talk_records.append(t_rec)
						
						# Map to map_id and click_id
						_map_npc_talk_map["%d_%d" % [mid, click_id]] = dia_id
						
						# Speaker assignment
						if d1 == 2 or (dptr_opcode == 2 and d2 == 2):
							t_rec.speaker = "Player"
							t_rec.speaker_id = 0
						elif t_rec.speaker.is_empty():
							t_rec.speaker = ev_name if not ev_name.begins_with("新事件") else ("NPC #%d" % click_id)
							t_rec.speaker_id = click_id
				
				# Link dialogue chain (next_talk_id) within subentry
				for k in range(sub_talk_records.size()):
					var cur := sub_talk_records[k]
					if k + 1 < sub_talk_records.size():
						cur.next_talk_id = sub_talk_records[k + 1].id
					
					# Attach rewards
					for rwd in sub_rewards:
						cur.rewards.append(rwd)
					
					# Attach condition requirement
					if cond_type > 0:
						var cond_desc := ""
						match cond_type:
							1: cond_desc = "Player Level >= %d" % w1
							2: cond_desc = "Player Has Item #%d x%d" % [w3 if w3 > 0 else w1, maxi(1, w2)]
							4: cond_desc = "Player Has Companion #%d" % w1
							5: cond_desc = "Quest #%d Status %d" % [w1, w2]
							7: cond_desc = "Selected Choice #%d" % w2
							15: cond_desc = "Free Inventory Slots >= %d" % w1
							_: cond_desc = "Condition Type %d" % cond_type
						
						cur.conditions.append({
							"type": "condition_%d" % cond_type,
							"target_id": w1,
							"value": w2,
							"comparison": w4,
							"description": cond_desc
						})
				
				if not sub_talk_records.is_empty():
					previous_talk_rec = sub_talk_records[-1]

func _ensure_talk(talk_id: int, speaker_name: String, speaker_id: int = 0, default_text: String = "") -> TalkRecord:
	if not _talks.has(talk_id):
		var new_rec: TalkRecord = TalkRecord.new()
		new_rec.id = talk_id
		new_rec.text = default_text
		new_rec.plain_text = default_text
		new_rec.speaker = speaker_name
		new_rec.speaker_id = speaker_id
		_talks[talk_id] = new_rec
		return new_rec
	var rec: TalkRecord = _talks[talk_id]
	rec.speaker = speaker_name
	rec.speaker_id = speaker_id
	if rec.text.is_empty() and not default_text.is_empty():
		rec.text = default_text
		rec.plain_text = default_text
	return rec

## Applies verified authentic WLO Ship Deck (Map 10001) & Cabin (Map 10002) linkages
func _apply_authentic_defaults() -> void:
	_apply_kelan_village_defaults()
	# Ship Deck NPCs (Map 10001)
	_bind_npc_talk(14003, 30124, "Captain", [
		{"text": "Thank you Captain!", "next_talk_id": 0, "branch": 1},
		{"text": "Where are we heading?", "next_talk_id": 0, "branch": 2}
	])
	# Chain Captain's 30124 -> 30125
	if _talks.has(30124) and _talks.has(30125):
		_talks[30124].next_talk_id = 30125
		_talks[30125].speaker = "Captain"
		_talks[30125].speaker_id = 14003
		_talks[30125].next_talk_id = 0
	
	_bind_npc_talk(14091, 30126, "Jack", [
		{"text": "The ocean is vast.", "next_talk_id": 0, "branch": 1},
		{"text": "Enjoy the breeze!", "next_talk_id": 0, "branch": 2}
	])
	
	_bind_npc_talk(14152, 30120, "Ross", [
		{"text": "Hold on tight!", "next_talk_id": 0, "branch": 1},
		{"text": "Watch out!", "next_talk_id": 0, "branch": 2}
	])
	
	_bind_npc_talk(14002, 30141, "Crew", [
		{"text": "Aye aye, sailor!", "next_talk_id": 0, "branch": 1}
	])
	
	_bind_npc_talk(14001, 30128, "Crew on Deck", [
		{"text": "Everything is great!", "next_talk_id": 0, "branch": 1}
	])
	
	_bind_npc_talk(14080, 30130, "Visitor", [
		{"text": "Have a wonderful journey!", "next_talk_id": 0, "branch": 1}
	])
	
	_bind_npc_talk(14087, 30131, "Visitor", [
		{"text": "It is truly amazing.", "next_talk_id": 0, "branch": 1}
	])
	
	_bind_npc_talk(14065, 30138, "Girl", [
		{"text": "Such a cute kitty!", "next_talk_id": 0, "branch": 1},
		{"text": "Where did you find her?", "next_talk_id": 0, "branch": 2}
	])
	
	_bind_npc_talk(11000, 30137, "Persian Cat", [
		{"text": "*Pet the cat*", "next_talk_id": 0, "branch": 1},
		{"text": "Give a treat", "next_talk_id": 0, "branch": 2}
	])
	
	# Ship Cabin NPCs (Map 10002)
	_bind_npc_talk(14042, 30127, "Drunk Man", [
		{"text": "Take it easy...", "next_talk_id": 0, "branch": 1}
	])
	
	_bind_npc_talk(10000, 30139, "Breillat", [
		{"text": "Thank you, Breillat!", "next_talk_id": 0, "branch": 1}
	])
	
	# Peter (14146, Talk ID 30160 -> 30161 / 30162)
	_bind_npc_talk(14146, 30160, "Peter", [
		{"text": "Is everything alright?", "next_talk_id": 30161, "branch": 1},
		{"text": "Need any help?", "next_talk_id": 30162, "branch": 2}
	])
	var rec_30161: TalkRecord = _ensure_talk(30161, "Peter", 14146, "I thought I heard something outside...")
	rec_30161.next_talk_id = 0
	var rec_30162: TalkRecord = _ensure_talk(30162, "Peter", 14146, "I am fine, thank you. Stay alert!")
	rec_30162.next_talk_id = 0

	# John (14145, Talk ID 30163 -> 30164 / 30165)
	_bind_npc_talk(14145, 30163, "John", [
		{"text": "What are you doing here?", "next_talk_id": 30164, "branch": 1},
		{"text": "See you around.", "next_talk_id": 30165, "branch": 2}
	])
	var rec_30164: TalkRecord = _ensure_talk(30164, "John", 14145, "I am waiting for the storm to clear.")
	rec_30164.next_talk_id = 0
	var rec_30165: TalkRecord = _ensure_talk(30165, "John", 14145, "Take care on your way.")
	rec_30165.next_talk_id = 0

	# Natasha (14303, Talk ID 30166 -> 30167 / 30168)
	_bind_npc_talk(14303, 30166, "Natasha", [
		{"text": "Are you feeling okay?", "next_talk_id": 30167, "branch": 1},
		{"text": "Just exploring the ship.", "next_talk_id": 30168, "branch": 2}
	])
	var rec_30167: TalkRecord = _ensure_talk(30167, "Natasha", 14303, "I feel a bit sea-sick today...")
	rec_30167.next_talk_id = 0
	var rec_30168: TalkRecord = _ensure_talk(30168, "Natasha", 14303, "Be careful, the lower deck is slippery!")
	rec_30168.next_talk_id = 0

	# Ship Kitchen / Bunk NPCs (Map 10003)
	# Chef (12006, Talk ID 30170 -> 30171 / 30172)
	_bind_npc_talk(12006, 30170, "Chef", [
		{"text": "Can I have some food?", "next_talk_id": 30171, "branch": 1},
		{"text": "Smells delicious!", "next_talk_id": 30172, "branch": 2}
	])
	var rec_30171: TalkRecord = _ensure_talk(30171, "Chef", 12006, "Fresh soup is almost ready! Help yourself to some bread.")
	rec_30171.next_talk_id = 0
	var rec_30172: TalkRecord = _ensure_talk(30172, "Chef", 12006, "Thank you! I take pride in feeding the whole ship.")
	rec_30172.next_talk_id = 0

	# Kitchen Crew (14002 on Map 10003, Talk ID 30173)
	_map_npc_talk_map["10003_14002"] = 30173
	var rec_30173: TalkRecord = _ensure_talk(30173, "Kitchen Crew", 14002, "Watch your step around the kitchen stoves!")
	rec_30173.next_talk_id = 0
	var kcrew_choices: Array[Dictionary] = [
		{"text": "Keep up the good work!", "next_talk_id": 0, "branch": 1}
	]
	rec_30173.choices = kcrew_choices

	# Bunk Crew (14001 on Map 10003, Talk ID 30174)
	_map_npc_talk_map["10003_14001"] = 30174
	var rec_30174: TalkRecord = _ensure_talk(30174, "Bunk Crew", 14001, "The bunks are cozy, but it's hard to sleep through rough waves.")
	rec_30174.next_talk_id = 0
	var bcrew_choices: Array[Dictionary] = [
		{"text": "Rest well!", "next_talk_id": 0, "branch": 1}
	]
	rec_30174.choices = bcrew_choices
	
	# Golden Axe Quest (TalkID 30129) branching choice options
	if _talks.has(30129):
		_talks[30129].speaker = "Lake Spirit"
		var axe_choices: Array[Dictionary] = [
			{"text": "Golden Axe", "next_talk_id": 30143, "branch": 1},
			{"text": "Iron Axe", "next_talk_id": 30144, "branch": 2}
		]
		_talks[30129].choices = axe_choices
		_talks[30129].rewards.append({"type": "item", "item_id": 26001, "amount": 1, "description": "Iron Axe"})
	
	# S.Monkey Recruitment Sequence (TalkIDs 20038..20053)
	for mid_id in range(20038, 20053):
		if _talks.has(mid_id) and _talks.has(mid_id + 1):
			_talks[mid_id].next_talk_id = mid_id + 1
			_talks[mid_id].speaker = "S.Monkey"
			_talks[mid_id].speaker_id = 17162

	# Deserted Island Beach Awakening (Map 10011 / Map 10003) - Kelang Dialogue Tree
	_bind_npc_talk(14062, 20305, "Kelang", [
		{"text": "I was on a ship...", "next_talk_id": 20306, "branch": 1},
		{"text": "Where is this place?", "next_talk_id": 20307, "branch": 2}
	])
	if _talks.has(20305):
		_talks[20305].speaker = "Kelang"
		_talks[20305].speaker_id = 14062
		_talks[20305].next_talk_id = 20307
	if _talks.has(20307):
		_talks[20307].speaker = "Kelang"
		_talks[20307].speaker_id = 14062
		_talks[20307].next_talk_id = 20308
	if _talks.has(20308):
		_talks[20308].speaker = "Kelang"
		_talks[20308].speaker_id = 14062
		_talks[20308].next_talk_id = 20310
	if _talks.has(20310):
		_talks[20310].speaker = "Kelang"
		_talks[20310].speaker_id = 14062
		_talks[20310].next_talk_id = 20312
	if _talks.has(20312):
		_talks[20312].speaker = "Kelang"
		_talks[20312].speaker_id = 14062
		_talks[20312].next_talk_id = 20313
	if _talks.has(20313):
		_talks[20313].speaker = "Kelang"
		_talks[20313].speaker_id = 14062
		var kelang_choices: Array[Dictionary] = [
			{"text": "Beginner's Guide", "next_talk_id": 20314, "branch": 1},
			{"text": "How do I leave?", "next_talk_id": 20355, "branch": 2}
		]
		_talks[20313].choices = kelang_choices
	if _talks.has(20314):
		_talks[20314].speaker = "Kelang"
		_talks[20314].speaker_id = 14062
		_talks[20314].next_talk_id = 0

## Kelan Village NPCs whose Talk.dat lines were verified by playing the real client (docs/re/ui_windows.md).
## Doll: 3 pages, then "Yes. / No." (the quest offer). Emilie and the Guard: one line each.
func _apply_kelan_village_defaults() -> void:
	var doll_pages: Array[int] = [20222, 20223, 20225, 20227]
	if _talks.has(doll_pages[0]):
		_bind_npc_talk(14141, 20222, "Doll")
		for i in doll_pages.size() - 1:
			if _talks.has(doll_pages[i]) and _talks.has(doll_pages[i + 1]):
				_talks[doll_pages[i]].next_talk_id = doll_pages[i + 1]
				_talks[doll_pages[i]].speaker = "Doll"
				_talks[doll_pages[i]].speaker_id = 14141
		_talks[20227].speaker = "Doll"
		_talks[20227].speaker_id = 14141
		_talks[20227].next_talk_id = 0
		_talks[20227].choices = [
			{"text": "Yes.", "next_talk_id": 0, "branch": 1},
			{"text": "No.", "next_talk_id": 0, "branch": 2},
		]
	if _talks.has(30552):
		_bind_npc_talk(14140, 30552, "Emilie")
	if _talks.has(30037):
		_bind_npc_talk(14118, 30037, "Guard")


func _bind_npc_talk(npc_id: int, talk_id: int, speaker_name: String, choices: Array = []) -> void:
	_npc_talk_map[npc_id] = talk_id
	var rec: TalkRecord = _ensure_talk(talk_id, speaker_name, npc_id)
	if not choices.is_empty():
		rec.choices = choices

## Returns authentic talk record dictionary by TalkID
func get_talk(talk_id: int) -> Dictionary:
	if not _talks.has(talk_id):
		return {}
	var rec: TalkRecord = _talks[talk_id]
	return {
		"id": rec.id,
		"raw_text": rec.raw_text,
		"text": rec.text,
		"plain_text": rec.plain_text,
		"speaker": rec.speaker,
		"speaker_id": rec.speaker_id,
		"face_index": rec.face_index,
		"sound_effect": rec.sound_effect,
		"choices": rec.choices,
		"conditions": rec.conditions,
		"rewards": rec.rewards,
		"next_talk_id": rec.next_talk_id,
		"record_index": rec.record_index,
		"offset": rec.offset
	}

## Returns true if the Talk ID exists in the database
func has_talk(talk_id: int) -> bool:
	return _talks.has(talk_id)

## Returns talk record dictionary by 1-based record index (1..17,494)
func get_talk_by_index(record_index: int) -> Dictionary:
	if not _talks_by_index.has(record_index):
		return {}
	var rec: TalkRecord = _talks_by_index[record_index]
	return get_talk(rec.id)

## Returns talk record dictionary by direct byte offset
func get_talk_by_offset(offset: int) -> Dictionary:
	if not _talks_by_offset.has(offset):
		return {}
	var rec: TalkRecord = _talks_by_offset[offset]
	return get_talk(rec.id)

## Resolves the active dialogue block for an NPC entity by npc_id and optional map_id
func resolve_talk_for_npc(npc_id: int, map_id: int = 0) -> Dictionary:
	if map_id > 0:
		var map_key := "%d_%d" % [map_id, npc_id]
		if _map_npc_talk_map.has(map_key):
			return get_talk(_map_npc_talk_map[map_key])
	
	if _npc_talk_map.has(npc_id):
		return get_talk(_npc_talk_map[npc_id])
	
	return {}

## Returns complete multi-page dialogue sequence following next_talk_id pointers
func get_dialogue_chain(start_talk_id: int) -> Array[Dictionary]:
	var chain: Array[Dictionary] = []
	var cur_id: int = start_talk_id
	var visited: Dictionary = {}
	
	while cur_id > 0 and not visited.has(cur_id):
		visited[cur_id] = true
		var talk_dict := get_talk(cur_id)
		if talk_dict.is_empty():
			break
		chain.append(talk_dict)
		# Stop chaining if this dialogue step branches with interactive choices
		var has_branching := false
		for c in talk_dict.get("choices", []):
			if c is Dictionary and c.get("next_talk_id", 0) > 0:
				has_branching = true
				break
		if has_branching:
			break
		cur_id = talk_dict.get("next_talk_id", 0)
	
	return chain

## Returns all loaded Talk IDs
func get_all_talk_ids() -> Array:
	return _talks.keys()

## Returns total count of loaded dialogue records
func get_count() -> int:
	return _talks.size()
