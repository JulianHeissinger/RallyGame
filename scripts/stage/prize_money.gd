class_name PrizeMoney
extends RefCounted
## Prize for a finished stage: `prize_base` times par time over final time (penalties included),
## clamped to `MIN_FACTOR`..`MAX_FACTOR`. Par time is `distance / prize_reference_speed`.

const MIN_FACTOR := 0.25
const MAX_FACTOR := 2.0


static func award(distance: float, total_time: float, params: StageParams) -> int:
	var par_time := distance / params.prize_reference_speed
	return roundi(params.prize_base * clampf(par_time / maxf(total_time, 0.001), MIN_FACTOR, MAX_FACTOR))
