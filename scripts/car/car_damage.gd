class_name CarDamage
extends Node
## Breakable car parts with conditions from 100 (intact) to 0 (broken). A damaged part keeps
## wearing while the car moves, faster the lower its condition.

signal part_damaged(part: String, amount: float)
signal part_broken(part: String)
signal immobilized(cause: String)

const PARTS: Array[String] = [
	"tire_fl", "tire_fr", "tire_rl", "tire_rr",
	"brake_fl", "brake_fr", "brake_rl", "brake_rr",
	"engine", "suspension", "chassis",
]
## Below this speed in m/s the car counts as standing and parts do not wear.
const MOVING_SPEED := 1.0

var condition: Dictionary = {}
var is_immobilized := false


func _init() -> void:
	for part in PARTS:
		condition[part] = 100.0


## Impact or hazard damage. Emits `part_damaged`, and `part_broken` when the part reaches 0.
func apply_damage(part: String, amount: float) -> void:
	if condition[part] <= 0.0 or amount <= 0.0:
		return
	var applied := minf(amount, condition[part])
	_set_condition(part, condition[part] - applied)
	part_damaged.emit(part, applied)
	_check_broken(part)


## Wear of damaged parts: `wear_rate * (1 + (100 - c) / wear_acceleration)` per second.
## Emits only `part_broken`, not `part_damaged`, to avoid a signal every tick.
func update_wear(stats: StatBlock, delta: float, speed: float) -> void:
	if speed < MOVING_SPEED:
		return
	var rate := stats.get_stat("wear_rate")
	var acceleration := stats.get_stat("wear_acceleration")
	for part in PARTS:
		var c: float = condition[part]
		if c >= 100.0 or c <= 0.0:
			continue
		_set_condition(part, c - rate * (1.0 + (100.0 - c) / acceleration) * delta)
		_check_broken(part)


## Ends the run for this car. Emits `immobilized` once.
func immobilize(cause: String) -> void:
	if is_immobilized:
		return
	is_immobilized = true
	immobilized.emit(cause)


func _set_condition(part: String, value: float) -> void:
	condition[part] = maxf(value, 0.0)


func _check_broken(part: String) -> void:
	if condition[part] <= 0.0:
		part_broken.emit(part)
