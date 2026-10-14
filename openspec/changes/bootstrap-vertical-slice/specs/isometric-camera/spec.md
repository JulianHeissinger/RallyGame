# Spec Delta

## Purpose

Defines the isometric follow camera used during stages, in an art of rally style, and keeps the camera swappable so a chase cam can be added later.

## ADDED Requirements

### Requirement: Isometric follow view
The stage camera SHALL view the car from a fixed elevated angle at a fixed rotation and follow its position smoothly.

#### Scenario: Car drives around a corner
- **WHEN** the car turns 90 degrees
- **THEN** the camera keeps its viewing angle and does not rotate with the car

### Requirement: Look-ahead
The camera SHALL shift its framing toward the car's direction of travel, scaled by speed, so more road ahead is visible at higher speed.

#### Scenario: Fast straight
- **WHEN** the car drives fast in one direction
- **THEN** the car sits off-center with more of the road ahead in view than behind

### Requirement: Swappable camera rig
The camera SHALL be a separate rig that targets a car, so a different rig can replace it without changing car or stage behavior.

#### Scenario: Replace the rig
- **WHEN** a different camera rig is set as the active stage camera
- **THEN** the car and stage keep working unchanged
