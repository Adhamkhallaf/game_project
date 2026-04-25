extends CanvasLayer

var final_time: float = 0.0
var final_mistakes: int = 0

func init_stats(time: float, mistakes: int):
	final_time = time
	final_mistakes = mistakes

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.85)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "YOU WIN!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "All Puzzles Solved!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	vbox.add_child(subtitle)
	
	var stats = Label.new()
	var mins = int(final_time) / 60
	var secs = int(final_time) % 60
	stats.text = "Time Left: %02d:%02d\nMistakes: %d" % [mins, secs, final_mistakes]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(stats)
	
	var stars_count = 1
	if final_mistakes == 0 and final_time > 30.0:
		stars_count = 3
	elif final_mistakes <= 2 or final_time > 15.0:
		stars_count = 2
		
	var stars = Label.new()
	var star_str = ""
	for i in range(stars_count):
		star_str += "★"
	stars.text = star_str
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 48)
	stars.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(stars)

	
	var play_again = Button.new()
	play_again.text = "Play Again"
	_style_button(play_again, Color(0.1, 0.7, 0.2), Color(0.05, 0.5, 0.1))
	play_again.pressed.connect(_on_play_again)
	vbox.add_child(play_again)
	
	var exit_btn = Button.new()
	exit_btn.text = "Exit Game"
	_style_button(exit_btn, Color(0.8, 0.1, 0.1), Color(0.6, 0.05, 0.05))
	exit_btn.pressed.connect(_on_exit)
	vbox.add_child(exit_btn)

func _on_play_again():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _style_button(btn: Button, color_normal: Color, color_hover: Color):
	btn.custom_minimum_size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 28)
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
