class_name BullbarEffect
extends ItemEffect
## A front-end hit knocks the body sideways and up, harder than a bare bumper. The reduced front
## damage is the item's `front_impact_damage_taken` modifier.

## Knock-away speed as a share of the car's speed, sideways away from the centreline and up.
@export var side := 0.8
@export var up := 0.4


func on_activate(car: Node, data: Variant) -> bool:
	var body := data["body"] as RigidBody3D
	if body == null or body.freeze or data["point"].z > -CarDamage.CENTER_HALF_LENGTH:
		return false
	var right: Vector3 = car.global_basis.x
	var away := right if (body.global_position - car.global_position).dot(right) >= 0.0 else -right
	var speed: float = car.linear_velocity.length()
	body.apply_central_impulse(body.mass * speed * (away * side + Vector3.UP * up))
	return true
