class_name RoadBuilder
## Builds the drivable road ribbon (mesh and collider) along a `RoadPath`.

const ROAD_COLOR := Color(0.55, 0.5, 0.4)


static func build(path: RoadPath, params: StageParams) -> StaticBody3D:
	var faces := _faces(path, params)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in faces:
		tool.add_vertex(vertex)
	tool.index()
	tool.generate_normals()
	var material := StandardMaterial3D.new()
	material.albedo_color = ROAD_COLOR
	tool.set_material(material)

	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = tool.commit()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape

	var road := StaticBody3D.new()
	road.name = "Road"
	road.set_meta("surface", "gravel")
	road.add_child(mesh)
	road.add_child(collision)
	return road


## Road surface plus a bevel on each side that slopes down to the terrain below the road.
static func _faces(path: RoadPath, params: StageParams) -> PackedVector3Array:
	var samples := path.samples
	var sink := Vector3.DOWN * params.road_sink
	var outer_left := PackedVector3Array()
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	var outer_right := PackedVector3Array()
	for i in samples.size():
		var tangent := samples[mini(i + 1, samples.size() - 1)] - samples[maxi(i - 1, 0)]
		var side := Vector3(tangent.x, 0.0, tangent.z).cross(Vector3.UP).normalized()
		var half := path.widths[i] / 2.0
		outer_left.append(samples[i] - side * (half + params.road_bevel) + sink)
		left.append(samples[i] - side * half)
		right.append(samples[i] + side * half)
		outer_right.append(samples[i] + side * (half + params.road_bevel) + sink)
	var faces := PackedVector3Array()
	_add_strip(faces, outer_left, left)
	_add_strip(faces, left, right)
	_add_strip(faces, right, outer_right)
	return faces


## Two triangles per sample step between a left and a right edge, wound so the faces point up.
static func _add_strip(faces: PackedVector3Array, left: PackedVector3Array, right: PackedVector3Array) -> void:
	for i in left.size() - 1:
		faces.append_array([left[i], left[i + 1], right[i]])
		faces.append_array([right[i], left[i + 1], right[i + 1]])
