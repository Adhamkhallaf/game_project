extends Area3D

enum PowerupType { SHIELD, FREEZE, TIME }
var type: PowerupType = PowerupType.SHIELD

func _ready():
	add_to_group("Powerup")
	
	collision_layer = 1
	collision_mask = 0xFFFFFFFF
	
	var mesh_inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 3.0
	
	# Assign shape and color based on type
	if type == PowerupType.SHIELD:
		# Upside down triangle for shield
		var prism = PrismMesh.new()
		prism.size = Vector3(1.0, 1.0, 0.2)
		mesh_inst.mesh = prism
		mesh_inst.rotation_degrees.z = 180 # Point downwards
		mat.albedo_color = Color(0.1, 0.3, 1.0)
		mat.emission = Color(0.1, 0.3, 1.0)
	elif type == PowerupType.FREEZE:
		# Cube for Ice Block
		var box = BoxMesh.new()
		box.size = Vector3(0.8, 0.8, 0.8)
		mesh_inst.mesh = box
		mat.albedo_color = Color(0.1, 1.0, 1.0)
		mat.emission = Color(0.1, 1.0, 1.0)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.8 # Slight transparency for ice
	elif type == PowerupType.TIME:
		# Cylinder for Clock
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.5
		cyl.bottom_radius = 0.5
		cyl.height = 0.15
		mesh_inst.mesh = cyl
		mesh_inst.rotation_degrees.x = 90 # Face camera
		mat.albedo_color = Color(1.0, 0.8, 0.1)
		mat.emission = Color(1.0, 0.8, 0.1)
		
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.7
	col.shape = shape
	add_child(col)
	
	body_entered.connect(_on_body_entered)
	
	# Rotation and floating animation
	var tween = create_tween().set_loops()
	tween.tween_property(mesh_inst, "position:y", 0.3, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(mesh_inst, "position:y", -0.3, 1.0).set_trans(Tween.TRANS_SINE)
	
	var rot_tween = create_tween().set_loops()
	rot_tween.tween_property(mesh_inst, "rotation_degrees:y", 360.0, 2.0).as_relative()

func _on_body_entered(body):
	var is_player = body.is_in_group("Player") or body.name.to_lower().contains("player") or body.name.to_lower().contains("knight")
	if is_player:
		var manager = get_tree().get_first_node_in_group("GameManager")
		if manager and manager.has_method("activate_powerup"):
			manager.activate_powerup(type, global_position)
		queue_free()
