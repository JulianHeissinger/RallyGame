class_name Mantle
extends RefCounted
## Lets a walking body (animal, person) climb a low ledge, such as the lip where the terrain meets
## the road bevel a few cm too low. Walkers set only horizontal velocity, so without it they stop
## dead at any step; a box even wedges its front under the bevel's thin edge. A grounded walker
## that sees a ledge of at most `MAX_STEP` just ahead hops onto it before touching it. Only ground
## and road (layer 1) count.

## A rise of more than `MIN_STEP` m between the ground under the body's front and `PROBE_AHEAD` m
## further counts as a ledge (about 17°, steeper than the road bevel and the terrain).
const MIN_STEP := 0.03
const MAX_STEP := 0.3
const PROBE_AHEAD := 0.1
## Extra height in m cleared above the ledge.
const CLEARANCE := 0.05
## Vertical speed in m/s below which the body counts as grounded.
const GROUNDED_SPEED := 0.3

var _body: RigidBody3D
## Half size of the collision shape along the body's own axes.
var _half := Vector3.ZERO


## Reads the size of `body`'s `Collision` shape (box or capsule) and keeps it upright.
func _init(body: RigidBody3D) -> void:
	_body = body
	var shape: Shape3D = body.get_node("Collision").shape
	if shape is BoxShape3D:
		_half = shape.size / 2.0
	elif shape is CapsuleShape3D:
		_half = Vector3(shape.radius, shape.height / 2.0, shape.radius)


## Upward speed for this tick while walking with horizontal velocity `step`: a hop speed at a
## ledge ahead, otherwise the body's current vertical speed.
func up_speed(step: Vector3) -> float:
	var up := _body.linear_velocity.y
	if step.length() < 0.01 or absf(up) > GROUNDED_SPEED:
		return up
	var height := _ledge(step.normalized())
	if height <= 0.0:
		return up
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	return sqrt(2.0 * gravity * (height + CLEARANCE))


## Rise in m of the ledge just ahead along `direction` above the ground under the body's front,
## or 0 when there is none or it is too high to climb.
func _ledge(direction: Vector3) -> float:
	var basis := _body.global_basis
	var reach := absf(direction.dot(basis.x)) * _half.x + absf(direction.dot(basis.z)) * _half.z
	var feet := _body.global_position.y - _half.y
	var front := _body.global_position + direction * reach
	var under := _ground(front, feet)
	var ahead := _ground(front + direction * PROBE_AHEAD, feet)
	if is_nan(under) or is_nan(ahead):
		return 0.0
	var height := ahead - feet
	return height if ahead - under > MIN_STEP and height <= MAX_STEP else 0.0


## Ground height below `point` from just above the climbable range, or NAN.
func _ground(point: Vector3, feet: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(point.x, feet + MAX_STEP + CLEARANCE, point.z),
			Vector3(point.x, feet - MAX_STEP, point.z), 1)
	query.exclude = [_body.get_rid()]
	var hit := _body.get_world_3d().direct_space_state.intersect_ray(query)
	return NAN if hit.is_empty() else hit["position"].y
