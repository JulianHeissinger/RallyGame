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


func test_wheel_factors_follow_condition() -> void:
	var stats := StatBlock.new({
		"flat_tire_grip": 0.4,
		"flat_tire_drag": 0.1,
		"suspension_damaged_sag": 0.6,
		"suspension_damaged_stiffness": 2.0,
	})
	var wheel := Wheel.new()
	wheel.apply_condition(stats, 100.0, 100.0, 100.0)
	assert_almost_eq(wheel.grip_factor, 1.0, 0.0001, "intact grip")
	assert_almost_eq(wheel.drag, 0.0, 0.0001, "intact drag")
	assert_almost_eq(wheel.brake_factor, 1.0, 0.0001, "intact brake")
	assert_almost_eq(wheel.rest_factor, 1.0, 0.0001, "intact rest length")
	assert_almost_eq(wheel.stiffness_factor, 1.0, 0.0001, "intact stiffness")
	wheel.apply_condition(stats, 0.0, 0.0, 50.0)
	assert_almost_eq(wheel.grip_factor, 0.4, 0.0001, "flat tire grip")
	assert_almost_eq(wheel.drag, 0.1, 0.0001, "flat tire drag")
	assert_almost_eq(wheel.brake_factor, 0.0, 0.0001, "broken brake")
	assert_almost_eq(wheel.rest_factor, 0.8, 0.0001, "half-damaged sag")
	assert_almost_eq(wheel.stiffness_factor, 1.5, 0.0001, "half-damaged stiffness")
	wheel.free()


func _impact_stats() -> StatBlock:
	return StatBlock.new({
		"impact_min_speed": 3.0,
		"impact_damage": 4.0,
		"impact_chassis_share": 0.3,
		"lethal_impact_speed": 18.0,
	})


func test_front_right_impact_damages_that_corner() -> void:
	var damage := _damage()
	damage.apply_impact(_impact_stats(), Vector3(0.8, 0.0, -1.9), 13.0, false)
	for part in ["tire_fr", "brake_fr", "suspension_fr"]:
		assert_almost_eq(damage.condition[part], 60.0, 0.0001, part)
	assert_almost_eq(damage.condition["chassis"], 88.0, 0.0001, "chassis share")
	assert_almost_eq(damage.condition["engine"], 88.0, 0.0001, "engine share on front hit")
	for part in ["tire_fl", "tire_rr", "brake_rl", "suspension_rl"]:
		assert_eq(damage.condition[part], 100.0, part)
	damage.free()


func test_center_and_rear_impacts() -> void:
	var damage := _damage()
	damage.apply_impact(_impact_stats(), Vector3(-0.85, 0.0, 0.2), 8.0, false)
	assert_almost_eq(damage.condition["chassis"], 80.0, 0.0001, "center hit damages chassis")
	damage.apply_impact(_impact_stats(), Vector3(-0.8, 0.0, 1.9), 8.0, false)
	assert_almost_eq(damage.condition["tire_rl"], 80.0, 0.0001, "rear-left tire")
	assert_eq(damage.condition["engine"], 100.0, "rear hit spares engine")
	damage.free()


func test_light_bump_does_no_damage() -> void:
	var damage := _damage()
	damage.apply_impact(_impact_stats(), Vector3(0.0, 0.0, -2.0), 2.5, true)
	assert_eq(_damaged, [], "below impact_min_speed")
	damage.free()


func test_lethal_impact_only_against_solid() -> void:
	var damage := _damage()
	damage.apply_impact(_impact_stats(), Vector3(0.0, 0.0, -2.0), 20.0, false)
	assert_false(damage.is_immobilized, "non-solid survives")
	damage.apply_impact(_impact_stats(), Vector3(0.0, 0.0, -2.0), 20.0, true)
	assert_eq(_immobilized, ["lethal_impact"], "solid above lethal speed")
	damage.free()


func test_raised_lethal_speed_survives() -> void:
	var damage := _damage()
	var stats := _impact_stats()
	stats.additive["lethal_impact_speed"] = 10.0
	stats.mark_dirty()
	damage.apply_impact(stats, Vector3(0.0, 0.0, -2.0), 20.0, true)
	assert_false(damage.is_immobilized, "raised threshold survives")
	assert_true(damage.condition["chassis"] < 100.0, "parts still damaged")
	damage.free()


func test_center_end_impacts_hit_both_corners() -> void:
	var damage := _damage()
	# amount = (13 - 3) * 4 = 40, each corner takes 0.75 of it.
	damage.apply_impact(_impact_stats(), Vector3(0.1, 0.0, -2.0), 13.0, false)
	for part in ["tire_fl", "tire_fr", "brake_fl", "brake_fr", "suspension_fl", "suspension_fr"]:
		assert_almost_eq(damage.condition[part], 70.0, 0.0001, part)
	assert_almost_eq(damage.condition["engine"], 88.0, 0.0001, "engine share unchanged")
	damage.apply_impact(_impact_stats(), Vector3(-0.1, 0.0, 2.0), 13.0, false)
	assert_almost_eq(damage.condition["tire_rl"], 70.0, 0.0001, "rear-center hits rear-left")
	assert_almost_eq(damage.condition["tire_rr"], 70.0, 0.0001, "rear-center hits rear-right")
	damage.free()
