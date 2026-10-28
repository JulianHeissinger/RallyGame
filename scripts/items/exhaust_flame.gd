class_name ExhaustFlame
extends MeshInstance3D
## Placeholder flame cone behind the car's exhaust that frees itself after its time.

## Exhaust position in car space (the body ends at z = 2, the back is +z).
const OFFSET := Vector3(0.45, -0.05, 2.5)


static func spawn(car: Node3D, time: float) -> void:
	var flame := ExhaustFlame.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.22
	cone.height = 1.0
	cone.radial_segments = 8
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.55, 0.1)
	cone.material = material
	flame.mesh = cone
	# The cone's tip points along +y; turn it to point backward (+z).
	flame.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), OFFSET)
	car.add_child(flame)
	car.get_tree().create_timer(time, false).timeout.connect(flame.queue_free)
