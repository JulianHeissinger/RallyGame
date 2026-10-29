class_name LuckyRepairEffect
extends ItemEffect
## A part that breaks may repair itself at once (Lucky Dice).

@export var chance := 0.25
@export var repair_to := 30.0

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func on_event(car: Node, event: String, data: Variant) -> void:
	if event == "part_broken" and car.damage.condition[data["part"]] <= 0.0 and _rng.randf() < chance:
		car.damage.repair(data["part"], repair_to)
