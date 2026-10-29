extends "res://tests/test_case.gd"


func test_broken_tire_shows_broken() -> void:
	var damage := CarDamage.new()
	var display := PartsDisplay.new()
	display.damage = damage
	damage.apply_damage("tire_fl", 1000.0)
	assert_eq(display.part_state("tire_fl"), PartsDisplay.State.BROKEN, "broken tire")
	assert_eq(display.part_state("tire_fr"), PartsDisplay.State.OK, "other tire intact")
	assert_eq(PartsDisplay.color(0.0), PartsDisplay.BROKEN_COLOR, "broken colour")
	display.free()
	damage.free()


func test_condition_bands() -> void:
	assert_eq(PartsDisplay.state(100.0), PartsDisplay.State.OK, "intact")
	assert_eq(PartsDisplay.state(60.0), PartsDisplay.State.OK, "60 still ok")
	assert_eq(PartsDisplay.state(59.0), PartsDisplay.State.WORN, "worn")
	assert_eq(PartsDisplay.state(24.0), PartsDisplay.State.DAMAGED, "damaged")
	assert_true(PartsDisplay.color(100.0).is_equal_approx(PartsDisplay.GOOD_COLOR), "green at 100")
	assert_true(PartsDisplay.color(60.0).is_equal_approx(PartsDisplay.WORN_COLOR), "yellow at 60")
	assert_true(PartsDisplay.color(25.0).is_equal_approx(PartsDisplay.DAMAGED_COLOR), "red at 25")


func test_time_text() -> void:
	assert_eq(Hud.time_text(0.0), "0:00.00", "zero")
	assert_eq(Hud.time_text(65.0), "1:05.00", "65 s")
	assert_eq(Hud.time_text(125.456), "2:05.46", "rounded to cs")


func test_shift_light() -> void:
	var stats := StatBlock.new(load("res://data/cars/prototype.tres").stats)
	assert_false(Hud.shift_light_on(6999.0, stats), "off below shift_up_rpm")
	assert_true(Hud.shift_light_on(7000.0, stats), "on at shift_up_rpm")
