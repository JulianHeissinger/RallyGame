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


func _add(node: Node3D) -> Node3D:
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	return node


func _free(a: Node, b: Node) -> void:
	a.free()
	b.free()
