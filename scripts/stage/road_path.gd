class_name RoadPath
extends RefCounted
## 3D road centreline: a `RoadLayout` lifted by noise and crests, with cumulative distance, progress
## and surface sections.

const CREST_END_MARGIN := 100.0
const CREST_SPACING := 150.0
const CREST_PLACE_TRIES := 20

## Centreline samples, same indices as the layout points.
var samples := PackedVector3Array()
## Road width at each sample.
var widths := PackedFloat32Array()
## Cumulative 3D distance from the start at each sample.
var distances := PackedFloat32Array()
## Distance of each crest top.
var crests := PackedFloat32Array()
## First sample index of each surface section, ascending from 0, and the section's surface entry.
var section_starts := PackedInt32Array()
var section_defs: Array[SurfaceSectionDef] = []
var length := 0.0
var curve := Curve3D.new()


static func build(layout: RoadLayout, stage_seed: int, params: StageParams) -> RoadPath:
	var rng := SeedStreams.rng(stage_seed, "elevation")
	var path := RoadPath.new()
	var heights := _base_heights(layout, rng, params)
	var crest_indices := _add_crests(heights, layout, rng, params)
	_clamp_gradient(heights, params.sample_spacing * params.max_gradient)
	path.widths = layout.widths
	path.curve.bake_interval = params.sample_spacing
	for i in layout.points.size():
		var sample := Vector3(layout.points[i].x, heights[i], layout.points[i].y)
		if i > 0:
			path.length += sample.distance_to(path.samples[i - 1])
		path.samples.append(sample)
		path.distances.append(path.length)
		path.curve.add_point(sample)
	for index in crest_indices:
		path.crests.append(path.distances[index])
	_add_sections(path, SeedStreams.rng(stage_seed, "surfaces"), params)
	return path


## Centreline point at `distance`, facing along the road.
func transform_at(distance: float) -> Transform3D:
	var d := clampf(distance, 0.0, length - 1.0)
	var origin := curve.sample_baked(d)
	return Transform3D(Basis.looking_at(curve.sample_baked(d + 1.0) - origin), origin)


## Distance along the road of the closest road point to `position`.
func progress_at(position: Vector3) -> float:
	return curve.get_closest_offset(position)


## Surface section that sample `index` belongs to.
func section_at(index: int) -> SurfaceSectionDef:
	return section_defs[section_starts.bsearch(index, false) - 1]


## Sections back to back from the start, each with a weighted surface and a length from its range,
## snapped to samples. A last section shorter than `min_section_length` merges into the one before.
static func _add_sections(path: RoadPath, rng: RandomNumberGenerator, params: StageParams) -> void:
	var weights := PackedFloat32Array()
	for def in params.surfaces:
		weights.append(def.weight)
	var last := path.samples.size() - 1
	var start := 0.0
	while true:
		var index := mini(path.distances.bsearch(start), last)
		if index == last:
			break
		var def := params.surfaces[rng.rand_weighted(weights)]
		path.section_starts.append(index)
		path.section_defs.append(def)
		start = path.distances[index] + rng.randf_range(def.length.x, def.length.y)
	if path.section_starts.size() > 1 \
			and path.length - path.distances[path.section_starts[-1]] < params.min_section_length:
		path.section_starts.resize(path.section_starts.size() - 1)
		path.section_defs.resize(path.section_defs.size() - 1)


static func _base_heights(layout: RoadLayout, rng: RandomNumberGenerator, params: StageParams) -> PackedFloat32Array:
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.frequency = 1.0 / params.elevation_wavelength
	var heights := PackedFloat32Array()
	for i in layout.points.size():
		heights.append(noise.get_noise_1d(i * params.sample_spacing) * params.elevation_amplitude)
	return heights


## Adds crest profiles to `heights` and returns the sample index of each crest top.
static func _add_crests(heights: PackedFloat32Array, layout: RoadLayout, rng: RandomNumberGenerator,
		params: StageParams) -> PackedInt32Array:
	var spacing := params.sample_spacing
	var count := maxi(params.min_crests, roundi(layout.length / 1000.0 * params.crests_per_km))
	var tops := PackedInt32Array()
	for crest in count:
		for attempt in CREST_PLACE_TRIES:
			var top := roundi(rng.randf_range(CREST_END_MARGIN, layout.length - CREST_END_MARGIN) / spacing)
			if _far_from(tops, top, roundi(CREST_SPACING / spacing)):
				tops.append(top)
				_add_crest(heights, top, rng, params)
				break
	return tops


static func _far_from(tops: PackedInt32Array, index: int, min_gap: int) -> bool:
	for top in tops:
		if absi(top - index) < min_gap:
			return false
	return true


## Linear flanks with a rounded top: soft |u| = sqrt(u² + r²) - r keeps the top smooth.
static func _add_crest(heights: PackedFloat32Array, top: int, rng: RandomNumberGenerator, params: StageParams) -> void:
	var gradient := rng.randf_range(params.crest_gradient.x, params.crest_gradient.y)
	var half := rng.randf_range(params.crest_length.x, params.crest_length.y) / 2.0
	var r := params.crest_top_radius
	var edge := sqrt(half * half + r * r) - r
	var reach := ceili(half / params.sample_spacing)
	for i in range(maxi(top - reach, 0), mini(top + reach + 1, heights.size())):
		var u := (i - top) * params.sample_spacing
		heights[i] += gradient * maxf(0.0, edge - (sqrt(u * u + r * r) - r))


## Limits the height change between neighbouring samples to `max_step`, forward then backward.
static func _clamp_gradient(heights: PackedFloat32Array, max_step: float) -> void:
	for i in range(1, heights.size()):
		heights[i] = clampf(heights[i], heights[i - 1] - max_step, heights[i - 1] + max_step)
	for i in range(heights.size() - 2, -1, -1):
		heights[i] = clampf(heights[i], heights[i + 1] - max_step, heights[i + 1] + max_step)
