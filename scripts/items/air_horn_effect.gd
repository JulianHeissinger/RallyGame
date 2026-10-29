class_name AirHornEffect
extends ItemEffect
## Clears the road ahead: people and animals on the road within `reach` m and `angle_deg` of the
## car's heading leave it to their nearer side. Needs a road (the stage) and at least one body
## to scare, or no cooldown starts.

@export var reach := 40.0
@export var angle_deg := 60.0
## Distance in m beyond the road edge that scared bodies head for.
@export var clearance := 4.0
## People run at this speed in m/s; animals walk at this multiple of their own walk speed.
@export var person_speed := 6.0
@export var animal_speed_scale := 2.0


func on_activate(car: Node, _data: Variant) -> bool:
	var path: RoadPath = car.road
	if path == null:
		return false
	var sphere := SphereShape3D.new()
	sphere.radius = reach
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, car.global_position)
	query.collision_mask = 2
	var forward: Vector3 = -car.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var scared := false
	for hit in car.get_world_3d().direct_space_state.intersect_shape(query, 256):
		var body: Node3D = hit["collider"]
		if not (body.has_method("flee") or body.has_method("flee_to")):
			continue
		var to: Vector3 = body.global_position - car.global_position
		to.y = 0.0
		if to.length() < 0.1 or rad_to_deg(forward.angle_to(to)) > angle_deg:
			continue
		var distance := path.progress_at(body.global_position)
		var closest := path.curve.sample_baked(distance)
		var half := path.widths[clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)] / 2.0
		var side := body.global_position - closest
		side.y = 0.0
		if side.length() > half:
			continue
		if side.length() < 0.1:
			side = path.transform_at(distance).basis.x.slide(Vector3.UP)
		var run := half - side.length() + clearance
		if body.has_method("flee_to"):
			body.flee_to(body.global_position + side.normalized() * run, animal_speed_scale)
		else:
			body.flee(side, run, person_speed)
		scared = true
	return scared
