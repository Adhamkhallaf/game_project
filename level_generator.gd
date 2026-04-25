extends Node3D

var floor_scene = preload("res://assets/KayKit_Adventurers_2.0_FREE/Characters/gltf/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/floor_foundation_allsides.gltf")
var wall_scene  = preload("res://assets/KayKit_Adventurers_2.0_FREE/Characters/gltf/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/wall.gltf")
var door_scene  = preload("res://assets/KayKit_Adventurers_2.0_FREE/Characters/gltf/KayKit_DungeonRemastered_1.1_FREE/Assets/gltf/wall_doorway.gltf")

var grid_w = 8
var grid_h = 16

# The physical size of one tile depends on its scale. Currently it's ~ 2.0 or 4.0?
# The wall.gltf usually assumes 4x4 or 2x2. Let's use standard step of 4.0
var step = 4.0

var gate_node: StaticBody3D

func _ready():
	_build_level()

func _build_level():
	# Clean any manual walls just in case they were left in
	# Building from x = -grid_w/2 to x = grid_w/2
	# and z = -8 to z = 8
	var h_w = int(grid_w / 2)
	var start_z = -12
	var end_z = 10
	
	for x in range(-h_w, h_w + 1):
		for z in range(start_z, end_z + 1):
			# Floor
			var f = floor_scene.instantiate()
			f.position = Vector3(x * step, 0, z * step)
			add_child(f)
			f.scale = Vector3(1, 1, 1)

			# Walls
			if x == -h_w:
				_spawn_wall(Vector3(x * step - step/2, 0, z * step), 90)
			if x == h_w:
				_spawn_wall(Vector3(x * step + step/2, 0, z * step), -90)
				
			if z == start_z:
				_spawn_wall(Vector3(x * step, 0, z * step - step/2), 0)
			if z == end_z:
				_spawn_wall(Vector3(x * step, 0, z * step + step/2), 180)
			
			# Middle division at z = 0
			if z == 0:
				if x == 0: # Door in the middle
					# We DO NOT instance wall_doorway.gltf because its collision blocks the player entirely.
					# We just put our block gate. The gap visually serves as the open door!
					_create_gate(Vector3(x * step, 0, z * step + step/2))
				else:
					_spawn_wall(Vector3(x * step, 0, z * step + step/2), 0)

func _spawn_wall(pos: Vector3, rot_deg: float):
	var w = wall_scene.instantiate()
	w.position = pos
	w.rotation_degrees = Vector3(0, rot_deg, 0)
	add_child(w)

func _create_gate(pos: Vector3):
	gate_node = StaticBody3D.new()
	gate_node.position = pos + Vector3(0, 2, 0)
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(4, 4, 1)
	col.shape = box
	gate_node.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(4, 4, 1)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	mesh.material = mat
	mesh_inst.mesh = mesh
	gate_node.add_child(mesh_inst)
	
	add_child(gate_node)

func open_door():
	if gate_node:
		if AudioManager:
			AudioManager.play("door")
		gate_node.queue_free()
		gate_node = null
