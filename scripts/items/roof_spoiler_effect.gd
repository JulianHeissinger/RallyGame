class_name RoofSpoilerEffect
extends ItemEffect
## Levels the car in the air: after a jump, a torque pulls pitch and roll toward level until the
## first wheel touches down. Heading is left alone.

## Angular acceleration in rad/s² per rad of tilt, and per rad/s of pitch and roll rate.
@export var gain := 8.0
@export var damping := 3.0
@export var max_accel := 6.0

var _airborne := false


func on_activate(_car: Node, _data: Variant) -> bool:
	_airborne = true
	return true


func on_physics(car: Node, _delta: float) -> void:
	if not _airborne:
		return
	if car.wheels.any(func(w: Wheel) -> bool: return w.is_grounded):
		_airborne = false
		return
	var up: Vector3 = car.global_basis.y
	var axis := up.cross(Vector3.UP)
	var tilt := up.angle_to(Vector3.UP)
	var correction := axis.normalized() * tilt if axis.length_squared() > 0.000001 else Vector3.ZERO
	var spin: Vector3 = car.angular_velocity
	var accel := (correction * gain - (spin - Vector3.UP * spin.y) * damping).limit_length(max_accel)
	car.apply_torque(car.get_inverse_inertia_tensor().inverse() * accel)
