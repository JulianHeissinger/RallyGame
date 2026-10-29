class_name DriftLaunchEffect
extends ItemEffect
## The end of a drift launches the car forward, more after longer drifts.

## Drifts shorter than this, in seconds, give nothing.
@export var min_duration := 0.5
## Forward speed in m/s per second of drift, capped at `max_speed_gain`.
@export var speed_per_second := 1.5
@export var max_speed_gain := 5.0


func on_activate(car: Node, data: Variant) -> bool:
	if data["duration"] < min_duration:
		return false
	var gain := minf(data["duration"] * speed_per_second, max_speed_gain)
	car.apply_central_impulse(-car.global_basis.z * gain * car.mass)
	ExhaustFlame.spawn(car, 0.3)
	return true
