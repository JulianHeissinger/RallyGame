# Proposal

## Why

The repo is empty apart from the design notes in `docs/` (`docs/questions.md`, `docs/syspec/`). Before building content (countries, bosses, service park, meta progression), the riskiest parts of the design need to be proven in a playable form: semi-sim car handling viewed from an isometric camera, seeded procedural stages, part-based damage, and the item/hazard systems that must support silly synergies later.

## What Changes

- Create a Godot 4 project (GDScript, static typing) at the repo root with a clear folder layout.
- Add a semi-sim raycast car: slip-based tire model, weight transfer, handbrake, gearbox with RPM, rev limiter and automatic or manual shifting, playable with controller and keyboard.
- Add part-based damage: per-part wear (tires x4, brakes x4, suspension x4, engine, chassis), effects on handling, and immobilization (lethal impact speed or critical parts destroyed).
- Add an isometric follow camera (art of rally style), built as a swappable rig.
- Add a seeded procedural stage: road spline with curves, hairpins and crests, terrain around it, scattered props, start and finish.
- Add a basic hazard system: data-driven hazards placed along the stage by seed and difficulty (e.g. rock, pothole, sheep flock, random malfunction).
- Add a basic item system: passive items with stacking, mounted active items (trigger-based and button-based), broken-part conditions, and a mid-stage slow-motion 1-of-3 pick fed by distance driven.
- Add a basic game flow: main menu (start with optional seed, quit), stage run with timer, rollover recovery with time penalty, finish screen with time and prize money, crash/game-over screen.
- Use placeholder primitives for all visuals (no Blender models yet).

Out of scope: service park and shop, countries/biomes, bosses, rival cars, drones, meta progression, pace notes, PS1 shader and liveries, chase cam, couch co-op, endless mode, save data (only a settings file for the gearbox mode).

## Capabilities

### New Capabilities
- `vehicle-handling`: Semi-sim car physics: suspension, slip-based tire forces, weight transfer, drivetrain, handbrake, and how driver input maps to them.
- `vehicle-damage`: Breakable car parts with wear, their effect on handling, rollover recovery, and when the car becomes immobile.
- `player-input`: Controller and keyboard actions, keyboard steering smoothing, per-device mapping that leaves room for couch co-op.
- `isometric-camera`: Isometric follow camera behavior and the swappable camera rig contract.
- `stage-generation`: Seeded procedural stage: road spline, road features, terrain, props, start/finish, determinism.
- `hazards`: Hazard definitions, seeded placement by difficulty, and how hazards damage parts.
- `items`: Item definitions, passive stacking, mounted active items with triggers or button activation, broken-part conditions, mid-stage upgrade pick.
- `game-flow`: Main menu, stage run lifecycle, stage timer, prize money, finish and game-over screens.

### Modified Capabilities
<!-- None: no existing specs. -->

## Impact

- New Godot 4.7 project files at repo root (`project.godot`, scenes, scripts, input map).
- No third-party addons or dependencies. Tests run as headless GDScript scripts via `godot --headless`.
- `docs/` (questions and syspec) stays as the design reference. This change only records decisions made during it (manual gearbox option).
