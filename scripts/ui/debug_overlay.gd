class_name DebugOverlay
extends CanvasLayer
## F1 handling overlay: per-wheel load, slip angle, slip ratio and surface of the target car.

var car: Car

@onready var _label: Label = $Label


func _ready() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		visible = not visible


func _process(_delta: float) -> void:
	if car == null or not visible:
		return
	var lines := PackedStringArray(["wheel   load N  slip°   ratio  surface"])
	for wheel in car.wheels:
		var collider := wheel.get_collider() if wheel.is_grounded else null
		var surface: String = collider.get_meta("surface", "-") if collider != null else "-"
		lines.append("%-6s %7.0f %6.1f %7.2f  %s" % [wheel.name.trim_prefix("Wheel"), wheel.normal_load,
			rad_to_deg(wheel.slip_angle), wheel.slip_ratio, surface])
	_label.text = "\n".join(lines)
