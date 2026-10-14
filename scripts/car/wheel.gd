class_name Wheel
extends RayCast3D
## Raycast wheel with spring/damper suspension. The ray points down from the mount point;
## its length is suspension rest length plus wheel radius.

var is_grounded := false
## Suspension force along the car's up axis, in N. 0 when the wheel is in the air.
var normal_load := 0.0

var _last_compression := 0.0


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

	var contact := get_collision_point()
	var compression := clampf(rest + radius - global_position.distance_to(contact), 0.0, rest)
	var compression_velocity := (compression - _last_compression) / delta
	_last_compression = compression
	normal_load = maxf(stats.get_stat("spring_stiffness") * compression
		+ stats.get_stat("damper") * compression_velocity, 0.0)
	body.apply_force(global_basis.y * normal_load, contact - body.global_position)
