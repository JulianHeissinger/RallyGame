class_name Car
extends RigidBody3D
## Player car: rigid body on four raycast wheels. Reads tunables through a `StatBlock` and
## driver input only through its `InputSource`.

@export var car_stats: CarStats

var stats: StatBlock
var input := InputSource.new()
var wheels: Array[Wheel] = []


func _ready() -> void:
	stats = StatBlock.new(car_stats.stats)
	mass = stats.get_stat("mass")
	for child in get_children():
		if child is Wheel:
			wheels.append(child)


func _physics_process(delta: float) -> void:
	input.update(delta, linear_velocity.length())
	var steer_angle := -input.steer * deg_to_rad(stats.get_stat("max_steer_angle_deg"))
	for wheel in wheels:
		if wheel.steerable:
			wheel.rotation.y = steer_angle
		wheel.update_suspension(self, stats, delta)
		wheel.update_tire(self, stats, delta)
