class_name ApproachHazard
extends Node3D
## Base for hazards that act once when the car approaches: `_trigger` runs when the car is
## `lead_time` seconds away along the road at its current speed. Subclasses that override
## `_physics_process` call `super`.

@export var lead_time := 2.0
## Arrival time uses at least this car speed in m/s, so a crawling car still triggers the hazard.
@export var min_trigger_speed := 5.0

var car: Car
var path: RoadPath
## Distance of the hazard along the road.
var distance := 0.0
var triggered := false


## Called by the stage before the hazard enters the tree; its `transform` is already set.
func setup(def: HazardDef, target: Car, road: RoadPath, rng: RandomNumberGenerator) -> void:
	car = target
	path = road
	distance = path.progress_at(transform.origin)
	_setup(def, rng)


## Placement-time setup for subclasses.
func _setup(_def: HazardDef, _rng: RandomNumberGenerator) -> void:
	pass


func _physics_process(_delta: float) -> void:
	if triggered or car == null:
		return
	if time_to_arrival() <= lead_time:
		triggered = true
		_trigger()


## Seconds until the car reaches the hazard along the road at its current speed.
func time_to_arrival() -> float:
	var remaining := distance - path.progress_at(car.global_position)
	return remaining / maxf(car.linear_velocity.length(), min_trigger_speed)


## Point beside the road at `along`, `gap` m beyond the road edge on `side` (+1 right, -1 left);
## a negative `gap` lies on the road.
func verge_point(along: float, side: float, gap: float) -> Vector3:
	var road := path.transform_at(along)
	var half := path.widths[clampi(path.distances.bsearch(along), 0, path.widths.size() - 1)] / 2.0
	return road.origin + road.basis.x * side * (half + gap)


func _trigger() -> void:
	pass
