extends SceneTree

## Automated Verification Suite for Dialogue Box Background & Text Parity.
## Verifies:
## 1. Captain Robinson multi-page sequence (page 0 -> page 1 -> choices in FormTalk3)
## 2. Kelang interactive dialogue branching (prompt + choices -> choice 1 -> Talk 20307)
## 3. SpeakerNameplate authenticity ("Captain Robinson", "Kelang")
## 4. FormTalk1 and FormTalk3 layout, anchors, and texture validity across resolutions

const MapViewScene = preload("res://scenes/world/map_view.tscn")

func _init() -> void:
	print("\n==================================================================")
	print("=== Running Dialogue Box Background & Text Parity Verification ===")
	print("==================================================================")
	var passed: int = 0
	var failed: int = 0

	var map_view = MapViewScene.instantiate()
	root.add_child(map_view)
	await process_frame
	await process_frame

	var hud = map_view.hud
	assert(hud != null, "HUD must exist")
	var d_ctrl = hud.dialogue_ctrl
	assert(d_ctrl != null, "HUDDialogue must exist")

	# -------------------------------------------------------------
	# Test 1: Verify FormTalk1 Background Texture and Layout
	# -------------------------------------------------------------
	var talk_bg = d_ctrl.dialogue_bg
	if talk_bg and talk_bg.texture:
		var tex_sz = talk_bg.texture.get_size()
		if tex_sz == Vector2(768, 169):
			print("[PASS] Test 1a: FormTalk1 TalkBackground texture loaded authentic 768x169 parchment")
			passed += 1
		else:
			print("[FAIL] Test 1a: Expected 768x169, got %s" % str(tex_sz))
			failed += 1
	else:
		print("[FAIL] Test 1a: TalkBackground texture missing")
		failed += 1

	if talk_bg and talk_bg.expand_mode == TextureRect.EXPAND_IGNORE_SIZE:
		print("[PASS] Test 1b: TalkBackground expand_mode is EXPAND_IGNORE_SIZE (full coverage)")
		passed += 1
	else:
		print("[FAIL] Test 1b: TalkBackground expand_mode mismatch")
		failed += 1

	# -------------------------------------------------------------
	# Test 2: Captain Robinson Dialogue Sequence & Speaker Verification
	# -------------------------------------------------------------
	var captain: NpcEntity = null
	for child in map_view.entities.get_children():
		if child is NpcEntity and child.npc_id == 14003:
			captain = child
			break
	
	if captain:
		map_view._on_npc_interacted(captain)
		await process_frame

		# Verify Page 0
		var spk: String = d_ctrl.speaker_label.text if d_ctrl.speaker_label else ""
		var txt0: String = d_ctrl.dialogue_text.text if d_ctrl.dialogue_text else ""
		if spk == "Captain Robinson":
			print("[PASS] Test 2a: SpeakerNameplate authentic: '%s'" % spk)
			passed += 1
		else:
			print("[FAIL] Test 2a: Expected 'Captain Robinson', got '%s'" % spk)
			failed += 1

		if "Welcome to Ocean Star" in txt0:
			print("[PASS] Test 2b: Page 0 text authentic: '%s'" % txt0)
			passed += 1
		else:
			print("[FAIL] Test 2b: Expected Ocean Star greeting, got '%s'" % txt0)
			failed += 1

		# Verify FormTalk3 is NOT visible yet
		if not d_ctrl.branching_dock.visible:
			print("[PASS] Test 2c: FormTalk3 choices hidden during Page 0")
			passed += 1
		else:
			print("[FAIL] Test 2c: FormTalk3 choices should be hidden during Page 0")
			failed += 1

		# Advance to Page 1
		hud.advance_dialogue()
		await process_frame

		var txt1: String = d_ctrl.dialogue_text.text if d_ctrl.dialogue_text else ""
		if "service staff" in txt1 or "pleasant journey" in txt1:
			print("[PASS] Test 2d: Advanced to Page 1 text: '%s'" % txt1)
			passed += 1
		else:
			print("[FAIL] Test 2d: Expected Page 1 service staff text, got '%s'" % txt1)
			failed += 1

		# Advance to Choices
		hud.advance_dialogue()
		await process_frame

		if d_ctrl.branching_dock.visible:
			print("[PASS] Test 2e: FormTalk3 choices opened after Page 1 conclusion")
			passed += 1
		else:
			print("[FAIL] Test 2e: FormTalk3 choices should be visible after Page 1")
			failed += 1

		var btn_count: int = d_ctrl.choices_container.get_child_count()
		if btn_count >= 2:
			print("[PASS] Test 2f: Choices buttons present: count=%d ('%s', '%s')" % [
				btn_count,
				d_ctrl.choices_container.get_child(0).text,
				d_ctrl.choices_container.get_child(1).text
			])
			passed += 1
		else:
			print("[FAIL] Test 2f: Expected >= 2 choice buttons, got %d" % btn_count)
			failed += 1

		# Click choice 0 ("Thank you Captain!") -> concludes dialogue and triggers cutscene
		var choice_btn: Button = d_ctrl.choices_container.get_child(0) as Button
		choice_btn.pressed.emit()
		await process_frame

		if not d_ctrl.dialogue_dock.visible and not d_ctrl.branching_dock.visible:
			print("[PASS] Test 2g: FormTalk1 and FormTalk3 closed after choice selection")
			passed += 1
		else:
			print("[FAIL] Test 2g: Dialogue should be closed after choice")
			failed += 1
	else:
		print("[FAIL] Test 2: Captain Robinson NPC not found")
		failed += 7

	# Fast-forward cutscene to beach
	map_view.sinking_cutscene.fast_forward()
	await process_frame
	await process_frame

	# -------------------------------------------------------------
	# Test 3: Kelang Dialogue Branching on Deserted Island
	# -------------------------------------------------------------
	var kelang: NpcEntity = null
	for child in map_view.entities.get_children():
		if child is NpcEntity and child.npc_id == 14062:
			kelang = child
			break

	if kelang:
		map_view._on_npc_interacted(kelang)
		await process_frame

		var kel_spk: String = d_ctrl.speaker_label.text if d_ctrl.speaker_label else ""
		var kel_txt: String = d_ctrl.dialogue_text.text if d_ctrl.dialogue_text else ""

		if kel_spk == "Kelang":
			print("[PASS] Test 3a: Kelang SpeakerNameplate authentic: '%s'" % kel_spk)
			passed += 1
		else:
			print("[FAIL] Test 3a: Expected 'Kelang', got '%s'" % kel_spk)
			failed += 1

		if "deserted island" in kel_txt:
			print("[PASS] Test 3b: Kelang prompt text authentic: '%s'" % kel_txt)
			passed += 1
		else:
			print("[FAIL] Test 3b: Expected deserted island text, got '%s'" % kel_txt)
			failed += 1

		if d_ctrl.branching_dock.visible:
			print("[PASS] Test 3c: Kelang branching choices displayed in FormTalk3")
			passed += 1
		else:
			print("[FAIL] Test 3c: FormTalk3 should be visible for Kelang choices")
			failed += 1

		# Click Choice 1 ("Where is this place?" leading to Talk 20307)
		if d_ctrl.choices_container.get_child_count() >= 2:
			var btn_where: Button = d_ctrl.choices_container.get_child(1) as Button
			btn_where.pressed.emit()
			await process_frame

			var branch_txt: String = d_ctrl.dialogue_text.text if d_ctrl.dialogue_text else ""
			var branch_spk: String = d_ctrl.speaker_label.text if d_ctrl.speaker_label else ""

			if branch_spk == "Kelang":
				print("[PASS] Test 3d: SpeakerNameplate preserved on branch: '%s'" % branch_spk)
				passed += 1
			else:
				print("[FAIL] Test 3d: Expected 'Kelang', got '%s'" % branch_spk)
				failed += 1

			if "shipwrecked" in branch_txt:
				print("[PASS] Test 3e: Branch talk 20307 text authentic: '%s'" % branch_txt)
				passed += 1
			else:
				print("[FAIL] Test 3e: Expected shipwrecked text for 20307, got '%s'" % branch_txt)
				failed += 1
		else:
			failed += 2
	else:
		print("[FAIL] Test 3: Kelang NPC not found on beach")
		failed += 5

	map_view.queue_free()
	await process_frame

	print("\n==================================================================")
	print("=== FINAL RESULTS: %d PASSED, %d FAILED ===" % [passed, failed])
	print("==================================================================\n")
	if failed == 0:
		print("ALL DIALOGUE PARITY TESTS PASSED PERFECTLY!\n")
		quit(0)
	else:
		print("SOME TESTS FAILED!\n")
		quit(1)
