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
- **Grip:** `tire_friction` 1.0 → 1.5 (about 1.3 g cornering on gravel). Surface grip: grass 0.8, snow 0.6, ice 0.4.
- **Steering:** `min_steer_angle_deg` 14 → 8, `steer_reduction_speed` 25 → 22. Keyboard ramp in `InputSource`: toward lock 5/1.5 → 6/4 per second, back to centre 6/3 → 6/5.5 (standstill/at speed).
- **Lift-off:** `engine_brake_torque` 60 → 20, `center_of_mass_y` −0.35 → −0.5.
- **Brakes:** `brake_torque` 700 → 1100, `brake_bias_front` 0.7 → 0.65 (100–0 km/h in 36 m without locking). More torque locks the wheels.
- **Steering yaw assist** (spec changed to allow it): `yaw_assist_lateral_g` 1.7, `yaw_assist_gain` 6, `yaw_assist_rate` 70, `yaw_assist_max_slip_deg` 12, `yaw_assist_max_accel` 3, `yaw_assist_min_speed` 5. Keep `yaw_assist_lateral_g` a little above the grip: about 0.2–0.4 g more gives a light drift, much more spins the car. After the grip raise to 1.5 the drift is lighter; 1.9 brings back about 6° of body slip at 60 km/h.

Still open for 3.8:

- **Sense of speed.** From the iso camera the player cannot tell when the car is too fast. As a result they underestimate the loss of grip and how much the car rotates. More speed feedback should let them judge corner entry speed.

- **Handbrake modulation.** While cornering, the rear wheels lock at 30% handbrake input or more for any `handbrake_torque` of 700 N·m or higher, because cornering already uses most of the rear grip. 500 N·m leaves a small usable range on an analog trigger. Keyboard input is all-or-nothing. Options: lower `handbrake_torque`, or ramp the handbrake key like steering (changes the player-input spec).
- **No aerodynamic drag.** Top speed is set only by the 5th-gear rev limiter (about 192 km/h).
- **Launch wheelspin on loose surfaces.** `torque_split_front` 0.35 stops front wheelspin on full grip. If gravel or grass (task 3.6) brings it back, add a viscous centre coupling: a `center_coupling` stat that moves torque from the faster axle to the slower one, capped per tick so the axles do not overshoot. This replaces the fixed split described in `design.md`, so update it too.

## Pace notes

Out of scope for the slice (see `proposal.md`). The design (`docs/syspec/art-audio.md`, `world.md`) wants co-driver pace notes: arrow icons on screen plus voiced calls ("left 4, don't cut!"), shown in the HUD.

To do as its own change: derive calls from the `RoadPath` ahead of the car, since the whole stage exists upfront. Corner direction and severity come from the curvature (e.g. 1–6 or hairpin). Crests come from `RoadPath.crests`, narrow sections from the road widths, and surface changes from the surface sections (task 5.7). Calls are timed by distance ahead at current speed. Severity thresholds should depend on the car's cornering speed, so they stay right after handling changes.

## More hazards

Hazards kept for after the slice (tasks 6.5–6.7 cover the rest of the proposed set):

- **UFO abduction.** Lifts the car and drops it about 50 m back along the road.
- **Paparazzi.** Camera flashes that blind the screen for a moment.
- **Road train.** A long truck crossing the road; wait or find a gap.

## Bad landing

The car takes no damage from hard landings; only body contacts count as impacts. To do when jumps matter (ramps in task 6.6, crests): damage the suspension of each wheel by its compression speed on touchdown above a threshold stat, so ramps and crests reward clean landings.

## Immobilized car keeps driving

`CarDamage.immobilize` only emits `immobilized(cause)`; the car still accepts input and drives. Task 8.6 (game-over screen) cuts the engine and stops the car when the signal fires, so game-over behaviour lives in one place.
