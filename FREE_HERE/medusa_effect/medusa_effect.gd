@tool
extends Node3D
@onready var sample: VoronoiShatter = $Sample

@onready var fractured_meshes: VoronoiCollection 
@onready var final_meshes: Node3D = $FinalMeshes
@onready var calculate_mesh: MeshInstance3D = $Sample/CalculateMesh
@onready var skin: Node3D = $SophiaSkin




func generate_rigid(delay_time: float) -> void:
	await get_tree().create_timer(delay_time).timeout
	calculate_mesh.mesh =  skin.mesh.bake_mesh_from_current_skeleton_pose()
	print(calculate_mesh)
	calculate_mesh.visible = true
	sample.execute()
	await get_tree().create_timer(0.5).timeout
	skin.visible = false
	fractured_meshes = sample.get_child(1)
	var meshes = fractured_meshes.find_children("*", "MeshInstance3D")
	
	if meshes.is_empty():
		print("Không tìm thấy mesh nào!")
		return

	var scene_root = get_tree().edited_scene_root

	for mesh: MeshInstance3D in meshes:
		# 1. Tạo RigidBody3D
		var rigid_body: RigidBody3D = RigidBody3D.new()
		final_meshes.add_child(rigid_body)	
		rigid_body.owner = scene_root # Để hiện lên Editor
		rigid_body.name = "Rigid_" + mesh.name
		
		# Giữ nguyên vị trí toàn cầu của mảnh vỡ
		var global_pos = mesh.global_transform
		
		# 2. Chuyển Mesh sang RigidBody (Dùng cách thủ công an toàn hơn reparent trong tool)
		mesh.get_parent().remove_child(mesh)
		rigid_body.add_child(mesh)
		mesh.owner = scene_root
		mesh.transform = Transform3D.IDENTITY # Reset local transform vì cha nó (Rigid) sẽ giữ vị trí
		
		# Cập nhật vị trí cho RigidBody đúng chỗ mảnh vỡ cũ
		rigid_body.global_transform = global_pos

		# 3. Tạo CollisionShape3D từ dữ liệu Mesh (Resource)
		var collision_node: CollisionShape3D = CollisionShape3D.new()
		
		# SỬA LỖI TẠI ĐÂY: Dùng create_convex_shape() từ Mesh resource
		if mesh.mesh:
			var convex_shape = mesh.mesh.create_convex_shape() 
			collision_node.shape = convex_shape
			
			rigid_body.add_child(collision_node)
			rigid_body.mass = 3.0
			collision_node.owner = scene_root
			collision_node.name = "Collision"
		
		print("Đã xử lý xong: ", mesh.name)

	
func set_rigid_sleeping(root: Node3D, sleep_state: bool = false) -> void:
	var rigids = root.find_children("*", "RigidBody3D", true, false)
	for rigid: RigidBody3D in rigids:
		rigid.sleeping = sleep_state
		
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		skin.motion_freeze()
		generate_rigid(skin.linger_time)
		
	if Input.is_action_just_pressed("action"):
		skin.motion_unfreeze()

@export_tool_button("Generate Rigid") 
var _generate_rigid = generate_rigid
