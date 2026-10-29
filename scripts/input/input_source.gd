class_name InputSource
extends RefCounted
## Single-player input: keyboard plus joypad device 0. The car reads only these values.
## Keyboard steering ramps toward its target; the ramp slows down as car speed rises.

const DEVICE := 0
const STICK_DEADZONE := 0.1

## Steering rate toward lock, in full-range units per second, at standstill and at `steer_fast_speed`.
var steer_rate_slow := 6.0
var steer_rate_fast := 4.0
## Steering rate back to center at standstill and at `steer_fast_speed`.
var steer_return_rate_slow := 6.0
var steer_return_rate_fast := 5.5
## Speed in m/s at which the fast rates apply fully.
var steer_fast_speed := 30.0

var steer := 0.0
var throttle := 0.0
var brake := 0.0
var handbrake := 0.0
var shift_up_pressed := false
var shift_down_pressed := false
var activate_pressed := false
## While true (upgrade pick open) every input reads as released and steering centres at once.
var blocked := false


## Reads input for one physics tick. `speed` is the car's speed in m/s.
func update(delta: float, speed: float) -> void:
	if blocked:
		steer = 0.0
		throttle = 0.0
		brake = 0.0
		handbrake = 0.0
		shift_up_pressed = false
		shift_down_pressed = false
		activate_pressed = false
		return
	var stick := Input.get_joy_axis(DEVICE, JOY_AXIS_LEFT_X)
	if absf(stick) > STICK_DEADZONE:
		steer = stick
	else:
		steer = step_steer(steer, Input.get_axis("steer_left", "steer_right"), delta, speed)
	throttle = Input.get_action_strength("throttle")
	brake = Input.get_action_strength("brake")
	handbrake = Input.get_action_strength("handbrake")
	shift_up_pressed = Input.is_action_just_pressed("shift_up")
	shift_down_pressed = Input.is_action_just_pressed("shift_down")
	activate_pressed = Input.is_action_just_pressed("activate_item")


## Moves `current` toward `target` at a speed-dependent rate. Moving away from center uses the
## steer rate, moving toward center uses the return rate.
func step_steer(current: float, target: float, delta: float, speed: float) -> float:
	var t := clampf(speed / steer_fast_speed, 0.0, 1.0)
	var toward_center := absf(target) < absf(current) and signf(target) != -signf(current)
	var rate := lerpf(steer_return_rate_slow, steer_return_rate_fast, t) if toward_center \
		else lerpf(steer_rate_slow, steer_rate_fast, t)
	return move_toward(current, target, rate * delta)
