# Spec Delta

## Purpose

Defines how the car takes damage through individual breakable parts instead of a health bar, how damage changes handling, and when a run ends because the car cannot move.

## ADDED Requirements

### Requirement: Breakable parts with wear
The car SHALL have these parts, each with a condition from 100% (intact) to 0% (broken): four tires, four brakes, engine, suspension, and chassis. The car SHALL NOT have a single health value.

#### Scenario: Fresh car
- **WHEN** a stage starts with a new car
- **THEN** every part is at 100%

### Requirement: Accelerating degradation once damaged
A damaged part SHALL keep losing condition over time while driving, with the rate rising as condition drops, so heavily damaged parts break within a stage while lightly damaged parts last several stages.

#### Scenario: Damaged tire degrades
- **WHEN** a tire is hit down to 70% and the car keeps driving
- **THEN** the tire's condition keeps falling and reaches 0% within about one stage of driving

#### Scenario: Intact part does not degrade
- **WHEN** a part is at 100% and nothing damages it
- **THEN** its condition stays at 100%

### Requirement: Damage affects handling
Each part's condition SHALL change handling: worn or flat tires lose grip and pull the car to that side, broken brakes stop braking on that wheel, a damaged engine loses power, and damaged suspension makes that corner sag and stiffen.

#### Scenario: Flat tire pulls
- **WHEN** the front-left tire is broken and the car drives straight with no steering
- **THEN** the car drifts toward the left

#### Scenario: Broken brake
- **WHEN** the rear-right brake is broken and the driver brakes
- **THEN** that wheel applies no brake force and the others still brake

### Requirement: Impact damage
Collisions SHALL damage the chassis and the parts nearest the impact point, scaled by impact speed.

#### Scenario: Light bump
- **WHEN** the car touches an obstacle at low speed
- **THEN** no part loses condition or only a small amount

#### Scenario: Side impact
- **WHEN** the car hits a rock with its front-right corner at medium speed
- **THEN** the front-right tire, brake and suspension and the chassis lose condition

### Requirement: Lethal impact speed
Hitting a solid obstacle above a lethal impact speed SHALL immobilize the car instantly. The lethal speed SHALL be a car stat that items can raise.

#### Scenario: High-speed tree hit
- **WHEN** the car hits a tree head-on above the lethal impact speed
- **THEN** the car is immobilized

#### Scenario: Raised threshold
- **WHEN** an item raises the lethal impact speed above the impact speed of that hit
- **THEN** the same hit damages parts but does not immobilize the car

### Requirement: Immobilization by part loss
The car SHALL be immobilized when the chassis reaches 0%, the engine reaches 0%, or three or more tires are broken.

#### Scenario: Engine destroyed
- **WHEN** the engine reaches 0%
- **THEN** the car is immobilized

#### Scenario: Two flat tires
- **WHEN** exactly two tires are broken and everything else is intact
- **THEN** the car can still drive

### Requirement: Rollover recovery
When the car rests on its roof or side for a short time, spectators SHALL push it back onto its wheels and the stage timer SHALL receive a time penalty.

#### Scenario: Car on its roof
- **WHEN** the car stays on its roof for 2 seconds
- **THEN** the car is placed back upright on the road near that spot and a time penalty is added

### Requirement: Damage events
The car SHALL emit events when a part takes damage, when a part breaks, and when the car is immobilized, so items and the game flow can react.

#### Scenario: Part break event
- **WHEN** a brake reaches 0%
- **THEN** a part-broken event naming that brake is emitted
