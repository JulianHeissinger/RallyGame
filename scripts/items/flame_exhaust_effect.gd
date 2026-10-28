class_name FlameExhaustEffect
extends ItemEffect
## Each upshift shoots a flame: a small forward kick, and light bodies behind the car are blasted
## away.

## Forward speed added per flame, in m/s.
@export var kick := 0.5
@export var radius := 3.0
## Blast speed in m/s given to bodies behind the car, away from it and up.
@export var blast_speed := 6.0
@export var blast_up := 3.0
@export var flame_time := 0.3


func on_activate(car: Node, data: Variant) -> bool:
	if data == null or data["to"] <= data["from"]:
		return false
	car.apply_central_impulse(-car.global_basis.z * kick * car.mass)
	ExhaustFlame.spawn(car, flame_time)
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), car.to_global(Vector3(0.0, 0.0, 2.0 + radius)))
	# Layer 2: animals and movable obstacles.
	query.collision_mask = 2
	query.exclude = [car.get_rid()]
	for hit in car.get_world_3d().direct_space_state.intersect_shape(query):
		var body := hit["collider"] as RigidBody3D
		if body == null or body.freeze:
			continue
		var away: Vector3 = (body.global_position - car.global_position).slide(Vector3.UP).normalized()
		body.apply_central_impulse(body.mass * (away * blast_speed + Vector3.UP * blast_up))
	return true
