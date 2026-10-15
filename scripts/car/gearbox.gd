class_name Gearbox
extends RefCounted
## Gear selection with reverse, neutral and forward gears. A shift cuts drive torque for
## `shift_time`, then engages the new gear and emits `gear_shifted`. Automatic mode shifts by
## road-speed RPM and engages reverse when braking at standstill; manual mode follows shift
## presses.

signal gear_shifted(from: int, to: int)

enum Mode { AUTOMATIC, MANUAL }

const REVERSE := -1
const NEUTRAL := 0
const RAD_PER_SEC_TO_RPM := 60.0 / TAU

var mode := Mode.AUTOMATIC
## Engaged gear: -1 is reverse, 0 is neutral, 1..n are forward gears.
var gear := 1

var _target_gear := 1
var _shift_timer := 0.0


func is_shifting() -> bool:
	return _shift_timer > 0.0


## Gear ratio without final drive: negative in reverse, 0 in neutral.
func ratio(stats: StatBlock, g: int) -> float:
	if g == REVERSE:
		return -stats.get_stat("gear_ratio_r")
	if g == NEUTRAL:
		return 0.0
	return stats.get_stat("gear_ratio_%d" % g)


## Engine RPM that the driven wheels' mean spin gives in gear `g`.
func rpm_in_gear(stats: StatBlock, g: int, mean_spin: float) -> float:
	return absf(mean_spin * ratio(stats, g) * stats.get_stat("final_drive")) * RAD_PER_SEC_TO_RPM


## Advances a running shift, then picks the next gear. `speed` is the car's speed in m/s.
func update(input: InputSource, mean_spin: float, speed: float, stats: StatBlock, delta: float) -> void:
	if is_shifting():
		_shift_timer -= delta
		if _shift_timer <= 0.0:
			_shift_timer = 0.0
			var from := gear
			gear = _target_gear
			gear_shifted.emit(from, gear)

	var next: int
	if mode == Mode.MANUAL:
		next = _choose_manual(input, mean_spin, speed, stats)
	elif is_shifting():
		return
	else:
		next = _choose_automatic(input, speed, stats)
	if next == _target_gear:
		return
	_target_gear = next
	# Shifting back to the engaged gear mid-shift cancels the shift.
	_shift_timer = 0.0 if next == gear else stats.get_stat("shift_time")


## Manual presses act on the target gear, so quick repeated presses chain.
func _choose_manual(input: InputSource, mean_spin: float, speed: float, stats: StatBlock) -> int:
	var g := _target_gear
	if input.shift_up_pressed and g < int(stats.get_stat("gear_count")):
		return g + 1
	if input.shift_down_pressed:
		if g > 1:
			var over_rev := rpm_in_gear(stats, g - 1, mean_spin) > stats.get_stat("redline_rpm")
			return g if over_rev else g - 1
		if g == 1:
			return NEUTRAL
		if g == NEUTRAL and speed < stats.get_stat("reverse_speed"):
			return REVERSE
	return g


## Shift points use RPM matched to road speed, so wheelspin hits the limiter instead of shifting.
func _choose_automatic(input: InputSource, speed: float, stats: StatBlock) -> int:
	var standstill := speed < stats.get_stat("reverse_speed")
	if gear == REVERSE:
		return 1 if standstill and input.throttle > 0.0 else REVERSE
	if standstill and input.brake > 0.0 and input.throttle == 0.0:
		return REVERSE
	if gear == NEUTRAL:
		return 1
	var rpm := rpm_in_gear(stats, gear, speed / stats.get_stat("wheel_radius"))
	if rpm > stats.get_stat("shift_up_rpm") and gear < int(stats.get_stat("gear_count")):
		return gear + 1
	if rpm < stats.get_stat("shift_down_rpm") and gear > 1:
		return gear - 1
	return gear
