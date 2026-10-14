# Spec Delta

## Purpose

Defines how the player's rally car moves: semi-sim handling where grip, sliding and weight transfer behave close to a real car, so real rally techniques work.

## ADDED Requirements

### Requirement: Per-wheel suspension
Each of the four wheels SHALL have independent suspension that keeps the car resting on uneven ground and reacts to bumps, crests and landings.

#### Scenario: Car rests on a slope
- **WHEN** the car is placed at rest on a sloped surface
- **THEN** all four wheels touch the ground and the body settles without bouncing indefinitely

#### Scenario: Wheel leaves the ground
- **WHEN** a wheel loses ground contact (e.g. over a crest)
- **THEN** that wheel produces no grip force until it touches the ground again

### Requirement: Slip-based tire grip
Tire forces SHALL depend on wheel slip (lateral slip angle and longitudinal slip ratio) and on the vertical load on that wheel, with grip peaking at a moderate slip and falling off beyond it.

#### Scenario: Gentle cornering grips
- **WHEN** the car turns gently at moderate speed on gravel
- **THEN** the car follows the steering with little sliding

#### Scenario: Over the limit slides
- **WHEN** the car enters a corner too fast with full steering
- **THEN** the tires exceed peak slip, grip drops, and the car slides

### Requirement: Weight transfer
Braking, acceleration and cornering SHALL shift vertical load between wheels, and the shifted load SHALL change each wheel's available grip.

#### Scenario: Lift-off rotation
- **WHEN** the driver brakes sharply while turning in
- **THEN** load moves to the front wheels, rear grip drops, and the car rotates more than at a constant throttle

#### Scenario: Scandinavian flick
- **WHEN** the driver steers away from a corner, then sharply into it
- **THEN** the load swing makes the rear step out and the car rotates into the corner

### Requirement: Surface grip
Each wheel SHALL use the grip of the surface it touches, so that off-road ground grips less than the road.

#### Scenario: Wheels on grass
- **WHEN** two wheels leave the road onto off-road terrain
- **THEN** those wheels have less grip than the wheels still on the road

### Requirement: Drivetrain and gears
The car SHALL be all-wheel drive with an engine torque curve and an automatic gearbox that shifts up and down by engine speed, and reverse SHALL engage when braking at near standstill.

#### Scenario: Accelerate from standstill
- **WHEN** the driver holds full throttle from standstill on a flat road
- **THEN** the car accelerates, shifts up through gears, and reaches a top speed it does not exceed

#### Scenario: Reverse
- **WHEN** the car is near standstill and the driver holds brake
- **THEN** the car drives backwards

### Requirement: Handbrake
A handbrake input SHALL lock the rear wheels while held, reducing rear grip so the car can rotate into tight corners.

#### Scenario: Handbrake hairpin
- **WHEN** the driver pulls the handbrake while steering at moderate speed
- **THEN** the rear slides out and the car rotates faster than with steering alone

### Requirement: Realistic rotation speed
The car's rotation when thrown into a slide SHALL be limited by its physical properties (mass, inertia, grip) with no artificial yaw boost or forced drift angle.

#### Scenario: No arcade spin assist
- **WHEN** the car slides with no driver input
- **THEN** its rotation slows down only through tire forces and does not snap to a preset drift angle

### Requirement: Tunable car parameters
Car handling parameters (mass, power, grip, suspension, steering) SHALL be data that can be changed without code changes, so items and damage can modify them at runtime.

#### Scenario: Runtime grip change
- **WHEN** a tire's grip value is reduced at runtime
- **THEN** that wheel immediately produces less grip
