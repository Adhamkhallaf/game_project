extends Node

var players = {}
var current_bgm_player: AudioStreamPlayer = null

func _ready():
	_register_sound("collect", "res://collect.wav")
	_register_sound("correct", "res://correct.wav")
	_register_sound("wrong", "res://wrong.wav")
	_register_sound("door", "res://door.wav")
	_register_sound("win", "res://win.wav")
	_register_sound("walk", "res://walk.wav")
	_register_sound("bgm_calm", "res://bgm_calm.wav", true)
	_register_sound("bgm_intense", "res://bgm_intense.wav", true)

func _register_sound(name_id: String, path: String, is_bgm: bool = false):
	var player = AudioStreamPlayer.new()
	var stream = load(path)
	if stream:
		if is_bgm:
			player.finished.connect(player.play)
		player.stream = stream
		player.bus = "Master"
		if is_bgm:
			player.volume_db = -8.0 # Make it a quiet background feeling, not harsh
			player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		players[name_id] = player
		print("Successfully registered sound: ", name_id)
	else:
		print("Warning: Could not load sound " + path)

func play(name_id: String):
	if players.has(name_id):
		# Prevent stacking the same sound too loudly or restart it
		players[name_id].play()

func play_bgm(name_id: String):
	print("Requested BGM: ", name_id)
	if current_bgm_player and current_bgm_player == players.get(name_id):
		print("Already playing BGM: ", name_id)
		return
	if current_bgm_player:
		print("Stopping old BGM")
		current_bgm_player.stop()
	if players.has(name_id):
		current_bgm_player = players[name_id]
		current_bgm_player.play()
		print("Started playing BGM: ", name_id)
	else:
		print("BGM not found: ", name_id)
