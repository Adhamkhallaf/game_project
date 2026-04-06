extends Node3D

@export var bubble_scene: PackedScene 

var systems = {
	"BIN": ["0", "1"],
	"OCT": ["0", "1", "2", "3", "4", "5", "6", "7"],
	"DEC": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
	"HEX": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
}

@export var current_target_system = "BIN" 

func _ready():
	randomize()
	spawn_bubbles(10)

func spawn_bubbles(count: int):
	# Make sure the system exists in our dictionary
	if not systems.has(current_target_system):
		print("Error: System not found!")
		return
		
	var pool = systems[current_target_system]
	
	for i in range(count):
		var new_bubble = bubble_scene.instantiate()
		new_bubble.value = pool.pick_random()
		
		# 1. ADD TO THE WORLD FIRST
		add_child(new_bubble)
		
		# 2. SET POSITION SECOND (using global_position)
		var rx = randf_range(-10.0, 10.0)
		var rz = randf_range(-10.0, 10.0)
		new_bubble.global_position = Vector3(rx, 2.0, rz) # Height 2.0 to be sure it's off the floor
