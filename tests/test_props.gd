extends "res://tests/test_case.gd"


func test_same_seed_identical() -> void:
	var a := _positions(12345)
	assert_true(a.size() > 0, "props are placed")
	assert_eq(a, _positions(12345), "same seed gives the same props")


func test_different_seeds_differ() -> void:
	assert_true(_positions(1) != _positions(2), "seeds 1 and 2 differ")


func test_no_prop_overlaps_road() -> void:
	var params := StageParams.new()
	for stage_seed in [1, 12345]:
		var path := _path(stage_seed, params)
		var overlaps := 0
		for prop in PropScatter.scatter(path, stage_seed, params):
			for k in path.samples.size():
				var center := Vector2(path.samples[k].x, path.samples[k].z)
				if prop.position.distance_to(center) < path.widths[k] / 2.0 + params.road_bevel + prop.radius:
					overlaps += 1
					break
		assert_eq(overlaps, 0, "seed %d props overlapping the road" % stage_seed)


func _positions(stage_seed: int) -> PackedVector2Array:
	var params := StageParams.new()
	var positions := PackedVector2Array()
	for prop in PropScatter.scatter(_path(stage_seed, params), stage_seed, params):
		positions.append(prop.position)
	return positions


func _path(stage_seed: int, params: StageParams) -> RoadPath:
	return RoadPath.build(RoadLayout.generate(stage_seed, params), stage_seed, params)
