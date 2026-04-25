extends Node3D

@export var bubble_scene: PackedScene 

@onready var prompt_label = get_node("../HUD/UI_Root/HBoxContainer/PromptLabel")
@onready var system_label = get_node("../HUD/UI_Root/HBoxContainer/SystemLabel")
@onready var collection_label = get_node("../HUD/UI_Root/HBoxContainer/NumberBox/CollectionLabel")
@onready var dir_light = get_node("../DirectionalLight3D")

var level_gen_script = preload("res://level_generator.gd")
var virus_script = preload("res://virus.gd")
var level_gen_node: Node3D

var systems = {"BIN": 2, "HEX": 16, "DEC": 10}
var system_chars = {
	"BIN": ["0", "0", "1", "1", "1", "1", "00", "01", "10", "11"]
}

enum State { ROOM_1, ROOM_2 }
var state = State.ROOM_1

var goal_value_decimal: int = 0
var goal_string_target: String = ""
var current_collected_string: String = ""

# Room 2 Specifics
var r2_val1_dec = 0
var r2_val2_dec = 0

var time_left: float = 60.0
var timer_label: Label

var has_shield: bool = false
var freeze_timer: float = 0.0
var mistakes: int = 0

func _ready():
	randomize()
	_style_ui()
	_create_timer_ui()
	_setup_level()
	start_new_round()

func _style_ui():
	var settings = LabelSettings.new()
	settings.font_size = 42
	settings.outline_size = 6
	settings.outline_color = Color(0, 0, 0, 1.0)
	settings.shadow_size = 4
	settings.shadow_color = Color(0, 0, 0, 0.8)
	settings.shadow_offset = Vector2(3, 3)

	if prompt_label:
		prompt_label.label_settings = settings.duplicate()
		prompt_label.label_settings.font_color = Color(0.2, 0.8, 1.0)
	if system_label:
		system_label.label_settings = settings.duplicate()
		system_label.label_settings.font_color = Color(1.0, 0.8, 0.2)
	if collection_label:
		collection_label.label_settings = settings.duplicate()
		collection_label.label_settings.font_color = Color(0.2, 1.0, 0.2)

func _create_timer_ui():
	timer_label = Label.new()
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	timer_label.add_theme_constant_override("shadow_offset_x", 3)
	timer_label.add_theme_constant_override("shadow_offset_y", 3)
	timer_label.add_theme_constant_override("shadow_outline_size", 4)
	timer_label.text = "⏳ 01:00"
	
	var canvas = get_node_or_null("../HUD")
	if canvas:
		canvas.add_child(timer_label)
		timer_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		timer_label.position = Vector2(40, 100)

func _setup_level():
	# Delete old manual walls if they exist
	for child in get_parent().get_children():
		if child.name.begins_with("wall") and child != self:
			child.queue_free()
	
	# Instantiate Level Generator
	level_gen_node = Node3D.new()
	level_gen_node.set_script(level_gen_script)
	get_parent().call_deferred("add_child", level_gen_node)
	
	# Add an OmniLight3D for Room 2 that is dim initially
	var omni = OmniLight3D.new()
	omni.name = "Room2Light"
	omni.position = Vector3(0, 8, 40)
	omni.light_energy = 0.0 # Off initially
	omni.omni_range = 60.0 # Wide range
	get_parent().call_deferred("add_child", omni)
	
	_create_minimap()

func start_new_round():
	current_collected_string = ""
	collection_label.text = ""
	
	if state == State.ROOM_1:
		time_left = 60.0
		goal_value_decimal = randi_range(1, 31)
		var prompt_val = _convert_to_base(goal_value_decimal, systems["HEX"])
		goal_string_target = _convert_to_base(goal_value_decimal, systems["BIN"])
		prompt_label.text = prompt_val + " (HEX) ➔ "
		system_label.text = "Collect BIN: "
	else:
		time_left = 120.0
		r2_val1_dec = randi_range(1, 15)
		r2_val2_dec = randi_range(1, 15)
		goal_value_decimal = r2_val1_dec + r2_val2_dec
		goal_string_target = _convert_to_base(goal_value_decimal, systems["BIN"])
		
		var hex_str = _convert_to_base(r2_val1_dec, systems["HEX"])
		var dec_str = str(r2_val2_dec)
		prompt_label.text = hex_str + " (HEX) + " + dec_str + " (DEC) ➔ "
		system_label.text = "Collect BIN: "
	
	_clear_old_bubbles()
	spawn_bubbles(100)
	spawn_powerups(5)
	
	if state == State.ROOM_1:
		spawn_viruses(1)
	else:
		spawn_viruses(2)

func _convert_to_base(decimal_val: int, base: int) -> String:
	return String.num_int64(decimal_val, base).to_upper()

func _clear_old_bubbles():
	for child in get_parent().get_children():
		if child is Area3D and child.has_method("_on_body_entered"):
			child.queue_free()
		if child.name.begins_with("Virus") or child.is_in_group("Virus") or child.is_in_group("Powerup"):
			child.queue_free()

func spawn_viruses(count: int):
	for i in range(count):
		var v = preload("res://virus.gd").new()
		v.name = "Virus_" + str(i)
		var rx = randf_range(-12.0, 12.0)
		var rz = 0.0
		if state == State.ROOM_1:
			rz = randf_range(-44.0, -4.0)
		else:
			rz = randf_range(6.0, 36.0)
		v.position = Vector3(rx, 2.0, rz)
		get_parent().call_deferred("add_child", v)

func spawn_bubbles(count: int):
	for i in range(count):
		spawn_single_bubble()

func spawn_single_bubble():
	var pool = system_chars["BIN"]
	var new_bubble = bubble_scene.instantiate()
	new_bubble.value = pool.pick_random()
	
	# Room 1 is z from -8 to 0 (approx), Room 2 is z from 0 to 8 (approx offset depending on scale)
	# Wait, level_gen uses step=4.0. So z=-8..8 tiles -> z = -32 to 32.
	# Room 1 is z=-32 to 0. Room 2 is z=4 to 32.
	var rx = randf_range(-12.0, 12.0)
	var rz = 0.0
	if state == State.ROOM_1:
		rz = randf_range(-44.0, -4.0)
	else:
		rz = randf_range(6.0, 36.0)
		
	new_bubble.position = Vector3(rx, 2.4, rz)
	get_parent().call_deferred("add_child", new_bubble)

func spawn_powerups(count: int):
	for i in range(count):
		var p = preload("res://powerup.gd").new()
		p.type = randi() % 3
		var rx = randf_range(-12.0, 12.0)
		var rz = 0.0
		if state == State.ROOM_1:
			rz = randf_range(-44.0, -4.0)
		else:
			rz = randf_range(6.0, 36.0)
		p.position = Vector3(rx, 2.4, rz)
		get_parent().call_deferred("add_child", p)

func activate_powerup(type: int, pos: Vector3):
	if type == 0: # SHIELD
		has_shield = true
		_spawn_vfx(pos, Color(0.1, 0.3, 1.0))
		_show_powerup_message("Shield x1 🛡️", Color(0.4, 0.6, 1.0))
	elif type == 1: # FREEZE
		freeze_timer = 5.0
		_spawn_vfx(pos, Color(0.1, 1.0, 1.0))
		_show_powerup_message("Frozen +5s ❄️", Color(0.4, 1.0, 1.0))
	elif type == 2: # TIME
		time_left += 10.0
		_spawn_vfx(pos, Color(1.0, 0.8, 0.1))
		_show_powerup_message("+10 Seconds! ⏳", Color(1.0, 0.9, 0.3))
		
	if AudioManager:
		AudioManager.play("collect")

func _show_powerup_message(msg: String, color: Color):
	var canvas = get_node_or_null("../HUD")
	if not canvas: return
	
	var label = Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var vp_size = get_viewport().get_visible_rect().size
	label.custom_minimum_size = Vector2(vp_size.x, 100)
	label.position = Vector2(0, vp_size.y / 2.0 - 150)
	
	var settings = LabelSettings.new()
	settings.font_size = 56
	settings.font_color = color
	settings.outline_size = 6
	settings.outline_color = Color.BLACK
	settings.shadow_size = 4
	settings.shadow_color = Color(0, 0, 0, 0.8)
	settings.shadow_offset = Vector2(3, 3)
	label.label_settings = settings
	
	canvas.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 120, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)

func is_frozen() -> bool:
	return freeze_timer > 0.0

func add_to_collection_with_pos(val: String, pos: Vector3):
	current_collected_string += val
	collection_label.text = ""
	for char in current_collected_string:
		collection_label.text += char + " "
	
	# UI Hacker Animation (Pop scale)
	var tween = create_tween()
	tween.tween_property(collection_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(collection_label, "scale", Vector2(1.0, 1.0), 0.1)
	
	_spawn_vfx(pos, Color(0.2, 1.0, 0.2)) # Green effect
	
	if AudioManager:
		AudioManager.play("collect")
	
	spawn_single_bubble()
	_check_win_condition()

func remove_last_digit():
	if has_shield:
		has_shield = false
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			_spawn_vfx(players[0].global_position, Color(0.1, 0.3, 1.0)) # Blue smoke for shield break
		if AudioManager:
			AudioManager.play("wrong")
		return
		
	mistakes += 1
	if current_collected_string.length() > 0:
		current_collected_string = ""
		collection_label.text = ""
		
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			var player_pos = players[0].global_position
			_spawn_vfx(player_pos, Color(1.0, 0.2, 0.2)) # Red smoke
			
		_flash_ui(Color(1.0, 0.2, 0.2))
		if AudioManager:
			AudioManager.play("wrong")

func _check_win_condition():
	if current_collected_string == goal_string_target:
		_flash_ui(Color(0.2, 1.0, 0.2)) # Green flash
		if AudioManager:
			AudioManager.play("correct")
		
		if state == State.ROOM_1:
			# Open Door, transition to Room 2
			level_gen_node.open_door()
			state = State.ROOM_2
			_transition_to_room2()
			start_new_round()
		else:
			if AudioManager:
				AudioManager.play("win")
			_show_end_game()
	elif not goal_string_target.begins_with(current_collected_string):
		_flash_ui(Color(1.0, 0.2, 0.2)) # Red flash
		if AudioManager:
			AudioManager.play("wrong")
		current_collected_string = ""
		collection_label.text = ""

func _spawn_vfx(pos: Vector3, color: Color):
	var parts = CPUParticles3D.new()
	parts.emitting = false
	parts.one_shot = true
	parts.amount = 30
	parts.lifetime = 0.5
	parts.explosiveness = 0.9
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = 0.6
	parts.direction = Vector3(0, 1, 0)
	parts.spread = 180.0
	parts.gravity = Vector3(0, 2, 0) if color.r > color.g else Vector3(0, -5, 0) # red smoke goes up
	parts.initial_velocity_min = 2.0
	parts.initial_velocity_max = 5.0
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.2, 0.2)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	mesh.material = mat
	parts.mesh = mesh
	
	parts.position = pos
	get_parent().call_deferred("add_child", parts)
	parts.call_deferred("set_emitting", true)
	
	get_tree().create_timer(1.0).timeout.connect(parts.queue_free)

func _flash_ui(color: Color):
	var ui_root = get_node("../HUD/UI_Root/HBoxContainer")
	if ui_root:
		var tween = create_tween()
		tween.tween_property(ui_root, "modulate", color, 0.1)
		tween.tween_property(ui_root, "modulate", Color.WHITE, 0.3)

func _transition_to_room2():
	if dir_light:
		var tween = create_tween()
		tween.tween_property(dir_light, "light_energy", 0.1, 2.0)
	var r2light = get_parent().get_node_or_null("Room2Light")
	if r2light:
		var tween2 = create_tween()
		tween2.tween_property(r2light, "light_energy", 1.5, 2.0)

func _show_end_game():
	get_tree().paused = true
	var end_ui = preload("res://end_game_ui.gd").new()
	if end_ui.has_method("init_stats"):
		end_ui.init_stats(time_left, mistakes)
	add_child(end_ui)

func _create_minimap():
	var canvas = get_node_or_null("../HUD")
	if not canvas: return
	
	var container = SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -220
	container.offset_right = -20
	container.offset_top = 20
	container.offset_bottom = 220
	
	var vp = SubViewport.new()
	vp.size = Vector2(200, 200)
	vp.transparent_bg = true
	container.add_child(vp)
	
	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 40.0
	cam.position = Vector3(0, 50, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	cam.cull_mask = ~(1 << 1) # Optional cull mask if needed
	vp.add_child(cam)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.4)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(bg)
	container.move_child(bg, 0)
	
	canvas.add_child(container)
	
	# Cam follow logic
	var cam_script = GDScript.new()
	cam_script.source_code = """
extends Camera3D
func _process(delta):
	var players = get_tree().get_nodes_in_group('Player')
	if players.size() > 0:
		var p = players[0]
		position.x = p.global_position.x
		position.z = p.global_position.z
"""
	cam_script.reload()
	cam.set_script(cam_script)

func _process(delta):
	if freeze_timer > 0:
		freeze_timer -= delta

	if time_left > 0:
		time_left -= delta
		if timer_label:
			var secs = int(time_left)
			var minutes = secs / 60
			var seconds = secs % 60
			timer_label.text = "⏳ %02d:%02d" % [minutes, seconds]
			
		if time_left <= 0:
			if AudioManager:
				AudioManager.play("wrong")
			_show_time_over_menu()

func _show_time_over_menu():
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS # Crucial for pausing
	add_child(canvas)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 50
	style.content_margin_right = 50
	style.content_margin_top = 40
	style.content_margin_bottom = 40
	# Add a nice shadow to the panel
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 10
	style.shadow_offset = Vector2(5, 5)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "TIME OVER!"
	var ts = LabelSettings.new()
	ts.font_size = 64
	ts.outline_size = 6
	ts.outline_color = Color.BLACK
	ts.font_color = Color(1.0, 0.2, 0.2)
	ts.shadow_size = 5
	ts.shadow_color = Color(0.5, 0.0, 0.0, 0.8)
	ts.shadow_offset = Vector2(3, 3)
	title.label_settings = ts
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var btn_center = CenterContainer.new()
	vbox.add_child(btn_center)
	
	var btn_vbox = VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 20)
	btn_center.add_child(btn_vbox)
	
	var btn_play = Button.new()
	btn_play.text = "Play Again"
	_style_menu_button(btn_play, Color(0.1, 0.7, 0.2), Color(0.05, 0.5, 0.1))
	btn_play.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	btn_vbox.add_child(btn_play)
	
	var btn_exit = Button.new()
	btn_exit.text = "Exit Game"
	_style_menu_button(btn_exit, Color(0.8, 0.1, 0.1), Color(0.6, 0.05, 0.05))
	btn_exit.pressed.connect(func():
		get_tree().quit()
	)
	btn_vbox.add_child(btn_exit)
	
	center.add_child(panel)

func _style_menu_button(btn: Button, color_normal: Color, color_hover: Color):
	btn.custom_minimum_size = Vector2(220, 65)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", Color.WHITE)
	
	var style_n = StyleBoxFlat.new()
	style_n.bg_color = color_normal
	style_n.corner_radius_top_left = 12
	style_n.corner_radius_top_right = 12
	style_n.corner_radius_bottom_left = 12
	style_n.corner_radius_bottom_right = 12
	style_n.shadow_color = Color(0, 0, 0, 0.4)
	style_n.shadow_size = 4
	style_n.shadow_offset = Vector2(2, 2)
	
	var style_h = style_n.duplicate()
	style_h.bg_color = color_hover
	
	btn.add_theme_stylebox_override("normal", style_n)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_h)
