class_name MalfunctionSchedule
## Malfunctions scheduled by road distance from the `"events"` sub-stream, so the same seed fires
## the same parts at the same places. Difficulty scales the count like hazards; one malfunction sits
## in each equal slot of the usable road. The chassis never malfunctions.


## One scheduled malfunction: `part` loses `amount` condition when the car passes `distance`.
class Malfunction:
	var distance: float
	var part: String
	var amount: float


static func generate(path: RoadPath, stage_seed: int, difficulty: int, params: StageParams) -> Array[Malfunction]:
	var malfunctions: Array[Malfunction] = []
	var parts := CarDamage.PARTS.filter(func(part: String) -> bool: return part != "chassis")
	var from := StageLines.START_LINE_DISTANCE + HazardPlacer.START_CLEAR
	var to := StageLines.finish_distance(path) - HazardPlacer.FINISH_CLEAR
	if to <= from:
		return malfunctions
	var scale := 1.0 + params.hazard_difficulty_scale * (difficulty - 1)
	var wanted := maxi(roundi(params.malfunctions_per_km * (to - from) / 1000.0 * scale), 1)
	var count := mini(wanted, floori((to - from) / params.malfunction_min_spacing))
	if count <= 0:
		return malfunctions
	var rng := SeedStreams.rng(stage_seed, "events")
	var slot := (to - from) / count
	for i in count:
		var malfunction := Malfunction.new()
		var jitter := rng.randf_range(params.malfunction_min_spacing / 2.0, slot - params.malfunction_min_spacing / 2.0)
		malfunction.distance = from + i * slot + jitter
		malfunction.part = parts[rng.randi_range(0, parts.size() - 1)]
		malfunction.amount = rng.randf_range(params.malfunction_damage.x, params.malfunction_damage.y)
		malfunctions.append(malfunction)
	return malfunctions
