# Spec Delta

## Purpose

Defines the player controls on controller and keyboard, both treated as first-class, in a way that stays open to couch co-op later.

## ADDED Requirements

### Requirement: Driving actions
The game SHALL provide these actions on both controller and keyboard: steer left/right, throttle, brake/reverse, handbrake, activate mounted item, pause, and menu confirm/back.

#### Scenario: Controller driving
- **WHEN** a controller is connected and the player uses the left stick, triggers and buttons
- **THEN** the car steers, accelerates, brakes and handbrakes

#### Scenario: Keyboard driving
- **WHEN** no controller is connected and the player uses the keyboard
- **THEN** all driving actions are available

### Requirement: Analog input on controller
Steering, throttle and brake SHALL be analog on controller, with a small deadzone.

#### Scenario: Partial throttle
- **WHEN** the throttle trigger is half pressed
- **THEN** the car applies about half throttle

### Requirement: Keyboard steering smoothing
On keyboard, steering SHALL ramp toward full lock over time instead of jumping, and ramp back to center when released, with the ramp speed reduced at higher car speed.

#### Scenario: Tap to steer
- **WHEN** the player taps the steer-left key briefly at speed
- **THEN** the steering moves only part of the way to full lock

### Requirement: Per-player input source
Each car SHALL read input from an assigned input source (a device or the keyboard), not from all devices at once.

#### Scenario: Single player any device
- **WHEN** one player plays with no explicit assignment
- **THEN** that player's car accepts both keyboard and the first controller
