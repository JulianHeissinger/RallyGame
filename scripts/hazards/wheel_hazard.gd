class_name WheelHazard
extends Node3D
## Damages the parts of each wheel that drives over it, once per entry: every `damage` group of
## its def on that wheel's corner, scaled by car speed between the def's `min_speed` and `full_speed`.

## Footprint radius in m around the node origin.
@export var radius := 0.5

var def: HazardDef
var car: Car

var _inside := {}


func setup(hazard_def: HazardDef, target: Car, _path: RoadPath, _rng: RandomNumberGenerator) -> void:
	def = hazard_def
	car = target


func _physics_process(_delta: float) -> void:
	if car == null:
		return
	var scale := clampf((car.linear_velocity.length() - def.min_speed) / (def.full_speed - def.min_speed), 0.0, 1.0)
	for wheel in car.wheels:
		var offset := wheel.global_position - global_position
		var inside := wheel.is_grounded and Vector2(offset.x, offset.z).length() < radius
		if inside and not _inside.get(wheel, false) and scale > 0.0:
			var corner := wheel.name.trim_prefix("Wheel").to_lower()
			for group: String in def.damage:
				car.damage.apply_damage(group + "_" + corner, def.damage[group] * scale)
		_inside[wheel] = inside
