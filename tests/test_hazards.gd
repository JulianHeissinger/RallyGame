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


func test_same_seed_same_malfunctions() -> void:
	var params := StageParams.new()
	var path := _path(12345, params)
	var a := _describe_malfunctions(MalfunctionSchedule.generate(path, 12345, 1, params))
	assert_true(a.size() >= 1, "at least one malfunction")
	assert_eq(a, _describe_malfunctions(MalfunctionSchedule.generate(path, 12345, 1, params)),
		"same seed gives the same malfunction distances, parts and amounts")


func test_malfunction_spacing_parts_and_scaling() -> void:
	var params := StageParams.new()
	for stage_seed in [1, 2, 12345]:
		var path := _path(stage_seed, params)
		var from := StageLines.START_LINE_DISTANCE + HazardPlacer.START_CLEAR
		var to := StageLines.finish_distance(path) - HazardPlacer.FINISH_CLEAR
		var malfunctions := MalfunctionSchedule.generate(path, stage_seed, 3, params)
		for i in malfunctions.size():
			var m := malfunctions[i]
			assert_true(m.distance >= from and m.distance <= to, "seed %d malfunction %d in range" % [stage_seed, i])
			assert_true(m.part != "chassis" and CarDamage.PARTS.has(m.part), "seed %d malfunction %d part %s" % [stage_seed, i, m.part])
			assert_true(m.amount >= params.malfunction_damage.x and m.amount <= params.malfunction_damage.y,
				"seed %d malfunction %d amount" % [stage_seed, i])
			if i > 0:
				assert_true(m.distance - malfunctions[i - 1].distance >= params.malfunction_min_spacing - 0.001,
					"seed %d malfunctions %d and %d spaced" % [stage_seed, i - 1, i])
		assert_true(malfunctions.size() >= MalfunctionSchedule.generate(path, stage_seed, 1, params).size(),
			"seed %d difficulty 3 has at least as many malfunctions" % stage_seed)


func test_hud_part_names() -> void:
	assert_eq(Hud.part_name("tire_fl"), "front-left tire", "corner part")
	assert_eq(Hud.part_name("suspension_rr"), "rear-right suspension", "corner part")
	assert_eq(Hud.part_name("engine"), "engine", "single part")


func _describe_malfunctions(malfunctions: Array[MalfunctionSchedule.Malfunction]) -> Array:
	return malfunctions.map(func(m: MalfunctionSchedule.Malfunction) -> Array: return [m.distance, m.part, m.amount])


func test_surface_gated_hazards_only_on_allowed_sections() -> void:
	var params := StageParams.new()
	var snow_only := _def("snow_only", 1, true)
	snow_only.surfaces = PackedStringArray(["snow"])
	params.hazards = [snow_only, _def("anywhere", 1, true)]
	var seen_snow_only := false
	for stage_seed in [1, 2, 3, 12345]:
		var path := _path(stage_seed, params)
		for p in HazardPlacer.place(path, stage_seed, 1, params):
			if p.def == snow_only:
				seen_snow_only = true
				var index := clampi(path.distances.bsearch(p.distance), 0, path.widths.size() - 1)
				assert_eq(path.section_at(index).road_surface, "snow", "seed %d snow-only hazard on snow" % stage_seed)
	assert_true(seen_snow_only, "snow-only hazard placed somewhere")


func test_surface_gated_hazard_without_allowed_section_never_placed() -> void:
	var params := StageParams.new()
	var lava_only := _def("lava_only", 1, true)
	lava_only.surfaces = PackedStringArray(["lava"])
	params.hazards = [lava_only]
	assert_eq(HazardPlacer.place(_path(1, params), 1, 1, params).size(), 0, "no lava sections, no hazards")


func test_patch_contains_circle_and_rectangle() -> void:
	var root := (Engine.get_main_loop() as SceneTree).root
	var circle := SurfacePatch.new()
	circle.radius = 2.0
	var rect := SurfacePatch.new()
	rect.size = Vector2(4.0, 10.0)
	rect.rotation.y = PI / 2.0
	root.add_child(circle)
	root.add_child(rect)
	assert_true(circle.contains(Vector3(1.9, 0.0, 0.0)), "inside circle")
	assert_false(circle.contains(Vector3(1.5, 0.0, 1.5)), "outside circle")
	# Rotated 90°: the 10 m length now runs along world x.
	assert_true(rect.contains(Vector3(4.5, 0.0, 1.5)), "inside rotated rectangle")
	assert_false(rect.contains(Vector3(1.0, 0.0, 2.5)), "outside rotated rectangle")
	circle.free()
	rect.free()


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
