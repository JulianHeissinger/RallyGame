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

Task 3.8a fixed the structural handling issues in the flat test scene. Task 3.8 (the tuning pass) is skipped until stage generation (section 5) gives a real track; it stays unchecked in `tasks.md` until then. That pass also covers:

- **Handbrake modulation.** While cornering, the rear wheels lock at 30% handbrake input or more for any `handbrake_torque` of 700 N·m or higher, because cornering already uses most of the rear grip. 500 N·m leaves a small usable range on an analog trigger. Keyboard input is all-or-nothing. Options: lower `handbrake_torque`, or ramp the handbrake key like steering (changes the player-input spec).
- **No aerodynamic drag.** Top speed is set only by the 5th-gear rev limiter (about 192 km/h).
- **Yaw wobble.** At 70 km/h with 30% steering, the yaw rate oscillates (about 40/17/32/22 °/s over 2 s).
- **Launch wheelspin on loose surfaces.** `torque_split_front` 0.35 stops front wheelspin on full grip. If gravel or grass (task 3.6) brings it back, add a viscous centre coupling: a `center_coupling` stat that moves torque from the faster axle to the slower one, capped per tick so the axles do not overshoot. This replaces the fixed split described in `design.md`, so update it too.

## Immobilized car keeps driving

`CarDamage.immobilize` only emits `immobilized(cause)`; the car still accepts input and drives. Task 8.6 (game-over screen) cuts the engine and stops the car when the signal fires, so game-over behaviour lives in one place.
