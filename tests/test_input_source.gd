extends "res://tests/test_case.gd"

const DELTA := 1.0 / 120.0


func test_ramps_up_to_full_lock() -> void:
	var source := InputSource.new()
	var steer := source.step_steer(0.0, 1.0, DELTA, 0.0)
	assert_true(steer > 0.0 and steer < 1.0, "first step is partial")
	for i in 120:
		steer = source.step_steer(steer, 1.0, DELTA, 0.0)
	assert_almost_eq(steer, 1.0, 0.0001, "reaches full lock")


func test_returns_to_center() -> void:
	var source := InputSource.new()
	var steer := -1.0
	for i in 120:
		steer = source.step_steer(steer, 0.0, DELTA, 0.0)
		assert_true(steer <= 0.0, "does not overshoot center")
	assert_almost_eq(steer, 0.0, 0.0001, "reaches center")


func test_ramps_slower_at_speed() -> void:
	var source := InputSource.new()
	var still := source.step_steer(0.0, 1.0, DELTA, 0.0)
	var fast := source.step_steer(0.0, 1.0, DELTA, 30.0)
	assert_true(fast < still, "ramp toward lock slower at speed")
	var still_return := 1.0 - source.step_steer(1.0, 0.0, DELTA, 0.0)
	var fast_return := 1.0 - source.step_steer(1.0, 0.0, DELTA, 30.0)
	assert_true(fast_return < still_return, "return to center slower at speed")
