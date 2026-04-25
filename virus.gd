extends Area3D

var speed = 1.5
var wander_dir = Vector3.ZERO
var wander_timer = 0.0

@onready var manager = get_tree().get_first_node_in_group("GameManager")

func _ready():
	add_to_group("Virus")
	
	# ROOT FIX: Look for collisions on ALL layers in Godot, guaranteeing it detects the player
	# no matter what collision layer the player physically exists on.
	collision_layer = 1
	collision_mask = 0xFFFFFFFF
	
	# Create Mesh
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	mesh_inst.mesh = sphere
	mesh_inst.position.y = 0.6
	
	# Create glowing red material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.1, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.0, 0.0)
	mat.emission_energy_multiplier = 4.0
	mesh_inst.material_override = mat
	add_child(mesh_inst)
	
	# Create Area Collision
	var col = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.7
	col.shape = shape
	col.position.y = 0.6
	add_child(col)
	
	body_entered.connect(_on_body_entered)
	
	_pick_new_dir()

func _pick_new_dir():
	wander_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	wander_timer = randf_range(1.5, 4.0)

var hit_cooldown = 0.0

func _process(delta):
	if manager and manager.has_method("is_frozen") and manager.is_frozen():
		return

	if hit_cooldown > 0:
		hit_cooldown -= delta

	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_dir()
		
	var players = get_tree().get_nodes_in_group("Player")
	var target_dir = wander_dir
	if players.size() > 0:
		var p = players[0]
		if p.global_position.distance_to(global_position) < 20.0:
			var dir_to_p = (p.global_position - global_position)
			dir_to_p.y = 0
			if dir_to_p.length() > 0:
				target_dir = dir_to_p.normalized()
			
	# Smoothly turn
	wander_dir = wander_dir.lerp(target_dir, delta * 3.0).normalized()
	
	# Force flight, manually integrate position since it is an Area3D now
	global_position.y = 2.0
	global_position.x += wander_dir.x * speed * delta
	global_position.z += wander_dir.z * speed * delta

func _on_body_entered(body):
	# Bulletproof check for player
	var is_player = body.is_in_group("Player") or body.name.to_lower().contains("player") or body.name.to_lower().contains("knight")
	
	if hit_cooldown <= 0.0 and is_player:
		if manager and manager.has_method("remove_last_digit"):
			manager.remove_last_digit() # Note: It clears all digits now inside this function
			hit_cooldown = 2.0
