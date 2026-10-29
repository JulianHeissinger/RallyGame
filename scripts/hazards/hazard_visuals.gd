class_name HazardVisuals
## Placeholder visuals shared by hazards: outlines that contrast with the road, edge posts and
## the roadside warning sign.

## Outline colours: light on dark roads, dark on light roads.
const LIGHT := Color(0.95, 0.95, 0.9)
const DARK := Color(0.08, 0.08, 0.08)
const OUTLINE_WIDTH := 0.25
const POST_SIZE := Vector3(0.15, 1.0, 0.15)
## Gap in m between the hazard's edge and its edge posts.
const POST_GAP := 0.3
const SIGN_DISTANCE := 40.0
## Sign position beyond the road edge, in m.
const SIGN_OFFSET := 2.5
const SIGN_POLE_HEIGHT := 1.6
const SIGN_SIZE := Vector3(1.4, 1.2, 0.05)
const SIGN_RED := Color(0.8, 0.1, 0.1)
const SIGN_WHITE := Color(0.95, 0.95, 0.95)


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


## Red-bordered triangle on a pole with `text` below it, facing traffic. Visual only.
static func warning_sign(text: String) -> Node3D:
	var board := Node3D.new()
	board.name = "Sign"
	var pole := BoxMesh.new()
	pole.size = Vector3(0.08, SIGN_POLE_HEIGHT, 0.08)
	pole.material = material(Color(0.5, 0.5, 0.5))
	var pole_instance := MeshInstance3D.new()
	pole_instance.mesh = pole
	pole_instance.position = Vector3.UP * SIGN_POLE_HEIGHT / 2.0
	board.add_child(pole_instance)
	for layer in 2:
		var prism := PrismMesh.new()
		prism.size = SIGN_SIZE * (Vector3(0.72, 0.72, 1.0) if layer == 1 else Vector3.ONE)
		prism.material = material(SIGN_WHITE if layer == 1 else SIGN_RED)
		var instance := MeshInstance3D.new()
		instance.mesh = prism
		instance.position = Vector3(0.0, SIGN_POLE_HEIGHT + SIGN_SIZE.y / 2.0 - layer * 0.08, layer * 0.03)
		board.add_child(instance)
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 96
	label.outline_size = 24
	label.pixel_size = 0.01
	label.modulate = SIGN_WHITE
	label.outline_modulate = DARK
	label.no_depth_test = false
	label.position = Vector3.UP * (SIGN_POLE_HEIGHT + SIGN_SIZE.y + 0.5)
	board.add_child(label)
	return board
