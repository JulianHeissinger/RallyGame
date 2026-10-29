# Roadmap

Technical work deferred past the vertical slice (`openspec/changes/bootstrap-vertical-slice`), plus slice tasks moved to a later point. Each entry says what triggers it.

## Multiple cars

Car tuning is data-driven: every value lives in a `CarStats` resource (`data/cars/*.tres`), and `Car`, `Wheel`, `Drivetrain` and `Gearbox` hold no shared state. A new car is a new `.tres` plus an inherited scene of `scenes/car.tscn` for its geometry.

To do when a second car or an AI/rival car is planned:

- **Input injection.** `Car` creates `InputSource.new()` itself, which reads keyboard and joypad 0. AI, rival and ghost cars need an `InputSource` subclass assigned from outside (e.g. an exported or spawner-set input), so the car never reads the player's devices.
- **Wheel mesh size.** The wheel meshes in `car.tscn` are sized by hand and not tied to the `wheel_radius` stat. Derive the mesh scale from the stat, or check it in a test, so a car with different wheels cannot drift out of sync.

Known limits, fine until a car needs them:

- **Geometry lives in the scene.** Wheelbase, track width and the collision box are node transforms in the car scene, not stats. They affect handling as much as the stats do, so tuning a car means editing both files.
- **Axle role comes from `steerable`.** `Drivetrain` picks the front axle for torque split and brake bias by the wheel's `steerable` flag. Rear-wheel steering would need a separate axle flag.
- **Gearbox mode is global.** `Settings.gearbox_mode` is one setting for all cars. Split-screen or per-car modes would need it per player.

## Countries

Road layout tuning is data-driven: `StageParams` holds the segment table (pick weights, length, radius and angle ranges), hairpin minimum, width range and pinch frequency. The slice uses only the defaults in code.

To do when countries are planned: one `StageParams` `.tres` per country (e.g. Monte Carlo with a high hairpin weight, tight radii, a higher `min_hairpins` and narrow roads), chosen by the run's current country.

## Handling tuning on a real track

Task 3.8a fixed the structural handling issues in the flat test scene. Task 3.8 (the tuning pass) waited for stage generation (section 5) to give a real track. A first pass on the generated stage (keyboard) is done; 3.8 stays unchecked until its checklist (flick, handbrake hairpin, manual shifting, controller) is worked through.

First pass, values now in `prototype.tres` and code:

- **Tire curve:** `tire_lat_b` 10 → 16, `tire_lat_c` 1.3 → 1.6. The old curve peaked at about 15° slip and stayed flat past it, so full keyboard lock overslipped the front and the yaw oscillated.
- **Grip:** `tire_friction` 1.0 → 1.5 (about 1.3 g cornering on gravel). Surface grip: grass 0.8, snow 0.75, ice 0.4.
- **Steering:** `min_steer_angle_deg` 14 → 8, `steer_reduction_speed` 25 → 22. Keyboard ramp in `InputSource`: toward lock 5/1.5 → 6/4 per second, back to centre 6/3 → 6/5.5 (standstill/at speed).
- **Lift-off:** `engine_brake_torque` 60 → 20, `center_of_mass_y` −0.35 → −0.5.
- **Brakes:** `brake_torque` 700 → 1100, `brake_bias_front` 0.7 → 0.65 (100–0 km/h in 36 m without locking). More torque locks the wheels.
- **Steering yaw assist** (spec changed to allow it): `yaw_assist_lateral_g` 1.7, `yaw_assist_gain` 6, `yaw_assist_rate` 70, `yaw_assist_max_slip_deg` 12, `yaw_assist_max_accel` 3, `yaw_assist_min_speed` 5. Keep `yaw_assist_lateral_g` a little above the grip: about 0.2–0.4 g more gives a light drift, much more spins the car. After the grip raise to 1.5 the drift is lighter; 1.9 brings back about 6° of body slip at 60 km/h.

- **Snow grip** 0.6 → 0.75 (2026-10-28, not yet driven). At 0.6 full keyboard lock at 60 km/h spun the car (47° body slip): the yaw assist (`yaw_assist_lateral_g` 1.9) asks for more lateral grip than snow has. Measured with full lock and throttle 0.4 at 60 km/h, and 100–0 braking:

  | Snow grip | Full lock at 60 km/h | 100–0 braking |
  |---|---|---|
  | 1.0 (gravel) | 1.34 g, 1° slip | 36 m |
  | 0.6 (old) | spins, 47° slip | 63 m |
  | 0.7 | unstable, 9° slip | 48 m |
  | 0.75 (chosen) | 0.91 g, 4° slip | 45 m |
  | 0.8 | 0.93 g, 6° slip | 36 m, brakes like gravel |

  Committed before driving it; check the feel on a snow section. Low-grip surfaces may need a yaw assist target scaled by surface grip; ice (0.4) likely spins the same way.

Still open for 3.8:

- **Sense of speed.** From the iso camera the player cannot tell when the car is too fast. As a result they underestimate the loss of grip and how much the car rotates. More speed feedback should let them judge corner entry speed.

- **Handbrake modulation.** While cornering, the rear wheels lock at 30% handbrake input or more for any `handbrake_torque` of 700 N·m or higher, because cornering already uses most of the rear grip. 500 N·m leaves a small usable range on an analog trigger. Keyboard input is all-or-nothing. Options: lower `handbrake_torque`, or ramp the handbrake key like steering (changes the player-input spec).
- **No aerodynamic drag.** Top speed is set only by the 5th-gear rev limiter (about 192 km/h).
- **Launch wheelspin on loose surfaces.** `torque_split_front` 0.35 stops front wheelspin on full grip. If gravel or grass (task 3.6) brings it back, add a viscous centre coupling: a `center_coupling` stat that moves torque from the faster axle to the slower one, capped per tick so the axles do not overshoot. This replaces the fixed split described in `design.md`, so update it too.

## Pace notes

Out of scope for the slice (see `proposal.md`). The design (`docs/syspec/art-audio.md`, `world.md`) wants co-driver pace notes: arrow icons on screen plus voiced calls ("left 4, don't cut!"), shown in the HUD.

To do as its own change: derive calls from the `RoadPath` ahead of the car, since the whole stage exists upfront. Corner direction and severity come from the curvature (e.g. 1–6 or hairpin). Crests come from `RoadPath.crests`, narrow sections from the road widths, and surface changes from the surface sections (task 5.7). Calls are timed by distance ahead at current speed. Severity thresholds should depend on the car's cornering speed, so they stay right after handling changes.

## More hazards

Hazards kept for after the slice (tasks 6.5–6.10 cover the rest of the proposed set):

- **UFO abduction.** Lifts the car and drops it about 50 m back along the road.
- **Road train.** A long truck crossing the road; wait or find a gap.

## Bad landing

The car takes no damage from hard landings; only body contacts count as impacts. To do when jumps matter (ramps in task 6.6, geysers in 6.9, crests): damage the suspension of each wheel by its compression speed on touchdown above a threshold stat, so ramps and crests reward clean landings.

## Stage build time

A 4 km stage takes 1–3 s to build (terrain, about 2000 props, hazards, spectators), so R and stage start pause. To do if it bothers: profile the terrain distance pass (`TerrainBuilder._heights`) and the prop colliders (one `CollisionShape3D` per prop) first.

## Immobilized car keeps driving

`CarDamage.immobilize` only emits `immobilized(cause)`; the car still accepts input and drives. Task 8.6 (game-over screen) cuts the engine and stops the car when the signal fires, so game-over behaviour lives in one place.

## Obstacle hazard tuning

Task 6.6 (committed 2026-10-28 as `a237c73`) was verified with headless runs; the user drove the stage on 2026-10-28 after task 6.10 and found it works well. The explosive barrel strength (`blast_impulse` 7000 N·s, `blast_speed` 10 m/s in `explosive_barrel.gd`) and the difficulty-2 gate on the fallen tree and the barrel are first guesses. Optional: tune them if the barrel feels too strong or the tree shows up too early.

## Area and triggered hazard tuning

Tasks 6.7–6.10 and 5.9 were verified with headless runs; the user drove the stage on 2026-10-28 and found it works well. The values below are first guesses, optional to tune: fire damage per second (`fire_patch.tres`, `burning_car.tres`), strike radius and blast strength (`meteorite.tscn`, `lightning.tscn`), rockfall rock size and `impact_scale` (a pass through the rocks costs about 200 condition points in total), and the difficulty-2 gate on landmine, sinkhole, strikes, rockfall and falling tree. The same goes for the 6.8 animals: herd sizes, walk speeds, lead times and `impact_scale` per animal scene (cow 0.3, moose 1 and `solid`). Task 6.9 force areas: wind gust 10 m/s² (moves an uncorrected car about 2.4 m per gust), steam geyser 25 m/s² up (launches at about 8 m/s), dust devil 12 m/s² up and 8 rad/s² yaw, helicopter downwash 2 m/s² down and 12 m/s² outward (only about 0.7 m sideways for a car passing 4 m off centre; tires resist most of it). Task 6.10 road followers are kinematic, so they never yield: a rear-end hit on the tractor at about 15 m/s costs about 190 condition points and a head-on with the wrong-way tourist about 600 (not lethal, they are not `solid`). Strikes land where the car would be at its speed when triggered, so braking or accelerating dodges them; that is intended.

## Roadside spectators

Task 5.9 was added during section 6 and done after 6.9. A 4 km stage has about 250 spectators as `Person` rigid bodies; with them the stage build takes about 2.6 s. Only people within 40 m of the car along the road are checked each tick. Rollover pushers stand beside the car for 1 s and walk off; the reset itself is still instant. To do when it matters: a real push animation, arms for waving, and `MultiMesh` people far from the car if the body count costs frame time.

`SpectatorPlacer`, `SpectatorCrowd` and the `CrowdSurge` hazard call underscore-private helpers of other scripts (`PropScatter._nearest`, `PropScatter._buckets`, `SurfacePatch._outside_sign`). Make them public (drop the underscore, update callers) if more scripts need them.

## Road edge lip

Where the terrain meets the road bevel, it often lies a little lower than the bevel's outer edge (on about 9% of the edge more than 2 cm, at most about 18 cm), which leaves a small lip. Walkers set only horizontal velocity, so animals stopped dead there, and a box even wedges its front under the bevel's thin edge. `Mantle` (`scripts/hazards/mantle.gd`, used by `Sheep` and `Person`) hops a grounded walker onto a ledge ahead that rises more than 3 cm within 0.1 m and is at most 0.3 m high. This roughly halved to quartered the animals stuck at the edge (2026-10-29, 10 spots per flock); some still stall with their front already at the lip, where the rise ahead is under 3 cm. Options if it still bothers: a stall fallback that hops on any rise of 1 cm or more, or a buried skirt below the bevel in `RoadBuilder._faces` so the terrain never meets a vertical edge.

## Items

Tasks 7.1–7.6 are done (7.6 on 2026-10-29). The 7.6 items, as built:

- Air Horn (roof, button, 10 s): people and animals on the road within 40 m and 60° ahead leave it to their nearer side, 4 m past the edge. People run at 6 m/s (`Person.flee`); sheep-type animals walk at double speed (`Sheep.flee_to`). Nothing on the road in range: no cooldown. In a headless run it cleared 75 of 97 sheep standing on the road; the rest were outside the cone or range.
- Spare Wheel (trunk, `part_broken`, 60 s): a broken tire repairs to 60; other parts do not fire it.
- Roof Spoiler (roof, `jump`): while airborne, a torque pulls pitch and roll toward level (gain 8, damping 3, max 6 rad/s²) until the first wheel touches down. A roll and pitch kick off the test ramp landed at 2° tilt with it and flipped the car without it.
- Roll Hoop (roof, `rolled_over`, 30 s): cancels the rollover penalty. `Car` passes the penalty to `items.on_event("rolled_over", data)` in a mutable dictionary before it emits `rolled_over` with the possibly changed value.
- Grapple Hook (front, button, 15 s): only off the road (more than half the road width from the centreline). Sets the horizontal velocity toward the nearest road point to `min(distance * 1.5, 12)` m/s, plus 3 m/s up. From 12 m off the centreline it lands about 1 m from it.

Task 7.7 adds the upgrade meter and pick (`UpgradeMeter`, `ItemPool`, `UpgradePick`, built by the stage). All its numbers are first guesses in the `StageParams` "Upgrades" group (one fill per 800 m, +5% per defeated hazard, 60 s real-time pick at time scale 0.02, 3 offers), so countries and the finished run loop can change them. The stage's `start_picks` export (3) opens picks right after spawn so items can be tried; drop it or move it after the countdown in task 8.3. The car takes no input during a pick and rolls freely, so on a slope at the start it can roll back a little during the start picks.

Items could not be driven in game before the upgrade pick (task 7.7). On 2026-10-28 the user declined an F3 dev key that would add items, so 7.2–7.6 are checked with tests and headless runs only.

Known limits:

- **Shared effect state.** Effects keep state on the loaded `.tres` resource (Nitro's burn timer, Roof Spoiler's airborne flag, the RNGs of Gearbox of Chaos and Lucky Dice). Two cars with the same item, or a stage reload while the resource stays cached, share that state. Duplicate item defs per car (`duplicate(true)` in `ItemManager.add_item`) when a second car or `RunState` (task 8.1) needs it; tests that compare mounted defs by identity then need updating.
- **Unseeded rolls.** Gearbox of Chaos and Lucky Dice roll with their own randomized RNG. Move them to the run RNG seeded by the stage seed (task 7.7 or 8.1).
- **Wear is harsh.** `wear_rate` 0.1 and `wear_acceleration` 10 take any damaged part from 99 to 0 in about 3 minutes. An item that wears a part "even while intact" therefore kills it within one stage; Overboost became data only (double engine damage) for that reason.
- **First-guess values.** Boost fill (Drift King 0.15/s, Nitro refill 0.04/s), Nitro (cost 0.25, 1.5 s, 6 m/s²), Flame Exhaust (cooldown 0.5 s, 3 m blast at 6 m/s), Bullbar (front damage ×0.5), Drift Launch (1.5 m/s per drift second, max 5), Jump Jacks (5.4 m/s, about 1.5 m) and all passive multipliers. Tune them after driving.
