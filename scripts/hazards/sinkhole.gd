class_name Sinkhole
extends ApproachHazard
## A hole that opens in the road on approach, growing to `radius` over `open_time`. A car whose
## centre gets inside the open part falls in: it is put back on the road `RESPAWN_GAP` m past the
## hole and `car_fell` lets the stage add the respawn penalty.

signal car_fell

@export var radius := 2.5
@export var open_time := 1.0

## Respawn distance in m past the hole's far edge.
const RESPAWN_GAP := 5.0

var _open := 0.0

@onready var _hole: Node3D = $Hole


func _ready() -> void:
	_hole.hide()


func _physics_process(delta: float) -> void:
	super(delta)
	if not triggered:
		return
	_open = minf(_open + delta / open_time, 1.0)
	_hole.scale = Vector3(_open * radius, 1.0, _open * radius)
	var local := to_local(car.global_position)
	if Vector2(local.x, local.z).length() < _open * radius:
		car.place(path.transform_at(distance + radius + RESPAWN_GAP).translated(Vector3.UP))
		car_fell.emit()


func _trigger() -> void:
	_hole.show()
