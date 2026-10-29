extends "res://tests/test_case.gd"

const SHIFT_TIME := 0.15
const DELTA := 1.0 / 120.0
const RAD_PER_SEC_TO_RPM := 60.0 / TAU
## Long enough for a started shift to finish despite float rounding of tick sums.
const SETTLE := SHIFT_TIME + 2.0 * DELTA

var _shifts: Array = []


func _stats() -> StatBlock:
	return StatBlock.new({
		"gear_count": 5.0,
		"gear_ratio_r": 3.2,
		"gear_ratio_1": 3.3,
		"gear_ratio_2": 2.1,
		"gear_ratio_3": 1.5,
		"gear_ratio_4": 1.15,
		"gear_ratio_5": 0.92,
		"final_drive": 4.1,
		"wheel_radius": 0.33,
		"redline_rpm": 7500.0,
		"shift_time": SHIFT_TIME,
		"shift_up_rpm": 7000.0,
		"shift_down_rpm": 3000.0,
		"reverse_speed": 1.0,
	})


func _gearbox(mode: Gearbox.Mode, gear: int) -> Gearbox:
	var gearbox := Gearbox.new()
	gearbox.mode = mode
	gearbox.gear = gear
	gearbox._target_gear = gear
	_shifts.clear()
	gearbox.gear_shifted.connect(func(from: int, to: int) -> void: _shifts.append([from, to]))
	return gearbox


## Wheel spin in rad/s that gives `rpm` in `gear`.
func _spin_for(stats: StatBlock, gear: int, rpm: float) -> float:
	return rpm / RAD_PER_SEC_TO_RPM / (stats.get_stat("gear_ratio_%d" % gear) * stats.get_stat("final_drive"))


## Car speed in m/s that gives `rpm` in `gear` without wheel slip.
func _speed_for(stats: StatBlock, gear: int, rpm: float) -> float:
	return _spin_for(stats, gear, rpm) * stats.get_stat("wheel_radius")


## Runs `seconds` of ticks with constant input; shift presses count only on the first tick.
func _run(gearbox: Gearbox, input: InputSource, mean_spin: float, speed: float, stats: StatBlock, seconds: float) -> void:
	for i in ceili(seconds / DELTA):
		gearbox.update(input, mean_spin, speed, stats, DELTA)
		input.shift_up_pressed = false
		input.shift_down_pressed = false


func test_automatic_upshift_after_shift_time_with_torque_cut() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.AUTOMATIC, 1)
	var input := InputSource.new()
	input.throttle = 1.0
	var spin := _spin_for(stats, 1, 7200.0)
	gearbox.update(input, spin, _speed_for(stats, 1, 7200.0), stats, DELTA)
	assert_true(gearbox.is_shifting(), "shift starts above shift-up RPM")
	assert_eq(gearbox.gear, 1, "old gear stays engaged during shift")
	_run(gearbox, input, spin, _speed_for(stats, 1, 7200.0), stats, SETTLE)
	assert_eq(gearbox.gear, 2, "2nd engaged after shift time")
	assert_false(gearbox.is_shifting(), "shift finished")
	assert_eq(_shifts, [[1, 2]], "gear_shifted emitted once")


func test_automatic_downshift() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.AUTOMATIC, 3)
	_run(gearbox, InputSource.new(), _spin_for(stats, 3, 2500.0), _speed_for(stats, 3, 2500.0), stats, SETTLE)
	assert_eq(gearbox.gear, 2, "shifts down below shift-down RPM")


func test_automatic_wheelspin_does_not_upshift() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.AUTOMATIC, 1)
	var input := InputSource.new()
	input.throttle = 1.0
	_run(gearbox, input, _spin_for(stats, 1, 7400.0), 4.0, stats, SETTLE)
	assert_eq(gearbox.gear, 1, "wheel RPM over shift point at low road speed stays in 1st")


func test_automatic_reverse_by_brake_and_back_by_throttle() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.AUTOMATIC, 1)
	var input := InputSource.new()
	input.brake = 1.0
	_run(gearbox, input, 0.0, 5.0, stats, SETTLE)
	assert_eq(gearbox.gear, 1, "brake while moving does not engage reverse")
	_run(gearbox, input, 0.0, 0.5, stats, SETTLE)
	assert_eq(gearbox.gear, Gearbox.REVERSE, "brake at standstill engages reverse")
	input.brake = 0.0
	input.throttle = 1.0
	_run(gearbox, input, 0.0, 0.5, stats, SETTLE)
	assert_eq(gearbox.gear, 1, "throttle at standstill engages 1st")


func test_manual_shift_up() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.MANUAL, 2)
	var input := InputSource.new()
	input.shift_up_pressed = true
	_run(gearbox, input, _spin_for(stats, 2, 5000.0), 20.0, stats, SHIFT_TIME / 2.0)
	assert_eq(gearbox.gear, 2, "still 2nd before shift time")
	_run(gearbox, input, _spin_for(stats, 2, 5000.0), 20.0, stats, SETTLE)
	assert_eq(gearbox.gear, 3, "3rd after shift time")
	assert_eq(_shifts, [[2, 3]], "gear_shifted emitted")


func test_manual_reverse_at_standstill() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.MANUAL, 1)
	var input := InputSource.new()
	input.shift_down_pressed = true
	_run(gearbox, input, 0.0, 0.0, stats, DELTA)
	input.shift_down_pressed = true
	_run(gearbox, input, 0.0, 0.0, stats, SETTLE)
	assert_eq(gearbox.gear, Gearbox.REVERSE, "two quick presses reach reverse")


func test_manual_reverse_refused_while_moving() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.MANUAL, Gearbox.NEUTRAL)
	var input := InputSource.new()
	input.shift_down_pressed = true
	_run(gearbox, input, 30.0, 10.0, stats, SETTLE)
	assert_eq(gearbox.gear, Gearbox.NEUTRAL, "stays in neutral at speed")


func test_manual_over_rev_downshift_refused() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.MANUAL, 3)
	var input := InputSource.new()
	input.shift_down_pressed = true
	# 6000 RPM in 3rd is 8400 RPM in 2nd.
	_run(gearbox, input, _spin_for(stats, 3, 6000.0), 30.0, stats, SETTLE)
	assert_eq(gearbox.gear, 3, "downshift above redline refused")
	assert_false(gearbox.is_shifting(), "no shift started")


func test_manual_brake_does_not_engage_reverse() -> void:
	var stats := _stats()
	var gearbox := _gearbox(Gearbox.Mode.MANUAL, 1)
	var input := InputSource.new()
	input.brake = 1.0
	_run(gearbox, input, 0.0, 0.0, stats, SETTLE)
	assert_eq(gearbox.gear, 1, "brake at standstill keeps 1st")
