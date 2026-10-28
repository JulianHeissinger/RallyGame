class_name ForceArea
extends Node3D
## Pushes the car while its centre is inside (wind gust, steam geyser, dust devil, helicopter
## downwash). Forces are accelerations in m/s², multiplied by the car's mass so every car feels the
## same: `push` in the area's own frame (x across, z along the road), `outward` away from the
## centre, and a yaw `spin` in rad/s². With `period` > 0 the area is on for `active_time` seconds
## of each period, starting at a seeded phase. `wander` sways it across the road. While active it
## shows its `Active` child; a `Spin` child turns all the time.

@export var radius := 2.0
## Rectangle footprint (x across, y along the road) instead of `radius`; x = 0 spans the road.
@export var size := Vector2.ZERO
@export var push := Vector3.ZERO
## Picks the sign of `push.x` from the placement RNG (wind from either side).
@export var random_side := false
@export var outward := 0.0
@export var spin := 0.0
@export var period := 0.0
@export var active_time := 0.0
## Sway amplitude in m across the road, and its period in s.
@export var wander := 0.0
@export var wander_period := 6.0
## Turn rate in rad/s of the `Spin` child.
@export var spin_visual := 6.0

var car: Car

var _time := 0.0
var _origin := Vector3.ZERO
var _active := true

@onready var _active_node: Node3D = get_node_or_null("Active")
@onready var _spin_node: Node3D = get_node_or_null("Spin")


func setup(_def: HazardDef, target: Car, path: RoadPath, rng: RandomNumberGenerator) -> void:
	car = target
	if size != Vector2.ZERO and size.x <= 0.0:
		size.x = path.widths[clampi(path.distances.bsearch(path.progress_at(transform.origin)), 0, path.widths.size() - 1)]
	if random_side and rng.randf() < 0.5:
		push.x = -push.x
	_time = rng.randf() * maxf(period, wander_period)


func _ready() -> void:
	_origin = position
	_update_active()


func _process(delta: float) -> void:
	if _spin_node:
		_spin_node.rotate_y(spin_visual * delta)


func _physics_process(delta: float) -> void:
	_time += delta
	if wander > 0.0:
		position = _origin + transform.basis.x * wander * sin(_time * TAU / wander_period)
	_update_active()
	if car == null or not _active or not _contains(car.global_position):
		return
	var acceleration := global_basis * push
	var away := car.global_position - global_position
	away.y = 0.0
	if outward != 0.0 and away.length() > 0.01:
		acceleration += away.normalized() * outward
	car.apply_central_force(acceleration * car.mass)
	if spin != 0.0:
		car.angular_velocity += Vector3.UP * spin * delta


func _update_active() -> void:
	_active = period <= 0.0 or fmod(_time, period) < active_time
	if _active_node:
		_active_node.visible = _active


func _contains(point: Vector3) -> bool:
	var local := to_local(point)
	if size != Vector2.ZERO:
		return absf(local.x) <= size.x / 2.0 and absf(local.z) <= size.y / 2.0
	return Vector2(local.x, local.z).length() <= radius
