class_name RoadBumps
extends StaticBody3D
## Low colliders across the road that wheel rays roll over: one bump, or a row every `spacing` m
## over `length` m (cattle grid, washboard). The owning hazard sets `width` to the road width and
## the `surface` metadata to the section's road surface before the bumps enter the tree.

@export var width := 0.0
@export var length := 0.0
@export var height := 0.04
## Distance between bumps; 0 builds one bump at the origin.
@export var spacing := 0.0
@export var depth := 0.1
## A cylinder across the road (log) instead of a box bar.
@export var round := false
@export var color := Color(0.4, 0.4, 0.4)


func _ready() -> void:
	var count := 1 if spacing <= 0.0 else floori(length / spacing) + 1
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	for i in count:
		var z := 0.0 if spacing <= 0.0 else -length / 2.0 + i * spacing
		var collision := CollisionShape3D.new()
		var visual := MeshInstance3D.new()
		if round:
			var shape := CylinderShape3D.new()
			shape.radius = height / 2.0
			shape.height = width
			collision.shape = shape
			var mesh := CylinderMesh.new()
			mesh.top_radius = height / 2.0
			mesh.bottom_radius = height / 2.0
			mesh.height = width
			mesh.material = material
			visual.mesh = mesh
			# The cylinder axis is y; turn it across the road (x).
			collision.transform = Transform3D(Basis(Vector3.BACK, PI / 2.0), Vector3(0.0, height / 2.0, z))
		else:
			var box := BoxShape3D.new()
			box.size = Vector3(width, height, depth)
			collision.shape = box
			var mesh := BoxMesh.new()
			mesh.size = box.size
			mesh.material = material
			visual.mesh = mesh
			collision.position = Vector3(0.0, height / 2.0, z)
		visual.transform = collision.transform
		add_child(collision)
		add_child(visual)
