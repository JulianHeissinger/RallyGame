class_name Wheel
extends RayCast3D
## Raycast wheel with spring/damper suspension and a slip-based tire. The ray points down from
## the mount point; its length is suspension rest length plus wheel radius.

## Front wheels turn with the steering input.
@export var steerable := false

var is_grounded := false
## Suspension force along the car's up axis, in N. 0 when the wheel is in the air.
var normal_load := 0.0
## Wheel angular velocity in rad/s, positive when rolling forward.
var spin := 0.0
var slip_angle := 0.0
var slip_ratio := 0.0

var _last_compression := 0.0
var _contact := Vector3.ZERO
var _contact_normal := Vector3.UP
## Sideways tire carcass deflection in m, used only near standstill.
var _lateral_deflection := 0.0


func update_suspension(body: RigidBody3D, stats: StatBlock, delta: float) -> void:
	var radius := stats.get_stat("wheel_radius")
	var rest := stats.get_stat("suspension_rest_length")
	target_position = Vector3(0.0, -(rest + radius), 0.0)
	force_raycast_update()
	is_grounded = is_colliding()
	if not is_grounded:
		normal_load = 0.0
		_last_compression = 0.0
		return

	_contact = get_collision_point()
	_contact_normal = get_collision_normal()
	var compression := clampf(rest + radius - global_position.distance_to(_contact), 0.0, rest)
	var compression_velocity := (compression - _last_compression) / delta
	_last_compression = compression
	normal_load = maxf(stats.get_stat("spring_stiffness") * compression
		+ stats.get_stat("damper") * compression_velocity, 0.0)
	body.apply_force(global_basis.y * normal_load, _contact - body.global_position)


## Applies tire forces at the contact point. Call after `update_suspension` in the same tick.
func update_tire(body: RigidBody3D, stats: StatBlock, delta: float) -> void:
	if not is_grounded:
		slip_angle = 0.0
		slip_ratio = 0.0
		_lateral_deflection = 0.0
		return

	var radius := stats.get_stat("wheel_radius")
	var low_speed := stats.get_stat("low_speed_threshold")
	var forward := -global_basis.z
	forward = (forward - _contact_normal * forward.dot(_contact_normal)).normalized()
	var right := forward.cross(_contact_normal)
	# Body origin is the centre of mass (auto mode, centred box shape).
	var offset := _contact - body.global_position
	var velocity := body.linear_velocity + body.angular_velocity.cross(offset)
	var v_long := velocity.dot(forward)
	var v_lat := velocity.dot(right)

	slip_ratio = (spin * radius - v_long) / maxf(absf(v_long), low_speed)
	slip_angle = atan2(v_lat, absf(v_long))

	var max_force := stats.get_stat("tire_friction") * normal_load
	var force_long := max_force * _magic_formula(slip_ratio,
		stats.get_stat("tire_long_b"), stats.get_stat("tire_long_c"))
	var force_lat := -max_force * _magic_formula(slip_angle,
		stats.get_stat("tire_lat_b"), stats.get_stat("tire_lat_c"))

	# Slip angle is ill-defined near standstill: blend toward a tire carcass spring, which holds
	# static side loads (e.g. on a slope) without creeping. Critically damped per wheel load share.
	var blend := clampf(Vector2(v_long, v_lat).length() / low_speed, 0.0, 1.0)
	var stiffness := stats.get_stat("tire_lateral_stiffness")
	var damping := 2.0 * sqrt(stiffness * normal_load / body.get_gravity().length())
	var max_deflection := max_force / stiffness
	_lateral_deflection = clampf(_lateral_deflection + v_lat * delta, -max_deflection, max_deflection)
	var force_lat_low := clampf(-stiffness * _lateral_deflection - damping * v_lat, -max_force, max_force)
	force_lat = lerpf(force_lat_low, force_lat, blend)
	_lateral_deflection *= 1.0 - blend
	# Slip ratio is too stiff to integrate near standstill: blend toward a wheel that sticks to
	# the ground, where only torque applied to the wheel (none yet) makes longitudinal force.
	var force_long_low := 0.0
	force_long = lerpf(force_long_low, force_long, blend)

	# Friction circle: combined demand cannot exceed the available grip.
	var demand := Vector2(force_long, force_lat).length()
	if demand > max_force and demand > 0.0:
		force_long *= max_force / demand
		force_lat *= max_force / demand

	_integrate_spin(-force_long * radius, v_long / radius, stats.get_stat("wheel_inertia"), delta)
	spin = lerpf(v_long / radius, spin, blend)
	body.apply_force(forward * force_long + right * force_lat, offset)


## Explicit integration at 120 Hz overshoots the free-rolling speed when slip stiffness is high,
## so with no drive or brake torque the spin may reach that speed but not cross it.
func _integrate_spin(torque: float, rolling_spin: float, inertia: float, delta: float) -> void:
	var next := spin + torque / inertia * delta
	if signf(spin - rolling_spin) != signf(next - rolling_spin):
		next = rolling_spin
	spin = next


## Simplified Pacejka curve, normalized to a peak of 1.
static func _magic_formula(slip: float, b: float, c: float) -> float:
	return sin(c * atan(b * slip))
