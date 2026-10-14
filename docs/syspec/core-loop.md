# Core Loop

## Run loop

```
 Main menu
   │
   ▼
 Country (random from pool)
   │
   ├─▶ Stage 1 ─▶ Service park ─▶ Stage 2 ─▶ Service park ─▶ ... ─▶ Boss stage
   │                                                                  │
   ▼                                                                  ▼
 Next country ◀───────────────────────────── Service park ◀──────────┘
   │
   ▼
 Final country (Iceland, or Area 51 when unlocked/triggered) ─▶ Final boss ─▶ Run won
```

At any point: car immobilized = run over.

## During a stage

1. Stage is generated from the seed before the start (see [world.md](world.md)).
2. Countdown, then the stage timer starts.
3. The player drives point to point. Threats appear (see [threats.md](threats.md)), parts wear and break (see [vehicle.md](vehicle.md)).
4. Distance driven (plus a bonus for defeating threats) fills the upgrade meter. When full: slow motion, pick 1 of 3 items (see [economy.md](economy.md)).
5. Rollovers cost a time penalty (spectators push the car back).
6. Finish line: stage time determines prize money.

## Between stages

Service park: limited service minutes for repairs, plus a shop paid with prize money and scrap (see [economy.md](economy.md)).

## Game modes

### Campaign
- 3-4 countries picked at random from the pool, then a final country.
- Each country: a few regular stages, then a boss stage.
- Target length: 40-60 minutes per run.
- Rough sizing: 4 countries × 3 stages × 3-4 min + service parks + boss stages ≈ 50 min.
- Two alternative endings (RoR2 Mithrix/Voidling style), one per run. See [world.md](world.md).

### Endless
- Loops through the countries forever with rising difficulty each loop.
- Service parks are kept.
- Ends only when the car is immobilized.

## Fail state

The run ends only when the car becomes immobilized. This should mostly happen through crashes, not through slow wear. There is no stage-timer fail. Details in [vehicle.md](vehicle.md).

## Speed pressure

There is no RoR2-style difficulty clock. Pressure to drive fast comes from prize money: faster stage times pay more, and time penalties (rollovers, respawns) reduce it.

## Difficulty scaling

- Difficulty steps up mainly **between stages**, per country, and per endless loop.
- Within long stages, difficulty may rise slightly with distance driven.
- Difficulty controls: number and density of threats, which threat tiers are unlocked, and boss intensity.
- Harmless silly threats (e.g. a flock of sheep) can appear at any difficulty. Dangerous ones (e.g. suicide drones) unlock later. See [threats.md](threats.md).
