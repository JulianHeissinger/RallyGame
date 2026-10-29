class_name CarDamage
extends Node
## Breakable car parts with conditions from 100 (intact) to 0 (broken). A damaged part keeps
## wearing while the car moves, faster the lower its condition.

signal part_damaged(part: String, amount: float)
signal part_broken(part: String)
signal immobilized(cause: String)
signal part_repaired(part: String)

const PARTS: Array[String] = [
	"tire_fl", "tire_fr", "tire_rl", "tire_rr",
	"brake_fl", "brake_fr", "brake_rl", "brake_rr",
	"suspension_fl", "suspension_fr", "suspension_rl", "suspension_rr",
	"engine", "chassis",
]
## Below this speed in m/s the car counts as standing and parts do not wear.
const MOVING_SPEED := 1.0
## Contacts within this distance of the body's centre along z hit the center zone (the middle
## third of the 4 m body); further out they hit a corner.
const CENTER_HALF_LENGTH := 0.67
## Front or rear contacts within this distance of the centre line along x (the middle third of
## the 1.7 m width) hit both corners of that end, each with `CENTER_END_SHARE` of the damage.
const CENTER_HALF_WIDTH := 0.28
const CENTER_END_SHARE := 0.75

var condition: Dictionary = {}
## Car stats, set by the car. Scales damage by the `<group>_damage_taken` stats; null in tests.
var stats: StatBlock
var is_immobilized := false


func _init() -> void:
	for part in PARTS:
		condition[part] = 100.0


## Impact, hazard or malfunction damage, scaled by the part group's `<group>_damage_taken` stat.
## Emits `part_damaged`, and `part_broken` when the part reaches 0.
func apply_damage(part: String, amount: float) -> void:
	if stats:
		amount *= stats.get_stat(part.get_slice("_", 0) + "_damage_taken")
	if condition[part] <= 0.0 or amount <= 0.0:
		return
	var applied := minf(amount, condition[part])
	_set_condition(part, condition[part] - applied)
	part_damaged.emit(part, applied)
	_check_broken(part)


## Collision at `local_point` (car space, front is -z) with `impact_speed` along the contact
## normal. `scale` multiplies the damage (soft bodies like sheep hurt less); front-end hits also
## scale by `front_impact_damage_taken` (bullbar). A hit on a `solid` body
## at or above `lethal_impact_speed` immobilizes the car.
func apply_impact(stats: StatBlock, local_point: Vector3, impact_speed: float, is_solid: bool,
		scale: float = 1.0) -> void:
	var amount := maxf(impact_speed - stats.get_stat("impact_min_speed"), 0.0) * stats.get_stat("impact_damage") * scale
	if absf(local_point.z) < CENTER_HALF_LENGTH:
		apply_damage("chassis", amount)
	else:
		var end := "f" if local_point.z < 0.0 else "r"
		if end == "f":
			amount *= stats.get_stat("front_impact_damage_taken")
		var corners: Array[String] = [end + ("l" if local_point.x < 0.0 else "r")]
		var corner_amount := amount
		if absf(local_point.x) < CENTER_HALF_WIDTH:
			corners = [end + "l", end + "r"]
			corner_amount *= CENTER_END_SHARE
		for corner in corners:
			for part in ["tire_", "brake_", "suspension_"]:
				apply_damage(part + corner, corner_amount)
		var share := amount * stats.get_stat("impact_chassis_share")
		apply_damage("chassis", share)
		if end == "f":
			apply_damage("engine", share)
	if is_solid and impact_speed >= stats.get_stat("lethal_impact_speed"):
		immobilize("lethal_impact")


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


## Raises `part` to `value` (at most 100). Does not undo immobilization.
func repair(part: String, value: float) -> void:
	value = minf(value, 100.0)
	if value <= condition[part]:
		return
	_set_condition(part, value)
	part_repaired.emit(part)


## Ends the run for this car. Emits `immobilized` once. Lethal impacts call it directly; part
## loss goes through `_check_immobilized`.
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
		_check_immobilized()


## Immobilized at chassis 0, engine 0, or three or more broken tires.
func _check_immobilized() -> void:
	if condition["chassis"] <= 0.0:
		immobilize("chassis_destroyed")
	elif condition["engine"] <= 0.0:
		immobilize("engine_destroyed")
	elif ["tire_fl", "tire_fr", "tire_rl", "tire_rr"].filter(
			func(tire: String) -> bool: return condition[tire] <= 0.0).size() >= 3:
		immobilize("tires_destroyed")
