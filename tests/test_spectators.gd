extends "res://tests/test_case.gd"


func test_same_seed_identical() -> void:
	var a := _positions(12345)
	assert_true(a.size() > 0, "spectators are placed")
	assert_eq(a, _positions(12345), "same seed gives the same spectators")


func test_no_spectator_inside_gap() -> void:
	var params := StageParams.new()
	for stage_seed in [1, 12345]:
		var path := _path(stage_seed, params)
		var inside := 0
		for spot in SpectatorPlacer.place(path, stage_seed, params, PropScatter.scatter(path, stage_seed, params)):
			for k in path.samples.size():
				var center := Vector2(path.samples[k].x, path.samples[k].z)
				if spot.position.distance_to(center) < path.widths[k] / 2.0 + params.spectator_gap - 0.01:
					inside += 1
					break
		assert_eq(inside, 0, "seed %d spectators inside the gap" % stage_seed)


func test_clusters_at_crests_and_corners() -> void:
	var params := StageParams.new()
	var path := _path(12345, params)
	var spots := SpectatorPlacer.place(path, 12345, params, PropScatter.scatter(path, 12345, params))
	for crest in path.crests:
		assert_true(_count_near(spots, crest, params.spectator_cluster_spread) >= 3, "cluster at crest %.0f m" % crest)
	var corner_clusters := 0
	for k in range(SpectatorPlacer.CURVATURE_REACH, path.samples.size() - SpectatorPlacer.CURVATURE_REACH, SpectatorPlacer.CURVATURE_REACH):
		if SpectatorPlacer._radius(path, k, params) <= params.spectator_corner_radius \
				and _count_near(spots, path.distances[k], params.spectator_cluster_spread) >= 3:
			corner_clusters += 1
	assert_true(corner_clusters > 0, "clusters at sharp corners")


func _count_near(spots: Array[SpectatorPlacer.Spot], distance: float, spread: float) -> int:
	return spots.filter(func(spot: SpectatorPlacer.Spot) -> bool: return absf(spot.distance - distance) <= spread / 2.0).size()


func _positions(stage_seed: int) -> PackedVector2Array:
	var params := StageParams.new()
	var path := _path(stage_seed, params)
	var positions := PackedVector2Array()
	for spot in SpectatorPlacer.place(path, stage_seed, params, PropScatter.scatter(path, stage_seed, params)):
		positions.append(spot.position)
	return positions


func _path(stage_seed: int, params: StageParams) -> RoadPath:
	return RoadPath.build(RoadLayout.generate(stage_seed, params), stage_seed, params)
