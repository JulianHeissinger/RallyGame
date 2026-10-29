class_name UpgradeMeter
extends Node
## Fills from road progress and defeated hazards; emits `filled` each time it passes 1 and keeps
## the overflow. Rates come from `StageParams`, the hazard bonus scale from the car's stats.

signal filled

## From 0 to 1.
var value := 0.0

var _params: StageParams
var _stats: StatBlock
var _car: Node3D
var _path: RoadPath
var _last_progress := 0.0


func setup(params: StageParams, stats: StatBlock) -> void:
	_params = params
	_stats = stats


## Fills from the car's progress along `path` every physics tick.
func track(car: Node3D, path: RoadPath) -> void:
	_car = car
	_path = path
	_last_progress = path.progress_at(car.global_position)


func _physics_process(_delta: float) -> void:
	if _car == null:
		return
	var progress := _path.progress_at(_car.global_position)
	var step := progress - _last_progress
	_last_progress = progress
	if step > 0.0 and step <= _params.upgrade_max_step:
		add_progress(step)


## Adds `distance` m of forward road progress.
func add_progress(distance: float) -> void:
	_add(distance / _params.upgrade_distance)


## Road distance in m still needed to fill the meter, without hazard bonuses.
func distance_left() -> float:
	return (1.0 - value) * _params.upgrade_distance


func add_hazard_bonus() -> void:
	_add(_params.upgrade_hazard_bonus * _stats.get_stat("hazard_bonus_scale"))


func _add(amount: float) -> void:
	value += amount
	while value >= 1.0:
		value -= 1.0
		filled.emit()
