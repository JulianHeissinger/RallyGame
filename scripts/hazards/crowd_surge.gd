class_name CrowdSurge
extends ApproachHazard
## Fans on the outside verge of a corner. When the car is `lead_time` seconds away they step onto
## the road; at `part_time` seconds they run back to their spots, clear before the car arrives.

const PERSON_SCENE := preload("res://scenes/hazards/person.tscn")
const COLORS: Array[Color] = [Color(0.8, 0.1, 0.1), Color(0.1, 0.4, 0.8), Color(0.95, 0.8, 0.1),
		Color(0.1, 0.6, 0.2), Color(0.95, 0.95, 0.95)]

@export var count_range := Vector2i(8, 15)
## Fans stand along this many m of road, centred on the placement.
@export var spread_along := 12.0
## Distance range in m beyond the road edge of their spots.
@export var gap_range := Vector2(1.5, 3.5)
## How far in m they step onto the road.
@export var step_in := Vector2(1.0, 2.0)
@export var step_speed := 2.5
@export var part_time := 1.2
@export var part_speed := 6.0
@export var spawn_height := 1.0

var _fans: Array[Person] = []
var _homes: Array[Vector3] = []
var _steps: Array[Vector3] = []
var _parted := false


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	var index := clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)
	var side := SurfacePatch._outside_sign(path, index)
	var to_local := transform.affine_inverse()
	for i in rng.randi_range(count_range.x, count_range.y):
		var along := distance + rng.randf_range(-spread_along, spread_along) / 2.0
		var home := verge_point(along, side, rng.randf_range(gap_range.x, gap_range.y))
		_homes.append(home)
		_steps.append(verge_point(along, side, -rng.randf_range(step_in.x, step_in.y)))
		var fan: Person = PERSON_SCENE.instantiate()
		fan.color = COLORS[rng.randi_range(0, COLORS.size() - 1)]
		fan.position = to_local * (home + Vector3.UP * spawn_height)
		_fans.append(fan)
		add_child(fan)


func _physics_process(delta: float) -> void:
	super(delta)
	if triggered and not _parted and time_to_arrival() <= part_time:
		_parted = true
		for i in _fans.size():
			_fans[i].dive_to(_homes[i], part_speed)


func _trigger() -> void:
	for i in _fans.size():
		_fans[i].walk_to(_steps[i], step_speed)
