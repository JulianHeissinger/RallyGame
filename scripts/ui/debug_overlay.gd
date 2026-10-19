class_name DebugOverlay
extends CanvasLayer
## F1 handling overlay: per-wheel load, slip angle, slip ratio and surface of the target car, plus
## each part's condition and the damage factors it applies.

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
	var lines := PackedStringArray(["wheel   load N  slip°   ratio  grip  surface"])
	for wheel in car.wheels:
		var surface := wheel.surface if wheel.is_grounded else "-"
		lines.append("%-6s %7.0f %6.1f %7.2f  %4.2f  %s" % [wheel.name.trim_prefix("Wheel"),
			wheel.normal_load, rad_to_deg(wheel.slip_angle), wheel.slip_ratio, wheel.surface_grip, surface])
	lines.append("")
	lines.append("corner  tire  grip  drag  brake  force  susp   sag  stiff")
	var condition := car.damage.condition
	for wheel in car.wheels:
		var corner := wheel.name.trim_prefix("Wheel")
		var key := corner.to_lower()
		lines.append("%-6s %5.0f  %4.2f  %4.2f  %5.0f   %4.2f  %4.0f  %4.2f   %4.2f" % [corner,
			condition["tire_" + key], wheel.grip_factor, wheel.drag, condition["brake_" + key], wheel.brake_factor,
			condition["suspension_" + key], wheel.rest_factor, wheel.stiffness_factor])
	lines.append("engine  %4.0f  power %4.2f" % [condition["engine"], car.stats.damage_multiplier.get("max_torque", 1.0)])
	lines.append("chassis %4.0f" % condition["chassis"])
	_label.text = "\n".join(lines)
