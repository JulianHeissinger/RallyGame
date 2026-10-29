class_name DriftKingEffect
extends ItemEffect
## Drifting fills the boost meter, twice as fast while any brake is broken.

@export var fill_per_second := 0.15


func on_event(car: Node, event: String, data: Variant) -> void:
	if event != "drift":
		return
	var rate := fill_per_second
	for corner in ["fl", "fr", "rl", "rr"]:
		if car.damage.condition["brake_" + corner] <= 0.0:
			rate *= 2.0
			break
	car.items.fill_boost(rate * data["delta"])
