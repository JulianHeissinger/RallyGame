class_name Sheep
extends RigidBody3D
## One flock sheep. Walks to `target` after `start_delay` once started, then stands. A hit by the
## car knocks it sideways and up and frees its rotation so it tumbles; ending up off the road after
## a hit emits `knocked_off` once. The scene's `impact_once` metadata makes only the first car hit
## damage the car. Sheep live on collision layer 2, which wheel rays do not scan, and stop colliding
## with the car after its first hit, so a flock never stops the car.

signal knocked_off(sheep: Sheep)

## Off the road means this far in m beyond the road edge, past the bevel.
const OFF_ROAD_MARGIN := 1.0
## Knock-away speed on a car hit, as a share of the car's speed: sideways away from the car's
## centreline and up. Without it the car pushes sheep along the road like a plough.
const KNOCK_SIDE := 0.6
const KNOCK_UP := 0.3

## Upward speed in m/s of each hop while walking (kangaroo); 0 walks.
@export var hop_speed := 0.0

var target := Vector3.ZERO
var walk_speed := 2.0
var start_delay := 0.0
var path: RoadPath

var _walking := false
var _timer := 0.0
var _hit := false
var _knocked_off := false
var _hop_timer := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func start() -> void:
	_walking = true
	sleeping = false


func _physics_process(delta: float) -> void:
	if _hit:
		if not _knocked_off and _off_road():
			_knocked_off = true
			knocked_off.emit(self)
		return
	if not _walking:
		return
	_timer += delta
	if _timer < start_delay:
		return
	var to := target - global_position
	to.y = 0.0
	if to.length() < 0.3:
		_walking = false
		linear_velocity = Vector3(0.0, linear_velocity.y, 0.0)
		return
	var step := to.normalized() * walk_speed
	var up := linear_velocity.y
	if hop_speed > 0.0:
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			up = hop_speed
			# Next hop once this one has landed: flight time plus a short pause.
			_hop_timer = 2.0 * hop_speed / (ProjectSettings.get_setting("physics/3d/default_gravity") as float) + 0.1
	linear_velocity = Vector3(step.x, up, step.z)


func _off_road() -> bool:
	var distance := path.progress_at(global_position)
	var closest := path.curve.sample_baked(distance)
	var half := path.widths[clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)] / 2.0
	return Vector2(global_position.x - closest.x, global_position.z - closest.z).length() > half + OFF_ROAD_MARGIN


func _on_body_entered(body: Node) -> void:
	if _hit or not body is Car:
		return
	_hit = true
	_walking = false
	axis_lock_angular_x = false
	axis_lock_angular_y = false
	axis_lock_angular_z = false
	var car := body as Car
	add_collision_exception_with(car)
	var right := car.global_basis.x
	var side := right if (global_position - car.global_position).dot(right) >= 0.0 else -right
	var speed := car.linear_velocity.length()
	apply_central_impulse(mass * (side * speed * KNOCK_SIDE + Vector3.UP * speed * KNOCK_UP))
