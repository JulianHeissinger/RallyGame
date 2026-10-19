class_name HazardDef
extends Resource
## One hazard type as data. New types are new `.tres` files in a `StageParams` hazard pool; the
## placer needs no change.

@export var name := ""
## Scene instanced at each placement.
@export var scene: PackedScene
## Never placed below this stage difficulty.
@export var min_difficulty := 1
## Pick weight among the unlocked hazards of the pool.
@export var weight := 1.0
## True: placed on the road with a lateral offset (rock, pothole). False: on the centreline,
## the scene handles its own extent (sheep flock crossing).
@export var on_road := true
## Part group to condition loss, e.g. {"tire": 30.0, "suspension": 15.0}. The hazard maps each
## group to the parts it hits.
@export var damage: Dictionary = {}
