class_name Car
extends RigidBody3D
## Player car: rigid body on four raycast wheels. Reads tunables through a `StatBlock` and
## driver input only through its `InputSource`.

## Emitted after spectators put the car back on its wheels; `penalty` is in seconds.
signal rolled_over(penalty: float)

## The car counts as rolled over while its up axis is below this against world up (~73° tilt).
const ROLLOVER_UP_DOT := 0.3
## Height in m the car is lifted on a rollover reset, so the wheels drop onto the ground.
const ROLLOVER_LIFT := 1.0

@export var car_stats: CarStats

var stats: StatBlock
var input := InputSource.new()
var drivetrain := Drivetrain.new()
var wheels: Array[Wheel] = []
## Road of the current stage, set by the stage. Null resets rollovers in place.
var road: RoadPath
## Surface patches (oil, mud, ...) that change grip and drag of the wheels on them; patches
## register themselves here.
var patches: Array[SurfacePatch] = []

## Colliders touched in the last physics step, by instance id. Only new contacts are impacts.
var _touching: Dictionary = {}
## Instance ids of `impact_once` bodies that already damaged the car.
var _impacted_once: Dictionary = {}
## Body velocity from the previous step, before the solver resolved this step's new contacts.
var _last_velocity := Vector3.ZERO
var _last_angular_velocity := Vector3.ZERO
var _rollover_timer := 0.0

@onready var damage: CarDamage = $Damage
@onready var items: ItemManager = $Items


func _ready() -> void:
	stats = StatBlock.new(car_stats.stats)
	mass = stats.get_stat("mass")
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, stats.get_stat("center_of_mass_y"), 0.0)
	drivetrain.gearbox.mode = Settings.gearbox_mode
	damage.stats = stats
	items.setup(self, stats, damage)
	drivetrain.gearbox.gear_shifted.connect(
		func(from: int, to: int) -> void: items.on_event("gear_shift", {"from": from, "to": to}))
	for child in get_children():
		if child is Wheel:
			wheels.append(child)


func _physics_process(delta: float) -> void:
	# Items can change the mass during a stage.
	mass = stats.get_stat("mass")
	input.update(delta, linear_velocity.length())
	damage.update_wear(stats, delta, linear_velocity.length())
	_apply_damage()
	_update_rollover(delta)
	drivetrain.update(input, wheels, stats, car_stats.torque_curve, linear_velocity.length(), delta)
	# Max lock shrinks with speed so full input stays near the tires' peak slip angle.
	var lock_t := clampf(linear_velocity.length() / stats.get_stat("steer_reduction_speed"), 0.0, 1.0)
	var max_lock := lerpf(stats.get_stat("max_steer_angle_deg"), stats.get_stat("min_steer_angle_deg"), lock_t)
	# Steering toward the slide adds the body slip angle, so countersteer can follow the slide.
	var v_right := linear_velocity.dot(global_basis.x)
	if input.steer * v_right > 0.0:
		var body_slip := rad_to_deg(atan2(absf(v_right), absf(linear_velocity.dot(-global_basis.z))))
		max_lock = minf(max_lock + body_slip, stats.get_stat("max_steer_angle_deg"))
	var steer_angle := -input.steer * deg_to_rad(max_lock)
	for wheel in wheels:
		if wheel.steerable:
			wheel.rotation.y = steer_angle
		wheel.update_suspension(self, stats, delta)
		_apply_patches(wheel)
		wheel.update_tire(self, stats, delta)
		wheel.update_visual(stats, delta)
	_apply_yaw_assist()


## Combines the patches under a grounded wheel: grip factors multiply, drags add up.
func _apply_patches(wheel: Wheel) -> void:
	wheel.patch_grip = 1.0
	wheel.patch_drag = 0.0
	if not wheel.is_grounded:
		return
	for patch in patches:
		if patch.contains(wheel.contact_point()):
			wheel.patch_grip *= patch.grip
			wheel.patch_drag += patch.drag * stats.get_stat("patch_drag_scale")


## Steering yaw assist: while steering, pulls the yaw rate toward a target set by the input, so
## the car holds a light drift and countersteer catches it. Off without steering input.
func _apply_yaw_assist() -> void:
	if input.steer == 0.0 or wheels.filter(func(w: Wheel) -> bool: return w.is_grounded).size() < 2:
		return
	var min_speed := stats.get_stat("yaw_assist_min_speed")
	var fade := clampf((linear_velocity.length() - min_speed) / min_speed, 0.0, 1.0)
	var up := global_basis.y
	# The target turn rate is capped by a lateral acceleration a bit above tire grip, so the car
	# drifts lightly at every speed instead of spinning at high speed.
	var speed := maxf(linear_velocity.length(), 0.1)
	var target_rate := minf(deg_to_rad(stats.get_stat("yaw_assist_rate")),
		stats.get_stat("yaw_assist_lateral_g") * get_gravity().length() / speed)
	var target := -input.steer * target_rate
	var max_accel := stats.get_stat("yaw_assist_max_accel")
	var accel := clampf(stats.get_stat("yaw_assist_gain") * (target - angular_velocity.dot(up)), -max_accel, max_accel)
	# Rotation-adding torque tapers off toward `yaw_assist_max_slip_deg` of body slip, so the assist
	# never pushes the car into a spin; torque against the rotation is never limited.
	if accel * target > 0.0:
		var body_slip := rad_to_deg(absf(atan2(linear_velocity.dot(global_basis.x), linear_velocity.dot(-global_basis.z))))
		accel *= clampf(1.0 - body_slip / stats.get_stat("yaw_assist_max_slip_deg"), 0.0, 1.0)
	var inertia := 1.0 / PhysicsServer3D.body_get_direct_state(get_rid()).inverse_inertia.y
	apply_torque(up * accel * fade * inertia)


## Turns new contacts into impacts. Contacts arrive after the solver has already slowed the car,
## so the impact speed uses the velocity saved from the previous step.
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var touching := {}
	var impacts := {}
	var com := global_transform * center_of_mass
	for i in state.get_contact_count():
		var collider := state.get_contact_collider_object(i)
		if collider == null:
			continue
		var id := collider.get_instance_id()
		touching[id] = true
		if _touching.has(id):
			continue
		var point := state.get_contact_local_position(i)
		var velocity := _last_velocity + _last_angular_velocity.cross(point - com)
		var relative := velocity - state.get_contact_collider_velocity_at_position(i)
		var speed := absf(relative.dot(state.get_contact_local_normal(i)))
		if not impacts.has(id) or speed > impacts[id][1]:
			impacts[id] = [point, speed, collider]
	for impact: Array in impacts.values():
		var collider: Object = impact[2]
		# Bodies with `impact_once` metadata (e.g. sheep) damage the car only on their first impact.
		if collider.get_meta("impact_once", false):
			if _impacted_once.has(collider.get_instance_id()):
				continue
			_impacted_once[collider.get_instance_id()] = true
		damage.apply_impact(stats, to_local(impact[0]), impact[1], collider.is_in_group("solid"),
			collider.get_meta("impact_scale", 1.0))
	_touching = touching
	_last_velocity = state.linear_velocity
	_last_angular_velocity = state.angular_velocity


## Feeds part conditions into handling: engine power through the stat block, the rest per wheel.
func _apply_damage() -> void:
	var power := lerpf(stats.get_stat("engine_damaged_power"), 1.0, damage.condition["engine"] / 100.0)
	if stats.damage_multiplier.get("max_torque", 1.0) != power:
		stats.damage_multiplier["max_torque"] = power
		stats.mark_dirty()
	for wheel in wheels:
		var corner := wheel.name.trim_prefix("Wheel").to_lower()
		wheel.apply_condition(stats, damage.condition["tire_" + corner],
			damage.condition["brake_" + corner], damage.condition["suspension_" + corner])


## Spectators push the car back upright after it rests on its side or roof for `rollover_time`.
## On a stage it is reset onto the nearest road point; without a road, in place, keeping its heading.
func _update_rollover(delta: float) -> void:
	if global_basis.y.dot(Vector3.UP) >= ROLLOVER_UP_DOT:
		_rollover_timer = 0.0
		return
	_rollover_timer += delta
	if _rollover_timer < stats.get_stat("rollover_time"):
		return
	_rollover_timer = 0.0
	if road:
		place(road.transform_at(road.progress_at(global_position)).translated(Vector3.UP * ROLLOVER_LIFT))
	else:
		var forward := -global_basis.z
		forward.y = 0.0
		if forward.length_squared() < 0.0001:
			forward = global_basis.y.slide(Vector3.UP)
		place(Transform3D(Basis.looking_at(forward.normalized()), global_position + Vector3.UP * ROLLOVER_LIFT))
	rolled_over.emit(stats.get_stat("rollover_penalty"))


## Moves the car to `target` at rest, with the wheels stopped.
func place(target: Transform3D) -> void:
	global_transform = target
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_last_velocity = Vector3.ZERO
	_last_angular_velocity = Vector3.ZERO
	for wheel in wheels:
		wheel.spin = 0.0
