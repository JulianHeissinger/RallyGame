extends "res://tests/test_case.gd"


func test_penalty_adds_to_total() -> void:
	var timer := StageTimer.new()
	timer.update(1.0)
	assert_eq(timer.total(), 0.0, "no time before start")
	timer.start()
	timer.update(60.0)
	timer.add_penalty(5.0)
	assert_eq(timer.total(), 65.0, "60 s plus 5 s penalty")
	timer.stop()
	timer.update(1.0)
	assert_eq(timer.elapsed, 60.0, "no time after stop")
