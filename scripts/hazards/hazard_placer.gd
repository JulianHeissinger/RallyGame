class_name HazardPlacer
## Seeded hazard placement along the road from the `"hazards"` sub-stream: difficulty gates the
## pool and scales the count, and one hazard sits in each equal slot of the usable road. A slot
## picks among the unlocked hazards that allow the road surface at its position; with none, it
## stays empty.

## Road kept free after the start line and before the finish line, in m.
const START_CLEAR := 50.0
const FINISH_CLEAR := 50.0


## One placed hazard: `distance` along the road and `lateral` offset from the centreline (+ is right).
class Placement:
	var def: HazardDef
	var distance: float
	var lateral: float


static func place(path: RoadPath, stage_seed: int, difficulty: int, params: StageParams) -> Array[Placement]:
	var placements: Array[Placement] = []
	var pool: Array[HazardDef] = []
	for def in params.hazards:
		if def.min_difficulty <= difficulty:
			pool.append(def)
	var from := StageLines.START_LINE_DISTANCE + START_CLEAR
	var to := StageLines.finish_distance(path) - FINISH_CLEAR
	if pool.is_empty() or to <= from:
		return placements
	var scale := 1.0 + params.hazard_difficulty_scale * (difficulty - 1)
	var wanted := roundi(params.hazards_per_km * (to - from) / 1000.0 * scale)
	var count := mini(wanted, floori((to - from) / params.hazard_min_spacing))
	if count <= 0:
		return placements
	var rng := SeedStreams.rng(stage_seed, "hazards")
	var slot := (to - from) / count
	for i in count:
		# Every slot draws the same three values, so an empty slot never shifts the ones after it.
		# Jitter inside the slot keeps half the spacing free at each slot edge.
		var jitter := rng.randf_range(params.hazard_min_spacing / 2.0, slot - params.hazard_min_spacing / 2.0)
		var pick_roll := rng.randf()
		var lateral_roll := rng.randf_range(-1.0, 1.0)
		var distance := from + i * slot + jitter
		var index := clampi(path.distances.bsearch(distance), 0, path.widths.size() - 1)
		var def := _pick(pool, path.section_at(index).road_surface, pick_roll)
		if def == null:
			continue
		var placement := Placement.new()
		placement.def = def
		placement.distance = distance
		if def.on_road:
			placement.lateral = lateral_roll * maxf(path.widths[index] / 2.0 - params.hazard_edge_margin, 0.0)
		placements.append(placement)
	return placements


## Weighted pick by `roll` (0..1) among the defs that allow `surface`; null when none does.
static func _pick(pool: Array[HazardDef], surface: String, roll: float) -> HazardDef:
	var allowed: Array[HazardDef] = []
	var total := 0.0
	for def in pool:
		if def.surfaces.is_empty() or def.surfaces.has(surface):
			allowed.append(def)
			total += def.weight
	var target := roll * total
	for def in allowed:
		target -= def.weight
		if target < 0.0:
			return def
	return allowed.back() if not allowed.is_empty() else null
