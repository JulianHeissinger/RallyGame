# Vehicle

## Handling model

Semi-sim. Goal: feel better than art of rally.

- Sliding behaves like a real car. Throwing the car into a corner happens about as fast or as slow as in real life. No exaggerated arcade drift, no yaw assist, no forced drift angle.
- Real rally techniques emerge from the physics: lift-off oversteer, Scandinavian flick, handbrake turns, left-foot braking.
- Physics basis: per-wheel suspension, slip-based tire model (slip angle and slip ratio, load-sensitive, combined slip), weight transfer, per-wheel spin.
- Surfaces have different grip: gravel, tarmac, snow, ice, mud, grass, sand/fesh-fesh, water. Countries mix surfaces (see [world.md](world.md)).
- Drivetrain: AWD with a torque curve. Engine RPM follows driven-wheel spin (wheelspin shows as RPM flare), with an automatic clutch at launch, engine braking and a rev limiter.
- Gearbox: R, N and forward gears with a shift time. Automatic or manual shifting, chosen in a player setting.
- All handling values are data, so items, damage and different cars can change them at runtime.

## Input

- Controller and keyboard are both first-class. No wheel support planned.
- Controller: analog steering, throttle and brake.
- Keyboard: steering ramps toward full lock over time and returns to center, slower at high speed, so taps make small corrections.
- Actions: steer, throttle, brake/reverse, handbrake, activate mounted item, pause.
- Each car reads from an assigned input source, to keep couch co-op possible later.

## Camera

- Isometric follow camera, art of rally style. Fixed angle, does not rotate with the car, look-ahead in the direction of travel.
- The camera is a swappable rig. An optional chase cam may come later as an unbalanced bonus view. The world is built fully 3D so this stays possible.

## Parts

The car has no health bar. It is a set of parts, each with a condition from 100% (intact) to 0% (broken).

| Part | Effect when worn / broken |
|---|---|
| Tires ×4 | Less grip; a flat tire pulls the car to its side |
| Brakes ×4 | Less / no brake force on that wheel |
| Engine | Less power; 0% = immobilized |
| Gearbox | Slow or missed shifts, lost gears |
| Steering | Reduced lock, play, pull |
| Suspension (per corner) | Sag, harsh ride, worse grip over bumps, lower jumps survive |
| Radiator | Engine overheats, loses power over time |
| Lights | Worse visibility at night / in fog |
| Heater | Fogged/frosted windscreen in cold countries (reduced visibility) |
| Chassis / body | Structural integrity; 0% = immobilized |

The prototype uses a subset: tires, brakes, engine, suspension, chassis. The full list is a target, not final.

## Damage and wear

- Damage is wear-based (gradual), but once a part is damaged it degrades fairly quickly to broken while driving.
- Damage sources: impacts (scaled by impact speed, applied to the parts nearest the impact point), hazards with specific damage profiles (pothole → tire and suspension), malfunctions (random part).
- Broken parts are not only a penalty: items can require broken parts and grow stronger with them (see [items.md](items.md)).

## Immobilization (run over)

Two paths:
1. **Lethal impact:** hitting a solid obstacle (e.g. a tree) above the lethal impact speed immobilizes the car instantly. The lethal speed is a car stat that upgrades raise (roll cage, reinforced chassis, ...).
2. **Critical parts lost:** chassis at 0%, engine at 0%, or too many tires broken (prototype: 3 or more).

## Rollover and recovery

- If the car rests on its roof or side for a short time, spectators push it back onto its wheels.
- This adds a time penalty, which reduces prize money.
- Falling out of the world respawns the car on the road with a time penalty.

## Cars

- Multiple cars, unlocked through meta progression (see [meta-progression.md](meta-progression.md)).
- Each car has its own handling and starting parts.
- Visual era: boxy Group A/B silhouettes, pop-up headlights, bold 90s liveries (see [art-audio.md](art-audio.md)).
