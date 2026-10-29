class_name Knockable
extends RigidBody3D
## A light obstacle (traffic cone, hay bale, wheelie bin, shopping trolley, portable toilet). The
## first car hit knocks it sideways and up, frees it from the car and emits `hazard_defeated` once.
## Like the sheep it lives on collision layer 2, which wheel rays do not scan, so the car never
## stands on it; the scene's `impact_scale` and `impact_once` metadata keep the car damage small.

signal hazard_defeated(hazard: Node)

## Knock-away speed on the car hit, as a share of the car's speed: sideways away from the car's
## centreline and up. Without it the car pushes the prop along the road like a plough.
const KNOCK_SIDE := 0.5
const KNOCK_UP := 0.3

var _hit := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _hit or not body is Car:
		return
	_hit = true
	var car := body as Car
	add_collision_exception_with(car)
	var right := car.global_basis.x
	var side := right if (global_position - car.global_position).dot(right) >= 0.0 else -right
	var speed := car.linear_velocity.length()
	apply_central_impulse(mass * (side * speed * KNOCK_SIDE + Vector3.UP * speed * KNOCK_UP))
	hazard_defeated.emit(self)
