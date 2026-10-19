extends Node3D
## Generated stage: builds road, terrain and props from a seed, puts the car on the start, and
## returns it to the road when it falls out of the world. `reroll_stage` reloads the scene, which
## rolls a new seed when the scene's `stage_seed` is 0.

## Emitted when the car fell out of the world and was put back on the road; `penalty` is in seconds.
signal car_respawned(penalty: float)
## Emitted once when the car crosses the finish line.
signal car_finished

## Depth in m of the kill plane below the lowest terrain point.
const KILL_DEPTH := 20.0
## Car spawn distance along the road, so the whole car stands on the road behind the start line.
const START_DISTANCE := 5.0
## The car counts as finished only within this distance in m before the finish line along the road,
## so another road part passing near the finish trigger does not finish the stage.
const FINISH_PROGRESS_TOLERANCE := 5.0

## 0 picks a random seed.
@export var stage_seed := 0
## Empty uses the `StageParams` defaults.
@export var params: StageParams

var path: RoadPath
var finish_distance := 0.0

var _params: StageParams
var _finished := false

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
	_print_sections()
	add_child(RoadBuilder.build(path, _params))
	var lines := StageLines.build(path, _params)
	add_child(lines)
	finish_distance = StageLines.finish_distance(path)
	lines.get_node("FinishArea").body_entered.connect(_on_finish_area_body_entered)
	var terrain := TerrainBuilder.build(path, stage_seed, _params)
	add_child(terrain)
	add_child(PropScatter.build(PropScatter.scatter(path, stage_seed, _params), terrain))
	add_child(_build_kill_plane(terrain.get_node("Mesh").get_aabb()))
	_car.road = path
	_car.global_transform = path.transform_at(START_DISTANCE).translated(Vector3.UP)
	_camera.road = path
	_camera.target = _car
	_hud.car = _car
	_debug_overlay.car = _car


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reroll_stage"):
		get_tree().reload_current_scene()


func _print_sections() -> void:
	var parts := PackedStringArray()
	for i in path.section_starts.size():
		parts.append("%s at %.0f m" % [path.section_defs[i].road_surface, path.distances[path.section_starts[i]]])
	print("Sections: " + ", ".join(parts))


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


func _on_finish_area_body_entered(body: Node3D) -> void:
	if body != _car or _finished:
		return
	if path.progress_at(_car.global_position) < finish_distance - FINISH_PROGRESS_TOLERANCE:
		return
	_finished = true
	car_finished.emit()
