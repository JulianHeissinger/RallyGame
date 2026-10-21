class_name SurfacePatch
extends Node3D
## Flat patch on the road (oil, mud, puddle, ...) that changes the grip and drag of the wheels on
## it; the car asks every registered patch with `contains`. Optional entry effects: a yaw kick
## (banana peel) and engine damage when entered too fast (water crossing). A circle of `radius`,
## or a rectangle when `size` is set (x across, y along the road; x = 0 spans the road). A
## `RoadBumps` child (snow drift) gets the patch width and the section's surface.

@export var radius := 2.0
@export var size := Vector2.ZERO
@export var grip := 1.0
@export var drag := 0.0
@export var color := Color(0.1, 0.1, 0.1)
## Yaw rate in deg/s added once when a wheel enters; the direction comes from the placement RNG.
@export var yaw_kick := 0.0
## Engine damage when the car enters faster than `engine_damage_speed` (m/s).
@export var engine_damage := 0.0
@export var engine_damage_speed := 0.0
## Moves the patch to the outside edge of the local turn (marbles).
@export var outside_of_turn := false

## Patches sit this far above the road surface to avoid z-fighting.
const LIFT := 0.015
## Samples on each side used to find the turn direction for `outside_of_turn`.
const TURN_REACH := 10
## Space in m kept between an outside-of-turn patch and the road edge.
const EDGE_GAP := 0.5

var car: Car

var _kick_sign := 1.0
var _inside := {}


func setup(_def: HazardDef, target: Car, path: RoadPath, rng: RandomNumberGenerator) -> void:
	car = target
	car.patches.append(self)
	_kick_sign = 1.0 if rng.randf() < 0.5 else -1.0
	var distance := path.progress_at(transform.origin)
	var index := clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)
	var half := path.widths[index] / 2.0
	if size != Vector2.ZERO and size.x <= 0.0:
		size.x = path.widths[index]
	for child in get_children():
		if child is RoadBumps:
			child.width = size.x if size != Vector2.ZERO else 2.0 * radius
			child.set_meta("surface", path.section_at(index).road_surface)
	if outside_of_turn:
		var road := path.transform_at(distance)
		var extent := size.x / 2.0 if size != Vector2.ZERO else radius
		transform.origin = road.origin + road.basis.x * _outside_sign(path, index) * maxf(half - extent - EDGE_GAP, 0.0)


func _ready() -> void:
	var mesh: PrimitiveMesh
	if size != Vector2.ZERO:
		var box := BoxMesh.new()
		box.size = Vector3(size.x, 0.01, size.y)
		mesh = box
	else:
		var disc := CylinderMesh.new()
		disc.top_radius = radius
		disc.bottom_radius = radius
		disc.height = 0.01
		mesh = disc
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = Vector3.UP * LIFT
	add_child(visual)


func _exit_tree() -> void:
	if car:
		car.patches.erase(self)


func contains(point: Vector3) -> bool:
	var local := to_local(point)
	if size != Vector2.ZERO:
		return absf(local.x) <= size.x / 2.0 and absf(local.z) <= size.y / 2.0
	return Vector2(local.x, local.z).length() <= radius


## Entry effects, once per wheel entry (yaw kick) or per car entry (engine damage).
func _physics_process(_delta: float) -> void:
	if car == null or (yaw_kick == 0.0 and engine_damage == 0.0):
		return
	var any_before := _inside.values().has(true)
	for wheel in car.wheels:
		var inside := wheel.is_grounded and contains(wheel.contact_point())
		if inside and not _inside.get(wheel, false) and yaw_kick != 0.0:
			car.angular_velocity += car.global_basis.y * deg_to_rad(yaw_kick) * _kick_sign
		_inside[wheel] = inside
	if not any_before and _inside.values().has(true) and engine_damage > 0.0 \
			and car.linear_velocity.length() > engine_damage_speed:
		car.damage.apply_damage("engine", engine_damage)


## +1 when the outside of the turn at sample `index` is on the road's right, -1 on its left.
static func _outside_sign(path: RoadPath, index: int) -> float:
	var last := path.samples.size() - 1
	var prev := path.samples[maxi(index - TURN_REACH, 0)]
	var here := path.samples[index]
	var next := path.samples[mini(index + TURN_REACH, last)]
	var turn := Vector2(here.x - prev.x, here.z - prev.z).angle_to(Vector2(next.x - here.x, next.z - here.z))
	# In x/z, a positive angle turns toward the road's right, so the outside is on the left.
	return -1.0 if turn > 0.0 else 1.0
