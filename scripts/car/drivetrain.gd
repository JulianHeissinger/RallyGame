class_name Drivetrain
extends RefCounted
## AWD engine and brakes: turns driver input into per-wheel drive and brake torque.
## Engine RPM follows the driven wheels; an automatic clutch holds a launch RPM under throttle
## so the engine never stalls.

const RAD_PER_SEC_TO_RPM := 60.0 / TAU

## 0 is neutral, 1..n are forward gears.
var gear := 1
var rpm := 0.0
var limiter_active := false


func update(input: InputSource, wheels: Array[Wheel], stats: StatBlock, torque_curve: Curve) -> void:
	var idle := stats.get_stat("idle_rpm")
	var redline := stats.get_stat("redline_rpm")
	var ratio := 0.0 if gear == 0 else stats.get_stat("gear_ratio_%d" % gear) * stats.get_stat("final_drive")

	var mean_spin := 0.0
	for wheel in wheels:
		mean_spin += wheel.spin
	mean_spin /= wheels.size()
	var clutch_rpm := lerpf(idle, stats.get_stat("launch_rpm"), input.throttle)
	rpm = maxf(absf(mean_spin) * ratio * RAD_PER_SEC_TO_RPM, clutch_rpm)

	if rpm >= redline:
		limiter_active = true
	elif rpm < redline - stats.get_stat("limiter_hysteresis_rpm"):
		limiter_active = false

	var engine_torque: float
	if input.throttle > 0.0 and not limiter_active:
		engine_torque = input.throttle * stats.get_stat("max_torque") * torque_curve.sample(rpm / redline)
	else:
		engine_torque = -signf(mean_spin) * stats.get_stat("engine_brake_torque") * rpm / redline
	var split_front := stats.get_stat("torque_split_front")

	# `brake_torque` is the mean per-wheel torque; the bias shifts it between axles.
	var brake := input.brake * stats.get_stat("brake_torque") * 4.0
	var bias_front := stats.get_stat("brake_bias_front")
	var handbrake := input.handbrake * stats.get_stat("handbrake_torque")

	for wheel in wheels:
		var axle_share := split_front if wheel.steerable else 1.0 - split_front
		wheel.drive_torque = engine_torque * ratio * axle_share * 0.5
		if wheel.steerable:
			wheel.brake_torque = brake * bias_front * 0.5
		else:
			wheel.brake_torque = brake * (1.0 - bias_front) * 0.5 + handbrake
