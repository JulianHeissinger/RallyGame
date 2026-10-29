class_name RoadFollower
extends ApproachHazard
## A vehicle that drives along the road once triggered (rally car ahead, tractor, caravan,
## wrong-way tourist). Its `Body` is an `AnimatableBody3D` on collision layer 2, moved along the
## `RoadPath` at `lateral` m from the centreline, so the car takes impact damage from contact but
## its wheel rays never stand on it. `direction` -1 drives against the road. It stops at the
## finish line, or at the road start when driving the wrong way.

signal hazard_defeated(hazard: Node)

## Overtaking counts once the car is this many m of road ahead of the follower.
const OVERTAKE_MARGIN := 2.0
## Seconds over which the player's speed is averaged for `pace`.
const PACE_TIME := 3.0
const DUST_COLOR := Color(0.75, 0.65, 0.5, 0.35)
const DUST_PUFFS := 6

@export var speed := 10.0
## Share of the player's averaged speed to drive at instead of `speed` (rally car); 0 keeps `speed`.
@export var pace := 0.0
@export var min_speed := 8.0
@export var lateral := 0.0
@export var direction := 1.0
## Emits `hazard_defeated` when the car overtakes it (rally car).
@export var defeat_on_overtake := false
## Trails translucent dust puffs that hide what is behind it.
@export var dust := false
## A `Trailer` child follows this many m behind, swaying ±`sway` m every `sway_period` s.
@export var trailer_gap := 6.0
@export var sway := 0.0
@export var sway_period := 2.0

var _at := 0.0
var _end := 0.0
var _player_speed := 0.0
var _time := 0.0
var _defeated := false
var _puffs: Array[MeshInstance3D] = []

@onready var _body: AnimatableBody3D = $Body
@onready var _trailer: AnimatableBody3D = get_node_or_null("Trailer")


func _setup(_def: HazardDef, _rng: RandomNumberGenerator) -> void:
	_at = distance
	_end = StageLines.finish_distance(path) if direction > 0.0 else 0.0


func _ready() -> void:
	if dust:
		var material := HazardVisuals.material(DUST_COLOR)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for i in DUST_PUFFS:
			var sphere := SphereMesh.new()
			sphere.radius = 1.0 + i * 0.5
			sphere.height = sphere.radius * 2.0
			sphere.material = material
			var puff := MeshInstance3D.new()
			puff.mesh = sphere
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_puffs.append(puff)
			add_child(puff)
	_place()


func _physics_process(delta: float) -> void:
	super(delta)
	if car == null:
		return
	_player_speed += (car.linear_velocity.length() - _player_speed) * delta / PACE_TIME
	if not triggered:
		return
	_time += delta
	var current := maxf(pace * _player_speed, min_speed) if pace > 0.0 else speed
	_at = minf(_at + current * delta, _end) if direction > 0.0 else maxf(_at - current * delta, _end)
	_place()
	if defeat_on_overtake and not _defeated and path.progress_at(car.global_position) > _at + OVERTAKE_MARGIN:
		_defeated = true
		hazard_defeated.emit(self)


## Puts the body, trailer and dust at the current road distance.
func _place() -> void:
	_body.global_transform = _road_transform(_at, lateral)
	var behind := _at - direction * trailer_gap
	if _trailer:
		_trailer.global_transform = _road_transform(behind, lateral + sway * sin(_time * TAU / sway_period))
	for i in _puffs.size():
		_puffs[i].global_position = _road_transform(_at - direction * (3.0 + i * 3.0), lateral).origin \
				+ Vector3.UP * (0.5 + i * 0.3)


## Road transform at `along`, `offset` m to the right, facing the driving direction.
func _road_transform(along: float, offset: float) -> Transform3D:
	var road := path.transform_at(clampf(along, 0.0, path.length)).translated_local(Vector3.RIGHT * offset)
	if direction < 0.0:
		road.basis = road.basis.rotated(Vector3.UP, PI)
	return road
