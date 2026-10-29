class_name ExplosiveBarrel
extends Area3D
## A barrel that explodes once when the car touches it: an impulse of `blast_impulse` N·s on the
## car, away from the barrel and tilted up by `lift`, plus impact damage at the barrel's side of
## the car as if hit at `blast_speed`. The barrel has no collider, so the car drives through the
## blast instead of stopping at the barrel; afterwards only its scorch mark stays.

@export var blast_impulse := 7000.0
@export var lift := 1.0
@export var blast_speed := 10.0

var _exploded := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _exploded or not body is Car:
		return
	_exploded = true
	var car := body as Car
	var away := car.global_position - global_position
	away.y = 0.0
	var direction := (away.normalized() + Vector3.UP * lift).normalized()
	car.apply_central_impulse(direction * blast_impulse)
	car.damage.apply_impact(car.stats, car.to_local(global_position), blast_speed, false)
	$Mesh.hide()
	$Scorch.show()
