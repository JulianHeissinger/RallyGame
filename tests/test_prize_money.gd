extends "res://tests/test_case.gd"


func test_faster_time_pays_more() -> void:
	var params := StageParams.new()
	params.prize_base = 1000
	params.prize_reference_speed = 20.0
	# 3000 m at 20 m/s: par 150 s.
	assert_eq(PrizeMoney.award(3000.0, 150.0, params), 1000, "par time pays base")
	assert_true(PrizeMoney.award(3000.0, 120.0, params) > PrizeMoney.award(3000.0, 180.0, params), "120 s beats 180 s")
	assert_eq(PrizeMoney.award(3000.0, 10.0, params), 2000, "capped at twice")
	assert_eq(PrizeMoney.award(3000.0, 6000.0, params), 250, "at least a quarter")
	var timer := StageTimer.new()
	timer.start()
	timer.update(150.0)
	var clean := PrizeMoney.award(3000.0, timer.total(), params)
	timer.add_penalty(10.0)
	assert_true(PrizeMoney.award(3000.0, timer.total(), params) < clean, "penalty lowers the prize")
