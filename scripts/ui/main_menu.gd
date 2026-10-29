class_name MainMenu
extends Control
## Main menu: Start Stage with an optional seed (empty or 0 rolls a random one), the gearbox
## setting (saved by `Settings`) and Quit. Keyboard and controller move focus through the built-in
## `ui_*` actions; the seed field needs a keyboard to type, and a controller simply skips it.

const STAGE_SCENE := "res://scenes/stage.tscn"

@onready var _start: Button = %Start
@onready var _seed: LineEdit = %Seed
@onready var _gearbox: OptionButton = %Gearbox
@onready var _quit: Button = %Quit


func _ready() -> void:
	_gearbox.add_item("Automatic", Gearbox.Mode.AUTOMATIC)
	_gearbox.add_item("Manual", Gearbox.Mode.MANUAL)
	_gearbox.select(_gearbox.get_item_index(Settings.gearbox_mode))
	_gearbox.item_selected.connect(func(index: int) -> void:
			Settings.set_gearbox_mode(_gearbox.get_item_id(index) as Gearbox.Mode))
	_seed.text_changed.connect(_on_seed_changed)
	_seed.text_submitted.connect(func(_text: String) -> void: _start_stage())
	_start.pressed.connect(_start_stage)
	_quit.pressed.connect(get_tree().quit)
	_start.grab_focus()


## Seed from the field's text; 0 (empty) means random.
static func parse_seed(text: String) -> int:
	return text.to_int() if text.is_valid_int() else 0


func _start_stage() -> void:
	RunState.reset(parse_seed(_seed.text))
	get_tree().change_scene_to_file(STAGE_SCENE)


## Keeps only digits in the seed field.
func _on_seed_changed(text: String) -> void:
	var digits := ""
	for character in text:
		if character >= "0" and character <= "9":
			digits += character
	if digits == text:
		return
	var caret := _seed.caret_column
	_seed.text = digits
	_seed.caret_column = mini(caret, digits.length())
