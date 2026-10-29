class_name SpareWheelEffect
extends ItemEffect
## Swaps in the spare when a tire breaks: the tire goes back to `condition`. Other parts do not
## fire it, so no cooldown starts.

@export var condition := 60.0


func on_activate(car: Node, data: Variant) -> bool:
	var part: String = data["part"]
	if not part.begins_with("tire_"):
		return false
	car.damage.repair(part, condition)
	return true
