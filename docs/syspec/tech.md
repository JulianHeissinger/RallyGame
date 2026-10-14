# Tech

## Engine and language

- **Godot 4** (installed: 4.7.2 stable). Free, MIT licensed, text-based scenes and resources.
- **GDScript with static typing.** Performance-critical hot spots (e.g. large drone swarms) can move to C# or GDExtension later if profiling shows a need; mixing languages requires the .NET build of Godot.
- **Physics:** Jolt (built into Godot), physics tick 120 Hz for car stability.
- **No third-party addons** without explicit approval.

## Architecture principles

- **Data-driven content:** cars, items, hazards and countries are Godot Resources (`.tres`). New content combining existing behaviors needs no code changes.
- **One stat path:** effective car stats = base, plus item modifiers, plus damage multipliers. Items, damage and car unlocks all use it.
- **Signals for events:** car and stage emit events (part damaged/broken, drift, jump, gear shift, collision, threat defeated); items and UI subscribe.
- **Seeded generation:** separate random sub-streams per subsystem, derived from the stage seed.
- **Swappable camera rig:** the camera targets a car and can be replaced (chase cam later).
- **Per-player input source:** cars never read global input directly (couch co-op later).
- **Custom car physics:** raycast wheels with a slip-based tire model on a `RigidBody3D`. Godot's `VehicleBody3D` is not used because its friction model cannot give realistic sliding.

## Project layout

```
project.godot
scenes/   game scenes
scripts/  core/ car/ stage/ hazards/ items/ ui/ input/
data/     cars/ items/ hazards/ (later: countries/)
tests/    headless test runner + tests
docs/     questions.md, syspec/
openspec/ change proposals and capability specs
```

## Testing

- Headless GDScript test runner, no test addon: `godot --headless --path . -s tests/run_tests.gd`.
- Automated tests cover deterministic and rule-based systems (generation, damage rules, stat stacking, items, prize money).
- Handling feel is verified by playtesting with a debug overlay.

## Workflow

- Changes are planned with OpenSpec (`/opsx:propose`, `/opsx:apply`, `/opsx:archive`).
- This folder holds the game-level spec; `openspec/specs/` holds testable capability requirements once changes are archived.

## Platforms

Not decided. Development on macOS. Console export would need third-party porting. See [open-questions.md](open-questions.md).

## Multiplayer

Single player first. Maybe couch co-op later. No online play.
