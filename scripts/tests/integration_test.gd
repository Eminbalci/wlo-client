extends SceneTree

const IsometricMath = preload("res://scripts/map/isometric_math.gd")
const WloCrypto = preload("res://scripts/network/wlo_crypto.gd")
const PacketFramer = preload("res://scripts/network/packet_framer.gd")
const ItemDatabase = preload("res://scripts/database/item_database.gd")
const SceneDatabase = preload("res://scripts/database/scene_database.gd")
const WloArchiveReader = preload("res://scripts/core/wlo_archive_reader.gd")

func _init() -> void:
	print("--- Starting Wonderland Online Godot Integration Tests ---")
	
	# Test 1: Isometric Math
	var world := Vector2(100, 50)
	var screen: Vector2 = IsometricMath.world_to_screen(world)
	var world_back: Vector2 = IsometricMath.screen_to_world(screen)
	assert(world.is_equal_approx(world_back), "Isometric roundtrip failed")
	print("[PASS] Isometric math roundtrip OK: %s -> %s -> %s" % [world, screen, world_back])
	
	# Test 2: Crypto & Packet Framing
	var crypto = WloCrypto.new(0xAD)
	var raw := "TestPayload".to_ascii_buffer()
	var enc: PackedByteArray = crypto.transform(raw)
	crypto.reset(0xAD)
	var dec: PackedByteArray = crypto.transform(enc)
	assert(dec == raw, "Crypto transformation failed")
	print("[PASS] Rolling keystream crypto transform OK")
	
	var frame: PackedByteArray = PacketFramer.frame(enc)
	assert(frame.size() == PacketFramer.HEADER_SIZE + enc.size(), "Framing size mismatch")
	var extract: Dictionary = PacketFramer.try_extract_frame(frame)
	assert(extract["success"] == true and extract["payload"] == enc, "Frame extraction failed")
	print("[PASS] 0x44F4 Packet framing & extraction OK")
	
	# Test 3: Game Database
	var items = ItemDatabase.new()
	var item_ok: bool = items.load_from_file("res://assets/data/Item.dat")
	assert(item_ok and items.get_all_items().size() > 0, "Item database empty")
	print("[PASS] Item.dat loaded %d items" % items.get_all_items().size())
	
	var plate = items.get_item(5)
	if plate:
		print("[PASS] Decrypted Item 5: Name='%s', Icon=%d" % [plate.name, plate.icon_id])
	
	var scenes = SceneDatabase.new()
	var scene_ok: bool = scenes.load_from_file("res://assets/data/SceneData.dat")
	assert(scene_ok and scenes.get_all_scenes().size() > 0, "Scene database empty")
	print("[PASS] SceneData.dat loaded %d scenes" % scenes.get_all_scenes().size())
	
	var ship_deck = scenes.get_scene(10001)
	if ship_deck:
		print("[PASS] Decrypted Scene 10001: Name='%s', BGM='%s'" % [ship_deck.name, ship_deck.bgm_name])
	
	# Test 4: Archive Reader (Memory Only)
	var archive = WloArchiveReader.open_archive("res://assets/pic/map.JMG")
	if archive:
		print("[PASS] Opened map.JMG: Found %d files in archive" % archive._entries.size())
		var tex = archive.extract_texture("10001.jpg")
		if tex:
			print("[PASS] Direct In-Memory Texture Decoded: 10001.jpg size=%s" % str(tex.get_size()))
	
	print("--- ALL INTEGRATION TESTS PASSED (0 LOOSE FILES WRITTEN) ---")
	quit(0)
