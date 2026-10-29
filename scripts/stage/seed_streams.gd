class_name SeedStreams
## Independent RNG sub-streams per generation step, so changing one step never shifts another.


## `attempt` > 0 gives a derived seed for regenerating a failed step.
static func rng(stage_seed: int, stream: String, attempt: int = 0) -> RandomNumberGenerator:
	var result := RandomNumberGenerator.new()
	result.seed = hash([stage_seed, stream, attempt])
	return result
