class_name RoadBuilder
## Builds the drivable road ribbon (mesh and collider) along a `RoadPath`, one body per surface section.


## Node "Road" with one `StaticBody3D` per section, named "Section<i>", carrying its `surface` metadata.
static func build(path: RoadPath, params: StageParams) -> Node3D:
	var road := Node3D.new()
	road.name = "Road"
	var last := path.samples.size() - 1
	for i in path.section_starts.size():
		var to := path.section_starts[i + 1] if i + 1 < path.section_starts.size() else last
		road.add_child(_section(path, params, i, path.section_starts[i], to))
	return road


## Road from sample `from` to sample `to`; neighbouring sections share their boundary sample.
static func _section(path: RoadPath, params: StageParams, index: int, from: int, to: int) -> StaticBody3D:
	var surface := path.section_defs[index].road_surface
	var faces := _faces(path, params, from, to)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in faces:
		tool.add_vertex(vertex)
	tool.index()
	tool.generate_normals()
	var material := StandardMaterial3D.new()
	material.albedo_color = Surface.COLOR[surface]
	tool.set_material(material)

	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = tool.commit()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape

	var body := StaticBody3D.new()
	body.name = "Section%d" % index
	body.set_meta("surface", surface)
	body.add_child(mesh)
	body.add_child(collision)
	return body


## Road surface plus a bevel on each side that slopes down to the terrain below the road.
static func _faces(path: RoadPath, params: StageParams, from: int, to: int) -> PackedVector3Array:
	var samples := path.samples
	var sink := Vector3.DOWN * params.road_sink
	var outer_left := PackedVector3Array()
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	var outer_right := PackedVector3Array()
	for i in range(from, to + 1):
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
