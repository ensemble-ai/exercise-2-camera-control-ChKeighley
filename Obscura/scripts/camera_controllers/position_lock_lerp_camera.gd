class_name PositionLockLerpCamera
extends CameraControllerBase


@export var follow_speed: float = 35.0
@export var catchup_speed: float = 70.0
@export var leash_distance: float = 40.0


func _ready() -> void:
	super()
	position = target.position
	

func _process(delta: float) -> void:
	if !current:
		position = target.position
		return
	
	if draw_camera_logic:
		draw_logic()
	
	var tpos_xz: Vector3 = Vector3(target.global_position.x, 0, target.global_position.z)
	var tspeed: float = target.speed
	var cpos_xz: Vector3 = Vector3(global_position.x, 0, global_position.z)
	
	var target_distance: float = tpos_xz.distance_to(cpos_xz)
	var target_unmoving: bool = is_zero_approx(target.velocity.x) and is_zero_approx(target.velocity.z)
	
	if target_distance <= 1 and target_unmoving:
		position = target.position
	elif target_unmoving:
		_follow_target(tpos_xz, cpos_xz, catchup_speed, delta)
	elif target_distance >= leash_distance:
		_follow_target(tpos_xz, cpos_xz, tspeed, delta)
	else:
		_follow_target(tpos_xz, cpos_xz, follow_speed, delta)
		
	super(delta)


func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var line_length: float = 10.0

	var left: float = -line_length / 2
	var right: float = line_length / 2
	var top: float = -line_length / 2
	var bottom: float = line_length / 2
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(0, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, bottom))
	
	immediate_mesh.surface_add_vertex(Vector3(right, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, 0))
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()


func _follow_target(tpos: Vector3, cpos: Vector3, speed: float, delta: float) -> void:
	var direction = (tpos - cpos).normalized()
	
	if direction:
		global_position = global_position + direction * speed * delta
