extends CharacterBody3D

@export var speed = 5.0
@export var acceleration = 15.0
@export var jump_velocity = 4.5
@export var mouse_sensitivity = 0.002

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cam_pivot = $Node3D 
@onready var spring_arm = $Node3D/SpringArm3D

# 1. NEW: Get reference to the AnimationPlayer
# Check your scene tree; if it's inside another node, adjust the path (e.g. $Model/AnimationPlayer)
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
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

	move_and_slide()

	# 2. NEW: Animation Logic
	if is_on_floor():
		# Use input_dir instead of velocity.length()
		# This triggers the change the MOMENT you let go of the keys.
		if input_dir.length() > 0:
			_play_animation("Rig_Medium_MovementBasic/Walking_A") 
		else:
			_play_animation("Rig_Medium_MovementBasic/T-Pose")
	else:
		# Optional: Add a jump animation if you have one
		# _play_animation("Rig_Medium_Movement/Jump_Idle")
		pass

	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# 3. Helper function to prevent the animation from restarting every single frame
func _play_animation(anim_name: String):
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)
