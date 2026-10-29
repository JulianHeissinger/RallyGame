class_name Mascot
extends ApproachHazard
## A team mascot waiting `gap` m beyond the road edge on a seeded side. On approach it runs along
## the verge beside the car, as fast as the car up to `max_speed`, until `chase_length` m past its
## spot. Never on the road.

const PERSON_SCENE := preload("res://scenes/hazards/person.tscn")
## The mascot aims this many m ahead of itself along the road, so it follows the verge.
const AIM_AHEAD := 2.0

@export var gap := 2.0
@export var max_speed := 10.0
@export var chase_length := 60.0
@export var spawn_height := 1.0

var _person: Person
var _side := 1.0
var _done := false


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	_side = 1.0 if rng.randf() < 0.5 else -1.0
	_person = PERSON_SCENE.instantiate()
	_person.color = Color(1.0, 0.85, 0.1)
	_person.head_color = Color(0.9, 0.3, 0.1)
	_person.position = transform.affine_inverse() * (verge_point(distance, _side, gap) + Vector3.UP * spawn_height)
	add_child(_person)


func _physics_process(delta: float) -> void:
	super(delta)
	if not triggered or _done:
		return
	var along := path.progress_at(_person.global_position)
	if along >= distance + chase_length:
		_done = true
		_person.walk_to(_person.global_position, 0.0)
		return
	_person.walk_to(verge_point(along + AIM_AHEAD, _side, gap), minf(car.linear_velocity.length(), max_speed))
