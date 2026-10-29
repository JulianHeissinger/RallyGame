extends Node3D
## Generated stage: builds road, terrain and props from a seed, puts the car on the start, and
## returns it to the road when it falls out of the world. `reroll_stage` reloads the scene, which
## rolls a new seed when the scene's `stage_seed` is 0; `cycle_difficulty` (dev key) steps the
## difficulty 1-2-3 and reloads the same way.

## Emitted when the car fell out of the world and was put back on the road; `penalty` is in seconds.
signal car_respawned(penalty: float)
## Emitted once when the car crosses the finish line.
signal car_finished
## Emitted when the car defeats a hazard, e.g. knocks a sheep off the road.
signal hazard_defeated(hazard: Node)
## Emitted when a scheduled malfunction damages a part of the car.
signal malfunction(part: String, amount: float)

## Depth in m of the kill plane below the lowest terrain point.
const KILL_DEPTH := 20.0
## Car spawn distance along the road, so the whole car stands on the road behind the start line.
const START_DISTANCE := 5.0
## The car counts as finished only within this distance in m before the finish line along the road,
## so another road part passing near the finish trigger does not finish the stage.
const FINISH_PROGRESS_TOLERANCE := 5.0
const MAX_DEV_DIFFICULTY := 3

## 0 picks a random seed.
@export var stage_seed := 0
## Empty uses the `StageParams` defaults.
@export var params: StageParams
## Gates and scales hazards. `RunState` sets it once it exists (task 8.1).
@export var difficulty := 1
## Upgrade picks offered right after spawn, for testing items until the run loop exists.
@export var start_picks := 3

## Difficulty chosen with the dev key; survives scene reloads. 0 keeps the exported `difficulty`.
static var _dev_difficulty := 0

var path: RoadPath
## Hazard placements, built into the "Hazards" node.
var hazards: Array[HazardPlacer.Placement] = []
## Malfunctions by road distance; `_next_malfunction` is the next one to fire.
var malfunctions: Array[MalfunctionSchedule.Malfunction] = []
var finish_distance := 0.0

var _params: StageParams
var _finished := false
var _next_malfunction := 0
var _item_pool: Array[ItemDef] = []
var _upgrade_rng: RandomNumberGenerator
## Picks still to show after the open one; the meter can fill again during a pick.
var _pending_picks := 0
var _meter := UpgradeMeter.new()
var _pick := UpgradePick.new()

@onready var _car: Car = $Car
@onready var _camera: IsoCameraRig = $IsoCameraRig
@onready var _hud: Hud = $Hud
@onready var _debug_overlay: DebugOverlay = $DebugOverlay


func _ready() -> void:
	if stage_seed == 0:
		stage_seed = randi_range(1, 999999)
	if _dev_difficulty > 0:
		difficulty = _dev_difficulty
	print("Stage seed: %d, difficulty %d" % [stage_seed, difficulty])
	_params = params if params else StageParams.new()
	path = RoadPath.build(RoadLayout.generate(stage_seed, _params), stage_seed, _params)
	_print_sections()
	hazards = HazardPlacer.place(path, stage_seed, difficulty, _params)
	malfunctions = MalfunctionSchedule.generate(path, stage_seed, difficulty, _params)
	add_child(RoadBuilder.build(path, _params))
	var lines := StageLines.build(path, _params)
	add_child(lines)
	finish_distance = StageLines.finish_distance(path)
	lines.get_node("FinishArea").body_entered.connect(_on_finish_area_body_entered)
	var terrain := TerrainBuilder.build(path, stage_seed, _params)
	add_child(terrain)
	var props := PropScatter.scatter(path, stage_seed, _params)
	add_child(PropScatter.build(props, terrain))
	var crowd := SpectatorCrowd.build(SpectatorPlacer.place(path, stage_seed, _params, props), terrain, _car, path)
	add_child(crowd)
	_car.rolled_over.connect(func(_penalty: float) -> void: crowd.push_car())
	add_child(_build_hazards())
	add_child(_build_kill_plane(terrain.get_node("Mesh").get_aabb()))
	_car.road = path
	_car.global_transform = path.transform_at(START_DISTANCE).translated(Vector3.UP)
	_camera.road = path
	_camera.target = _car
	_hud.car = _car
	malfunction.connect(_hud.show_malfunction)
	hazard_defeated.connect(func(hazard: Node) -> void: _car.items.on_event("hazard_defeated", {"hazard": hazard}))
	_debug_overlay.car = _car
	_setup_upgrades()


func _exit_tree() -> void:
	# A reload or quit during a pick must not leave the next scene in slow motion.
	Engine.time_scale = 1.0


## Upgrade meter and pick: offers come from the whole item pool through a stream of the stage seed.
func _setup_upgrades() -> void:
	_item_pool = ItemPool.load_all()
	_upgrade_rng = SeedStreams.rng(stage_seed, "upgrades")
	_meter.name = "UpgradeMeter"
	_meter.setup(_params, _car.stats)
	_meter.track(_car, path)
	add_child(_meter)
	_pick.name = "UpgradePick"
	add_child(_pick)
	_meter.filled.connect(_queue_pick)
	hazard_defeated.connect(func(_hazard: Node) -> void: _meter.add_hazard_bonus())
	_pick.picked.connect(_on_picked)
	for i in start_picks:
		_queue_pick()


func _queue_pick() -> void:
	if _pick.visible:
		_pending_picks += 1
		return
	_pick.open(ItemPool.offer(_item_pool, _car.items, _upgrade_rng, _params.upgrade_offer_count), _car.items,
			_params.upgrade_pick_time)
	_car.input.blocked = true
	Engine.time_scale = _params.upgrade_time_scale


func _on_picked(def: ItemDef) -> void:
	_car.items.add_item(def)
	print("Picked: " + def.name)
	if _pending_picks > 0:
		_pending_picks -= 1
		_queue_pick()
		return
	_car.input.blocked = false
	Engine.time_scale = 1.0


## Fires each scheduled malfunction once, when the car's road progress passes its distance.
func _physics_process(_delta: float) -> void:
	if _next_malfunction >= malfunctions.size():
		return
	var next := malfunctions[_next_malfunction]
	if path.progress_at(_car.global_position) < next.distance:
		return
	_next_malfunction += 1
	_car.damage.apply_damage(next.part, next.amount)
	malfunction.emit(next.part, next.amount)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reroll_stage"):
		get_tree().reload_current_scene()
	elif event.is_action_pressed("cycle_difficulty"):
		_dev_difficulty = difficulty % MAX_DEV_DIFFICULTY + 1
		get_tree().reload_current_scene()


func _print_sections() -> void:
	var parts := PackedStringArray()
	for i in path.section_starts.size():
		parts.append("%s at %.0f m" % [path.section_defs[i].road_surface, path.distances[path.section_starts[i]]])
	print("Sections: " + ", ".join(parts))


## One scene per placement, on the road at its distance and lateral offset. Hazards with a `setup`
## method get their def, the car, the road and their own seeded RNG; their `hazard_defeated` is
## forwarded, their `car_fell` (sinkhole) becomes a respawn penalty and their `screen_flash` goes
## to the HUD.
func _build_hazards() -> Node3D:
	var root := Node3D.new()
	root.name = "Hazards"
	for i in hazards.size():
		var placement := hazards[i]
		var hazard := placement.def.scene.instantiate() as Node3D
		hazard.transform = path.transform_at(placement.distance).translated_local(Vector3.RIGHT * placement.lateral)
		if hazard.has_method("setup"):
			hazard.setup(placement.def, _car, path, SeedStreams.rng(stage_seed, "hazard_%d" % i))
		if hazard.has_signal("hazard_defeated"):
			hazard.hazard_defeated.connect(hazard_defeated.emit)
		if hazard.has_signal("car_fell"):
			hazard.car_fell.connect(func() -> void: car_respawned.emit(_params.respawn_penalty))
		if hazard.has_signal("screen_flash"):
			hazard.screen_flash.connect(_hud.flash)
		root.add_child(hazard)
		var sign_node := _build_sign(placement)
		sign_node.name = "Sign%d" % i
		root.add_child(sign_node)
	return root


## Warning sign naming the hazard, beside the road on the right, `SIGN_DISTANCE` before it.
func _build_sign(placement: HazardPlacer.Placement) -> Node3D:
	var distance := maxf(placement.distance - HazardVisuals.SIGN_DISTANCE, 0.0)
	var index := clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)
	var offset := path.widths[index] / 2.0 + _params.road_bevel + HazardVisuals.SIGN_OFFSET
	var sign_node := HazardVisuals.warning_sign(placement.def.sign_text)
	var road := path.transform_at(distance)
	sign_node.transform = Transform3D(road.basis, road.origin + road.basis.x * offset + Vector3.DOWN * _params.road_sink)
	return sign_node


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
