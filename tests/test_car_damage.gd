extends "res://tests/test_case.gd"

const DELTA := 1.0 / 120.0
const DRIVING_SPEED := 20.0

var _damaged: Array = []
var _broken: Array = []
var _immobilized: Array = []


func _stats() -> StatBlock:
	return StatBlock.new({"wear_rate": 0.1, "wear_acceleration": 10.0})


func _damage() -> CarDamage:
	_damaged.clear()
	_broken.clear()
	_immobilized.clear()
	var damage := CarDamage.new()
	damage.part_damaged.connect(func(part: String, amount: float) -> void: _damaged.append([part, amount]))
	damage.part_broken.connect(func(part: String) -> void: _broken.append(part))
	damage.immobilized.connect(func(cause: String) -> void: _immobilized.append(cause))
	return damage


func _drive(damage: CarDamage, stats: StatBlock, seconds: float, speed: float) -> void:
	for i in roundi(seconds / DELTA):
		damage.update_wear(stats, DELTA, speed)


func test_fresh_car_is_intact() -> void:
	var damage := _damage()
	for part in CarDamage.PARTS:
		assert_eq(damage.condition[part], 100.0, part)
	damage.free()


func test_intact_part_does_not_wear() -> void:
	var damage := _damage()
	_drive(damage, _stats(), 300.0, DRIVING_SPEED)
	assert_eq(damage.condition["tire_fl"], 100.0, "intact tire after 300 s of driving")
	damage.free()


func test_damaged_part_wears_to_zero_within_a_stage() -> void:
	var damage := _damage()
	damage.apply_damage("tire_fl", 30.0)
	_drive(damage, _stats(), 60.0, DRIVING_SPEED)
	assert_true(damage.condition["tire_fl"] > 0.0, "70% tire still holds after 60 s")
	_drive(damage, _stats(), 90.0, DRIVING_SPEED)
	assert_eq(damage.condition["tire_fl"], 0.0, "70% tire broken within 150 s")
	assert_eq(_broken, ["tire_fl"], "part_broken fires once from wear")
	damage.free()


func test_no_wear_while_standing() -> void:
	var damage := _damage()
	damage.apply_damage("engine", 30.0)
	_drive(damage, _stats(), 60.0, 0.5)
	assert_eq(damage.condition["engine"], 70.0, "no wear below moving speed")
	damage.free()


func test_damage_signals() -> void:
	var damage := _damage()
	damage.apply_damage("brake_rr", 60.0)
	damage.apply_damage("brake_rr", 60.0)
	damage.apply_damage("brake_rr", 10.0)
	assert_eq(_damaged, [["brake_rr", 60.0], ["brake_rr", 40.0]], "part_damaged reports applied amount")
	assert_eq(_broken, ["brake_rr"], "part_broken fires once")
	assert_eq(damage.condition["brake_rr"], 0.0, "condition clamped at 0")
	damage.free()


func test_immobilized_fires_once() -> void:
	var damage := _damage()
	damage.immobilize("engine")
	damage.immobilize("chassis")
	assert_eq(_immobilized, ["engine"], "immobilized fires once")
	assert_true(damage.is_immobilized, "flag set")
	damage.free()
