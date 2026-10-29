class_name RoadLayout
extends RefCounted
## 2D road centreline from a seed: a chain of straights, arcs and hairpins sampled at fixed spacing.
## x/y map to 3D x/z; the road starts at the origin heading toward -y.

enum SegmentType { STRAIGHT, FAST_ARC, TIGHT_ARC, HAIRPIN }

## Centreline samples, `sample_spacing` apart.
var points := PackedVector2Array()
## Road width at each sample.
var widths := PackedFloat32Array()
## Accepted segments as {type, length, radius, angle}. Angle is signed radians; straights have radius 0.
## A segment cut at the target length keeps its type with a shortened length and angle.
var segments: Array[Dictionary] = []
var length := 0.0

## Spatial hash of point indices, cell size `min_clearance`.
var _grid := {}


## Returns null only if every derived seed fails, which means the params cannot fit.
static func generate(stage_seed: int, params: StageParams) -> RoadLayout:
	for attempt in params.max_regenerations:
		var rng := SeedStreams.rng(stage_seed, "road", attempt)
		var layout := RoadLayout.new()
		if layout._build(rng, params):
			layout._build_widths(rng, params)
			return layout
	push_error("RoadLayout: no layout for seed %d after %d attempts" % [stage_seed, params.max_regenerations])
	return null


func _build(rng: RandomNumberGenerator, params: StageParams) -> bool:
	var spacing := params.sample_spacing
	var target_samples := floori(params.target_length / spacing)
	# Points closer than this along the path are neighbours, not a second pass of the road.
	var window := ceili(2.0 * params.min_clearance / spacing)
	var pos := Vector2.ZERO
	var heading := -PI / 2.0
	# Distance from the last sample to the end of the last segment.
	var carry := 0.0
	var hairpins := 0
	_add_point(Vector2.ZERO, params.min_clearance)
	while points.size() - 1 < target_samples:
		var force_hairpin := hairpins < params.min_hairpins \
				and (points.size() - 1) * spacing >= params.hairpin_force_after * params.target_length
		var accepted := false
		for retry in params.max_segment_retries:
			var type := SegmentType.HAIRPIN if force_hairpin else _pick_type(rng, params)
			var segment := _make_segment(type, rng, params)
			var candidate := _sample(segment, pos, heading, spacing - carry, spacing)
			var room := target_samples - (points.size() - 1)
			var trimmed := candidate.size() > room
			if trimmed:
				candidate.resize(room)
			if not _is_clear(candidate, params.min_clearance, window):
				continue
			for point in candidate:
				_add_point(point, params.min_clearance)
			if trimmed:
				var kept := room * spacing - carry
				segment.angle *= kept / segment.length
				segment.length = kept
			elif type == SegmentType.HAIRPIN:
				hairpins += 1
			segments.append(segment)
			pos = _point_at(segment, pos, heading, segment.length)
			heading += segment.angle
			carry += segment.length - candidate.size() * spacing
			accepted = true
			break
		if not accepted:
			return false
	length = (points.size() - 1) * spacing
	return hairpins >= params.min_hairpins


func _pick_type(rng: RandomNumberGenerator, params: StageParams) -> SegmentType:
	var weights := PackedFloat32Array([
		params.straight_weight, params.fast_arc_weight, params.tight_arc_weight, params.hairpin_weight,
	])
	return rng.rand_weighted(weights) as SegmentType


func _make_segment(type: SegmentType, rng: RandomNumberGenerator, params: StageParams) -> Dictionary:
	var radius_range: Vector2
	var angle_range: Vector2
	match type:
		SegmentType.STRAIGHT:
			var straight := rng.randf_range(params.straight_length.x, params.straight_length.y)
			return {"type": type, "length": straight, "radius": 0.0, "angle": 0.0}
		SegmentType.FAST_ARC:
			radius_range = params.fast_arc_radius
			angle_range = params.fast_arc_angle
		SegmentType.TIGHT_ARC:
			radius_range = params.tight_arc_radius
			angle_range = params.tight_arc_angle
		SegmentType.HAIRPIN:
			radius_range = params.hairpin_radius
			angle_range = params.hairpin_angle
	var radius := rng.randf_range(radius_range.x, radius_range.y)
	var angle := deg_to_rad(rng.randf_range(angle_range.x, angle_range.y))
	if rng.randf() < 0.5:
		angle = -angle
	return {"type": type, "length": radius * absf(angle), "radius": radius, "angle": angle}


## Samples a segment starting at `pos`, from distance `first` on in steps of `spacing`.
func _sample(segment: Dictionary, pos: Vector2, heading: float, first: float, spacing: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	var s := first
	while s <= segment.length:
		result.append(_point_at(segment, pos, heading, s))
		s += spacing
	return result


func _point_at(segment: Dictionary, pos: Vector2, heading: float, s: float) -> Vector2:
	if segment.radius == 0.0:
		return pos + Vector2.from_angle(heading) * s
	var turn := signf(segment.angle)
	var center: Vector2 = pos + Vector2.from_angle(heading + turn * PI / 2.0) * segment.radius
	return center + (pos - center).rotated(turn * s / segment.radius)


## Checks candidate points against accepted points. A single segment turns at most 180 degrees,
## so it cannot come back onto itself and needs no self-check.
func _is_clear(candidate: PackedVector2Array, clearance: float, window: int) -> bool:
	var limit := clearance * clearance
	for i in candidate.size():
		var point := candidate[i]
		var newest_checked := points.size() + i - window
		var cell := _cell(point, clearance)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for j: int in _grid.get(cell + Vector2i(dx, dy), PackedInt32Array()):
					if j <= newest_checked and points[j].distance_squared_to(point) < limit:
						return false
	return true


func _add_point(point: Vector2, clearance: float) -> void:
	var cell := _cell(point, clearance)
	if not _grid.has(cell):
		_grid[cell] = PackedInt32Array()
	_grid[cell].append(points.size())
	points.append(point)


func _cell(point: Vector2, size: float) -> Vector2i:
	return Vector2i(floori(point.x / size), floori(point.y / size))


## Smooth random width between min and max, narrowed by rare pinches.
func _build_widths(rng: RandomNumberGenerator, params: StageParams) -> void:
	var knots := PackedFloat32Array()
	for k in floori(length / params.width_wavelength) + 2:
		knots.append(rng.randf_range(params.road_width_min, params.road_width_max))
	var pinches: Array[Vector2] = []
	for km in ceili(length / 1000.0):
		if rng.randf() < params.pinch_chance_per_km:
			var pinch_length := rng.randf_range(params.pinch_length.x, params.pinch_length.y)
			var start := rng.randf_range(km * 1000.0, minf((km + 1) * 1000.0, length) - pinch_length)
			pinches.append(Vector2(start, start + pinch_length))
	for i in points.size():
		var d := i * params.sample_spacing
		var t := d / params.width_wavelength
		var k := floori(t)
		var width := lerpf(knots[k], knots[k + 1], smoothstep(0.0, 1.0, t - k))
		for pinch in pinches:
			var outside := maxf(pinch.x - d, d - pinch.y)
			width = minf(width, lerpf(params.pinch_width, width, clampf(outside / params.pinch_taper, 0.0, 1.0)))
		widths.append(width)
