class_name SpectatorCrowd
extends Node3D
## Roadside spectators standing on `SpectatorPlacer` spots. Only people within `WINDOW` m along the
## road of the car are checked: they cheer while the car passes and flee when it comes at them off
## the road. After a rollover reset a few appear beside the car, push it and walk off.

const PERSON_SCENE := preload("res://scenes/hazards/person.tscn")
const WINDOW := 40.0
const SPAWN_HEIGHT := 1.0
## People within this many m of the car hop.
const CHEER_DISTANCE := 25.0
const CHEER_TIME := 0.5
## An off-road car closer than `FLEE_DISTANCE` m, moving toward a person faster than
## `FLEE_APPROACH` m/s, sends them running `FLEE_RUN` m sideways out of its path.
const FLEE_DISTANCE := 15.0
const FLEE_APPROACH := 3.0
const FLEE_RUN := 8.0
const FLEE_SPEED := 6.0
## Pusher spots around the car in car space, and how long they push before walking off.
const PUSHER_OFFSETS: Array[Vector3] = [Vector3(-1.6, 0.0, 0.0), Vector3(1.6, 0.0, 0.0), Vector3(0.0, 0.0, 2.6)]
const PUSH_TIME := 1.0
const PUSHER_LIFETIME := 3.0
const PUSHER_WALK_OFF := 6.0

var car: Car
var path: RoadPath

var _people: Array[Person] = []
var _distances := PackedFloat32Array()


static func build(spots: Array[SpectatorPlacer.Spot], terrain: StaticBody3D, target: Car, road: RoadPath) -> SpectatorCrowd:
	var crowd := SpectatorCrowd.new()
	crowd.name = "Spectators"
	crowd.car = target
	crowd.path = road
	for spot in spots:
		var person: Person = PERSON_SCENE.instantiate()
		person.color = CrowdSurge.COLORS[spot.color % CrowdSurge.COLORS.size()]
		var ground := TerrainBuilder.height_at(terrain, spot.position.x, spot.position.y)
		person.position = Vector3(spot.position.x, ground + SPAWN_HEIGHT, spot.position.y)
		crowd._people.append(person)
		crowd._distances.append(spot.distance)
		crowd.add_child(person)
	return crowd


func _physics_process(_delta: float) -> void:
	if car == null:
		return
	var progress := path.progress_at(car.global_position)
	var road := path.transform_at(progress)
	var half := path.widths[clampi(path.distances.bsearch(progress), 0, path.widths.size() - 1)] / 2.0
	var off_road := absf((car.global_position - road.origin).dot(road.basis.x)) > half
	var velocity := car.linear_velocity
	velocity.y = 0.0
	for i in range(_distances.bsearch(progress - WINDOW), _distances.bsearch(progress + WINDOW)):
		var person := _people[i]
		var to := person.global_position - car.global_position
		to.y = 0.0
		if to.length() < CHEER_DISTANCE:
			person.cheer(CHEER_TIME)
		if off_road and to.length() < FLEE_DISTANCE and velocity.dot(to.normalized()) > FLEE_APPROACH:
			# Run sideways out of the car's path, to the side the person already stands on.
			var side := to - velocity.normalized() * to.dot(velocity.normalized())
			if side.length() < 0.1:
				side = car.global_basis.x
			person.flee(side, FLEE_RUN, FLEE_SPEED)


## A few spectators push the car back onto its wheels, then walk off and leave.
func push_car() -> void:
	for offset in PUSHER_OFFSETS:
		var person: Person = PERSON_SCENE.instantiate()
		person.color = CrowdSurge.COLORS[_people.size() % CrowdSurge.COLORS.size()]
		add_child(person)
		person.global_position = car.to_global(offset) + Vector3.UP * SPAWN_HEIGHT
		person.add_collision_exception_with(car)
		var away := car.global_basis * offset
		get_tree().create_timer(PUSH_TIME, false, true).timeout.connect(func() -> void:
			if is_instance_valid(person):
				person.flee(away, PUSHER_WALK_OFF, 2.0))
		get_tree().create_timer(PUSHER_LIFETIME, false, true).timeout.connect(func() -> void:
			if is_instance_valid(person):
				person.queue_free())
