class_name Paparazzi
extends ApproachHazard
## Photographers on the verge on a seeded side. When the car reaches them their flashes white out
## the screen: `screen_flash` with `strength`, which the stage forwards to the HUD.

signal screen_flash(strength: float)

const PERSON_SCENE := preload("res://scenes/hazards/person.tscn")

@export var count_range := Vector2i(2, 4)
@export var spread_along := 6.0
@export var gap := 2.0
@export var strength := 1.0
@export var spawn_height := 1.0


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var to_local := transform.affine_inverse()
	for i in rng.randi_range(count_range.x, count_range.y):
		var along := distance + rng.randf_range(-spread_along, spread_along) / 2.0
		var person: Person = PERSON_SCENE.instantiate()
		person.color = Color(0.1, 0.1, 0.12)
		person.position = to_local * (verge_point(along, side, gap) + Vector3.UP * spawn_height)
		add_child(person)


func _trigger() -> void:
	screen_flash.emit(strength)
