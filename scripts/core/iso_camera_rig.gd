class_name IsoCameraRig
extends Node3D
## Near-isometric follow camera: fixed pitch and yaw, narrow FOV, far away.
## The rig node is the focus point; it follows the target with a critically damped spring
## plus a horizontal look-ahead along the target's velocity. Its rotation never changes.

@export var pitch_deg := 45.0
@export var yaw_deg := 45.0
@export var fov := 30.0
@export var distance := 55.0
## Spring frequency of the follow, in rad/s. Higher follows tighter.
@export var follow_frequency := 4.0
## Look-ahead offset is horizontal velocity times this time, capped at `look_ahead_max` meters.
@export var look_ahead_time := 0.6
@export var look_ahead_max := 12.0

## Node to follow. Setting it snaps the focus onto it on the next update.
var target: Node3D:
	set(value):
		target = value
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
		_snapped = true
		return

	var target_velocity := (target_position - _last_target_position) / delta
	_last_target_position = target_position
	var horizontal_velocity := Vector3(target_velocity.x, 0.0, target_velocity.z)
	# The spring trails a target moving at constant velocity by 2v/frequency; add it back so the
	# focus leads by the look-ahead alone.
	var lag_compensation := horizontal_velocity * (2.0 / follow_frequency)
	var look_ahead := (horizontal_velocity * look_ahead_time).limit_length(look_ahead_max)
	global_position = _smooth_damp(global_position, target_position + lag_compensation + look_ahead, delta)


## Critically damped spring step (closed-form approximation, stable for large delta).
func _smooth_damp(current: Vector3, goal: Vector3, delta: float) -> Vector3:
	var x := follow_frequency * delta
	var decay := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := current - goal
	var temp := (_focus_velocity + follow_frequency * change) * delta
	_focus_velocity = (_focus_velocity - follow_frequency * temp) * decay
	return goal + (change + temp) * decay
