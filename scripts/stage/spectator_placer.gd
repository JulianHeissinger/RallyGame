class_name SpectatorPlacer
## Roadside spectators as data from the `"spectators"` sub-stream: clusters on both sides of the
## start and finish lines, on crests and on the outside of sharp corners, plus a thin spread along
## the road. Every spot keeps `spectator_gap` m from the nearest road edge and stays clear of props.

## Samples on each side used to measure road curvature, as in `PropScatter`.
const CURVATURE_REACH := 5
## Free space in m around a prop's footprint.
const PROP_CLEARANCE := 0.5


## One spectator. `distance` is the road progress of the road point it stands beside.
class Spot:
	var position: Vector2
	var distance: float
	var color: int


static func place(path: RoadPath, stage_seed: int, params: StageParams, props: Array[PropScatter.Prop]) -> Array[Spot]:
	var rng := SeedStreams.rng(stage_seed, "spectators")
	var buckets := PropScatter._buckets(path)
	var spots: Array[Spot] = []
	for site in _sites(path, rng, params):
		var count := rng.randi_range(params.spectator_cluster_size.x, params.spectator_cluster_size.y)
		for i in count:
			var along := site.x + rng.randf_range(-0.5, 0.5) * params.spectator_cluster_spread
			var gap := params.spectator_gap + rng.randf() * params.spectator_depth
			_add(spots, path, buckets, props, params, along, site.y, gap, rng.randi())
	var along := rng.randf_range(params.spectator_spacing.x, params.spectator_spacing.y)
	while along < path.length:
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var gap := params.spectator_gap + rng.randf() * params.spectator_depth
		_add(spots, path, buckets, props, params, along, side, gap, rng.randi())
		along += rng.randf_range(params.spectator_spacing.x, params.spectator_spacing.y)
	spots.sort_custom(func(a: Spot, b: Spot) -> bool: return a.distance < b.distance)
	return spots


## Cluster sites as (road distance, side): start and finish on both sides, crests on a random
## side, and the outside of sharp corners, up to `spectator_clusters_per_km`, spaced along the road.
static func _sites(path: RoadPath, rng: RandomNumberGenerator, params: StageParams) -> Array[Vector2]:
	var sites: Array[Vector2] = []
	for distance in [StageLines.START_LINE_DISTANCE, StageLines.finish_distance(path)]:
		sites.append(Vector2(distance, 1.0))
		sites.append(Vector2(distance, -1.0))
	for crest in path.crests:
		sites.append(Vector2(crest, 1.0 if rng.randf() < 0.5 else -1.0))
	var corners: Array[int] = []
	for k in range(CURVATURE_REACH, path.samples.size() - CURVATURE_REACH, CURVATURE_REACH):
		if _radius(path, k, params) <= params.spectator_corner_radius:
			corners.append(k)
	var wanted := roundi(path.length / 1000.0 * params.spectator_clusters_per_km)
	var placed := 0
	while placed < wanted and not corners.is_empty():
		var k: int = corners.pop_at(rng.randi_range(0, corners.size() - 1))
		var distance := path.distances[k]
		if sites.any(func(site: Vector2) -> bool: return absf(site.x - distance) < params.spectator_cluster_min_spacing):
			continue
		sites.append(Vector2(distance, SurfacePatch._outside_sign(path, k)))
		placed += 1
	return sites


static func _add(spots: Array[Spot], path: RoadPath, buckets: Dictionary, props: Array[PropScatter.Prop],
		params: StageParams, along: float, side: float, gap: float, color: int) -> void:
	along = clampf(along, 0.0, path.length)
	var road := path.transform_at(along)
	var half := path.widths[clampi(path.distances.bsearch(along), 0, path.widths.size() - 1)] / 2.0
	var point3 := road.origin + road.basis.x * side * (half + gap)
	var point := Vector2(point3.x, point3.z)
	# Other parts of the road (hairpins) may pass closer than the one the spot was placed beside.
	if PropScatter._nearest(path, buckets, point, params.spectator_gap).y < params.spectator_gap - 0.01:
		return
	for prop in props:
		if point.distance_to(prop.position) < prop.radius + PROP_CLEARANCE:
			return
	var spot := Spot.new()
	spot.position = point
	spot.distance = along
	spot.color = color
	spots.append(spot)


## Corner radius in m at sample `k`; INF on a straight.
static func _radius(path: RoadPath, k: int, params: StageParams) -> float:
	var prev := path.samples[k - CURVATURE_REACH]
	var here := path.samples[k]
	var next := path.samples[k + CURVATURE_REACH]
	var turn := absf(Vector2(here.x - prev.x, here.z - prev.z).angle_to(Vector2(next.x - here.x, next.z - here.z)))
	return INF if turn == 0.0 else 2.0 * CURVATURE_REACH * params.sample_spacing / turn
