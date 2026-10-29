# Design

## Context

Empty repo apart from `docs/` (design decisions in `docs/questions.md`, game spec in `docs/syspec/`) and OpenSpec config. Godot 4.7.2 is installed (`/opt/homebrew/bin/godot`). No Blender models yet, so every visual is a placeholder primitive. Motivation: see proposal.md - Why. Requirements: see `specs/`.

Constraints from the user: GDScript with static typing, no third-party addons/dependencies without asking, latest stable tools.

## Goals / Non-Goals

**Goals:**
- One playable loop: menu, seeded stage, drive, take damage, pick items, finish or crash.
- Architecture that later content (countries, service park, rivals, bosses, meta progression) can extend without rewrites: data resources for items, hazards and car stats; signals for events; seeded sub-streams for generation.
- Handling that is tuned by data and inspectable with a debug overlay.

**Non-Goals:**
- Final tuning or balance. Values are first guesses.
- Visual polish, audio, art pipeline (Blender scripts come in a later change).
- Item evolutions, scrap currency, service park (later changes).

## Decisions

### Project and layout
Godot 4.7 project at repo root, Forward+ renderer, Jolt physics set explicitly, physics tick 120 Hz (car stability).

```
project.godot
scenes/   main_menu.tscn, stage.tscn, car.tscn, ui/*.tscn, hazards/*.tscn
scripts/  core/ car/ stage/ hazards/ items/ ui/ input/
data/     cars/*.tres  items/*.tres  hazards/*.tres
tests/    run_tests.gd + test_*.gd
```
`.gitignore` for `.godot/` (repo has no git yet; `git init` is left to the user).

### Car: custom RigidBody3D with raycast wheels
`RigidBody3D` body with four wheel nodes, each a `RayCast3D` for suspension. Per physics tick each wheel computes spring + damper force, load, slip angle and slip ratio, then tire force from a simplified Pacejka-style curve, with combined slip limited by a friction ellipse scaled by load and surface grip.

- Alternative `VehicleBody3D`: rejected. Its friction model has no slip curve, so it cannot give realistic sliding.
- Alternative kinematic arcade model: rejected. It conflicts with the semi-sim requirement.
- Low-speed jitter: below a few m/s slip uses a blended velocity-damping model, a standard fix for raycast cars.
- Wheel spin is integrated per wheel (angular velocity from drive torque, brake torque and tire force) so slip ratio, handbrake lock and wheelspin are real.
- Drivetrain: AWD with fixed torque split and a torque curve from data. Engine RPM is derived from the mean angular velocity of the driven wheels × gear ratio × final drive, so wheelspin shows up as RPM flare. Below a clutch engage speed an automatic clutch slips: RPM is held at least at a launch RPM and torque still reaches the wheels, so the car never stalls. Engine braking is a negative torque scaled by RPM when throttle is 0. The rev limiter cuts drive torque at redline and restores it below redline minus a hysteresis.
  - Alternative: simulated flywheel inertia with clutch torque transfer. Rejected for the prototype: harder to tune, and wheel-coupled RPM already shows wheelspin.
- Gearbox: gears R, N, 1..n with ratios in `CarStats`. A shift starts a timer (`shift_time` stat) with zero drive torque, then engages the new gear and emits `gear_shifted(from, to)`. Automatic mode shifts by RPM thresholds, using the RPM matched to road speed (not wheel spin) so wheelspin bounces off the limiter instead of causing upshift/downshift hunting, and engages reverse when braking near standstill. Manual mode reads shift presses from the `InputSource`: down from 1st goes to N, then R (R only below a standstill speed), and downshifts that would exceed redline are refused. The mode comes from `Settings`.
- Steering yaw assist (spec: realistic rotation speed): while steering input is non-zero, a yaw torque of `inertia * clamp(gain * (target - yaw_rate), ±max_accel)` pulls the yaw rate toward `steer * min(yaw_assist_rate, yaw_assist_lateral_g * g / speed)`, a turn rate slightly above tire grip, so the car holds a light drift at every speed. Torque that adds rotation tapers to zero at `yaw_assist_max_slip_deg` of body slip, so the assist never pushes the car into a spin; torque against the rotation (countersteer) is not limited. It fades in above `yaw_assist_min_speed`, needs at least 2 grounded wheels, and is off without steering input. All values are `CarStats` stats.

### Car stats as Resources plus a modifier stack
`CarStats` resource (`data/cars/prototype.tres`) holds base values. A `StatBlock` computes effective stats as `base`, then additive item modifiers, then multiplicative item modifiers, then damage multipliers. It recomputes only when items or part conditions change. Wheels and drivetrain read effective stats. This one path serves items, damage and later car unlocks.

### Damage
`CarDamage` node owns a dictionary of parts (`tire_fl` ... `brake_rr`, `suspension_fl` ... `suspension_rr`, `engine`, `chassis`) with conditions from 0 to 100.
- Impacts come from contact monitoring on the body. Impact speed is the relative velocity along the contact normal. The contact point in car-local space maps to a zone (front-left, front-right, rear-left, rear-right, center), and the zone decides which parts take damage: a corner zone damages that corner's tire, brake and suspension plus a share to the chassis (and to the engine for front zones); a hit near the middle of the front or rear damages both corners of that end at 0.75 each; the center zone damages the chassis. Only new contacts count, with the velocity from before the physics step, so resting or sliding contact does not stack damage.
- Lethal impact: impact speed against a body in group `solid` above `lethal_impact_speed` (a stat) immobilizes the car immediately.
- Degradation: once a part is below 100, it loses `rate * (1 + (100 - c) / k)` per second while the car moves.
- Rollover: the body's up vector stays below a threshold for 2 s, then the car resets to the nearest road sample, upright, with a penalty.
- Signals: `part_damaged(part, amount)`, `part_broken(part)`, `immobilized(cause)`.
- Handling effects: car-wide effects (engine power) go through `StatBlock` damage multipliers. Per-wheel effects (tire grip and rolling drag, brake loss, suspension sag and stiffness) are factors on each `Wheel`, set by the car from the matching parts each tick, because `StatBlock` holds only car-wide stats.

### Input
InputMap actions: `steer_left/right`, `throttle`, `brake`, `handbrake`, `shift_up`, `shift_down`, `activate_item`, `pause`, `ui_*`. Both keyboard and joypad events are bound to each action.

An `InputSource` object exposes `steer/throttle/brake/handbrake` as floats and `shift_up/shift_down` as just-pressed flags. The car reads only from its assigned source. The single-player source uses the `Input` singleton with keyboard and device 0. A per-device source for couch co-op can be added later without touching the car. Keyboard steering ramps at a rate that drops with speed.

### Camera
`IsoCameraRig` (Node3D + Camera3D) with a target. Perspective camera with a narrow FOV (~30°) placed far away at a fixed pitch (~35°). This gives a near-isometric look while keeping depth cues on crests. With a `road` (`RoadPath`) set, the yaw follows the road tangent a little ahead of the car's progress through a slow smoothing, so the car always drives away from the camera and its own spins do not turn the view. Without a road the yaw is fixed (~45°).
- Alternative: orthographic. Rejected because it flattens height, which makes crests and jumps hard to read.
- Smoothing: position follows with critically damped smoothing, plus a look-ahead offset of velocity × factor (clamped).

### Stage generation pipeline
`StageGenerator` takes `(seed, difficulty, params)` and returns a built stage. Every sub-step gets its own `RandomNumberGenerator` seeded by `hash([seed, "road"])`, `hash([seed, "props"])` and so on. Changing prop logic therefore never changes the road. This is the basis for the determinism requirement.

1. **Road layout (2D):** chain of segments (straight, arc with radius, hairpin) from a weighted table, then turn into a heading and position path. Each candidate segment is checked against existing samples for minimum clearance; on failure it retries with another segment, and after N failures the stage regenerates with a derived seed. It stops at the target length.
2. **Elevation:** low-frequency noise plus placed crest features, with the gradient clamped (readability from the iso camera).
3. **Curve:** `Curve3D` sampled at fixed spacing. Samples are stored in an array with cumulative distance, used for progress, respawns and placement.
4. **Road mesh:** ribbon extruded along the samples with `SurfaceTool`. Collision is a `ConcavePolygonShape3D` with metadata `surface = "gravel"`.
5. **Terrain:** heightmap grid covering road bounds plus a margin. Heights come from noise, blended toward road height by distance to the road (spatial hash of road samples). The terrain sits slightly below the road under it to avoid z-fighting. Collision is `HeightMapShape3D` with `surface = "grass"`.
6. **Props:** jittered-grid sampling, rejected inside the road width plus margin. Density is boosted on corner outsides using curvature. Visuals use `MultiMeshInstance3D` per prop type; trees and rocks get `StaticBody3D` colliders in group `solid`.
7. **Bounds:** invisible walls at the terrain edge, plus a kill plane below the terrain that triggers respawn.
8. **Surface sections:** the road is split into sections drawn from a weighted surface table in `StageParams` (road surface, matching terrain surface, weight, length range) using the `"surfaces"` sub-stream. Road mesh and collider are built per section with its `surface` metadata, replacing the single `gravel` collider of step 4. The terrain beside each section takes the section's terrain surface instead of plain `grass`.

Each wheel reads the `surface` metadata from the collider its ray hits and looks up grip in a surface table.

### Hazards
`HazardDef` resource holds name, scene, `min_difficulty`, `weight`, `on_road`, and damage profile. Hazard density lives in `StageParams` (the hazard pool, `hazards_per_km`, `hazard_difficulty_scale`, `hazard_min_spacing`): one density per stage style, scaled by difficulty, with the type mix set by the unlocked defs' weights. Placement during generation uses the hazards sub-stream and puts one hazard in each equal slot of the road between start and finish, so spacing never drops below the minimum.
- **Rock:** solid body on or near the road.
- **Pothole:** an `Area3D` decal; a wheel ray inside it applies tire and suspension damage scaled by speed.
- **Sheep flock:** 40–100 sheep wait beside the road and start crossing when the car is a few seconds away at its current speed, so many are on the road when it arrives. Each sheep is a light `RigidBody3D`. A car hit knocks it sideways and up; the car takes normal impact damage scaled down by the sheep's `impact_scale` metadata, once per sheep (`impact_once`). A hit sheep that ends up off the road emits `hazard_defeated`.
- **Malfunction:** not placed physically. Malfunctions are scheduled at road distances drawn from the events sub-stream, and trigger when the car's progress passes that distance. Distance-based scheduling (not time-based) keeps them repeatable for the same seed and path.

### Items
`ItemDef` resource holds id, name, description, `kind` (passive/active), `cursed`, `modifiers: Array[StatModifier]`, `mount` (enum), `activation` (none/button/trigger), `trigger_event`, `cooldown`, `condition_broken` (part or part group that must be broken), and `effect: ItemEffect`.
- `ItemEffect` is a small Resource base class with `on_activate(car)` and `on_event(car, event, data)`. Prototype effects: Drift King, Gearbox of Chaos, Underdog, Lucky Dice, Overboost, Nitro, Flame Exhaust, Bullbar, Drift Launch, Jump Jacks, Air Horn, Spare Wheel, Roof Spoiler, Roll Hoop, Grapple Hook. The other prototype items, including the engine parts and Hazard Hunter (a `hazard_bonus_scale` stat the upgrade meter reads), are modifiers only.
- New items that combine existing effects and modifiers are pure `.tres` data. New behaviors need one new effect script. That is the "addable without changing the item system" boundary.
- `ItemManager` (child of car) holds passive stacks (`id → count`) and 4 mount slots. It connects car and stage signals, and fans them out to items whose trigger or condition matches. Cooldowns are tracked per slot.
- **Upgrade pick:** `UpgradeMeter` gains value from progress delta and `hazard_defeated`. When full it sets `Engine.time_scale = 0.2` and shows a 3-card UI. The card timer uses real time (`Time.get_ticks_msec`) so slow motion does not stretch it; on timeout it picks the first card. Offers are drawn from a run RNG seeded by stage seed.

### Game flow
- `Settings` autoload holds player settings (prototype: gearbox mode) and saves them in a `ConfigFile` at `user://settings.cfg`.
- `RunState` autoload holds the current seed, difficulty, prize money, and owned items. It is ready for multi-stage runs later. `GameEvents` is not needed; signals stay local to car, stage and items.
- Scenes: `main_menu.tscn`, then `stage.tscn` (generator, car, camera, HUD, pause, finish and game-over overlays). Retry reloads `stage.tscn` with the same seed and a reset `RunState`.
- **Prize money:** `base * clamp(par_time / final_time, 0.25, 2.0)`, where `par_time = road_length / reference_speed`.
- **Pause:** `get_tree().paused`. UI nodes use process mode `ALWAYS`.

### Testing
No test addon (no new dependencies). `tests/run_tests.gd` extends `SceneTree`, runs `test_*.gd` files headless, and exits non-zero on failure:
`godot --headless --path . -s tests/run_tests.gd`

Covered:
- Generator determinism and road validity: no self-intersection, connected, length, hairpin and crest present, props off road.
- Damage rules: degradation, immobilization conditions, lethal speed with a modifier.
- Stat modifier stacking.
- Item conditions and cooldowns.
- Hazard difficulty gating.
- Prize money ordering.

Handling feel is checked by manual playtest with an F1 debug overlay (per-wheel load, slip angle, slip ratio, surface).

## Risks / Trade-offs

- [Custom tire model feels wrong or unstable] → 120 Hz physics, low-speed blending, every constant in `CarStats`, debug overlay, and a dedicated tuning task before the other systems pile on.
- [Road/terrain seams or wheels catching on edges] → terrain lowered under the road, road edges slightly beveled, wheel rays (not shapes) so edges do not snag.
- [Road generator dead ends] → bounded retries plus regeneration with a derived seed. Determinism holds because the derived seed comes from the original.
- [Concave road collider performance] → about 4 km of road is small. Split it into chunks if profiling shows a cost.
- [Slow motion affects physics stability] → Jolt scales the step with time_scale. If issues appear, physics can be paused during the pick instead (falls back to the VS-style pause).
- [Scope is large for one change] → tasks are ordered so each section is playable on its own (car on flat ground first).

## Open Questions

- Final tuning values for tires, suspension and degradation rates. They are found by playtesting and do not change the structure.
- Exact prize money base and reference speed. They are tuned later.
