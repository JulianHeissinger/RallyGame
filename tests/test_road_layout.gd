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
