class_name StageTimer
extends RefCounted
## Stage clock: runs from `start` to `stop` on the time it is fed, with penalties kept apart so the
## finish screen can show them. The shown time is `total`.

var elapsed := 0.0
var penalties := 0.0
var running := false


func start() -> void:
	elapsed = 0.0
	running = true


func stop() -> void:
	running = false


func update(delta: float) -> void:
	if running:
		elapsed += delta


func add_penalty(seconds: float) -> void:
	penalties += seconds


func total() -> float:
	return elapsed + penalties
