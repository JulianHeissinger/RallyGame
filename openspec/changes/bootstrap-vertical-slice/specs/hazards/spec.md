# Spec Delta

## Purpose

Defines threats that damage the car during a stage, how they are defined as data, and how they are placed or triggered by seed and difficulty.

## ADDED Requirements

### Requirement: Data-driven hazard definitions
Each hazard type SHALL be defined as data: name, minimum difficulty, spawn weight, which parts it can damage, and how much. New hazard types SHALL be addable without changing the placement system.

#### Scenario: Locked by difficulty
- **WHEN** a stage is generated below a hazard's minimum difficulty
- **THEN** that hazard type is never placed

### Requirement: Seeded placement
Static hazards SHALL be placed along the road during stage generation using the stage seed, with more hazards at higher difficulty.

#### Scenario: Higher difficulty
- **WHEN** the same seed is generated at difficulty 1 and difficulty 3
- **THEN** difficulty 3 has more hazards

### Requirement: Prototype hazard set
The prototype SHALL include at least: a rock on the road (solid, damages tires and suspension), a pothole (damages one tire and suspension when driven through), a sheep flock (animals cross the road; hitting them damages the front and slows the car), and a random malfunction (an event that damages a random part).

#### Scenario: Pothole hit
- **WHEN** a wheel drives through a pothole at speed
- **THEN** that wheel's tire and suspension lose condition

#### Scenario: Sheep crossing
- **WHEN** the car approaches a sheep flock hazard
- **THEN** the sheep start crossing the road and collisions with them damage the car's front

#### Scenario: Random malfunction
- **WHEN** a malfunction event fires during the stage
- **THEN** one random part loses condition and the player is notified which part

### Requirement: Wheel-contact hazards
Beyond the prototype set, nails or a spike strip, broken glass and a log across the road SHALL damage the wheels that cross them.

#### Scenario: Spike strip
- **WHEN** the car drives across a spike strip
- **THEN** every tire that crosses it loses condition

### Requirement: Surface-patch hazards
An oil slick, puddle, mud patch, black ice patch, banana peel and water crossing SHALL change the grip or drag of the wheels on them. A water crossing taken too fast SHALL damage the engine.

#### Scenario: Oil slick
- **WHEN** a wheel drives over an oil slick
- **THEN** that wheel has less grip until it leaves the slick

### Requirement: Obstacle and launch hazards
A fallen tree (solid), crashed car (pushable), hay bales, traffic cones (defeatable), explosive barrel and ramp SHALL be placeable as obstacles.

#### Scenario: Traffic cone
- **WHEN** the car knocks a traffic cone away
- **THEN** a hazard-defeated event is emitted

### Requirement: Area and triggered hazards
A fire patch, burning crashed car, spectator on the road, meteorite, rockfall, falling tree, landmine, tumbleweed and cows SHALL act when the car is inside them or approaches them.

#### Scenario: Spectator on the road
- **WHEN** the car approaches a spectator standing on the road
- **THEN** the spectator dives clear before the car reaches them and is never hit

#### Scenario: Meteorite
- **WHEN** the car approaches a meteorite hazard
- **THEN** a marker shows where it will land, and the impact damages the car if it is inside the blast radius

### Requirement: Deterministic events
Timed or triggered hazard events (e.g. malfunctions) SHALL draw from a random stream derived from the stage seed.

#### Scenario: Repeatable malfunctions
- **WHEN** the same seed is driven twice along the same path
- **THEN** malfunction events pick the same parts

### Requirement: Defeatable hazards
Hazards that can be defeated (e.g. a sheep knocked off the road) SHALL emit a defeated event so items and rewards can react.

#### Scenario: Sheep knocked off
- **WHEN** the car knocks a sheep off the road
- **THEN** a hazard-defeated event is emitted
