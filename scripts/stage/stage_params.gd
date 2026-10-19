class_name StageParams
extends Resource
## Layout tuning for one stage style. Defaults are the prototype stage; countries get their own `.tres` later.

@export_group("Length")
@export var target_length := 2000.0
@export var sample_spacing := 2.0

@export_group("Width")
@export var road_width_min := 6.0
@export var road_width_max := 10.0
## Distance between random width values along the road; the width blends smoothly between them.
@export var width_wavelength := 150.0
## Rare narrow sections. Chance is per started kilometre of road.
@export var pinch_chance_per_km := 0.3
@export var pinch_width := 2.0
@export var pinch_length := Vector2(10.0, 30.0)
## Distance over which the road narrows into and widens out of a pinch.
@export var pinch_taper := 10.0

@export_group("Segments")
## Each type has a pick weight and ranges (x = min, y = max): lengths and radii in m, angles in degrees.
@export var straight_weight := 3.0
@export var straight_length := Vector2(40.0, 150.0)
@export var fast_arc_weight := 3.0
@export var fast_arc_radius := Vector2(60.0, 150.0)
@export var fast_arc_angle := Vector2(20.0, 60.0)
@export var tight_arc_weight := 2.0
@export var tight_arc_radius := Vector2(20.0, 40.0)
@export var tight_arc_angle := Vector2(45.0, 90.0)
@export var hairpin_weight := 1.0
@export var hairpin_radius := Vector2(12.0, 15.0)
@export var hairpin_angle := Vector2(160.0, 180.0)
@export var min_hairpins := 1
## Fraction of `target_length` after which missing hairpins are forced.
@export var hairpin_force_after := 0.6

@export_group("Validation")
## Minimum centre-to-centre distance between separate parts of the road.
## Keep it above `road_width_max` and below `2 * hairpin_radius.x`, or hairpins never fit.
@export var min_clearance := 16.0
@export var max_segment_retries := 10
@export var max_regenerations := 20
