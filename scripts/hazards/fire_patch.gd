class_name FirePatch
extends Node3D
## Burning ground of `radius` (fire patch, burning crashed car, meteorite crater). Every second
## on it costs each grounded wheel inside its def's `tire` damage and the car its `engine` damage
## while the car's centre is inside; car speed does not matter. Flames flicker on top.

@export var radius := 2.5
@export var flame_count := 8

const GROUND := Color(0.15, 0.08, 0.04)
const FLAME := Color(1.0, 0.45, 0.05)
const FLAME_HEIGHT := 1.2
## Flicker frequency in Hz and the flame height it swings by, as a share.
const FLICKER_RATE := 6.0
const FLICKER_AMOUNT := 0.35

var def: HazardDef
var car: Car

var _flames: Array[MeshInstance3D] = []
var _time := 0.0


func setup(hazard_def: HazardDef, target: Car, _path: RoadPath, _rng: RandomNumberGenerator) -> void:
	def = hazard_def
	car = target


func _ready() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.01
	disc.material = HazardVisuals.material(GROUND)
	var ground := MeshInstance3D.new()
	ground.mesh = disc
	ground.position = Vector3.UP * 0.02
	add_child(ground)
	var flame_material := HazardVisuals.material(FLAME)
	flame_material.emission_enabled = true
	flame_material.emission = FLAME
	# Flames on a golden-angle spiral cover the disc evenly without an RNG.
	for i in flame_count:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.35
		cone.height = FLAME_HEIGHT
		cone.material = flame_material
		var flame := MeshInstance3D.new()
		flame.mesh = cone
		var r := radius * 0.85 * sqrt((i + 0.5) / flame_count)
		var angle := i * 2.39996
		flame.position = Vector3(cos(angle) * r, FLAME_HEIGHT / 2.0, sin(angle) * r)
		add_child(flame)
		_flames.append(flame)


func _process(delta: float) -> void:
	_time += delta
	for i in _flames.size():
		_flames[i].scale.y = 1.0 + FLICKER_AMOUNT * sin(_time * TAU * FLICKER_RATE + i * 1.7)


func _physics_process(delta: float) -> void:
	if car == null:
		return
	for wheel in car.wheels:
		if wheel.is_grounded and _contains(wheel.global_position):
			var corner := wheel.name.trim_prefix("Wheel").to_lower()
			car.damage.apply_damage("tire_" + corner, def.damage.get("tire", 0.0) * delta)
	if _contains(car.global_position):
		car.damage.apply_damage("engine", def.damage.get("engine", 0.0) * delta)


func _contains(point: Vector3) -> bool:
	var local := to_local(point)
	return Vector2(local.x, local.z).length() <= radius
