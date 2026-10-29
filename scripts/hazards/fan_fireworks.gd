class_name FanFireworks
extends ApproachHazard
## Fans on the verge who fire rockets over the road on approach. The burst flashes the screen
## (`screen_flash` with `strength`) and costs the car `spark_damage` chassis condition if it is
## within `spark_radius` m of the burst point above the road.

signal screen_flash(strength: float)

const PERSON_SCENE := preload("res://scenes/hazards/person.tscn")
const SPARK_COLORS: Array[Color] = [Color(1.0, 0.2, 0.2), Color(0.2, 0.6, 1.0), Color(1.0, 0.9, 0.2), Color(0.3, 1.0, 0.4)]
## Rocket flight time in s, burst height in m and how long the sparks stay visible.
const FLIGHT := 0.6
const BURST_HEIGHT := 4.0
const SPARK_TIME := 0.8

@export var count_range := Vector2i(3, 6)
@export var gap := 2.0
@export var strength := 0.6
@export var spark_radius := 6.0
@export var spark_damage := 3.0
@export var spawn_height := 1.0

var _rockets: Array[MeshInstance3D] = []
var _side := 1.0
var _timer := 0.0
var _burst := false


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	_side = 1.0 if rng.randf() < 0.5 else -1.0
	var to_local := transform.affine_inverse()
	for i in rng.randi_range(count_range.x, count_range.y):
		var along := distance + rng.randf_range(-4.0, 4.0)
		var fan: Person = PERSON_SCENE.instantiate()
		fan.color = SPARK_COLORS[rng.randi_range(0, SPARK_COLORS.size() - 1)]
		fan.position = to_local * (verge_point(along, _side, gap) + Vector3.UP * spawn_height)
		add_child(fan)
	for i in 12:
		var spark := SphereMesh.new()
		spark.radius = 0.25
		spark.height = 0.5
		var material := HazardVisuals.material(SPARK_COLORS[i % SPARK_COLORS.size()])
		material.emission_enabled = true
		material.emission = SPARK_COLORS[i % SPARK_COLORS.size()]
		spark.material = material
		var rocket := MeshInstance3D.new()
		rocket.mesh = spark
		rocket.visible = false
		rocket.position = to_local * verge_point(distance, _side, gap)
		_rockets.append(rocket)
		add_child(rocket)


func _physics_process(delta: float) -> void:
	super(delta)
	if not triggered or _timer > FLIGHT + SPARK_TIME:
		return
	_timer += delta
	var launch := to_local(verge_point(distance, _side, gap))
	var burst := Vector3(0.0, BURST_HEIGHT, 0.0)
	for i in _rockets.size():
		var angle := i * TAU / _rockets.size()
		if _timer < FLIGHT:
			_rockets[i].position = launch.lerp(burst, _timer / FLIGHT)
		else:
			var spread := (_timer - FLIGHT) / SPARK_TIME * 3.0
			_rockets[i].position = burst + Vector3(cos(angle), 0.3 * sin(angle * 2.0), sin(angle)) * spread
	if not _burst and _timer >= FLIGHT:
		_burst = true
		screen_flash.emit(strength)
		if car.global_position.distance_to(to_global(burst)) <= spark_radius:
			car.damage.apply_damage("chassis", spark_damage)
	if _timer > FLIGHT + SPARK_TIME:
		for rocket in _rockets:
			rocket.hide()


func _trigger() -> void:
	for rocket in _rockets:
		rocket.show()
