class_name GrappleHookEffect
extends ItemEffect
## Pulls an off-road car back toward the road: sets its horizontal velocity toward the nearest
## road point and lifts it. Works only on a stage and when the car is off the road.

## Pull speed in m/s per m of distance from the road point, capped at `max_speed`.
@export var pull := 1.5
@export var max_speed := 12.0
@export var lift := 3.0


func on_activate(car: Node, _data: Variant) -> bool:
	var path: RoadPath = car.road
	if path == null:
		return false
	var distance := path.progress_at(car.global_position)
	var to: Vector3 = path.curve.sample_baked(distance) - car.global_position
	to.y = 0.0
	var half := path.widths[clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)] / 2.0
	if to.length() <= half:
		return false
	var speed := minf(to.length() * pull, max_speed)
	car.linear_velocity = to.normalized() * speed + Vector3.UP * lift
	return true
