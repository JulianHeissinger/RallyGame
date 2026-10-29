class_name Strike
extends ApproachHazard
## Meteorite or lightning strike. On approach a `Marker` disc grows to `radius` over `lead_time`
## while an optional `Falling` child drops from `fall_height`, so the strike lands about when the
## car arrives at constant speed. The strike shows `Flash` for `flash_time` and, if the car's
## centre is inside `radius`, pushes it away and up with `blast_impulse` N·s and damages its side
## facing the strike as an impact at `blast_speed`. Each def in `aftermath` (meteorite crater:
## pothole plus fire) is then placed at the strike point.

@export var radius := 4.0
@export var blast_impulse := 6000.0
@export var lift := 1.0
@export var blast_speed := 10.0
@export var fall_height := 40.0
@export var flash_time := 0.3
@export var aftermath: Array[HazardDef] = []

var _rng: RandomNumberGenerator
var _timer := 0.0
var _struck := false

@onready var _marker: Node3D = $Marker
@onready var _flash: Node3D = $Flash
@onready var _falling: Node3D = get_node_or_null("Falling")


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	_rng = rng


func _ready() -> void:
	_marker.hide()
	_flash.hide()
	if _falling:
		_falling.hide()


func _physics_process(delta: float) -> void:
	super(delta)
	if not triggered:
		return
	_timer += delta
	if not _struck:
		var t := minf(_timer / lead_time, 1.0)
		_marker.scale = Vector3(t * radius, 1.0, t * radius)
		if _falling:
			_falling.position.y = fall_height * (1.0 - t)
		if t >= 1.0:
			_strike()
	elif _timer >= lead_time + flash_time:
		_flash.hide()
		set_physics_process(false)


func _trigger() -> void:
	_marker.show()
	if _falling:
		_falling.show()


func _strike() -> void:
	_struck = true
	_marker.hide()
	if _falling:
		_falling.hide()
	_flash.show()
	var away := car.global_position - global_position
	away.y = 0.0
	if away.length() <= radius:
		var direction := (away.normalized() + Vector3.UP * lift).normalized()
		car.apply_central_impulse(direction * blast_impulse)
		car.damage.apply_impact(car.stats, car.to_local(global_position), blast_speed, false)
	for def in aftermath:
		var hazard := def.scene.instantiate() as Node3D
		hazard.transform = transform
		if hazard.has_method("setup"):
			hazard.setup(def, car, path, _rng)
		get_parent().add_child(hazard)
