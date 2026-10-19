class_name SheepFlock
extends Node3D
## A flock waiting beside the road. When the car is `lead_time` seconds away along the road at its
## current speed, every sheep crosses to the mirrored spot on the other side, each after its own
## delay, so many are on the road when the car arrives. Layout and timing come from the placement's RNG.

signal hazard_defeated(hazard: Node)

const SHEEP_SCENE := preload("res://scenes/hazards/sheep.tscn")

@export var count_range := Vector2i(40, 100)
## Cluster size in m along the road and outward from the nearest sheep. Sheep stand on distinct
## cells of a `cell` m grid, so they never spawn inside each other.
@export var spread_along := 30.0
@export var spread_side := 10.0
@export var cell := 1.5
## Gap in m between the road edge and the nearest sheep.
@export var side_gap := 1.0
## Seconds before the car arrives at which the crossing starts.
@export var lead_time := 5.0
## Arrival time uses at least this car speed in m/s, so a crawling car still triggers the flock.
@export var min_trigger_speed := 5.0
@export var max_delay := 2.0
@export var walk_speed := Vector2(2.0, 3.0)
## Sheep spawn this far above the road and settle onto the ground.
@export var spawn_height := 0.6

var _car: Car
var _path: RoadPath
var _distance := 0.0
var _started := false
var _sheep: Array[Sheep] = []


## Called by the stage before the flock enters the tree; its `transform` is already set.
func setup(_def: HazardDef, car: Car, path: RoadPath, rng: RandomNumberGenerator) -> void:
	_car = car
	_path = path
	_distance = path.progress_at(transform.origin)
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var to_local := transform.affine_inverse()
	var columns := floori(spread_along / cell)
	var rows := floori(spread_side / cell)
	var cells := range(columns * rows)
	# Seeded Fisher-Yates shuffle; `Array.shuffle` uses the global RNG.
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: int = cells[i]
		cells[i] = cells[j]
		cells[j] = swap
	for i in mini(rng.randi_range(count_range.x, count_range.y), cells.size()):
		var column: int = cells[i] % columns
		var row: int = cells[i] / columns
		var along := _distance - spread_along / 2.0 + (column + rng.randf_range(0.2, 0.8)) * cell
		var road := path.transform_at(along)
		var half := path.widths[clampi(path.distances.bsearch(along), 0, path.widths.size() - 1)] / 2.0
		var out := half + Sheep.OFF_ROAD_MARGIN + side_gap + (row + rng.randf_range(0.2, 0.8)) * cell
		var start := road.origin + road.basis.x * side * out + Vector3.UP * spawn_height
		var sheep: Sheep = SHEEP_SCENE.instantiate()
		sheep.path = path
		sheep.target = road.origin - road.basis.x * side * out
		sheep.start_delay = rng.randf() * max_delay
		sheep.walk_speed = rng.randf_range(walk_speed.x, walk_speed.y)
		sheep.transform = to_local * Transform3D(Basis.looking_at(-road.basis.x * side), start)
		sheep.knocked_off.connect(func(knocked: Sheep) -> void: hazard_defeated.emit(knocked))
		_sheep.append(sheep)
		add_child(sheep)


func _physics_process(_delta: float) -> void:
	if _started or _car == null:
		return
	var remaining := _distance - _path.progress_at(_car.global_position)
	if remaining <= lead_time * maxf(_car.linear_velocity.length(), min_trigger_speed):
		_started = true
		for sheep in _sheep:
			sheep.start()
