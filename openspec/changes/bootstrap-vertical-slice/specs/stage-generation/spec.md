# Spec Delta

## Purpose

Defines how a rally stage is built procedurally from a seed: the road, its features, the terrain and props around it, and the start and finish, all generated before the stage begins.

## ADDED Requirements

### Requirement: Seeded determinism
A stage SHALL be fully determined by its seed and difficulty level: the same seed and difficulty SHALL produce the same road, terrain, props and hazard placement.

#### Scenario: Same seed twice
- **WHEN** a stage is generated twice with seed 12345 and the same difficulty
- **THEN** both stages have identical road shape, prop positions and hazard positions

#### Scenario: Different seeds
- **WHEN** stages are generated with seeds 1 and 2
- **THEN** the road shapes differ

### Requirement: Upfront generation
The whole stage SHALL be generated before the player gains control, and the full road path SHALL be available from the start.

#### Scenario: Stage start
- **WHEN** the countdown begins
- **THEN** the full road from start to finish already exists

### Requirement: Point-to-point road
The road SHALL be a continuous, drivable path from a start line to a finish line, with a target length set by a parameter (default about 2 km for the prototype) and a road width that fits one car comfortably with room to slide.

#### Scenario: Road is drivable end to end
- **WHEN** a stage is generated
- **THEN** the road does not cross itself and connects the start line to the finish line

### Requirement: Road features
The generator SHALL produce a mix of straights, fast corners, tight corners, hairpins and crests, with gradients that stay readable from the isometric camera.

#### Scenario: Feature variety
- **WHEN** a 2 km stage is generated
- **THEN** it contains at least one hairpin and at least one crest

### Requirement: Terrain around the road
The road SHALL sit on generated terrain that extends to both sides, blends into the road edges without steps, and is drivable but grips less than the road.

#### Scenario: Leaving the road
- **WHEN** the car drives off the road edge
- **THEN** it lands on terrain without falling through or hitting an invisible wall

### Requirement: Props
The generator SHALL scatter props (trees, rocks, fences) beside the road, keeping the road itself clear, with denser solid props creating real crash risk on corner outsides.

#### Scenario: Road kept clear
- **WHEN** a stage is generated
- **THEN** no prop overlaps the road surface

#### Scenario: Solid trees
- **WHEN** the car hits a tree
- **THEN** the tree blocks the car as a solid obstacle

### Requirement: Stage boundaries
The stage SHALL stop the car from leaving the generated area and SHALL return the car to the road if it falls below the terrain.

#### Scenario: Fell out of world
- **WHEN** the car falls below the terrain
- **THEN** the car is placed back on the road near its last position with a time penalty

### Requirement: Progress along the road
The stage SHALL report the car's distance along the road, so other systems can use distance driven and position on the stage.

#### Scenario: Halfway
- **WHEN** the car is at the middle of a 2 km road
- **THEN** reported progress is about 1 km
