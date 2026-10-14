class_name Car
extends RigidBody3D
## Player car: rigid body on four raycast wheels. Reads tunables through a `StatBlock`.

@export var car_stats: CarStats

var stats: StatBlock
var wheels: Array[Wheel] = []


func _ready() -> void:
	stats = StatBlock.new(car_stats.stats)
	mass = stats.get_stat("mass")
	for child in get_children():
		if child is Wheel:
			wheels.append(child)


func _physics_process(delta: float) -> void:
	for wheel in wheels:
		wheel.update_suspension(self, stats, delta)
