extends Node3D
## Generated stage: builds road, terrain and props from a seed, puts the car on the start, and
## returns it to the road when it falls out of the world. Seed and difficulty come from `RunState`.
## Lifecycle: start picks, then a countdown with the car frozen on the start once it has settled,
## then the timer runs until the finish line; rollover and respawn penalties add to it.
## `reroll_stage` starts a new run with a new seed and reloads; `cycle_difficulty` (dev key) does
## the same with the next difficulty 1-2-3.

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
## The car freezes for the countdown once it has dropped onto its wheels: at least this long after
## spawn, all wheels grounded, and vertical speed below `SETTLE_SPEED` m/s. Horizontal speed is not
## checked; on a sloped start the car already rolls by then.
const SETTLE_TIME := 0.3
const SETTLE_SPEED := 0.05

enum State { PICKS, COUNTDOWN, RUNNING, FINISHED }

## 0 takes `RunState.stage_seed`, or rolls a random seed when that is 0 too.
@export var stage_seed := 0
## Empty uses the `StageParams` defaults.
@export var params: StageParams
## Upgrade picks offered before the countdown, for testing items until the run loop exists.
@export var start_picks := 3

## Gates and scales hazards; set from `RunState.difficulty`.
var difficulty := 1

var path: RoadPath
## Hazard placements, built into the "Hazards" node.
var hazards: Array[HazardPlacer.Placement] = []
## Malfunctions by road distance; `_next_malfunction` is the next one to fire.
var malfunctions: Array[MalfunctionSchedule.Malfunction] = []
var finish_distance := 0.0
var state := State.PICKS
var timer := StageTimer.new()

var _params: StageParams
var _countdown_left := 0.0
var _settle_time := 0.0
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
		stage_seed = RunState.stage_seed
	if stage_seed == 0:
		stage_seed = randi_range(1, 999999)
	RunState.stage_seed = stage_seed
	difficulty = RunState.difficulty
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
	_car.rolled_over.connect(timer.add_penalty)
	car_respawned.connect(timer.add_penalty)
	_car.input.blocked = true
	_setup_upgrades()
	if not _pick.visible:
		_start_countdown()


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
	_hud.meter = _meter
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
	RunState.add_item(def)
	print("Picked: " + def.name)
	if _pending_picks > 0:
		_pending_picks -= 1
		_queue_pick()
		return
	Engine.time_scale = 1.0
	if state == State.PICKS:
		_start_countdown()
	else:
		_car.input.blocked = false


func _start_countdown() -> void:
	state = State.COUNTDOWN
	_countdown_left = _params.countdown_time
	_hud.show_notice(str(ceili(_countdown_left)))


## Freezes the car once it has settled, counts down and starts the timer.
func _update_countdown(delta: float) -> void:
	_settle_time += delta
	if not _car.freeze and _settle_time >= SETTLE_TIME and absf(_car.linear_velocity.y) < SETTLE_SPEED \
			and _car.wheels.all(func(wheel: Wheel) -> bool: return wheel.is_grounded):
		_car.freeze = true
	if state != State.COUNTDOWN:
		return
	var shown := ceili(_countdown_left)
	_countdown_left -= delta
	if _countdown_left > 0.0:
		if ceili(_countdown_left) != shown:
			_hud.show_notice(str(ceili(_countdown_left)))
		return
	_car.freeze = false
	_car.input.blocked = false
	state = State.RUNNING
	timer.start()
	_hud.show_notice("Go")


func _physics_process(delta: float) -> void:
	timer.update(delta)
	if state == State.PICKS or state == State.COUNTDOWN:
		_update_countdown(delta)
	_update_malfunctions()


## Fires each scheduled malfunction once, when the car's road progress passes its distance.
func _update_malfunctions() -> void:
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
		RunState.reset(0, difficulty)
		get_tree().reload_current_scene()
	elif event.is_action_pressed("cycle_difficulty"):
		RunState.reset(0, difficulty % MAX_DEV_DIFFICULTY + 1)
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
	if body != _car or state == State.FINISHED:
		return
	if path.progress_at(_car.global_position) < finish_distance - FINISH_PROGRESS_TOLERANCE:
		return
	state = State.FINISHED
	timer.stop()
	car_finished.emit()
