extends "res://tests/test_case.gd"


func test_locked_hazard_never_placed_below_min_difficulty() -> void:
	var params := _params()
	var path := _path(12345, params)
	for difficulty in [1, 2]:
		for placement in HazardPlacer.place(path, 12345, difficulty, params):
			assert_true(placement.def.name != "locked", "locked hazard placed at difficulty %d" % difficulty)
	var names := HazardPlacer.place(path, 12345, 3, params).map(func(p: HazardPlacer.Placement) -> String: return p.def.name)
	assert_true(names.has("locked"), "locked hazard appears at difficulty 3")


func test_more_hazards_at_higher_difficulty() -> void:
	var params := _params()
	var path := _path(12345, params)
	assert_true(HazardPlacer.place(path, 12345, 3, params).size() > HazardPlacer.place(path, 12345, 1, params).size(),
		"difficulty 3 has more hazards than difficulty 1")


func test_same_seed_same_placement() -> void:
	var params := _params()
	var path := _path(12345, params)
	assert_eq(_describe(HazardPlacer.place(path, 12345, 2, params)), _describe(HazardPlacer.place(path, 12345, 2, params)),
		"same seed and difficulty give the same placement")


func test_spacing_and_range() -> void:
	var params := _params()
	for stage_seed in [1, 2, 12345]:
		var path := _path(stage_seed, params)
		var placements := HazardPlacer.place(path, stage_seed, 3, params)
		var from := StageLines.START_LINE_DISTANCE + HazardPlacer.START_CLEAR
		var to := StageLines.finish_distance(path) - HazardPlacer.FINISH_CLEAR
		for i in placements.size():
			var p := placements[i]
			assert_true(p.distance >= from and p.distance <= to, "seed %d hazard %d at %.0f m in range" % [stage_seed, i, p.distance])
			if i > 0:
				assert_true(p.distance - placements[i - 1].distance >= params.hazard_min_spacing - 0.001,
					"seed %d hazards %d and %d spaced" % [stage_seed, i - 1, i])
			if not p.def.on_road:
				assert_eq(p.lateral, 0.0, "off-road hazard on the centreline")


func test_empty_pool_places_nothing() -> void:
	var params := StageParams.new()
	params.hazards = []
	assert_eq(HazardPlacer.place(_path(1, params), 1, 3, params).size(), 0, "no pool, no hazards")


func _params() -> StageParams:
	var params := StageParams.new()
	params.hazards = [_def("rock", 1, true), _def("sheep", 1, false), _def("locked", 3, true)]
	return params


func _def(def_name: String, min_difficulty: int, on_road: bool) -> HazardDef:
	var def := HazardDef.new()
	def.name = def_name
	def.min_difficulty = min_difficulty
	def.on_road = on_road
	return def


func _describe(placements: Array[HazardPlacer.Placement]) -> Array:
	return placements.map(func(p: HazardPlacer.Placement) -> Array: return [p.def.name, p.distance, p.lateral])


func _path(stage_seed: int, params: StageParams) -> RoadPath:
	return RoadPath.build(RoadLayout.generate(stage_seed, params), stage_seed, params)
