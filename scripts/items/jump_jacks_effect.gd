class_name JumpJacksEffect
extends ItemEffect
## Hops the car into the air; needs two or more wheels on the ground.

## Upward speed in m/s; 5.4 gives a hop of about 1.5 m.
@export var speed := 5.4


func on_activate(car: Node, _data: Variant) -> bool:
	if car.wheels.filter(func(w: Wheel) -> bool: return w.is_grounded).size() < 2:
		return false
	car.apply_central_impulse(car.global_basis.y * speed * car.mass)
	return true
