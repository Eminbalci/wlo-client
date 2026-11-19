class_name SkillExpressWindow
extends Control

## Element skill tree ("Intro" tab, Go client: skills/form.go, form_skillexpress<element>).
## Geometry is the Go constants in form-local pixels: the element background at (69,87); three
## columns of six nodes at x 69/128/186 and y 129 + 34*row, 28 px icons. A node shows only when the
## character has learned it (grade != 0). Hovering a node shows its name, description and the
## attribute requirements; the requirement text sits at (100,395).

signal node_hovered(index: int)

const TREE_COLUMNS := 3
const TREE_ROWS := 6
const FIRST_Y := 129
const STEP_Y := 34
const ICON_SIZE := 28
const COLUMN_X := [69, 128, 186]
const BACKGROUND_POS := Vector2(69, 87)
const BACKGROUND_DIR := "res://assets/menu/Skins/white/form_skillexpress%d.bmp"
const SkillExpressTable := preload("res://scripts/data/skill_express_table.gd")

var element: int = 1
## skill id -> learned grade (0 or missing = not learned). Supplied by the owner of the character.
var grades: Dictionary = {}
var _rows: Array = []
var _background: TextureRect


func _ready() -> void:
	visible = false
	_background = TextureRect.new()
	_background.name = "Background"
	_background.stretch_mode = TextureRect.STRETCH_KEEP
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.position = BACKGROUND_POS
	add_child(_background)
	set_element(element)


## Switches the tree to an element (1..4) and loads its background picture.
func set_element(value: int) -> void:
	element = clampi(value, 1, 4)
	_rows = SkillExpressTable.rows_for_element(element)
	if _background:
		var path := BACKGROUND_DIR % element
		_background.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null


func set_grades(value: Dictionary) -> void:
	grades = value


## Top-left of the node at tree index `i` (Go treePoint).
static func tree_point(i: int) -> Vector2:
	var column := clampi(i / TREE_ROWS, 0, TREE_COLUMNS - 1)
	return Vector2(COLUMN_X[column], FIRST_Y + (i % TREE_ROWS) * STEP_Y)


## Number of nodes the tree shows (the Go loop stops at 18).
func node_count() -> int:
	return mini(_rows.size(), TREE_COLUMNS * TREE_ROWS)


func is_learned(skill_id: int) -> bool:
	return int(grades.get(skill_id, 0)) != 0


## Index of the node under a form-local point, or -1.
func node_at(point: Vector2) -> int:
	for i in node_count():
		var p := tree_point(i) + BACKGROUND_POS
		if Rect2(p, Vector2(ICON_SIZE, ICON_SIZE)).has_point(point):
			return i
	return -1


## Learned nodes in tree order: [{index, skill_id}].
func learned_nodes() -> Array:
	var out: Array = []
	for i in node_count():
		var skill_id: int = _rows[i][1]
		if is_learned(skill_id):
			out.append({"index": i, "skill_id": skill_id})
	return out


## Requirement text for the node at `i` (Go requirements()); "None" when there is none.
func requirement_text(i: int) -> String:
	if i < 0 or i >= _rows.size():
		return ""
	return SkillExpressWindow.format_requirements(_rows[i][2], _rows[i][3], _rows[i][4], _rows[i][5], _rows[i][6])


static func format_requirements(strength: int, constitution: int, intelligence: int, wisdom: int, agility: int) -> String:
	var parts: Array[String] = []
	var labels := ["STR", "CON", "INT", "WIS", "AGI"]
	var values := [strength, constitution, intelligence, wisdom, agility]
	for k in labels.size():
		if values[k] != 0:
			parts.append("%s %d" % [labels[k], values[k]])
	return "None" if parts.is_empty() else ", ".join(parts)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hit := node_at((event as InputEventMouseMotion).position)
		if hit >= 0:
			node_hovered.emit(hit)
