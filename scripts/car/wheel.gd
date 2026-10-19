class_name Wheel
extends RayCast3D
## Raycast wheel with spring/damper suspension and a slip-based tire. The ray points down from
## the mount point; its length is suspension rest length plus wheel radius.

## Slip stiffness is too high for one explicit spin step at 120 Hz; substeps keep it stable.
const SPIN_SUBSTEPS := 8

## Front wheels turn with the steering input.
@export var steerable := false

var is_grounded := false
## Suspension force along the car's up axis, in N. 0 when the wheel is in the air.
var normal_load := 0.0
## Wheel angular velocity in rad/s, positive when rolling forward.
var spin := 0.0
var slip_angle := 0.0
var slip_ratio := 0.0
## Surface under the wheel and its grip factor, from the last grounded ray hit.
var surface := Surface.DEFAULT
var surface_grip: float = Surface.GRIP[Surface.DEFAULT]
## Set by the drivetrain each tick, in N·m. Drive is signed; brake is a magnitude.
var drive_torque := 0.0
var brake_torque := 0.0

var _last_compression := 0.0
var _contact := Vector3.ZERO
var _contact_normal := Vector3.UP
## Tire carcass deflections in m, used only near standstill.
var _lateral_deflection := 0.0
var _longitudinal_deflection := 0.0
## Optional wheel mesh, moved along the suspension and rolled by `spin`.
@onready var _visual: Node3D = get_node_or_null("Visual")


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
	var collider := get_collider()
	surface = Surface.name_of(collider)
	surface_grip = Surface.grip_of(collider)
	_contact_normal = get_collision_normal()
	var compression := clampf(rest + radius - global_position.distance_to(_contact), 0.0, rest)
	var compression_velocity := (compression - _last_compression) / delta
	_last_compression = compression
	normal_load = maxf(stats.get_stat("spring_stiffness") * compression
		+ stats.get_stat("damper") * compression_velocity, 0.0)
	body.apply_force(global_basis.y * normal_load, _contact - body.global_position)


## Applies tire forces at the contact point. Call after `update_suspension` in the same tick.
func update_tire(body: RigidBody3D, stats: StatBlock, delta: float) -> void:
	var radius := stats.get_stat("wheel_radius")
	var inertia := stats.get_stat("wheel_inertia")
	if not is_grounded:
		slip_angle = 0.0
		slip_ratio = 0.0
		_lateral_deflection = 0.0
		_longitudinal_deflection = 0.0
		spin = move_toward(spin + drive_torque / inertia * delta, 0.0, brake_torque / inertia * delta)
		return

	var low_speed := stats.get_stat("low_speed_threshold")
	var forward := -global_basis.z
	forward = (forward - _contact_normal * forward.dot(_contact_normal)).normalized()
	var right := forward.cross(_contact_normal)
	# `linear_velocity` is the centre-of-mass velocity; forces are applied relative to the origin.
	var offset := _contact - body.global_position
	var com_offset := _contact - body.global_transform * body.center_of_mass
	var velocity := body.linear_velocity + body.angular_velocity.cross(com_offset)
	var v_long := velocity.dot(forward)
	var v_lat := velocity.dot(right)
	var mass_share := normal_load / body.get_gravity().length()

	slip_angle = atan2(v_lat, absf(v_long))
	var max_force := stats.get_stat("tire_friction") * surface_grip * normal_load
	var lat_b := stats.get_stat("tire_lat_b")
	var lat_c := stats.get_stat("tire_lat_c")
	var long_b := stats.get_stat("tire_long_b")
	var long_c := stats.get_stat("tire_long_c")
	var lat_peak := _peak_slip(lat_b, lat_c)
	var long_peak := _peak_slip(long_b, long_c)
	var lat_norm := slip_angle / lat_peak

	# Spin and longitudinal force are integrated together in substeps. Combined slip: both slips
	# are normalized to their curve's peak, each curve is evaluated on the combined length, and
	# the force is split by direction. A locked wheel thus loses almost all lateral grip.
	var h := delta / SPIN_SUBSTEPS
	var force_long := 0.0
	var force_lat := 0.0
	for i in SPIN_SUBSTEPS:
		slip_ratio = (spin * radius - v_long) / maxf(absf(v_long), low_speed)
		var long_norm := slip_ratio / long_peak
		var combined := Vector2(long_norm, lat_norm).length()
		var force := 0.0
		if combined > 0.0:
			force = max_force * _magic_formula(combined * long_peak, long_b, long_c) \
				* long_norm / combined
			force_lat -= max_force * _magic_formula(combined * lat_peak, lat_b, lat_c) \
				* lat_norm / combined
		spin = move_toward(spin + (drive_torque - force * radius) / inertia * h, 0.0,
			brake_torque / inertia * h)
		force_long += force
	force_long /= SPIN_SUBSTEPS
	force_lat /= SPIN_SUBSTEPS

	# Slip is ill-defined near standstill: blend toward tire carcass springs, which hold static
	# loads (e.g. on a slope) without creeping. Critically damped per wheel load share.
	var blend := clampf(Vector2(v_long, v_lat).length() / low_speed, 0.0, 1.0)

	var lat_stiffness := stats.get_stat("tire_lateral_stiffness")
	_lateral_deflection = clampf(_lateral_deflection + v_lat * delta,
		-max_force / lat_stiffness, max_force / lat_stiffness)
	var force_lat_low := clampf(-lat_stiffness * _lateral_deflection
		- 2.0 * sqrt(lat_stiffness * mass_share) * v_lat, -max_force, max_force)
	force_lat = lerpf(force_lat_low, force_lat, blend)
	_lateral_deflection *= 1.0 - blend

	# Near standstill the wheel sticks to the ground: drive torque pushes directly, and a braked
	# wheel holds through the carcass spring up to what the brake can resist.
	var force_long_low := drive_torque / radius
	var spin_low := v_long / radius
	if brake_torque > 0.0:
		var long_stiffness := stats.get_stat("tire_longitudinal_stiffness")
		var hold := minf(max_force, brake_torque / radius)
		_longitudinal_deflection = clampf(_longitudinal_deflection + v_long * delta,
			-hold / long_stiffness, hold / long_stiffness)
		force_long_low += clampf(-long_stiffness * _longitudinal_deflection
			- 2.0 * sqrt(long_stiffness * mass_share) * v_long, -hold, hold)
		spin_low = 0.0
	else:
		_longitudinal_deflection = 0.0
	force_long_low = clampf(force_long_low, -max_force, max_force)
	force_long = lerpf(force_long_low, force_long, blend)
	spin = lerpf(spin_low, spin, blend)
	_longitudinal_deflection *= 1.0 - blend

	body.apply_force(forward * force_long + right * force_lat, offset)


## Places the wheel mesh at the suspension's current travel and rolls it.
func update_visual(stats: StatBlock, delta: float) -> void:
	if _visual == null:
		return
	_visual.position.y = -(stats.get_stat("suspension_rest_length") - _last_compression)
	_visual.rotate_x(-spin * delta)


## Simplified Pacejka curve, normalized to a peak of 1.
static func _magic_formula(slip: float, b: float, c: float) -> float:
	return sin(c * atan(b * slip))


## Slip at which `_magic_formula` peaks.
static func _peak_slip(b: float, c: float) -> float:
	return tan(PI / (2.0 * c)) / b
