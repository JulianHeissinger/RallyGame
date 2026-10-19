class_name TerrainBuilder
## Heightmap terrain around the road: its own noise far away, blended to just below the road near it.
## Bounds walls at the terrain edge keep the car on the generated area.

const COLOR := Color(0.3, 0.5, 0.22)
## Wall height in m above the highest and depth below the lowest terrain point.
const WALL_REACH := 50.0
const WALL_THICKNESS := 2.0
## Blur radius in m and passes for the road height spread beside the road. Where two road parts at
## different heights are close, the nearest one switches abruptly; the blur turns that step into a slope.
const ROAD_HEIGHT_BLUR := 10.0
const ROAD_HEIGHT_BLUR_PASSES := 2
## Distance in m beyond the bevel over which the terrain moves from exact to blurred road height.
const ROAD_HEIGHT_EXACT_BAND := 4.0


static func build(path: RoadPath, stage_seed: int, params: StageParams) -> StaticBody3D:
	var cell := params.terrain_cell
	var bounds := Rect2(Vector2(path.samples[0].x, path.samples[0].z), Vector2.ZERO)
	for sample in path.samples:
		bounds = bounds.expand(Vector2(sample.x, sample.z))
	bounds = bounds.grow(params.terrain_margin)
	var nx := ceili(bounds.size.x / cell) + 1
	var nz := ceili(bounds.size.y / cell) + 1
	var corner := bounds.position
	var heights := _heights(path, SeedStreams.rng(stage_seed, "terrain"), params, corner, nx, nz)

	var terrain := StaticBody3D.new()
	terrain.name = "Terrain"
	terrain.set_meta("surface", "grass")
	terrain.add_child(_mesh(heights, corner, nx, nz, cell))
	terrain.add_child(_collision(heights, corner, nx, nz, cell))
	terrain.add_child(_walls(heights, corner, nx, nz, cell))
	return terrain


static func _heights(path: RoadPath, rng: RandomNumberGenerator, params: StageParams, corner: Vector2,
		nx: int, nz: int) -> PackedFloat32Array:
	var cell := params.terrain_cell
	# Signed distance from the nearest road edge (negative under the road) and that road's height.
	var edge := PackedFloat32Array()
	edge.resize(nx * nz)
	edge.fill(INF)
	var road_y := PackedFloat32Array()
	road_y.resize(nx * nz)
	# Exact distances in a small band around the road, then spread outward.
	for k in path.samples.size():
		var sample := path.samples[k]
		var half := path.widths[k] / 2.0
		var reach := half + params.road_bevel + 2.0 * cell
		var center := Vector2(sample.x, sample.z)
		for j in range(maxi(floori((center.y - reach - corner.y) / cell), 0), mini(ceili((center.y + reach - corner.y) / cell) + 1, nz)):
			for i in range(maxi(floori((center.x - reach - corner.x) / cell), 0), mini(ceili((center.x + reach - corner.x) / cell) + 1, nx)):
				var d := (corner + Vector2(i, j) * cell).distance_to(center) - half
				var index := j * nx + i
				if d < edge[index]:
					edge[index] = d
					road_y[index] = sample.y
	_spread(edge, road_y, nx, nz, cell)
	var smooth_y := road_y.duplicate()
	for blur_pass in ROAD_HEIGHT_BLUR_PASSES:
		_box_blur(smooth_y, nx, nz, roundi(ROAD_HEIGHT_BLUR / cell))

	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.fractal_octaves = 3
	noise.frequency = 1.0 / params.terrain_wavelength
	var heights := PackedFloat32Array()
	heights.resize(nx * nz)
	for j in nz:
		for i in nx:
			var index := j * nx + i
			var point := corner + Vector2(i, j) * cell
			var own := noise.get_noise_2d(point.x, point.y) * params.terrain_amplitude
			var beyond := edge[index] - params.road_bevel
			var near_y := lerpf(road_y[index], smooth_y[index], smoothstep(0.0, ROAD_HEIGHT_EXACT_BAND, beyond))
			heights[index] = lerpf(near_y - params.road_sink, own, smoothstep(0.0, params.terrain_blend, beyond))
	return heights


## Two-pass chamfer distance transform: carries edge distance and road height to every grid point.
static func _spread(edge: PackedFloat32Array, road_y: PackedFloat32Array, nx: int, nz: int, cell: float) -> void:
	var diagonal := cell * sqrt(2.0)
	var forward := [Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(-1, -1, 1), Vector3i(1, -1, 1)]
	var backward := [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 1), Vector3i(-1, 1, 1)]
	for pass_offsets: Array in [forward, backward]:
		var reverse: bool = pass_offsets == backward
		for jj in nz:
			var j := nz - 1 - jj if reverse else jj
			for ii in nx:
				var i := nx - 1 - ii if reverse else ii
				var index := j * nx + i
				for offset: Vector3i in pass_offsets:
					var ni := i + offset.x
					var nj := j + offset.y
					if ni < 0 or ni >= nx or nj < 0 or nj >= nz:
						continue
					var neighbour := nj * nx + ni
					var candidate := edge[neighbour] + (diagonal if offset.z == 1 else cell)
					if candidate < edge[index]:
						edge[index] = candidate
						road_y[index] = road_y[neighbour]


## Box blur with radius `r` cells along rows, then columns, clamped at the grid edges.
static func _box_blur(values: PackedFloat32Array, nx: int, nz: int, r: int) -> void:
	for axis in 2:
		var count := nx if axis == 0 else nz
		var lines := nz if axis == 0 else nx
		var stride := 1 if axis == 0 else nx
		var step_line := nx if axis == 0 else 1
		var line := PackedFloat32Array()
		line.resize(count)
		for l in lines:
			var start := l * step_line
			for i in count:
				line[i] = values[start + i * stride]
			var sum := 0.0
			for i in range(-r, r + 1):
				sum += line[clampi(i, 0, count - 1)]
			for i in count:
				values[start + i * stride] = sum / (2 * r + 1)
				sum += line[mini(i + r + 1, count - 1)] - line[maxi(i - r, 0)]


static func _mesh(heights: PackedFloat32Array, corner: Vector2, nx: int, nz: int, cell: float) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for j in nz:
		for i in nx:
			var point := corner + Vector2(i, j) * cell
			vertices.append(Vector3(point.x, heights[j * nx + i], point.y))
			var dx := heights[j * nx + mini(i + 1, nx - 1)] - heights[j * nx + maxi(i - 1, 0)]
			var dz := heights[mini(j + 1, nz - 1) * nx + i] - heights[maxi(j - 1, 0) * nx + i]
			normals.append(Vector3(-dx, 2.0 * cell, -dz).normalized())
	var indices := PackedInt32Array()
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			var b := a + 1
			var c := a + nx
			var d := c + 1
			indices.append_array([c, a, d, a, b, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_color = COLOR
	mesh.surface_set_material(0, material)
	var instance := MeshInstance3D.new()
	instance.name = "Mesh"
	instance.mesh = mesh
	return instance


## `HeightMapShape3D` has 1 m spacing centred on its node, so the node is scaled by `cell`
## (heights divided to match) and moved to the grid centre.
static func _collision(heights: PackedFloat32Array, corner: Vector2, nx: int, nz: int, cell: float) -> CollisionShape3D:
	var scaled := PackedFloat32Array()
	for h in heights:
		scaled.append(h / cell)
	var shape := HeightMapShape3D.new()
	shape.map_width = nx
	shape.map_depth = nz
	shape.map_data = scaled
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.scale = Vector3.ONE * cell
	collision.position = Vector3(corner.x + (nx - 1) * cell / 2.0, 0.0, corner.y + (nz - 1) * cell / 2.0)
	return collision


static func _walls(heights: PackedFloat32Array, corner: Vector2, nx: int, nz: int, cell: float) -> StaticBody3D:
	var low := Array(heights).min() as float - WALL_REACH
	var high := Array(heights).max() as float + WALL_REACH
	var size := Vector2((nx - 1) * cell, (nz - 1) * cell)
	var center := corner + size / 2.0
	var walls := StaticBody3D.new()
	walls.name = "Bounds"
	for side in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var box := BoxShape3D.new()
		var along_x: bool = side.y != 0.0
		box.size = Vector3(size.x if along_x else WALL_THICKNESS, high - low, WALL_THICKNESS if along_x else size.y)
		var collision := CollisionShape3D.new()
		collision.shape = box
		var offset: Vector2 = side * (size / 2.0 + Vector2.ONE * WALL_THICKNESS / 2.0)
		collision.position = Vector3(center.x + offset.x, (low + high) / 2.0, center.y + offset.y)
		walls.add_child(collision)
	return walls
