class_name Roller
extends ApproachHazard
## A rolling `Body` (cheese wheel, runaway wheel, tumbleweed), frozen until triggered. `across`:
## it starts `start_gap` m beyond the road edge on a seeded side and rolls across the road, timed
## to reach the centreline `early` seconds before the car. Otherwise it starts on the road at the
## placement and rolls toward the car with `lead_time`. With `push` it keeps its speed until past
## the far verge (a tumbleweed in the wind); otherwise it only gets the start speed.

@export var speed := 6.0
@export var across := true
@export var start_gap := 4.0
@export var early := 1.0
@export var push := false
## Body radius in m; sets the start spin so it rolls without slipping.
@export var radius := 0.5
## Spawn height in m above the ground below the body's lowest point.
const DROP := 0.3

var _direction := Vector3.ZERO
var _push_time := 0.0

@onready var _body: RigidBody3D = $Body


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	var road := path.transform_at(distance)
	var half := path.widths[clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)] / 2.0
	var start := transform.origin
	if across:
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		start = verge_point(distance, side, start_gap)
		_direction = -road.basis.x * side
		lead_time = (half + start_gap) / speed + early
		_push_time = 2.0 * (half + start_gap) / speed
	else:
		# The car drives toward -z of the road basis.
		_direction = road.basis.z
	var axis := Vector3.UP.cross(_direction).normalized()
	var body := get_node("Body") as Node3D
	body.transform = transform.affine_inverse() * Transform3D(
			Basis(_direction, axis, _direction.cross(axis)), start + Vector3.UP * (radius + DROP))


func _physics_process(delta: float) -> void:
	super(delta)
	if not push or not triggered or _push_time <= 0.0:
		return
	_push_time -= delta
	var velocity := _direction * speed
	_body.linear_velocity = Vector3(velocity.x, _body.linear_velocity.y, velocity.z)


func _trigger() -> void:
	_body.freeze = false
	_body.linear_velocity = _direction * speed
	_body.angular_velocity = Vector3.UP.cross(_direction * speed) / radius
