class_name Car
extends RigidBody3D
## Player car: rigid body on four raycast wheels. Reads tunables through a `StatBlock` and
## driver input only through its `InputSource`.

@export var car_stats: CarStats

var stats: StatBlock
var input := InputSource.new()
var drivetrain := Drivetrain.new()
var wheels: Array[Wheel] = []


func _ready() -> void:
	stats = StatBlock.new(car_stats.stats)
	mass = stats.get_stat("mass")
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, stats.get_stat("center_of_mass_y"), 0.0)
	drivetrain.gearbox.mode = Settings.gearbox_mode
	for child in get_children():
		if child is Wheel:
			wheels.append(child)


func _physics_process(delta: float) -> void:
	input.update(delta, linear_velocity.length())
	drivetrain.update(input, wheels, stats, car_stats.torque_curve, linear_velocity.length(), delta)
	# Max lock shrinks with speed so full input stays near the tires' peak slip angle.
	var lock_t := clampf(linear_velocity.length() / stats.get_stat("steer_reduction_speed"), 0.0, 1.0)
	var max_lock := lerpf(stats.get_stat("max_steer_angle_deg"), stats.get_stat("min_steer_angle_deg"), lock_t)
	var steer_angle := -input.steer * deg_to_rad(max_lock)
	for wheel in wheels:
		if wheel.steerable:
			wheel.rotation.y = steer_angle
		wheel.update_suspension(self, stats, delta)
		wheel.update_tire(self, stats, delta)
		wheel.update_visual(stats, delta)
