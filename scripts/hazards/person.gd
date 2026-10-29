class_name Person
extends RigidBody3D
## A person by or on the road (spectator, fan, streaker, mascot). Moves only when told to: walks,
## runs, dives or flees toward a target, or hops on the spot to cheer. Lives on collision layer 2
## like the sheep; the scene's `impact_scale` 0 means a hit never damages the car, and a hit knocks
## the person away and frees them from the car. Hazards time the moves so the car does not reach them.

## Upward speed in m/s of each cheering hop.
const CHEER_HOP := 1.5
## Upward speed in m/s at the start of a dive.
const DIVE_UP := 2.5
## A target closer than this in m counts as reached.
const ARRIVE := 0.3
## Knock-away speed on a car hit, as a share of the car's speed, like the sheep.
const KNOCK_SIDE := 0.6
const KNOCK_UP := 0.3

@export var color := Color(0.2, 0.3, 0.7)
@export var head_color := Color(0.9, 0.75, 0.6)

## True once the car hit this person.
var hit := false

var _target := Vector3.ZERO
var _speed := 0.0
var _moving := false
var _cheer_time := 0.0


func _ready() -> void:
	$Body.material_override = HazardVisuals.material(color)
	$Head.material_override = HazardVisuals.material(head_color)
	body_entered.connect(_on_body_entered)


func walk_to(target: Vector3, speed: float) -> void:
	_target = target
	_speed = speed
	_moving = true
	sleeping = false


func dive_to(target: Vector3, speed: float) -> void:
	walk_to(target, speed)
	linear_velocity.y = DIVE_UP


## Hops on the spot for `time` seconds.
func cheer(time: float) -> void:
	_cheer_time = time
	sleeping = false


## Runs `run` m along `direction` (flattened) at `speed`.
func flee(direction: Vector3, run: float, speed: float) -> void:
	direction.y = 0.0
	walk_to(global_position + direction.normalized() * run, speed)


func _physics_process(delta: float) -> void:
	if hit:
		return
	if _cheer_time > 0.0:
		_cheer_time -= delta
		if not _moving and absf(linear_velocity.y) < 0.05:
			linear_velocity.y = CHEER_HOP
	if not _moving:
		return
	var to := _target - global_position
	to.y = 0.0
	if to.length() < ARRIVE:
		_moving = false
		linear_velocity = Vector3(0.0, linear_velocity.y, 0.0)
		return
	var step := to.normalized() * _speed
	linear_velocity = Vector3(step.x, linear_velocity.y, step.z)


func _on_body_entered(body: Node) -> void:
	if hit or not body is Car:
		return
	hit = true
	_moving = false
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	var car := body as Car
	add_collision_exception_with(car)
	var right := car.global_basis.x
	var side := right if (global_position - car.global_position).dot(right) >= 0.0 else -right
	var speed := car.linear_velocity.length()
	apply_central_impulse(mass * (side * speed * KNOCK_SIDE + Vector3.UP * speed * KNOCK_UP))
