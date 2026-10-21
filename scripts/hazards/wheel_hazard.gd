class_name WheelHazard
extends Node3D
## Damages the parts of each wheel that drives over it: every `damage` group of its def on that
## wheel's corner, scaled by car speed between the def's `min_speed` and `full_speed`. Once per
## entry, or per second while on it when `continuous` (washboard). A circle of `radius`, or a
## rectangle when `size` is set (x across, y along the road; x = 0 spans the road). A `RoadBumps`
## child gets the road width and the section's surface.

## Footprint radius in m around the node origin.
@export var radius := 0.5
@export var size := Vector2.ZERO
@export var continuous := false

## Extra width in m beyond the road edges for hazards that span the road.
const SPAN_MARGIN := 1.0

var def: HazardDef
var car: Car

var _inside := {}


func setup(hazard_def: HazardDef, target: Car, path: RoadPath, _rng: RandomNumberGenerator) -> void:
	def = hazard_def
	car = target
	var index := clampi(path.distances.bsearch(path.progress_at(transform.origin)), 0, path.widths.size() - 1)
	if size != Vector2.ZERO and size.x <= 0.0:
		size.x = path.widths[index] + 2.0 * SPAN_MARGIN
	for child in get_children():
		if child is RoadBumps:
			child.width = size.x if size != Vector2.ZERO else 2.0 * radius
			child.set_meta("surface", path.section_at(index).road_surface)


func _physics_process(delta: float) -> void:
	if car == null:
		return
	var scale := clampf((car.linear_velocity.length() - def.min_speed) / (def.full_speed - def.min_speed), 0.0, 1.0)
	for wheel in car.wheels:
		var inside := wheel.is_grounded and _contains(wheel.global_position)
		var entering: bool = inside and not _inside.get(wheel, false)
		if scale > 0.0 and (entering or (inside and continuous)):
			var corner := wheel.name.trim_prefix("Wheel").to_lower()
			for group: String in def.damage:
				var amount: float = def.damage[group] * scale * (delta if continuous else 1.0)
				car.damage.apply_damage(group + "_" + corner, amount)
		_inside[wheel] = inside


func _contains(point: Vector3) -> bool:
	var local := to_local(point)
	if size != Vector2.ZERO:
		return absf(local.x) <= size.x / 2.0 and absf(local.z) <= size.y / 2.0
	return Vector2(local.x, local.z).length() < radius
