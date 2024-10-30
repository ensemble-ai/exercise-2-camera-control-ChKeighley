class_name AutoscrollCamera
extends CameraControllerBase


@export var top_left: Vector2 = Vector2(-15, -10)
@export var bottom_right: Vector2 = Vector2(15, 10)
@export var autoscroll_speed: Vector3 = Vector3(20, 0, 0)

var box_width: float
var box_height: float


func _ready() -> void:
	super()
	position = target.position
	box_width = -top_left.x + bottom_right.x
	box_height = -top_left.y + bottom_right.y
	

func _process(delta: float) -> void:
	if !current:
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()
	
	var current_fps = Engine.get_frames_per_second()
	var tpos = target.global_position
	var cpos = global_position

	global_position.x += autoscroll_speed.x / current_fps
	global_position.z += autoscroll_speed.z / current_fps
	
	#boundary checks
	#left
	#var diff_between_left_edges = (tpos.x - target.WIDTH / 2.0) - (cpos.x - box_width / 2.0)
	var target_left_edge = tpos.x - (target.WIDTH / 2.0)
	var camera_left_edge = cpos.x - (box_width / 2.0)
	if target_left_edge < camera_left_edge:
		target.global_position.x += camera_left_edge - target_left_edge
	#right
	var diff_between_right_edges = (tpos.x - target.WIDTH / 2.0) - (cpos.x + box_width / 2.0)
	if diff_between_right_edges > 0:
		target.global_position.x -= diff_between_right_edges
	#top
	var diff_between_top_edges = (tpos.z - target.HEIGHT / 2.0) - (cpos.z - box_height / 2.0)
	if diff_between_top_edges < 0:
		target.global_position.z -= diff_between_top_edges
	#bottom
	var diff_between_bottom_edges = (tpos.z + target.HEIGHT / 2.0) - (cpos.z + box_height / 2.0)
	if diff_between_bottom_edges > 0:
		target.global_position.z -= diff_between_bottom_edges
		
	super(delta)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left: float = top_left.x
	var right: float = bottom_right.x
	var top: float = top_left.y
	var bottom: float = bottom_right.y
	
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

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
