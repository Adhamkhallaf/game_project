extends Node3D

@export var bubble_scene: PackedScene 
@export var current_target_system = "BIN" 

var systems = {
	"BIN": ["0", "1"],
	"OCT": ["0", "1", "2", "3", "4", "5", "6", "7"],
	"DEC": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
	"HEX": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
}

func _ready():
	randomize()
	spawn_bubbles(20)

func spawn_bubbles(count: int):
	if not systems.has(current_target_system):
		print("Error: System name is incorrect in Inspector!")
		return
		
	var pool = systems[current_target_system]
	
	for i in range(count):
		var new_bubble = bubble_scene.instantiate()
		
		new_bubble.value = pool.pick_random()
		
		add_child(new_bubble)
		
		var rx = randf_range(-15.0, 15.0)
		var rz = randf_range(-15.0, 15.0)
		new_bubble.global_position = Vector3(rx, 1.5, rz)
