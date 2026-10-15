class_name Drivetrain
extends RefCounted
## AWD engine and brakes: turns driver input into per-wheel drive and brake torque.
## Engine RPM follows the driven wheels; an automatic clutch holds a launch RPM under throttle
## so the engine never stalls.

var gearbox := Gearbox.new()
var rpm := 0.0
var limiter_active := false


## `speed` is the car's speed in m/s.
func update(input: InputSource, wheels: Array[Wheel], stats: StatBlock, torque_curve: Curve, speed: float, delta: float) -> void:
	var idle := stats.get_stat("idle_rpm")
	var redline := stats.get_stat("redline_rpm")

	var mean_spin := 0.0
	for wheel in wheels:
		mean_spin += wheel.spin
	mean_spin /= wheels.size()
	gearbox.update(input, mean_spin, speed, stats, delta)
	var ratio := gearbox.ratio(stats, gearbox.gear) * stats.get_stat("final_drive")

	# Automatic reverse: brake drives backwards and throttle brakes.
	var swap := gearbox.mode == Gearbox.Mode.AUTOMATIC and gearbox.gear == Gearbox.REVERSE
	var throttle := input.brake if swap else input.throttle
	var brake_input := input.throttle if swap else input.brake

	var clutch_rpm := lerpf(idle, stats.get_stat("launch_rpm"), throttle)
	rpm = maxf(gearbox.rpm_in_gear(stats, gearbox.gear, mean_spin), clutch_rpm)

	if rpm >= redline:
		limiter_active = true
	elif rpm < redline - stats.get_stat("limiter_hysteresis_rpm"):
		limiter_active = false

	# Total torque at the driven wheels; the reverse ratio is negative, so engine braking uses its
	# magnitude to always oppose wheel spin.
	var wheel_torque: float
	if gearbox.is_shifting():
		wheel_torque = 0.0
	elif throttle > 0.0 and not limiter_active:
		wheel_torque = throttle * stats.get_stat("max_torque") * torque_curve.sample(rpm / redline) * ratio
	else:
		wheel_torque = -signf(mean_spin) * stats.get_stat("engine_brake_torque") * rpm / redline * absf(ratio)
	var split_front := stats.get_stat("torque_split_front")

	# `brake_torque` is the mean per-wheel torque; the bias shifts it between axles.
	var brake := brake_input * stats.get_stat("brake_torque") * 4.0
	var bias_front := stats.get_stat("brake_bias_front")
	var handbrake := input.handbrake * stats.get_stat("handbrake_torque")

	for wheel in wheels:
		var axle_share := split_front if wheel.steerable else 1.0 - split_front
		wheel.drive_torque = wheel_torque * axle_share * 0.5
		if wheel.steerable:
			wheel.brake_torque = brake * bias_front * 0.5
		else:
			wheel.brake_torque = brake * (1.0 - bias_front) * 0.5 + handbrake
