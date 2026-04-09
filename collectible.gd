extends Area3D

@export var value: String = "1"

@onready var text_mesh = $Number

func _ready():
	if text_mesh and text_mesh.mesh:
		text_mesh.mesh = text_mesh.mesh.duplicate()
		text_mesh.mesh.text = value
	$AnimationPlayer.play("idle")

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var manager = get_tree().get_first_node_in_group("GameManager")
		if manager:
			manager.add_to_collection(value)
		queue_free()
