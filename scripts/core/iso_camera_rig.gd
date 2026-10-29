class_name IsoCameraRig
extends Node3D
## Near-isometric follow camera: fixed pitch, narrow FOV, far away.
## The rig node is the focus point; it follows the target with a critically damped spring
## plus a horizontal look-ahead along the target's velocity. With a `road` set, the yaw slowly
## follows the road direction ahead of the target, so the car drives away from the camera;
## the target's own rotation never turns the view. Without a road the yaw stays at `yaw_deg`.

@export var pitch_deg := 35.0
@export var yaw_deg := 45.0
@export var fov := 30.0
@export var distance := 65.0
## Spring frequency of the follow, in rad/s. Higher follows tighter.
@export var follow_frequency := 4.0
## Look-ahead offset is horizontal velocity times this time, capped at `look_ahead_max` meters.
@export var look_ahead_time := 1.0
@export var look_ahead_max := 12.0
## Distance in m ahead of the target's road progress whose direction the yaw follows.
@export var yaw_road_ahead := 20.0
## Yaw smoothing rate in 1/s. Higher turns faster toward the road direction.
@export var yaw_follow_rate := 1.5

## Node to follow. Setting it snaps the focus onto it on the next update.
var target: Node3D:
	set(value):
		target = value
		_snapped = false

## Road the yaw follows. Null keeps the yaw fixed.
var road: RoadPath:
	set(value):
		road = value
		_snapped = false

var camera: Camera3D

var _snapped := false
var _last_target_position := Vector3.ZERO
var _focus_velocity := Vector3.ZERO


func _ready() -> void:
	rotation_degrees = Vector3(-pitch_deg, yaw_deg, 0.0)
	camera = Camera3D.new()
	camera.fov = fov
	camera.position = Vector3(0.0, 0.0, distance)
	add_child(camera)


func _process(delta: float) -> void:
	follow(delta)


func follow(delta: float) -> void:
	if target == null or delta <= 0.0:
		return
	var target_position := target.global_position
	if not _snapped:
		global_position = target_position
		_last_target_position = target_position
		_focus_velocity = Vector3.ZERO
		if road:
			rotation.y = _road_yaw(target_position)
		_snapped = true
		return
	if road:
		rotation.y = lerp_angle(rotation.y, _road_yaw(target_position), 1.0 - exp(-yaw_follow_rate * delta))

	var target_velocity := (target_position - _last_target_position) / delta
	_last_target_position = target_position
	var horizontal_velocity := Vector3(target_velocity.x, 0.0, target_velocity.z)
	# The spring trails a target moving at constant velocity by 2v/frequency; add it back so the
	# focus leads by the look-ahead alone.
	var lag_compensation := horizontal_velocity * (2.0 / follow_frequency)
	var look_ahead := (horizontal_velocity * look_ahead_time).limit_length(look_ahead_max)
	global_position = _smooth_damp(global_position, target_position + lag_compensation + look_ahead, delta)


## Yaw that points the camera's view along the road `yaw_road_ahead` beyond `position`'s progress.
func _road_yaw(position: Vector3) -> float:
	var progress := road.progress_at(position)
	var direction := road.curve.sample_baked(progress + yaw_road_ahead) - road.curve.sample_baked(progress)
	return atan2(-direction.x, -direction.z)


## Critically damped spring step (closed-form approximation, stable for large delta).
func _smooth_damp(current: Vector3, goal: Vector3, delta: float) -> Vector3:
	var x := follow_frequency * delta
	var decay := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - goal
	var temp := (_focus_velocity + follow_frequency * change) * delta
	_focus_velocity = (_focus_velocity - follow_frequency * temp) * decay
	return goal + (change + temp) * decay
