extends Node3D
## Flat ground plus a ramp for driving the car in isolation.

@onready var _car: Car = $Car
@onready var _camera: IsoCameraRig = $IsoCameraRig


func _ready() -> void:
	_camera.target = _car
