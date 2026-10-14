# Threats

Threats are what damage the car. They are a mix, weighted toward environmental dangers.

## Categories

| Category | Share | Examples |
|---|---|---|
| Environmental | Main source | Rocks, potholes, fallen trees, black ice, rockfall, river crossings, fog, dust storms, whiteouts |
| Wildlife / crowd | Common | Sheep flocks, moose, reindeer, zebras, kangaroos, charging rhino, spectators on the road |
| Rival cars | Regular | Rivals you can ram off the track (defeatable), rivals you must escape from (pursuers) |
| Malfunctions | Regular | A random part suddenly takes damage (tire blowout, brake failure, heater dies, ...) |
| Crazy / hilarious | Escalating | Suicide drones, meteorites, UFO abductions, paparazzi, road trains |

## Escalation tiers

Threats are tiered by how dangerous they are, not by how silly they are.

- **Tier 1 (any difficulty):** harmless or mildly damaging, often funny. Sheep flock, potholes, a single rock, spectators.
- **Tier 2 (mid):** real damage. Fallen trees, rockfall, rival rammers, moose.
- **Tier 3 (late / high difficulty):** dangerous and dramatic. Suicide drones, meteorite showers, pursuer rivals, charging rhinos.

Each threat has a minimum difficulty and a spawn weight. Higher difficulty increases threat count and unlocks higher tiers.

## Defeating threats

Some threats can be defeated: a rival run off the track, a sheep knocked off the road, a drone shot down by a gadget. Defeating threats:
- adds a bonus to the upgrade meter,
- can trigger item effects (see [items.md](items.md)),
- may pay scrap (see [economy.md](economy.md)).

## Determinism

Placement of static threats and the schedule of events (malfunctions) come from the stage seed, so the same seed gives the same threats.

## Country-specific threats

Each country has its own threat set on top of the generic ones. See [world.md](world.md).

## Bosses

Bosses are **critical map conditions**, not classic boss enemies. A boss stage is a stage where the environment itself turns against the player, and surviving to the finish defeats it.

| Country | Boss |
|---|---|
| Finland | Moose stampede: the herd crosses the road in waves |
| Wales | Flood: rising water cuts off low road sections |
| Kenya | Great migration: wildebeest stampede |
| Monte Carlo | Avalanche chasing you downhill |
| Sweden | Frozen lake: the ice cracks behind you |
| Australia | Bushfire: a wall of fire chases you |
| Iceland (final) | Volcanic eruption: lava flows, meteorite shower, suicide drones |
| Area 51 (alt. final) | Alien invasion: UFO abductions, military drones, test-site chaos |

Boss mechanics (phases, how chasing conditions scale, rewards) are not designed yet. See [open-questions.md](open-questions.md).
