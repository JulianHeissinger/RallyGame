extends Node3D
## Flat ground plus a ramp for driving the car in isolation.

@onready var _car: Car = $Car
@onready var _camera: IsoCameraRig = $IsoCameraRig
@onready var _hud: Hud = $Hud
@onready var _debug_overlay: DebugOverlay = $DebugOverlay


func _ready() -> void:
	_camera.target = _car
	_hud.car = _car
	_debug_overlay.car = _car
