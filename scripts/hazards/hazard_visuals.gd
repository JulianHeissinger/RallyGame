class_name HazardVisuals
## Placeholder visuals shared by hazards: outlines that contrast with the road and edge posts.

## Outline colours: light on dark roads, dark on light roads.
const LIGHT := Color(0.95, 0.95, 0.9)
const DARK := Color(0.08, 0.08, 0.08)
const OUTLINE_WIDTH := 0.25
const POST_SIZE := Vector3(0.15, 1.0, 0.15)
## Gap in m between the hazard's edge and its edge posts.
const POST_GAP := 0.3


static func material(color: Color, glossy: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	if color.a < 1.0:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glossy:
		result.roughness = 0.05
		result.metallic = 0.4
	return result


## Outline colour that stands out against `surface`'s road colour.
static func contrast(surface: String) -> Color:
	return DARK if Surface.COLOR[surface].get_luminance() > 0.5 else LIGHT


## Flat disc (`size` = Vector2.ZERO) or rectangle, `width` larger than the footprint, just under
## a patch at `lift`, so it shows as a ring around it.
static func outline(radius: float, size: Vector2, color: Color, lift: float) -> MeshInstance3D:
	var mesh: PrimitiveMesh
	if size != Vector2.ZERO:
		var box := BoxMesh.new()
		box.size = Vector3(size.x + 2.0 * OUTLINE_WIDTH, 0.01, size.y + 2.0 * OUTLINE_WIDTH)
		mesh = box
	else:
		var disc := CylinderMesh.new()
		disc.top_radius = radius + OUTLINE_WIDTH
		disc.bottom_radius = radius + OUTLINE_WIDTH
		disc.height = 0.01
		mesh = disc
	mesh.material = material(color)
	var instance := MeshInstance3D.new()
	instance.name = "Outline"
	instance.mesh = mesh
	instance.position = Vector3.UP * lift
	return instance


## Two posts just beyond `half_width` on both sides.
static func edge_posts(half_width: float, color: Color) -> Node3D:
	var posts := Node3D.new()
	posts.name = "EdgePosts"
	for side in [-1.0, 1.0]:
		var mesh := BoxMesh.new()
		mesh.size = POST_SIZE
		mesh.material = material(color)
		var post := MeshInstance3D.new()
		post.mesh = mesh
		post.position = Vector3(side * (half_width + POST_GAP + POST_SIZE.x / 2.0), POST_SIZE.y / 2.0, 0.0)
		posts.add_child(post)
	return posts

