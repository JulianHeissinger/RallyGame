class_name Rockfall
extends ApproachHazard
## Rocks that fall from the verge on a seeded side onto the road on approach. Each rock spawns
## `drop_height` m up beside the road and is thrown toward the road; they stay there as obstacles.
## Like the sheep they live on collision layer 2, so the car hits them but never stands on them.

const STONE := Color(0.45, 0.42, 0.38)

@export var count_range := Vector2i(4, 8)
## Rocks spread over this many m along the road, centred on the placement.
@export var spread_along := 12.0
@export var size_range := Vector2(0.6, 1.0)
## Mass in kg of a 1 m rock; smaller rocks scale with volume.
@export var density := 300.0
@export var drop_height := 8.0
## Spawn distance range in m beyond the road edge.
@export var gap_range := Vector2(2.0, 4.0)
## Speed range in m/s toward the road at spawn.
@export var throw_speed := Vector2(3.0, 6.0)
@export var impact_scale := 0.5

var _rng: RandomNumberGenerator
var _side := 1.0


func _setup(_def: HazardDef, rng: RandomNumberGenerator) -> void:
	_rng = rng
	_side = 1.0 if rng.randf() < 0.5 else -1.0


func _trigger() -> void:
	var material := HazardVisuals.material(STONE)
	for i in _rng.randi_range(count_range.x, count_range.y):
		var along := distance + _rng.randf_range(-spread_along, spread_along) / 2.0
		var size := _rng.randf_range(size_range.x, size_range.y)
		var shape := BoxShape3D.new()
		shape.size = Vector3.ONE * size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var mesh := BoxMesh.new()
		mesh.size = shape.size
		mesh.material = material
		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		var rock := RigidBody3D.new()
		rock.collision_layer = 2
		rock.collision_mask = 3
		rock.mass = density * size * size * size
		rock.set_meta("impact_scale", impact_scale)
		rock.add_child(collision)
		rock.add_child(visual)
		var road := path.transform_at(along)
		var start := verge_point(along, _side, _rng.randf_range(gap_range.x, gap_range.y)) + Vector3.UP * drop_height
		var spin := Basis.from_euler(Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU))
		add_child(rock)
		rock.global_transform = Transform3D(spin, start)
		rock.linear_velocity = -road.basis.x * _side * _rng.randf_range(throw_speed.x, throw_speed.y)
