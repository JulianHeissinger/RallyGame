class_name StageParams
extends Resource
## Layout tuning for one stage style. Defaults are the prototype stage; countries get their own `.tres` later.

@export_group("Length")
@export var target_length := 4000.0
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

@export_group("Elevation")
## Low-frequency base height: amplitude in m, wavelength in m along the road.
@export var elevation_amplitude := 6.0
@export var elevation_wavelength := 400.0
## Steepest allowed rise or fall per metre, so slopes stay readable from the iso camera.
@export var max_gradient := 0.12
@export var crests_per_km := 1.5
@export var min_crests := 1
## Crest flank gradient and total length in m. A crest is a sharp change from rising to falling.
@export var crest_gradient := Vector2(0.08, 0.12)
@export var crest_length := Vector2(40.0, 80.0)
## Rounds the crest top over about this many metres.
@export var crest_top_radius := 4.0

@export_group("Terrain")
## Terrain extends this far in m beyond the road bounds.
@export var terrain_margin := 100.0
@export var terrain_cell := 2.0
@export var terrain_amplitude := 4.0
@export var terrain_wavelength := 200.0
## Terrain sits this far in m below the road, and the road edge bevels down to it.
@export var road_sink := 0.2
@export var road_bevel := 1.0
## Distance in m beyond the bevel over which the terrain blends from road height to its own.
@export var terrain_blend := 40.0
## Seconds added when the car falls out of the world and is put back on the road.
@export var respawn_penalty := 10.0

@export_group("Surfaces")
## Weighted surface table the road sections are drawn from. Neighbouring sections may repeat a surface.
@export var surfaces: Array[SurfaceSectionDef] = []
## A last section shorter than this in m merges into the one before it.
@export var min_section_length := 100.0

@export_group("Hazards")
## Hazard pool for this stage style; locked entries are skipped below their `min_difficulty`.
## Filled with the prototype hazards in `_init`.
@export var hazards: Array[HazardDef] = []
## Hazards per km of usable road at difficulty 1.
@export var hazards_per_km := 4.0
## Extra hazards per difficulty step above 1, as a share of the difficulty 1 count.
@export var hazard_difficulty_scale := 0.5
## Minimum distance in m along the road between two hazards.
@export var hazard_min_spacing := 40.0
## On-road hazards keep this far in m from the road edge.
@export var hazard_edge_margin := 1.0

@export_group("Malfunctions")
## Malfunctions per km of usable road at difficulty 1, scaled by `hazard_difficulty_scale`; at least one.
@export var malfunctions_per_km := 0.75
## Condition loss range of one malfunction (x = min, y = max).
@export var malfunction_damage := Vector2(20.0, 40.0)
## Minimum distance in m along the road between two malfunctions.
@export var malfunction_min_spacing := 200.0

@export_group("Props")
## Jittered grid spacing in m; each cell holds at most one prop.
@export var prop_cell := 6.0
## Props are placed up to this far in m from the road edge.
@export var prop_max_distance := 40.0
## Free space in m between the bevel and a prop's footprint.
@export var prop_road_clearance := 2.0
## Chance that a grid cell holds a prop.
@export var prop_density := 0.25
## Extra keep chance on corner outsides, as a multiple of `prop_density`, at full strength.
@export var corner_density_boost := 2.0
## Corners this tight in m or tighter get the full boost; wider corners get less.
@export var corner_full_boost_radius := 20.0
## The boost fades out over this distance in m from the road edge.
@export var corner_band := 20.0
@export var tree_weight := 3.0
@export var rock_weight := 2.0
@export var fence_weight := 1.0

@export_group("Spectators")
## Clusters on the outside of sharp corners per km, on top of the start, finish and crest clusters.
@export var spectator_clusters_per_km := 3.0
## Corners this tight in m or tighter get clusters.
@export var spectator_corner_radius := 40.0
@export var spectator_cluster_size := Vector2i(5, 20)
## Cluster length in m along the road.
@export var spectator_cluster_spread := 15.0
## Minimum distance in m along the road between two clusters.
@export var spectator_cluster_min_spacing := 100.0
## Distance range in m along the road between two spread spectators.
@export var spectator_spacing := Vector2(20.0, 40.0)
## Minimum distance in m from the road edge; spots lie up to `spectator_depth` m further out.
@export var spectator_gap := 5.0
@export var spectator_depth := 6.0

@export_group("Validation")
## Minimum centre-to-centre distance between separate parts of the road.
## Keep it above `road_width_max` and below `2 * hairpin_radius.x`, or hairpins never fit.
@export var min_clearance := 16.0
@export var max_segment_retries := 10
@export var max_regenerations := 20


## Default surface table and hazard pool for the prototype stage. A `.tres` that sets them replaces them.
func _init() -> void:
	hazards = [
		preload("res://data/hazards/rock.tres"),
		preload("res://data/hazards/pothole.tres"),
		preload("res://data/hazards/sheep_flock.tres"),
		preload("res://data/hazards/nails.tres"),
		preload("res://data/hazards/glass.tres"),
		preload("res://data/hazards/log.tres"),
		preload("res://data/hazards/cattle_grid.tres"),
		preload("res://data/hazards/washboard.tres"),
		preload("res://data/hazards/oil.tres"),
		preload("res://data/hazards/puddle.tres"),
		preload("res://data/hazards/mud.tres"),
		preload("res://data/hazards/black_ice.tres"),
		preload("res://data/hazards/banana.tres"),
		preload("res://data/hazards/ford.tres"),
		preload("res://data/hazards/marbles.tres"),
		preload("res://data/hazards/tar.tres"),
		preload("res://data/hazards/snow_drift.tres"),
		preload("res://data/hazards/fallen_tree.tres"),
		preload("res://data/hazards/crashed_car.tres"),
		preload("res://data/hazards/hay_bales.tres"),
		preload("res://data/hazards/cones.tres"),
		preload("res://data/hazards/wheelie_bins.tres"),
		preload("res://data/hazards/shopping_trolleys.tres"),
		preload("res://data/hazards/portable_toilet.tres"),
		preload("res://data/hazards/explosive_barrel.tres"),
		preload("res://data/hazards/ramp.tres"),
		preload("res://data/hazards/fire_patch.tres"),
		preload("res://data/hazards/burning_car.tres"),
		preload("res://data/hazards/landmine.tres"),
		preload("res://data/hazards/sinkhole.tres"),
		preload("res://data/hazards/meteorite.tres"),
		preload("res://data/hazards/lightning.tres"),
		preload("res://data/hazards/spectator.tres"),
		preload("res://data/hazards/crowd_surge.tres"),
		preload("res://data/hazards/streaker.tres"),
		preload("res://data/hazards/mascot.tres"),
		preload("res://data/hazards/rockfall.tres"),
		preload("res://data/hazards/falling_tree.tres"),
		preload("res://data/hazards/cheese_wheel.tres"),
		preload("res://data/hazards/runaway_wheel.tres"),
		preload("res://data/hazards/tumbleweed.tres"),
		preload("res://data/hazards/cow_herd.tres"),
		preload("res://data/hazards/chicken_flock.tres"),
		preload("res://data/hazards/moose_crossing.tres"),
		preload("res://data/hazards/kangaroos.tres"),
		preload("res://data/hazards/marching_band.tres"),
		preload("res://data/hazards/wind_gust.tres"),
		preload("res://data/hazards/steam_geyser.tres"),
		preload("res://data/hazards/dust_devil.tres"),
		preload("res://data/hazards/helicopter.tres"),
		preload("res://data/hazards/fog_bank.tres"),
		preload("res://data/hazards/paparazzi.tres"),
		preload("res://data/hazards/fan_fireworks.tres"),
	]
	surfaces = [
		SurfaceSectionDef.create("gravel", "grass", 1.0, Vector2(300.0, 700.0)),
		SurfaceSectionDef.create("tarmac", "grass", 1.0, Vector2(300.0, 700.0)),
		SurfaceSectionDef.create("snow", "snow", 1.0, Vector2(300.0, 700.0)),
	]
