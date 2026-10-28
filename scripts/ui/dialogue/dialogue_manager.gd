class_name DialogueManager
extends Node

## Central Coordinator for Wonderland Online Dialogue, Talk & Quest Interactions
## Manages active dialogue state, multi-page Talk.dat progression, speaker resolution,
## choice branches, quest status checks, and flexible DialogueBox UI bindings.

signal dialogue_started(talk_id: int, speaker: String)
signal page_changed(current_page: int, total_pages: int, text: String)
signal typewriter_completed()
signal choices_presented(choices: Array)
signal choice_selected(choice_index: int, choice_text: String)
signal dialogue_closed()
signal quest_reward_triggered(reward_data: Dictionary)

enum DialogueState {
	IDLE,
	TYPING,
	WAITING_INPUT,
	CHOICES_ACTIVE,
	CLOSED
}

@export var dialogue_box_path: NodePath = NodePath("")
@export var dialogue_box_scene: PackedScene = preload("res://scenes/ui/dialogue/dialogue_box.tscn")

var dialogue_box: DialogueBox = null
var current_state: DialogueState = DialogueState.IDLE

# Active Session State
var active_talk_id: int = 0
var active_speaker: String = ""
var active_pages: Array[String] = []
var active_page_index: int = 0
var active_choices: Array = []
var active_choice_callback: Callable = Callable()

func _enter_tree() -> void:
	ensure_initialized()

func _ready() -> void:
	ensure_initialized()

## Ensures DialogueBox instance and signals are bound
func ensure_initialized() -> void:
	if not dialogue_box or not is_instance_valid(dialogue_box):
		if not dialogue_box_path.is_empty():
			dialogue_box = get_node_or_null(dialogue_box_path) as DialogueBox
		if not dialogue_box and dialogue_box_scene:
			dialogue_box = dialogue_box_scene.instantiate() as DialogueBox
			add_child(dialogue_box)

	if dialogue_box:
		dialogue_box.ensure_initialized()
		_bind_dialogue_box_signals()

func set_dialogue_box(p_box: DialogueBox) -> void:
	if dialogue_box and is_instance_valid(dialogue_box):
		_unbind_dialogue_box_signals()

	dialogue_box = p_box
	if dialogue_box:
		dialogue_box.ensure_initialized()
		_bind_dialogue_box_signals()

func _bind_dialogue_box_signals() -> void:
	if not dialogue_box:
		return
	if not dialogue_box.dialogue_started.is_connected(_on_box_dialogue_started):
		dialogue_box.dialogue_started.connect(_on_box_dialogue_started)
	if not dialogue_box.dialogue_finished.is_connected(_on_box_dialogue_finished):
		dialogue_box.dialogue_finished.connect(_on_box_dialogue_finished)
	if not dialogue_box.page_changed.is_connected(_on_box_page_changed):
		dialogue_box.page_changed.connect(_on_box_page_changed)
	if not dialogue_box.typewriter_completed.is_connected(_on_box_typewriter_completed):
		dialogue_box.typewriter_completed.connect(_on_box_typewriter_completed)
	if not dialogue_box.choice_selected.is_connected(_on_box_choice_selected):
		dialogue_box.choice_selected.connect(_on_box_choice_selected)

func _unbind_dialogue_box_signals() -> void:
	if not dialogue_box or not is_instance_valid(dialogue_box):
		return
	if dialogue_box.dialogue_started.is_connected(_on_box_dialogue_started):
		dialogue_box.dialogue_started.disconnect(_on_box_dialogue_started)
	if dialogue_box.dialogue_finished.is_connected(_on_box_dialogue_finished):
		dialogue_box.dialogue_finished.disconnect(_on_box_dialogue_finished)
	if dialogue_box.page_changed.is_connected(_on_box_page_changed):
		dialogue_box.page_changed.disconnect(_on_box_page_changed)
	if dialogue_box.typewriter_completed.is_connected(_on_box_typewriter_completed):
		dialogue_box.typewriter_completed.disconnect(_on_box_typewriter_completed)
	if dialogue_box.choice_selected.is_connected(_on_box_choice_selected):
		dialogue_box.choice_selected.disconnect(_on_box_choice_selected)

# ==============================================================================
# Dialogue Playback API
# ==============================================================================

## Starts a dialogue sequence with raw text and optional choices
func start_dialogue(
	speaker: String,
	text: String,
	choices: Array = [],
	portrait_tex: Texture2D = null,
	portrait_id: int = 0,
	speaker_side: DialogueBox.SpeakerSide = DialogueBox.SpeakerSide.LEFT,
	choice_callback: Callable = Callable()
) -> void:
	start_dialogue_chain(
		speaker,
		[text],
		choices,
		portrait_tex,
		portrait_id,
		speaker_side,
		choice_callback
	)

## Starts a multi-page dialogue sequence
func start_dialogue_chain(
	speaker: String,
	pages: Array,
	choices: Array = [],
	portrait_tex: Texture2D = null,
	portrait_id: int = 0,
	speaker_side: DialogueBox.SpeakerSide = DialogueBox.SpeakerSide.LEFT,
	choice_callback: Callable = Callable()
) -> void:
	ensure_initialized()

	active_talk_id = 0
	active_speaker = speaker
	active_pages.clear()
	for p in pages:
		active_pages.append(str(p))

	active_choices = choices
	active_choice_callback = choice_callback
	active_page_index = 0
	current_state = DialogueState.TYPING

	if dialogue_box:
		dialogue_box.show_dialogue_sequence(
			speaker,
			active_pages,
			choices,
			portrait_tex,
			portrait_id,
			speaker_side
		)

## Resolves and plays authentic dialogue from TalkDatabase by Talk ID
func start_talk_id(talk_id: int, player_name: String = "", custom_speaker: String = "") -> bool:
	ensure_initialized()

	var talk_db = _get_talk_database()
	if not talk_db:
		push_error("DialogueManager: TalkDatabase not available")
		return false

	var chain: Array[Dictionary] = []
	if talk_db.has_method("get_dialogue_chain"):
		chain = talk_db.get_dialogue_chain(talk_id)

	if chain.is_empty():
		var single = talk_db.get_talk(talk_id) if talk_db.has_method("get_talk") else {}
		if not single.is_empty():
			chain.append(single)

	if chain.is_empty():
		push_warning("DialogueManager: No dialogue record found for Talk ID %d" % talk_id)
		return false

	active_talk_id = talk_id
	active_pages.clear()

	var resolved_speaker: String = custom_speaker
	var resolved_choices: Array = []
	var portrait_id: int = 0

	for i in range(chain.size()):
		var step: Dictionary = chain[i]
		var step_text: String = str(step.get("text", ""))
		active_pages.append(step_text)

		if resolved_speaker.is_empty() and step.has("speaker"):
			resolved_speaker = str(step.get("speaker", ""))

		# Check for choices on final step
		if i == chain.size() - 1 and step.has("choices") and step["choices"] is Array:
			resolved_choices = step["choices"]

		# Sound effect trigger
		if step.has("sound_effect") and not str(step["sound_effect"]).is_empty():
			_play_sfx(str(step["sound_effect"]))

	# Resolve speaker portrait
	portrait_id = _resolve_portrait_id(resolved_speaker, talk_id)

	active_speaker = resolved_speaker if not resolved_speaker.is_empty() else "NPC"
	active_choices = resolved_choices
	current_state = DialogueState.TYPING

	if dialogue_box:
		dialogue_box.show_dialogue_sequence(
			active_speaker,
			active_pages,
			resolved_choices,
			null,
			portrait_id,
			DialogueBox.SpeakerSide.LEFT
		)

	dialogue_started.emit(talk_id, active_speaker)
	return true

## Advances active dialogue
func advance() -> void:
	if dialogue_box:
		dialogue_box.advance_dialogue()

## Selects choice by index
func select_choice(choice_index: int) -> void:
	if dialogue_box and dialogue_box.choices_container:
		if choice_index >= 0 and choice_index < dialogue_box.choices_container.get_child_count():
			var btn = dialogue_box.choices_container.get_child(choice_index) as Button
			if btn:
				btn.emit_signal("pressed")

## Closes dialogue
func close() -> void:
	if dialogue_box:
		dialogue_box.hide_dialogue()
	current_state = DialogueState.CLOSED
	dialogue_closed.emit()

func is_active() -> bool:
	return current_state != DialogueState.IDLE and current_state != DialogueState.CLOSED

# ==============================================================================
# Signal Callbacks
# ==============================================================================

func _on_box_dialogue_started(speaker: String) -> void:
	current_state = DialogueState.TYPING
	dialogue_started.emit(active_talk_id, speaker)

func _on_box_dialogue_finished() -> void:
	current_state = DialogueState.CLOSED
	active_talk_id = 0
	active_pages.clear()
	active_choices.clear()
	dialogue_closed.emit()

func _on_box_page_changed(page_idx: int, total_pages: int) -> void:
	active_page_index = page_idx
	current_state = DialogueState.TYPING
	var cur_text: String = active_pages[page_idx] if page_idx < active_pages.size() else ""
	page_changed.emit(page_idx, total_pages, cur_text)

func _on_box_typewriter_completed() -> void:
	if active_page_index >= active_pages.size() - 1 and not active_choices.is_empty():
		current_state = DialogueState.CHOICES_ACTIVE
		choices_presented.emit(active_choices)
	else:
		current_state = DialogueState.WAITING_INPUT
	typewriter_completed.emit()

func _on_box_choice_selected(idx: int, txt: String) -> void:
	current_state = DialogueState.CLOSED
	if active_choice_callback.is_valid():
		active_choice_callback.call(idx, txt)
	choice_selected.emit(idx, txt)

# ==============================================================================
# Helper Methods
# ==============================================================================

func _resolve_portrait_id(speaker: String, talk_id: int) -> int:
	var s_low := speaker.to_lower()
	if "captain" in s_low or talk_id in [14003, 30124, 30125]:
		return 8025
	elif "kelang" in s_low or "kelan" in s_low or talk_id in [14062, 20305, 20307]:
		return 8038
	elif "jack" in s_low or talk_id == 30126:
		return 8004
	elif "ross" in s_low or talk_id == 30120:
		return 8005
	elif "drunk" in s_low or "peter" in s_low or "john" in s_low:
		return 8017
	elif "natasha" in s_low:
		return 8083
	elif "breillat" in s_low:
		return 8092
	elif "chef" in s_low or "cook" in s_low:
		return 8021
	elif "crew" in s_low or "sailor" in s_low:
		return 8026
	elif "girl" in s_low:
		return 8003
	return 0

func _play_sfx(sfx_name: String) -> void:
	if dialogue_box and dialogue_box.has_method("_play_sfx"):
		var p: String = "res://assets/sound/%s.wav" % sfx_name.replace(".wav", "").replace(".WAV", "")
		if ResourceLoader.exists(p):
			var stream = load(p)
			dialogue_box._play_sfx(stream)

func _get_talk_database() -> Object:
	var loop = Engine.get_main_loop()
	if loop is SceneTree and loop.root:
		var gdb = loop.root.get_node_or_null("GameDatabase")
		if gdb and "talks" in gdb and gdb.talks:
			return gdb.talks
	if is_inside_tree() and get_tree().root:
		var gdb = get_tree().root.get_node_or_null("GameDatabase")
		if gdb and "talks" in gdb and gdb.talks:
			return gdb.talks

	# Fallback directly load TalkDatabase
	var td_res = load("res://scripts/database/talk_database.gd")
	if td_res:
		var td = td_res.new()
		var p := "res://assets/data/Talk.dat"
		if not FileAccess.file_exists(p):
			p = "D:/GitHub/WLRI/data/Talk.dat"
		if FileAccess.file_exists(p):
			td.load_from_file(p)
			return td
	return null
