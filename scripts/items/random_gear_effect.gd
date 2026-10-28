class_name RandomGearEffect
extends ItemEffect
## Each shift into a forward gear lands in a random other forward gear (Gearbox of Chaos).

## Seconds automatic mode keeps the random gear before shifting again.
@export var hold := 1.5

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func on_event(car: Node, event: String, data: Variant) -> void:
	var count := int(car.stats.get_stat("gear_count"))
	if event != "gear_shift" or data["to"] < 1 or count < 2:
		return
	# Draw from the other forward gears: skip over the gear the shift landed in.
	var gear := _rng.randi_range(1, count - 1)
	if gear >= data["to"]:
		gear += 1
	car.drivetrain.gearbox.force_gear(gear, hold)
