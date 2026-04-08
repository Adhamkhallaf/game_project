extends Area3D

@export var value: String = "1"

@onready var text_mesh = $Number

func _ready():
	_update_text()
	$AnimationPlayer.play("idle")

func _update_text():
	if text_mesh and text_mesh.mesh:
		text_mesh.mesh.text = value

func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("Character collected: ", value)
		queue_free()
