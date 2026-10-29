class_name UnderdogEffect
extends ItemEffect
## More engine power for every broken part.

@export var power_per_broken_part := 0.05


func dynamic_modifiers(car: Node) -> Array[StatModifier]:
	var broken := 0
	for part: String in car.damage.condition:
		if car.damage.condition[part] <= 0.0:
			broken += 1
	var modifier := StatModifier.new()
	modifier.stat = "max_torque"
	modifier.multiplier = 1.0 + power_per_broken_part * broken
	return [modifier]
