extends CharacterBody3D

@export var speed = 5.0
@export var sprint_speed = 10.0
@export var acceleration = 15.0
@export var jump_velocity = 8.0
@export var mouse_sensitivity = 0.002

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cam_pivot = $Node3D 
@onready var spring_arm = $Node3D/SpringArm3D
@onready var anim_player = $AnimationPlayer 

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spring_arm.add_excluded_object(get_rid())

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x, deg_to_rad(-70), deg_to_rad(70))

func _physics_process(delta):
	if is_on_floor():
		if not has_meta("last_safe_pos"):
			set_meta("last_safe_pos", global_position)
		set_meta("last_safe_pos", global_position)

	if global_position.y < -10.0 and has_meta("last_safe_pos"):
		global_position = get_meta("last_safe_pos")
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_speed = speed
	if Input.is_action_pressed("sprint") and is_on_floor():
		current_speed = sprint_speed

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()

	if is_on_floor():
		if input_dir.length() > 0:
			if not has_meta("footstep_timer"):
				set_meta("footstep_timer", 0.0)
			var timer = get_meta("footstep_timer") - delta
			if timer <= 0.0:
				if AudioManager:
					AudioManager.play("walk")
				timer = 0.35 if Input.is_action_pressed("sprint") else 0.5
			set_meta("footstep_timer", timer)
			
			if Input.is_action_pressed("sprint"):
				_play_animation("Rig_Medium_MovementBasic/Running_A")
			else:
				_play_animation("Rig_Medium_MovementBasic/Walking_A")
		else:
			_play_animation("Rig_Medium_General/Idle_A")
	else:
		_play_animation("Rig_Medium_MovementBasic/Jump_Full_Short")

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _play_animation(anim_name: String):
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
