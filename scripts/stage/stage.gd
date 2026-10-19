extends Node3D
## Generated stage: builds road and terrain from a seed, puts the car on the start, and
## returns it to the road when it falls out of the world.

## Emitted when the car fell out of the world and was put back on the road; `penalty` is in seconds.
signal car_respawned(penalty: float)

## Depth in m of the kill plane below the lowest terrain point.
const KILL_DEPTH := 20.0
## Car spawn distance along the road, so the whole car stands on the road.
const START_DISTANCE := 5.0

## 0 picks a random seed.
@export var stage_seed := 0
## Empty uses the `StageParams` defaults.
@export var params: StageParams

var path: RoadPath

var _params: StageParams

@onready var _car: Car = $Car
@onready var _camera: IsoCameraRig = $IsoCameraRig
@onready var _hud: Hud = $Hud
@onready var _debug_overlay: DebugOverlay = $DebugOverlay


func _ready() -> void:
	if stage_seed == 0:
		stage_seed = randi_range(1, 999999)
	print("Stage seed: %d" % stage_seed)
	_params = params if params else StageParams.new()
	path = RoadPath.build(RoadLayout.generate(stage_seed, _params), stage_seed, _params)
	add_child(RoadBuilder.build(path, _params))
	var terrain := TerrainBuilder.build(path, stage_seed, _params)
	add_child(terrain)
	add_child(_build_kill_plane(terrain.get_node("Mesh").get_aabb()))
	_car.road = path
	_car.global_transform = path.transform_at(START_DISTANCE).translated(Vector3.UP)
	_camera.road = path
	_camera.target = _car
	_hud.car = _car
	_debug_overlay.car = _car


## Wide trigger below the terrain; anything falling into it is out of the world.
func _build_kill_plane(terrain_bounds: AABB) -> Area3D:
	var box := BoxShape3D.new()
	box.size = Vector3(terrain_bounds.size.x * 2.0, 10.0, terrain_bounds.size.z * 2.0)
	var collision := CollisionShape3D.new()
	collision.shape = box
	var plane := Area3D.new()
	plane.name = "KillPlane"
	plane.position = terrain_bounds.get_center() * Vector3(1.0, 0.0, 1.0) \
			+ Vector3.UP * (terrain_bounds.position.y - KILL_DEPTH - box.size.y / 2.0)
	plane.add_child(collision)
	plane.body_entered.connect(_on_kill_plane_body_entered)
	return plane


func _on_kill_plane_body_entered(body: Node3D) -> void:
	if body != _car:
		return
	_car.place(path.transform_at(path.progress_at(_car.global_position)).translated(Vector3.UP))
	car_respawned.emit(_params.respawn_penalty)
