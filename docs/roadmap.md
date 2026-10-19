# Roadmap

Technical work deferred past the vertical slice (`openspec/changes/bootstrap-vertical-slice`). Each entry says what triggers it.

## Multiple cars

Car tuning is data-driven: every value lives in a `CarStats` resource (`data/cars/*.tres`), and `Car`, `Wheel`, `Drivetrain` and `Gearbox` hold no shared state. A new car is a new `.tres` plus an inherited scene of `scenes/car.tscn` for its geometry.

To do when a second car or an AI/rival car is planned:

- **Input injection.** `Car` creates `InputSource.new()` itself, which reads keyboard and joypad 0. AI, rival and ghost cars need an `InputSource` subclass assigned from outside (e.g. an exported or spawner-set input), so the car never reads the player's devices.
- **Wheel mesh size.** The wheel meshes in `car.tscn` are sized by hand and not tied to the `wheel_radius` stat. Derive the mesh scale from the stat, or check it in a test, so a car with different wheels cannot drift out of sync.

Known limits, fine until a car needs them:

- **Geometry lives in the scene.** Wheelbase, track width and the collision box are node transforms in the car scene, not stats. They affect handling as much as the stats do, so tuning a car means editing both files.
- **Axle role comes from `steerable`.** `Drivetrain` picks the front axle for torque split and brake bias by the wheel's `steerable` flag. Rear-wheel steering would need a separate axle flag.
- **Gearbox mode is global.** `Settings.gearbox_mode` is one setting for all cars. Split-screen or per-car modes would need it per player.
