extends Node3D

@export var bubble_scene: PackedScene 

@onready var prompt_label = get_node("../HUD/UI_Root/HBoxContainer/PromptLabel")
@onready var system_label = get_node("../HUD/UI_Root/HBoxContainer/SystemLabel")
@onready var collection_label = get_node("../HUD/UI_Root/HBoxContainer/NumberBox/CollectionLabel")

var systems = {
	"BIN": 2,
	"OCT": 8,
	"DEC": 10,
	"HEX": 16
}

var system_chars = {
	"BIN": ["0", "1"],
	"OCT": ["0", "1", "2", "3", "4", "5", "6", "7"],
	"DEC": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
	"HEX": ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
}

var source_system: String = ""
var target_system: String = ""
var goal_value_decimal: int = 0
var goal_string_target: String = ""
var current_collected_string: String = ""

func _ready():
	randomize()
	start_new_round()

func start_new_round():
	current_collected_string = ""
	collection_label.text = ""
	
	var system_names = systems.keys()
	source_system = system_names.pick_random()
	
	target_system = source_system
	while target_system == source_system:
		target_system = system_names.pick_random()
	
	goal_value_decimal = randi_range(1, 31)
	
	var prompt_val = _convert_to_base(goal_value_decimal, systems[source_system])
	goal_string_target = _convert_to_base(goal_value_decimal, systems[target_system])
	
	prompt_label.text = prompt_val + " (" + source_system + ") ➔ "
	system_label.text = "Collect " + target_system + ": "
	
	_clear_old_bubbles()
	spawn_bubbles(25)

func _convert_to_base(decimal_val: int, base: int) -> String:
	return String.num_int64(decimal_val, base).to_upper()

func _clear_old_bubbles():
	for child in get_children():
		if child is Area3D:
			child.queue_free()

func spawn_bubbles(count: int):
	var pool = system_chars[target_system]
	for i in range(count):
		var new_bubble = bubble_scene.instantiate()
		new_bubble.value = pool.pick_random()
		var rx = randf_range(-12.0, 12.0)
		var rz = randf_range(-12.0, 12.0)
		new_bubble.position = Vector3(rx, 1.5, rz)
		add_child(new_bubble)

func add_to_collection(val: String):
	current_collected_string += val
	collection_label.text = ""
	for char in current_collected_string:
		collection_label.text += char + " "
	
	_check_win_condition()

func _check_win_condition():
	if current_collected_string == goal_string_target:
		print("Correct!")
		start_new_round()
	elif not goal_string_target.begins_with(current_collected_string):
		print("Wrong sequence! Resetting...")
		current_collected_string = ""
		collection_label.text = ""
