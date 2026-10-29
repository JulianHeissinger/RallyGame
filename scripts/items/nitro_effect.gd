class_name NitroEffect
extends ItemEffect
## Spends boost for a burn that pushes the car forward. A mounted nitro refills the boost meter
## slowly by itself.

@export var cost := 0.25
@export var burn_time := 1.5
## Forward acceleration in m/s² while burning with two or more wheels grounded.
@export var acceleration := 6.0
## Boost refilled per second.
@export var refill := 0.04

var _burn_left := 0.0


func on_activate(car: Node, _data: Variant) -> bool:
	if not car.items.spend_boost(cost):
		return false
	_burn_left = burn_time
	ExhaustFlame.spawn(car, burn_time)
	return true


func on_physics(car: Node, delta: float) -> void:
	car.items.fill_boost(refill * delta)
	if _burn_left <= 0.0:
		return
	_burn_left -= delta
	if car.wheels.filter(func(w: Wheel) -> bool: return w.is_grounded).size() >= 2:
		car.apply_central_force(-car.global_basis.z * acceleration * car.mass)
