extends Area3D

@export var value: String = "1"

@onready var text_mesh = $Number

func _ready():
	text_mesh.mesh.text = value
	
	$AnimationPlayer.play("idle")
	
func _on_body_entered(body):
	if body.name == "Knight":
		print("Collected: ", value)
		queue_free()
