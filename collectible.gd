extends Area3D

@export var value: String = "1"

@onready var text_mesh = $Number

func _ready():
	if text_mesh and text_mesh.mesh:
		text_mesh.mesh = text_mesh.mesh.duplicate()
		text_mesh.mesh.text = value
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 1.0, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(0.1, 1.0, 0.1)
		mat.emission_energy_multiplier = 3.0
		text_mesh.material_override = mat
		
	$AnimationPlayer.play("idle")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var manager = get_tree().get_first_node_in_group("GameManager")
		if manager:
			if manager.has_method("add_to_collection_with_pos"):
				manager.add_to_collection_with_pos(value, global_position)
			else:
				manager.add_to_collection(value)
		queue_free()
