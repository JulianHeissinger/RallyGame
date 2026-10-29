class_name SurfaceSectionDef
extends Resource
## One entry of a stage style's surface table: the road surface, the off-road surface beside it,
## its pick weight and its section length range.

@export var road_surface := "gravel"
@export var terrain_surface := "grass"
@export var weight := 1.0
## Section length range in m (x = min, y = max).
@export var length := Vector2(300.0, 700.0)


static func create(road: String, terrain: String, pick_weight: float, length_range: Vector2) -> SurfaceSectionDef:
	var def := SurfaceSectionDef.new()
	def.road_surface = road
	def.terrain_surface = terrain
	def.weight = pick_weight
	def.length = length_range
	return def
