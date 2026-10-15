class_name Hud
extends CanvasLayer
## In-stage HUD: gear, engine RPM and speed of the target car.

var car: Car

@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	if car == null:
		return
	var gearbox := car.drivetrain.gearbox
	var gear := "R" if gearbox.gear == Gearbox.REVERSE \
		else "N" if gearbox.gear == Gearbox.NEUTRAL else str(gearbox.gear)
	_label.text = "%s\n%d rpm\n%d km/h" % [gear, roundi(car.drivetrain.rpm),
		roundi(car.linear_velocity.length() * 3.6)]
