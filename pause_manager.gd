extends CanvasLayer

var panel: PanelContainer
var options_container: VBoxContainer
var is_paused = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	
	panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.visible = false
	add_child(panel)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	
	options_container = VBoxContainer.new()
	options_container.add_theme_constant_override("separation", 20)
	options_container.custom_minimum_size = Vector2(300, 0)
	center.add_child(options_container)
	
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	options_container.add_child(title)
	
	var label1 = Label.new()
	label1.text = "Game Volume"
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options_container.add_child(label1)
	
	var slider1 = HSlider.new()
	slider1.min_value = 0.0
	slider1.max_value = 1.0
	slider1.step = 0.05
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx != -1:
		slider1.value = db_to_linear(AudioServer.get_bus_volume_db(master_idx))
	slider1.value_changed.connect(_on_sfx_volume_changed)
	options_container.add_child(slider1)
	
	var resume_btn = Button.new()
	resume_btn.text = "Resume"
	_style_button(resume_btn, Color(0.1, 0.55, 0.9),  Color(0.05, 0.4, 0.75))
	resume_btn.pressed.connect(_on_resume)
	options_container.add_child(resume_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "Main Menu"
	_style_button(menu_btn, Color(0.65, 0.1, 0.1),  Color(0.5, 0.05, 0.05))
	menu_btn.pressed.connect(_on_menu)
	options_container.add_child(menu_btn)

func _process(delta):
	# Only allow pausing if we're not in the main menu
	var cur_scene = get_tree().current_scene
	if cur_scene and cur_scene.name == "MainMenu":
		return
		
	if Input.is_action_just_pressed("ui_cancel"):
		if is_paused:
			_on_resume()
		else:
			_show_pause()

func _show_pause():
	is_paused = true
	get_tree().paused = true
	panel.visible = true

func _on_resume():
	is_paused = false
	get_tree().paused = false
	panel.visible = false

func _on_menu():
	is_paused = false
	get_tree().paused = false
	panel.visible = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_sfx_volume_changed(val):
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var master_idx = AudioServer.get_bus_index("Master")
	for idx in [sfx_idx, master_idx]:
		if idx != -1:
			if val <= 0.01:
				AudioServer.set_bus_mute(idx, true)
			else:
				AudioServer.set_bus_mute(idx, false)
				AudioServer.set_bus_volume_db(idx, linear_to_db(val))

func _style_button(btn: Button, color_normal: Color, color_hover: Color):
	btn.custom_minimum_size = Vector2(300, 58)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color_normal
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color_hover
	style_hover.corner_radius_top_left = 10
	style_hover.corner_radius_top_right = 10
	style_hover.corner_radius_bottom_left = 10
	style_hover.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover",  style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
