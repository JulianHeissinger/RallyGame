class_name CarStats
extends Resource
## Base car constants, keyed by stat name. `StatBlock` layers item and damage modifiers on top.

@export var stats: Dictionary = {}
## Engine torque as a fraction of `max_torque` (y) over RPM as a fraction of redline (x).
@export var torque_curve: Curve
