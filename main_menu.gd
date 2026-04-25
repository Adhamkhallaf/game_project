extends Control

const GAME_SCENE = "res://floor_foundation_allsides_2.tscn"

@onready var play_btn    = $CenterContainer/VBoxContainer/PlayButton
@onready var options_btn = $CenterContainer/VBoxContainer/OptionsButton
@onready var exit_btn    = $CenterContainer/VBoxContainer/ExitButton
@onready var title_label = $CenterContainer/VBoxContainer/GameTitle

var options_container: VBoxContainer
var is_options_open = false

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex = load("res://beautiful_bg.png")
	if tex:
		bg.texture = tex
	add_child(bg)
	move_child(bg, 0)

	var center = $CenterContainer
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = $CenterContainer/VBoxContainer
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.content_margin_left = 40
	panel_style.content_margin_right = 40
	panel_style.content_margin_top = 40
	panel_style.content_margin_bottom = 40
	panel.add_theme_stylebox_override("panel", panel_style)

	center.remove_child(vbox)
	panel.add_child(vbox)
	center.add_child(panel)

	# Options Container
	options_container = VBoxContainer.new()
	options_container.visible = false
	options_container.add_theme_constant_override("separation", 10)
	
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
	else:
		slider1.value = 1.0 
	slider1.value_changed.connect(_on_sfx_volume_changed)
	options_container.add_child(slider1)

	var label_back = Button.new()
	label_back.text = "Back"
	_style_button(label_back, Color(0.2, 0.2, 0.35),  Color(0.15, 0.15, 0.28))
	label_back.pressed.connect(_on_options_pressed)
	options_container.add_child(label_back)
	
	options_container.custom_minimum_size = Vector2(300, 0)
	panel.add_child(options_container)

	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(0.25, 0.9, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_style_button(play_btn,    Color(0.1, 0.55, 0.9),  Color(0.05, 0.4, 0.75))
	_style_button(options_btn, Color(0.2, 0.2, 0.35),  Color(0.15, 0.15, 0.28))
	_style_button(exit_btn,    Color(0.65, 0.1, 0.1),  Color(0.5, 0.05, 0.05))

	vbox.add_theme_constant_override("separation", 16)

	play_btn.pressed.connect(_on_play_pressed)
	options_btn.pressed.connect(_on_options_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

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

func _on_play_pressed():
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_options_pressed():
	is_options_open = !is_options_open
	$CenterContainer/VBoxContainer.visible = !is_options_open
	options_container.visible = is_options_open

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

func _on_exit_pressed():
	get_tree().quit()
