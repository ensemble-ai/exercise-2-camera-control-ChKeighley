class_name FourWaySpeedupPushBox
extends CameraControllerBase


enum Direction {
	LEFT,
	RIGHT,
	TOP,
	BOTTOM,
}

@export var push_ratio: float
@export var pushbox_top_left: Vector2
@export var pushbox_bottom_right: Vector2
@export var speedup_zone_top_left: Vector2
@export var speedup_zone_bottom_right: Vector2

var pushbox_width: float
var pushbox_height: float
var speedup_width: float
var speedup_height: float


func _ready() -> void:
	super()
	position = target.position
	pushbox_width = -pushbox_top_left.x + pushbox_bottom_right.x
	pushbox_height = -pushbox_top_left.y + pushbox_bottom_right.y
	speedup_width = -speedup_zone_top_left.x + speedup_zone_bottom_right.x
	speedup_height = -speedup_zone_top_left.y + speedup_zone_bottom_right.y
	

func _process(delta: float) -> void:
	if !current:
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()
	
	var tpos: Vector3 = target.global_position
	var cpos: Vector3 = global_position
	var target_left: float = tpos.x - target.WIDTH / 2.0
	var target_right: float = tpos.x + target.WIDTH / 2.0
	var target_top: float = tpos.z - target.HEIGHT / 2.0
	var target_bottom: float = tpos.z + target.HEIGHT / 2.0
	
	#boundary checks
	#left
	var diff_between_left_edges = target_left - (cpos.x - pushbox_width / 2.0)
	var	diff_between_left_speedup_edges = target_left - (cpos.x - speedup_width / 2.0)
	if diff_between_left_edges < 0:
		global_position.x += diff_between_left_edges
	elif diff_between_left_speedup_edges < 0 and target.velocity.x < 0:
		_speedup_in_direction(Direction.LEFT, target.velocity.x * push_ratio, delta)
		
	#right
	var diff_between_right_edges = target_right - (cpos.x + pushbox_width / 2.0)
	var	diff_between_right_speedup_edges = target_right - (cpos.x + speedup_width / 2.0)
	if diff_between_right_edges > 0:
		global_position.x += diff_between_right_edges
	elif diff_between_right_speedup_edges > 0 and target.velocity.x > 0:
		_speedup_in_direction(Direction.RIGHT, target.velocity.x * push_ratio, delta)
		
	#top
	var diff_between_top_edges = target_top - (cpos.z - pushbox_height / 2.0)
	var	diff_between_top_speedup_edges = target_top - (cpos.z - speedup_height / 2.0)
	if diff_between_top_edges < 0:
		global_position.z += diff_between_top_edges
	elif diff_between_top_speedup_edges < 0 and target.velocity.z < 0:
		_speedup_in_direction(Direction.TOP, target.velocity.z * push_ratio, delta)
		
	#bottom
	var diff_between_bottom_edges = target_bottom - (cpos.z + pushbox_height / 2.0)
	var	diff_between_bottom_speedup_edges = target_bottom - (cpos.z + speedup_height / 2.0)
	if diff_between_bottom_edges > 0:
		global_position.z += diff_between_bottom_edges
	elif diff_between_bottom_speedup_edges > 0 and target.velocity.z > 0:
		_speedup_in_direction(Direction.BOTTOM, target.velocity.z * push_ratio, delta)

	super(delta)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left: float = -pushbox_width / 2
	var right: float = pushbox_width / 2
	var top: float = -pushbox_height / 2
	var bottom: float = pushbox_height / 2
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_end()
	
	# Show speedup zone box
	left = -speedup_width / 2
	right = speedup_width / 2
	top = -speedup_height / 2
	bottom = speedup_height / 2
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	
	immediate_mesh.surface_add_vertex(Vector3(left, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, top))
	immediate_mesh.surface_end()
	# End speedup zone box

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()


func _speedup_in_direction(dir: Direction, speed: float, delta: float) -> void:
	match dir:
		Direction.LEFT:
			global_position.x = global_position.x + -1 * abs(speed) * delta
		Direction.RIGHT:
			global_position.x = global_position.x + 1 * abs(speed) * delta
		Direction.TOP:
			global_position.z = global_position.z + -1 * abs(speed) * delta
		Direction.BOTTOM:
			global_position.z = global_position.z + 1 * abs(speed) * delta
