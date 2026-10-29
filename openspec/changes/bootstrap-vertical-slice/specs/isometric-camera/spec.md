# Spec Delta

## Purpose

Defines the isometric follow camera used during stages, in an art of rally style, and keeps the camera swappable so a chase cam can be added later.

## ADDED Requirements

### Requirement: Isometric follow view
The stage camera SHALL view the car from a fixed elevated angle and follow its position smoothly. On a stage, the camera's rotation SHALL slowly follow the direction of the road ahead, so the car drives away from the camera. It SHALL NOT rotate with the car's own yaw, slides or spins. Without a road, the rotation stays fixed.

#### Scenario: Car spins
- **WHEN** the car spins on a straight
- **THEN** the camera keeps its rotation

#### Scenario: Road turns
- **WHEN** the road turns 90 degrees and the car follows it
- **THEN** the camera rotates with the road, so the road ahead points away from the camera

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
