extends "res://tests/test_case.gd"

const SEEDS := [1, 2, 3, 12345]


func test_same_seed_identical() -> void:
	var params := StageParams.new()
	var a := RoadLayout.generate(12345, params)
	var b := RoadLayout.generate(12345, params)
	assert_eq(a.points, b.points, "same seed gives the same centreline")
	assert_eq(a.widths, b.widths, "same seed gives the same widths")


func test_different_seeds_differ() -> void:
	var params := StageParams.new()
	assert_true(RoadLayout.generate(1, params).points != RoadLayout.generate(2, params).points, "seeds 1 and 2 differ")


func test_no_self_intersection() -> void:
	var params := StageParams.new()
	for stage_seed in SEEDS:
		var points := RoadLayout.generate(stage_seed, params).points
		assert_false(_self_intersects(points), "seed %d crosses itself" % stage_seed)


func test_hairpin_present() -> void:
	var params := StageParams.new()
	for stage_seed in SEEDS:
		assert_true(_count_hairpins(RoadLayout.generate(stage_seed, params), params) >= 1, "seed %d has a hairpin" % stage_seed)


func test_min_hairpins_forced() -> void:
	var params := StageParams.new()
	params.min_hairpins = 3
	for stage_seed in SEEDS:
		assert_true(_count_hairpins(RoadLayout.generate(stage_seed, params), params) >= 3, "seed %d has 3 hairpins" % stage_seed)


func test_length_within_tolerance() -> void:
	var params := StageParams.new()
	for stage_seed in SEEDS:
		var layout := RoadLayout.generate(stage_seed, params)
		assert_almost_eq(layout.length, params.target_length, params.target_length * 0.01, "seed %d length" % stage_seed)
		assert_eq(layout.widths.size(), layout.points.size(), "one width per sample")


func test_width_range_and_pinch() -> void:
	var params := StageParams.new()
	params.pinch_chance_per_km = 1.0
	var widths := RoadLayout.generate(12345, params).widths
	var narrowest: float = Array(widths).min()
	assert_almost_eq(narrowest, params.pinch_width, 0.01, "a certain pinch reaches pinch width")
	assert_true(Array(widths).max() <= params.road_width_max + 0.001, "width never above max")


func _count_hairpins(layout: RoadLayout, params: StageParams) -> int:
	var count := 0
	for segment in layout.segments:
		if segment.type == RoadLayout.SegmentType.HAIRPIN and absf(segment.angle) >= deg_to_rad(params.hairpin_angle.x):
			count += 1
	return count


func _self_intersects(points: PackedVector2Array) -> bool:
	for i in points.size() - 1:
		for j in range(i + 2, points.size() - 1):
			if Geometry2D.segment_intersects_segment(points[i], points[i + 1], points[j], points[j + 1]) != null:
				return true
	return false


func test_crest_present() -> void:
	var params := StageParams.new()
	for stage_seed in SEEDS:
		var path := _path(stage_seed, params)
		assert_true(path.crests.size() >= 1, "seed %d has a crest" % stage_seed)
		for top in path.crests:
			var rise := _gradient(path, top - 15.0, top - 5.0)
			var fall := _gradient(path, top + 5.0, top + 15.0)
			assert_true(rise - fall >= params.crest_gradient.x, "seed %d crest at %.0f m turns from rise to fall" % [stage_seed, top])


func test_gradient_clamped() -> void:
	var params := StageParams.new()
	for stage_seed in SEEDS:
		var samples := _path(stage_seed, params).samples
		var steepest := 0.0
		for i in range(1, samples.size()):
			var run := Vector2(samples[i].x, samples[i].z).distance_to(Vector2(samples[i - 1].x, samples[i - 1].z))
			steepest = maxf(steepest, absf(samples[i].y - samples[i - 1].y) / run)
		assert_true(steepest <= params.max_gradient + 0.001, "seed %d steepest gradient %.3f" % [stage_seed, steepest])


func test_same_seed_same_heights() -> void:
	var params := StageParams.new()
	assert_eq(_path(12345, params).samples, _path(12345, params).samples, "same seed gives the same 3D road")


func test_progress_at_midpoint() -> void:
	var params := StageParams.new()
	var path := _path(12345, params)
	var mid := path.samples.size() / 2
	var side := (path.samples[mid + 1] - path.samples[mid]).cross(Vector3.UP).normalized() * 2.0
	assert_almost_eq(path.progress_at(path.samples[mid]), path.length / 2.0, path.length * 0.01, "progress on the centreline")
	assert_almost_eq(path.progress_at(path.samples[mid] + side), path.distances[mid], 0.5, "progress 2 m off the centreline")


func test_same_seed_same_sections() -> void:
	var params := StageParams.new()
	var a := _path(12345, params)
	var b := _path(12345, params)
	assert_true(a.section_starts.size() >= 2, "a 2 km stage has several sections")
	assert_eq(a.section_starts, b.section_starts, "same seed gives the same section starts")
	assert_eq(_surfaces(a), _surfaces(b), "same seed gives the same section surfaces")
	assert_true(_path(1, params).section_starts != _path(2, params).section_starts, "seeds 1 and 2 differ")


func test_section_lengths() -> void:
	var params := StageParams.new()
	for stage_seed in SEEDS:
		var path := _path(stage_seed, params)
		var starts := path.section_starts
		assert_eq(starts[0], 0, "seed %d first section starts at the start" % stage_seed)
		for i in starts.size():
			var end := path.length if i + 1 == starts.size() else path.distances[starts[i + 1]]
			var length := end - path.distances[starts[i]]
			var def := path.section_defs[i]
			# Snapping to samples moves a boundary by up to one spacing; the last section may be
			# shorter (but not below the floor) or have a short tail merged into it.
			if i + 1 < starts.size():
				assert_true(length >= def.length.x - params.sample_spacing and length <= def.length.y + params.sample_spacing,
					"seed %d section %d length %.0f m in range" % [stage_seed, i, length])
			else:
				assert_true(length >= params.min_section_length and length <= def.length.y + params.min_section_length,
					"seed %d last section length %.0f m" % [stage_seed, length])
			assert_eq(path.section_at(starts[i]), def, "seed %d section_at start of section %d" % [stage_seed, i])


func _surfaces(path: RoadPath) -> PackedStringArray:
	var names := PackedStringArray()
	for def in path.section_defs:
		names.append(def.road_surface)
	return names


func _path(stage_seed: int, params: StageParams) -> RoadPath:
	return RoadPath.build(RoadLayout.generate(stage_seed, params), stage_seed, params)


## Average gradient between two distances along the road.
func _gradient(path: RoadPath, from: float, to: float) -> float:
	var a := path.curve.sample_baked(from)
	var b := path.curve.sample_baked(to)
	return (b.y - a.y) / Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
