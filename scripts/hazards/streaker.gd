class_name Streaker
extends ApproachHazard
## A streaker on the road who, on approach, runs ahead along the road. When the car would catch
## them within `dive_time` seconds, or after `run_length` m, they dive off to the nearer verge.

const PERSON_SCENE := preload("res://scenes/hazards/person.tscn")
## Look-ahead in m along the road of the running target.
const RUN_AHEAD := 5.0

@export var run_speed := 7.0
@export var run_length := 40.0
@export var dive_time := 1.2
@export var dive_speed := 7.0
@export var gap := 2.0
@export var spawn_height := 1.0

var _person: Person
var _lateral := 0.0
var _dived := false


func _setup(_def: HazardDef, _rng: RandomNumberGenerator) -> void:
	var road := path.transform_at(distance)
	_lateral = (transform.origin - road.origin).dot(road.basis.x)
	_person = PERSON_SCENE.instantiate()
	_person.color = Color(0.95, 0.7, 0.6)
	_person.position = Vector3.UP * spawn_height
	add_child(_person)


func _physics_process(delta: float) -> void:
	super(delta)
	if not triggered or _dived:
		return
	var along := path.progress_at(_person.global_position)
	var closing := car.linear_velocity.length() - run_speed
	var catch_time := (along - path.progress_at(car.global_position)) / closing if closing > 0.0 else INF
	if catch_time <= dive_time or along >= distance + run_length:
		_dived = true
		var side := signf(_lateral) if _lateral != 0.0 else 1.0
		_person.dive_to(verge_point(along, side, gap), dive_speed)
		return
	var road := path.transform_at(along + RUN_AHEAD)
	_person.walk_to(road.origin + road.basis.x * _lateral, run_speed)
