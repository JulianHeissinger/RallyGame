extends "res://tests/test_case.gd"

const DELTA := 1.0 / 60.0


func test_does_not_rotate_when_target_turns() -> void:
	var target := _add(Node3D.new())
	var rig: IsoCameraRig = _add(IsoCameraRig.new())
	rig.target = target
	var initial_basis := rig.camera.global_basis
	var rotated := false
	for i in 600:
		var angle := i * DELTA * 0.5
		target.global_position = Vector3(cos(angle), 0.0, sin(angle)) * 20.0
		rig.follow(DELTA)
		rotated = rotated or not rig.camera.global_basis.is_equal_approx(initial_basis)
	assert_false(rotated, "camera basis unchanged while target circles")
	assert_true(rig.global_position.distance_to(target.global_position) < rig.look_ahead_max + 2.0, "focus stays near target")
	_free(target, rig)


func test_looks_ahead_along_velocity() -> void:
	var target := _add(Node3D.new())
	var rig: IsoCameraRig = _add(IsoCameraRig.new())
	rig.target = target
	for i in 180:
		target.global_position = Vector3(i * DELTA * 10.0, 0.0, 0.0)
		rig.follow(DELTA)
	var offset := rig.global_position - target.global_position
	assert_almost_eq(offset.x, 10.0 * rig.look_ahead_time, 0.5, "focus ahead by velocity * look_ahead_time")
	assert_almost_eq(offset.y, 0.0, 0.001, "no vertical look-ahead")
	_free(target, rig)


func test_keeps_rotation_while_target_spins_on_road() -> void:
	var road := _corner_road()
	var target := _add(Node3D.new())
	target.global_position = road.samples[20]
	var rig: IsoCameraRig = _add(IsoCameraRig.new())
	rig.road = road
	rig.target = target
	rig.follow(DELTA)
	var initial_basis := rig.camera.global_basis
	for i in 300:
		target.rotation.y = i * DELTA * 6.0
		rig.follow(DELTA)
	assert_true(rig.camera.global_basis.is_equal_approx(initial_basis), "spinning target does not turn the camera")
	_free(target, rig)


func test_turns_with_road_through_corner() -> void:
	var road := _corner_road()
	var target := _add(Node3D.new())
	target.global_position = road.samples[0]
	var rig: IsoCameraRig = _add(IsoCameraRig.new())
	rig.road = road
	rig.target = target
	rig.follow(DELTA)
	var start_yaw := rig.rotation.y
	# Drive the whole road at 20 m/s, then hold at the end so the yaw settles.
	for i in road.samples.size() * 6:
		target.global_position = road.curve.sample_baked(minf(i * DELTA * 20.0, road.length))
		rig.follow(DELTA)
	var end := road.samples.size() - 1
	var direction := road.samples[end] - road.samples[end - 10]
	var road_yaw := atan2(-direction.x, -direction.z)
	assert_almost_eq(rad_to_deg(angle_difference(start_yaw, rig.rotation.y)), -90.0, 5.0, "camera turned with the right-hand corner")
	assert_almost_eq(angle_difference(rig.rotation.y, road_yaw), 0.0, deg_to_rad(5.0), "camera looks along the road after the corner")
	_free(target, rig)


## 100 m straight toward -z, a 90 degree right-hand corner (radius 30 m), then 100 m toward +x.
func _corner_road() -> RoadPath:
	var params := StageParams.new()
	params.elevation_amplitude = 0.0
	params.min_crests = 0
	params.crests_per_km = 0.0
	var layout := RoadLayout.new()
	var spacing := params.sample_spacing
	for i in 50:
		layout.points.append(Vector2(0.0, -i * spacing))
	var corner_start := layout.points[-1]
	var center := corner_start + Vector2(30.0, 0.0)
	for i in range(1, 24):
		var angle := PI - i * (PI / 2.0) / 23.0
		layout.points.append(center + Vector2(cos(angle), -sin(angle)) * 30.0)
	var straight_start := layout.points[-1]
	for i in range(1, 51):
		layout.points.append(straight_start + Vector2(i * spacing, 0.0))
	for i in layout.points.size():
		layout.widths.append(8.0)
	layout.length = (layout.points.size() - 1) * spacing
	return RoadPath.build(layout, 1, params)


func _add(node: Node3D) -> Node3D:
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	return node


func _free(a: Node, b: Node) -> void:
	a.free()
	b.free()
