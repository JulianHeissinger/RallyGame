class_name PropScatter
## Trees, rocks and fences beside the road: placed as data from the `"props"` sub-stream, then built
## as one `MultiMeshInstance3D` and one `solid` body per type.

enum Type { TREE, ROCK, FENCE }

const TREE_COLOR := Color(0.35, 0.25, 0.15)
const CROWN_COLOR := Color(0.15, 0.35, 0.15)
const ROCK_COLOR := Color(0.45, 0.45, 0.45)
const FENCE_COLOR := Color(0.6, 0.45, 0.3)
const TRUNK_RADIUS := 0.4
const TRUNK_HEIGHT := 6.0
const CROWN_RADIUS := 1.8
const CROWN_HEIGHT := 4.0
## Rocks are spheres sunk this fraction of their radius into the ground.
const ROCK_SINK := 0.4
const FENCE_SIZE := Vector3(4.0, 1.0, 0.15)
## Bucket size in m of the road sample hash used for nearest-road lookups.
const BUCKET := 20.0
## Samples on each side used to measure road curvature at a point.
const CURVATURE_REACH := 5


## One placed prop. `radius` is its footprint around `position`, used for road clearance.
class Prop:
	var type: Type
	var position: Vector2
	var yaw: float
	var scale: float
	var radius: float


static func scatter(path: RoadPath, stage_seed: int, params: StageParams) -> Array[Prop]:
	var rng := SeedStreams.rng(stage_seed, "props")
	var buckets := _buckets(path)
	var reach := params.prop_max_distance + params.road_width_max / 2.0 + params.road_bevel
	var bounds := Rect2(Vector2(path.samples[0].x, path.samples[0].z), Vector2.ZERO)
	for sample in path.samples:
		bounds = bounds.expand(Vector2(sample.x, sample.z))
	bounds = bounds.grow(reach)
	var weights := PackedFloat32Array([params.tree_weight, params.rock_weight, params.fence_weight])
	var props: Array[Prop] = []
	var cell := params.prop_cell
	for j in ceili(bounds.size.y / cell):
		for i in ceili(bounds.size.x / cell):
			# Every cell draws the same values, so a rejected cell never shifts the ones after it.
			var point := bounds.position + Vector2(i + rng.randf(), j + rng.randf()) * cell
			var keep_roll := rng.randf()
			var type := rng.rand_weighted(weights) as Type
			var yaw := rng.randf() * TAU
			var scale_roll := rng.randf()
			var nearest := _nearest(path, buckets, point, reach)
			if nearest.x < 0:
				continue
			var k := int(nearest.x)
			var edge := nearest.y
			var prop := Prop.new()
			prop.type = type
			prop.position = point
			prop.yaw = yaw
			match type:
				Type.TREE:
					prop.scale = lerpf(0.8, 1.3, scale_roll)
					prop.radius = CROWN_RADIUS * prop.scale
				Type.ROCK:
					prop.scale = lerpf(0.6, 1.5, scale_roll)
					prop.radius = prop.scale
				Type.FENCE:
					prop.scale = 1.0
					prop.radius = FENCE_SIZE.x / 2.0
					prop.yaw = _road_yaw(path, k)
			if edge - prop.radius < params.road_bevel + params.prop_road_clearance or edge > params.prop_max_distance:
				continue
			if keep_roll < params.prop_density * (1.0 + _corner_boost(path, k, point, edge, params)):
				props.append(prop)
	return props


static func build(props: Array[Prop], terrain: StaticBody3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Props"
	for type: Type in Type.values():
		var transforms: Array[Transform3D] = []
		var body := StaticBody3D.new()
		body.name = Type.keys()[type].capitalize()
		body.add_to_group("solid")
		for prop in props:
			if prop.type != type:
				continue
			var ground := Vector3(prop.position.x, TerrainBuilder.height_at(terrain, prop.position.x, prop.position.y), prop.position.y)
			var transform := Transform3D(Basis(Vector3.UP, prop.yaw).scaled(Vector3.ONE * prop.scale), ground)
			transforms.append(transform)
			body.add_child(_collider(type, prop, ground))
		root.add_child(_multimesh(type, transforms))
		root.add_child(body)
	return root


## Sample index lists keyed by 2D bucket.
static func _buckets(path: RoadPath) -> Dictionary:
	var buckets := {}
	for k in path.samples.size():
		var key := Vector2i(floori(path.samples[k].x / BUCKET), floori(path.samples[k].z / BUCKET))
		if not buckets.has(key):
			buckets[key] = PackedInt32Array()
		buckets[key].append(k)
	return buckets


## x = index of the sample whose road edge is closest to `point`, y = distance to that edge
## (negative under the road). x = -1 when no sample is within `reach`.
static func _nearest(path: RoadPath, buckets: Dictionary, point: Vector2, reach: float) -> Vector2:
	var best := Vector2(-1.0, INF)
	var r := ceili(reach / BUCKET)
	var home := Vector2i(floori(point.x / BUCKET), floori(point.y / BUCKET))
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var key := home + Vector2i(dx, dz)
			if not buckets.has(key):
				continue
			for k: int in buckets[key]:
				var edge := point.distance_to(Vector2(path.samples[k].x, path.samples[k].z)) - path.widths[k] / 2.0
				if edge < best.y:
					best = Vector2(k, edge)
	return best


## Extra keep chance on the outside of corners: up to `corner_density_boost` at tight radii,
## fading out over `corner_band` m from the road edge.
static func _corner_boost(path: RoadPath, k: int, point: Vector2, edge: float, params: StageParams) -> float:
	var last := path.samples.size() - 1
	var prev := _flat(path.samples[maxi(k - CURVATURE_REACH, 0)])
	var here := _flat(path.samples[k])
	var next := _flat(path.samples[mini(k + CURVATURE_REACH, last)])
	var turn := (here - prev).angle_to(next - here)
	var outside := signf((next - prev).cross(point - here)) != signf(turn)
	if not outside or turn == 0.0:
		return 0.0
	var curvature := absf(turn) / (2.0 * CURVATURE_REACH * params.sample_spacing)
	var tightness := clampf(curvature * params.corner_full_boost_radius, 0.0, 1.0)
	return params.corner_density_boost * tightness * clampf(1.0 - edge / params.corner_band, 0.0, 1.0)


## Yaw that lines a fence's long (x) axis up with the road at sample `k`.
static func _road_yaw(path: RoadPath, k: int) -> float:
	var last := path.samples.size() - 1
	var tangent := _flat(path.samples[mini(k + 1, last)]) - _flat(path.samples[maxi(k - 1, 0)])
	return -tangent.angle()


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func _collider(type: Type, prop: Prop, ground: Vector3) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	match type:
		Type.TREE:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = TRUNK_RADIUS * prop.scale
			cylinder.height = TRUNK_HEIGHT * prop.scale
			collision.shape = cylinder
			collision.position = ground + Vector3.UP * cylinder.height / 2.0
		Type.ROCK:
			var sphere := SphereShape3D.new()
			sphere.radius = prop.scale
			collision.shape = sphere
			collision.position = ground + Vector3.DOWN * ROCK_SINK * prop.scale
		Type.FENCE:
			var box := BoxShape3D.new()
			box.size = FENCE_SIZE
			collision.shape = box
			collision.position = ground + Vector3.UP * FENCE_SIZE.y / 2.0
			collision.rotation.y = prop.yaw
	return collision


static func _multimesh(type: Type, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _mesh(type)
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = Type.keys()[type].capitalize() + "Mesh"
	instance.multimesh = multimesh
	return instance


## Placeholder primitive per type, origin at ground level.
static func _mesh(type: Type) -> Mesh:
	match type:
		Type.TREE:
			var trunk := CylinderMesh.new()
			trunk.top_radius = TRUNK_RADIUS
			trunk.bottom_radius = TRUNK_RADIUS
			trunk.height = TRUNK_HEIGHT
			var crown := CylinderMesh.new()
			crown.top_radius = 0.0
			crown.bottom_radius = CROWN_RADIUS
			crown.height = CROWN_HEIGHT
			var mesh := ArrayMesh.new()
			_append(mesh, trunk, TREE_COLOR, Vector3.UP * TRUNK_HEIGHT / 2.0)
			_append(mesh, crown, CROWN_COLOR, Vector3.UP * (TRUNK_HEIGHT - CROWN_HEIGHT / 4.0))
			return mesh
		Type.ROCK:
			var sphere := SphereMesh.new()
			sphere.radius = 1.0
			sphere.height = 2.0
			var mesh := ArrayMesh.new()
			_append(mesh, sphere, ROCK_COLOR, Vector3.DOWN * ROCK_SINK)
			return mesh
		_:
			var box := BoxMesh.new()
			box.size = FENCE_SIZE
			var mesh := ArrayMesh.new()
			_append(mesh, box, FENCE_COLOR, Vector3.UP * FENCE_SIZE.y / 2.0)
			return mesh


## Adds `source` as a new surface of `mesh`, moved by `offset`, with its own colour.
static func _append(mesh: ArrayMesh, source: PrimitiveMesh, color: Color, offset: Vector3) -> void:
	var tool := SurfaceTool.new()
	tool.append_from(source, 0, Transform3D(Basis.IDENTITY, offset))
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	tool.set_material(material)
	tool.commit(mesh)
