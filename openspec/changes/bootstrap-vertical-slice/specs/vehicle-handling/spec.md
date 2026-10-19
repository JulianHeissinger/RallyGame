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

### Requirement: Engine and RPM
The car SHALL be all-wheel drive with an engine torque curve. While a gear is engaged, engine RPM SHALL follow the average spin of the driven wheels times the gear ratio and final drive, and SHALL NOT drop below idle RPM. An automatic clutch SHALL slip at low speed so the car can pull away and the engine never stalls. Releasing the throttle in gear SHALL produce engine braking.

#### Scenario: Wheelspin raises RPM
- **WHEN** the driver applies full throttle on a low-grip surface and the driven wheels spin faster than the car moves
- **THEN** engine RPM rises above the RPM that matches the car's road speed

#### Scenario: Engine braking
- **WHEN** the driver lifts off the throttle in gear at speed without braking
- **THEN** the car slows down faster than when coasting in neutral

#### Scenario: Launch without stall
- **WHEN** the car is at standstill in 1st gear and the driver applies throttle
- **THEN** the car pulls away and the engine does not stall

### Requirement: Rev limiter
When engine RPM reaches the redline, drive torque SHALL be cut until RPM falls a small margin below the redline, and then restored.

#### Scenario: Limiter bounce
- **WHEN** the driver holds full throttle in one gear until the redline
- **THEN** RPM oscillates just below the redline and the car does not exceed that gear's top speed

### Requirement: Gearbox
The gearbox SHALL have reverse, neutral and forward gears with ratios defined as car data. Each shift SHALL take a shift time (car data) during which no drive torque reaches the wheels. Each completed shift SHALL emit a gear-shift event.

#### Scenario: Torque cut during shift
- **WHEN** a shift starts
- **THEN** no drive torque reaches the wheels until the shift time has passed and the new gear is engaged

### Requirement: Gearbox modes
The gearbox SHALL support an automatic mode and a manual mode, selected by a player setting. In automatic mode the gearbox SHALL shift up and down by engine RPM, and reverse SHALL engage when braking at near standstill. In manual mode the player SHALL shift with shift up and shift down; shifting down from 1st SHALL select neutral and then reverse, reverse SHALL only engage at near standstill, and brake SHALL NOT engage reverse.

#### Scenario: Accelerate from standstill
- **WHEN** the gearbox is automatic and the driver holds full throttle from standstill on a flat road
- **THEN** the car accelerates, shifts up through gears, and reaches a top speed it does not exceed

#### Scenario: Reverse
- **WHEN** the gearbox is automatic, the car is near standstill and the driver holds brake
- **THEN** the car drives backwards

#### Scenario: Manual shift up
- **WHEN** the gearbox is manual, the car is in 2nd gear and the driver presses shift up
- **THEN** the gearbox engages 3rd gear after the shift time

#### Scenario: Manual reverse
- **WHEN** the gearbox is manual, the car is near standstill in 1st gear and the driver presses shift down twice
- **THEN** the gearbox selects neutral, then reverse, and throttle drives the car backwards

#### Scenario: Reverse refused while moving
- **WHEN** the gearbox is manual, the car is in neutral at speed and the driver presses shift down
- **THEN** the gearbox stays in neutral

#### Scenario: Over-rev downshift refused
- **WHEN** the gearbox is manual and a downshift would put engine RPM above the redline
- **THEN** the gearbox stays in the current gear

### Requirement: Handbrake
A handbrake input SHALL lock the rear wheels while held, reducing rear grip so the car can rotate into tight corners.

#### Scenario: Handbrake hairpin
- **WHEN** the driver pulls the handbrake while steering at moderate speed
- **THEN** the rear slides out and the car rotates faster than with steering alone

### Requirement: Realistic rotation speed
The car's rotation when thrown into a slide SHALL come from its physical properties (mass, inertia, grip) and never snap to a forced drift angle. While the driver steers, a steering yaw assist MAY add a limited yaw torque toward a yaw rate set by the steering input, so the car holds a light, controllable drift and countersteer catches it. Without steering input the assist SHALL be off.

#### Scenario: No arcade spin assist
- **WHEN** the car slides with no driver input
- **THEN** its rotation slows down only through tire forces and does not snap to a preset drift angle

#### Scenario: Assist follows steering
- **WHEN** the driver steers into a corner and then countersteers
- **THEN** the assist first adds rotation toward the corner and then works against the slide

### Requirement: Tunable car parameters
Car handling parameters (mass, power, grip, suspension, steering) SHALL be data that can be changed without code changes, so items and damage can modify them at runtime.

#### Scenario: Runtime grip change
- **WHEN** a tire's grip value is reduced at runtime
- **THEN** that wheel immediately produces less grip
