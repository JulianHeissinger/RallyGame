class_name Spectator
extends ApproachHazard
## One spectator standing on the road at the placement. On approach they dive to the nearer verge,
## `gap` m past the road edge, fast enough to be clear before the car arrives.

const PERSON_SCENE := preload("res://scenes/hazards/person.tscn")

@export var gap := 2.0
@export var dive_speed := 7.0
## Spawn height in m above the road; the person settles onto it.
@export var spawn_height := 1.0

var _person: Person
var _side := 1.0


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	var road := path.transform_at(distance)
	var lateral := (transform.origin - road.origin).dot(road.basis.x)
	_side = signf(lateral) if absf(lateral) > 0.1 else (1.0 if rng.randf() < 0.5 else -1.0)
	_person = PERSON_SCENE.instantiate()
	_person.position = Vector3.UP * spawn_height
	add_child(_person)


func _trigger() -> void:
	_person.dive_to(verge_point(distance, _side, gap), dive_speed)
