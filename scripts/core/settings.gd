extends Node
## Player settings (autoload `Settings`), saved in a `ConfigFile`.

const PATH := "user://settings.cfg"

var gearbox_mode := Gearbox.Mode.AUTOMATIC


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		gearbox_mode = config.get_value("gameplay", "gearbox_mode", gearbox_mode)


func set_gearbox_mode(mode: Gearbox.Mode) -> void:
	gearbox_mode = mode
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value("gameplay", "gearbox_mode", gearbox_mode)
	config.save(PATH)
